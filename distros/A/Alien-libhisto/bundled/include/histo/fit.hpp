// Curve fitting and non-linear regression C++ wrapper for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_FIT_HPP
#define LIBHISTO_FIT_HPP

#include <cstddef>
#include <cstdint>
#include <vector>

#include "histo/fit.h"
#include "histo/histogram.hpp"
#include "histo/status.hpp"
#include "histo/types.h"

namespace libhisto {

using FitModel = histo_fit_model_t;
using FitLoss = histo_fit_loss_t;
using FitAlgo = histo_fit_algo_t;
using FitOptions = histo_fit_options_t;
using FitStatus = histo_fit_status_t;

inline FitOptions DefaultFitOptions() noexcept {
  FitOptions opts{};
  histo_fit_options_init(&opts);
  return opts;
}

/**
 * @brief RAII container for curve fitting results and diagnostics.
 */
class FitResult {
 public:
  constexpr FitResult() noexcept : handle_(nullptr) {}
  explicit constexpr FitResult(histo_fit_result_t* handle) noexcept : handle_(handle) {}

  ~FitResult() noexcept {
    if (handle_) {
      histo_fit_result_destroy(handle_);
      handle_ = nullptr;
    }
  }

  FitResult(FitResult&& other) noexcept : handle_(other.handle_) {
    other.handle_ = nullptr;
  }

  FitResult& operator=(FitResult&& other) noexcept {
    if (this != &other) {
      if (handle_) {
        histo_fit_result_destroy(handle_);
      }
      handle_ = other.handle_;
      other.handle_ = nullptr;
    }
    return *this;
  }

  FitResult(const FitResult&) = delete;
  FitResult& operator=(const FitResult&) = delete;

  bool is_valid() const noexcept { return handle_ != nullptr; }
  explicit operator bool() const noexcept { return is_valid(); }
  const histo_fit_result_t* c_handle() const noexcept { return handle_; }

  bool converged() const noexcept { return handle_ ? handle_->converged : false; }
  size_t num_params() const noexcept { return handle_ ? handle_->num_params : 0; }
  double chi2() const noexcept { return handle_ ? handle_->chi2 : 0.0; }
  int ndf() const noexcept { return handle_ ? handle_->ndf : 0; }
  double reduced_chi2() const noexcept { return handle_ ? handle_->reduced_chi2 : 0.0; }
  double p_value() const noexcept { return handle_ ? handle_->p_value : 0.0; }
  uint32_t iterations() const noexcept { return handle_ ? handle_->iterations : 0; }
  double aic() const noexcept { return handle_ ? handle_->aic : 0.0; }
  double bic() const noexcept { return handle_ ? handle_->bic : 0.0; }

  Span<const double> params() const noexcept {
    if (!handle_ || !handle_->params) return {};
    return Span<const double>(handle_->params, handle_->num_params);
  }

  Span<const double> param_errors() const noexcept {
    if (!handle_ || !handle_->param_errors) return {};
    return Span<const double>(handle_->param_errors, handle_->num_params);
  }

  const histo_fit_result_t& raw() const noexcept { return *handle_; }

 private:
  histo_fit_result_t* handle_;
};

/**
 * @brief Performs parametric curve fitting on a 1D histogram.
 */
inline Result<FitResult> Fit(const HistogramView& h, FitModel model,
                             Span<const double> initial_params = {},
                             const FitOptions* opts = nullptr) noexcept {
  if (!h.c_handle()) return Status(StatusCode::kInvalidArgument);
  histo_fit_result_t* res = nullptr;
  const double* init_p = initial_params.empty() ? nullptr : initial_params.data();
  histo_status_t st = histo_fit_model(h.c_handle(), model, init_p, opts, &res);
  if (st != HISTO_OK && st != HISTO_WARN_NON_FINITE) {
    if (res) histo_fit_result_destroy(res);
    return Status(st);
  }
  return FitResult(res);
}

inline double EvalFitModel(FitModel model, Span<const double> params, double x) noexcept {
  return histo_fit_eval(model, params.data(), params.size(), x);
}

}  // namespace libhisto

#endif  // LIBHISTO_FIT_HPP
