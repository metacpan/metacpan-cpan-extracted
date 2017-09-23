#include "Async.h"

#include <cassert>

auto Async::alloc() -> AsyncRef
{
    AsyncRef ref{new Async{}, AsyncRef::no_inc};

    ASYNC_LOG_DEBUG("created new Async at %p\n", ref.decay());

    return ref;
}

auto Async::unref() -> void
{
    refcount--;

    if (refcount)
        return;

    ASYNC_LOG_DEBUG("deleting Async at %p\n", this);

    delete this;
}

auto Async::ptr_follow() -> Async&
{
    if (type != Async_Type::IS_PTR)
        return *this;

    // flatten the pointer until we reach something concrete
    AsyncRef& ptr = as_ptr;
    while (ptr->type == Async_Type::IS_PTR)
        ptr = ptr->as_ptr;

    return ptr.get();
}

auto Async::add_blocked(AsyncRef b) -> void
{
    ptr_follow().blocked.emplace_back(std::move(b));
}
