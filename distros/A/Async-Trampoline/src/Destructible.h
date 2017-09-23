#pragma once

#include "NoexceptSwap.h"

#include <cassert>
#include <memory>

#define DESTRUCTIBLE_FORMAT "<%p refs=%zu \"%s\">"
#define DESTRUCTIBLE_FORMAT_ARGS_BORROWED(vtable, data)                     \
    (data),                                                                 \
    ((data) ? (vtable)->get_refcount((data)) : 0),                          \
    ((data) ? (vtable)->get_stringification((data)) : "<null>")
#define DESTRUCTIBLE_FORMAT_ARGS(d)                                         \
    DESTRUCTIBLE_FORMAT_ARGS_BORROWED((d).vtable, (d).data)

struct Destructible_Vtable {
    using DestroyT = void (*)(void* data);
    using CopyT = void* (*)(void* data);
    using GetRefcntT = size_t (*)(void* data);
    using GetStringficationT = const char* (*)(void* data);

    DestroyT destroy;
    CopyT copy;
    GetRefcntT get_refcount;
    GetStringficationT get_stringification;

    Destructible_Vtable(
            DestroyT destroy,
            CopyT copy,
            GetRefcntT get_refcount,
            GetStringficationT get_stringification) :
        destroy{destroy},
        copy{copy},
        get_refcount{get_refcount},
        get_stringification{get_stringification}
    {
        assert(destroy);
        assert(copy);
        assert(get_refcount);
        assert(get_stringification);
    }
};

struct Destructible {
    void*                       data;
    Destructible_Vtable const*  vtable;

    Destructible(void* data, Destructible_Vtable const* vtable) :
        data{data}, vtable{vtable}
    {
        assert(data);
        assert(vtable);
    }

    Destructible(Destructible&& other) noexcept :
        data{nullptr}, vtable{nullptr}
    { noexcept_swap(*this, other); }

    Destructible(Destructible const& other) :
        Destructible{other.vtable->copy(other.data), other.vtable}
    {}

    auto clear() -> void
    {
        if (vtable)
            vtable->destroy(data);
        data = nullptr;
        vtable = nullptr;
    }

    ~Destructible()
    {
        clear();
    }

    friend auto swap(Destructible& lhs, Destructible& rhs) noexcept -> void
    {
        noexcept_member_swap(lhs, rhs,
                &Destructible::data,
                &Destructible::vtable);
    }

    auto operator= (Destructible other) -> Destructible&
    {
        swap(*this, other);
        return *this;
    }
};

struct DestructibleTuple {
    Destructible_Vtable const* vtable;
    size_t size;
    std::unique_ptr<void*[]> data;

    DestructibleTuple() :
        vtable{nullptr}, size{0}, data{nullptr}
    {}

    DestructibleTuple(Destructible_Vtable const* vtable, size_t size) :
        vtable{vtable},
        size{size},
        data{new void*[size]}
    {
        assert(vtable);
        for (size_t i = 0; i < size; i++)
            data[i] = nullptr;
    }

    DestructibleTuple(DestructibleTuple const& other) :
        DestructibleTuple{other.vtable, other.size}
    {
        for (size_t i = 0; i < size; i++)
            data[i] = vtable->copy(other.data[i]);
    }

    DestructibleTuple(DestructibleTuple&& other) noexcept :
        DestructibleTuple{}
    { noexcept_swap(*this, other); }

    ~DestructibleTuple()
    {
        for (size_t i = 0; i < size; i++)
        {
            vtable->destroy(data[i]);
            data[i] = nullptr;
        }
    }

    friend void swap(DestructibleTuple& lhs, DestructibleTuple& rhs) noexcept
    {
        noexcept_member_swap(lhs, rhs,
                &DestructibleTuple::vtable,
                &DestructibleTuple::size,
                &DestructibleTuple::data);
    }

    auto operator=(DestructibleTuple other) noexcept -> DestructibleTuple&
    { noexcept_swap(*this, other); return *this; }

    auto begin()        -> void**       { return &data[0]; }
    auto begin() const  -> void* const* { return &data[0]; }
    auto end()          -> void**       { return &data[size]; }
    auto end() const    -> void* const* { return &data[size]; }

    auto at(size_t i) const -> void*
    {
        assert(i < size);
        return data[i];
    }

    auto copy_from(size_t i) const -> Destructible
    { return { vtable->copy(at(i)), vtable }; }

    auto move_from(size_t i) -> Destructible
    {
        assert(i < size);
        Destructible result { data[i], vtable };
        data[i] = nullptr;
        return result;
    }

    auto set(size_t i, Destructible source) -> void
    {
        assert(vtable == source.vtable);
        assert(i < size);
        assert(data[i] == nullptr);

        noexcept_swap(data[i], source.data);
        source.vtable = nullptr;  // to avoid empty dtor from running
    }
};
