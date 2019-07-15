#pragma once
#include <panda/lib/owning_list.h>
#include <panda/function.h>
#include <panda/optional.h>

namespace panda {

namespace {
    template <typename T> struct optional_type {
        using type = optional<T>;
        static type default_value() { return type{}; }
    };

    template <>
    struct optional_type<void> {
        static void default_value(){}
        using type = void;
    };
}

template <typename Ret, typename... Args>
class CallbackDispatcher {
public:
    struct Event;
    using OptionalRet    = typename optional_type<Ret>::type;
    using Callback       = function<OptionalRet(Event&, Args...)>;
    using SimpleCallback = function<void(Args...)>;

    struct Wrapper {
        Callback       real;
        SimpleCallback simple;

        explicit Wrapper (Callback real)         : real(real)     {}
        explicit Wrapper (SimpleCallback simple) : simple(simple) {}

        template <typename... RealArgs>
        auto operator() (Event& e, RealArgs&&... args) -> decltype(real(e, args...)) {
            if (real) return real(e, std::forward<RealArgs>(args)...);

            simple(args...);
            return e.next(std::forward<RealArgs>(args)...);
        }

        bool equal (const Wrapper& oth) {
            if (simple) return simple == oth.simple;
            return real == oth.real;
        }

        template <typename T>
        decltype(simple == std::declval<const T&>()) equal (const T& oth) {
            return simple && simple == oth;
        }

        template <typename T>
        decltype(real == std::declval<const T&>()) equal (const T& oth) {
            return real && real == oth;
        }
    };

    using CallbackList = lib::owning_list<Wrapper>;

    struct Event {
        CallbackDispatcher& dispatcher;
        typename CallbackList::iterator state;

        Event (const Event& oth) = delete;

        template <typename... RealArgs>
        OptionalRet next (RealArgs&&... args) {
            return dispatcher.next(*this, std::forward<RealArgs>(args)...);
        }
    };

    void add_event_listener (const Callback& callback, bool back = false) {
        if (!callback) return;
        if (back) listeners.push_back(Wrapper(callback));
        else      listeners.push_front(Wrapper(callback));
    }

    void add_event_listener (Callback&& callback, bool back = false) {
        if (!callback) return;
        if (back) listeners.push_back(Wrapper(std::forward<Callback>(callback)));
        else      listeners.push_front(Wrapper(std::forward<Callback>(callback)));
    }

    void add (const SimpleCallback& callback, bool back = false) {
        if (!callback) return;
        if (back) listeners.push_back(Wrapper(callback));
        else      listeners.push_front(Wrapper(callback));
    }

    void add (SimpleCallback&& callback, bool back = false) {
        if (!callback) return;
        if (back) listeners.push_back(Wrapper(std::forward<SimpleCallback>(callback)));
        else      listeners.push_front(Wrapper(std::forward<SimpleCallback>(callback)));
    }

    template <class T> void add_back (T&& callback) { add(std::forward<T>(callback), true); }

    template <typename... RealArgs >
    auto operator() (RealArgs&&... args) -> decltype(std::declval<Wrapper>()(std::declval<Event&>(), args...)) {
        auto iter = listeners.begin();
        if (iter == listeners.end()) return optional_type<Ret>::default_value();

        Event e{*this, iter};
        return (*iter)(e, std::forward<RealArgs>(args)...);
    }

    template <typename SmthComparable>
    void remove (const SmthComparable& callback) {
        for (auto iter = listeners.rbegin(); iter != listeners.rend(); ++iter) {
            if (iter->equal(callback)) {
                listeners.erase(iter);
                break;
            }
        }
    }

    template <typename T>
    void remove_object(T&& makable,
                       decltype(function_details::tmp_abstract_function<void, Args...>(std::forward<T>(std::declval<T>())))* = nullptr)
    {
        auto tmp = function_details::tmp_abstract_function<void, Args...>(std::forward<T>(makable));
        remove(tmp);
    }

    template <typename T>
    void remove_object(T&& makable,
                       decltype(function_details::tmp_abstract_function<OptionalRet, Event&, Args...>(std::forward<T>(std::declval<T>())))* = nullptr)
    {
        auto tmp = function_details::tmp_abstract_function<OptionalRet, Event&, Args...>(std::forward<T>(makable));
        remove(tmp);
    }

    void remove_all () {
        listeners.clear();
    }

    bool has_listeners () const {
        return listeners.size();
    }

private:
    template <typename... RealArgs>
    OptionalRet next (Event& e, RealArgs&&... args) {
        ++e.state;
        if (e.state != listeners.end()) {
            return (*e.state)(e, std::forward<RealArgs>(args)...);
        } else {
            return optional_type<Ret>::default_value();
        }
    }

    CallbackList listeners;
};

template <typename Ret, typename... Args>
class CallbackDispatcher<Ret(Args...)> : public CallbackDispatcher<Ret, Args...> {};

}
