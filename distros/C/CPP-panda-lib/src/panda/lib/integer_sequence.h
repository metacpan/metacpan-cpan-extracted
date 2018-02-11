#pragma once
#if __cplusplus >= 201402L
#  include <utility>
#else
namespace std {

template <typename T, T... ints>
struct integer_sequence
{ };

template <typename T, T N, typename = void>
struct make_integer_sequence_impl
{
    template <typename>
    struct tmp;

    template <T... Prev>
    struct tmp<integer_sequence<T, Prev...>>
    {
        using type = integer_sequence<T, Prev..., N-1>;
    };

    using type = typename tmp<typename make_integer_sequence_impl<T, N-1>::type>::type;
};

template <typename T, T N>
struct make_integer_sequence_impl<T, N, typename std::enable_if<N==0>::type>
{ using type = integer_sequence<T>; };

template <typename T, T N>
using make_integer_sequence = typename make_integer_sequence_impl<T, N>::type;

}

#endif
