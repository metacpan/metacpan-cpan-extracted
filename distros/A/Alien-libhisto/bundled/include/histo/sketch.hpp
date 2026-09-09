// Streaming quantile sketches (DDSketch) C++ wrapper for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_SKETCH_HPP
#define LIBHISTO_SKETCH_HPP

#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <utility>
#include <vector>

#include "histo/histogram.hpp"
#include "histo/sketch.h"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

/**
 * @brief Non-owning view over a dynamic quantile DDSketch.
 */
class SketchView {
 public:
  constexpr explicit SketchView(const histo_sketch_t* s = nullptr) noexcept
      : handle_(s) {}

  constexpr bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit constexpr operator bool() const noexcept { return is_valid(); }
  constexpr const histo_sketch_t* c_handle() const noexcept { return handle_; }

  uint64_t count() const noexcept {
    return handle_ ? histo_sketch_num_entries(handle_) : 0;
  }

  double total_weight() const noexcept {
    return handle_ ? histo_sketch_total_weight(handle_) : 0.0;
  }

  double min() const noexcept {
    return handle_ ? histo_sketch_min(handle_) : 0.0;
  }

  double max() const noexcept {
    return handle_ ? histo_sketch_max(handle_) : 0.0;
  }

  Result<double> quantile(double q) const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    double val = 0.0;
    histo_status_t st = histo_sketch_quantile(handle_, q, &val);
    if (st != HISTO_OK) return Status(st);
    return val;
  }

 protected:
  const histo_sketch_t* handle_;
};

/**
 * @brief Owning RAII handle for dynamic quantile DDSketch.
 */
class DDSketch : public SketchView {
 public:
  constexpr DDSketch() noexcept : SketchView(nullptr) {}
  explicit constexpr DDSketch(histo_sketch_t* handle) noexcept : SketchView(handle) {}

  DDSketch(double alpha, uint32_t max_bins = 2048) noexcept
      : SketchView(histo_sketch_create(alpha, max_bins)) {}

  static Result<DDSketch> Create(double alpha, uint32_t max_bins = 2048) noexcept {
    histo_sketch_t* s = histo_sketch_create(alpha, max_bins);
    if (!s) return Status(StatusCode::kInvalidArgument);
    return DDSketch(s);
  }

  ~DDSketch() noexcept {
    if (mut_handle()) {
      histo_sketch_destroy(mut_handle());
      handle_ = nullptr;
    }
  }

  DDSketch(DDSketch&& other) noexcept : SketchView(other.handle_) {
    other.handle_ = nullptr;
  }

  DDSketch& operator=(DDSketch&& other) noexcept {
    if (this != &other) {
      if (mut_handle()) {
        histo_sketch_destroy(mut_handle());
      }
      handle_ = other.handle_;
      other.handle_ = nullptr;
    }
    return *this;
  }

  DDSketch(const DDSketch&) = delete;
  DDSketch& operator=(const DDSketch&) = delete;

  histo_sketch_t* release() noexcept {
    histo_sketch_t* s = mut_handle();
    handle_ = nullptr;
    return s;
  }

  // Insertion
  Status Insert(double value) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_sketch_insert(mut_handle(), value);
  }

  Status Insert(double value, double weight) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_sketch_insert_w(mut_handle(), value, weight);
  }

  Status Insert(Span<const double> values) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    if (values.empty()) return OkStatus();
    return histo_sketch_insert_n(mut_handle(), values.size(), values.data(), nullptr);
  }

  Status Insert(std::initializer_list<double> values) noexcept {
    return Insert(Span<const double>(values.begin(), values.size()));
  }

  Status Insert(Span<const double> values, Span<const double> weights) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    if (values.size() != weights.size()) return Status(StatusCode::kInvalidArgument);
    if (values.empty()) return OkStatus();
    return histo_sketch_insert_n(mut_handle(), values.size(), values.data(), weights.data());
  }

  // Mutators
  Status Reset() noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_sketch_reset(mut_handle());
  }

  Status Merge(const SketchView& other) noexcept {
    if (!handle_ || !other.c_handle()) return Status(StatusCode::kInvalidArgument);
    return histo_sketch_merge(mut_handle(), other.c_handle());
  }

  DDSketch& operator+=(const SketchView& other) noexcept {
    Merge(other);
    return *this;
  }

  // Serialization
  Result<std::vector<uint8_t>> Serialize() const {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    void* out_buf = nullptr;
    size_t out_size = 0;
    histo_status_t st = histo_sketch_serialize_binary(handle_, &out_buf, &out_size);
    if (st != HISTO_OK || !out_buf) return Status(st);

    const uint8_t* byte_ptr = static_cast<const uint8_t*>(out_buf);
    std::vector<uint8_t> buffer(byte_ptr, byte_ptr + out_size);
    free(out_buf);
    return buffer;
  }

  static Result<DDSketch> Deserialize(Span<const uint8_t> data) {
    if (data.empty()) return Status(StatusCode::kInvalidArgument);
    histo_sketch_t* s = nullptr;
    histo_status_t st = histo_sketch_deserialize_binary(data.data(), data.size(), &s);
    if (st != HISTO_OK || !s) return Status(st != HISTO_OK ? st : HISTO_ERR_DESERIALIZATION);
    return DDSketch(s);
  }

 private:
  histo_sketch_t* mut_handle() noexcept {
    return const_cast<histo_sketch_t*>(handle_);
  }
};

}  // namespace libhisto

#endif  // LIBHISTO_SKETCH_HPP
