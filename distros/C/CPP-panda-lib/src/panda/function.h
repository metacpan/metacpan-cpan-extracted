#pragma once
#include <utility>
#include <panda/refcnt.h>
#include "function_utils.h"

namespace panda {

using std::remove_reference;

template <typename Ret, typename... Args>
class function;

template <typename Ret, typename... Args>
class function {
public:
    using Func = iptr<Ifunction<Ret, Args...>>;
    Func func;

public:
    function(){}
    function(std::nullptr_t){}

    template <typename Derr>
    function(const iptr<Derr>& f) : func(f) {}

    template<typename... F,
             typename = decltype(function_details::make_abstract_function<Ret, Args...>(std::declval<F>()...)),
             typename = typename std::enable_if<!std::is_constructible<function, F...>::value>::type>
    function(F&&... f)
        : func(function_details::make_abstract_function<Ret, Args...>(std::forward<F>(f)...))
    {}

    function(Func func) : func(func) {};

    function(const function& oth) = default;
    function(function&& oth) = default;

    function& operator=(const function& oth) = default;
    function& operator=(function&& oth) = default;

    Ret operator ()(Args... args) const {return func->operator ()(std::forward<Args>(args)...);}

    template <typename ORet, typename... OArgs,
              typename = typename std::enable_if<std::is_convertible<function<ORet, OArgs...>, function>::value>::type>
    bool operator ==(const function<ORet, OArgs...>& oth) const {
        return (func && func->equals(oth.func.get())) || (!func && !oth.func);
    }

    template <typename ORet, typename... OArgs,
              typename = typename std::enable_if<std::is_convertible<function<ORet, OArgs...>, function>::value>::type>
    bool operator !=(const function<ORet, OArgs...>& oth) const {return !operator ==(oth);}

    bool operator ==(const Ifunction<Ret, Args...>& oth) const {
        return func && func->equals(&oth);
    }
    bool operator !=(const Ifunction<Ret, Args...>& oth) const {return !operator ==(oth);}

    explicit operator bool() const {
        return func;
    }
};

template <typename Ret, typename... Args>
class function<Ret (Args...)> : public function<Ret, Args...>{
public:
    using function<Ret, Args...>::function;
    using ArgsTuple = std::tuple<Args...>;
    using RetType = Ret;
};

template <class Class, typename Ret, typename... Args>
inline function<Ret( Args...)> make_function(Ret (Class::*meth)(Args...), iptr<Class> thiz = nullptr) {
    return function<Ret(Args...)>(meth, thiz);
}

template <typename Ret, typename... Args>
inline function<Ret (Args...)> make_function(Ret (*f)(Args...)) {
    return function<Ret(Args...)>(f);
}

}

