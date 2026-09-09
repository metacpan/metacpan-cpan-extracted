// Kernel Density Estimation (KDE) C++ RAII wrapper for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_KDE_HPP
#define LIBHISTO_KDE_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

#include "histo/histogram.hpp"
#include "histo/kde.h"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

using KDEKernel = histo_kde_kernel_t;
using KDEBandwidthMethod = histo_kde_bandwidth_method_t;
using KDEOptions = histo_kde_options_t;

inline KDEOptions DefaultKDEOptions() noexcept {
  return histo_kde_default_options();
}

/**
 * @brief Non-parametric Kernel Density Estimation continuous density model.
 */
class KDE {
 public:
  constexpr KDE() noexcept : handle_(nullptr) {}
  explicit constexpr KDE(histo_kde_t* handle) noexcept : handle_(handle) {}

  // Construct from raw sample coordinates
  explicit KDE(Span<const double> samples, const KDEOptions* options = nullptr) noexcept
      : handle_(samples.empty()
                    ? nullptr
                    : histo_kde_create(samples.size(), samples.data(), nullptr, options)) {}

  // Construct from an existing 1D Histogram
  explicit KDE(const HistogramView& histo, const KDEOptions* options = nullptr) noexcept
      : handle_(histo.c_handle()
                    ? histo_kde_create_from_histo(histo.c_handle(), options)
                    : nullptr) {}

  static Result<KDE> FromSamples(Span<const double> samples,
                                 const KDEOptions* options = nullptr) noexcept {
    if (samples.empty()) return Status(StatusCode::kInvalidArgument);
    histo_kde_t* k = histo_kde_create(samples.size(), samples.data(), nullptr, options);
    if (!k) return Status(StatusCode::kInvalidArgument);
    return KDE(k);
  }

  static Result<KDE> FromHistogram(const HistogramView& histo,
                                   const KDEOptions* options = nullptr) noexcept {
    if (!histo.c_handle()) return Status(StatusCode::kInvalidArgument);
    histo_kde_t* k = histo_kde_create_from_histo(histo.c_handle(), options);
    if (!k) return Status(StatusCode::kInvalidArgument);
    return KDE(k);
  }

  ~KDE() noexcept {
    if (handle_) {
      histo_kde_destroy(handle_);
      handle_ = nullptr;
    }
  }

  KDE(KDE&& other) noexcept : handle_(other.handle_) {
    other.handle_ = nullptr;
  }

  KDE& operator=(KDE&& other) noexcept {
    if (this != &other) {
      if (handle_) histo_kde_destroy(handle_);
      handle_ = other.handle_;
      other.handle_ = nullptr;
    }
    return *this;
  }

  KDE(const KDE&) = delete;
  KDE& operator=(const KDE&) = delete;

  bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit operator bool() const noexcept { return is_valid(); }
  const histo_kde_t* c_handle() const noexcept { return handle_; }
  histo_kde_t* release() noexcept {
    histo_kde_t* k = handle_;
    handle_ = nullptr;
    return k;
  }

  double bandwidth() const noexcept {
    return handle_ ? histo_kde_get_bandwidth(handle_) : 0.0;
  }

  KDEKernel kernel() const noexcept {
    return handle_ ? histo_kde_get_kernel(handle_) : HISTO_KDE_KERNEL_GAUSSIAN;
  }

  size_t num_points() const noexcept {
    return handle_ ? histo_kde_num_points(handle_) : 0;
  }

  double EvalPdf(double x) const noexcept {
    return handle_ ? histo_kde_eval(handle_, x) : 0.0;
  }

  double EvalCdf(double x) const noexcept {
    return handle_ ? histo_kde_cdf(handle_, x) : 0.0;
  }

  Result<double> Quantile(double q) const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    double val = 0.0;
    histo_status_t st = histo_kde_quantile(handle_, q, &val);
    if (st != HISTO_OK) return Status(st);
    return val;
  }

  Status Sample(Span<double> out_samples, uint64_t seed = 0) const noexcept {
    if (!handle_ || out_samples.empty()) return Status(StatusCode::kInvalidArgument);
    return histo_kde_sample(handle_, out_samples.size(), out_samples.data(), seed);
  }

  Result<std::vector<double>> SampleN(size_t n, uint64_t seed = 0) const {
    if (!handle_ || n == 0) return Status(StatusCode::kInvalidArgument);
    std::vector<double> samples(n);
    histo_status_t st = histo_kde_sample(handle_, n, samples.data(), seed);
    if (st != HISTO_OK) return Status(st);
    return samples;
  }

 private:
  histo_kde_t* handle_;
};

}  // namespace libhisto

#endif  // LIBHISTO_KDE_HPP
