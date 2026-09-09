// Owning 1D Histogram RAII handle and operations for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_HISTOGRAM_HPP
#define LIBHISTO_HISTOGRAM_HPP

#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <ostream>
#include <string>
#include <utility>
#include <vector>

#if __has_include(<span>) && __cplusplus >= 202002L
#include <span>
#endif

#include "histo/histo.h"
#include "histo/histogram_view.hpp"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

#if __has_include(<span>) && __cplusplus >= 202002L
template <typename T>
using Span = std::span<T>;
#else
template <typename T>
class Span {
 public:
  constexpr Span() noexcept : data_(nullptr), size_(0) {}
  constexpr Span(T* data, size_t size) noexcept : data_(data), size_(size) {}
  template <size_t N>
  constexpr Span(T (&arr)[N]) noexcept : data_(arr), size_(N) {}
  template <typename Container,
            typename = std::enable_if_t<!std::is_same_v<std::decay_t<Container>, Span>>>
  constexpr Span(Container&& c) noexcept
      : data_(std::data(c)), size_(std::size(c)) {}

  constexpr T* data() const noexcept { return data_; }
  constexpr size_t size() const noexcept { return size_; }
  constexpr bool empty() const noexcept { return size_ == 0; }
  constexpr T& operator[](size_t idx) const noexcept { return data_[idx]; }
  constexpr T* begin() const noexcept { return data_; }
  constexpr T* end() const noexcept { return data_ + size_; }

 private:
  T* data_;
  size_t size_;
};
#endif

/**
 * @brief Owning RAII handle for a 1D histogram.
 *
 * Guarantees zero memory overhead (sizeof(Histogram) == sizeof(void*))
 * and exception-free safety.
 */
class Histogram {
 public:
  // Default constructor creates an empty/invalid handle
  constexpr Histogram() noexcept : handle_(nullptr) {}

  // Wrap an existing raw C pointer, taking ownership
  explicit constexpr Histogram(histo_t* handle) noexcept : handle_(handle) {}

  // Direct Constructor (Uniform binning)
  Histogram(uint32_t nbins, double min, double max, uint32_t flags = 0) noexcept
      : handle_(histo_create_uniform(nbins, min, max, flags)) {}

  // Direct Constructor (Variable binning from initializer_list)
  explicit Histogram(std::initializer_list<double> edges, uint32_t flags = 0) noexcept
      : handle_(edges.size() > 1 
                      ? histo_create_variable(static_cast<uint32_t>(edges.size() - 1),
                                              edges.begin(), flags)
                      : nullptr) {}

  // Direct Constructor (Variable binning from span)
  explicit Histogram(Span<const double> edges, uint32_t flags = 0) noexcept
      : handle_(edges.size() > 1
                      ? histo_create_variable(static_cast<uint32_t>(edges.size() - 1),
                                              edges.data(), flags)
                      : nullptr) {}

  // Static Factory Methods (alternative for explicit error reporting)
  static Result<Histogram> Uniform(uint32_t nbins, double min, double max,
                                   uint32_t flags = 0) noexcept {
    histo_t* h = histo_create_uniform(nbins, min, max, flags);
    if (!h) {
      return Status(StatusCode::kInvalidArgument);
    }
    return Histogram(h);
  }

  static Result<Histogram> Variable(Span<const double> edges,
                                    uint32_t flags = 0) noexcept {
    if (edges.size() < 2) {
      return Status(StatusCode::kInvalidArgument);
    }
    histo_t* h = histo_create_variable(static_cast<uint32_t>(edges.size() - 1),
                                       edges.data(), flags);
    if (!h) {
      return Status(StatusCode::kInvalidArgument);
    }
    return Histogram(h);
  }

  // Destructor safely releases the owned C handle
  ~Histogram() noexcept {
    if (handle_) {
      histo_destroy(handle_);
      handle_ = nullptr;
    }
  }

  // Move-only semantics (no implicit copying)
  Histogram(Histogram&& other) noexcept : handle_(other.handle_) {
    other.handle_ = nullptr;
  }

  Histogram& operator=(Histogram&& other) noexcept {
    if (this != &other) {
      if (handle_) {
        histo_destroy(handle_);
      }
      handle_ = other.handle_;
      other.handle_ = nullptr;
    }
    return *this;
  }

  Histogram(const Histogram&) = delete;
  Histogram& operator=(const Histogram&) = delete;

  // View conversions & handles
  constexpr bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit constexpr operator bool() const noexcept { return is_valid(); }
  constexpr histo_t* c_handle() noexcept { return handle_; }
  constexpr const histo_t* c_handle() const noexcept { return handle_; }

  HistogramView view() const noexcept { return HistogramView(handle_); }
  operator HistogramView() const noexcept { return view(); }

  // Forwarded read-only queries
  uint32_t nbins() const noexcept { return view().nbins(); }
  double min() const noexcept { return view().min(); }
  double max() const noexcept { return view().max(); }
  histo_bin_type_t bin_type() const noexcept { return view().bin_type(); }
  double total_weight() const noexcept { return view().total_weight(); }
  uint64_t n_entries() const noexcept { return view().n_entries(); }
  double underflow_weight() const noexcept { return view().underflow_weight(); }
  double overflow_weight() const noexcept { return view().overflow_weight(); }
  uint64_t nan_count() const noexcept { return view().nan_count(); }
  double bin_content(uint32_t bin) const noexcept { return view().bin_content(bin); }
  double bin_error(uint32_t bin) const noexcept { return view().bin_error(bin); }
  double bin_low_edge(uint32_t bin) const noexcept { return view().bin_low_edge(bin); }
  double bin_high_edge(uint32_t bin) const noexcept { return view().bin_high_edge(bin); }
  double bin_width(uint32_t bin) const noexcept { return view().bin_width(bin); }
  double bin_center(uint32_t bin) const noexcept { return view().bin_center(bin); }
  int64_t find_bin(double x) const noexcept { return view().find_bin(x); }
  double mean() const noexcept { return view().mean(); }
  double variance() const noexcept { return view().variance(); }
  double std_dev() const noexcept { return view().std_dev(); }
  double skewness() const noexcept { return view().skewness(); }
  double kurtosis() const noexcept { return view().kurtosis(); }
  Result<double> quantile(double p) const noexcept { return view().quantile(p); }
  Result<Stats> stats() const noexcept { return view().stats(); }
  std::vector<double> bin_edges() const { return view().bin_edges(); }
  BinIterator begin() const noexcept { return BinIterator(handle_, 0); }
  BinIterator end() const noexcept { return BinIterator(handle_, nbins()); }

  // Explicit deep copy / clone
  Histogram Clone(bool empty = false) const noexcept {
    if (!handle_) return Histogram();
    return Histogram(histo_clone(handle_, empty));
  }

  // Release ownership of raw pointer to caller
  histo_t* release() noexcept {
    histo_t* h = handle_;
    handle_ = nullptr;
    return h;
  }

  // Ingestion methods
  Status Fill(double x) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_fill(handle_, x);
  }

  Status Fill(double x, double weight) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_fill_w(handle_, x, weight);
  }

  Status Fill(Span<const double> samples) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    if (samples.empty()) return OkStatus();
    return histo_fill_n(handle_, samples.size(), samples.data(), nullptr);
  }

  Status Fill(std::initializer_list<double> samples) noexcept {
    return Fill(Span<const double>(samples.begin(), samples.size()));
  }

  Status Fill(Span<const double> samples, Span<const double> weights) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    if (samples.size() != weights.size()) return Status(StatusCode::kInvalidArgument);
    if (samples.empty()) return OkStatus();
    return histo_fill_n(handle_, samples.size(), samples.data(), weights.data());
  }

  // Mutators & Operations
  Status Reset() noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_reset(handle_);
  }

  Status Scale(double factor) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo_scale(handle_, factor);
  }

  Status Merge(const HistogramView& other) noexcept {
    if (!handle_ || !other.c_handle()) return Status(StatusCode::kInvalidArgument);
    return histo_add(handle_, other.c_handle());
  }

  Histogram& operator+=(const HistogramView& other) noexcept {
    Merge(other);
    return *this;
  }

  Histogram& operator*=(double factor) noexcept {
    Scale(factor);
    return *this;
  }

  // Serialization
  Result<std::vector<uint8_t>> Serialize() const {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    size_t needed = histo_serialize_binary_size(handle_);
    if (needed == 0) return Status(StatusCode::kSerialization);
    std::vector<uint8_t> buffer(needed);
    histo_status_t st = histo_serialize_binary_into(handle_, buffer.data(), buffer.size());
    if (st != HISTO_OK) return Status(st);
    return buffer;
  }

  static Result<Histogram> Deserialize(Span<const uint8_t> data) {
    if (data.empty()) return Status(StatusCode::kInvalidArgument);
    histo_t* h = nullptr;
    histo_status_t st = histo_deserialize_binary(data.data(), data.size(), &h);
    if (st != HISTO_OK || !h) return Status(st != HISTO_OK ? st : HISTO_ERR_DESERIALIZATION);
    return Histogram(h);
  }

 private:
  histo_t* handle_;
};

inline std::ostream& operator<<(std::ostream& os, const HistogramView& h) {
  os << "Histogram(nbins=" << h.nbins() << ", min=" << h.min()
     << ", max=" << h.max() << ", entries=" << h.n_entries()
     << ", total_weight=" << h.total_weight() << ")";
  return os;
}

}  // namespace libhisto

#endif  // LIBHISTO_HISTOGRAM_HPP
