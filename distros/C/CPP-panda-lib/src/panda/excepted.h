#pragma once
#include "expected.h"
#include <utility>

namespace panda {

namespace {
    template <class E>
    inline typename std::enable_if<!std::is_base_of<std::exception, typename std::decay<E>::type>::value, void>::type exthrow (E&& e) {
        throw bad_expected_access<typename std::decay<E>::type>(std::forward<E>(e));
    }

    template <class E>
    inline typename std::enable_if<std::is_base_of<std::exception, typename std::decay<E>::type>::value, void>::type exthrow (E&& e) {
        throw std::forward<E>(e);
    }
}

template <class T, class E>
struct excepted {
    using value_type = T;
    using error_type = E;
    using unexpected_type = unexpected<E>;

    template <typename = typename std::enable_if<std::is_default_constructible<T>::value>::type>
    excepted () {
        _has_val = true;
        ::new (&_val) T();
    }

    excepted (const excepted& ex) {
        if (ex._has_val) construct_val(ex._val);
        else {
            construct_err(ex._err);
            ex._checked = true;
        }
    }

    excepted (excepted&& ex) {
        if (ex._has_val) construct_val(std::move(ex._val));
        else {
            construct_err(std::move(ex._err));
            ex._checked = true;
        }
    }

    template <class T2, class E2>
    explicit excepted (const excepted<T2,E2>& ex) {
        if (ex._has_val) construct_val(ex._val);
        else {
            construct_err(ex._err);
            ex._checked = true;
        }
    }

    template <class T2, class E2>
    explicit excepted (excepted<T2,E2>&& ex) {
        if (ex._has_val) construct_val(std::move(ex._val));
        else {
            construct_err(std::move(ex._err));
            ex._checked = true;
        }
    }

    template <class T2>
    excepted (T2&& v) {
        construct_val(std::forward<T2>(v));
    }

    template <class E2>
    excepted (const unexpected<E2>& uex) {
        construct_err(uex.value());
    }

    template <class E2>
    excepted (unexpected<E2>&& uex) {
        construct_err(std::move(uex.value()));
    }

    ~excepted () noexcept(false) {
        if      (_has_val) _val.~T();
        else if (_checked) _err.~E();
        else {
            auto tmp = std::move(_err);
            _err.~E();
            exthrow(std::move(tmp));
        }
    }

    excepted& operator= (const excepted& ex) {
        if (ex._has_val) set_val(ex._val);
        else {
            set_err(ex._err);
            ex._checked = true;
        }
        return *this;
    }

    excepted& operator= (excepted&& ex) {
        if (ex._has_val) set_val(std::move(ex._val));
        else {
            set_err(std::move(ex._err));
            ex._checked = true;
        }
        return *this;
    }

    template <class T2>
    excepted& operator= (T2&& v) {
        set_val(std::forward<T2>(v));
    }

    template <class E2>
    excepted& operator= (const unexpected<E2>& uex) {
        set_err(uex.value());
    }

    template <class E2>
    excepted& operator= (unexpected<E2>&& uex) {
        set_err(std::move(uex.value()));
    }

    constexpr bool     has_value     () const noexcept { _checked = true; return _has_val; }
    constexpr explicit operator bool () const noexcept { _checked = true; return _has_val; }

    const T&  value () const &  { if (!has_value()) exthrow(_err); return _val; }
          T&  value ()       &  { if (!has_value()) exthrow(_err); return _val; }
    const T&& value () const && { if (!has_value()) exthrow(_err); return std::move(_val); }
          T&& value ()       && { if (!has_value()) exthrow(_err); return std::move(_val); }

    template <class T2> constexpr T value_or (T2&& v) const & { _checked = true; return bool(*this) ? this->_val : static_cast<T>(std::forward<T2>(v)); }
    template <class T2> constexpr T value_or (T2&& v)      && { _checked = true; return bool(*this) ? std::move(this->_val) : static_cast<T>(std::forward<T2>(v)); }

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
        _checked = true;
        if (!_has_val) return unexpected_type(_err);
        return f(_val);
    }

    template <class F>
    auto and_then (F&& f) const && -> decltype(f(std::declval<T>())) {
        _checked = true;
        if (!_has_val) return unexpected_type(std::move(_err));
        return f(std::move(_val));
    }

    template <class F>
    auto or_else (F&& f) const & -> decltype(f(std::declval<E>())) {
        _checked = true;
        if (_has_val) return *this;
        return f(_err);
    }

    template <class F>
    auto or_else (F&& f) const && -> decltype(f(std::declval<E>())) {
        _checked = true;
        if (_has_val) return std::move(*this);
        return f(std::move(_err));
    }

    template <class F>
    auto map (F&& f) const & -> excepted<decltype(f(std::declval<T>())), E> {
        _checked = true;
        if (!_has_val) return unexpected_type(_err);
        return f(_val);
    }

    template <class F>
    auto map (F&& f) const && -> excepted<decltype(f(std::declval<T>())), E> {
        _checked = true;
        if (!_has_val) return unexpected_type(std::move(_err));
        return f(std::move(_val));
    }

    template <class F>
    auto map_error (F&& f) const & -> excepted<T, decltype(f(std::declval<E>()))> {
        _checked = true;
        if (_has_val) return _val;
        return make_unexpected(f(_err));
    }

    template <class F>
    auto map_error (F&& f) const && -> excepted<T, decltype(f(std::declval<E>()))> {
        _checked = true;
        if (_has_val) return std::move(_val);
        return make_unexpected(f(std::move(_err)));
    }

    template <class T2 = T>
    void swap (excepted& ex) {
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
                _checked = ex._checked;
            }
        }
        else {
            if (ex._has_val) ex.swap(*this);
            else std::swap(_err, ex._err);
        }
    }

    void nevermind () const { _checked = true; }

private:
    template <class T2, class E2> friend class excepted;

    template <class T2>
    void construct_val (T2&& v) {
        _has_val = true;
        ::new (&_val) T(std::forward<T2>(v));
    }

    template <class E2>
    void construct_err (E2&& e) {
        _has_val = false;
        _checked = false;
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
        _checked = false;
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
    mutable bool _checked;
};


template <class E>
struct excepted<void, E> {
    using value_type = void;
    using error_type = E;
    using unexpected_type = unexpected<E>;

    excepted () { _has_val = true; }

    excepted (const excepted& ex) {
        if (ex._has_val) _has_val = true;
        else {
            construct_err(ex._err);
            ex._checked = true;
        }
    }

    excepted (excepted&& ex) {
        if (ex._has_val) _has_val = true;
        else {
            construct_err(std::move(ex._err));
            ex._checked = true;
        }
    }

    template <class E2>
    explicit excepted (const excepted<void,E2>& ex) {
        if (ex._has_val) _has_val = true;
        else {
            construct_err(ex._err);
            ex._checked = true;
        }
    }

    template <class E2>
    explicit excepted (excepted<void,E2>&& ex) {
        if (ex._has_val) _has_val = true;
        else {
            construct_err(std::move(ex._err));
            ex._checked = true;
        }
    }

    template <class E2>
    excepted (const unexpected<E2>& uex) {
        construct_err(uex.value());
    }

    template <class E2>
    excepted (unexpected<E2>&& uex) {
        construct_err(std::move(uex.value()));
    }

    ~excepted () noexcept(false) {
        if      (_has_val) return;
        else if (_checked) _err.~E();
        else {
            auto tmp = std::move(_err);
            _err.~E();
            exthrow(std::move(tmp));
        }
    }

    excepted& operator= (const excepted& ex) {
        if (ex._has_val) set_val();
        else {
            set_err(ex._err);
            ex._checked = true;
        }
        return *this;
    }

    excepted& operator= (excepted&& ex) {
        if (ex._has_val) set_val();
        else {
            set_err(std::move(ex._err));
            ex._checked = true;
        }
        return *this;
    }

    template <class E2>
    excepted& operator= (const unexpected<E2>& uex) {
        set_err(uex.value());
    }

    template <class E2>
    excepted& operator= (unexpected<E2>&& uex) {
        set_err(std::move(uex.value()));
    }

    constexpr bool     has_value     () const noexcept { _checked = true; return _has_val; }
    constexpr explicit operator bool () const noexcept { _checked = true; return _has_val; }

    const E&  error () const &  { return _err; }
          E&  error ()       &  { return _err; }
    const E&& error () const && { return std::move(_err); }
          E&& error ()       && { return std::move(_err); }

    template <class F>
    auto and_then (F&& f) const & -> decltype(f()) {
        _checked = true;
        if (!_has_val) return unexpected_type(_err);
        return f();
    }

    template <class F>
    auto and_then (F&& f) const && -> decltype(f()) {
        _checked = true;
        if (!_has_val) return unexpected_type(std::move(_err));
        return f();
    }

    template <class F>
    auto or_else (F&& f) const & -> decltype(f(std::declval<E>())) {
        _checked = true;
        if (_has_val) return *this;
        return f(_err);
    }

    template <class F>
    auto or_else (F&& f) const && -> decltype(f(std::declval<E>())) {
        _checked = true;
        if (_has_val) return std::move(*this);
        return f(std::move(_err));
    }

    template <class F>
    auto map (F&& f) const & -> excepted<decltype(f()), E> {
        _checked = true;
        if (!_has_val) return unexpected_type(_err);
        return f();
    }

    template <class F>
    auto map (F&& f) const && -> excepted<decltype(f()), E> {
        _checked = true;
        if (!_has_val) return unexpected_type(std::move(_err));
        return f();
    }

    template <class F>
    auto map_error (F&& f) const & -> excepted<void, decltype(f(std::declval<E>()))> {
        _checked = true;
        if (_has_val) return {};
        return make_unexpected(f(_err));
    }

    template <class F>
    auto map_error (F&& f) const && -> excepted<void, decltype(f(std::declval<E>()))> {
        _checked = true;
        if (_has_val) return {};
        return make_unexpected(f(std::move(_err)));
    }

    template <class E2 = E>
    void swap (excepted& ex) {
        if (_has_val) {
            if (!ex._has_val) {
                new (&_err) E(std::move(ex._err));
                ex._err.~E();
                std::swap(_has_val, ex._has_val);
                _checked = ex._checked;
            }
        }
        else {
            if (ex._has_val) ex.swap(*this);
            else std::swap(_err, ex._err);
        }
    }

    void nevermind () const { _checked = true; }

private:
    template <class T2, class E2> friend class excepted;

    template <class E2>
    void construct_err (E2&& e) {
        _has_val = false;
        _checked = false;
        ::new (&_err) E(std::forward<E2>(e));
    }

    void set_val () {
        if (_has_val) return;
        _err.~E();
        _has_val = true;
    }

    template <class E2>
    void set_err (E2&& e) {
        _checked = false;
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
    mutable bool _checked;
};

template <class T, class E, class T2, class E2>
bool operator== (const excepted<T, E>& lhs, const excepted<T2, E2>& rhs) {
    if (lhs.has_value() != rhs.has_value()) return false;
    return lhs.has_value() ? *lhs == *rhs : lhs.error() == rhs.error();
}

template <class E, class E2>
bool operator== (const excepted<void, E>& lhs, const excepted<void, E2>& rhs) {
    if (lhs.has_value() != rhs.has_value()) return false;
    return lhs.has_value() ? true : lhs.error() == rhs.error();
}

template <class T, class E, class T2, class E2>
bool operator!= (const excepted<T, E>& lhs, const excepted<T2, E2>& rhs) { return !operator==(lhs, rhs); }

template <class T, class E, class T2>
typename std::enable_if<!std::is_void<T>::value, bool>::type
operator== (const excepted<T, E>& x, const T2& v) { return x.has_value() ? *x == v : false; }

template <class T, class E, class T2>
bool operator== (const T2& v, const excepted<T, E>& x) { return x == v; }

template <class T, class E, class T2>
bool operator!= (const excepted<T, E>& x, const T2& v) { return !(x == v); }

template <class T, class E, class T2>
bool operator!= (const T2& v, const excepted<T, E>& x) { return !(x == v); }

template <class T, class E>
bool operator== (const excepted<T, E>& x, const unexpected<E>& e) { return x.has_value() ? false : x.error() == e.value(); }
template <class T, class E>
bool operator== (const unexpected<E>& e, const excepted<T, E>& x) { return x == e; }
template <class T, class E>
bool operator!= (const excepted<T, E>& x, const unexpected<E>& e) { return !(x == e); }
template <class T, class E>
bool operator!= (const unexpected<E>& e, const excepted<T, E>& x) { return !(x == e); }

template <class T, class E>
void swap (excepted<T,E>& lhs, excepted<T,E>& rhs) { lhs.swap(rhs); }

}
