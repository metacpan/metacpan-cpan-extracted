#include "test.h"
#include <panda/refcnt.h>

using panda::iptr;
using test::Tracer;
using panda::Refcnt;

class Test : public Tracer, public Refcnt {
    using Tracer::Tracer;
};

class TestChild : public Test {
    using Test::Test;
};

using TestSP      = iptr<Test>;
using TestChildSP = iptr<TestChild>;

TEST_CASE("ctor", "[iptr]") {
    Tracer::reset();

    SECTION("empty") {
        {
            auto p = TestSP();
            REQUIRE(!p);
            REQUIRE(Tracer::ctor_calls == 0);
        }
        REQUIRE(Tracer::dtor_calls == 0);
    }

    SECTION("from object") {
        {
            auto p = TestSP(new Test());
            REQUIRE(p);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(p->refcnt() == 1);
        }
        REQUIRE(Tracer::dtor_calls == 1);
    }

    SECTION("from iptr") {
        {
            auto src = TestSP(new Test());
            REQUIRE(Tracer::ctor_calls == 1);
            auto p(src);
            REQUIRE(p);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(p->refcnt() == 2);
        }
        REQUIRE(Tracer::dtor_calls == 1);
    }

    SECTION("from foreign iptr") {
        {
            auto src = TestChildSP(new TestChild());
            REQUIRE(Tracer::ctor_calls == 1);
            TestSP p(src);
            REQUIRE(p);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(p->refcnt() == 2);
        }
        REQUIRE(Tracer::dtor_calls == 1);
    }

    SECTION("move from iptr") {
        {
            auto src = TestSP(new Test(123));
            auto p = TestSP(std::move(src));
            REQUIRE(p);
            REQUIRE(!src);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 123);
        }
        REQUIRE(Tracer::dtor_calls == 1);
    }

    SECTION("move from foreign iptr") {
        {
            auto src = TestChildSP(new TestChild(321));
            auto p = TestSP(std::move(src));
            REQUIRE(p);
            REQUIRE(!src);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 321);
        }
        REQUIRE(Tracer::dtor_calls == 1);
    }
}

TEST_CASE("reset", "[iptr]") {
    Tracer::reset();

    SECTION("no args") {
        auto p = TestSP(new Test());
        REQUIRE(Tracer::ctor_calls == 1);
        p.reset();
        REQUIRE(Tracer::dtor_calls == 1);
        REQUIRE(!p);
    }

    SECTION("with same object") {
        auto p = TestSP(new Test(1));
        auto o = new Test(2);
        p.reset(o);
        REQUIRE(Tracer::dtor_calls == 1);
        REQUIRE(p);
        REQUIRE(p->value == 2);
        p.reset();
        REQUIRE(Tracer::dtor_calls == 2);
        REQUIRE(!p);
    }

    SECTION("foreign object") {
        auto p = TestSP(new Test(10));
        auto o = new TestChild(20);
        p.reset(o);
        REQUIRE(Tracer::dtor_calls == 1);
        REQUIRE(p);
        REQUIRE(p->value == 20);
        p.reset();
        REQUIRE(Tracer::dtor_calls == 2);
        REQUIRE(!p);
    }
}

TEST_CASE("assign", "[iptr]") {
    Tracer::reset();

    SECTION("NULL") {
        SECTION("from empty") {
            TestSP p;
            p = NULL;
            REQUIRE(Tracer::ctor_calls == 0);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(!p);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 0);
        }
        SECTION("from object") {
            auto p = TestSP(new Test());
            p = NULL;
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 1);
            REQUIRE(!p);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
    }

    SECTION("same object") {
        SECTION("from empty") {
            TestSP p;
            p = new Test(2);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
        SECTION("from object") {
            auto p = TestSP(new Test(1));
            p = new Test(2);
            REQUIRE(Tracer::ctor_calls == 2);
            REQUIRE(Tracer::dtor_calls == 1);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 2);
        }
    }

    SECTION("foreign object") {
        SECTION("from empty") {
            TestSP p;
            p = new TestChild(2);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
        SECTION("from object") {
            auto p = TestSP(new Test(1));
            p = new TestChild(2);
            REQUIRE(Tracer::ctor_calls == 2);
            REQUIRE(Tracer::dtor_calls == 1);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 2);
        }
    }

    SECTION("same iptr") {
        SECTION("from empty") {
            TestSP p;
            auto p2 = TestSP(new Test(2));
            p = p2;
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p2->refcnt() == 2);
            p.reset();
            REQUIRE(p2->refcnt() == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
        SECTION("from object") {
            auto p = TestSP(new Test(1));
            auto p2 = TestSP(new Test(2));
            p = p2;
            REQUIRE(Tracer::ctor_calls == 2);
            REQUIRE(Tracer::dtor_calls == 1);
            REQUIRE(p);
            REQUIRE(p2->refcnt() == 2);
            p.reset();
            REQUIRE(p2->refcnt() == 1);
            REQUIRE(Tracer::dtor_calls == 1);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 2);
        }
    }

    SECTION("foreign iptr") {
        SECTION("from empty") {
            TestSP p;
            auto p2 = TestChildSP(new TestChild(2));
            p = p2;
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p2->refcnt() == 2);
            p.reset();
            REQUIRE(p2->refcnt() == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
        SECTION("from object") {
            auto p = TestSP(new Test(1));
            auto p2 = TestChildSP(new TestChild(2));
            p = p2;
            REQUIRE(Tracer::ctor_calls == 2);
            REQUIRE(Tracer::dtor_calls == 1);
            REQUIRE(p);
            REQUIRE(p2->refcnt() == 2);
            p.reset();
            REQUIRE(p2->refcnt() == 1);
            REQUIRE(Tracer::dtor_calls == 1);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 2);
        }
    }

    SECTION("move same iptr") {
        SECTION("from empty") {
            TestSP p;
            auto p2 = TestSP(new Test(2));
            p = std::move(p2);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            REQUIRE(!p2);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 1);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
        SECTION("from object") {
            auto p = TestSP(new Test(1));
            auto p2 = TestSP(new Test(2));
            p = std::move(p2);
            REQUIRE(Tracer::ctor_calls == 2);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            REQUIRE(p2);
            REQUIRE(p2->refcnt() == 1);
            REQUIRE(p2->value == 1);
            p.reset();
            REQUIRE(!p);
            REQUIRE(p2);
            REQUIRE(p2->refcnt() == 1);
            REQUIRE(p2->value == 1);
            REQUIRE(Tracer::dtor_calls == 1);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 2);
        }
    }

    SECTION("move foreign iptr") {
        SECTION("from empty") {
            TestSP p;
            auto p2 = TestChildSP(new TestChild(2));
            p = std::move(p2);
            REQUIRE(Tracer::ctor_calls == 1);
            REQUIRE(Tracer::dtor_calls == 0);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            REQUIRE(!p2);
            p.reset();
            REQUIRE(Tracer::dtor_calls == 1);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 1);
        }
        SECTION("from object") {
            auto p = TestSP(new Test(1));
            auto p2 = TestChildSP(new TestChild(2));
            p = std::move(p2);
            REQUIRE(Tracer::ctor_calls == 2);
            REQUIRE(Tracer::dtor_calls == 1);
            REQUIRE(p);
            REQUIRE(p->refcnt() == 1);
            REQUIRE(p->value == 2);
            REQUIRE(!p2);
            p.reset();
            REQUIRE(!p);
            REQUIRE(Tracer::dtor_calls == 2);
            p2.reset();
            REQUIRE(Tracer::dtor_calls == 2);
        }
    }
}

TEST_CASE("dereference", "[iptr]") {
    auto obj = new Test(123);
    auto p = TestSP(obj);
    REQUIRE(p->value == 123);
    REQUIRE((*p).value == 123);
    REQUIRE(p.get()->value == 123);
    REQUIRE(p.get() == obj);
    REQUIRE(((Test*)p)->value == 123);
    REQUIRE((Test*)p == obj);
    REQUIRE(p);
    REQUIRE((bool)p == true);
}
