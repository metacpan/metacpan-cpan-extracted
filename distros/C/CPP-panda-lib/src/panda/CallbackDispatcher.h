#pragma once

#include <panda/lib/owning_list.h>
#include <panda/function.h>
#include <panda/optional.h>
#include <iostream>

namespace panda {

template <typename Ret, typename... Args>
class CallbackDispatcher {
public:
    struct Event;
    using RetType = typename optional_tools<Ret>::type;
    using Callback = function<RetType (Event&, Args...)>;
    using SimpleCallback = function<Ret (Args...)>;

    struct Wrapper {
        Callback real;
        SimpleCallback simple;

        Wrapper(Callback real, SimpleCallback simple = nullptr) : real(real), simple(simple) {}

        template <typename... RealArgs>
        RetType operator()(RealArgs&&... args) {
            return real(args...);
        }

        bool operator ==(const Wrapper& oth) {
            if (simple) {
                return simple == oth.simple;
            } else {
                return real == oth.real;
            }
        }

        bool operator ==(const SimpleCallback& oth) {
            if (simple) {
                return simple == oth;
            } else {
               return false;
            }
        }
    };

    using CallbackList = lib::owning_list<Wrapper>;

    struct Event {
        CallbackDispatcher& dispatcher;
        typename CallbackList::iterator state;

        template <typename... RealArgs>
        RetType next(RealArgs&&... args) {
            return dispatcher.next(*this, std::forward<RealArgs>(args)...);
        }
    };



    void add(const Callback& callback) {
        listeners.push_back(Wrapper(callback));
    }

    void add(Callback&& callback) {
        listeners.push_back(Wrapper(std::forward<Callback>(callback)));
    }

    void add(const SimpleCallback& callback) {
        auto wrapper = [callback](Event& e, Args... args) -> RetType {
            callback(std::forward<Args>(args)...);
            return e.next(std::forward<Args>(args)...);
        };

        static_assert(panda::has_call_operator<decltype(wrapper), Event&, Args...>::value);

        listeners.push_back(Wrapper(wrapper, callback));
    }

    template <typename... RealArgs>
    RetType operator()(RealArgs&&... args) {
        auto iter = listeners.begin();
        if (iter == listeners.end()) return optional_tools<Ret>::default_value();

        Event e{*this, iter};
        return (*iter)(e, std::forward<RealArgs>(args)...);
    }

    template <typename SmthComparable>
    void remove(const SmthComparable& callback) {
        for (auto iter = listeners.rbegin(); iter != listeners.rend(); ++iter) {
            if (*iter == callback) {
                listeners.erase(iter);
                break;
            }
        }
    }

    void remove_all() {
        listeners.clear();
    }

    bool has_listeners() const {
        return listeners.size();
    }

private:
    template <typename... RealArgs>
    RetType next(Event& e, RealArgs&&... args) {
        ++e.state;
        if (e.state != listeners.end()) {
            return (*e.state)(e, std::forward<RealArgs>(args)...);
        } else {
            return optional_tools<Ret>::default_value();
        }
    }

    CallbackList listeners;
};

template <typename Ret, typename... Args>
class CallbackDispatcher<Ret(Args...)> : public CallbackDispatcher<Ret, Args...> {};

}
