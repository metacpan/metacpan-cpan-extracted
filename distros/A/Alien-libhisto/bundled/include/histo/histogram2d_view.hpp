// Non-owning 2D HistogramView for bivariate histograms in libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_HISTOGRAM2D_VIEW_HPP
#define LIBHISTO_HISTOGRAM2D_VIEW_HPP

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "histo/histo2d.h"
#include "histo/histogram.hpp"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

using Stats2D = histo2d_stats_t;
using Region2D = histo2d_region_t;
using Axis2D = histo2d_axis_t;

/**
 * @brief Non-owning read-only view over a 2D bivariate histogram.
 */
class Histogram2DView {
 public:
  constexpr explicit Histogram2DView(const histo2d_t* h = nullptr) noexcept
      : handle_(h) {}

  constexpr bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit constexpr operator bool() const noexcept { return is_valid(); }
  constexpr const histo2d_t* c_handle() const noexcept { return handle_; }

  uint32_t nx() const noexcept {
    return handle_ ? histo2d_nbins_x(handle_) : 0;
  }

  uint32_t ny() const noexcept {
    return handle_ ? histo2d_nbins_y(handle_) : 0;
  }

  size_t total_bins() const noexcept {
    return static_cast<size_t>(nx()) * static_cast<size_t>(ny());
  }

  double total_weight() const noexcept {
    return handle_ ? histo2d_total_weight(handle_) : 0.0;
  }

  uint64_t n_entries() const noexcept {
    return handle_ ? histo2d_num_entries(handle_) : 0;
  }

  double bin_content(uint32_t binx, uint32_t biny) const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_bin_content(handle_, binx, biny, &val);
    return val;
  }

  double bin_error(uint32_t binx, uint32_t biny) const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_bin_error(handle_, binx, biny, &val);
    return val;
  }

  double region_weight(Region2D region) const noexcept {
    if (!handle_) return 0.0;
    double w = 0.0;
    uint64_t c = 0;
    histo2d_region_content(handle_, region, &w, &c);
    return w;
  }

  uint64_t region_count(Region2D region) const noexcept {
    if (!handle_) return 0;
    double w = 0.0;
    uint64_t c = 0;
    histo2d_region_content(handle_, region, &w, &c);
    return c;
  }

  int32_t find_bin(double x, double y, int64_t* binx, int64_t* biny) const noexcept {
    return handle_ ? histo2d_find_bin(handle_, x, y, binx, biny) : -1;
  }

  double mean_x() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_mean_x(handle_, &val);
    return val;
  }

  double mean_y() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_mean_y(handle_, &val);
    return val;
  }

  double variance_x() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_variance_x(handle_, &val);
    return val;
  }

  double variance_y() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_variance_y(handle_, &val);
    return val;
  }

  double std_dev_x() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_std_dev_x(handle_, &val);
    return val;
  }

  double std_dev_y() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_std_dev_y(handle_, &val);
    return val;
  }

  double covariance() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_covariance(handle_, &val);
    return val;
  }

  double correlation() const noexcept {
    if (!handle_) return 0.0;
    double val = 0.0;
    histo2d_correlation(handle_, &val);
    return val;
  }

  Result<Stats2D> stats() const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    Stats2D s{};
    histo_status_t st = histo2d_get_stats(handle_, &s);
    if (st != HISTO_OK) return Status(st);
    return s;
  }

  // 1D Projections and Profiles
  Result<Histogram> ProjectX() const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    histo_t* proj = nullptr;
    histo_status_t st = histo2d_project_x(handle_, &proj);
    if (st != HISTO_OK || !proj) return Status(st);
    return Histogram(proj);
  }

  Result<Histogram> ProjectY() const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    histo_t* proj = nullptr;
    histo_status_t st = histo2d_project_y(handle_, &proj);
    if (st != HISTO_OK || !proj) return Status(st);
    return Histogram(proj);
  }

  Result<Histogram> SliceX(uint32_t iy_min, uint32_t iy_max) const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    histo_t* slice = nullptr;
    histo_status_t st = histo2d_slice_x(handle_, iy_min, iy_max, &slice);
    if (st != HISTO_OK || !slice) return Status(st);
    return Histogram(slice);
  }

  Result<Histogram> SliceY(uint32_t ix_min, uint32_t ix_max) const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    histo_t* slice = nullptr;
    histo_status_t st = histo2d_slice_y(handle_, ix_min, ix_max, &slice);
    if (st != HISTO_OK || !slice) return Status(st);
    return Histogram(slice);
  }

  Result<Histogram> ProfileX() const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    histo_t* prof = nullptr;
    histo_status_t st = histo2d_profile_x(handle_, &prof);
    if (st != HISTO_OK || !prof) return Status(st);
    return Histogram(prof);
  }

  Result<Histogram> ProfileY() const noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    histo_t* prof = nullptr;
    histo_status_t st = histo2d_profile_y(handle_, &prof);
    if (st != HISTO_OK || !prof) return Status(st);
    return Histogram(prof);
  }

 private:
  const histo2d_t* handle_;
};

}  // namespace libhisto

#endif  // LIBHISTO_HISTOGRAM2D_VIEW_HPP
