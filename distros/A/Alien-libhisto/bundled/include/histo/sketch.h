/**
 * @file sketch.h
 * @brief Public C API for DDSketch online quantile streaming sketches.
 */

#ifndef LIBHISTO_SKETCH_H
#define LIBHISTO_SKETCH_H

/**
 * @file sketch.h
 * @brief Online Dynamic Quantile Sketch (bounded relative-error, based on DDSketch).
 *
 * Provides dynamic logarithmic-binning quantile sketches capable of tracking
 * unbounded numeric ranges with mathematically guaranteed relative error bounds.
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
 * @brief Create a new dynamic quantile sketch with guaranteed relative error.
 *
 * @param[in] alpha    The relative error guarantee (e.g. 0.01 for +/- 1% accuracy). Must satisfy 0 < alpha < 1.
 * @param[in] max_bins Maximum number of bins before collapsing (limits memory consumption).
 * @return Pointer to new sketch handle, or NULL on memory failure or invalid arguments.
 *
 * @par Complexity:
 * O(1) time, O(max_bins) space.
 */
histo_sketch_t* histo_sketch_create(double alpha, uint32_t max_bins);

/**
 * @brief Destroy a sketch and release all allocated resources.
 *
 * Safe to call with NULL.
 *
 * @param[in,out] s The sketch handle to destroy.
 *
 * @par Complexity:
 * O(1) time and space.
 */
void histo_sketch_destroy(histo_sketch_t *s);

/**
 * @brief Insert a single value into the sketch with unit weight (1.0).
 *
 * @param[in,out] s     The sketch handle.
 * @param[in]     value The coordinate value to insert.
 * @return HISTO_OK on success, or HISTO_ERR_NON_FINITE if value is NaN/Inf.
 *
 * @par Complexity:
 * O(1) amortized time.
 */
histo_status_t histo_sketch_insert(histo_sketch_t *s, double value);

/**
 * @brief Insert a weighted value into the sketch.
 *
 * @param[in,out] s      The sketch handle.
 * @param[in]     value  The coordinate value to insert.
 * @param[in]     weight Real-valued event weight (must be >= 0).
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(1) amortized time.
 */
histo_status_t histo_sketch_insert_w(histo_sketch_t *s, double value, double weight);

/**
 * @brief Insert an array of contiguous values with optional weights into the sketch.
 *
 * @param[in,out] s       The sketch handle.
 * @param[in]     n       Number of elements in values array.
 * @param[in]     values  Array of coordinate values.
 * @param[in]     weights Array of weights (can be NULL for uniform unit weight 1.0).
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(n) amortized time.
 */
histo_status_t histo_sketch_insert_n(histo_sketch_t *s, size_t n, const double *values, const double *weights);

/**
 * @brief Query an estimated quantile value from the sketch.
 *
 * @param[in]  s       The sketch handle.
 * @param[in]  q       The quantile rank to query (0.0 to 1.0 inclusive).
 * @param[out] out_val Pointer to store the computed quantile value.
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(B) time where B <= max_bins.
 */
histo_status_t histo_sketch_quantile(const histo_sketch_t *s, double q, double *out_val);

/**
 * @brief Merge source sketch into destination sketch.
 *
 * Both sketches must have been created with compatible alpha configuration.
 *
 * @param[in,out] dest The destination sketch handle.
 * @param[in]     src  The source sketch handle.
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(B_src) time where B_src <= max_bins.
 */
histo_status_t histo_sketch_merge(histo_sketch_t *dest, const histo_sketch_t *src);

/**
 * @brief Reset the sketch to an empty state, clearing all bins and accumulators.
 *
 * @param[in,out] s The sketch handle.
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(B) time.
 */
histo_status_t histo_sketch_reset(histo_sketch_t *s);

/**
 * @brief Get the minimum value observed in the sketch.
 *
 * @param[in] s The sketch handle.
 * @return The minimum observed finite value, or NAN if empty.
 *
 * @par Complexity:
 * O(1) time.
 */
double histo_sketch_min(const histo_sketch_t *s);

/**
 * @brief Get the maximum value observed in the sketch.
 *
 * @param[in] s The sketch handle.
 * @return The maximum observed finite value, or NAN if empty.
 *
 * @par Complexity:
 * O(1) time.
 */
double histo_sketch_max(const histo_sketch_t *s);

/**
 * @brief Get the total accumulated weight across all inserted values.
 *
 * @param[in] s The sketch handle.
 * @return Total weight sum (>= 0).
 *
 * @par Complexity:
 * O(1) time.
 */
double histo_sketch_total_weight(const histo_sketch_t *s);

/**
 * @brief Get the total number of entries inserted into the sketch.
 *
 * @param[in] s The sketch handle.
 * @return Number of fill events.
 *
 * @par Complexity:
 * O(1) time.
 */
uint64_t histo_sketch_num_entries(const histo_sketch_t *s);

/**
 * @brief Serialize the sketch to a binary byte buffer.
 *
 * @param[in]  s          The sketch handle.
 * @param[out] out_buffer Pointer to receive newly allocated binary buffer.
 * @param[out] out_size   Pointer to store size of allocated buffer in bytes.
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(B) time and space.
 */
histo_status_t histo_sketch_serialize_binary(const histo_sketch_t *s, void **out_buffer, size_t *out_size);

/**
 * @brief Deserialize a sketch from a binary byte buffer.
 *
 * @param[in]  buffer     The input binary buffer.
 * @param[in]  size       Size of buffer in bytes.
 * @param[out] out_sketch Pointer to store newly created deserialized sketch.
 * @return HISTO_OK on success, or error status code.
 *
 * @par Complexity:
 * O(B) time and space.
 */
histo_status_t histo_sketch_deserialize_binary(const void *buffer, size_t size, histo_sketch_t **out_sketch);

#ifdef __cplusplus
}
#endif

#endif /* LIBHISTO_SKETCH_H */
