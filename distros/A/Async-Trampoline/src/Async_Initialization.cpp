#include "Async.h"

#include <memory>
#include <utility>

#define UNUSED(x) (void)(x)

#define BINARY_INIT(name, type)                                             \
    void Async::set_to_ ## name (AsyncRef left, AsyncRef right)             \
    { set_to_Binary(*this, type, std::move(left), std::move(right)); }

#define ASSERT_INIT(self) do {                                              \
    assert((self)->type == Async_Type::IS_UNINITIALIZED);                   \
} while (0)

static void set_to_Binary(Async& self, Async_Type, AsyncRef, AsyncRef);

static void Async_Ptr_clear        (Async* self);
static void Async_RawThunk_clear   (Async* self);
static void Async_Thunk_clear      (Async* self);
static void Async_Binary_clear     (Async& self, Async_Type type);
static void Async_Flow_clear       (Async& self);
static void Async_Cancel_clear     (Async* self);
static void Async_Error_clear      (Async* self);
static void Async_Value_clear      (Async* self);

// Polymorphic

auto Async::clear() -> void
{
    ASYNC_LOG_DEBUG("clear() " ASYNC_FORMAT "\n",
            ASYNC_FORMAT_ARGS(this));

    switch (type) {
        case Async_Type::IS_UNINITIALIZED:
            break;

        case Async_Type::CATEGORY_INITIALIZED:
            assert(0);
            break;
        case Async_Type::IS_PTR:
            Async_Ptr_clear(this);
            break;
        case Async_Type::IS_RAWTHUNK:
            Async_RawThunk_clear(this);
            break;
        case Async_Type::IS_THUNK:
            Async_Thunk_clear(this);
            break;
        case Async_Type::IS_CONCAT:
            Async_Binary_clear(*this, type);
            break;
        case Async_Type::IS_FLOW:
            Async_Flow_clear(*this);
            break;

        case Async_Type::CATEGORY_COMPLETE:
            assert(0);
            break;
        case Async_Type::IS_CANCEL:
            Async_Cancel_clear(this);
            break;

        case Async_Type::CATEGORY_RESOLVED:
            assert(0);
            break;
        case Async_Type::IS_ERROR:
            Async_Error_clear(this);
            break;
        case Async_Type::IS_VALUE:
            Async_Value_clear(this);
            break;

        default:
            assert(0);
    }
}

auto Async::set_from(Async&& other) -> void
{
    assert(type == Async_Type::IS_UNINITIALIZED);

    assert(other.blocked.size() == 0);

    switch (other.type)
    {
        case Async_Type::IS_UNINITIALIZED:
            break;

        case Async_Type::CATEGORY_INITIALIZED:
            assert(0);
            break;
        case Async_Type::IS_PTR:
            set_to_Ptr(std::move(other.as_ptr));
            Async_Ptr_clear(&other);
            break;
        case Async_Type::IS_RAWTHUNK:
            assert(0); // TODO not implemented
            break;
        case Async_Type::IS_THUNK:
            set_to_Thunk(
                    std::move(other.as_thunk.callback),
                    std::move(other.as_thunk.dependency));
            Async_Thunk_clear(&other);
            break;
        case Async_Type::IS_CONCAT:
            set_to_Binary(
                    *this,
                    other.type,
                    std::move(other.as_binary.left),
                    std::move(other.as_binary.right));
            Async_Binary_clear(other, other.type);
            break;
        case Async_Type::IS_FLOW:
            set_to_Flow(std::move(other.as_flow));
            Async_Flow_clear(other);
            break;

        case Async_Type::CATEGORY_COMPLETE:
            assert(0);
            break;
        case Async_Type::IS_CANCEL:
            set_to_Cancel();
            Async_Cancel_clear(&other);
            break;

        case Async_Type::CATEGORY_RESOLVED:
            assert(0);
            break;
        case Async_Type::IS_ERROR:
            set_to_Error(std::move(other.as_error));
            Async_Error_clear(&other);
            break;
        case Async_Type::IS_VALUE:
            set_to_Value(std::move(other.as_value));
            Async_Value_clear(&other);
            break;

        default:
            assert(0);
    }

}

auto Async::operator=(Async& other) -> Async&
{
    ASYNC_LOG_DEBUG("unify " ASYNC_FORMAT " with " ASYNC_FORMAT "\n",
            ASYNC_FORMAT_ARGS(this),
            ASYNC_FORMAT_ARGS(&other));

    // as a special case, CANCEL holds no resources and can always be copied
    if (other.has_type(Async_Type::IS_CANCEL))
    {
        clear();
        set_to_Cancel();
        return *this;
    }

    if (other.refcount > 1)
    {
        AsyncRef ref{&other};  // keep ref in case we own it
        clear();
        set_to_Ptr(std::move(ref));
        return *this;
    }

    assert(other.refcount == 1); // caller is the only owner

    // save other in case we might own it, because we clear() ourself.
    AsyncRef unref_me{};
    if (type != Async_Type::IS_UNINITIALIZED)
        unref_me = &other;

    clear();

    set_from(std::move(other));
    return *this;
}

// Ptr

void Async::set_to_Ptr(
        AsyncRef target)
{
    ASSERT_INIT(this);
    assert(target);

    target.fold();

    ASYNC_LOG_DEBUG("init %p to Ptr: target=" ASYNC_FORMAT "\n",
            this,
            ASYNC_FORMAT_ARGS(target.decay()));

    type = Async_Type::IS_PTR;
    new (&as_ptr) AsyncRef { std::move(target) };

    //  // transfer all dependencies to target
    //  Async& target_ref = ptr_follow();
    //  for (auto& depref : blocked)
    //      target_ref.add_blocked(std::move(depref));
    //  blocked.clear();
}

void
Async_Ptr_clear(
        Async*  self)
{
    assert(self);
    assert(self->type == Async_Type::IS_PTR);

    ASYNC_LOG_DEBUG("clear %p of Ptr: target=" ASYNC_FORMAT "\n",
            self,
            ASYNC_FORMAT_ARGS(self->as_ptr.decay()));

    self->type = Async_Type::IS_UNINITIALIZED;
    self->as_ptr.~AsyncRef();
}

// RawThunk

void Async::set_to_RawThunk(
        Async_RawThunk::Callback    callback,
        AsyncRef                    dependency)
{
    ASSERT_INIT(this);
    assert(callback);

    UNUSED(dependency);

    assert(0); // TODO not implemented
}

void
Async_RawThunk_clear(
        Async*  self)
{
    assert(self);
    assert(self->type == Async_Type::IS_RAWTHUNK);

    assert(0);  // TODO not implemented
}

// Thunk

void Async::set_to_Thunk(
        Async_Thunk::Callback   callback,
        AsyncRef                dependency)
{
    ASSERT_INIT(this);
    assert(callback);

    if (dependency)
        dependency.fold();

    ASYNC_LOG_DEBUG(
            "init %p to Thunk: callback=??? dependency=" ASYNC_FORMAT "\n",
            this,
            ASYNC_FORMAT_ARGS(dependency.decay()));

    type = Async_Type::IS_THUNK;
    new (&as_thunk) Async_Thunk{
        std::move(callback),
        std::move(dependency),
    };
}

void
Async_Thunk_clear(
        Async*  self)
{
    assert(self);
    assert(self->type == Async_Type::IS_THUNK);

    ASYNC_LOG_DEBUG(
            "clear %p of Thunk: callback=??? dependency=" ASYNC_FORMAT "\n",
            self,
            ASYNC_FORMAT_ARGS(self->as_thunk.dependency.decay()));

    self->type = Async_Type::IS_UNINITIALIZED;
    self->as_thunk.~Async_Thunk();
}

// Binary

static void set_to_Binary(
        Async&      self,
        Async_Type  type,
        AsyncRef    left,
        AsyncRef    right)
{
    ASSERT_INIT(&self);
    assert(left);
    assert(right);

    left.fold();
    right.fold();

    ASYNC_LOG_DEBUG(
            "init %p to Binary %s: "
            "left=" ASYNC_FORMAT " "
            "right=" ASYNC_FORMAT "\n",
            &self,
            Async_Type_name(type),
            ASYNC_FORMAT_ARGS(left.decay()),
            ASYNC_FORMAT_ARGS(right.decay()));

    self.type = type;
    new (&self.as_binary) Async_Pair {
        std::move(left),
        std::move(right),
    };
}

static void Async_Binary_clear(
        Async&      self,
        Async_Type  type)
{
    assert(self.type == type);

    ASYNC_LOG_DEBUG(
            "clear %p from Binary %s: "
            "left=" ASYNC_FORMAT " "
            "right=" ASYNC_FORMAT "\n",
            &self,
            Async_Type_name(self.type),
            ASYNC_FORMAT_ARGS(self.as_binary.left.decay()),
            ASYNC_FORMAT_ARGS(self.as_binary.right.decay()));

    self.type = Async_Type::IS_UNINITIALIZED;
    self.as_binary.~Async_Pair();
}

BINARY_INIT(Concat,     Async_Type::IS_CONCAT)

// Flow

void Async::set_to_Flow(Async_Flow flow)
{
    ASSERT_INIT(this);
    assert(flow.left);
    assert(flow.right);

    flow.left.fold();
    flow.right.fold();

    ASYNC_LOG_DEBUG(
            "init %p to Flow: "
            "left=" ASYNC_FORMAT " "
            "right=" ASYNC_FORMAT " "
            "decision=%s "
            "flow=%s\n",
            this,
            ASYNC_FORMAT_ARGS(flow.left.decay()),
            ASYNC_FORMAT_ARGS(flow.right.decay()),
            Async_Type_name(flow.flow_type),
            (flow.direction == Async_Flow::THEN)        ? "THEN"
                : (flow.direction == Async_Flow::OR)    ? "OR"
                : "(unknown)");

    type = Async_Type::IS_FLOW;
    new (&as_flow) Async_Flow( std::move(flow) );
}

static void Async_Flow_clear(Async& self)
{
    assert(self.type == Async_Type::IS_FLOW);

    ASYNC_LOG_DEBUG(
            "clear %p from Flow: "
            "left=" ASYNC_FORMAT " "
            "right=" ASYNC_FORMAT " "
            "decision=%s "
            "flow=%s\n",
            &self,
            ASYNC_FORMAT_ARGS(self.as_flow.left.decay()),
            ASYNC_FORMAT_ARGS(self.as_flow.right.decay()),
            Async_Type_name(self.as_flow.flow_type),
            (self.as_flow.direction == Async_Flow::THEN)        ? "THEN"
                : (self.as_flow.direction == Async_Flow::OR)    ? "OR"
                : "(unknown)");

    self.type = Async_Type::IS_UNINITIALIZED;
    self.as_flow.~Async_Flow();
}

// Cancel

void Async::set_to_Cancel()
{
    ASSERT_INIT(this);

    ASYNC_LOG_DEBUG("init %p to Cancel\n", this);

    type = Async_Type::IS_CANCEL;
}

void
Async_Cancel_clear(
        Async* self)
{
    assert(self);
    assert(self->type == Async_Type::IS_CANCEL);

    ASYNC_LOG_DEBUG("clear %p of Cancel\n", self);

    self->type = Async_Type::IS_UNINITIALIZED;
}

// Error

void Async::set_to_Error(
        Destructible    error)
{
    ASSERT_INIT(this);
    assert(error.vtable);

    ASYNC_LOG_DEBUG("init %p to Error: " DESTRUCTIBLE_FORMAT "\n",
            this,
            DESTRUCTIBLE_FORMAT_ARGS(error));

    type = Async_Type::IS_ERROR;
    new (&as_error) Destructible { std::move(error) };
}

void
Async_Error_clear(
        Async*  self)
{
    assert(self);
    assert(self->type == Async_Type::IS_ERROR);

    ASYNC_LOG_DEBUG("clear %p from Error: " DESTRUCTIBLE_FORMAT "\n",
            self,
            DESTRUCTIBLE_FORMAT_ARGS(self->as_error));

    self->type = Async_Type::IS_UNINITIALIZED;
    self->as_error.~Destructible();
}

// Value

void Async::set_to_Value(
        DestructibleTuple               values)
{
    ASSERT_INIT(this);

    if (ASYNC_TRAMPOLINE_DEBUG)
    {
        ASYNC_LOG_DEBUG(
                "init %p to Values: values=%p size=%zu\n",
                this, values.data.get(), values.size);
        for (auto val : values)
        {
            ASYNC_LOG_DEBUG("  - value " DESTRUCTIBLE_FORMAT "\n",
                    DESTRUCTIBLE_FORMAT_ARGS_BORROWED(values.vtable, val));
        }
    }

    type = Async_Type::IS_VALUE;
    new (&as_value) DestructibleTuple{std::move(values)};
}

void
Async_Value_clear(
        Async*  self)
{
    assert(self);
    assert(self->type == Async_Type::IS_VALUE);

    if (ASYNC_TRAMPOLINE_DEBUG)
    {
        ASYNC_LOG_DEBUG(
                "clear %p from Values: values=%p size=%zu\n",
                self, self->as_value.data.get(), self->as_value.size);

        for (auto val : self->as_value)
        {
            ASYNC_LOG_DEBUG("  - value " DESTRUCTIBLE_FORMAT "\n",
                    DESTRUCTIBLE_FORMAT_ARGS_BORROWED(
                        self->as_value.vtable,
                        val));
        }
    }

    self->type = Async_Type::IS_UNINITIALIZED;
    self->as_value.~DestructibleTuple();
}
