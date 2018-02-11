#pragma once

#include <panda/refcnt.h>
#include <iostream>

namespace panda {

using panda::shared_ptr;

template <typename Ret, typename... Args>
class function;

template <typename Ret, typename... Args>
struct Ifunction : virtual public RefCounted {
    virtual ~Ifunction() {}
    virtual Ret operator()(Args...) = 0;
    virtual bool equals(const Ifunction* oth) const = 0;
};

template<typename T, bool Trivial = std::is_class<T>::value>
struct is_comparable {
    static const bool value = true;
};

template<typename T>
struct is_comparable<T, true> {
    struct fallback { bool operator==(const fallback& oth); };
    struct mixed_type: std::remove_reference<T>::type, fallback {};
    template < typename U, U > struct type_check {};

    template < typename U > static std::false_type  test( type_check< bool (fallback::*)(const fallback&), &U::operator== >* = 0 );
    template < typename U > static std::true_type   test( ... );

    static const bool value = std::is_same<decltype(test<mixed_type>(nullptr)), std::true_type>::value;
};


template<typename T, typename... Args>
struct has_call_operator {
private:
    typedef std::true_type yes;
    typedef std::false_type no;

    template<typename U> static auto test(int) -> decltype(std::declval<U>()(std::declval<Args>()...), yes());
    template<typename> static no test(...);

public:
    static constexpr bool value = std::is_same<decltype(test<T>(0)),yes>::value;
};


template <typename Func, typename Ret, bool Comparable, typename... Args>
class abstract_function {};

template <typename Func, typename Ret, bool SELF, typename Self,  typename... Args>
class callable {};

template <typename Func, typename Ret, typename Self, typename... Args>
class callable<Func, Ret, false, Self, Args...>
{
public:
    template <typename F>
    explicit callable(F&& f) : func(std::forward<F>(f)) {}

    Ret operator()(Self&, Args... args) {
        return func(args...);
    }
protected:
    typename std::remove_reference<Func>::type func;
};

template <typename Func, typename Ret, typename Self, typename... Args>
class callable<Func, Ret, true, Self, Args...>
{
public:
    template <typename F>
    explicit callable(F&& f) : func(std::forward<F>(f)) {}

    Ret operator()(Self& self, Args... args) {
        return func(self, args...);
    }
protected:
    typename std::remove_reference<Func>::type func;
};


template <typename Func, typename Ret, typename... Args>
class abstract_function<Func, Ret, true, Args...> : public Ifunction<Ret, Args...>{
public:
    template <typename F>
    explicit abstract_function(F&& f) : func(std::forward<F>(f)) {}

    Ret operator()(Args... args) override {
        static_assert(std::is_convertible<decltype(func(args...)), Ret>::value, "return type mismatch");
        return func(args...);
    }

    bool equals(const Ifunction<Ret, Args...>* oth) const override {
        auto foth = dynamic_cast<const abstract_function*>(oth);
        if (foth == nullptr) {
            return false;
        }

        return func == foth->func;
    }

    typename std::remove_reference<Func>::type func;
};

template <typename Func, typename Ret, typename... Args>
class abstract_function<Func, Ret, false, Args...> : public Ifunction<Ret, Args...>
        , public callable<Func, Ret, !has_call_operator<Func, Args...>::value, Ifunction<Ret, Args...>, Args...>
{
public:
    using Derfed = typename std::remove_reference<Func>::type;
    using Caller = callable<Func, Ret, !has_call_operator<Func, Args...>::value, Ifunction<Ret, Args...>, Args...>;

    template <typename F>
    explicit abstract_function(F&& f) : Caller(std::forward<F>(f)) {}

    Ret operator()(Args... args) override {
        return Caller::operator()(*this, args...);
    }

    bool equals(const Ifunction<Ret, Args...>* oth) const override {
        return static_cast<const Ifunction<Ret, Args...>*>(this) == oth;
    }

private:
    template <Ret(Derfed::*meth)(Args...)>
    Ret call(Args... args) {
       return (this->template func.*meth)(args...);
    }

//    template <Ret(Derfed::*meth)(int, Args...)>
//    Ret call(Args... args) {
//       return (this->template func.*meth)(10, args...);
//    }
};


template <typename Ret, typename... Args>
class abstract_function<Ret (*)(Args...), Ret, true, Args...> : public Ifunction<Ret, Args...> {
public:
    using Func = Ret (*)(Args...);
    explicit abstract_function(const Func& f) : func(f) {}

    Ret operator()(Args... args) override {
        return func(args...);
    }

    bool equals(const Ifunction<Ret, Args...>* oth) const override {
        auto foth = dynamic_cast<const abstract_function*>(oth);
        if (foth == nullptr) return false;

        return func == foth->func;
    }

    Ret (*func)(Args...);
};

template <typename Ret, typename... Args>
auto make_abstract_function(Ret (*f)(Args...)) -> shared_ptr<abstract_function<Ret (*)(Args...), Ret, true, Args...>> {
    return panda::make_shared<abstract_function<Ret (*)(Args...), Ret, true, Args...>>(f);
}

template <typename Ret, typename... Args>
auto tmp_abstract_function(Ret (*f)(Args...)) -> abstract_function<Ret (*)(Args...), Ret, true, Args...> {
    return abstract_function<Ret (*)(Args...), Ret, true, Args...>(f);
}

template <typename Ret, typename... Args,
          typename Functor, bool IsComp = is_comparable<typename std::remove_reference<Functor>::type>::value,
          typename DeFunctor = typename std::remove_reference<Functor>::type,
          typename Check = decltype(std::declval<Functor>()(std::declval<Args>()...))>
shared_ptr<abstract_function<DeFunctor, Ret, IsComp, Args...>> make_abstract_function(Functor&& f, Check(*)() = 0) {
    return panda::make_shared<abstract_function<DeFunctor, Ret, IsComp, Args...>>(std::forward<Functor>(f));
}

template <typename Ret, typename... Args,
          typename Functor, bool IsComp = is_comparable<typename std::remove_reference<Functor>::type>::value,
          typename DeFunctor = typename std::remove_reference<Functor>::type,
          typename Check = decltype(std::declval<Functor>()(std::declval<Args>()...))>
abstract_function<DeFunctor, Ret, IsComp, Args...> tmp_abstract_function(Functor&& f, Check(*)() = 0) {
    return abstract_function<DeFunctor, Ret, IsComp, Args...>(std::forward<Functor>(f));
}

template <typename Ret, typename... Args,
          typename Functor, bool IsComp = is_comparable<typename std::remove_reference<Functor>::type>::value,
          typename DeFunctor = typename std::remove_reference<Functor>::type,
          typename Check = decltype(std::declval<Functor>()(std::declval<Ifunction<Ret, Args...>&>(), std::declval<Args>()...))>
shared_ptr<abstract_function<DeFunctor, Ret, IsComp, Args...>> make_abstract_function(Functor&& f) {
    return panda::make_shared<abstract_function<DeFunctor, Ret, IsComp, Args...>>(std::forward<Functor>(f));
}

template <typename Ret, typename... Args,
          typename Functor, bool IsComp = is_comparable<typename std::remove_reference<Functor>::type>::value,
          typename DeFunctor = typename std::remove_reference<Functor>::type,
          typename Check = decltype(std::declval<Functor>()(std::declval<Ifunction<Ret, Args...>&>(), std::declval<Args>()...))>
abstract_function<DeFunctor, Ret, IsComp, Args...> tmp_abstract_function(Functor&& f) {
    return abstract_function<DeFunctor, Ret, IsComp, Args...>(std::forward<Functor>(f));
}

template <class Class, typename Ret, typename... Args>
struct method : public Ifunction<Ret, Args...>{
    using Method = Ret (Class::*)(Args...);
    using ifunction = Ifunction<Ret, Args...>;

    method(Method method, shared_ptr<Class> thiz = nullptr) : thiz(thiz), meth(method) {}
    shared_ptr<method, true> bind(shared_ptr<Class> thiz) {
        this->thiz = thiz;
        return shared_ptr<method, true>(this);
    }

    Ret operator()(Args... args) override {
        return (thiz.get()->*meth)(std::forward<Args>(args)...);
    }

    bool equals(const ifunction* oth) const override {
        auto moth = dynamic_cast<const method<Class, Ret, Args...>*>(oth);
        if (moth == nullptr) return false;

        return operator ==(*moth);
    }

    bool operator==(const method& oth) const {
        return thiz == oth.thiz && meth == oth.meth;
    }

    bool operator !=(const method& oth) const {
        return !operator ==(oth);
    }

    explicit operator bool() const {
        return thiz && meth;
    }

private:
    shared_ptr<Class> thiz;
    Method meth;
};

template <class Class, typename Ret, typename... Args>
inline shared_ptr<method<Class, Ret, Args...>> make_method(Ret (Class::*meth)(Args...), shared_ptr<Class> thiz = nullptr) {
    return panda::make_shared<method<Class, Ret, Args...>>(meth, thiz);
}

template <typename Ret, typename... Args, class Class>
inline shared_ptr<method<Class, Ret, Args...>> make_abstract_function(Ret (Class::*meth)(Args...), shared_ptr<Class> thiz = nullptr) {
    return panda::make_shared<method<Class, Ret, Args...>>(meth, thiz);
}

template <typename Ret, typename... Args, class Class>
inline method<Class, Ret, Args...> tmp_abstract_function(Ret (Class::*meth)(Args...), shared_ptr<Class> thiz = nullptr) {
    return method<Class, Ret, Args...>(meth, thiz);
}
}
