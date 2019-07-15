#include "test.h"
#include <panda/refcnt.h>
#include <panda/function.h>
#include <panda/lib/intrusive_chain.h>

using namespace panda;
using namespace panda::lib;
using std::shared_ptr;
using test::Tracer;

struct MyPtr : IntrusiveChainNode<MyPtr*> {};

struct MyIPtr : Refcnt, IntrusiveChainNode<iptr<MyIPtr>> {};

struct MySPtr : IntrusiveChainNode<shared_ptr<MySPtr>> {};

struct MyCustom : IntrusiveChainNode<MyCustom*> {
    MyCustom () : p(), n() {}

    MyCustom* p;
    MyCustom* n;
};

MyCustom* intrusive_chain_next (MyCustom* n) { return n->n; }
MyCustom* intrusive_chain_prev (MyCustom* n) { return n->p; }

void intrusive_chain_next (MyCustom* n, MyCustom* v) { n->n = v; }
void intrusive_chain_prev (MyCustom* n, MyCustom* v) { n->p = v; }

template <class T>
struct Test {
    using IC = IntrusiveChain<T>;
    using CIt = typename IC::const_iterator;

    static void check_content (CIt begin, CIt end) {
        CHECK(begin == end);
    }

    template <typename... Args>
    static void check_content (CIt begin, CIt end, const T& v, Args&&... rest) {
        REQUIRE(begin != end);
        CHECK(*begin == v);
        ++begin;
        check_content(begin, end, rest...);
    }

    template <typename... Args>
    static void check_content (const IC& list, Args&&... rest) {
        CHECK(list.size() == sizeof...(Args));
        check_content(list.begin(), list.end(), rest...);
    }

    //checks that elements has been properly removed from chain: next/prev properties must be reset
    static void check_removed (const T& v) {
        CHECK(!intrusive_chain_next(v));
        CHECK(!intrusive_chain_prev(v));
    }

    static void test (function<T()> ctor) {
        T v[10];
        for (int i = 0; i < 10; ++i) v[i] = ctor();

        SECTION("ctor: empty") {
            IC list;
            check_content(list);
            CHECK(list.empty());
        }

        SECTION("push_back") {
            IC list;
            list.push_back(v[0]);
            check_content(list, v[0]);
            list.push_back(v[1]);
            check_content(list, v[0], v[1]);
        }

        SECTION("push_front") {
            IC list;
            list.push_front(v[0]);
            check_content(list, v[0]);
            list.push_front(v[1]);
            check_content(list, v[1], v[0]);
        }

        SECTION("ctor: initializer list") {
            IC list({v[0], v[1], v[2]});
            check_content(list, v[0], v[1], v[2]);
        }

        SECTION("pop_back") {
            IC list({v[0], v[1], v[2]});
            CHECK(list.pop_back());
            check_content(list, v[0], v[1]);
            check_removed(v[2]);
            CHECK(list.pop_back());
            check_content(list, v[0]);
            check_removed(v[1]);
            CHECK(!list.pop_back());
            check_content(list);
            check_removed(v[0]);
        }

        SECTION("pop_front") {
            IC list({v[0], v[1], v[2]});
            CHECK(list.pop_front());
            check_content(list, v[1], v[2]);
            check_removed(v[0]);
            CHECK(list.pop_front());
            check_content(list, v[2]);
            check_removed(v[1]);
            CHECK(!list.pop_front());
            check_content(list);
            check_removed(v[2]);
        }

        SECTION("insert") {
            IC list;
            auto it = list.insert(list.begin(), v[0]);
            check_content(list, v[0]);
            CHECK(*it == v[0]);

            it = list.insert(list.begin(), v[1]);
            check_content(list, v[1], v[0]);
            CHECK(*it == v[1]);

            it = list.insert(list.end(), v[2]);
            check_content(list, v[1], v[0], v[2]);
            CHECK(*it == v[2]);

            --it;
            it = list.insert(it, v[3]);
            check_content(list, v[1], v[3], v[0], v[2]);
            CHECK(*it == v[3]);

            list.insert(T(), v[4]);
            check_content(list, v[1], v[3], v[0], v[2], v[4]);

            list.insert(v[1], v[5]);
            check_content(list, v[5], v[1], v[3], v[0], v[2], v[4]);

            list.insert(v[3], v[6]);
            check_content(list, v[5], v[1], v[6], v[3], v[0], v[2], v[4]);
        }

        SECTION("erase") {
            IC list({v[0], v[1], v[2], v[3]});

            SECTION("at end") {
                auto it = list.erase(list.end());
                check_content(list, v[0], v[1], v[2], v[3]);
                CHECK(it == list.end());
                list.erase(T());
                check_content(list, v[0], v[1], v[2], v[3]);
            }

            SECTION("from head") {
                auto it = list.erase(list.begin());
                check_content(list, v[1], v[2], v[3]);
                CHECK(*it == v[1]);
                check_removed(v[0]);

                it = list.erase(list.begin());
                check_content(list, v[2], v[3]);
                CHECK(*it == v[2]);
                check_removed(v[1]);

                list.erase(v[2]);
                check_content(list, v[3]);
                check_removed(v[2]);

                list.erase(v[3]);
                check_content(list);
                check_removed(v[3]);
            }

            SECTION("from tail") {
                auto pos = list.end(); --pos;
                auto it = list.erase(pos);
                check_content(list, v[0], v[1], v[2]);
                CHECK(it == list.end());
                check_removed(v[3]);

                pos = list.end(); --pos;
                it = list.erase(pos);
                check_content(list, v[0], v[1]);
                CHECK(it == list.end());
                check_removed(v[2]);

                list.erase(v[1]);
                check_content(list, v[0]);
                check_removed(v[1]);

                list.erase(v[0]);
                check_content(list);
                check_removed(v[0]);
            }

            SECTION("from the middle") {
                auto pos = list.begin(); ++pos; ++pos;
                auto it = list.erase(pos);
                check_content(list, v[0], v[1], v[3]);
                CHECK(*it == v[3]);
                check_removed(v[2]);

                pos = list.begin(); ++pos;
                it = list.erase(pos);
                check_content(list, v[0], v[3]);
                CHECK(*it == v[3]);
                check_removed(v[1]);

                list.push_back(v[4]);
                list.push_back(v[5]);

                list.erase(v[3]);
                check_content(list, v[0], v[4], v[5]);
                check_removed(v[3]);

                list.erase(v[4]);
                check_content(list, v[0], v[5]);
                check_removed(v[4]);
            }
            SECTION("element not in the list") {
                auto it = list.erase(v[4]);
                check_content(list, v[0], v[1], v[2], v[3]);
                CHECK(it == list.end());
            }
        }

        SECTION("clear") {
            IC list({v[0], v[1], v[2]});
            list.clear();
            check_content(list);
            CHECK(list.empty());
            check_removed(v[0]);
            check_removed(v[1]);
            check_removed(v[2]);
        }

        SECTION("front/back") {
            IC list;
            CHECK(list.front() == T());
            CHECK(list.back() == T());
            CHECK(list.size() == 0);

            list.push_back(v[0]);
            CHECK(list.front() == v[0]);
            CHECK(list.back() == v[0]);
            CHECK(list.size() == 1);

            list.push_back(v[1]);
            CHECK(list.front() == v[0]);
            CHECK(list.back() == v[1]);
            CHECK(list.size() == 2);

            list.push_back(v[2]);
            CHECK(list.front() == v[0]);
            CHECK(list.back() == v[2]);
            CHECK(list.size() == 3);
        }

    }
};

TEST_CASE("pointer type", "[intrusive_chain]") {
    Test<MyPtr*>::test([&]() -> MyPtr* {
        return new MyPtr();
    });
}

TEST_CASE("iptr type", "[intrusive_chain]") {
    Test<iptr<MyIPtr>>::test([&]() -> iptr<MyIPtr> {
        return new MyIPtr();
    });
}

TEST_CASE("shared_ptr type", "[intrusive_chain]") {
    Test<shared_ptr<MySPtr>>::test([&]() -> shared_ptr<MySPtr> {
        return shared_ptr<MySPtr>(new MySPtr());
    });
}

TEST_CASE("custom type", "[intrusive_chain]") {
    Test<MyCustom*>::test([&]() -> MyCustom* {
        return new MyCustom();
    });
}
