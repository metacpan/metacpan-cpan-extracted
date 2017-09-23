#pragma once

#include "Async.h"

#include <memory>

class Async_Trampoline_Scheduler {
    class Impl;
    std::unique_ptr<Impl> m_impl;

public:

    /** Create a new Scheduler.
     *
     *  initial_capacity: size_t = 32
     *      should be a powert of 2.
     */
    Async_Trampoline_Scheduler(size_t initial_capacity = 32);
    ~Async_Trampoline_Scheduler();

    /** Number of enqueued elements.
     *
     *  Returns: size_t
     *      the number of enqueued elements.
     */
    auto queue_size() const -> size_t;

    /** Enqueue an item as possibly runnable.
     *
     *  async: AsyncRef
     *      should be run in the future.
     */
    auto enqueue(AsyncRef async) -> void;

    /** Dequeue the next item.
     *
     *  You *must* enqueue() or complete() the item later!
     *
     *  Precondition: queue_size() > 0
     *      There must be at least one element present.
     *
     *  Returns: AsyncRef
     *      The next item.
     */
    auto dequeue() -> AsyncRef;

    /** Register a dependency relationship.
     *
     *  This is similar to a Makefile rule:
     *
     *      blocked_async: dependency_async
     *
     *  dependency_async: Async&
     *      must be completed first.
     *  blocked_async: AsyncRef
     *      is blocked until the "dependency_async" is completed-
     */
    auto block_on(Async& dependency_async, AsyncRef blocked_async) -> void;

    /** Mark an item as completed.
     *
     *  Any items that block on the completed items will be enqueued in an
     *  unspecified order.
     *
     *  async: Async&
     *      a completed item.
     */
    auto complete(Async& async) -> void;
};
