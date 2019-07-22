#pragma once
#include <utility>
#include <exception>

namespace panda {

template <class E>
struct unexpected {
  static_assert(!std::is_same<E, void>::value, "E must not be void");

  unexpected () = delete;
  constexpr explicit unexpected (const E& e) : _val(e)            {}
  constexpr explicit unexpected (E&& e)      : _val(std::move(e)) {}

  constexpr const E&  value () const &  { return _val; }
  constexpr const E&& value () const && { return std::move(_val); }

  E&  value () &  { return _val; }
  E&& value () && { return std::move(_val); }

private:
    E _val;
};

template <class E>
inline unexpected<typename std::decay<E>::type> make_unexpected (E &&e) {
  return unexpected<typename std::decay<E>::type>(std::forward<E>(e));
}

template <class E>
struct bad_expected_access : std::exception {
  explicit bad_expected_access (E e) : _val(std::move(e)) {}

  virtual const char* what () const noexcept override { return "Bad expected access"; }

  const E&  error () const &  { return _val; }
  const E&& error () const && { return std::move(_val); }

  E&  error () &  { return _val; }
  E&& error () && { return std::move(_val); }

private:
  E _val;
};

/// A tag to tell expected to construct the unexpected value
struct unexpect_t { unexpect_t() = default; };
static constexpr unexpect_t unexpect {};


template <class T, class E>
struct expected {
    using value_type = T;
    using error_type = E;
    using unexpected_type = unexpected<E>;

    template <typename = typename std::enable_if<std::is_default_constructible<T>::value>::type>
    expected () {
        _has_val = true;
        ::new (&_val) T();
    }

    expected (const expected& ex) {
        if (ex._has_val) construct_val(ex._val);
        else             construct_err(ex._err);
    }

    expected (expected&& ex) {
        if (ex._has_val) construct_val(std::move(ex._val));
        else             construct_err(std::move(ex._err));
    }

    template <class T2, class E2>
    explicit expected (const expected<T2,E2>& ex) {
        if (ex._has_val) construct_val(ex._val);
        else             construct_err(ex._err);
    }

    template <class T2, class E2>
    explicit expected (expected<T2,E2>&& ex) {
        if (ex._has_val) construct_val(std::move(ex._val));
        else             construct_err(std::move(ex._err));
    }

    template <class T2>
    expected (T2&& v) {
        construct_val(std::forward<T2>(v));
    }

    template <class E2>
    expected (const unexpected<E2>& uex) {
        construct_err(uex.value());
    }

    template <class E2>
    expected (unexpected<E2>&& uex) {
        construct_err(std::move(uex.value()));
    }

    ~expected () {
        if (_has_val) _val.~T();
        else          _err.~E();
    }

    expected& operator= (const expected& ex) {
        if (ex._has_val) set_val(ex._val);
        else             set_err(ex._err);
        return *this;
    }

    expected& operator= (expected&& ex) {
        if (ex._has_val) set_val(std::move(ex._val));
        else             set_err(std::move(ex._err));
        return *this;
    }

    template <class T2>
    expected& operator= (T2&& v) {
        set_val(std::forward<T2>(v));
    }

    template <class E2>
    expected& operator= (const unexpected<E2>& uex) {
        set_err(uex.value());
    }

    template <class E2>
    expected& operator= (unexpected<E2>&& uex) {
        set_err(std::move(uex.value()));
    }

    constexpr bool     has_value     () const noexcept { return _has_val; }
    constexpr explicit operator bool () const noexcept { return _has_val; }

    const T&  value () const &  { if (!_has_val) throw bad_expected_access<E>(_err); return _val; }
          T&  value ()       &  { if (!_has_val) throw bad_expected_access<E>(_err); return _val; }
    const T&& value () const && { if (!_has_val) throw bad_expected_access<E>(_err); return std::move(_val); }
          T&& value ()       && { if (!_has_val) throw bad_expected_access<E>(_err); return std::move(_val); }

    template <class T2> constexpr T value_or (T2&& v) const & { return bool(*this) ? this->_val : static_cast<T>(std::forward<T2>(v)); }
    template <class T2> constexpr T value_or (T2&& v)      && { return bool(*this) ? std::move(this->_val) : static_cast<T>(std::forward<T2>(v)); }

    const E&  error () const &  { return _err; }
          E&  error ()       &  { return _err; }
    const E&& error () const && { return std::move(_err); }
          E&& error ()       && { return std::move(_err); }

    const T* operator-> () const { return &_val; }
          T* operator-> ()       { return &_val; }

    const T&  operator* () const &  { return _val; }
          T&  operator* ()       &  { return _val; }
    const T&& operator* () const && { return std::move(_val); }
          T&& operator* ()       && { return std::move(_val); }

    template <class...Args>
    void emplace (Args&&... args) {
        if (_has_val) _val = T(std::forward<Args>(args)...);
        else {
            auto tmp = std::move(_err);
            _err.~E();
            try {
                ::new (&_val) T(std::forward<Args>(args)...);
                _has_val = true;
            } catch (...) {
                new (&_err) E(std::move(tmp));
                throw;
            }
        }
    }

    template <class F>
    auto and_then (F&& f) const & -> decltype(f(std::declval<T>())) {
        if (!_has_val) return unexpected_type(_err);
        return f(_val);
    }

    template <class F>
    auto and_then (F&& f) const && -> decltype(f(std::declval<T>())) {
        if (!_has_val) return unexpected_type(std::move(_err));
        return f(std::move(_val));
    }

    template <class F>
    auto or_else (F&& f) const & -> decltype(f(std::declval<E>())) {
        if (_has_val) return *this;
        return f(_err);
    }

    template <class F>
    auto or_else (F&& f) const && -> decltype(f(std::declval<E>())) {
        if (_has_val) return std::move(*this);
        return f(std::move(_err));
    }

    template <class F>
    auto map (F&& f) const & -> expected<decltype(f(std::declval<T>())), E> {
        if (!_has_val) return unexpected_type(_err);
        return f(_val);
    }

    template <class F>
    auto map (F&& f) const && -> expected<decltype(f(std::declval<T>())), E> {
        if (!_has_val) return unexpected_type(std::move(_err));
        return f(std::move(_val));
    }

    template <class F>
    auto map_error (F&& f) const & -> expected<T, decltype(f(std::declval<E>()))> {
        if (_has_val) return _val;
        return make_unexpected(f(_err));
    }

    template <class F>
    auto map_error (F&& f) const && -> expected<T, decltype(f(std::declval<E>()))> {
        if (_has_val) return std::move(_val);
        return make_unexpected(f(std::move(_err)));
    }

    template <class T2 = T>
    void swap (expected& ex) {
        if (_has_val) {
            if (ex._has_val) std::swap(_val, ex._val);
            else {
                auto tmp = std::move(ex._err);
                ex._err.~E();
                ex._has_val = true;
                new (&ex._val) T(std::move(_val));

                _val.~T();
                _has_val = false;
                new (&_err) E(std::move(tmp));
            }
        }
        else {
            if (ex._has_val) ex.swap(*this);
            else std::swap(_err, ex._err);
        }
    }

private:
    template <class T2, class E2> friend struct expected;

    template <class T2>
    void construct_val (T2&& v) {
        _has_val = true;
        ::new (&_val) T(std::forward<T2>(v));
    }

    template <class E2>
    void construct_err (E2&& e) {
        _has_val = false;
        ::new (&_err) E(std::forward<E2>(e));
    }

    template <class T2>
    void set_val (T2&& v) {
        if (_has_val) _val = std::forward<T2>(v);
        else {
            _err.~E();
            _has_val = true;
            ::new (&_val) T(std::forward<T2>(v));
        }
    }

    template <class E2>
    void set_err (E2&& e) {
        if (_has_val) {
            _val.~T();
            _has_val = false;
            ::new (&_err) E(std::forward<E2>(e));
        }
        else _err = std::forward<E2>(e);
    }

    union {
        T _val;
        E _err;
    };
    bool _has_val;
};


template <class E>
struct expected<void, E> {
    using value_type = void;
    using error_type = E;
    using unexpected_type = unexpected<E>;

    expected () { _has_val = true; }

    expected (const expected& ex) {
        if (ex._has_val) _has_val = true;
        else             construct_err(ex._err);
    }

    expected (expected&& ex) {
        if (ex._has_val) _has_val = true;
        else             construct_err(std::move(ex._err));
    }

    template <class E2>
    explicit expected (const expected<void,E2>& ex) {
        if (ex._has_val) _has_val = true;
        else             construct_err(ex._err);
    }

    template <class E2>
    explicit expected (expected<void,E2>&& ex) {
        if (ex._has_val) _has_val = true;
        else             construct_err(std::move(ex._err));
    }

    template <class E2>
    expected (const unexpected<E2>& uex) {
        construct_err(uex.value());
    }

    template <class E2>
    expected (unexpected<E2>&& uex) {
        construct_err(std::move(uex.value()));
    }

    ~expected () {
        if (!_has_val) _err.~E();
    }

    expected& operator= (const expected& ex) {
        if (ex._has_val) set_val();
        else             set_err(ex._err);
        return *this;
    }

    expected& operator= (expected&& ex) {
        if (ex._has_val) set_val();
        else             set_err(std::move(ex._err));
        return *this;
    }

    template <class E2>
    expected& operator= (const unexpected<E2>& uex) {
        set_err(uex.value());
    }

    template <class E2>
    expected& operator= (unexpected<E2>&& uex) {
        set_err(std::move(uex.value()));
    }

    constexpr bool     has_value     () const noexcept { return _has_val; }
    constexpr explicit operator bool () const noexcept { return _has_val; }

    const E&  error () const &  { return _err; }
          E&  error ()       &  { return _err; }
    const E&& error () const && { return std::move(_err); }
          E&& error ()       && { return std::move(_err); }

    template <class F>
    auto and_then (F&& f) const & -> decltype(f()) {
        if (!_has_val) return unexpected_type(_err);
        return f();
    }

    template <class F>
    auto and_then (F&& f) const && -> decltype(f()) {
        if (!_has_val) return unexpected_type(std::move(_err));
        return f();
    }

    template <class F>
    auto or_else (F&& f) const & -> decltype(f(std::declval<E>())) {
        if (_has_val) return *this;
        return f(_err);
    }

    template <class F>
    auto or_else (F&& f) const && -> decltype(f(std::declval<E>())) {
        if (_has_val) return std::move(*this);
        return f(std::move(_err));
    }

    template <class F>
    auto map (F&& f) const & -> expected<decltype(f()), E> {
        if (!_has_val) return unexpected_type(_err);
        return f();
    }

    template <class F>
    auto map (F&& f) const && -> expected<decltype(f()), E> {
        if (!_has_val) return unexpected_type(std::move(_err));
        return f();
    }

    template <class F>
    auto map_error (F&& f) const & -> expected<void, decltype(f(std::declval<E>()))> {
        if (_has_val) return {};
        return make_unexpected(f(_err));
    }

    template <class F>
    auto map_error (F&& f) const && -> expected<void, decltype(f(std::declval<E>()))> {
        if (_has_val) return {};
        return make_unexpected(f(std::move(_err)));
    }

    template <class E2 = E>
    void swap (expected& ex) {
        if (_has_val) {
            if (!ex._has_val) {
                new (&_err) E(std::move(ex._err));
                ex._err.~E();
                std::swap(_has_val, ex._has_val);
            }
        }
        else {
            if (ex._has_val) ex.swap(*this);
            else std::swap(_err, ex._err);
        }
    }

private:
    template <class T2, class E2> friend struct expected;

    template <class E2>
    void construct_err (E2&& e) {
        _has_val = false;
        ::new (&_err) E(std::forward<E2>(e));
    }

    void set_val () {
        if (_has_val) return;
        _err.~E();
        _has_val = true;
    }

    template <class E2>
    void set_err (E2&& e) {
        if (_has_val) {
            _has_val = false;
            ::new (&_err) E(std::forward<E2>(e));
        }
        else _err = std::forward<E2>(e);
    }

    union {
        E _err;
    };
    bool _has_val;
};

template <class T, class E, class T2, class E2>
bool operator== (const expected<T, E>& lhs, const expected<T2, E2>& rhs) {
    if (lhs.has_value() != rhs.has_value()) return false;
    return lhs.has_value() ? *lhs == *rhs : lhs.error() == rhs.error();
}

template <class E, class E2>
bool operator== (const expected<void, E>& lhs, const expected<void, E2>& rhs) {
    if (lhs.has_value() != rhs.has_value()) return false;
    return lhs.has_value() ? true : lhs.error() == rhs.error();
}

template <class T, class E, class T2, class E2>
bool operator!= (const expected<T, E>& lhs, const expected<T2, E2>& rhs) { return !operator==(lhs, rhs); }

template <class T, class E, class T2>
typename std::enable_if<!std::is_void<T>::value, bool>::type
operator== (const expected<T, E>& x, const T2& v) { return x.has_value() ? *x == v : false; }

template <class T, class E, class T2>
bool operator== (const T2& v, const expected<T, E>& x) { return x == v; }

template <class T, class E, class T2>
bool operator!= (const expected<T, E>& x, const T2& v) { return !(x == v); }

template <class T, class E, class T2>
bool operator!= (const T2& v, const expected<T, E>& x) { return !(x == v); }

template <class T, class E>
bool operator== (const expected<T, E>& x, const unexpected<E>& e) { return x.has_value() ? false : x.error() == e.value(); }
template <class T, class E>
bool operator== (const unexpected<E>& e, const expected<T, E>& x) { return x == e; }
template <class T, class E>
bool operator!= (const expected<T, E>& x, const unexpected<E>& e) { return !(x == e); }
template <class T, class E>
bool operator!= (const unexpected<E>& e, const expected<T, E>& x) { return !(x == e); }

template <class T, class E>
void swap (expected<T,E>& lhs, expected<T,E>& rhs) { lhs.swap(rhs); }


}
