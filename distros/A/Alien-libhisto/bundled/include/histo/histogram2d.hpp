// Owning 2D Histogram RAII handle and operations for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_HISTOGRAM2D_HPP
#define LIBHISTO_HISTOGRAM2D_HPP

#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <utility>
#include <vector>

#include "histo/histo2d.h"
#include "histo/histogram.hpp"
#include "histo/histogram2d_view.hpp"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

/**
 * @brief Owning RAII handle for a 2D bivariate histogram.
 */
class Histogram2D {
 public:
  constexpr Histogram2D() noexcept : handle_(nullptr) {}
  explicit constexpr Histogram2D(histo2d_t* handle) noexcept : handle_(handle) {}

  // Direct Constructors (Uniform - Uniform)
  Histogram2D(uint32_t nx, double xmin, double xmax,
              uint32_t ny, double ymin, double ymax,
              uint32_t flags = 0) noexcept
      : handle_(histo2d_create_uniform(nx, xmin, xmax, ny, ymin, ymax, flags)) {}

  // Direct Constructors (Uniform - Variable)
  Histogram2D(uint32_t nx, double xmin, double xmax,
              Span<const double> y_edges, uint32_t flags = 0) noexcept
      : handle_(y_edges.size() > 1
                ? histo2d_create_uniform_variable(nx, xmin, xmax,
                                                  static_cast<uint32_t>(y_edges.size() - 1),
                                                  y_edges.data(), flags)
                : nullptr) {}

  // Direct Constructors (Variable - Uniform)
  Histogram2D(Span<const double> x_edges,
              uint32_t ny, double ymin, double ymax,
              uint32_t flags = 0) noexcept
      : handle_(x_edges.size() > 1
                ? histo2d_create_variable_uniform(static_cast<uint32_t>(x_edges.size() - 1),
                                                  x_edges.data(), ny, ymin, ymax, flags)
                : nullptr) {}

  // Direct Constructors (Variable - Variable)
  Histogram2D(Span<const double> x_edges, Span<const double> y_edges,
              uint32_t flags = 0) noexcept
      : handle_((x_edges.size() > 1 && y_edges.size() > 1)
                ? histo2d_create_variable(static_cast<uint32_t>(x_edges.size() - 1),
                                          x_edges.data(),
                                          static_cast<uint32_t>(y_edges.size() - 1),
                                          y_edges.data(), flags)
                : nullptr) {}

  // Static Factory Methods
  static Result<Histogram2D> UniformUniform(uint32_t nx, double xmin, double xmax,
                                            uint32_t ny, double ymin, double ymax,
                                            uint32_t flags = 0) noexcept {
    histo2d_t* h = histo2d_create_uniform(nx, xmin, xmax, ny, ymin, ymax, flags);
    if (!h) return Status(StatusCode::kInvalidArgument);
    return Histogram2D(h);
  }

  static Result<Histogram2D> UniformVariable(uint32_t nx, double xmin, double xmax,
                                             Span<const double> y_edges,
                                             uint32_t flags = 0) noexcept {
    if (y_edges.size() < 2) return Status(StatusCode::kInvalidArgument);
    histo2d_t* h = histo2d_create_uniform_variable(nx, xmin, xmax,
                                                   static_cast<uint32_t>(y_edges.size() - 1),
                                                   y_edges.data(), flags);
    if (!h) return Status(StatusCode::kInvalidArgument);
    return Histogram2D(h);
  }

  static Result<Histogram2D> VariableUniform(Span<const double> x_edges,
                                             uint32_t ny, double ymin, double ymax,
                                             uint32_t flags = 0) noexcept {
    if (x_edges.size() < 2) return Status(StatusCode::kInvalidArgument);
    histo2d_t* h = histo2d_create_variable_uniform(static_cast<uint32_t>(x_edges.size() - 1),
                                                   x_edges.data(), ny, ymin, ymax, flags);
    if (!h) return Status(StatusCode::kInvalidArgument);
    return Histogram2D(h);
  }

  static Result<Histogram2D> VariableVariable(Span<const double> x_edges,
                                              Span<const double> y_edges,
                                              uint32_t flags = 0) noexcept {
    if (x_edges.size() < 2 || y_edges.size() < 2) return Status(StatusCode::kInvalidArgument);
    histo2d_t* h = histo2d_create_variable(static_cast<uint32_t>(x_edges.size() - 1),
                                           x_edges.data(),
                                           static_cast<uint32_t>(y_edges.size() - 1),
                                           y_edges.data(), flags);
    if (!h) return Status(StatusCode::kInvalidArgument);
    return Histogram2D(h);
  }

  // Destructor & Move Operations
  ~Histogram2D() noexcept {
    if (handle_) {
      histo2d_destroy(handle_);
      handle_ = nullptr;
    }
  }

  Histogram2D(Histogram2D&& other) noexcept : handle_(other.handle_) {
    other.handle_ = nullptr;
  }

  Histogram2D& operator=(Histogram2D&& other) noexcept {
    if (this != &other) {
      if (handle_) {
        histo2d_destroy(handle_);
      }
      handle_ = other.handle_;
      other.handle_ = nullptr;
    }
    return *this;
  }

  Histogram2D(const Histogram2D&) = delete;
  Histogram2D& operator=(const Histogram2D&) = delete;

  // View conversions & handles
  constexpr bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit constexpr operator bool() const noexcept { return is_valid(); }
  constexpr histo2d_t* c_handle() noexcept { return handle_; }
  constexpr const histo2d_t* c_handle() const noexcept { return handle_; }

  Histogram2DView view() const noexcept { return Histogram2DView(handle_); }
  operator Histogram2DView() const noexcept { return view(); }

  // Forwarded read-only queries
  uint32_t nx() const noexcept { return view().nx(); }
  uint32_t ny() const noexcept { return view().ny(); }
  size_t total_bins() const noexcept { return view().total_bins(); }
  double total_weight() const noexcept { return view().total_weight(); }
  uint64_t n_entries() const noexcept { return view().n_entries(); }
  double bin_content(uint32_t ix, uint32_t iy) const noexcept { return view().bin_content(ix, iy); }
  double bin_error(uint32_t ix, uint32_t iy) const noexcept { return view().bin_error(ix, iy); }
  double region_weight(Region2D region) const noexcept { return view().region_weight(region); }
  uint64_t region_count(Region2D region) const noexcept { return view().region_count(region); }
  int32_t find_bin(double x, double y, int64_t* binx, int64_t* biny) const noexcept { return view().find_bin(x, y, binx, biny); }
  double mean_x() const noexcept { return view().mean_x(); }
  double mean_y() const noexcept { return view().mean_y(); }
  double variance_x() const noexcept { return view().variance_x(); }
  double variance_y() const noexcept { return view().variance_y(); }
  double std_dev_x() const noexcept { return view().std_dev_x(); }
  double std_dev_y() const noexcept { return view().std_dev_y(); }
  double covariance() const noexcept { return view().covariance(); }
  double correlation() const noexcept { return view().correlation(); }
  Result<Stats2D> stats() const noexcept { return view().stats(); }
  Result<Histogram> ProjectX() const noexcept { return view().ProjectX(); }
  Result<Histogram> ProjectY() const noexcept { return view().ProjectY(); }
  Result<Histogram> SliceX(uint32_t iy_min, uint32_t iy_max) const noexcept { return view().SliceX(iy_min, iy_max); }
  Result<Histogram> SliceY(uint32_t ix_min, uint32_t ix_max) const noexcept { return view().SliceY(ix_min, ix_max); }
  Result<Histogram> ProfileX() const noexcept { return view().ProfileX(); }
  Result<Histogram> ProfileY() const noexcept { return view().ProfileY(); }

  Histogram2D Clone(bool empty = false) const noexcept {
    if (!handle_) return Histogram2D();
    return Histogram2D(histo2d_clone(handle_, empty));
  }

  histo2d_t* release() noexcept {
    histo2d_t* h = handle_;
    handle_ = nullptr;
    return h;
  }

  // Ingestion
  Status Fill(double x, double y) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo2d_fill(handle_, x, y);
  }

  Status Fill(double x, double y, double weight) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo2d_fill_w(handle_, x, y, weight);
  }

  Status Fill(Span<const double> x, Span<const double> y) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    if (x.size() != y.size()) return Status(StatusCode::kInvalidArgument);
    if (x.empty()) return OkStatus();
    return histo2d_fill_n(handle_, x.size(), x.data(), y.data(), nullptr);
  }

  Status Fill(Span<const double> x, Span<const double> y, Span<const double> weights) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    if (x.size() != y.size() || x.size() != weights.size()) {
      return Status(StatusCode::kInvalidArgument);
    }
    if (x.empty()) return OkStatus();
    return histo2d_fill_n(handle_, x.size(), x.data(), y.data(), weights.data());
  }

  // Mutators
  Status Reset() noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo2d_reset(handle_);
  }

  Status Scale(double factor) noexcept {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    return histo2d_scale(handle_, factor);
  }

  Status Merge(const Histogram2DView& other, double scale = 1.0) noexcept {
    if (!handle_ || !other.c_handle()) return Status(StatusCode::kInvalidArgument);
    return histo2d_add(handle_, other.c_handle(), scale);
  }

  Histogram2D& operator+=(const Histogram2DView& other) noexcept {
    Merge(other, 1.0);
    return *this;
  }

  Histogram2D& operator*=(double factor) noexcept {
    Scale(factor);
    return *this;
  }

  // Serialization
  Result<std::vector<uint8_t>> Serialize() const {
    if (!handle_) return Status(StatusCode::kInvalidArgument);
    size_t needed = 0;
    histo_status_t st = histo2d_serialize_binary(handle_, nullptr, 0, &needed);
    if (st != HISTO_OK && st != HISTO_ERR_SERIALIZATION && needed == 0) {
      return Status(st);
    }
    std::vector<uint8_t> buffer(needed);
    size_t written = 0;
    st = histo2d_serialize_binary(handle_, buffer.data(), buffer.size(), &written);
    if (st != HISTO_OK) return Status(st);
    buffer.resize(written);
    return buffer;
  }

  static Result<Histogram2D> Deserialize(Span<const uint8_t> data) {
    if (data.empty()) return Status(StatusCode::kInvalidArgument);
    histo2d_t* h = nullptr;
    histo_status_t st = histo2d_deserialize_binary(data.data(), data.size(), &h);
    if (st != HISTO_OK || !h) return Status(st != HISTO_OK ? st : HISTO_ERR_DESERIALIZATION);
    return Histogram2D(h);
  }

 private:
  histo2d_t* handle_;
};

}  // namespace libhisto

#endif  // LIBHISTO_HISTOGRAM2D_HPP
