
#include "histo/sketch.h"
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <float.h>

#define MAX_BINS_LIMIT 10000000

typedef struct {
    double *counts;
    int32_t min_k;
    int32_t max_k;
    uint32_t max_bins;
} sketch_store_t;

struct histo_sketch {
    double alpha;
    double gamma;
    double log_gamma;
    uint32_t max_bins;
    
    sketch_store_t pos;
    sketch_store_t neg;
    
    double zero_count;
    double total_weight;
    uint64_t num_entries;
    double min_val;
    double max_val;
};

static void store_init(sketch_store_t *s, uint32_t max_bins) {
    s->counts = NULL;
    s->min_k = 0;
    s->max_k = 0;
    s->max_bins = max_bins;
}

static void store_destroy(sketch_store_t *s) {
    free(s->counts);
}

static void store_add(sketch_store_t *s, int32_t k, double weight) {
    if (!s->counts) {
        s->counts = (double*)calloc(s->max_bins, sizeof(double));
        s->min_k = k;
        s->max_k = k;
        s->counts[0] = weight;
        return;
    }

    if (k < s->min_k) {
        if (s->max_k - k >= (int32_t)s->max_bins) {
            // Collapse: we can't represent k. Add to the smallest bin we can represent, which is s->max_k - s->max_bins + 1
            int32_t min_valid = s->max_k - s->max_bins + 1;
            if (k < min_valid) {
                // Instead of actually storing at k, we collapse into min_valid
                k = min_valid;
            }
        }
    }
    
    if (k > s->max_k) {
        if (k - s->min_k >= (int32_t)s->max_bins) {
            // Need to shift and collapse smaller bins
            int32_t new_min_k = k - s->max_bins + 1;
            double collapse_weight = 0;
            for (int32_t i = s->min_k; i < new_min_k && i <= s->max_k; i++) {
                collapse_weight += s->counts[(i % s->max_bins + s->max_bins) % s->max_bins];
                s->counts[(i % s->max_bins + s->max_bins) % s->max_bins] = 0.0;
            }
            s->min_k = new_min_k;
            // The collapsed weight is placed in the new min_k
            s->counts[(s->min_k % s->max_bins + s->max_bins) % s->max_bins] += collapse_weight;
        }
        s->max_k = k;
    }
    
    if (k < s->min_k) {
        s->min_k = k;
    }
    
    s->counts[(k % s->max_bins + s->max_bins) % s->max_bins] += weight;
}

static void store_merge(sketch_store_t *dest, const sketch_store_t *src) {
    if (!src->counts) return;
    for (int32_t k = src->min_k; k <= src->max_k; k++) {
        double w = src->counts[(k % src->max_bins + src->max_bins) % src->max_bins];
        if (w > 0.0) {
            store_add(dest, k, w);
        }
    }
}

histo_sketch_t* histo_sketch_create(double alpha, uint32_t max_bins) {
    if (alpha <= 0.0 || alpha >= 1.0 || max_bins == 0 || max_bins > MAX_BINS_LIMIT) return NULL;
    histo_sketch_t *s = (histo_sketch_t*)calloc(1, sizeof(histo_sketch_t));
    if (!s) return NULL;
    
    s->alpha = alpha;
    s->gamma = (1.0 + alpha) / (1.0 - alpha);
    s->log_gamma = log(s->gamma);
    s->max_bins = max_bins;
    
    store_init(&s->pos, max_bins);
    store_init(&s->neg, max_bins);
    
    s->min_val = INFINITY;
    s->max_val = -INFINITY;
    
    return s;
}

void histo_sketch_destroy(histo_sketch_t *s) {
    if (!s) return;
    store_destroy(&s->pos);
    store_destroy(&s->neg);
    free(s);
}

histo_status_t histo_sketch_insert_w(histo_sketch_t *s, double value, double weight) {
    if (!s || weight < 0.0) return HISTO_ERR_INVALID_ARG;
    if (!isfinite(value) || !isfinite(weight)) return HISTO_WARN_NON_FINITE;
    if (weight == 0.0) return HISTO_OK;

    if (value < s->min_val) s->min_val = value;
    if (value > s->max_val) s->max_val = value;
    s->total_weight += weight;
    s->num_entries++;

    if (value > 0.0) {
        int32_t k = (int32_t)ceil(log(value) / s->log_gamma);
        store_add(&s->pos, k, weight);
    } else if (value < 0.0) {
        int32_t k = (int32_t)ceil(log(-value) / s->log_gamma);
        store_add(&s->neg, k, weight);
    } else {
        s->zero_count += weight;
    }
    return HISTO_OK;
}

histo_status_t histo_sketch_insert(histo_sketch_t *s, double value) {
    return histo_sketch_insert_w(s, value, 1.0);
}

histo_status_t histo_sketch_insert_n(histo_sketch_t *s, size_t n, const double *values, const double *weights) {
    if (!s || !values) return HISTO_ERR_INVALID_ARG;
    histo_status_t st = HISTO_OK;
    for (size_t i = 0; i < n; i++) {
        double w = weights ? weights[i] : 1.0;
        histo_status_t curr = histo_sketch_insert_w(s, values[i], w);
        if (curr != HISTO_OK) st = curr;
    }
    return st;
}

histo_status_t histo_sketch_quantile(const histo_sketch_t *s, double q, double *out_val) {
    if (!s || !out_val) return HISTO_ERR_INVALID_ARG;
    if (q < 0.0 || q > 1.0) return HISTO_ERR_INVALID_ARG;
    if (s->num_entries == 0) {
        *out_val = NAN;
        return HISTO_ERR_EMPTY;
    }

    double rank = q * (s->total_weight - 1.0);
    double cumulative = 0.0;

    // Negatives (iterated backwards from max_k down to min_k)
    if (s->neg.counts) {
        for (int32_t k = s->neg.max_k; k >= s->neg.min_k; k--) {
            double w = s->neg.counts[(k % s->neg.max_bins + s->neg.max_bins) % s->neg.max_bins];
            if (w > 0.0) {
                cumulative += w;
                if (cumulative > rank) {
                    *out_val = -pow(s->gamma, k);
                    // bound check
                    if (*out_val < s->min_val) *out_val = s->min_val;
                    if (*out_val > s->max_val) *out_val = s->max_val;
                    return HISTO_OK;
                }
            }
        }
    }

    // Zero
    if (s->zero_count > 0.0) {
        cumulative += s->zero_count;
        if (cumulative > rank) {
            *out_val = 0.0;
            return HISTO_OK;
        }
    }

    // Positives (iterated forwards from min_k to max_k)
    if (s->pos.counts) {
        for (int32_t k = s->pos.min_k; k <= s->pos.max_k; k++) {
            double w = s->pos.counts[(k % s->pos.max_bins + s->pos.max_bins) % s->pos.max_bins];
            if (w > 0.0) {
                cumulative += w;
                if (cumulative > rank) {
                    *out_val = pow(s->gamma, k); // approximation logic
                    *out_val = 2.0 * *out_val / (1.0 + s->gamma); // typical representative value for bin
                    // bound check
                    if (*out_val < s->min_val) *out_val = s->min_val;
                    if (*out_val > s->max_val) *out_val = s->max_val;
                    return HISTO_OK;
                }
            }
        }
    }

    *out_val = s->max_val;
    return HISTO_OK;
}

histo_status_t histo_sketch_merge(histo_sketch_t *dest, const histo_sketch_t *src) {
    if (!dest || !src) return HISTO_ERR_INVALID_ARG;
    if (fabs(dest->alpha - src->alpha) > 1e-9) return HISTO_ERR_INCOMPATIBLE;
    
    if (src->min_val < dest->min_val) dest->min_val = src->min_val;
    if (src->max_val > dest->max_val) dest->max_val = src->max_val;
    dest->total_weight += src->total_weight;
    dest->num_entries += src->num_entries;
    dest->zero_count += src->zero_count;
    
    store_merge(&dest->pos, &src->pos);
    store_merge(&dest->neg, &src->neg);
    
    return HISTO_OK;
}

histo_status_t histo_sketch_reset(histo_sketch_t *s) {
    if (!s) return HISTO_ERR_INVALID_ARG;
    store_destroy(&s->pos);
    store_destroy(&s->neg);
    store_init(&s->pos, s->max_bins);
    store_init(&s->neg, s->max_bins);
    s->zero_count = 0.0;
    s->total_weight = 0.0;
    s->num_entries = 0;
    s->min_val = INFINITY;
    s->max_val = -INFINITY;
    return HISTO_OK;
}

double histo_sketch_min(const histo_sketch_t *s) { return s ? (s->num_entries > 0 ? s->min_val : NAN) : NAN; }
double histo_sketch_max(const histo_sketch_t *s) { return s ? (s->num_entries > 0 ? s->max_val : NAN) : NAN; }
double histo_sketch_total_weight(const histo_sketch_t *s) { return s ? s->total_weight : 0.0; }
uint64_t histo_sketch_num_entries(const histo_sketch_t *s) { return s ? s->num_entries : 0; }

#include "internal_common.h"

#define HISTO_SKETCH_MAGIC "\x89LSKET\n\0"
#define HISTO_SKETCH_MAGIC_LEN 8
#define HISTO_SKETCH_HEADER_SIZE 128
#define HISTO_SKETCH_FORMAT_VERSION 1

histo_status_t histo_sketch_serialize_binary(const histo_sketch_t *s, void **out_buffer, size_t *out_size) {
    if (!s || !out_buffer || !out_size) return HISTO_ERR_INVALID_ARG;

    uint32_t pos_has = (s->pos.counts != NULL) ? 1 : 0;
    uint32_t pos_num = (pos_has && s->pos.max_k >= s->pos.min_k) ? (uint32_t)(s->pos.max_k - s->pos.min_k + 1) : 0;
    if (pos_num > s->max_bins) pos_num = s->max_bins;

    uint32_t neg_has = (s->neg.counts != NULL) ? 1 : 0;
    uint32_t neg_num = (neg_has && s->neg.max_k >= s->neg.min_k) ? (uint32_t)(s->neg.max_k - s->neg.min_k + 1) : 0;
    if (neg_num > s->max_bins) neg_num = s->max_bins;

    size_t total_size = HISTO_SKETCH_HEADER_SIZE + ((size_t)pos_num + (size_t)neg_num) * sizeof(double);
    uint8_t *buf = (uint8_t *)calloc(1, total_size);
    if (!buf) return HISTO_ERR_NOMEM;

    /* Magic & Version */
    memcpy(buf, HISTO_SKETCH_MAGIC, HISTO_SKETCH_MAGIC_LEN);
    uint32_t ver = histo_htole32(HISTO_SKETCH_FORMAT_VERSION);
    uint32_t hdr_sz = histo_htole32(HISTO_SKETCH_HEADER_SIZE);
    memcpy(buf + 8, &ver, 4);
    memcpy(buf + 12, &hdr_sz, 4);

    /* Parameters */
    double alpha_le = histo_dtole(s->alpha);
    double gamma_le = histo_dtole(s->gamma);
    double log_gamma_le = histo_dtole(s->log_gamma);
    uint32_t max_bins_le = histo_htole32(s->max_bins);
    uint32_t flags_le = 0;
    memcpy(buf + 16, &alpha_le, 8);
    memcpy(buf + 24, &gamma_le, 8);
    memcpy(buf + 32, &log_gamma_le, 8);
    memcpy(buf + 40, &max_bins_le, 4);
    memcpy(buf + 44, &flags_le, 4);

    /* Summaries */
    double zero_le = histo_dtole(s->zero_count);
    double tot_w_le = histo_dtole(s->total_weight);
    uint64_t entries_le = histo_htole64(s->num_entries);
    double min_v_le = histo_dtole(s->min_val);
    double max_v_le = histo_dtole(s->max_val);
    memcpy(buf + 48, &zero_le, 8);
    memcpy(buf + 56, &tot_w_le, 8);
    memcpy(buf + 64, &entries_le, 8);
    memcpy(buf + 72, &min_v_le, 8);
    memcpy(buf + 80, &max_v_le, 8);

    /* Pos Store metadata */
    int32_t pos_min_k_le = (int32_t)histo_htole32((uint32_t)s->pos.min_k);
    int32_t pos_max_k_le = (int32_t)histo_htole32((uint32_t)s->pos.max_k);
    uint32_t pos_has_le = histo_htole32(pos_has);
    uint32_t pos_num_le = histo_htole32(pos_num);
    memcpy(buf + 88, &pos_min_k_le, 4);
    memcpy(buf + 92, &pos_max_k_le, 4);
    memcpy(buf + 96, &pos_has_le, 4);
    memcpy(buf + 100, &pos_num_le, 4);

    /* Neg Store metadata */
    int32_t neg_min_k_le = (int32_t)histo_htole32((uint32_t)s->neg.min_k);
    int32_t neg_max_k_le = (int32_t)histo_htole32((uint32_t)s->neg.max_k);
    uint32_t neg_has_le = histo_htole32(neg_has);
    uint32_t neg_num_le = histo_htole32(neg_num);
    memcpy(buf + 104, &neg_min_k_le, 4);
    memcpy(buf + 108, &neg_max_k_le, 4);
    memcpy(buf + 112, &neg_has_le, 4);
    memcpy(buf + 116, &neg_num_le, 4);

    /* Pos Payload */
    size_t offset = HISTO_SKETCH_HEADER_SIZE;
    if (pos_has && pos_num > 0) {
        for (uint32_t i = 0; i < pos_num; ++i) {
            int32_t k = s->pos.min_k + (int32_t)i;
            double w = s->pos.counts[(k % (int32_t)s->pos.max_bins + (int32_t)s->pos.max_bins) % (int32_t)s->pos.max_bins];
            double w_le = histo_dtole(w);
            memcpy(buf + offset, &w_le, sizeof(double));
            offset += sizeof(double);
        }
    }

    /* Neg Payload */
    if (neg_has && neg_num > 0) {
        for (uint32_t i = 0; i < neg_num; ++i) {
            int32_t k = s->neg.min_k + (int32_t)i;
            double w = s->neg.counts[(k % (int32_t)s->neg.max_bins + (int32_t)s->neg.max_bins) % (int32_t)s->neg.max_bins];
            double w_le = histo_dtole(w);
            memcpy(buf + offset, &w_le, sizeof(double));
            offset += sizeof(double);
        }
    }

    *out_buffer = buf;
    *out_size = total_size;
    return HISTO_OK;
}

histo_status_t histo_sketch_deserialize_binary(const void *buffer, size_t size, histo_sketch_t **out_sketch) {
    if (!buffer || !out_sketch) return HISTO_ERR_INVALID_ARG;
    if (size < HISTO_SKETCH_HEADER_SIZE) return HISTO_ERR_DESERIALIZATION;

    const uint8_t *buf = (const uint8_t *)buffer;

    /* Verify Magic */
    if (memcmp(buf, HISTO_SKETCH_MAGIC, HISTO_SKETCH_MAGIC_LEN) != 0) {
        return HISTO_ERR_DESERIALIZATION;
    }

    /* Verify Version & Header Size */
    uint32_t ver, hdr_sz;
    memcpy(&ver, buf + 8, 4);
    memcpy(&hdr_sz, buf + 12, 4);
    ver = histo_le32toh(ver);
    hdr_sz = histo_le32toh(hdr_sz);
    if (ver != HISTO_SKETCH_FORMAT_VERSION || hdr_sz != HISTO_SKETCH_HEADER_SIZE) {
        return HISTO_ERR_DESERIALIZATION;
    }

    /* Parameters */
    double alpha_le;
    uint32_t max_bins_le;
    memcpy(&alpha_le, buf + 16, 8);
    memcpy(&max_bins_le, buf + 40, 4);
    double alpha = histo_letoh_d(alpha_le);
    uint32_t max_bins = histo_le32toh(max_bins_le);

    if (alpha <= 0.0 || alpha >= 1.0 || max_bins == 0 || max_bins > MAX_BINS_LIMIT) {
        return HISTO_ERR_DESERIALIZATION;
    }

    /* Store metadata */
    int32_t pos_min_k, pos_max_k, neg_min_k, neg_max_k;
    uint32_t pos_has, pos_num, neg_has, neg_num;
    memcpy(&pos_min_k, buf + 88, 4);
    memcpy(&pos_max_k, buf + 92, 4);
    memcpy(&pos_has, buf + 96, 4);
    memcpy(&pos_num, buf + 100, 4);
    memcpy(&neg_min_k, buf + 104, 4);
    memcpy(&neg_max_k, buf + 108, 4);
    memcpy(&neg_has, buf + 112, 4);
    memcpy(&neg_num, buf + 116, 4);

    pos_min_k = (int32_t)histo_le32toh((uint32_t)pos_min_k);
    pos_max_k = (int32_t)histo_le32toh((uint32_t)pos_max_k);
    pos_has = histo_le32toh(pos_has);
    pos_num = histo_le32toh(pos_num);
    neg_min_k = (int32_t)histo_le32toh((uint32_t)neg_min_k);
    neg_max_k = (int32_t)histo_le32toh((uint32_t)neg_max_k);
    neg_has = histo_le32toh(neg_has);
    neg_num = histo_le32toh(neg_num);

    size_t expected_size = HISTO_SKETCH_HEADER_SIZE + ((size_t)pos_num + (size_t)neg_num) * sizeof(double);
    if (size < expected_size) {
        return HISTO_ERR_DESERIALIZATION;
    }

    histo_sketch_t *s = histo_sketch_create(alpha, max_bins);
    if (!s) return HISTO_ERR_NOMEM;

    /* Summaries */
    double zero_le, tot_w_le, min_v_le, max_v_le;
    uint64_t entries_le;
    memcpy(&zero_le, buf + 48, 8);
    memcpy(&tot_w_le, buf + 56, 8);
    memcpy(&entries_le, buf + 64, 8);
    memcpy(&min_v_le, buf + 72, 8);
    memcpy(&max_v_le, buf + 80, 8);

    s->zero_count = histo_letoh_d(zero_le);
    s->total_weight = histo_letoh_d(tot_w_le);
    s->num_entries = histo_le64toh(entries_le);
    s->min_val = histo_letoh_d(min_v_le);
    s->max_val = histo_letoh_d(max_v_le);

    /* Read Pos Counts */
    size_t offset = HISTO_SKETCH_HEADER_SIZE;
    if (pos_has && pos_num > 0) {
        s->pos.counts = (double *)calloc(s->pos.max_bins, sizeof(double));
        if (!s->pos.counts) {
            histo_sketch_destroy(s);
            return HISTO_ERR_NOMEM;
        }
        s->pos.min_k = pos_min_k;
        s->pos.max_k = pos_max_k;
        for (uint32_t i = 0; i < pos_num; ++i) {
            double w_le;
            memcpy(&w_le, buf + offset, sizeof(double));
            offset += sizeof(double);
            double w = histo_letoh_d(w_le);
            int32_t k = pos_min_k + (int32_t)i;
            s->pos.counts[(k % (int32_t)s->pos.max_bins + (int32_t)s->pos.max_bins) % (int32_t)s->pos.max_bins] = w;
        }
    }

    /* Read Neg Counts */
    if (neg_has && neg_num > 0) {
        s->neg.counts = (double *)calloc(s->neg.max_bins, sizeof(double));
        if (!s->neg.counts) {
            histo_sketch_destroy(s);
            return HISTO_ERR_NOMEM;
        }
        s->neg.min_k = neg_min_k;
        s->neg.max_k = neg_max_k;
        for (uint32_t i = 0; i < neg_num; ++i) {
            double w_le;
            memcpy(&w_le, buf + offset, sizeof(double));
            offset += sizeof(double);
            double w = histo_letoh_d(w_le);
            int32_t k = neg_min_k + (int32_t)i;
            s->neg.counts[(k % (int32_t)s->neg.max_bins + (int32_t)s->neg.max_bins) % (int32_t)s->neg.max_bins] = w;
        }
    }

    *out_sketch = s;
    return HISTO_OK;
}

