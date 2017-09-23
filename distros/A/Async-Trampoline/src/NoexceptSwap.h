#pragma once

#include <utility>
#include <cassert>

template<class T>
void noexcept_swap(T& lhs, T& rhs) noexcept
{
    using std::swap;
    static_assert(noexcept(swap(lhs, rhs)), "swap must be noexcept");
    swap(lhs, rhs);
}

namespace noexcept_swap_details {
    template<class T, class Member>
    int member_swap_helper(T& lhs, T& rhs, Member T::* member) noexcept
    {
        assert(/*must be non-null*/ member);
        noexcept_swap(lhs.*member, rhs.*member);
        return {};
    }

    inline void sink(int...) noexcept {}
}

template<class T, class... Members>
void noexcept_member_swap(T& lhs, T& rhs, Members T::*... members) noexcept
{
    using noexcept_swap_details::sink;
    using noexcept_swap_details::member_swap_helper;

    sink(member_swap_helper(lhs, rhs, members)...);
}
