#include "test.h"
#include <panda/refcnt.h>

using panda::iptr;
using panda::weak_iptr;
using test::Tracer;
using panda::Refcnt;
using panda::Refcntd;

static int on_delete_calls = 0;

struct Test : Tracer, Refcnt {
    using Tracer::Tracer;
};

struct TestChild : Test {
    using Test::Test;
};

struct TestDel : Tracer, Refcntd {
    using Tracer::Tracer;

    void on_delete () noexcept override { on_delete_calls++; }
};

struct TestRes : Tracer, Refcntd {
    using Tracer::Tracer;
    bool resurected;

    TestRes () : resurected() {}

    void on_delete () noexcept override {
        on_delete_calls++;
        if (resurected) return;
        retain();
        resurected = true;
    }
};

using TestSP      = iptr<Test>;
using TestChildSP = iptr<TestChild>;
using TestDelSP   = iptr<TestDel>;
using TestResSP   = iptr<TestRes>;
using TestWP      = weak_iptr<Test>;
using TestChildWP = weak_iptr<TestChild>;

struct A  : Refcnt {};
struct AA : A {};
struct B  : Refcnt {};

static int foo (iptr<A>) {
    return 10;
}

static int foo (iptr<B>) {
    return 20;
}

TEST_CASE("iptr", "[iptr]") {
    Tracer::reset();
    on_delete_calls = 0;

    SECTION("ctor") {
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

    SECTION("reset") {
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

    SECTION("assign") {
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

    SECTION("dereference") {
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

    SECTION("weak") {
        SECTION("ctor") {
            SECTION("empty") {
                TestWP empty;
                CHECK_FALSE(empty);
            }
            SECTION("from iptr") {
                SECTION("base") {
                    TestSP obj = new Test(123);
                    CHECK(obj->refcnt() == 1);
                    TestWP weak = obj;
                    CHECK(obj->refcnt() == 1);
                }
                SECTION("derived") {
                    TestChildSP obj = new TestChild(123);
                    TestWP weak = obj;
                    CHECK(obj->refcnt() == 1);
                }
            }
            SECTION("from bad") {
                SECTION("bad iptr") {
                    TestSP nothing;
                    TestWP weak(nothing);
                    CHECK_FALSE(weak);
                }

                SECTION("bad weak_iptr") {
                    TestWP nothing;
                    TestWP weak(nothing);
                    CHECK_FALSE(weak);
                }
            }

            SECTION("from weak") {
                TestSP base = new Test(123);
                TestChildSP der = new TestChild(123);
                TestWP wbase = base;
                TestChildWP wder = der;

                SECTION("base") {
                    TestWP weak = wbase;
                    CHECK(weak.lock() == base);
                    CHECK(base->refcnt() == 1);
                }
                SECTION("derived") {
                    TestWP weak = wder;
                    CHECK(weak.lock() == der);
                    CHECK(der->refcnt() == 1);
                }

                SECTION("move") {
                    TestWP moved(std::move(wbase));
                    CHECK(moved.weak_count() == 1);
                    CHECK(moved.use_count() == 1);
                }
            }
        }

        SECTION("assign") {
            TestWP empty;
            TestSP base = new Test(123);
            TestChildSP der = new TestChild(123);
            TestWP wbase = base;
            TestChildWP wder = der;

            TestWP wbase2;
            TestChildWP wder2;

            SECTION("empty") {
                TestWP e2;
                e2 = empty;
                CHECK_FALSE(e2);
            }

            SECTION("base") {
                wbase2 = base;
                CHECK(wbase2.lock() == base);
                CHECK(wbase2.weak_count() == 2);
                wbase2 = der;
                CHECK(wbase2.lock() == der);
                CHECK(wbase2.weak_count() == 2);
                wbase2 = wbase;
                CHECK(wbase2.lock() == base);
                CHECK(wbase2.weak_count() == 2);
                wbase2 = wder;
                CHECK(wbase2.lock() == der);
                CHECK(wbase2.weak_count() == 2);
            }
            SECTION("derived") {
                wder2 = der;
                CHECK(wder2.lock() == der);
                wder2 = wder;
                CHECK(wder2.lock() == der);
                CHECK(der->refcnt() == 1);
            }

            SECTION("move") {
                wbase2 = std::move(wbase);
                CHECK(wbase2.lock() == base);
                CHECK(wbase2.weak_count() == 1);
                wbase2 = std::move(wder);
                CHECK(wbase2.lock() == der);
                CHECK(wbase2.weak_count() == 1);
            }

            SECTION("from bad") {
                SECTION("bad iptr") {
                    TestSP nothing;
                    wbase2 = nothing;
                }

                SECTION("bad weak_iptr") {
                    TestWP nothing;
                    wbase2 = nothing;
                }
                CHECK_FALSE(wbase2);
                CHECK_FALSE(wbase2.lock());
            }
        }

        SECTION("lock") {
            TestSP obj;
            TestWP weak;
            CHECK_FALSE(weak.lock());

            SECTION("base") {
                obj  = new Test(123);
            }
            SECTION("derived") {
                obj = new TestChild(123);
            }
            weak = obj;

            if (TestSP tmp = weak.lock()) {
                CHECK(obj->refcnt() == 2);
                CHECK(obj == tmp);
            }
            CHECK(obj->refcnt() == 1);
            obj.reset();
            CHECK(Tracer::dtor_calls == 1);
            CHECK(weak.expired());
            CHECK_FALSE(weak.lock());
        }

        SECTION("use_count") {
            TestWP weak;
            CHECK(weak.use_count() == 0);
            CHECK(weak.weak_count() == 0);

            TestSP obj = new Test;
            weak = obj;
            CHECK(weak.use_count() == 1);
            CHECK(weak.weak_count() == 1);

            TestWP w2 = weak;
            CHECK(weak.use_count() == 1);
            CHECK(weak.weak_count() == 2);

            obj.reset();
            CHECK(weak.use_count() == 0);
            CHECK(weak.weak_count() == 2);
        }

        SECTION("weak generalization") {
            TestSP obj = new Test;
            panda::weak<TestSP> weak = obj;
            CHECK(weak.use_count() == 1);
            CHECK(weak.weak_count() == 1);

            // check that weak<iptr<T>> is interchangeable with weak_iptr<T>
            weak = panda::weak<TestSP>(TestWP());
            CHECK(weak.weak_count() == 0);

            weak = TestWP();
            CHECK(weak.weak_count() == 0);
        }

        CHECK(Tracer::dtor_calls == Tracer::ctor_total());
    }

    SECTION("Refcntd") {
        SECTION("on_delete") {
            TestDelSP obj = new TestDel();
            obj.reset();
            CHECK(Tracer::ctor_calls == 1);
            CHECK(Tracer::dtor_calls == 1);
            CHECK(on_delete_calls == 1);
        }
        SECTION("resurect") {
            auto ptr = new TestRes();
            TestResSP obj = ptr;
            obj.reset();
            CHECK(Tracer::ctor_calls == 1);
            CHECK(Tracer::dtor_calls == 0);
            CHECK(on_delete_calls == 1);

            ptr->release();
            CHECK(Tracer::dtor_calls == 1);
            CHECK(on_delete_calls == 2);
        }
    }

    SECTION("compiles") {
        REQUIRE(foo(iptr<A>(nullptr)) == 10);
        REQUIRE(foo(iptr<B>(nullptr)) == 20);
        REQUIRE(foo(iptr<AA>(nullptr)) == 10);
    }
}
