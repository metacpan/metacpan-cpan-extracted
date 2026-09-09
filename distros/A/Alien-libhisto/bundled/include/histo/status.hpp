// Core exception-free status codes, Status container, and Result<T> for libhisto.
// Compliant with Google C++ style guide with zero runtime and memory overhead.

#ifndef LIBHISTO_STATUS_HPP
#define LIBHISTO_STATUS_HPP

#include <cstdint>
#include <string_view>
#include <utility>
#include <new>

#include "histo/types.h"
#include "histo/histo.h"

namespace libhisto {

/**
 * @brief Strongly typed status codes mirroring histo_status_t.
 */
enum class StatusCode : int32_t {
  kOk                  = HISTO_OK,
  kWarnNonFinite       = HISTO_WARN_NON_FINITE,
  kInvalidArgument     = HISTO_ERR_INVALID_ARG,
  kOutOfMemory         = HISTO_ERR_NOMEM,
  kIncompatible        = HISTO_ERR_INCOMPATIBLE,
  kOutOfRange          = HISTO_ERR_OUT_OF_RANGE,
  kNonFinite           = HISTO_ERR_NON_FINITE,
  kEmpty               = HISTO_ERR_EMPTY,
  kDivisionByZero      = HISTO_ERR_DIV_BY_ZERO,
  kSerialization       = HISTO_ERR_SERIALIZATION,
  kDeserialization     = HISTO_ERR_DESERIALIZATION
};

/**
 * @brief Lightweight, exception-free status container.
 */
class Status {
 public:
  constexpr Status() noexcept : code_(StatusCode::kOk) {}
  constexpr Status(StatusCode code) noexcept : code_(code) {}
  constexpr Status(histo_status_t status) noexcept 
      : code_(static_cast<StatusCode>(status)) {}

  constexpr bool ok() const noexcept {
    return code_ == StatusCode::kOk || code_ == StatusCode::kWarnNonFinite;
  }

  constexpr StatusCode code() const noexcept { return code_; }
  constexpr histo_status_t c_status() const noexcept {
    return static_cast<histo_status_t>(code_);
  }

  const char* message() const noexcept {
    return histo_status_str(static_cast<histo_status_t>(code_));
  }

  explicit constexpr operator bool() const noexcept { return ok(); }
  constexpr bool operator==(const Status& other) const noexcept {
    return code_ == other.code_;
  }
  constexpr bool operator!=(const Status& other) const noexcept {
    return code_ != other.code_;
  }
  constexpr bool operator==(StatusCode code) const noexcept {
    return code_ == code;
  }
  constexpr bool operator!=(StatusCode code) const noexcept {
    return code_ != code;
  }

 private:
  StatusCode code_;
};

inline constexpr Status OkStatus() noexcept {
  return Status(StatusCode::kOk);
}

/**
 * @brief Exception-free outcome container holding either a value T or an error Status.
 */
template <typename T>
class Result {
 public:
  // Construct from successful value
  Result(const T& val) noexcept(std::is_nothrow_copy_constructible_v<T>)
      : status_(StatusCode::kOk) {
    new (&storage_.value) T(val);
  }

  Result(T&& val) noexcept(std::is_nothrow_move_constructible_v<T>)
      : status_(StatusCode::kOk) {
    new (&storage_.value) T(std::move(val));
  }

  // Construct from error Status
  Result(Status status) noexcept : status_(status) {
    if (status_.ok()) {
      status_ = Status(StatusCode::kInvalidArgument);
    }
  }

  Result(StatusCode code) noexcept : Result(Status(code)) {}
  Result(histo_status_t status) noexcept : Result(Status(status)) {}

  ~Result() noexcept {
    if (status_.ok()) {
      storage_.value.~T();
    }
  }

  // Move operations
  Result(Result&& other) noexcept(std::is_nothrow_move_constructible_v<T>)
      : status_(other.status_) {
    if (status_.ok()) {
      new (&storage_.value) T(std::move(other.storage_.value));
    }
  }

  Result& operator=(Result&& other) noexcept(
      std::is_nothrow_move_constructible_v<T> && std::is_nothrow_destructible_v<T>) {
    if (this != &other) {
      if (status_.ok()) {
        storage_.value.~T();
      }
      status_ = other.status_;
      if (status_.ok()) {
        new (&storage_.value) T(std::move(other.storage_.value));
      }
    }
    return *this;
  }

  // Copy operations
  Result(const Result& other) noexcept(std::is_nothrow_copy_constructible_v<T>)
      : status_(other.status_) {
    if (status_.ok()) {
      new (&storage_.value) T(other.storage_.value);
    }
  }

  Result& operator=(const Result& other) noexcept(
      std::is_nothrow_copy_constructible_v<T> && std::is_nothrow_destructible_v<T>) {
    if (this != &other) {
      if (status_.ok()) {
        storage_.value.~T();
      }
      status_ = other.status_;
      if (status_.ok()) {
        new (&storage_.value) T(other.storage_.value);
      }
    }
    return *this;
  }

  bool ok() const noexcept { return status_.ok(); }
  explicit operator bool() const noexcept { return ok(); }
  Status status() const noexcept { return status_; }

  T& value() & noexcept { return storage_.value; }
  const T& value() const& noexcept { return storage_.value; }
  T&& value() && noexcept { return std::move(storage_.value); }

  T* operator->() noexcept { return &storage_.value; }
  const T* operator->() const noexcept { return &storage_.value; }
  T& operator*() & noexcept { return storage_.value; }
  const T& operator*() const& noexcept { return storage_.value; }
  T&& operator*() && noexcept { return std::move(storage_.value); }

  template <typename U>
  T value_or(U&& default_value) const& {
    return ok() ? storage_.value : static_cast<T>(std::forward<U>(default_value));
  }

  template <typename U>
  T value_or(U&& default_value) && {
    return ok() ? std::move(storage_.value) : static_cast<T>(std::forward<U>(default_value));
  }

 private:
  union Storage {
    char dummy;
    T value;
    constexpr Storage() noexcept : dummy(0) {}
    ~Storage() noexcept {}
  } storage_;

  Status status_;
};

}  // namespace libhisto

#define HISTO_STATUS_MACROS_CONCAT_INNER(x, y) x##y
#define HISTO_STATUS_MACROS_CONCAT(x, y) HISTO_STATUS_MACROS_CONCAT_INNER(x, y)

#define HISTO_RETURN_IF_ERROR(expr)                         \
  do {                                                      \
    const ::libhisto::Status _status = (expr);              \
    if (!_status.ok()) {                                    \
      return _status;                                       \
    }                                                       \
  } while (0)

#define HISTO_ASSIGN_OR_RETURN_IMPL(result_var, lhs, rexpr) \
  auto result_var = (rexpr);                                \
  if (!result_var.ok()) {                                   \
    return result_var.status();                             \
  }                                                         \
  lhs = std::move(result_var).value()

#define HISTO_ASSIGN_OR_RETURN(lhs, rexpr)                  \
  HISTO_ASSIGN_OR_RETURN_IMPL(                              \
      HISTO_STATUS_MACROS_CONCAT(_status_or_value_, __LINE__), lhs, rexpr)

#endif  // LIBHISTO_STATUS_HPP
