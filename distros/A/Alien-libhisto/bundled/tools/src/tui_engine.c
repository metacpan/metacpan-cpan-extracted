/*
 * TUI state machine: background ingestion, viewport math, and rendering loop.
 */

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#ifndef _DEFAULT_SOURCE
#define _DEFAULT_SOURCE 1
#endif
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 700
#endif

#include "tui_engine.h"
#include "cli_common.h"
#include "tui_shm.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <math.h>
#include <time.h>

#if defined(_WIN32) || defined(_WIN64)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <sys/types.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#endif

/* ========================================================================= */
/* Shared Memory Binary Ring Buffer Implementation                           */
/* ========================================================================= */

bool histo_shm_create(histo_shm_t *shm, const char *path, size_t capacity, uint32_t entry_size, uint64_t flags) {
    if (!shm || !path || capacity == 0 || entry_size == 0) return false;
    memset(shm, 0, sizeof(*shm));
    shm->fd = -1;
    strncpy(shm->path, path, sizeof(shm->path) - 1);
    shm->is_creator = true;

    /* Ensure capacity is a power of two */
    size_t cap = 1;
    while (cap < capacity) cap <<= 1;

    size_t total_size = sizeof(histo_shm_ring_t) + (cap * entry_size);
    shm->size = total_size;

#if defined(_WIN32) || defined(_WIN64)
    const char *win_name = path;
    while (*win_name == '/' || *win_name == '\\') win_name++;
    char clean_name[256];
    size_t ki = 0;
    for (size_t i = 0; win_name[i] && ki < sizeof(clean_name) - 1; i++) {
        clean_name[ki++] = (win_name[i] == '/' || win_name[i] == '\\') ? '_' : win_name[i];
    }
    clean_name[ki] = '\0';
    const char *target_name = clean_name[0] ? clean_name : "histo_shm_default";

    HANDLE hMap = CreateFileMappingA(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
                                     (DWORD)(total_size >> 32), (DWORD)(total_size & 0xFFFFFFFF), target_name);
    if (!hMap) return false;
    shm->os_handle = (void *)hMap;
    shm->ring = (histo_shm_ring_t *)MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, total_size);
    if (!shm->ring) {
        CloseHandle(hMap);
        shm->os_handle = NULL;
        return false;
    }
#else
    int fd = -1;
    if (path[0] == '/') {
        fd = shm_open(path, O_CREAT | O_RDWR | O_TRUNC, 0666);
    }
    if (fd < 0) {
        fd = open(path, O_CREAT | O_RDWR | O_TRUNC, 0666);
    }
    if (fd < 0) return false;

    if (ftruncate(fd, (off_t)total_size) != 0) {
        close(fd);
        if (path[0] == '/') shm_unlink(path);
        return false;
    }

    void *ptr = mmap(NULL, total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (ptr == MAP_FAILED) {
        close(fd);
        if (path[0] == '/') shm_unlink(path);
        return false;
    }

    shm->fd = fd;
    shm->ring = (histo_shm_ring_t *)ptr;
#endif

    memset(shm->ring, 0, sizeof(histo_shm_ring_t));
    shm->ring->magic = HISTO_SHM_MAGIC;
    shm->ring->version = HISTO_SHM_VERSION;
    shm->ring->entry_size = entry_size;
    shm->ring->mask = (uint64_t)(cap - 1);
    shm->ring->head = 0;
    shm->ring->tail = 0;
    shm->ring->dropped = 0;
    shm->ring->flags = flags;

    return true;
}

bool histo_shm_open(histo_shm_t *shm, const char *path) {
    if (!shm || !path) return false;
    memset(shm, 0, sizeof(*shm));
    shm->fd = -1;
    strncpy(shm->path, path, sizeof(shm->path) - 1);
    shm->is_creator = false;

#if defined(_WIN32) || defined(_WIN64)
    const char *win_name = path;
    while (*win_name == '/' || *win_name == '\\') win_name++;
    char clean_name[256];
    size_t ki = 0;
    for (size_t i = 0; win_name[i] && ki < sizeof(clean_name) - 1; i++) {
        clean_name[ki++] = (win_name[i] == '/' || win_name[i] == '\\') ? '_' : win_name[i];
    }
    clean_name[ki] = '\0';
    const char *target_name = clean_name[0] ? clean_name : "histo_shm_default";

    HANDLE hMap = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, target_name);
    if (!hMap) return false;
    shm->os_handle = (void *)hMap;
    histo_shm_ring_t *hdr = (histo_shm_ring_t *)MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, sizeof(histo_shm_ring_t));
    if (!hdr) {
        CloseHandle(hMap);
        shm->os_handle = NULL;
        return false;
    }
    if (hdr->magic != HISTO_SHM_MAGIC) {
        UnmapViewOfFile(hdr);
        CloseHandle(hMap);
        shm->os_handle = NULL;
        return false;
    }
    size_t total_size = sizeof(histo_shm_ring_t) + ((hdr->mask + 1) * hdr->entry_size);
    UnmapViewOfFile(hdr);

    shm->size = total_size;
    shm->ring = (histo_shm_ring_t *)MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, total_size);
    if (!shm->ring) {
        CloseHandle(hMap);
        shm->os_handle = NULL;
        return false;
    }
#else
    int fd = -1;
    if (path[0] == '/') {
        fd = shm_open(path, O_RDWR, 0666);
    }
    if (fd < 0) {
        fd = open(path, O_RDWR, 0666);
    }
    if (fd < 0) return false;

    struct stat st;
    if (fstat(fd, &st) != 0 || st.st_size < (off_t)sizeof(histo_shm_ring_t)) {
        close(fd);
        return false;
    }

    size_t total_size = (size_t)st.st_size;
    void *ptr = mmap(NULL, total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (ptr == MAP_FAILED) {
        close(fd);
        return false;
    }

    histo_shm_ring_t *ring = (histo_shm_ring_t *)ptr;
    if (ring->magic != HISTO_SHM_MAGIC) {
        munmap(ptr, total_size);
        close(fd);
        return false;
    }

    shm->fd = fd;
    shm->size = total_size;
    shm->ring = ring;
#endif

    return true;
}

void histo_shm_close(histo_shm_t *shm) {
    if (!shm || !shm->ring) return;

#if defined(_WIN32) || defined(_WIN64)
    if (shm->ring) UnmapViewOfFile(shm->ring);
    if (shm->os_handle) CloseHandle((HANDLE)shm->os_handle);
#else
    if (shm->ring && shm->size > 0) {
        munmap(shm->ring, shm->size);
    }
    if (shm->fd >= 0) {
        close(shm->fd);
    }
    if (shm->is_creator && shm->path[0] != '\0') {
        if (shm->path[0] == '/') shm_unlink(shm->path);
        else unlink(shm->path);
    }
#endif
    shm->ring = NULL;
    shm->fd = -1;
    shm->os_handle = NULL;
    shm->size = 0;
}

bool histo_shm_push(histo_shm_ring_t *ring, const void *entry) {
    if (!ring || !entry) return false;
    uint64_t head = ring->head;
    uint64_t tail = ring->tail;
    uint64_t cap = ring->mask + 1;

    if (head - tail >= cap) {
        ring->dropped++;
        ring->tail = head - cap + 1;
    }

    uint64_t idx = head & ring->mask;
    memcpy(ring->data + (idx * ring->entry_size), entry, ring->entry_size);
    ring->head = head + 1;
    return true;
}

size_t histo_shm_pop_batch(histo_shm_ring_t *ring, void *out_entries, size_t max_entries) {
    if (!ring || !out_entries || max_entries == 0) return 0;
    uint64_t head = ring->head;
    uint64_t tail = ring->tail;

    if (tail >= head) return 0;

    uint64_t available = head - tail;
    uint64_t cap = ring->mask + 1;
    if (available > cap) {
        tail = head - cap;
        ring->tail = tail;
        available = cap;
    }

    size_t count = (available < (uint64_t)max_entries) ? (size_t)available : max_entries;
    uint8_t *dest = (uint8_t *)out_entries;

    for (size_t i = 0; i < count; ++i) {
        uint64_t idx = (tail + i) & ring->mask;
        memcpy(dest + (i * ring->entry_size), ring->data + (idx * ring->entry_size), ring->entry_size);
    }

    ring->tail = tail + count;
    return count;
}

/* ========================================================================= */
/* TUI Engine Internal Helpers                                               */
/* ========================================================================= */

static double get_time_now_sec(void) {
#if defined(_WIN32)
    static LARGE_INTEGER freq;
    static int has_freq = 0;
    if (!has_freq) {
        QueryPerformanceFrequency(&freq);
        has_freq = 1;
    }
    LARGE_INTEGER count;
    QueryPerformanceCounter(&count);
    return (double)count.QuadPart / (double)freq.QuadPart;
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
#endif
}

static void reservoir_init(tui_reservoir_t *r, size_t cap, bool is_2d, bool has_weights) {
    if (!r) return;
    if (cap < 1000) cap = TUI_RESERVOIR_DEFAULT_CAP;
    for (int c = 0; c < TUI_MAX_COLS; ++c) {
        r->col_data[c] = (double *)malloc(cap * sizeof(double));
    }
    r->weights = has_weights ? (double *)malloc(cap * sizeof(double)) : NULL;
    r->count = 0;
    r->cap = cap;
    r->head = 0;
    r->num_cols = is_2d ? 2 : 1;
    r->is_2d = is_2d;
    r->has_weights = has_weights;
}

static void reservoir_push(tui_reservoir_t *r, const double *cols, size_t num_cols, double w) {
    if (!r || !r->col_data[0]) return;
    if (num_cols > TUI_MAX_COLS) num_cols = TUI_MAX_COLS;
    if (num_cols > r->num_cols) r->num_cols = num_cols;

    size_t idx;
    if (r->count < r->cap) {
        idx = r->count++;
    } else {
        idx = r->head;
        r->head = (r->head + 1 < r->cap) ? r->head + 1 : 0;
    }

    for (size_t c = 0; c < num_cols; ++c) {
        r->col_data[c][idx] = cols[c];
    }
    for (size_t c = num_cols; c < r->num_cols; ++c) {
        r->col_data[c][idx] = 0.0;
    }
    if (r->weights) r->weights[idx] = w;
}

static void reservoir_push_batch(tui_reservoir_t *r, const double bcols[][TUI_MAX_COLS], const size_t *ncols, const double *weights, size_t n) {
    if (!r || !r->col_data[0] || n == 0) return;

    for (size_t i = 0; i < n; ++i) {
        size_t nc = ncols ? ncols[i] : 1;
        if (nc > TUI_MAX_COLS) nc = TUI_MAX_COLS;
        if (nc > r->num_cols) r->num_cols = nc;

        size_t idx;
        if (r->count < r->cap) {
            idx = r->count++;
        } else {
            idx = r->head;
            r->head = (r->head + 1 < r->cap) ? r->head + 1 : 0;
        }

        for (size_t c = 0; c < nc; ++c) {
            r->col_data[c][idx] = bcols[i][c];
        }
        for (size_t c = nc; c < r->num_cols; ++c) {
            r->col_data[c][idx] = 0.0;
        }
        if (r->weights) {
            r->weights[idx] = weights ? weights[i] : 1.0;
        }
    }
}

static void reservoir_free(tui_reservoir_t *r) {
    if (!r) return;
    for (int c = 0; c < TUI_MAX_COLS; ++c) {
        if (r->col_data[c]) free(r->col_data[c]);
        r->col_data[c] = NULL;
    }
    if (r->weights) free(r->weights);
    r->weights = NULL;
    r->count = 0;
    r->cap = 0;
}

static bool is_engine_running(tui_engine_t *eng) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    bool r = eng->running;
    histo_mutex_unlock(&eng->mutex);
    return r;
}

/* Helper to extract windowed linear arrays from the rolling reservoir */
static size_t get_reservoir_window(tui_engine_t *eng, double *out_x, double *out_y, double *out_w, int col_x, int col_y) {
    size_t total = eng->reservoir.count;
    if (total == 0) return 0;
    size_t win = (eng->window_size > 0 && eng->window_size < total) ? eng->window_size : total;
    size_t start_offset = total - win;

    int cx = (col_x >= 1 && col_x <= (int)eng->reservoir.num_cols) ? col_x - 1 : 0;
    int cy = (col_y >= 1 && col_y <= (int)eng->reservoir.num_cols) ? col_y - 1 : (eng->reservoir.num_cols > 1 ? 1 : 0);

    for (size_t i = 0; i < win; ++i) {
        size_t idx = (eng->reservoir.count < eng->reservoir.cap) ?
                     (start_offset + i) :
                     (eng->reservoir.head + start_offset + i) % eng->reservoir.cap;
        if (out_x) out_x[i] = eng->reservoir.col_data[cx][idx];
        if (out_y) out_y[i] = eng->reservoir.col_data[cy][idx];
        if (out_w) out_w[i] = eng->reservoir.weights ? eng->reservoir.weights[idx] : 1.0;
    }
    return win;
}

static void *ingest_worker_thread(void *arg) {
    tui_engine_t *eng = (tui_engine_t *)arg;
    if (!eng) return NULL;

    /* Shared Memory Ingestion Mode */
    if (eng->is_shm) {
        if (!eng->shm.ring) return NULL;
        const size_t max_b = 256;
        uint8_t raw_batch[256 * 32];
        double bx[256], by[256], bw[256];
        double bcols[256][TUI_MAX_COLS];
        size_t entry_sz = eng->shm.ring->entry_size;
        if (entry_sz == 0 || entry_sz > 32) entry_sz = sizeof(double);

        double last_calc_time = get_time_now_sec();
        uint64_t last_calc_samples = 0;

        while (is_engine_running(eng)) {
            size_t n = histo_shm_pop_batch(eng->shm.ring, raw_batch, max_b);
            if (n == 0) {
                histo_sleep_us(500);
                double now = get_time_now_sec();
                if (now - last_calc_time >= 0.25) {
                    histo_mutex_lock(&eng->mutex);
                    uint64_t diff = eng->total_samples - last_calc_samples;
                    eng->current_rate_ops = (double)diff / (now - last_calc_time);
                    last_calc_time = now;
                    last_calc_samples = eng->total_samples;
                    histo_mutex_unlock(&eng->mutex);
                }
                continue;
            }

            double scale = (eng->scale_input > 0.0) ? eng->scale_input : 1.0;
            bool is_2d = eng->is_2d;
            size_t nvals = entry_sz / sizeof(double);
            if (nvals == 0) nvals = 1;

            for (size_t i = 0; i < n; ++i) {
                const double *vals = (const double *)(raw_batch + (i * entry_sz));
                for (size_t c = 0; c < nvals && c < TUI_MAX_COLS; ++c) {
                    bcols[i][c] = vals[c] * scale;
                }
                for (size_t c = nvals; c < TUI_MAX_COLS; ++c) {
                    bcols[i][c] = 0.0;
                }
                bx[i] = bcols[i][0];
                by[i] = (nvals > 1) ? bcols[i][1] : 0.0;
                bw[i] = (nvals > 2) ? vals[2] : 1.0;
            }

            double now = get_time_now_sec();
            histo_mutex_lock(&eng->mutex);

            if (eng->decay_lambda > 0.0 && eng->last_decay_time > 0.0) {
                double dt = now - eng->last_decay_time;
                if (dt >= 0.1) {
                    double factor = exp(-eng->decay_lambda * dt);
                    if (eng->live_1d) histo_scale(eng->live_1d, factor);
                    if (eng->live_2d) histo2d_scale(eng->live_2d, factor);
                    eng->last_decay_time = now;
                }
            }

            if (is_2d && eng->live_2d) {
                for (size_t i = 0; i < n; ++i) {
                    histo2d_fill_w(eng->live_2d, bx[i], by[i], bw[i]);
                }
            } else if (eng->live_1d) {
                histo_fill_n(eng->live_1d, n, bx, NULL);
            }
            for (size_t i = 0; i < n; ++i) {
                reservoir_push(&eng->reservoir, bcols[i], nvals, bw[i]);
            }
            eng->total_samples += n;
            histo_mutex_unlock(&eng->mutex);

            if (now - last_calc_time >= 0.25) {
                histo_mutex_lock(&eng->mutex);
                uint64_t diff = eng->total_samples - last_calc_samples;
                eng->current_rate_ops = (double)diff / (now - last_calc_time);
                last_calc_time = now;
                last_calc_samples = eng->total_samples;
                histo_mutex_unlock(&eng->mutex);
            }
        }
        return NULL;
    }

    if (!eng->in_stream) return NULL;

    char line[4096];
    const size_t batch_max = 4096;
    double *batch_x = (double *)malloc(batch_max * sizeof(double));
    double *batch_y = (double *)malloc(batch_max * sizeof(double));
    double *batch_w = (double *)malloc(batch_max * sizeof(double));
    double (*batch_cols)[TUI_MAX_COLS] = (double (*)[TUI_MAX_COLS])malloc(batch_max * sizeof(*batch_cols));
    size_t *batch_ncols = (size_t *)malloc(batch_max * sizeof(size_t));
    double *raw_buf = (double *)malloc(batch_max * 3 * sizeof(double));
    size_t batch_len = 0;

    if (!batch_x || !batch_y || !batch_w || !batch_cols || !batch_ncols || !raw_buf) {
        if (batch_x) free(batch_x);
        if (batch_y) free(batch_y);
        if (batch_w) free(batch_w);
        if (batch_cols) free(batch_cols);
        if (batch_ncols) free(batch_ncols);
        if (raw_buf) free(raw_buf);
        return NULL;
    }

    double last_calc_time = get_time_now_sec();
    double last_flush_time = last_calc_time;
    uint64_t last_calc_samples = 0;

    while (is_engine_running(eng)) {
        if (eng->is_binary) {
            size_t n_vals_per_sample = eng->is_2d ? (eng->has_weights ? 3 : 2) : (eng->has_weights ? 2 : 1);
            size_t n_req = batch_max - batch_len;
            if (n_req == 0) n_req = batch_max;

            size_t n_read = fread(raw_buf, sizeof(double) * n_vals_per_sample, n_req, eng->in_stream);
            if (n_read == 0) {
                if (feof(eng->in_stream)) {
                    histo_mutex_lock(&eng->mutex);
                    if (batch_len > 0) {
                        int val_col = eng->val_col;
                        int x_col = eng->x_col;
                        int y_col = eng->y_col;
                        int w_col = eng->w_col;
                        bool is_2d = eng->is_2d;
                        bool has_w = eng->has_weights;

                        for (size_t i = 0; i < batch_len; ++i) {
                            size_t nc = batch_ncols[i];
                            int v_idx = (val_col >= 1 && val_col <= (int)nc) ? val_col - 1 : 0;
                            int x_idx = (x_col >= 1 && x_col <= (int)nc) ? x_col - 1 : 0;
                            int y_idx = (y_col >= 1 && y_col <= (int)nc) ? y_col - 1 : (nc > 1 ? 1 : 0);
                            int w_idx = (w_col >= 1 && w_col <= (int)nc) ? w_col - 1 : -1;

                            batch_w[i] = (w_idx >= 0) ? batch_cols[i][w_idx] : 1.0;
                            if (is_2d) {
                                batch_x[i] = batch_cols[i][x_idx];
                                batch_y[i] = batch_cols[i][y_idx];
                            } else {
                                batch_x[i] = batch_cols[i][v_idx];
                                batch_y[i] = 0.0;
                            }
                        }

                        if (is_2d && eng->live_2d) {
                            for (size_t i = 0; i < batch_len; ++i) {
                                histo2d_fill_w(eng->live_2d, batch_x[i], batch_y[i], batch_w[i]);
                            }
                        } else if (eng->live_1d) {
                            if (has_w) {
                                histo_fill_n(eng->live_1d, batch_len, batch_x, batch_w);
                            } else {
                                histo_fill_n(eng->live_1d, batch_len, batch_x, NULL);
                            }
                        }
                        reservoir_push_batch(&eng->reservoir, (const double (*)[TUI_MAX_COLS])batch_cols, batch_ncols, batch_w, batch_len);
                        eng->total_samples += batch_len;
                        batch_len = 0;
                    }
                    eng->finished_reading = true;
                    histo_mutex_unlock(&eng->mutex);
                    histo_sleep_us(20000);
                    continue;
                }
                histo_sleep_us(500);
            } else {
                double scale = (eng->scale_input > 0.0) ? eng->scale_input : 1.0;
                for (size_t i = 0; i < n_read; ++i) {
                    size_t offset = i * n_vals_per_sample;
                    if (eng->is_2d) {
                        batch_cols[batch_len][0] = raw_buf[offset] * scale;
                        batch_cols[batch_len][1] = raw_buf[offset + 1] * scale;
                        if (eng->has_weights) {
                            batch_cols[batch_len][2] = raw_buf[offset + 2];
                            batch_ncols[batch_len] = 3;
                        } else {
                            batch_ncols[batch_len] = 2;
                        }
                    } else {
                        batch_cols[batch_len][0] = raw_buf[offset] * scale;
                        if (eng->has_weights) {
                            batch_cols[batch_len][1] = raw_buf[offset + 1];
                            batch_ncols[batch_len] = 2;
                        } else {
                            batch_ncols[batch_len] = 1;
                        }
                    }
                    for (size_t c = batch_ncols[batch_len]; c < TUI_MAX_COLS; ++c) {
                        batch_cols[batch_len][c] = 0.0;
                    }
                    batch_len++;
                }
            }
        } else {
            if (!fgets(line, sizeof(line), eng->in_stream)) {
                histo_mutex_lock(&eng->mutex);
                if (batch_len > 0) {
                    int val_col = eng->val_col;
                    int x_col = eng->x_col;
                    int y_col = eng->y_col;
                    int w_col = eng->w_col;
                    bool is_2d = eng->is_2d;
                    bool has_w = eng->has_weights;

                    for (size_t i = 0; i < batch_len; ++i) {
                        size_t nc = batch_ncols[i];
                        int v_idx = (val_col >= 1 && val_col <= (int)nc) ? val_col - 1 : 0;
                        int x_idx = (x_col >= 1 && x_col <= (int)nc) ? x_col - 1 : 0;
                        int y_idx = (y_col >= 1 && y_col <= (int)nc) ? y_col - 1 : (nc > 1 ? 1 : 0);
                        int w_idx = (w_col >= 1 && w_col <= (int)nc) ? w_col - 1 : -1;

                        batch_w[i] = (w_idx >= 0) ? batch_cols[i][w_idx] : 1.0;
                        if (is_2d) {
                            batch_x[i] = batch_cols[i][x_idx];
                            batch_y[i] = batch_cols[i][y_idx];
                        } else {
                            batch_x[i] = batch_cols[i][v_idx];
                            batch_y[i] = 0.0;
                        }
                    }

                    if (is_2d && eng->live_2d) {
                        for (size_t i = 0; i < batch_len; ++i) {
                            histo2d_fill_w(eng->live_2d, batch_x[i], batch_y[i], batch_w[i]);
                        }
                    } else if (eng->live_1d) {
                        if (has_w) {
                            histo_fill_n(eng->live_1d, batch_len, batch_x, batch_w);
                        } else {
                            histo_fill_n(eng->live_1d, batch_len, batch_x, NULL);
                        }
                    }
                    reservoir_push_batch(&eng->reservoir, (const double (*)[TUI_MAX_COLS])batch_cols, batch_ncols, batch_w, batch_len);
                    eng->total_samples += batch_len;
                    batch_len = 0;
                }
                eng->finished_reading = true;
                histo_mutex_unlock(&eng->mutex);
                histo_sleep_us(20000);
                continue;
            }

            char *p = line;
            while (*p && isspace((unsigned char)*p)) p++;
            if (*p == '\0' || *p == '#') continue;

            double parsed_cols[TUI_MAX_COLS];
            size_t n_cols = 0;
            char *cur = p;
            double scale = (eng->scale_input > 0.0) ? eng->scale_input : 1.0;

            while (*cur && n_cols < TUI_MAX_COLS) {
                while (*cur && (isspace((unsigned char)*cur) || *cur == ',' || *cur == '\t' || *cur == ';')) cur++;
                if (*cur == '\0' || *cur == '#') break;
                char *endp = NULL;
                double v = strtod(cur, &endp);
                if (endp == cur) break;
                parsed_cols[n_cols++] = v * scale;
                cur = endp;
            }

            if (n_cols == 0) continue;

            for (size_t c = 0; c < TUI_MAX_COLS; ++c) {
                batch_cols[batch_len][c] = (c < n_cols) ? parsed_cols[c] : (n_cols > 0 ? parsed_cols[0] : 0.0);
            }
            batch_ncols[batch_len] = n_cols;
            batch_len++;
        }

        double now = get_time_now_sec();
        if (batch_len >= batch_max || (batch_len > 0 && now - last_flush_time >= 0.05)) {
            histo_mutex_lock(&eng->mutex);

            int val_col = eng->val_col;
            int x_col = eng->x_col;
            int y_col = eng->y_col;
            int w_col = eng->w_col;
            bool is_2d = eng->is_2d;
            bool has_w = eng->has_weights;

            for (size_t i = 0; i < batch_len; ++i) {
                size_t nc = batch_ncols[i];
                int v_idx = (val_col >= 1 && val_col <= (int)nc) ? val_col - 1 : 0;
                int x_idx = (x_col >= 1 && x_col <= (int)nc) ? x_col - 1 : 0;
                int y_idx = (y_col >= 1 && y_col <= (int)nc) ? y_col - 1 : (nc > 1 ? 1 : 0);
                int w_idx = (w_col >= 1 && w_col <= (int)nc) ? w_col - 1 : -1;

                batch_w[i] = (w_idx >= 0) ? batch_cols[i][w_idx] : 1.0;
                if (is_2d) {
                    batch_x[i] = batch_cols[i][x_idx];
                    batch_y[i] = batch_cols[i][y_idx];
                } else {
                    batch_x[i] = batch_cols[i][v_idx];
                    batch_y[i] = 0.0;
                }
            }

            if (eng->decay_lambda > 0.0 && eng->last_decay_time > 0.0) {
                double dt = now - eng->last_decay_time;
                if (dt >= 0.1) {
                    double factor = exp(-eng->decay_lambda * dt);
                    if (eng->live_1d) histo_scale(eng->live_1d, factor);
                    if (eng->live_2d) histo2d_scale(eng->live_2d, factor);
                    eng->last_decay_time = now;
                }
            }

            if (is_2d && eng->live_2d) {
                for (size_t i = 0; i < batch_len; ++i) {
                    histo2d_fill_w(eng->live_2d, batch_x[i], batch_y[i], batch_w[i]);
                }
            } else if (eng->live_1d) {
                if (has_w) {
                    histo_fill_n(eng->live_1d, batch_len, batch_x, batch_w);
                } else {
                    histo_fill_n(eng->live_1d, batch_len, batch_x, NULL);
                }
            }
            reservoir_push_batch(&eng->reservoir, (const double (*)[TUI_MAX_COLS])batch_cols, batch_ncols, batch_w, batch_len);
            eng->total_samples += batch_len;
            histo_mutex_unlock(&eng->mutex);
            batch_len = 0;
            last_flush_time = now;
        }

        if (now - last_calc_time >= 0.25) {
            histo_mutex_lock(&eng->mutex);
            uint64_t diff = eng->total_samples - last_calc_samples;
            eng->current_rate_ops = (double)diff / (now - last_calc_time);
            last_calc_time = now;
            last_calc_samples = eng->total_samples;
            histo_mutex_unlock(&eng->mutex);
        }
    }

    if (batch_len > 0) {
        histo_mutex_lock(&eng->mutex);
        int val_col = eng->val_col;
        int x_col = eng->x_col;
        int y_col = eng->y_col;
        int w_col = eng->w_col;
        bool is_2d = eng->is_2d;
        bool has_w = eng->has_weights;

        for (size_t i = 0; i < batch_len; ++i) {
            size_t nc = batch_ncols[i];
            int v_idx = (val_col >= 1 && val_col <= (int)nc) ? val_col - 1 : 0;
            int x_idx = (x_col >= 1 && x_col <= (int)nc) ? x_col - 1 : 0;
            int y_idx = (y_col >= 1 && y_col <= (int)nc) ? y_col - 1 : (nc > 1 ? 1 : 0);
            int w_idx = (w_col >= 1 && w_col <= (int)nc) ? w_col - 1 : -1;

            batch_w[i] = (w_idx >= 0) ? batch_cols[i][w_idx] : 1.0;
            if (is_2d) {
                batch_x[i] = batch_cols[i][x_idx];
                batch_y[i] = batch_cols[i][y_idx];
            } else {
                batch_x[i] = batch_cols[i][v_idx];
                batch_y[i] = 0.0;
            }
        }

        if (is_2d && eng->live_2d) {
            for (size_t i = 0; i < batch_len; ++i) {
                histo2d_fill_w(eng->live_2d, batch_x[i], batch_y[i], batch_w[i]);
            }
        } else if (eng->live_1d) {
            if (has_w) {
                histo_fill_n(eng->live_1d, batch_len, batch_x, batch_w);
            } else {
                histo_fill_n(eng->live_1d, batch_len, batch_x, NULL);
            }
        }
        reservoir_push_batch(&eng->reservoir, (const double (*)[TUI_MAX_COLS])batch_cols, batch_ncols, batch_w, batch_len);
        eng->total_samples += batch_len;
        histo_mutex_unlock(&eng->mutex);
        batch_len = 0;
    }

    free(batch_x);
    free(batch_y);
    free(batch_w);
    free(batch_cols);
    free(batch_ncols);
    free(raw_buf);
    return NULL;
}

bool tui_engine_init(tui_engine_t *eng, FILE *in_stream, bool is_2d, uint32_t nbins, double rmin, double rmax, uint32_t flags, bool has_weights) {
    if (!eng) return false;
    memset(eng, 0, sizeof(*eng));

    eng->in_stream = in_stream;
    eng->is_2d = is_2d;
    eng->has_weights = has_weights;
    eng->val_col = 1;
    eng->x_col = 1;
    eng->y_col = 2;
    eng->w_col = has_weights ? 2 : 0;
    eng->flags = flags;
    eng->scale_input = 1.0;
    eng->running = false;
    eng->finished_reading = false;
    eng->paused = false;
    eng->window_size = 0;
    eng->decay_lambda = 0.0;
    eng->last_decay_time = get_time_now_sec();

    if (rmin >= rmax) {
        rmin = 0.0;
        rmax = 100.0;
    }
    if (nbins == 0) nbins = 50;

    histo_mutex_init(&eng->mutex);

    if (is_2d) {
        eng->live_2d = histo2d_create_uniform(nbins, rmin, rmax, nbins, rmin, rmax, flags);
    } else {
        eng->live_1d = histo_create_uniform(nbins, rmin, rmax, flags);
    }

    reservoir_init(&eng->reservoir, TUI_RESERVOIR_DEFAULT_CAP, is_2d, eng->has_weights);
    eng->auto_range = true;
    eng->auto_range_threshold = 0.05;
    eng->last_autorange_time_sec = get_time_now_sec();
    return true;
}

bool tui_engine_init_shm(tui_engine_t *eng, const char *shm_path, bool is_2d, uint32_t nbins, double rmin, double rmax, uint32_t flags) {
    if (!eng || !shm_path) return false;
    memset(eng, 0, sizeof(*eng));

    if (!histo_shm_open(&eng->shm, shm_path)) {
        return false;
    }

    eng->is_shm = true;
    eng->is_2d = is_2d;
    eng->has_weights = false;
    eng->val_col = 1;
    eng->x_col = 1;
    eng->y_col = 2;
    eng->w_col = 0;
    eng->flags = flags;
    eng->scale_input = 1.0;
    eng->running = false;
    eng->finished_reading = false;
    eng->paused = false;
    eng->window_size = 0;
    eng->decay_lambda = 0.0;
    eng->last_decay_time = get_time_now_sec();

    if (rmin >= rmax) {
        rmin = 0.0;
        rmax = 100.0;
    }
    if (nbins == 0) nbins = 50;

    histo_mutex_init(&eng->mutex);

    if (is_2d) {
        eng->live_2d = histo2d_create_uniform(nbins, rmin, rmax, nbins, rmin, rmax, flags);
    } else {
        eng->live_1d = histo_create_uniform(nbins, rmin, rmax, flags);
    }

    reservoir_init(&eng->reservoir, TUI_RESERVOIR_DEFAULT_CAP, is_2d, false);
    eng->auto_range = true;
    eng->auto_range_threshold = 0.05;
    eng->last_autorange_time_sec = get_time_now_sec();
    return true;
}

void tui_engine_set_scale_input(tui_engine_t *eng, double scale_input) {
    if (!eng) return;
    histo_mutex_lock(&eng->mutex);
    eng->scale_input = (scale_input > 0.0) ? scale_input : 1.0;
    histo_mutex_unlock(&eng->mutex);
}

void tui_engine_set_binary(tui_engine_t *eng, bool is_binary) {
    if (!eng) return;
    histo_mutex_lock(&eng->mutex);
    eng->is_binary = is_binary;
    histo_mutex_unlock(&eng->mutex);
}

bool tui_engine_start(tui_engine_t *eng) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    if (eng->thread_started) {
        histo_mutex_unlock(&eng->mutex);
        return true;
    }
    eng->running = true;
    eng->last_time_sec = get_time_now_sec();
    if (histo_thread_create(&eng->thread, ingest_worker_thread, eng) != 0) {
        eng->running = false;
        histo_mutex_unlock(&eng->mutex);
        return false;
    }
    eng->thread_started = true;
    histo_mutex_unlock(&eng->mutex);
    return true;
}

void tui_engine_stop(tui_engine_t *eng) {
    if (!eng) return;
    histo_mutex_lock(&eng->mutex);
    if (!eng->thread_started) {
        eng->running = false;
        histo_mutex_unlock(&eng->mutex);
        return;
    }
    eng->running = false;
    eng->thread_started = false;
    histo_thread_t th = eng->thread;
    histo_mutex_unlock(&eng->mutex);
    histo_thread_join(th);
}

void tui_engine_free(tui_engine_t *eng) {
    if (!eng) return;
    tui_engine_stop(eng);
    histo_mutex_lock(&eng->mutex);
    if (eng->live_1d) {
        histo_destroy(eng->live_1d);
        eng->live_1d = NULL;
    }
    if (eng->live_2d) {
        histo2d_destroy(eng->live_2d);
        eng->live_2d = NULL;
    }
    reservoir_free(&eng->reservoir);
    if (eng->is_shm) {
        histo_shm_close(&eng->shm);
    }
    histo_mutex_unlock(&eng->mutex);
    histo_mutex_destroy(&eng->mutex);
}

static int double_cmp(const void *a, const void *b) {
    double da = *(const double *)a;
    double db = *(const double *)b;
    if (isnan(da)) return isnan(db) ? 0 : 1;
    if (isnan(db)) return -1;
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

static bool tui_engine_check_and_autorange_locked(tui_engine_t *eng) {
    if (!eng || !eng->auto_range || !eng->live_1d || eng->reservoir.count < 50) {
        return false;
    }

    double now = get_time_now_sec();
    if (now - eng->last_autorange_time_sec < 1.0) {
        return false;
    }

    double in_range_w = histo_total_weight(eng->live_1d);
    double underflow_w = histo_underflow(eng->live_1d);
    double overflow_w = histo_overflow(eng->live_1d);
    double total_w = in_range_w + underflow_w + overflow_w;
    if (total_w <= 0.0) return false;

    double bad_ratio = (underflow_w + overflow_w) / total_w;
    if (bad_ratio <= eng->auto_range_threshold) {
        return false;
    }

    eng->last_autorange_time_sec = now;

    size_t count = eng->reservoir.count;
    double *tmp_x = (double *)malloc(count * sizeof(double));
    double *tmp_w = (double *)malloc(count * sizeof(double));
    if (!tmp_x || !tmp_w) {
        if (tmp_x) free(tmp_x);
        if (tmp_w) free(tmp_w);
        return false;
    }

    size_t win_n = get_reservoir_window(eng, tmp_x, NULL, tmp_w, eng->val_col, 0);
    if (win_n < 10) {
        free(tmp_x);
        free(tmp_w);
        return false;
    }

    double *sorted = (double *)malloc(win_n * sizeof(double));
    if (!sorted) {
        free(tmp_x);
        free(tmp_w);
        return false;
    }
    memcpy(sorted, tmp_x, win_n * sizeof(double));
    qsort(sorted, win_n, sizeof(double), double_cmp);

    size_t idx_p01 = (size_t)(win_n * 0.01);
    size_t idx_p99 = (size_t)(win_n * 0.99);
    if (idx_p99 >= win_n) idx_p99 = win_n - 1;

    double n_min = sorted[idx_p01];
    double n_max = sorted[idx_p99];
    free(sorted);

    if (n_max <= n_min || isnan(n_min) || isnan(n_max) || isinf(n_min) || isinf(n_max)) {
        free(tmp_x);
        free(tmp_w);
        return false;
    }

    double pad = (n_max - n_min) * 0.05;
    if (pad <= 0.0) pad = 1.0;
    n_min -= pad;
    n_max += pad;

    uint32_t nbins = histo_nbins(eng->live_1d);
    histo_t *new_h = histo_create_uniform(nbins, n_min, n_max, eng->flags);
    if (!new_h) {
        free(tmp_x);
        free(tmp_w);
        return false;
    }

    if (eng->has_weights) {
        histo_fill_n(new_h, win_n, tmp_x, tmp_w);
    } else {
        histo_fill_n(new_h, win_n, tmp_x, NULL);
    }

    histo_destroy(eng->live_1d);
    eng->live_1d = new_h;

    free(tmp_x);
    free(tmp_w);
    return true;
}

bool tui_engine_check_and_autorange(tui_engine_t *eng) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    bool changed = tui_engine_check_and_autorange_locked(eng);
    histo_mutex_unlock(&eng->mutex);
    return changed;
}

void tui_engine_set_autorange(tui_engine_t *eng, bool enable, double threshold) {
    if (!eng) return;
    histo_mutex_lock(&eng->mutex);
    eng->auto_range = enable;
    if (threshold > 0.0) eng->auto_range_threshold = threshold;
    histo_mutex_unlock(&eng->mutex);
}

histo_t *tui_engine_get_snapshot_1d(tui_engine_t *eng) {
    if (!eng) return NULL;
    histo_mutex_lock(&eng->mutex);
    tui_engine_check_and_autorange_locked(eng);
    histo_t *snap = eng->live_1d ? histo_clone(eng->live_1d, false) : NULL;
    histo_mutex_unlock(&eng->mutex);
    return snap;
}

histo2d_t *tui_engine_get_snapshot_2d(tui_engine_t *eng) {
    if (!eng) return NULL;
    histo_mutex_lock(&eng->mutex);
    histo2d_t *snap = eng->live_2d ? histo2d_clone(eng->live_2d, false) : NULL;
    histo_mutex_unlock(&eng->mutex);
    return snap;
}

bool tui_engine_rebuild_1d(tui_engine_t *eng, uint32_t nbins, double rmin, double rmax, histo_t **out_h) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);

    size_t count = eng->reservoir.count;
    if (count == 0 && !eng->live_1d) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    if (rmin >= rmax) {
        if (eng->live_1d) {
            histo_range(eng->live_1d, &rmin, &rmax);
        } else {
            rmin = 0.0; rmax = 100.0;
        }
    }
    if (nbins == 0) nbins = 50;

    histo_t *new_h = histo_create_uniform(nbins, rmin, rmax, eng->flags);
    if (!new_h) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    if (count > 0) {
        double *tmp_x = (double *)malloc(count * sizeof(double));
        double *tmp_w = (double *)malloc(count * sizeof(double));
        if (tmp_x && tmp_w) {
            size_t win_n = get_reservoir_window(eng, tmp_x, NULL, tmp_w, eng->val_col, 0);
            if (eng->has_weights) {
                histo_fill_n(new_h, win_n, tmp_x, tmp_w);
            } else {
                histo_fill_n(new_h, win_n, tmp_x, NULL);
            }
        }
        if (tmp_x) free(tmp_x);
        if (tmp_w) free(tmp_w);
    }

    if (eng->live_1d) histo_destroy(eng->live_1d);
    eng->live_1d = new_h;

    if (out_h) {
        *out_h = histo_clone(new_h, false);
    }

    histo_mutex_unlock(&eng->mutex);
    return true;
}

bool tui_engine_rebuild_1d_log(tui_engine_t *eng, uint32_t nbins, histo_t **out_h) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);

    size_t count = eng->reservoir.count;
    double rmin = 0.1, rmax = 100.0;
    if (count > 0) {
        double *tmp_x = (double *)malloc(count * sizeof(double));
        if (tmp_x) {
            size_t win_n = get_reservoir_window(eng, tmp_x, NULL, NULL, eng->val_col, 0);
            bool found_pos = false;
            for (size_t i = 0; i < win_n; ++i) {
                if (tmp_x[i] > 0.0) {
                    if (!found_pos) {
                        rmin = tmp_x[i];
                        rmax = tmp_x[i];
                        found_pos = true;
                    } else {
                        if (tmp_x[i] < rmin) rmin = tmp_x[i];
                        if (tmp_x[i] > rmax) rmax = tmp_x[i];
                    }
                }
            }
            free(tmp_x);
        }
    }
    if (rmin <= 0.0) rmin = 1e-3;
    if (rmax <= rmin) rmax = rmin * 100.0;
    if (nbins == 0) nbins = 50;

    double *edges = (double *)malloc((nbins + 1) * sizeof(double));
    if (!edges) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    double log_min = log10(rmin);
    double log_max = log10(rmax * 1.000001);
    double step = (log_max - log_min) / (double)nbins;
    for (uint32_t i = 0; i <= nbins; ++i) {
        edges[i] = pow(10.0, log_min + i * step);
    }

    histo_t *new_h = histo_create_variable(nbins, edges, eng->flags);
    free(edges);
    if (!new_h) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    if (count > 0) {
        double *tmp_x = (double *)malloc(count * sizeof(double));
        double *tmp_w = (double *)malloc(count * sizeof(double));
        if (tmp_x && tmp_w) {
            size_t win_n = get_reservoir_window(eng, tmp_x, NULL, tmp_w, eng->val_col, 0);
            if (eng->has_weights) {
                histo_fill_n(new_h, win_n, tmp_x, tmp_w);
            } else {
                histo_fill_n(new_h, win_n, tmp_x, NULL);
            }
        }
        if (tmp_x) free(tmp_x);
        if (tmp_w) free(tmp_w);
    }

    if (eng->live_1d) histo_destroy(eng->live_1d);
    eng->live_1d = new_h;

    if (out_h) {
        *out_h = histo_clone(new_h, false);
    }

    histo_mutex_unlock(&eng->mutex);
    return true;
}

bool tui_engine_zoom_1d(tui_engine_t *eng, double factor, histo_t **out_h) {
    if (!eng || factor <= 0.0) return false;
    histo_mutex_lock(&eng->mutex);
    histo_t *source = eng->live_1d;
    if (!source) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }
    double rmin, rmax;
    histo_range(source, &rmin, &rmax);
    uint32_t nb = histo_nbins(source);

    double center = 0.5 * (rmin + rmax);
    double half_span = 0.5 * (rmax - rmin) * factor;
    if (half_span < 1e-12) half_span = 1.0;

    double n_min = center - half_span;
    double n_max = center + half_span;

    eng->auto_range = false;
    histo_mutex_unlock(&eng->mutex);

    return tui_engine_rebuild_1d(eng, nb, n_min, n_max, out_h);
}

bool tui_engine_pan_1d(tui_engine_t *eng, double fraction, histo_t **out_h) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    histo_t *source = eng->live_1d;
    if (!source) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }
    double rmin, rmax;
    histo_range(source, &rmin, &rmax);
    uint32_t nb = histo_nbins(source);

    double shift = (rmax - rmin) * fraction;
    double n_min = rmin + shift;
    double n_max = rmax + shift;

    eng->auto_range = false;
    histo_mutex_unlock(&eng->mutex);

    return tui_engine_rebuild_1d(eng, nb, n_min, n_max, out_h);
}

bool tui_engine_rebuild_2d(tui_engine_t *eng, uint32_t xbins, double xmin, double xmax, uint32_t ybins, double ymin, double ymax, histo2d_t **out_h) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);

    size_t count = eng->reservoir.count;
    if (count == 0 && !eng->live_2d) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    if (xmin >= xmax || ymin >= ymax) {
        if (eng->live_2d) {
            histo2d_axis_t ax, ay;
            histo2d_axis_x(eng->live_2d, &ax);
            histo2d_axis_y(eng->live_2d, &ay);
            xmin = ax.min; xmax = ax.max;
            ymin = ay.min; ymax = ay.max;
        } else {
            xmin = 0.0; xmax = 100.0;
            ymin = 0.0; ymax = 100.0;
        }
    }
    if (xbins == 0) xbins = 50;
    if (ybins == 0) ybins = 50;

    histo2d_t *new_h = histo2d_create_uniform(xbins, xmin, xmax, ybins, ymin, ymax, eng->flags);
    if (!new_h) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    if (count > 0) {
        double *tmp_x = (double *)malloc(count * sizeof(double));
        double *tmp_y = (double *)malloc(count * sizeof(double));
        double *tmp_w = (double *)malloc(count * sizeof(double));
        if (tmp_x && tmp_y && tmp_w) {
            size_t win_n = get_reservoir_window(eng, tmp_x, tmp_y, tmp_w, eng->x_col, eng->y_col);
            for (size_t i = 0; i < win_n; ++i) {
                histo2d_fill_w(new_h, tmp_x[i], tmp_y[i], tmp_w[i]);
            }
        }
        if (tmp_x) free(tmp_x);
        if (tmp_y) free(tmp_y);
        if (tmp_w) free(tmp_w);
    }

    if (eng->live_2d) histo2d_destroy(eng->live_2d);
    eng->live_2d = new_h;

    if (out_h) {
        *out_h = histo2d_clone(new_h, false);
    }

    histo_mutex_unlock(&eng->mutex);
    return true;
}

bool tui_engine_zoom_2d(tui_engine_t *eng, double factor, histo2d_t **out_h) {
    if (!eng || factor <= 0.0) return false;
    histo_mutex_lock(&eng->mutex);
    histo2d_t *source = eng->live_2d;
    if (!source) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }
    histo2d_axis_t ax, ay;
    histo2d_axis_x(source, &ax);
    histo2d_axis_y(source, &ay);
    uint32_t nx = histo2d_nbins_x(source);
    uint32_t ny = histo2d_nbins_y(source);

    double cx = 0.5 * (ax.min + ax.max);
    double cy = 0.5 * (ay.min + ay.max);
    double hx = 0.5 * (ax.max - ax.min) * factor;
    double hy = 0.5 * (ay.max - ay.min) * factor;
    if (hx < 1e-12) hx = 1.0;
    if (hy < 1e-12) hy = 1.0;

    double n_xmin = cx - hx, n_xmax = cx + hx;
    double n_ymin = cy - hy, n_ymax = cy + hy;

    eng->auto_range = false;
    histo_mutex_unlock(&eng->mutex);

    return tui_engine_rebuild_2d(eng, nx, n_xmin, n_xmax, ny, n_ymin, n_ymax, out_h);
}

bool tui_engine_pan_2d(tui_engine_t *eng, double frac_x, double frac_y, histo2d_t **out_h) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    histo2d_t *source = eng->live_2d;
    if (!source) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }
    histo2d_axis_t ax, ay;
    histo2d_axis_x(source, &ax);
    histo2d_axis_y(source, &ay);
    uint32_t nx = histo2d_nbins_x(source);
    uint32_t ny = histo2d_nbins_y(source);

    double shift_x = (ax.max - ax.min) * frac_x;
    double shift_y = (ay.max - ay.min) * frac_y;

    double n_xmin = ax.min + shift_x, n_xmax = ax.max + shift_x;
    double n_ymin = ay.min + shift_y, n_ymax = ay.max + shift_y;

    eng->auto_range = false;
    histo_mutex_unlock(&eng->mutex);

    return tui_engine_rebuild_2d(eng, nx, n_xmin, n_xmax, ny, n_ymin, n_ymax, out_h);
}

bool tui_engine_set_column(tui_engine_t *eng, int val_col, int x_col, int y_col, histo_t **out_1d, histo2d_t **out_2d) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    if (val_col > 0) eng->val_col = val_col;
    if (x_col > 0) eng->x_col = x_col;
    if (y_col > 0) eng->y_col = y_col;
    histo_mutex_unlock(&eng->mutex);

    if (eng->is_2d) {
        uint32_t nx = 50, ny = 50;
        double xmin = 0, xmax = 100, ymin = 0, ymax = 100;
        if (eng->live_2d) {
            histo2d_axis_t ax, ay;
            histo2d_axis_x(eng->live_2d, &ax);
            histo2d_axis_y(eng->live_2d, &ay);
            nx = histo2d_nbins_x(eng->live_2d);
            ny = histo2d_nbins_y(eng->live_2d);
            xmin = ax.min; xmax = ax.max;
            ymin = ay.min; ymax = ay.max;
        }
        return tui_engine_rebuild_2d(eng, nx, xmin, xmax, ny, ymin, ymax, out_2d);
    } else {
        uint32_t nbins = eng->live_1d ? histo_nbins(eng->live_1d) : 50;
        double rmin = 0, rmax = 0;
        if (eng->live_1d) histo_range(eng->live_1d, &rmin, &rmax);
        return tui_engine_rebuild_1d(eng, nbins, rmin, rmax, out_1d);
    }
}

bool tui_engine_set_window(tui_engine_t *eng, size_t window_size, histo_t **out_1d, histo2d_t **out_2d) {
    if (!eng) return false;
    histo_mutex_lock(&eng->mutex);
    eng->window_size = window_size;
    histo_mutex_unlock(&eng->mutex);

    if (eng->is_2d) {
        uint32_t nx = 50, ny = 50;
        double xmin = 0, xmax = 100, ymin = 0, ymax = 100;
        if (eng->live_2d) {
            histo2d_axis_t ax, ay;
            histo2d_axis_x(eng->live_2d, &ax);
            histo2d_axis_y(eng->live_2d, &ay);
            nx = histo2d_nbins_x(eng->live_2d);
            ny = histo2d_nbins_y(eng->live_2d);
            xmin = ax.min; xmax = ax.max;
            ymin = ay.min; ymax = ay.max;
        }
        return tui_engine_rebuild_2d(eng, nx, xmin, xmax, ny, ymin, ymax, out_2d);
    } else {
        uint32_t nbins = eng->live_1d ? histo_nbins(eng->live_1d) : 50;
        double rmin = 0, rmax = 0;
        if (eng->live_1d) histo_range(eng->live_1d, &rmin, &rmax);
        return tui_engine_rebuild_1d(eng, nbins, rmin, rmax, out_1d);
    }
}

void tui_engine_set_decay(tui_engine_t *eng, double decay_lambda) {
    if (!eng) return;
    histo_mutex_lock(&eng->mutex);
    eng->decay_lambda = (decay_lambda >= 0.0) ? decay_lambda : 0.0;
    eng->last_decay_time = get_time_now_sec();
    histo_mutex_unlock(&eng->mutex);
}

bool tui_engine_export_snapshot(tui_engine_t *eng, const char *filepath, bool is_json) {
    if (!eng || !filepath) return false;
    histo_mutex_lock(&eng->mutex);

    FILE *out = fopen(filepath, "wb");
    if (!out) {
        histo_mutex_unlock(&eng->mutex);
        return false;
    }

    bool ok = false;
    if (eng->is_2d) {
        if (eng->live_2d) {
            if (is_json || strstr(filepath, ".json") != NULL) {
                char *json = NULL;
                size_t sz = 0;
                if (histo2d_serialize_json_alloc(eng->live_2d, &json, &sz) == HISTO_OK && json) {
                    ok = (fwrite(json, 1, sz, out) == sz);
                    histo_free_buffer(json);
                }
            } else {
                void *bin = NULL;
                size_t sz = 0;
                if (histo2d_serialize_binary_alloc(eng->live_2d, &bin, &sz) == HISTO_OK && bin) {
                    ok = (fwrite(bin, 1, sz, out) == sz);
                    histo_free_buffer(bin);
                }
            }
        }
    } else {
        if (eng->live_1d) {
            if (is_json || strstr(filepath, ".json") != NULL) {
                char *json = NULL;
                if (histo_serialize_json(eng->live_1d, &json) == HISTO_OK && json) {
                    size_t len = strlen(json);
                    ok = (fwrite(json, 1, len, out) == len);
                    histo_free_buffer(json);
                }
            } else {
                void *bin = NULL;
                size_t sz = 0;
                if (histo_serialize_binary(eng->live_1d, &bin, &sz) == HISTO_OK && bin) {
                    ok = (fwrite(bin, 1, sz, out) == sz);
                    histo_free_buffer(bin);
                }
            }
        }
    }

    fclose(out);
    histo_mutex_unlock(&eng->mutex);
    return ok;
}

void tui_engine_clear(tui_engine_t *eng) {
    if (!eng) return;
    histo_mutex_lock(&eng->mutex);
    if (eng->live_1d) histo_reset(eng->live_1d);
    if (eng->live_2d) histo2d_reset(eng->live_2d);
    eng->reservoir.count = 0;
    eng->reservoir.head = 0;
    eng->total_samples = 0;
    eng->current_rate_ops = 0.0;
    histo_mutex_unlock(&eng->mutex);
}

bool tui_engine_is_finished(tui_engine_t *eng) {
    if (!eng) return true;
    histo_mutex_lock(&eng->mutex);
    bool fin = eng->finished_reading;
    histo_mutex_unlock(&eng->mutex);
    return fin;
}
