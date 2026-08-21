/**
 * @file serialize_2d.c
 * @brief Canonical Little-Endian V3 and JSON serialization for 2D histograms.
 */

#include "histo/histo2d.h"
#include "internal_2d.h"
#include "vendor/cJSON/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HISTO2D_MAGIC_LEN 8
static const uint8_t HISTO2D_MAGIC[HISTO2D_MAGIC_LEN] = {0x89, 'L', 'H', 'I', 'S', 'T', 0x0A, 0x00};

#define HISTO2D_FORMAT_VERSION 3
#define HISTO2D_HEADER_SIZE    256

/* Wire bit flags for 2D V3 format */
#define HISTO2D_WIRE_FLAG_VAR_X        (1u << 0)
#define HISTO2D_WIRE_FLAG_VAR_Y        (1u << 1)
#define HISTO2D_WIRE_FLAG_SUMW2        (1u << 2)
#define HISTO2D_WIRE_FLAG_EXACT_MOMENTS (1u << 3)

static size_t histo2d_calculate_binary_size(const histo2d_t *h) {
    if (!h) return 0;
    size_t sz = HISTO2D_HEADER_SIZE;

    if (h->x_axis.bin_type == HISTO_BIN_VARIABLE) {
        sz += (size_t)(h->x_axis.nbins + 1) * sizeof(double);
    }
    if (h->y_axis.bin_type == HISTO_BIN_VARIABLE) {
        sz += (size_t)(h->y_axis.nbins + 1) * sizeof(double);
    }

    size_t total_cells = (size_t)h->x_axis.nbins * (size_t)h->y_axis.nbins;
    sz += total_cells * sizeof(double); /* bins */
    if (h->sum_w2) {
        sz += total_cells * sizeof(double); /* sum_w2 */
    }

    /* 9 guard regions */
    sz += (size_t)HISTO2D_REGION_COUNT * sizeof(double);   /* guard weights */
    if (h->sum_w2) {
        sz += (size_t)HISTO2D_REGION_COUNT * sizeof(double); /* guard sum_w2 */
    }
    sz += (size_t)HISTO2D_REGION_COUNT * sizeof(uint64_t); /* guard counts */

    return sz;
}

histo_status_t histo2d_serialize_binary(const histo2d_t *h, void *buf,
                                        size_t buf_size, size_t *out_size)
{
    if (!h) return HISTO_ERR_INVALID_ARG;
    size_t req_size = histo2d_calculate_binary_size(h);
    if (out_size) *out_size = req_size;

    if (!buf || buf_size < req_size) {
        return HISTO_ERR_SERIALIZATION;
    }

    uint8_t *p = (uint8_t*)buf;
    memset(p, 0, HISTO2D_HEADER_SIZE);

    /* 0x00 - 0x07: Magic */
    memcpy(p + 0x00, HISTO2D_MAGIC, HISTO2D_MAGIC_LEN);

    /* 0x08 - 0x09: Version (0x0003) */
    uint16_t version_le = histo_htole16(HISTO2D_FORMAT_VERSION);
    memcpy(p + 0x08, &version_le, sizeof(uint16_t));

    /* 0x0A - 0x0B: Header Size (0x0100 = 256) */
    uint16_t header_sz_le = histo_htole16(HISTO2D_HEADER_SIZE);
    memcpy(p + 0x0A, &header_sz_le, sizeof(uint16_t));

    /* 0x0C - 0x0F: Flags */
    uint32_t wire_flags = 0;
    if (h->x_axis.bin_type == HISTO_BIN_VARIABLE) wire_flags |= HISTO2D_WIRE_FLAG_VAR_X;
    if (h->y_axis.bin_type == HISTO_BIN_VARIABLE) wire_flags |= HISTO2D_WIRE_FLAG_VAR_Y;
    if (h->sum_w2) wire_flags |= HISTO2D_WIRE_FLAG_SUMW2;
    if (h->flags & HISTO_FLAG_EXACT_MOMENTS) wire_flags |= HISTO2D_WIRE_FLAG_EXACT_MOMENTS;
    uint32_t flags_le = histo_htole32(wire_flags);
    memcpy(p + 0x0C, &flags_le, sizeof(uint32_t));

    /* 0x10 - 0x13: nx */
    uint32_t nx_le = histo_htole32(h->x_axis.nbins);
    memcpy(p + 0x10, &nx_le, sizeof(uint32_t));

    /* 0x14 - 0x17: ny */
    uint32_t ny_le = histo_htole32(h->y_axis.nbins);
    memcpy(p + 0x14, &ny_le, sizeof(uint32_t));

    /* 0x18 - 0x1B: x_bin_type */
    uint32_t xtype_le = histo_htole32((uint32_t)h->x_axis.bin_type);
    memcpy(p + 0x18, &xtype_le, sizeof(uint32_t));

    /* 0x1C - 0x1F: y_bin_type */
    uint32_t ytype_le = histo_htole32((uint32_t)h->y_axis.bin_type);
    memcpy(p + 0x1C, &ytype_le, sizeof(uint32_t));

    /* 0x20 - 0x27: xmin */
    double xmin_le = histo_dtole(h->x_axis.min);
    memcpy(p + 0x20, &xmin_le, sizeof(double));

    /* 0x28 - 0x2F: xmax */
    double xmax_le = histo_dtole(h->x_axis.max);
    memcpy(p + 0x28, &xmax_le, sizeof(double));

    /* 0x30 - 0x37: ymin */
    double ymin_le = histo_dtole(h->y_axis.min);
    memcpy(p + 0x30, &ymin_le, sizeof(double));

    /* 0x38 - 0x3F: ymax */
    double ymax_le = histo_dtole(h->y_axis.max);
    memcpy(p + 0x38, &ymax_le, sizeof(double));

    /* 0x40 - 0x47: total_weight */
    double tot_w_le = histo_dtole(h->total_weight);
    memcpy(p + 0x40, &tot_w_le, sizeof(double));

    /* 0x48 - 0x4F: total_sum_w2 */
    double tot_w2_le = histo_dtole(h->total_sum_w2);
    memcpy(p + 0x48, &tot_w2_le, sizeof(double));

    /* 0x50 - 0x57: n_fills */
    uint64_t n_fills_le = histo_htole64(h->n_fills);
    memcpy(p + 0x50, &n_fills_le, sizeof(uint64_t));

    /* 0x58 - 0x5F: n_nan */
    uint64_t n_nan_le = histo_htole64(h->n_nan);
    memcpy(p + 0x58, &n_nan_le, sizeof(uint64_t));

    /* 0x60 - 0x67: stats_mean_x */
    double smx_le = histo_dtole(h->stats_mean_x);
    memcpy(p + 0x60, &smx_le, sizeof(double));

    /* 0x68 - 0x6F: stats_mean_y */
    double smy_le = histo_dtole(h->stats_mean_y);
    memcpy(p + 0x68, &smy_le, sizeof(double));

    /* 0x70 - 0x77: stats_M2_x */
    double sm2x_le = histo_dtole(h->stats_M2_x);
    memcpy(p + 0x70, &sm2x_le, sizeof(double));

    /* 0x78 - 0x7F: stats_M2_y */
    double sm2y_le = histo_dtole(h->stats_M2_y);
    memcpy(p + 0x78, &sm2y_le, sizeof(double));

    /* 0x80 - 0x87: stats_C_xy */
    double scxy_le = histo_dtole(h->stats_C_xy);
    memcpy(p + 0x80, &scxy_le, sizeof(double));

    /* 0x88 - 0x8F: stats_min_x */
    double sminx_le = histo_dtole(h->stats_min_x);
    memcpy(p + 0x88, &sminx_le, sizeof(double));

    /* 0x90 - 0x97: stats_max_x */
    double smaxx_le = histo_dtole(h->stats_max_x);
    memcpy(p + 0x90, &smaxx_le, sizeof(double));

    /* 0x98 - 0x9F: stats_min_y */
    double sminy_le = histo_dtole(h->stats_min_y);
    memcpy(p + 0x98, &sminy_le, sizeof(double));

    /* 0xA0 - 0xA7: stats_max_y */
    double smaxy_le = histo_dtole(h->stats_max_y);
    memcpy(p + 0xA0, &smaxy_le, sizeof(double));

    /* Write Payloads starting at 256 */
    uint8_t *cur = p + HISTO2D_HEADER_SIZE;

    /* 1. X Edges */
    if (h->x_axis.bin_type == HISTO_BIN_VARIABLE) {
        for (uint32_t i = 0; i <= h->x_axis.nbins; ++i) {
            double v_le = histo_dtole(h->x_axis.bin_edges[i]);
            memcpy(cur, &v_le, sizeof(double));
            cur += sizeof(double);
        }
    }

    /* 2. Y Edges */
    if (h->y_axis.bin_type == HISTO_BIN_VARIABLE) {
        for (uint32_t j = 0; j <= h->y_axis.nbins; ++j) {
            double v_le = histo_dtole(h->y_axis.bin_edges[j]);
            memcpy(cur, &v_le, sizeof(double));
            cur += sizeof(double);
        }
    }

    /* 3. Bins */
    size_t total_cells = (size_t)h->x_axis.nbins * (size_t)h->y_axis.nbins;
    for (size_t k = 0; k < total_cells; ++k) {
        double v_le = histo_dtole(h->bins[k]);
        memcpy(cur, &v_le, sizeof(double));
        cur += sizeof(double);
    }

    /* 4. Sum_w2 */
    if (h->sum_w2) {
        for (size_t k = 0; k < total_cells; ++k) {
            double v_le = histo_dtole(h->sum_w2[k]);
            memcpy(cur, &v_le, sizeof(double));
            cur += sizeof(double);
        }
    }

    /* 5. Guard Weights */
    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        double v_le = histo_dtole(h->guards[r].weight);
        memcpy(cur, &v_le, sizeof(double));
        cur += sizeof(double);
    }

    /* 6. Guard Sum_w2 */
    if (h->sum_w2) {
        for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
            double v_le = histo_dtole(h->guards[r].sum_w2);
            memcpy(cur, &v_le, sizeof(double));
            cur += sizeof(double);
        }
    }

    /* 7. Guard Counts */
    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        uint64_t c_le = histo_htole64(h->guards[r].count);
        memcpy(cur, &c_le, sizeof(uint64_t));
        cur += sizeof(uint64_t);
    }

    return HISTO_OK;
}

histo_status_t histo2d_serialize_binary_alloc(const histo2d_t *h, void **out_buf,
                                              size_t *out_size)
{
    if (!h || !out_buf) return HISTO_ERR_INVALID_ARG;
    size_t sz = histo2d_calculate_binary_size(h);
    void *buf = malloc(sz);
    if (!buf) return HISTO_ERR_NOMEM;

    histo_status_t status = histo2d_serialize_binary(h, buf, sz, out_size);
    if (status != HISTO_OK) {
        free(buf);
        return status;
    }

    *out_buf = buf;
    return HISTO_OK;
}

histo_status_t histo2d_deserialize_binary(const void *buf, size_t size,
                                          histo2d_t **out_h)
{
    if (!buf || !out_h || size < HISTO2D_HEADER_SIZE) {
        return HISTO_ERR_INVALID_ARG;
    }

    const uint8_t *p = (const uint8_t*)buf;

    /* Verify Magic */
    if (memcmp(p, HISTO2D_MAGIC, HISTO2D_MAGIC_LEN) != 0) {
        return HISTO_ERR_DESERIALIZATION;
    }

    uint16_t version_raw, header_sz_raw;
    memcpy(&version_raw, p + 0x08, sizeof(uint16_t));
    memcpy(&header_sz_raw, p + 0x0A, sizeof(uint16_t));

    uint16_t version = histo_le16toh(version_raw);
    uint16_t header_sz = histo_le16toh(header_sz_raw);

    if (version != HISTO2D_FORMAT_VERSION || header_sz != HISTO2D_HEADER_SIZE) {
        return HISTO_ERR_DESERIALIZATION;
    }

    uint32_t flags_raw, nx_raw, ny_raw, xtype_raw, ytype_raw;
    memcpy(&flags_raw, p + 0x0C, sizeof(uint32_t));
    memcpy(&nx_raw, p + 0x10, sizeof(uint32_t));
    memcpy(&ny_raw, p + 0x14, sizeof(uint32_t));
    memcpy(&xtype_raw, p + 0x18, sizeof(uint32_t));
    memcpy(&ytype_raw, p + 0x1C, sizeof(uint32_t));

    uint32_t wire_flags = histo_le32toh(flags_raw);
    uint32_t nx = histo_le32toh(nx_raw);
    uint32_t ny = histo_le32toh(ny_raw);
    uint32_t xtype = histo_le32toh(xtype_raw);
    uint32_t ytype = histo_le32toh(ytype_raw);

    if (nx == 0 || nx > HISTO_MAX_NBINS || ny == 0 || ny > HISTO_MAX_NBINS) {
        return HISTO_ERR_DESERIALIZATION;
    }

    uint64_t total_cells = (uint64_t)nx * (uint64_t)ny;
    if (total_cells > HISTO_MAX_NBINS) {
        return HISTO_ERR_DESERIALIZATION;
    }

    double xmin, xmax, ymin, ymax;
    memcpy(&xmin, p + 0x20, sizeof(double)); xmin = histo_dtole(xmin);
    memcpy(&xmax, p + 0x28, sizeof(double)); xmax = histo_dtole(xmax);
    memcpy(&ymin, p + 0x30, sizeof(double)); ymin = histo_dtole(ymin);
    memcpy(&ymax, p + 0x38, sizeof(double)); ymax = histo_dtole(ymax);

    if (!isfinite(xmin) || !isfinite(xmax) || xmin >= xmax ||
        !isfinite(ymin) || !isfinite(ymax) || ymin >= ymax)
    {
        return HISTO_ERR_DESERIALIZATION;
    }

    const uint8_t *cur = p + HISTO2D_HEADER_SIZE;
    double *xedges = NULL;
    double *yedges = NULL;

    if (xtype == HISTO_BIN_VARIABLE) {
        size_t xedge_bytes = (size_t)(nx + 1) * sizeof(double);
        if ((size_t)(cur - p) + xedge_bytes > size) return HISTO_ERR_DESERIALIZATION;
        xedges = (double*)malloc(xedge_bytes);
        if (!xedges) return HISTO_ERR_NOMEM;
        for (uint32_t i = 0; i <= nx; ++i) {
            double v; memcpy(&v, cur, sizeof(double));
            xedges[i] = histo_dtole(v);
            cur += sizeof(double);
        }
    }

    if (ytype == HISTO_BIN_VARIABLE) {
        size_t yedge_bytes = (size_t)(ny + 1) * sizeof(double);
        if ((size_t)(cur - p) + yedge_bytes > size) {
            free(xedges);
            return HISTO_ERR_DESERIALIZATION;
        }
        yedges = (double*)malloc(yedge_bytes);
        if (!yedges) {
            free(xedges);
            return HISTO_ERR_NOMEM;
        }
        for (uint32_t j = 0; j <= ny; ++j) {
            double v; memcpy(&v, cur, sizeof(double));
            yedges[j] = histo_dtole(v);
            cur += sizeof(double);
        }
    }

    histo2d_axis_t x_axis = { (histo_bin_type_t)xtype, nx, xmin, xmax, xedges };
    histo2d_axis_t y_axis = { (histo_bin_type_t)ytype, ny, ymin, ymax, yedges };

    uint32_t lib_flags = 0;
    if (wire_flags & HISTO2D_WIRE_FLAG_SUMW2) lib_flags |= HISTO_FLAG_TRACK_SUMW2;
    if (wire_flags & HISTO2D_WIRE_FLAG_EXACT_MOMENTS) lib_flags |= HISTO_FLAG_EXACT_MOMENTS;

    histo2d_t *h = histo2d_create(&x_axis, &y_axis, lib_flags);
    free(xedges);
    free(yedges);
    if (!h) return HISTO_ERR_NOMEM;

    /* Read Bins */
    size_t bin_bytes = (size_t)total_cells * sizeof(double);
    if ((size_t)(cur - p) + bin_bytes > size) {
        histo2d_destroy(h);
        return HISTO_ERR_DESERIALIZATION;
    }
    for (size_t k = 0; k < total_cells; ++k) {
        double v; memcpy(&v, cur, sizeof(double));
        h->bins[k] = histo_dtole(v);
        cur += sizeof(double);
    }

    /* Read Sum_w2 */
    if (h->sum_w2) {
        if ((size_t)(cur - p) + bin_bytes > size) {
            histo2d_destroy(h);
            return HISTO_ERR_DESERIALIZATION;
        }
        for (size_t k = 0; k < total_cells; ++k) {
            double v; memcpy(&v, cur, sizeof(double));
            h->sum_w2[k] = histo_dtole(v);
            cur += sizeof(double);
        }
    }

    /* Read Guard Weights */
    size_t guard_d_bytes = (size_t)HISTO2D_REGION_COUNT * sizeof(double);
    if ((size_t)(cur - p) + guard_d_bytes > size) {
        histo2d_destroy(h);
        return HISTO_ERR_DESERIALIZATION;
    }
    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        double v; memcpy(&v, cur, sizeof(double));
        h->guards[r].weight = histo_dtole(v);
        cur += sizeof(double);
    }

    /* Read Guard Sum_w2 */
    if (h->sum_w2) {
        if ((size_t)(cur - p) + guard_d_bytes > size) {
            histo2d_destroy(h);
            return HISTO_ERR_DESERIALIZATION;
        }
        for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
            double v; memcpy(&v, cur, sizeof(double));
            h->guards[r].sum_w2 = histo_dtole(v);
            cur += sizeof(double);
        }
    }

    /* Read Guard Counts */
    size_t guard_c_bytes = (size_t)HISTO2D_REGION_COUNT * sizeof(uint64_t);
    if ((size_t)(cur - p) + guard_c_bytes > size) {
        histo2d_destroy(h);
        return HISTO_ERR_DESERIALIZATION;
    }
    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        uint64_t c; memcpy(&c, cur, sizeof(uint64_t));
        h->guards[r].count = histo_le64toh(c);
        cur += sizeof(uint64_t);
    }

    /* Header Totals */
    double tot_w, tot_w2;
    uint64_t n_fills, n_nan;
    memcpy(&tot_w, p + 0x40, sizeof(double)); h->total_weight = histo_dtole(tot_w);
    memcpy(&tot_w2, p + 0x48, sizeof(double)); h->total_sum_w2 = histo_dtole(tot_w2);
    memcpy(&n_fills, p + 0x50, sizeof(uint64_t)); h->n_fills = histo_le64toh(n_fills);
    memcpy(&n_nan, p + 0x58, sizeof(uint64_t)); h->n_nan = histo_le64toh(n_nan);

    /* Moments */
    double smx, smy, sm2x, sm2y, scxy, sminx, smaxx, sminy, smaxy;
    memcpy(&smx, p + 0x60, sizeof(double)); h->stats_mean_x = histo_dtole(smx);
    memcpy(&smy, p + 0x68, sizeof(double)); h->stats_mean_y = histo_dtole(smy);
    memcpy(&sm2x, p + 0x70, sizeof(double)); h->stats_M2_x = histo_dtole(sm2x);
    memcpy(&sm2y, p + 0x78, sizeof(double)); h->stats_M2_y = histo_dtole(sm2y);
    memcpy(&scxy, p + 0x80, sizeof(double)); h->stats_C_xy = histo_dtole(scxy);
    memcpy(&sminx, p + 0x88, sizeof(double)); h->stats_min_x = histo_dtole(sminx);
    memcpy(&smaxx, p + 0x90, sizeof(double)); h->stats_max_x = histo_dtole(smaxx);
    memcpy(&sminy, p + 0x98, sizeof(double)); h->stats_min_y = histo_dtole(sminy);
    memcpy(&smaxy, p + 0xA0, sizeof(double)); h->stats_max_y = histo_dtole(smaxy);

    *out_h = h;
    return HISTO_OK;
}

/* -------------------------------------------------------------------------
 * JSON Serialization & Deserialization
 * ------------------------------------------------------------------------- */

histo_status_t histo2d_serialize_json_alloc(const histo2d_t *h, char **out_str,
                                            size_t *out_size)
{
    if (!h || !out_str) return HISTO_ERR_INVALID_ARG;

    cJSON *root = cJSON_CreateObject();
    if (!root) return HISTO_ERR_NOMEM;

    cJSON_AddStringToObject(root, "schema", "libhisto2d-v1");

    /* X Axis */
    cJSON *x_axis = cJSON_CreateObject();
    cJSON_AddStringToObject(x_axis, "bin_type", (h->x_axis.bin_type == HISTO_BIN_UNIFORM) ? "uniform" : "variable");
    cJSON_AddNumberToObject(x_axis, "nbins", h->x_axis.nbins);
    cJSON_AddNumberToObject(x_axis, "min", h->x_axis.min);
    cJSON_AddNumberToObject(x_axis, "max", h->x_axis.max);
    if (h->x_axis.bin_type == HISTO_BIN_VARIABLE && h->x_axis.bin_edges) {
        cJSON *edges = cJSON_CreateDoubleArray(h->x_axis.bin_edges, (int)h->x_axis.nbins + 1);
        cJSON_AddItemToObject(x_axis, "edges", edges);
    }
    cJSON_AddItemToObject(root, "x_axis", x_axis);

    /* Y Axis */
    cJSON *y_axis = cJSON_CreateObject();
    cJSON_AddStringToObject(y_axis, "bin_type", (h->y_axis.bin_type == HISTO_BIN_UNIFORM) ? "uniform" : "variable");
    cJSON_AddNumberToObject(y_axis, "nbins", h->y_axis.nbins);
    cJSON_AddNumberToObject(y_axis, "min", h->y_axis.min);
    cJSON_AddNumberToObject(y_axis, "max", h->y_axis.max);
    if (h->y_axis.bin_type == HISTO_BIN_VARIABLE && h->y_axis.bin_edges) {
        cJSON *edges = cJSON_CreateDoubleArray(h->y_axis.bin_edges, (int)h->y_axis.nbins + 1);
        cJSON_AddItemToObject(y_axis, "edges", edges);
    }
    cJSON_AddItemToObject(root, "y_axis", y_axis);

    cJSON_AddNumberToObject(root, "flags", h->flags);
    cJSON_AddNumberToObject(root, "nan_count", (double)h->n_nan);

    /* Guard Regions */
    static const char *region_names[HISTO2D_REGION_COUNT] = {
        "center", "east", "north", "south", "west",
        "south_west", "south_east", "north_west", "north_east"
    };
    cJSON *guards = cJSON_CreateObject();
    for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
        cJSON *g = cJSON_CreateObject();
        cJSON_AddNumberToObject(g, "weight", h->guards[r].weight);
        cJSON_AddNumberToObject(g, "sum_w2", h->guards[r].sum_w2);
        cJSON_AddNumberToObject(g, "entries", (double)h->guards[r].count);
        cJSON_AddItemToObject(guards, region_names[r], g);
    }
    cJSON_AddItemToObject(root, "guard_regions", guards);

    /* Exact Stats */
    cJSON *stats = cJSON_CreateObject();
    cJSON_AddNumberToObject(stats, "mean_x", h->stats_mean_x);
    cJSON_AddNumberToObject(stats, "mean_y", h->stats_mean_y);
    cJSON_AddNumberToObject(stats, "M2_x", h->stats_M2_x);
    cJSON_AddNumberToObject(stats, "M2_y", h->stats_M2_y);
    cJSON_AddNumberToObject(stats, "C_xy", h->stats_C_xy);
    cJSON_AddItemToObject(root, "exact_stats", stats);

    /* Bins 2D Row-Major Matrix */
    cJSON *bins_matrix = cJSON_CreateArray();
    uint32_t nx = h->x_axis.nbins;
    uint32_t ny = h->y_axis.nbins;
    for (uint32_t ix = 0; ix < nx; ++ix) {
        cJSON *row = cJSON_CreateDoubleArray(&h->bins[histo2d_linear_index(ix, 0, ny)], (int)ny);
        cJSON_AddItemToArray(bins_matrix, row);
    }
    cJSON_AddItemToObject(root, "bins_row_major", bins_matrix);

    if (h->sum_w2) {
        cJSON *w2_matrix = cJSON_CreateArray();
        for (uint32_t ix = 0; ix < nx; ++ix) {
            cJSON *row = cJSON_CreateDoubleArray(&h->sum_w2[histo2d_linear_index(ix, 0, ny)], (int)ny);
            cJSON_AddItemToArray(w2_matrix, row);
        }
        cJSON_AddItemToObject(root, "sum_w2_row_major", w2_matrix);
    }

    char *rendered = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);

    if (!rendered) return HISTO_ERR_NOMEM;
    if (out_size) *out_size = strlen(rendered);
    *out_str = rendered;
    return HISTO_OK;
}

histo_status_t histo2d_serialize_json(const histo2d_t *h, char *buf,
                                      size_t buf_size, size_t *out_size)
{
    if (!h) return HISTO_ERR_INVALID_ARG;
    char *str = NULL;
    size_t sz = 0;
    histo_status_t status = histo2d_serialize_json_alloc(h, &str, &sz);
    if (status != HISTO_OK) return status;

    if (out_size) *out_size = sz;
    if (!buf || buf_size <= sz) {
        free(str);
        return HISTO_ERR_SERIALIZATION;
    }

    memcpy(buf, str, sz + 1);
    free(str);
    return HISTO_OK;
}

histo_status_t histo2d_deserialize_json(const char *json_str, histo2d_t **out_h) {
    if (!json_str || !out_h) return HISTO_ERR_INVALID_ARG;

    cJSON *root = cJSON_Parse(json_str);
    if (!root) return HISTO_ERR_DESERIALIZATION;

    cJSON *x_axis_obj = cJSON_GetObjectItemCaseSensitive(root, "x_axis");
    cJSON *y_axis_obj = cJSON_GetObjectItemCaseSensitive(root, "y_axis");
    if (!x_axis_obj || !y_axis_obj) {
        cJSON_Delete(root);
        return HISTO_ERR_DESERIALIZATION;
    }

    cJSON *x_type_obj = cJSON_GetObjectItemCaseSensitive(x_axis_obj, "bin_type");
    cJSON *x_nbins_obj = cJSON_GetObjectItemCaseSensitive(x_axis_obj, "nbins");
    cJSON *x_min_obj = cJSON_GetObjectItemCaseSensitive(x_axis_obj, "min");
    cJSON *x_max_obj = cJSON_GetObjectItemCaseSensitive(x_axis_obj, "max");

    cJSON *y_type_obj = cJSON_GetObjectItemCaseSensitive(y_axis_obj, "bin_type");
    cJSON *y_nbins_obj = cJSON_GetObjectItemCaseSensitive(y_axis_obj, "nbins");
    cJSON *y_min_obj = cJSON_GetObjectItemCaseSensitive(y_axis_obj, "min");
    cJSON *y_max_obj = cJSON_GetObjectItemCaseSensitive(y_axis_obj, "max");

    if (!x_type_obj || !x_nbins_obj || !x_min_obj || !x_max_obj ||
        !y_type_obj || !y_nbins_obj || !y_min_obj || !y_max_obj)
    {
        cJSON_Delete(root);
        return HISTO_ERR_DESERIALIZATION;
    }

    uint32_t nx = (uint32_t)x_nbins_obj->valuedouble;
    uint32_t ny = (uint32_t)y_nbins_obj->valuedouble;
    double xmin = x_min_obj->valuedouble;
    double xmax = x_max_obj->valuedouble;
    double ymin = y_min_obj->valuedouble;
    double ymax = y_max_obj->valuedouble;

    histo_bin_type_t xtype = (strcmp(x_type_obj->valuestring, "variable") == 0) ? HISTO_BIN_VARIABLE : HISTO_BIN_UNIFORM;
    histo_bin_type_t ytype = (strcmp(y_type_obj->valuestring, "variable") == 0) ? HISTO_BIN_VARIABLE : HISTO_BIN_UNIFORM;

    double *xedges = NULL;
    double *yedges = NULL;

    if (xtype == HISTO_BIN_VARIABLE) {
        cJSON *edges_arr = cJSON_GetObjectItemCaseSensitive(x_axis_obj, "edges");
        if (!edges_arr || cJSON_GetArraySize(edges_arr) != (int)(nx + 1)) {
            cJSON_Delete(root);
            return HISTO_ERR_DESERIALIZATION;
        }
        xedges = (double*)malloc((nx + 1) * sizeof(double));
        for (uint32_t i = 0; i <= nx; ++i) {
            xedges[i] = cJSON_GetArrayItem(edges_arr, (int)i)->valuedouble;
        }
    }

    if (ytype == HISTO_BIN_VARIABLE) {
        cJSON *edges_arr = cJSON_GetObjectItemCaseSensitive(y_axis_obj, "edges");
        if (!edges_arr || cJSON_GetArraySize(edges_arr) != (int)(ny + 1)) {
            free(xedges);
            cJSON_Delete(root);
            return HISTO_ERR_DESERIALIZATION;
        }
        yedges = (double*)malloc((ny + 1) * sizeof(double));
        for (uint32_t j = 0; j <= ny; ++j) {
            yedges[j] = cJSON_GetArrayItem(edges_arr, (int)j)->valuedouble;
        }
    }

    cJSON *flags_obj = cJSON_GetObjectItemCaseSensitive(root, "flags");
    uint32_t flags = flags_obj ? (uint32_t)flags_obj->valuedouble : 0;

    histo2d_axis_t x_axis = { xtype, nx, xmin, xmax, xedges };
    histo2d_axis_t y_axis = { ytype, ny, ymin, ymax, yedges };

    histo2d_t *h = histo2d_create(&x_axis, &y_axis, flags);
    free(xedges);
    free(yedges);
    if (!h) {
        cJSON_Delete(root);
        return HISTO_ERR_NOMEM;
    }

    cJSON *nan_obj = cJSON_GetObjectItemCaseSensitive(root, "nan_count");
    if (nan_obj) h->n_nan = (uint64_t)nan_obj->valuedouble;

    /* Populate Bins */
    cJSON *bins_matrix = cJSON_GetObjectItemCaseSensitive(root, "bins_row_major");
    if (bins_matrix && cJSON_GetArraySize(bins_matrix) == (int)nx) {
        for (uint32_t ix = 0; ix < nx; ++ix) {
            cJSON *row = cJSON_GetArrayItem(bins_matrix, (int)ix);
            if (row && cJSON_GetArraySize(row) == (int)ny) {
                for (uint32_t iy = 0; iy < ny; ++iy) {
                    double val = cJSON_GetArrayItem(row, (int)iy)->valuedouble;
                    h->bins[histo2d_linear_index(ix, iy, ny)] = val;
                    h->total_weight += val;
                }
            }
        }
    }

    cJSON *w2_matrix = cJSON_GetObjectItemCaseSensitive(root, "sum_w2_row_major");
    if (w2_matrix && h->sum_w2 && cJSON_GetArraySize(w2_matrix) == (int)nx) {
        for (uint32_t ix = 0; ix < nx; ++ix) {
            cJSON *row = cJSON_GetArrayItem(w2_matrix, (int)ix);
            if (row && cJSON_GetArraySize(row) == (int)ny) {
                for (uint32_t iy = 0; iy < ny; ++iy) {
                    double val = cJSON_GetArrayItem(row, (int)iy)->valuedouble;
                    h->sum_w2[histo2d_linear_index(ix, iy, ny)] = val;
                    h->total_sum_w2 += val;
                }
            }
        }
    }

    /* Guard Regions */
    cJSON *guards = cJSON_GetObjectItemCaseSensitive(root, "guard_regions");
    if (guards) {
        static const char *region_names[HISTO2D_REGION_COUNT] = {
            "center", "east", "north", "south", "west",
            "south_west", "south_east", "north_west", "north_east"
        };
        for (int r = 0; r < HISTO2D_REGION_COUNT; ++r) {
            cJSON *g = cJSON_GetObjectItemCaseSensitive(guards, region_names[r]);
            if (g) {
                cJSON *w = cJSON_GetObjectItemCaseSensitive(g, "weight");
                cJSON *w2 = cJSON_GetObjectItemCaseSensitive(g, "sum_w2");
                cJSON *e = cJSON_GetObjectItemCaseSensitive(g, "entries");
                if (w) h->guards[r].weight = w->valuedouble;
                if (w2) h->guards[r].sum_w2 = w2->valuedouble;
                if (e) h->guards[r].count = (uint64_t)e->valuedouble;
            }
        }
    }

    /* Exact Stats */
    cJSON *stats = cJSON_GetObjectItemCaseSensitive(root, "exact_stats");
    if (stats) {
        cJSON *smx = cJSON_GetObjectItemCaseSensitive(stats, "mean_x");
        cJSON *smy = cJSON_GetObjectItemCaseSensitive(stats, "mean_y");
        cJSON *sm2x = cJSON_GetObjectItemCaseSensitive(stats, "M2_x");
        cJSON *sm2y = cJSON_GetObjectItemCaseSensitive(stats, "M2_y");
        cJSON *scxy = cJSON_GetObjectItemCaseSensitive(stats, "C_xy");
        if (smx) h->stats_mean_x = smx->valuedouble;
        if (smy) h->stats_mean_y = smy->valuedouble;
        if (sm2x) h->stats_M2_x = sm2x->valuedouble;
        if (sm2y) h->stats_M2_y = sm2y->valuedouble;
        if (scxy) h->stats_C_xy = scxy->valuedouble;
    }

    cJSON_Delete(root);
    *out_h = h;
    return HISTO_OK;
}
