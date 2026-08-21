#ifndef LIBHISTO_SKETCH_H
#define LIBHISTO_SKETCH_H

/**
 * @file sketch.h
 * @brief Online Dynamic Quantile Sketch (bounded relative-error, based on DDSketch).
 */

#include "histo/types.h"
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @brief Opaque sketch handle */
typedef struct histo_sketch histo_sketch_t;

/**
 * @brief Create a new dynamic quantile sketch.
 *
 * @param alpha The relative error guarantee (e.g., 0.01 for +/- 1% accuracy).
 * @param max_bins Maximum number of bins before collapsing (limits memory).
 * @return Pointer to new sketch, or NULL on failure.
 */
histo_sketch_t* histo_sketch_create(double alpha, uint32_t max_bins);

/**
 * @brief Destroy a sketch and free its resources.
 *
 * @param s The sketch to destroy.
 */
void histo_sketch_destroy(histo_sketch_t *s);

/**
 * @brief Insert a value into the sketch.
 *
 * @param s The sketch.
 * @param value The value to insert.
 * @return Status code (HISTO_OK on success).
 */
histo_status_t histo_sketch_insert(histo_sketch_t *s, double value);

/**
 * @brief Insert a weighted value into the sketch.
 *
 * @param s The sketch.
 * @param value The value to insert.
 * @param weight The weight of the value (must be >= 0).
 * @return Status code.
 */
histo_status_t histo_sketch_insert_w(histo_sketch_t *s, double value, double weight);

/**
 * @brief Insert an array of weighted values into the sketch.
 *
 * @param s The sketch.
 * @param n Number of elements.
 * @param values Array of values.
 * @param weights Array of weights (can be NULL for uniform weight 1.0).
 * @return Status code.
 */
histo_status_t histo_sketch_insert_n(histo_sketch_t *s, size_t n, const double *values, const double *weights);

/**
 * @brief Query a quantile from the sketch.
 *
 * @param s The sketch.
 * @param q The quantile to query (0.0 to 1.0).
 * @param out_val Pointer to store the computed quantile.
 * @return Status code.
 */
histo_status_t histo_sketch_quantile(const histo_sketch_t *s, double q, double *out_val);

/**
 * @brief Merge src sketch into dest sketch.
 * Both sketches must have been created with the same alpha.
 *
 * @param dest The destination sketch.
 * @param src The source sketch.
 * @return Status code.
 */
histo_status_t histo_sketch_merge(histo_sketch_t *dest, const histo_sketch_t *src);

/**
 * @brief Reset the sketch to an empty state.
 *
 * @param s The sketch.
 * @return Status code.
 */
histo_status_t histo_sketch_reset(histo_sketch_t *s);

/**
 * @brief Get the minimum value inserted into the sketch.
 *
 * @param s The sketch.
 * @return The minimum value, or NaN if empty.
 */
double histo_sketch_min(const histo_sketch_t *s);

/**
 * @brief Get the maximum value inserted into the sketch.
 *
 * @param s The sketch.
 * @return The maximum value, or NaN if empty.
 */
double histo_sketch_max(const histo_sketch_t *s);

/**
 * @brief Get the total weight of all inserted values.
 *
 * @param s The sketch.
 * @return Total weight.
 */
double histo_sketch_total_weight(const histo_sketch_t *s);

/**
 * @brief Get the total number of entries inserted.
 *
 * @param s The sketch.
 * @return Number of entries.
 */
uint64_t histo_sketch_num_entries(const histo_sketch_t *s);

/**
 * @brief Serialize the sketch to a binary format.
 *
 * @param s The sketch.
 * @param out_buffer Pointer to a pointer where the newly allocated buffer will be stored.
 * @param out_size Pointer to store the size of the allocated buffer.
 * @return Status code.
 */
histo_status_t histo_sketch_serialize_binary(const histo_sketch_t *s, void **out_buffer, size_t *out_size);

/**
 * @brief Deserialize a sketch from a binary format.
 *
 * @param buffer The binary buffer.
 * @param size The size of the buffer.
 * @param out_sketch Pointer to store the deserialized sketch.
 * @return Status code.
 */
histo_status_t histo_sketch_deserialize_binary(const void *buffer, size_t size, histo_sketch_t **out_sketch);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_SKETCH_H */
