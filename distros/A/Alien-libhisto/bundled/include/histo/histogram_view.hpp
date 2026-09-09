// Non-owning 1D HistogramView and Bin proxy iterators for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_HISTOGRAM_VIEW_HPP
#define LIBHISTO_HISTOGRAM_VIEW_HPP

#include <cstddef>
#include <cstdint>
#include <iterator>
#include <string>
#include <string_view>
#include <vector>

#include "histo/histo.h"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

using Stats = histo_stats_t;

/**
 * @brief Proxy value representing an individual histogram bin.
 */
struct Bin {
  uint32_t index;
  double lower_edge;
  double upper_edge;
  double content;
  double error;

  constexpr double width() const noexcept { return upper_edge - lower_edge; }
  constexpr double center() const noexcept { return (lower_edge + upper_edge) * 0.5; }
};

class HistogramView;

/**
 * @brief Zero-overhead forward iterator over histogram bins.
 */
class BinIterator {
 public:
  using iterator_category = std::forward_iterator_tag;
  using value_type = Bin;
  using difference_type = std::ptrdiff_t;
  using pointer = void;
  using reference = Bin;

  constexpr BinIterator() noexcept : handle_(nullptr), index_(0) {}
  constexpr BinIterator(const histo_t* handle, uint32_t index) noexcept
      : handle_(handle), index_(index) {}

  Bin operator*() const noexcept;

  BinIterator& operator++() noexcept {
    ++index_;
    return *this;
  }

  BinIterator operator++(int) noexcept {
    BinIterator tmp = *this;
    ++index_;
    return tmp;
  }

  constexpr bool operator==(const BinIterator& other) const noexcept {
    return handle_ == other.handle_ && index_ == other.index_;
  }

  constexpr bool operator!=(const BinIterator& other) const noexcept {
    return !(*this == other);
  }

 private:
  const histo_t* handle_;
  uint32_t index_;
};

/**
 * @brief Non-owning, read-only view over an existing 1D histogram.
 */
class HistogramView {
 public:
  constexpr explicit HistogramView(const histo_t* h = nullptr) noexcept
      : handle_(h) {}

  constexpr bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit constexpr operator bool() const noexcept { return is_valid(); }
  constexpr const histo_t* c_handle() const noexcept { return handle_; }

  uint32_t nbins() const noexcept {
    return handle_ ? histo_nbins(handle_) : 0;
  }

  double min() const noexcept {
    if (!handle_) return 0.0;
    double min_val = 0.0, max_val = 0.0;
    histo_range(handle_, &min_val, &max_val);
    return min_val;
  }

  double max() const noexcept {
    if (!handle_) return 0.0;
    double min_val = 0.0, max_val = 0.0;
    histo_range(handle_, &min_val, &max_val);
    return max_val;
  }

  histo_bin_type_t bin_type() const noexcept {
    return handle_ ? histo_bin_type(handle_) : HISTO_BIN_UNIFORM;
  }

  double total_weight() const noexcept {
    return handle_ ? histo_total_weight(handle_) : 0.0;
  }

  uint64_t n_entries() const noexcept {
    return handle_ ? histo_num_entries(handle_) : 0;
  }

  double underflow_weight() const noexcept {
    return handle_ ? histo_underflow(handle_) : 0.0;
  }

  double overflow_weight() const noexcept {
    return handle_ ? histo_overflow(handle_) : 0.0;
  }

  uint64_t nan_count() const noexcept {
    return handle_ ? histo_nan_count(handle_) : 0;
  }

  double bin_content(uint32_t bin) const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_bin_content(handle_, bin, &val);
    return val;
  }

  double bin_error(uint32_t bin) const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_bin_error(handle_, bin, &val);
    return val;
  }

  double bin_low_edge(uint32_t bin) const noexcept {
    if (!handle_) return 0.0;
    double lower = 0.0, upper = 0.0;
    histo_bin_bounds(handle_, bin, &lower, &upper);
    return lower;
  }

  double bin_high_edge(uint32_t bin) const noexcept {
    if (!handle_) return 0.0;
    double lower = 0.0, upper = 0.0;
    histo_bin_bounds(handle_, bin, &lower, &upper);
    return upper;
  }

  double bin_width(uint32_t bin) const noexcept {
    if (!handle_) return 0.0;
    double lower = 0.0, upper = 0.0;
    histo_bin_bounds(handle_, bin, &lower, &upper);
    return upper - lower;
  }

  double bin_center(uint32_t bin) const noexcept {
    if (!handle_) return 0.0;
    double center = 0.0;
    histo_bin_center(handle_, bin, &center);
    return center;
  }

  int64_t find_bin(double x) const noexcept {
    if (!handle_) return -1;
    int64_t bin = -1;
    histo_find_bin(handle_, x, &bin);
    return bin;
  }

  double mean() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_mean(handle_, &val);
    return val;
  }

  double variance() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_variance(handle_, &val);
    return val;
  }

  double std_dev() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_std_dev(handle_, &val);
    return val;
  }

  double skewness() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_skewness(handle_, &val);
    return val;
  }

  double kurtosis() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo_kurtosis(handle_, &val);
    return val;
  }

  Result<double> quantile(double p) const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    double q = 0.0;
    histo_status_t st = histo_quantile(handle_, p, &q);
    if (st != HISTO_OK) return Status(st);
    return q;
  }

  Result<Stats> stats() const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    Stats s{};
    histo_status_t st = histo_get_stats(handle_, &s);
    if (st != HISTO_OK) return Status(st);
    return s;
  }

  std::vector<double> bin_edges() const {
    if (!handle_) return {};
    uint32_t n = nbins();
    std::vector<double> edges(n + 1);
    for (uint32_t i = 0; i < n; ++i) {
      double lower = 0.0, upper = 0.0;
      histo_bin_bounds(handle_, i, &lower, &upper);
      edges[i] = lower;
      if (i == n - 1) {
        edges[n] = upper;
      }
    }
    return edges;
  }

  BinIterator begin() const noexcept {
    return BinIterator(handle_, 0);
  }

  BinIterator end() const noexcept {
    return BinIterator(handle_, nbins());
  }

 private:
  const histo_t* handle_;
};

inline Bin BinIterator::operator*() const noexcept {
  if (!handle_) {
    return Bin{index_, 0.0, 0.0, 0.0, 0.0};
  }
  double lower = 0.0, upper = 0.0, content = 0.0, error = 0.0;
  histo_bin_bounds(handle_, index_, &lower, &upper);
  histo_bin_content(handle_, index_, &content);
  histo_bin_error(handle_, index_, &error);
  return Bin{index_, lower, upper, content, error};
}

}  // namespace libhisto

#endif  // LIBHISTO_HISTOGRAM_VIEW_HPP
