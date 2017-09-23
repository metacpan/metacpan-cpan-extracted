#include "Async.h"
#include "Scheduler.h"

#define EVAL_RETURN(next_async, blocked_async) \
    (void)  (next = next_async, blocked = blocked_async)

void
Async_run_until_completion(
        Async* async)
{
    ASYNC_LOG_DEBUG("loop for Async %p\n", async);

    Async_Trampoline_Scheduler scheduler{};

    scheduler.enqueue(async);

    while (scheduler.queue_size() > 0)
    {
        AsyncRef top = scheduler.dequeue();

        if (!top)
            break;

        Async trap;
        AsyncRef next = &trap;
        AsyncRef blocked = &trap;
        Async_eval(top.decay(), next, blocked);

        assert(next.decay() != &trap);
        assert(blocked.decay() != &trap);

        if (blocked)
            assert(next);

        if (next)
        {
            scheduler.enqueue(next.decay());

            if (blocked)
                scheduler.block_on(next.get(), blocked.decay());
        }

        if (top.decay() != next.decay() && top.decay() != blocked.decay())
        {
            ASYNC_LOG_DEBUG("completed %p\n", top.decay());
            assert(top->has_category(Async_Type::CATEGORY_COMPLETE));
            scheduler.complete(*top);
        }
    }

    ASYNC_LOG_DEBUG("loop complete\n");
}

// Type-specific cases

#define ENSURE_DEPENDENCY(self, dependency) do {                            \
    if (!(dependency)->has_category(Async_Type::CATEGORY_COMPLETE))         \
        return EVAL_RETURN((dependency), (self));                           \
} while (0)

static void Async_Ptr_eval(
        Async*      self,
        AsyncRef&   next,
        AsyncRef&   blocked)
{
    assert(self);
    assert(self->type == Async_Type::IS_PTR);

    Async* dep = self->as_ptr.decay();

    ASYNC_LOG_DEBUG("eval Ptr %p dep=%p\n", self, dep);

    ENSURE_DEPENDENCY(self, dep);

    Async* followed = &self->ptr_follow();
    if (dep != followed)
        self->as_ptr = followed;

    return EVAL_RETURN(nullptr, nullptr);
}

static
void
Async_RawThunk_eval(
        Async*  self,
        AsyncRef& next,
        AsyncRef& blocked)
{
    assert(self);
    assert(self->type == Async_Type::IS_RAWTHUNK);

    assert(0);  // TODO not implemented
}

static
void
Async_Thunk_eval(
        Async*  self,
        AsyncRef& next,
        AsyncRef& blocked)
{
    assert(self);
    assert(self->type == Async_Type::IS_THUNK);

    ASYNC_LOG_DEBUG(
            "running Thunk %p: callback=??? dependency=%p\n",
            self,
            self->as_thunk.dependency.decay());

    AsyncRef dependency = self->as_thunk.dependency;
    DestructibleTuple default_value{};
    DestructibleTuple const* values = &default_value;
    if (dependency)
    {
        dependency.fold();

        ENSURE_DEPENDENCY(self, dependency);

        if (!dependency->has_type(Async_Type::IS_VALUE))
        {
            *self = dependency.get();
            return EVAL_RETURN(NULL, NULL);
        }

        assert(dependency->type == Async_Type::IS_VALUE);
        values = &dependency->as_value;
    }

    AsyncRef result = self->as_thunk.callback(*values);
    assert(result);

    *self = result.get();

    return EVAL_RETURN(self, nullptr);
}

static
Async*
select_if_either_has_type(AsyncRef& left, AsyncRef& right, Async_Type type)
{
    if (left->has_type(type))
        return left.decay();
    if (right->has_type(type))
        return right.decay();
    return nullptr;
}

static
void
Async_Concat_eval(
        Async*  self,
        AsyncRef& next,
        AsyncRef& blocked)
{
    assert(self);
    assert(self->type == Async_Type::IS_CONCAT);

    auto& left  = self->as_binary.left.fold();
    auto& right = self->as_binary.right.fold();

    for (Async_Type type : { Async_Type::IS_CANCEL, Async_Type::IS_ERROR })
    {
        if(Async* selected  = select_if_either_has_type(left, right, type))
        {
            *self = *selected;
            return EVAL_RETURN(nullptr, nullptr);
        }
    }

    ENSURE_DEPENDENCY(self, left);
    ENSURE_DEPENDENCY(self, right);

    assert(left->type   == Async_Type::IS_VALUE);
    assert(right->type  == Async_Type::IS_VALUE);

    assert(left->as_value.vtable == right->as_value.vtable);

    auto vtable = left->as_value.vtable;
    size_t size = left->as_value.size + right->as_value.size;

    DestructibleTuple tuple {vtable, size};

    // move or copy the values,
    // depending on left/right refcount

    size_t output_i = 0;
    for (Async* source : { left.decay(), right.decay() })
    {
        auto copy_or_move =
            (source->refcount == 1)
            ? [](DestructibleTuple& input, size_t i)
                { return input.move_from(i); }
            : [](DestructibleTuple& input, size_t i)
                { return input.copy_from(i); };
        DestructibleTuple& input = source->as_value;
        for (size_t input_i = 0; input_i < input.size; input_i++, output_i++)
        {
            Destructible temp = copy_or_move(input, input_i);
            tuple.set(output_i, std::move(temp));
        }
    }

    self->clear();
    self->set_to_Value(std::move(tuple));
    return EVAL_RETURN(NULL, NULL);
}

void Async_Flow_eval(
        Async*      self,
        AsyncRef&   next,
        AsyncRef&   blocked)
{
    assert(self);
    assert(self->type == Async_Type::IS_FLOW);

    using Direction = Async_Flow::Direction;
    Async* left = self->as_flow.left.decay();
    Async* right = self->as_flow.right.decay();
    Async_Type decision_type = self->as_flow.flow_type;
    Direction flow_direction = self->as_flow.direction;

    ENSURE_DEPENDENCY(self, left);

    bool stay_left;
    switch (flow_direction)
    {
        case Direction::THEN:
            stay_left = !Async_has_category(left, decision_type);
            break;
        case Direction::OR:
            stay_left = Async_has_category(left, decision_type);
            break;
        default:
            assert(0);
    }

    if (stay_left)
    {
        *self = *left;
        return EVAL_RETURN(NULL, NULL);
    }
    else
    {
        *self = *right;
        return EVAL_RETURN(self, NULL);
    }
}

// Polymorphic

void
Async_eval(
        Async*  self,
        AsyncRef& next,
        AsyncRef& blocked)
{
    ASYNC_LOG_DEBUG(
            "running Async %p (%2d %s)\n",
            self,
            static_cast<int>(self->type),
            Async_Type_name(self->type));

    switch (self->type) {
        case Async_Type::IS_UNINITIALIZED:
            assert(0);
            break;

        case Async_Type::CATEGORY_INITIALIZED:
            assert(0);
            break;
        case Async_Type::IS_PTR:
            Async_Ptr_eval(self, next, blocked);
            break;
        case Async_Type::IS_RAWTHUNK:
            Async_RawThunk_eval(
                    self, next, blocked);
            break;
        case Async_Type::IS_THUNK:
            Async_Thunk_eval(
                    self, next, blocked);
            break;
        case Async_Type::IS_CONCAT:
            Async_Concat_eval(
                    self, next, blocked);
            break;
        case Async_Type::IS_FLOW:
            Async_Flow_eval(self, next, blocked);
            break;

        case Async_Type::CATEGORY_COMPLETE:
            assert(0);
            break;
        case Async_Type::IS_CANCEL:  // already complete
            EVAL_RETURN(NULL, NULL);
            break;

        case Async_Type::CATEGORY_RESOLVED:
            assert(0);
            break;
        case Async_Type::IS_ERROR:  // already complete
            EVAL_RETURN(NULL, NULL);
            break;
        case Async_Type::IS_VALUE:  // already complete
            EVAL_RETURN(NULL, NULL);
            break;

        default:
            assert(0);
    }

    ASYNC_LOG_DEBUG(
            "... %p result: next=%p blocked=%p\n",
            self,
            next.decay(),
            blocked.decay());
}
