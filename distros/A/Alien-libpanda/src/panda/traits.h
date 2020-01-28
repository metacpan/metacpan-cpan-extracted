#pragma once
#include <utility>

namespace panda {

namespace detail {
    template <bool...> struct bool_pack {};
}

/// bool_or returns its first argument converted to bool if it is possible, or default value (second arg) if type is not convertible to bool
template <typename T>
inline bool bool_or (T&& val, decltype(bool(val))) {
    return bool(val);
}

template <typename T, typename = typename std::enable_if<!std::is_constructible<bool, T>::value>::type>
inline bool bool_or (T&&, bool default_val) {
    return default_val;
}

template <typename T, bool Trivial = std::is_class<T>::value>
struct is_comparable {
    static const bool value = true;
};

template <typename T>
struct is_comparable<T, true> {
    struct fallback { bool operator==(const fallback& oth); };
    struct mixed_type: std::remove_reference<T>::type, fallback {};
    template < typename U, U > struct type_check {};

    template < typename U > static std::false_type  test( type_check< bool (fallback::*)(const fallback&), &U::operator== >* = 0 );
    template < typename U > static std::true_type   test( ... );

    static const bool value = std::is_same<decltype(test<mixed_type>(nullptr)), std::true_type>::value;
};

template <typename T, typename... Args>
struct has_call_operator {
private:
    typedef std::true_type yes;
    typedef std::false_type no;

    template<typename U> static auto test(int) -> decltype(std::declval<U>()(std::declval<Args>()...), yes());
    template<typename> static no test(...);

public:
    static constexpr bool value = std::is_same<decltype(test<T>(0)),yes>::value;
};

template <class FROM, class TO> using enable_if_convertible_t = std::enable_if_t<std::is_convertible<FROM, TO>::value>;

template <bool...T> using conjunction = std::is_same<detail::bool_pack<true,T...>, detail::bool_pack<T..., true>>;
template <bool...T> using disjunction = std::integral_constant<bool, !std::is_same<detail::bool_pack<false,T...>, detail::bool_pack<T..., false>>::value>;

template <class T, class...Args> using is_one_of           = disjunction<std::is_same<T,Args>::value...>;
template <class T, class...Args> using enable_if_one_of_t  = std::enable_if_t<is_one_of<T,Args...>::value, T>;
template <class T, class...Args> using enable_if_one_of_vt = std::enable_if_t<is_one_of<T,Args...>::value, void>;

template <class T, class R = T> using enable_if_arithmetic_t        = std::enable_if_t<std::is_arithmetic<T>::value, R>;
template <class T, class R = T> using enable_if_signed_integral_t   = std::enable_if_t<std::is_integral<T>::value && std::is_signed<T>::value, R>;
template <class T, class R = T> using enable_if_unsigned_integral_t = std::enable_if_t<std::is_integral<T>::value && std::is_unsigned<T>::value, R>;
template <class T, class R = T> using enable_if_floatp_t            = std::enable_if_t<std::is_floating_point<T>::value, R>;

}
