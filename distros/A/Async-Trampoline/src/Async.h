#pragma once
#include "Destructible.h"
#include "NoexceptSwap.h"

#include <cassert>
#include <functional>
#include <vector>
#include <utility>

#ifndef ASYNC_TRAMPOLINE_DEBUG
#define ASYNC_TRAMPOLINE_DEBUG 0
#define ASYNC_LOG_DEBUG(...) do {                                           \
    if (0) _async_log_debug_ignoreall(__VA_ARGS__);                         \
} while (0)
template<class... Args>
static inline void _async_log_debug_ignoreall(Args&&...) { }
#else
#include <cstdio>
#define ASYNC_TRAMPOLINE_DEBUG 1
#define ASYNC_LOG_DEBUG(...) do {                                           \
    fprintf(stderr, "#DEBUG Async: " __VA_ARGS__);                          \
    fflush(stderr);                                                         \
} while (0)
#endif /* ifndef ASYNC_TRAMPOLINE_DEBUG */

#define ASYNC_FORMAT "<Async %p %s ref=%zu blocks=%zu>"
#define ASYNC_FORMAT_ARGS(aptr)                                          \
    (aptr),                                                                 \
    ((aptr) ? Async_Type_name((aptr)->type) : "(NULL)"),                    \
    ((aptr) ? (aptr)->refcount : 0),                                        \
    ((aptr) ? (aptr)->blocked.size() : 0)

enum class Async_Type
{
    IS_UNINITIALIZED,

    CATEGORY_INITIALIZED,
    IS_PTR,
    IS_RAWTHUNK,
    IS_THUNK,
    IS_CONCAT,
    IS_FLOW,

    CATEGORY_COMPLETE,
    IS_CANCEL,

    CATEGORY_RESOLVED,
    IS_ERROR,
    IS_VALUE,
};

inline
const char*
Async_Type_name(enum Async_Type type)
{
    switch (type) {
        case Async_Type::IS_UNINITIALIZED:      return "IS_UNINITIALIZED";
        case Async_Type::CATEGORY_INITIALIZED:  return "CATEGORY_INITIALIZED";
        case Async_Type::IS_PTR:                return "IS_PTR";
        case Async_Type::IS_RAWTHUNK:           return "IS_RAWTHUNK";
        case Async_Type::IS_THUNK:              return "IS_THUNK";
        case Async_Type::IS_CONCAT:             return "IS_CONCAT";
        case Async_Type::IS_FLOW:               return "IS_FLOW";
        case Async_Type::CATEGORY_COMPLETE:     return "CATEGORY_COMPLETE";
        case Async_Type::IS_CANCEL:             return "IS_CANCEL";
        case Async_Type::CATEGORY_RESOLVED:     return "CATEGORY_RESOLVED";
        case Async_Type::IS_ERROR:              return "IS_ERROR";
        case Async_Type::IS_VALUE:              return "IS_VALUE";
        default:                                return "(unknown)";
    }
}

struct Async;

class AsyncRef
{
    Async* ptr;

    struct NoInc{};
public:
    static constexpr NoInc no_inc{};

    AsyncRef() noexcept : ptr{nullptr} {}
    AsyncRef(Async* ptr);
    AsyncRef(Async* ptr, NoInc) : ptr{ptr} {}
    AsyncRef(AsyncRef const& other) : AsyncRef{other.ptr} {}
    AsyncRef(AsyncRef&& other) noexcept : AsyncRef{}
    { noexcept_swap(*this, other); }
    ~AsyncRef() { clear(); }

    auto clear() -> void;

    friend auto swap(AsyncRef& lhs, AsyncRef& rhs) noexcept -> void
    {
        noexcept_member_swap(lhs, rhs,
                &AsyncRef::ptr);
    }

    auto operator=(AsyncRef other) noexcept -> AsyncRef&
    { noexcept_swap(*this, other); return *this; }

    auto decay()        -> Async*       { return ptr; }
    auto decay() const  -> Async const* { return ptr; }
    auto get()          -> Async&       { return *ptr; }
    auto get() const    -> Async const& { return *ptr; }
    auto operator*()        -> Async&       { return *ptr; }
    auto operator*() const  -> Async const& { return *ptr; }
    auto operator->()       -> Async*       { return ptr; }
    auto operator->() const -> Async const* { return ptr; }
    operator bool() const { return ptr; }

    auto fold() -> AsyncRef&;

    auto ptr_with_ownership() && noexcept -> Async*
    {
        Async* retval = nullptr;
        noexcept_swap(retval, ptr);
        return retval;
    }
};

struct Async_RawThunk
{
    using Callback = std::function<AsyncRef(AsyncRef dependency)>;
    Callback    callback;
    AsyncRef    dependency;
};

struct Async_Thunk
{
    using Callback = std::function<AsyncRef(DestructibleTuple const& data)>;
    Callback    callback;
    AsyncRef    dependency;
};

struct Async_Pair
{
    AsyncRef left;
    AsyncRef right;
};

struct Async_Flow
{
    AsyncRef left;
    AsyncRef right;
    Async_Type flow_type;
    enum Direction { THEN, OR } direction;
};

struct Async_Uninitialized {};

struct Async
{
    Async_Type type;
    size_t refcount;
    union {
        Async_Uninitialized as_uninitialized;
        AsyncRef            as_ptr;
        Async_Thunk         as_thunk;
        Async_Pair          as_binary;
        Async_Flow          as_flow;
        Destructible        as_error;
        DestructibleTuple   as_value;
    };
    std::vector<AsyncRef> blocked;

    Async() :
        type{Async_Type::IS_UNINITIALIZED},
        refcount{1},
        as_ptr{nullptr},
        blocked{}
    { }
    Async(Async&& other) : Async{} { set_from(std::move(other)); }
    ~Async() {
        assert(blocked.size() == 0);
        clear();
        assert(type == Async_Type::IS_UNINITIALIZED);
    }

    auto ref() noexcept -> Async& { refcount++; return *this; }
    auto unref() -> void;

    auto operator=(Async& other) -> Async&;
    auto clear() -> void;
    auto set_from(Async&& other) -> void;

    void set_to_Ptr         (AsyncRef target);
    void set_to_RawThunk    (Async_RawThunk::Callback callback, AsyncRef dep);
    void set_to_Thunk       (Async_Thunk::Callback    callback, AsyncRef dep);
    void set_to_Concat      (AsyncRef left, AsyncRef right);
    void set_to_Flow        (Async_Flow);
    void set_to_Cancel      ();
    void set_to_Error       (Destructible error);
    void set_to_Value       (DestructibleTuple values);

    auto add_blocked(AsyncRef blocked) -> void;

    auto ptr_follow() -> Async&;

    auto has_category(Async_Type type) -> bool
    { return ptr_follow().type >= type; }

    auto has_type(Async_Type type) -> bool
    { return ptr_follow().type == type; }

    static auto alloc() -> AsyncRef;
};

inline AsyncRef::AsyncRef(Async* ptr) : AsyncRef{ptr, no_inc} {
    if (ptr)
        ptr->ref();
}

inline auto AsyncRef::clear() -> void {
    if (ptr)
        ptr->unref();
    ptr = nullptr;
}

// Evaluation: Async_X_evaluate()
// Incomplete -> Complete
void
Async_eval(
        Async*  self,
        AsyncRef& next,
        AsyncRef& blocked);

inline auto AsyncRef::fold() -> AsyncRef&
{
    Async* target = &ptr->ptr_follow();
    if (target != ptr)
        *this = target;
    return *this;
}

inline static
AsyncRef&
Async_Ptr_fold(AsyncRef& ptr)
{
    return ptr.fold();
}

inline
bool
Async_has_type(
        Async* self,
        enum Async_Type type)
{ assert(self); return self->has_type(type); }

inline
bool
Async_has_category(
        Async* self,
        enum Async_Type category)
{ assert(self); return self->has_category(category); }

void
Async_run_until_completion(
        Async*  async);

