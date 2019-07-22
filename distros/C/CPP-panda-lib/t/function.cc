#include "test.h"
#include <panda/function.h>
#include <panda/function_utils.h>
#include <panda/refcnt.h>
#include <panda/string.h>

using panda::function;
using panda::make_function;
using panda::iptr;
using panda::function_details::make_method;
using panda::function_details::tmp_abstract_function;
using test::Tracer;

namespace test {


void void_func(){}
void void_func2(){}
void func_int(int){}
void func_int16(int16_t){}
void func_double(int){}

int foo2() {return 1;}
int plus_one(int a) { return a + 1;}

class Test : public panda::Refcnt {
public:
    int value = 0;

    Test(int value) : value(value) {}
    Test() : value(0) {}

    void foo(int) {}
    void foo2(int) {}
    int bar() {return value + 40;}

    int operator()(int v) {return v;}
    bool operator == (const Test& oth) const { return value == oth.value;}
};
}

using namespace test;

TEST_CASE("simplest function", "[function]") {
    function<void(void)> f = &void_func;
    REQUIRE(true);
}

TEST_CASE("simplest function call", "[function]") {
    function<int(int)> f;
    f = &plus_one;
    REQUIRE(f(1) == 2);
}

TEST_CASE("function by reference call", "[function]") {
    function<int(int)> f;
    f = plus_one;
    REQUIRE(f(1) == 2);
}

TEST_CASE("simplest lambda call", "[function]") {
    int a = 13;
    function<int(void)> f = [&](){return a;};
    REQUIRE(f() == 13);
}

TEST_CASE("simplest method call", "[function]") {
    iptr<Test> t = new Test();
    t->value = 14;
    auto m = make_function(&Test::bar, t);
    REQUIRE(m() == 54);
}

TEST_CASE("mixedcall", "[function]") {
    iptr<Test> t = new Test();
    t->value = 14;
    auto f = make_function(&Test::bar, t);
    REQUIRE(f() == 54);

    f = &foo2;
    REQUIRE(f() == 1);

    int a = 13;
    f = [&](){return a;};
    REQUIRE(f() == 13);
}

TEST_CASE("function ptr comparations", "[function]") {
    function<void(void)> f1_void = &void_func;
    function<void(void)> f2_void = &void_func;
    function<void(void)> f3_void = &void_func2;

    REQUIRE(f1_void == f2_void);
    REQUIRE(f1_void != f3_void);

    REQUIRE(f1_void == tmp_abstract_function(&void_func));
    REQUIRE(f1_void != tmp_abstract_function(&void_func2));
}

TEST_CASE("function ptr comparations covariant", "[function]") {
    struct Int {
        void operator()(int) {}
        bool operator==(const Int&) const {
            return true;
        }
    };

    function<void(int)>    f1(&func_int);
    function<void(double)> f2(&func_int);
    function<void(double)> f3(&func_double);
    function<void(double)> f4(&func_int);

    CHECK(f1 == f2);
    CHECK(f1 != f3);
    CHECK(f2 != f3);
    CHECK(f2 == f4);

    Int i;
    function<void(int)>    ff1(i);
    function<void(double)> ff2(i);

    CHECK(ff1 == ff2);
}

TEST_CASE("function covariant copy comparations", "[function]") {
    bool called = false;
    auto lambda = [&](int a) {
        called = true;
        return a;
    };

    function<int(int16_t)> f1 = lambda;
    function<int(int)> f2(f1);
    CHECK(f1 == f2);
    CHECK(f2 == f1);
}

TEST_CASE("methods comparations", "[function]") {
    iptr<Test> t = new Test();
    auto m1 = make_function(&Test::foo, t);
    auto m2 = make_method(&Test::foo);
    REQUIRE(m1 != *m2);

    m2->bind(t);
    REQUIRE(m1 == function<void(int)>(m2));

    iptr<Test> t2 = new Test();
    m2->bind(t2);
    REQUIRE(m1 != *m2);

    auto m3 = make_method(&Test::foo2);
    REQUIRE(m1 != *m3);

}

TEST_CASE("lambdas comparations", "[function]") {
    int a = 10;
    function<int(void)> l1 = [&](){return a;};
    auto l2 = l1;
    function<int(void)> l3 = [&](){return a;};

    REQUIRE(l1 == l2);
    REQUIRE(l1 != l3);
}

TEST_CASE("mixed function comparations", "[function]") {
    int a = 10;
    function<int(void)> l = [&](){return a;};
    function<int(void)> f = &foo2;
    iptr<Test> t = new Test();
    auto m = make_function(&Test::bar, t);

    REQUIRE(l != f);
    REQUIRE(m != l);
    REQUIRE(m != f);
}

TEST_CASE("functors comparations", "[function]") {
    function<int(int)> f1 = Test(1);
    function<int(int)> f2 = Test(2);
    function<int(int)> f11 = Test(1);

    REQUIRE(f1 != f2);
    REQUIRE(f1 == f11);

    auto tmp1 = tmp_abstract_function<int, int>(Test(1)); // inited from rvalue
    REQUIRE(f1 == tmp1);
}

TEST_CASE("function copy ellision", "[function]") {
    Tracer::refresh();
    {
        function<int(int)> f = Tracer(10);
        auto f2 = f;
        f(11);
        f2(12);
    }
    REQUIRE(Tracer::ctor_calls == 1); // 1 for temporary object Tracer(10);
    REQUIRE(Tracer::copy_calls == 0);
    REQUIRE(Tracer::move_calls == 1); // 1 construction from tmp object function<int(int)> f = Tracer(10);
    REQUIRE(Tracer::dtor_calls == 2);
}

TEST_CASE("covariant return type optional" , "[function]") {
    function<panda::optional<int> (int)> cb = [](int a) -> int {
        return a;
    };
    REQUIRE(cb(3).value_or(42) == 3);
}

TEST_CASE("covariant return type double" , "[function]") {
    function<double (int)> cb = [](int a) -> int {
        return a;
    };
    REQUIRE(cb(3) == 3.0);
}

TEST_CASE("contravariance of arguments" , "[function]") {
    function<double (int)> cb = [](double) -> int {
        return 10;
    };
    REQUIRE(cb(3) == 10);
}

TEST_CASE("contravariance of arguments classes" , "[function]") {
    using panda::string;
    struct Base {
        virtual ~Base(){}
        virtual string name() { return "base";}
    };
    struct Derrived : Base {
        virtual string name() override { return "override";}
    };
    function<Base& (Derrived&)> cb = [](Base& b) -> Base& {
        return b;
    };
    Derrived b;
    REQUIRE(cb(b).name() == b.name());
}

function<int(int)> lamda() {
    Tracer t(1);
    auto wrapper = [t](int a) -> int {
        Tracer o = t;
        return a + 1;
    };
    return wrapper;
}


TEST_CASE("function memory", "[function]") {

    Tracer::refresh();
    {
        auto wrapper = lamda();
        REQUIRE(wrapper(10) == 11);
    }

    REQUIRE(Tracer::ctor_total() == Tracer::dtor_calls);
}


TEST_CASE("lambda self reference", "[function]") {
    int a = 1;
    int b;
    function<void(void)> outer;
    {
        auto inner = [=, &b](panda::Ifunction<void>& self) mutable {
            if (a == 1) {
                a++;
                self();;
            } else {
                b = 43;
            }
        };
        outer = inner;
    }
    outer();
    REQUIRE(b == 43);
}

TEST_CASE("no capture self reference", "[function]") {
    static int a = 0;
    function<void(int)> outer;
    {
        auto inner = [](panda::Ifunction<void, int>& self, int val) {
            while(false) {self(a);}
            a = val;
        };
        outer = inner;
    }
    outer(1);
    REQUIRE(a == 1);
}

TEST_CASE("function from null", "[function]") {
    void (*fptr)();
    fptr = nullptr;
    function<void()> f = fptr;
    REQUIRE(!f);
}

TEST_CASE("function from null method", "[function]") {
    auto meth = &Test::bar;
    meth = nullptr;
    auto m = make_function(meth);
    REQUIRE(!m);
}

TEST_CASE("function from nullable object", "[function]") {
    struct S {
        void operator()() const {}
        explicit operator bool() const {
            return val;
        }
        bool val;
    };

    S s{false};
    function<void()> f = s;
    REQUIRE(!f);
    s.val = true;
    f = s;
    REQUIRE(f);
}

TEST_CASE("lambda self reference gcc bug", "[function]") {
    struct SomeStruct {
        void method(int val) {
            function<void(int)> ff = [this](panda::Ifunction<void, int>&, auto... args) mutable {
                this->bar(args...);
            };
            ff(val);
        }

        void bar(int val) {
            a = val;
        }
        int a = 10;
    };
    SomeStruct s;
    s.method(20);
    REQUIRE(s.a == 20);
}

TEST_CASE("lambda self reference auto...", "[function]") {
    int a = 10;
    function<int(int)> f = [&](auto...args) -> int {
        static_assert(sizeof...(args) == 1, "auto... resolved as without SELF");
        return (a = 20) + 1;
    };
    int b = f(42);
    REQUIRE(a == 20);
    REQUIRE(b == 21);

    function<int(int)> f2 = [&](auto&&...args) -> int {
        static_assert(sizeof...(args) == 1, "auto... resolved as without SELF");
        return 111;
    };
    CHECK(f2(123) == 111);

    function<int(int)> f3 = [&](auto&&...args) {
        REQUIRE(sizeof...(args) == 1);
        return 111;
    };
    CHECK(f3(123) == 111);
}
