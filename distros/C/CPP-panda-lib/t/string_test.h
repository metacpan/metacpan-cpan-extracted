#pragma once
#include "test.h"
#include <panda/string.h>
#include <panda/string_view.h>

namespace test {

using namespace panda;

template <typename T>
struct test_string {
    using Allocator  = typename test::Allocator<T>;
    using String     = panda::basic_string<T, std::char_traits<T>, Allocator>;
    using String2    = panda::basic_string<T, std::char_traits<T>, test::Allocator<T,1>>;
    using StdString  = std::basic_string<T>;
    using ExternalShared = typename String::ExternalShared;
    template <class A> using AnyString = panda::basic_string<T, std::char_traits<T>, A>;

    static const size_t MAX_SSO_CHARS = String::MAX_SSO_CHARS;
    static const size_t BUF_CHARS     = (sizeof(size_t) + sizeof(uint32_t)) / sizeof(T);
    static const size_t EBUF_CHARS    = 4*sizeof(void*)/sizeof(T);
    static const size_t CHAR_SIZE     = sizeof(T);
    static const T      LITERAL[38];
    static const size_t LITERAL_LEN   = sizeof(LITERAL)/sizeof(T)-1;
    static const T      EMPTY[1];
    static StdString    defexp;
    static size_t       defsz;

    static size_t slen (const T* src) {
        size_t cnt = 0;
        while (*src++) ++cnt;
        return cnt;
    }

    template <class A> static void REQUIRE_STR (const AnyString<A>& str, const T* src, size_t len, size_t cap, size_t shcap) {
        REQUIRE(str.length() == len);
        REQUIRE(std::basic_string<T>(str.data(), len) == std::basic_string<T>(src, len));
        REQUIRE(str.capacity() == cap);
        REQUIRE(str.shared_capacity() == shcap);
    }
    template <class A> static void REQUIRE_STR  (const AnyString<A>& str, const T* src, size_t len, size_t cap)    { REQUIRE_STR(str, src, len, cap, cap); }
    template <class A> static void REQUIRE_STR  (const AnyString<A>& str, const T* src, size_t len)                { REQUIRE_STR(str, src, len, len); }
    template <class A> static void REQUIRE_STR  (const AnyString<A>& str, const T* src)                            { REQUIRE_STR(str, src, slen(src)); }
    template <class A> static void REQUIRE_STR  (const AnyString<A>& str, StdString src, size_t cap, size_t shcap) { REQUIRE_STR(str, src.data(), src.size(), cap, shcap); }
    template <class A> static void REQUIRE_STR  (const AnyString<A>& str, StdString src, size_t cap)               { REQUIRE_STR(str, src, cap, cap); }
    template <class A> static void REQUIRE_STR  (const AnyString<A>& str, StdString src)                           { REQUIRE_STR(str, src, src.size()); }
    template <class A> static void REQUIRE_STRM (const AnyString<A>& str, StdString src)                           { REQUIRE_STR(str, src, str.capacity(), str.shared_capacity()); }

    static void REQUIRE_ALLOCS (int allocated_cnt = 0, int allocated = 0, int deallocated_cnt = 0, int deallocated = 0, int reallocated_cnt = 0, int reallocated = 0, int ext_deallocated_cnt = 0, int ext_deallocated = 0, int ext_shbuf_deallocated = 0) {
        auto stat = get_allocs();
        REQUIRE(stat.allocated_cnt         == allocated_cnt);
        REQUIRE(stat.allocated             == allocated);
        REQUIRE(stat.deallocated_cnt       == deallocated_cnt);
        REQUIRE(stat.deallocated           == deallocated);
        REQUIRE(stat.reallocated_cnt       == reallocated_cnt);
        REQUIRE(stat.reallocated           == reallocated);
        REQUIRE(stat.ext_deallocated_cnt   == ext_deallocated_cnt);
        REQUIRE(stat.ext_deallocated       == ext_deallocated);
        REQUIRE(stat.ext_shbuf_deallocated == ext_shbuf_deallocated);
    }

    static StdString mstr (const char* data, size_t count = 1) {
        StdString ret;
        for (size_t i = 0; i < count; ++i) {
            const char* ptr = data;
            while (*ptr) ret += (T)*ptr++;
        }
        return ret;
    }

    // temporary return value, only immediate use, no assigments!
    static const T* cstr (const char* data, size_t count = 1) {
        static T dest[100000];
        auto s = mstr(data, count);
        s.copy(dest, s.size());
        dest[s.size()] = (T)0;
        return dest;
    }

    // temporary return value, only immediate use, no assigments!
    static basic_string_view<T> svstr (const char* data, size_t count = 1) {
        return basic_string_view<T>(cstr(data, count));
    }

    static T* extstr (StdString src, size_t cap = 0) {
        if (cap < src.size()) cap = src.size();
        T* ext = (T*)malloc(cap * sizeof(T));
        std::memcpy(ext, src.data(), cap * sizeof(T));
        return ext;
    }

    static ExternalShared* shared_buf_alloc () {
        return (ExternalShared*)panda::DynamicMemoryPool::instance()->allocate(sizeof(ExternalShared));
    }

    template <class U = String> static U create_external      (StdString exp, size_t cap) { return U(extstr(exp), exp.size(), cap, &Allocator::ext_free); }
    template <class U = String> static U create_external      (StdString exp)             { return create_external<U>(exp, exp.size()); }
    template <class U = String> static U create_external_cbuf (StdString exp, size_t cap) { return U(extstr(exp), exp.size(), cap, &Allocator::ext_free, shared_buf_alloc(), &Allocator::shared_buf_free); }
    template <class U = String> static U create_external_cbuf (StdString exp)             { return create_external_cbuf<U>(exp, exp.size()); }

    static void   assign_external      (String& s, StdString exp, size_t cap) { s.assign(extstr(exp), exp.size(), cap, &Allocator::ext_free); }
    static void   assign_external      (String& s, StdString exp)             { assign_external(s, exp, exp.size()); }
    static void   assign_external_cbuf (String& s, StdString exp, size_t cap) { s.assign(extstr(exp), exp.size(), cap, &Allocator::ext_free, shared_buf_alloc(), &Allocator::shared_buf_free); }
    static void   assign_external_cbuf (String& s, StdString exp)             { assign_external_cbuf(s, exp, exp.size()); }

    static void test_ctor () {
        SECTION("empty") {
            {
                String s;
                REQUIRE_STR(s, EMPTY);
            }
            REQUIRE_ALLOCS();
        };

        SECTION("literal") {
            {
                String s(LITERAL);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            }
            REQUIRE_ALLOCS();
        };


        SECTION("sso") {
            StdString cur;

            while (cur.size() <= MAX_SSO_CHARS) {
                String s(cur.data(), cur.size());
                REQUIRE_STR(s, cur, MAX_SSO_CHARS);
                if (cur.size() == defexp.size()) throw "should not happen";
                cur += defexp[cur.size()];
            }
            REQUIRE_ALLOCS();

            auto sz = BUF_CHARS + cur.size();
            {
                String s(cur.data(), cur.size());
                REQUIRE_STR(s, cur);
                REQUIRE_ALLOCS(1, sz);
            }
            REQUIRE_ALLOCS(0, 0, 1, sz);
        }


        SECTION("internal with len") {
            {
                String s(defexp.data(), defexp.size());
                REQUIRE_STR(s, defexp);
            }
            REQUIRE_ALLOCS(1, defsz, 1, defsz);
        }

        SECTION("internal without len") {
            {
                String s(defexp.c_str());
                REQUIRE_STR(s, defexp);
            }
            REQUIRE_ALLOCS(1, defsz, 1, defsz);
        }

        SECTION("external") {
            {
                String s(extstr(defexp), defexp.size(), defexp.size(), &Allocator::ext_free);
                REQUIRE_STR(s, defexp);
            }
            REQUIRE_ALLOCS(1, EBUF_CHARS, 1, EBUF_CHARS, 0, 0, 1, defexp.size());
        }

        SECTION("external with custom buf") {
            {
                String s(extstr(defexp), defexp.size(), defexp.size(), &Allocator::ext_free, shared_buf_alloc(), &Allocator::shared_buf_free);
                REQUIRE_STR(s, defexp);
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0, 0, 0, 0, 0, 0, 1, defexp.size(), 1);
        }

        SECTION("fill") {
            SECTION("sso") {
                {
                    auto exp = mstr("aa");
                    String s(exp.size(), (T)'a');
                    REQUIRE_STR(s, exp, MAX_SSO_CHARS);
                }
                REQUIRE_ALLOCS();
            };
            SECTION("internal") {
                auto exp = mstr("B", 50);
                {
                    String s(exp.size(), (T)'B');
                    REQUIRE_STR(s, exp);
                }
                auto sz = BUF_CHARS + exp.size();
                REQUIRE_ALLOCS(1, sz, 1, sz);
            };
        };

        SECTION("new capacity") {
            SECTION("sso") {
                {
                    String s(2);
                    REQUIRE_STR(s, EMPTY, 0, MAX_SSO_CHARS);
                }
                REQUIRE_ALLOCS();
            };
            SECTION("internal") {
                {
                    String s(50);
                    REQUIRE_STR(s, EMPTY, 0, 50);
                }
                auto sz = BUF_CHARS + 50;
                REQUIRE_ALLOCS(1, sz, 1, sz);
            };
        };
    }

    template <class FString>
    static void test_copy_ctor () {
        SECTION("from empty") {
            {
                FString src;
                String s(src);
                REQUIRE_STR(src, EMPTY);
                REQUIRE_STR(s, EMPTY);
                REQUIRE(src.use_count() == 1);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from literal") {
            {
                FString src(LITERAL);
                String s(src);
                REQUIRE_STR(src, LITERAL, LITERAL_LEN, 0);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
                REQUIRE(src.use_count() == 1);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from sso") {
            {
                auto exp = mstr("bu");
                FString src(exp.c_str());
                String s(src);
                REQUIRE_STR(src, exp, MAX_SSO_CHARS);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS);
                REQUIRE(src.use_count() == 1);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from internal") {
            auto exp = mstr("bu", 50);
            auto sz = BUF_CHARS + exp.size();
            {
                FString src(exp.c_str());
                REQUIRE_ALLOCS(1, sz);
                {
                    String s(src);
                    REQUIRE_STR(src, exp, 0, exp.size());
                    REQUIRE_STR(s, exp, 0, exp.size());
                    REQUIRE_ALLOCS();
                    REQUIRE(src.use_count() == 2);
                }
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0, 0, 1, sz);
        }
        SECTION("from external") {
            auto exp = mstr("c", 50);
            {
                FString src(extstr(exp), exp.size(), exp.size(), &Allocator::ext_free);
                REQUIRE_ALLOCS(1, EBUF_CHARS);
                {
                    String s(src);
                    REQUIRE_STR(src, exp, 0, exp.size());
                    REQUIRE_STR(s, exp, 0, exp.size());
                    REQUIRE_ALLOCS();
                    REQUIRE(src.use_count() == 2);
                }
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0, 0, 1, EBUF_CHARS, 0, 0, 1, exp.size());
        }
    }

    template <class FString>
    static void test_move_ctor () {
        SECTION("from empty") {
            {
                FString src;
                String s(std::move(src));
                REQUIRE_STR(src, EMPTY);
                REQUIRE_STR(s, EMPTY);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from literal") {
            {
                FString src(LITERAL);
                String s(std::move(src));
                REQUIRE_STR(src, EMPTY);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from sso") {
            {
                auto exp = mstr("bu");
                FString src(exp.c_str());
                String s(std::move(src));
                REQUIRE_STR(src, EMPTY);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from internal") {
            auto exp = mstr("bu", 50);
            auto sz = BUF_CHARS + exp.size();
            {
                FString src(exp.data(), exp.size());
                REQUIRE_ALLOCS(1,sz);
                String s(std::move(src));
                REQUIRE_STR(src, EMPTY);
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0,0,1,sz);
        }
        SECTION("from external") {
            auto exp = mstr("c", 50);
            {
                FString src(extstr(exp), exp.size(), exp.size(), &Allocator::ext_free);
                REQUIRE_ALLOCS(1,EBUF_CHARS);
                String s(std::move(src));
                REQUIRE_STR(src, EMPTY);
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp.size());
        }
    }

    template <class FString>
    static void test_copy_ctor_offset () {
        SECTION("from literal") {
            {
                auto exp = StdString(LITERAL).substr(2, 25);
                FString src(LITERAL);
                String s(src, 2, 25);
                REQUIRE_STR(src, LITERAL, LITERAL_LEN, 0);
                REQUIRE_STR(s, exp, 0);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from sso") {
            {
                auto exp = mstr("bu");
                FString src(exp.c_str());
                String s(src, 1, 1);
                REQUIRE_STR(src, exp, MAX_SSO_CHARS);
                REQUIRE_STR(s, mstr("u"), MAX_SSO_CHARS-1);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from internal") {
            auto exp = mstr("bu", 50);
            auto sz = BUF_CHARS + exp.size();
            {
                FString src(exp.c_str());
                REQUIRE_ALLOCS(1, sz);
                String s(src, 9, 5);
                REQUIRE_STR(src, exp, 0, exp.size());
                REQUIRE_STR(s, mstr("ububu"), 0, exp.size()-9);
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0,0,1,sz);
        }
        SECTION("from external") {
            auto exp = mstr("c", 50);
            {
                FString src(extstr(exp), exp.size(), exp.size(), &Allocator::ext_free);
                REQUIRE_ALLOCS(1, EBUF_CHARS);
                String s(src, 10, 30);
                REQUIRE_STR(src, exp, 0, exp.size());
                REQUIRE_STR(s, mstr("c", 30), 0, exp.size()-10);
                REQUIRE_ALLOCS();
            }
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp.size());
        }
        SECTION("out of bounds") {
            auto exp = mstr("hello");
            FString src(exp.c_str());
            SECTION("too big length acts as npos") {
                String s(src, 3, 10);
                REQUIRE_STRM(s, mstr("lo"));
            }
            SECTION("too big offset throws exception") {
                REQUIRE_THROWS(String(src, 6, 10));
            }
        }
    }

    static void test_substr () {
        auto exp = mstr("hello world, hello world!");
        String src(exp.c_str());
        String s = src.substr(0, 5);
        REQUIRE_STR(s, mstr("hello"), 0, exp.size());
        s = src.substr(6);
        REQUIRE_STR(s, mstr("world, hello world!"), 0, exp.size()-6);
        s = src.substr(4, 3);
        REQUIRE_STR(s, mstr("o w"), 0, exp.size()-4);
        REQUIRE_STR(src, exp, 0, exp.size());
    }

    static void test_clear () {
        SECTION("literal") {
            {
                String s(LITERAL);
                s.clear();
                REQUIRE_STR(s, EMPTY);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("sso") {
            {
                auto exp = mstr("bu");
                String s(exp.c_str());
                s.clear();
                REQUIRE_STR(s, EMPTY, 0, MAX_SSO_CHARS);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("internal") {
            auto exp = mstr("bu", 50);
            {
                String s(exp.c_str());
                get_allocs();
                s.clear();
                REQUIRE_STR(s, EMPTY, 0, exp.size());
            }
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp.size());
        }
        SECTION("external") {
            auto exp = mstr("c", 50);
            {
                String s(extstr(exp), exp.size(), exp.size(), &Allocator::ext_free);
                get_allocs();
                s.clear();
                REQUIRE_ALLOCS();
                REQUIRE_STR(s, EMPTY, 0, exp.size());
            }
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp.size());
        };
    }

    struct AssignLiteral   { template <size_t U> static void op (String& s, const T (&val)[U]) { s.assign(val); } };
    struct OpAssignLiteral { template <size_t U> static void op (String& s, const T (&val)[U]) { s = val; } };
    struct AssignPtr       { static void op (String& s, const T* val) { s.assign(val); } };
    struct OpAssignPtr     { static void op (String& s, const T* val) { s = val; } };
    struct AssignCopy      {
        static void op (String& s, const String& val) { s.assign(val); }
        static void op (String& s, const String2& val) { s.assign(val); }
    };
    struct OpAssignCopy    {
        static void op (String& s, const String& val) { s = val; }
        static void op (String& s, const String2& val) { s = val; }
    };
    struct AssignMove      {
        static void op (String& s, String& val) { s.assign(std::move(val)); }
        static void op (String& s, String2& val) { s.assign(std::move(val)); }
    };
    struct OpAssignMove    {
        static void op (String& s, String& val) { s = std::move(val); }
        static void op (String& s, String2& val) { s = std::move(val); }
    };

    template <class U>
    static void test_assign_literal () {
        SECTION("from empty") {
            {
                String s;
                U::op(s, LITERAL);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from literal") {
            {
                const T exp[] = {'h', 'e', 'l', 'l', 'o', 0};
                const size_t exp_len = sizeof(exp) / sizeof(T) - 1;
                String s(exp);
                REQUIRE_STR(s, exp, exp_len, 0);
                U::op(s, LITERAL);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from sso") {
            {
                auto exp = mstr("bu");
                String s(exp.c_str());
                U::op(s, LITERAL);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from internal") {
            {
                auto exp = mstr("a", 50);
                auto sz = BUF_CHARS + exp.size();
                String s(exp.c_str());
                REQUIRE_ALLOCS(1,sz);
                U::op(s, LITERAL);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
                REQUIRE_ALLOCS(0,0,1,sz);
            }
            REQUIRE_ALLOCS();
        }
        SECTION("from external") {
            {
                auto exp = mstr("c", 50);
                String s(extstr(exp), exp.size(), exp.size(), &Allocator::ext_free);
                REQUIRE_ALLOCS(1, EBUF_CHARS);
                U::op(s, LITERAL);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
                REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp.size());
            }
            REQUIRE_ALLOCS();
        }
    }

    template <class U>
    static void test_assign_ptr () {
        SECTION("from literal") {
            auto exp = mstr("0", 50);
            String s(LITERAL);
            SECTION("no len") {
                U::op(s, exp.c_str());
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS(1,BUF_CHARS+exp.size());
                s = EMPTY;
                REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp.size());
            }
            SECTION("with len") {
                s.assign(exp.data(), 40);
                REQUIRE_ALLOCS(1,BUF_CHARS+40);
                REQUIRE_STR(s, exp.data(), 40, 40);
                s = EMPTY;
                REQUIRE_ALLOCS(0,0,1,BUF_CHARS+40);
            }

        }
        SECTION("from sso") {
            auto exp = mstr("1", 50);
            String s(cstr("yt"));
            U::op(s, exp.c_str());
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1,BUF_CHARS+exp.size());
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp.size());
        }
        SECTION("from internal") {
            auto exp = mstr("1", 50);
            String s(cstr("2", 50));
            get_allocs();
            U::op(s, exp.c_str());
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(); //no allocs for sufficient capacity
            U::op(s, cstr("so"));
            REQUIRE_STR(s, mstr("so"), 50); // didnt become sso
            REQUIRE_ALLOCS();
            exp = mstr("3", 60);
            U::op(s, exp.c_str());
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1, BUF_CHARS+60, 1, BUF_CHARS+50); //extended storage
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+60);
        }
        SECTION("from external") {
            auto exp = mstr("4", 50);
            String s(extstr(mstr("5", 50)), 50, 50, &Allocator::ext_free);
            get_allocs();
            U::op(s, exp.c_str());
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(); //no allocs for sufficient capacity
            exp = mstr("bt");
            U::op(s, exp.c_str());
            REQUIRE_STR(s, exp, 50); // didnt become sso
            exp = mstr("6", 70);
            U::op(s, exp.c_str());
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1, BUF_CHARS+70, 1, EBUF_CHARS, 0, 0, 1, 50); //extended storage moved to internal
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+70);
        }
        SECTION("from cow") {
            auto exp = mstr("1", 40);
            SECTION("from internal cow") {
                String tmp(cstr("2", 50));
                String s(tmp);
                get_allocs();
                U::op(s, exp.c_str());
                REQUIRE_STR(s, exp); //string detached
                REQUIRE_ALLOCS(1, BUF_CHARS+40); //string detached

                s = tmp;
                get_allocs();
                U::op(s, cstr("qw"));
                REQUIRE_STR(s, mstr("qw"), MAX_SSO_CHARS); //string detached to sso
            }
            SECTION("from external cow") {
                String tmp(extstr(mstr("2", 50)), 50, 50, &Allocator::ext_free);
                String s(tmp);
                get_allocs();
                U::op(s, exp.c_str());
                REQUIRE_STR(s, exp); //string detached
                REQUIRE_ALLOCS(1, BUF_CHARS+40); //string detached

                s = tmp;
                get_allocs();
                U::op(s, cstr("qw"));
                REQUIRE_STR(s, mstr("qw"), MAX_SSO_CHARS); //string detached to sso
            }
        }
        get_allocs();
    }

    static void test_assign_external () {
        SECTION("from literal") {
            auto exp = mstr("0", 50);
            String s(LITERAL);
            assign_external(s, exp);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1, EBUF_CHARS);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
        SECTION("from sso") {
            auto exp = mstr("1", 50);
            String s(cstr("yt"));
            assign_external(s, exp);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1, EBUF_CHARS);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
        SECTION("from internal") {
            auto exp = mstr("1", 50);
            String s(cstr("2", 60));
            get_allocs();
            assign_external(s, exp);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1, EBUF_CHARS, 1, BUF_CHARS + 60);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
        SECTION("from external") {
            auto exp = mstr("4", 50);
            //refcnt = 1
            String s = create_external<>(mstr("abcd"));
            get_allocs();
            assign_external(s, exp);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(0,0,0,0,0,0,1,4); //this case is optimized to reuse ExternalBuffer instead of dropping and creating a new one
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);

            // refcnt = 2
            s = create_external<>(mstr("abcd"));
            String tmp(s);
            get_allocs();
            assign_external(s, exp);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(1,EBUF_CHARS);
            tmp = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,4);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
        SECTION("with custom buf") {
            auto exp = mstr("4", 50);
            String s = create_external<>(mstr("abcd"));
            get_allocs();
            assign_external_cbuf(s, exp);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,4);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,0,0,0,0,1,50,1);
        }
    }

    static void test_assign_fill () {
        String s;
        s.assign(2, (T)'a');
        REQUIRE_STR(s, mstr("aa"), MAX_SSO_CHARS);
        REQUIRE_ALLOCS();
        s = String(cstr("a", 50));
        get_allocs();
        s.assign(10, (T)'b');
        REQUIRE_STR(s, mstr("bbbbbbbbbb"), 50);
        REQUIRE_ALLOCS();

        s = EMPTY;
        get_allocs();
    }

    static void test_assign_char () {
        String s;
        s = (T)'A';
        REQUIRE_STR(s, mstr("A"), MAX_SSO_CHARS);
        s = (T)'B';
        REQUIRE_STR(s, mstr("B"), MAX_SSO_CHARS);
    }

    template <class U, class FString>
    static void test_assign_copy () {
        SECTION("literal<->literal") {
            FString src(LITERAL);
            String s;
            U::op(s, src);
            REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            REQUIRE_STR(src, LITERAL, LITERAL_LEN, 0);
            s = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("sso<->sso") {
            auto exp = mstr("bu");
            FString src(exp.c_str());
            String s(cstr("du"));
            REQUIRE_ALLOCS();
            U::op(s, src);
            REQUIRE_STR(s, exp, MAX_SSO_CHARS);
            REQUIRE_STR(src, exp, MAX_SSO_CHARS);
            REQUIRE_ALLOCS();
            s = EMPTY;
            src = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("internal<->internal") {
            auto exp = mstr("q", 50);
            FString src(exp.c_str());
            String s(cstr("d", 30));
            get_allocs();
            U::op(s, src);
            REQUIRE_STR(s, exp, 0, exp.size());
            REQUIRE_STR(src, exp, 0, exp.size());
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+30);
            s = EMPTY;
            REQUIRE_ALLOCS();
            src = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+50);
        }
        SECTION("external<->external") {
            auto exp = mstr("q", 50);
            FString src = create_external<FString>(exp);
            String s = create_external<>(mstr("d", 30));
            get_allocs();
            U::op(s, src);
            REQUIRE_STR(s, exp, 0, exp.size());
            REQUIRE_STR(src, exp, 0, exp.size());
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,30);
            s = EMPTY;
            REQUIRE_ALLOCS();
            src = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
        SECTION("same object") {
            auto exp = mstr("q", 50);
            String s(exp.c_str());
            get_allocs();
            U::op(s, s);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS();
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+50);
        }
    }

    template <class FString>
    static void test_assign_offset () {
        SECTION("internal<->internal") {
            auto exp = mstr("q", 50);
            FString src(exp.c_str());
            String s(cstr("d", 30));
            get_allocs();
            s.assign(src, 10, 30);
            REQUIRE_STR(s, mstr("q", 30), 0, 40);
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+30);
            s = EMPTY;
            REQUIRE_ALLOCS();
            src = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+50);
        }
        SECTION("same object") {
            auto exp = mstr("x", 50);
            String s = create_external<>(exp);
            get_allocs();
            s.assign(s, 10, 30);
            REQUIRE_STR(s, mstr("x", 30), 40);
            REQUIRE_ALLOCS();
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
    }

    template <class U, class FString>
    static void test_assign_move () {
        SECTION("literal<->literal") {
            FString src(LITERAL);
            String s;
            U::op(s, src);
            REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            REQUIRE_STR(src, EMPTY);
            s = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("sso<->sso") {
            auto exp = mstr("bu");
            FString src(exp.c_str());
            String s(cstr("du"));
            REQUIRE_ALLOCS();
            U::op(s, src);
            REQUIRE_STR(s, exp, MAX_SSO_CHARS);
            REQUIRE_STR(src, EMPTY);
            REQUIRE_ALLOCS();
            s = EMPTY;
            src = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("internal<->internal") {
            auto exp = mstr("q", 50);
            FString src(exp.c_str());
            String s(cstr("d", 30));
            get_allocs();
            U::op(s, src);
            REQUIRE_STR(s, exp);
            REQUIRE_STR(src, EMPTY);
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+30);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+50);
            src = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("external<->external") {
            auto exp = mstr("q", 50);
            FString src = create_external<FString>(exp);
            String s = create_external<>(mstr("d", 30));
            get_allocs();
            U::op(s, src);
            REQUIRE_STR(s, exp);
            REQUIRE_STR(src, EMPTY);
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,30);
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
            src = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("same object") {
            auto exp = mstr("q", 50);
            String s(exp.c_str());
            get_allocs();
            U::op(s, s);
            REQUIRE_STR(s, exp);
            REQUIRE_ALLOCS();
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+50);
        }
    }

    template <class FString>
    static void test_assign () {
        SECTION("literal") {
            SECTION("method")   { test_assign_literal<AssignLiteral>(); }
            SECTION("operator") { test_assign_literal<OpAssignLiteral>(); }
        }
        SECTION("ptr") {
            SECTION("method")   { test_assign_ptr<AssignPtr>(); }
            SECTION("operator") { test_assign_ptr<OpAssignPtr>(); }
        }
        SECTION("external") { test_assign_external(); }
        SECTION("fill")     { test_assign_fill(); }
        SECTION("char")     { test_assign_char(); }
        SECTION("copy") {
            SECTION("method")   { test_assign_copy<AssignCopy, FString>(); }
            SECTION("operator") { test_assign_copy<OpAssignCopy, FString>(); }
        }
        SECTION("offset") { test_assign_offset<FString>(); }
        SECTION("move") {
            SECTION("method")   { test_assign_move<AssignMove, FString>(); }
            SECTION("operator") { test_assign_move<OpAssignMove, FString>(); }
        }
    }

    static void test_offset () {
        SECTION("from literal") {
            auto exp = StdString(LITERAL).substr(2, 25);
            String s(LITERAL);
            s.offset(2, 25);
            REQUIRE_STR(s, exp, 0);
            s = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("from sso") {
            auto exp = mstr("bu");
            String s(exp.c_str());
            s.offset(1, 1);
            REQUIRE_STR(s, mstr("u"), MAX_SSO_CHARS-1);
            s = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("from internal") {
            auto exp = mstr("bu", 50);
            String s(exp.c_str());
            s.offset(9, 5);
            REQUIRE_STR(s, mstr("ububu"), 100-9);
            s = EMPTY;
            auto sz = BUF_CHARS + 100;
            REQUIRE_ALLOCS(1,sz,1,sz);
        }
        SECTION("from external") {
            auto exp = mstr("c", 50);
            String s = create_external<>(exp);
            s.offset(10, 30);
            REQUIRE_STR(s, mstr("c", 30), exp.size()-10);
            s = EMPTY;
            REQUIRE_ALLOCS(1, EBUF_CHARS, 1, EBUF_CHARS, 0, 0, 1, exp.size());
        }
        SECTION("out of bounds") {
            auto exp = mstr("hello");
            String s(exp.c_str());
            SECTION("too big length acts as npos") {
                s.offset(3, 10);
                REQUIRE_STRM(s, mstr("lo"));
            };
            SECTION("too big offset throws exception") {
                REQUIRE_THROWS(s.offset(6,10));
            }
        }
    }

    template <class FString>
    static void test_swap () {
        SECTION("literal<->literal") {
            String s1;
            FString s2(LITERAL);
            s1.swap(s2);
            REQUIRE_STR(s1, LITERAL, LITERAL_LEN, 0);
            REQUIRE_STR(s2, EMPTY);
            s1 = EMPTY; s2 = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("literal<->sso") {
            auto exp = mstr("eb");
            String s1(LITERAL);
            FString s2(exp.c_str());
            s1.swap(s2);
            REQUIRE_STR(s1, exp, MAX_SSO_CHARS);
            REQUIRE_STR(s2, LITERAL, LITERAL_LEN, 0);
            s1 = EMPTY; s2 = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("literal<->internal") {
            auto exp = mstr("eb", 50);
            String s1(LITERAL);
            FString s2(exp.c_str());
            get_allocs();
            s1.swap(s2);
            REQUIRE_STR(s1, exp);
            REQUIRE_STR(s2, LITERAL, LITERAL_LEN, 0);
            s2 = EMPTY;
            REQUIRE_ALLOCS();
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp.size());
        }
        SECTION("literal<->external") {
            auto exp = mstr("be", 50);
            String s1(LITERAL);
            FString s2 = create_external<FString>(exp);
            get_allocs();
            s1.swap(s2);
            REQUIRE_STR(s1, exp);
            REQUIRE_STR(s2, LITERAL, LITERAL_LEN, 0);
            s2 = EMPTY;
            REQUIRE_ALLOCS();
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp.size());
        }
        SECTION("sso<->sso") {
            auto exp1 = mstr("eb");
            auto exp2 = mstr("ta");
            String s1(exp1.c_str());
            FString s2(exp2.c_str());
            s1.swap(s2);
            REQUIRE_STR(s1, exp2, MAX_SSO_CHARS);
            REQUIRE_STR(s2, exp1, MAX_SSO_CHARS);
            s1 = EMPTY; s2 = EMPTY;
            REQUIRE_ALLOCS();
        }
        SECTION("sso<->internal") {
            auto exp1 = mstr("eb");
            auto exp2 = mstr("ta", 50);
            String s1(exp1.c_str());
            FString s2(exp2.c_str());
            get_allocs();
            s1.swap(s2);
            REQUIRE_STR(s1, exp2);
            REQUIRE_STR(s2, exp1, MAX_SSO_CHARS);
            s2 = EMPTY;
            REQUIRE_ALLOCS();
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp2.size());
        }
        SECTION("sso<->external") {
            auto exp1 = mstr("eb");
            auto exp2 = mstr("ta", 50);
            String s1(exp1.c_str());
            FString s2 = create_external<FString>(exp2);
            get_allocs();
            s1.swap(s2);
            REQUIRE_STR(s1, exp2);
            REQUIRE_STR(s2, exp1, MAX_SSO_CHARS);
            s2 = EMPTY;
            REQUIRE_ALLOCS();
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp2.size());
        }
        SECTION("internal<->internal") {
            auto exp1 = mstr("eb", 100);
            auto exp2 = mstr("ta", 50);
            String s1(exp1.c_str());
            FString s2(exp2.c_str());
            REQUIRE_ALLOCS(2, BUF_CHARS*2 + exp1.size() + exp2.size());
            s1.swap(s2);
            REQUIRE_ALLOCS();
            REQUIRE_STR(s1, exp2);
            REQUIRE_STR(s2, exp1);
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp2.size());
            s2 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp1.size());
        }
        SECTION("internal<->external") {
            auto exp1 = mstr("eb", 100);
            auto exp2 = mstr("ta", 50);
            String s1(exp1.c_str());
            FString s2 = create_external<FString>(exp2);
            REQUIRE_ALLOCS(2, EBUF_CHARS + BUF_CHARS + exp1.size());
            s1.swap(s2);
            REQUIRE_STR(s1, exp2);
            REQUIRE_STR(s2, exp1);
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp2.size());
            s2 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp1.size());
        }
        SECTION("external<->external") {
            auto exp1 = mstr("eb", 100);
            auto exp2 = mstr("ta", 50);
            String s1 = create_external<>(exp1);
            FString s2 = create_external<FString>(exp2);
            REQUIRE_ALLOCS(2, EBUF_CHARS*2);
            s1.swap(s2);
            REQUIRE_STR(s1, exp2);
            REQUIRE_STR(s2, exp1);
            s1 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp2.size());
            s2 = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp1.size());
        }
    }

    static void test_copy () {
        String s(cstr("the password for my bank account is w74mnds320ft but i won't tell you the login)"));
        T t[500];
        size_t cnt;

        cnt = s.copy(t, 0);
        REQUIRE(cnt == 0);

        cnt = s.copy(t, 10);
        REQUIRE(cnt == 10);
        REQUIRE_STRM(String(t, cnt), mstr("the passwo"));

        cnt = s.copy(t, 20, 15);
        REQUIRE(cnt == 20);
        REQUIRE_STRM(String(t, cnt), mstr("r my bank account is"));

        cnt = s.copy(t, 20, 70); //too much count
        REQUIRE(cnt == 10);
        REQUIRE_STRM(String(t, cnt), mstr("the login)"));

        cnt = s.copy(t, String::npos, 60); //count=npos
        REQUIRE(cnt == 20);
        REQUIRE_STRM(String(t, cnt), mstr(" tell you the login)"));

        REQUIRE_THROWS(s.copy(t, 10, 90)); //too much offset
    }

    static void test_bool_empty () {
        String s;
        REQUIRE(s.empty());
        REQUIRE(!s);
        s = 'a';
        REQUIRE(!s.empty());
        REQUIRE(s);
    }

    static void test_use_count () {
        String s1(LITERAL);
        String s2(s1);
        REQUIRE(s1.use_count() == 1);
        REQUIRE(s2.use_count() == 1);

        s1 = cstr("ab");
        s2 = s1;
        REQUIRE(s1.use_count() == 1);
        REQUIRE(s2.use_count() == 1);

        s1 = cstr("a", 50);
        REQUIRE(s1.use_count() == 1);
        s2 = s1;
        REQUIRE(s1.use_count() == 2);
        REQUIRE(s2.use_count() == 2);

        s1 = create_external<>(mstr("b", 50));
        REQUIRE(s1.use_count() == 1);
        s2 = s1;
        REQUIRE(s1.use_count() == 2);
        REQUIRE(s2.use_count() == 2);
    }

    static void test_detach () {
        get_allocs();
        SECTION("literal") {
            String s(LITERAL);
            s.buf();
            REQUIRE_STR(s, LITERAL, LITERAL_LEN, LITERAL_LEN);
            REQUIRE_ALLOCS(1, BUF_CHARS + LITERAL_LEN);
        };
        SECTION("sso") {
            String s(cstr("ab"));
            s.buf();
            REQUIRE_ALLOCS();
            REQUIRE_STR(s, mstr("ab"), MAX_SSO_CHARS);
        };
        SECTION("internal") {
            auto exp = mstr("q", 50);
            String s(exp.c_str());
            get_allocs();
            s.buf();
            REQUIRE_ALLOCS();
            String s2(s);
            REQUIRE(s.use_count() == 2);
            REQUIRE(s2.use_count() == 2);
            s.buf();
            REQUIRE_ALLOCS(1, BUF_CHARS + exp.size()); //cow - detached
            REQUIRE_STR(s, exp);
            REQUIRE(s.use_count() == 1);
            REQUIRE(s2.use_count() == 1);
        };
        SECTION("external") {
            auto exp = mstr("q", 50);
            String s = create_external<>(exp);
            get_allocs();
            s.buf();
            REQUIRE_ALLOCS();
            String s2(s);
            REQUIRE(s.use_count() == 2);
            REQUIRE(s2.use_count() == 2);
            s.buf();
            REQUIRE_ALLOCS(1, BUF_CHARS + exp.size()); //cow - detached
            REQUIRE_STR(s, exp);
            REQUIRE(s.use_count() == 1);
            REQUIRE(s2.use_count() == 1);
        };
    }

    static void test_at_front_back () {
        String s(cstr("0123456789", 5));
        String tmp(s);
        get_allocs();

        SECTION("front") {
            REQUIRE(s.front() == (T)'0');
            REQUIRE(s.use_count() == 2); // not detached
            s.front() = (T)'9';
            REQUIRE_STRM(String(s, 0, 10), mstr("9123456789"));
            REQUIRE(s.use_count() == 1); //string detached
        }

        SECTION("at") {
            REQUIRE(s.at(1) == (T)'1');
            REQUIRE(s.at(2) == (T)'2');
            REQUIRE_THROWS(s.at(1000));
            REQUIRE(s.use_count() == 2); // not detached
            s.at(1) = (T)'8';
            REQUIRE_STRM(String(s, 0, 10), mstr("0823456789"));
            REQUIRE(s.use_count() == 1); //string detached
            s.at(0) = s.at(1);
            REQUIRE_STRM(String(s, 0, 10), mstr("8823456789"));
        }

        SECTION("op[]") {
            REQUIRE(s[3] == (T)'3');
            REQUIRE(s.use_count() == 2); // not detached
            s[2] = (T)'7';
            REQUIRE_STRM(String(s, 0, 10), mstr("0173456789"));
            REQUIRE(s.use_count() == 1); //string detached
        }

        SECTION("back") {
            REQUIRE(s.back() == (T)'9');
            REQUIRE(s.use_count() == 2); // not detached
            s.back() = (T)'0';
            REQUIRE_STRM(String(s, 40, 10), mstr("0123456780"));
            REQUIRE(s.use_count() == 1); //string detached
        }

        SECTION("pop_back") {
            auto exp = StdString(LITERAL).substr(0, LITERAL_LEN-1);
            String s(LITERAL);
            s.pop_back();
            REQUIRE_STR(s, exp, 0);
            s = EMPTY;
            REQUIRE_ALLOCS();
        }
    }

    static void test_iterator () {
        String s(cstr("0123456789", 5));
        String tmp(s);
        get_allocs();

        SECTION("begin + mutations") {
            auto it = s.begin();
            REQUIRE(*it++ == (T)'0');
            REQUIRE(*it++ == (T)'1');
            REQUIRE(*(it += 2) == (T)'4');
            REQUIRE(*(it -= 1) == (T)'3');

            REQUIRE(s.use_count() == 2); // not detached
            *it = (T)'x';
            REQUIRE(s.use_count() == 1); // detached
            REQUIRE_STRM(String(s, 0, 10), mstr("012x456789"));
        }
        SECTION("end") {
            auto it = s.end();
            REQUIRE(*(--it) == (T)'9');
            REQUIRE(*(--it) == (T)'8');
            std::advance(it, -2);
            REQUIRE(*it == (T)'6');
        }

        SECTION("diffence & eq & ne") {
            auto b = s.begin();
            auto e = s.end();
            REQUIRE(b == b);
            REQUIRE(e == e);
            REQUIRE(b != e);
            REQUIRE(size_t(e - b) == s.length());
        }

        SECTION("ordening relations") {
            auto b = s.begin();
            auto e = s.end();
            REQUIRE(b >= b);
            REQUIRE(!(b > b));
            REQUIRE(e > b);
            REQUIRE(b < e);
            REQUIRE(b <= e);
            REQUIRE(e <= e);
            REQUIRE(!(e < e ));
        }

        SECTION("global -+ operators") {
            auto b = s.begin();
            auto e = s.end();

            REQUIRE(*(b + 1) == (T)'1');
            REQUIRE(*(2 + b) == (T)'2');
            REQUIRE(*(e - 1) == (T)'9');
            REQUIRE(*(2 - e) == (T)'8');
        }

        SECTION("as const iterator") {
            auto b = s.begin();
            auto cb = (const T*)b;
            REQUIRE(*cb++ == (T)'0');
            REQUIRE(*cb++ == (T)'1');
        }

        SECTION("plus and as const iterator") {
            auto b = s.begin() + 2;
            auto cb = (const T*)b;
            REQUIRE(*cb++ == (T)'2');
            REQUIRE(*cb++ == (T)'3');
        }
    }

    static void test_erase () {
        get_allocs();
        SECTION("literal") {
            String s(LITERAL);
            s.erase(11);
            REQUIRE_STR(s, mstr("hello world"), 0);
            REQUIRE_ALLOCS();
            s.erase(0, 6);
            REQUIRE_STR(s, mstr("world"), 0);
            REQUIRE_ALLOCS();
            s.erase(1, 3);
            REQUIRE_STR(s, mstr("wd"), MAX_SSO_CHARS);
            REQUIRE_ALLOCS();
        }
        if (CHAR_SIZE == 1) {
            SECTION("sso") {
                String s(cstr("motherfuck"));
                s.erase(8);
                REQUIRE_STR(s, mstr("motherfu"), MAX_SSO_CHARS);
                s.erase(0, 2);
                REQUIRE_STR(s, mstr("therfu"), MAX_SSO_CHARS-2);
                s.erase(1, 2);
                REQUIRE_STR(s, mstr("trfu"), MAX_SSO_CHARS-4);
                s = EMPTY;
                REQUIRE_ALLOCS();
            }
        }
        SECTION("internal") {
            auto exp = mstr("0123456789", 7);
            String s(exp.c_str());
            get_allocs();
            s.erase(65);
            REQUIRE_STR(s, mstr("01234567890123456789012345678901234567890123456789012345678901234"), 70);
            s.erase(0, 5);
            REQUIRE_STR(s, mstr("567890123456789012345678901234567890123456789012345678901234"), 65);
            s.erase(5, 5);
            REQUIRE_STR(s, mstr("5678956789012345678901234567890123456789012345678901234"), 60); //head moved
            s.erase(45, 5);
            REQUIRE_STR(s, mstr("56789567890123456789012345678901234567890123401234"), 60); //tail moved
            REQUIRE_ALLOCS();
            String s2(s);
            REQUIRE_STR(s2, mstr("56789567890123456789012345678901234567890123401234"), 0, 60);
            s.erase(45);
            REQUIRE_STR(s, mstr("567895678901234567890123456789012345678901234"), 0, 60); // still cow
            s.erase(0, 5);
            REQUIRE_STR(s, mstr("5678901234567890123456789012345678901234"), 0, 55); // still cow
            REQUIRE_ALLOCS();
            REQUIRE(s.use_count() == 2); // cow
            s.erase(5, 5);
            REQUIRE_STR(s, mstr("56789567890123456789012345678901234")); // detached
            REQUIRE(s.use_count() == 1);
            REQUIRE_ALLOCS(1,BUF_CHARS+35);
        }
        SECTION("external") {
            auto exp = mstr("0123456789", 5);
            String s(exp.c_str());
            get_allocs();
            s.erase(45);
            REQUIRE_STR(s, mstr("012345678901234567890123456789012345678901234"), 50);
            s.erase(0, 5);
            REQUIRE_STR(s, mstr("5678901234567890123456789012345678901234"), 45);
            s.erase(5, 5);
            REQUIRE_STR(s, mstr("56789567890123456789012345678901234"), 40); //head moved
            s.erase(25, 5);
            REQUIRE_STR(s, mstr("567895678901234567890123401234"), 40); //tail moved
            REQUIRE_ALLOCS();
            String s2(s);
            REQUIRE_STR(s2, mstr("567895678901234567890123401234"), 0, 40);
            s.erase(25);
            REQUIRE_STR(s, mstr("5678956789012345678901234"), 0, 40); // still cow
            s.erase(0, 5);
            REQUIRE_STR(s, mstr("56789012345678901234"), 0, 35); // still cow
            REQUIRE_ALLOCS();
            REQUIRE(s.use_count() == 2);
            s.erase(1, 18);
            REQUIRE_STR(s, mstr("54"), MAX_SSO_CHARS); // detached
            REQUIRE(s.use_count() == 1);
        }
        SECTION("offset exceed") {
            String s(LITERAL);
            REQUIRE_THROWS(s.erase(100));
        }
    }

    template <class FString>
    static void test_compare () {
        String  s1(cstr("keyword"));
        FString s2(cstr("abcword"));
        FString s3(cstr("keyword1"));
        FString s4(cstr("keyword"));
        FString s5(cstr("word"));
        get_allocs();

        REQUIRE(s1.compare(0, 7, s2, 0, 7) > 0);
        REQUIRE(s1.compare(0, 7, s3, 0, 8) < 0);
        REQUIRE(s1.compare(0, 7, s4, 0, 7) == 0);
        REQUIRE(s1.compare(0, 7, s5, 0, 4) < 0);
        REQUIRE(s1.compare(0, 7, s3, 0, 7) == 0);
        REQUIRE(s1.compare(3, 4, s5, 0, 4) == 0);
        REQUIRE(s1.compare(3, 4, s2, 3, 4) == 0);

        REQUIRE_THROWS(s1.compare(8, 7, s2, 0, 7)); //offset exceeded
        REQUIRE_THROWS(s1.compare(0, 7, s2, 8, 7)); //offset exceeded

        REQUIRE(s1.compare(0, 10, s4, 0, 7)  == 0); //len exceeded
        REQUIRE(s1.compare(0, 10, s4, 0, 11) == 0); //len exceeded

        REQUIRE_FALSE(s1 == s3);
        REQUIRE(s1 == s4);

        REQUIRE(s1 != s3);
        REQUIRE_FALSE(s1 != s4);

        REQUIRE(s1 > s2);
        REQUIRE_FALSE(s1 > s3);
        REQUIRE_FALSE(s1 > s4);

        REQUIRE(s1 >= s2);
        REQUIRE_FALSE(s1 >= s3);
        REQUIRE(s1 >= s4);

        REQUIRE_FALSE(s1 < s2);
        REQUIRE(s1 < s3);
        REQUIRE_FALSE(s1 < s4);

        REQUIRE_FALSE(s1 <= s2);
        REQUIRE(s1 <= s3);
        REQUIRE(s1 <= s4);

        REQUIRE_ALLOCS();
    }

    template <class FString>
    static void test_find () {
        auto npos = String::npos;
        String s(cstr("jopa noviy god"));
        SECTION("find") {
            REQUIRE(s.find(FString(cstr("o"))) == 1);
            REQUIRE(s.find(FString(cstr("jopa"))) == 0);
            REQUIRE(s.find(FString(cstr("noviy"))) == 5);
            REQUIRE(s.find(FString(cstr("god"))) == 11);
            REQUIRE(s.find(FString(cstr("o")), 2) == 6);
            REQUIRE(s.find(FString(EMPTY), 0) == 0);
            REQUIRE(s.find(FString(EMPTY), 13) == 13);
            REQUIRE(s.find(FString(EMPTY), 14) == 14);
            REQUIRE(s.find(FString(EMPTY), 15) == npos);
            REQUIRE(s.find(FString(cstr("o")), 14) == npos);
            REQUIRE(s.find(FString(cstr("god")), 11) == 11);
            REQUIRE(s.find(FString(cstr("god")), 12) == npos);
        }
        SECTION("rfind") {
            REQUIRE(s.rfind(FString(cstr("o"))) == 12);
            REQUIRE(s.rfind(FString(cstr("o")), 99999) == 12);
            REQUIRE(s.rfind(FString(cstr("jopa"))) == 0);
            REQUIRE(s.rfind(FString(cstr("jopa")), 0) == 0);
            REQUIRE(s.rfind(FString(cstr("noviy"))) == 5);
            REQUIRE(s.rfind(FString(cstr("o")), 11) == 6);
            REQUIRE(s.rfind(FString(EMPTY), 0) == 0);
            REQUIRE(s.rfind(FString(EMPTY), 13) == 13);
            REQUIRE(s.rfind(FString(EMPTY), 14) == 14);
            REQUIRE(s.rfind(FString(EMPTY), 15) == 14);
            REQUIRE(s.rfind(FString(cstr("o")), 0) == npos);
            REQUIRE(s.rfind(FString(cstr("god")), 11) == 11);
            REQUIRE(s.rfind(FString(cstr("god")), 10) == npos);
        }
        SECTION("find_first_of") {
            REQUIRE(s.find_first_of(FString(cstr("o"))) == 1);
            REQUIRE(s.find_first_of(FString(cstr("o")), 2) == 6);
            REQUIRE(s.find_first_of(FString(cstr("o")), 14) == npos);
            REQUIRE(s.find_first_of(FString(EMPTY), 0) == npos);
            REQUIRE(s.find_first_of(FString(EMPTY), 15) == npos);
            REQUIRE(s.find_first_of(FString(cstr("pnv"))) == 2);
            REQUIRE(s.find_first_of(FString(cstr("pnv")), 3) == 5);
            REQUIRE(s.find_first_of(FString(cstr("pnv")), 6) == 7);
            REQUIRE(s.find_first_of(FString(cstr("pnv")), 8) == npos);
        }
        SECTION("find_first_not_of") {
            REQUIRE(s.find_first_not_of(FString(cstr("o"))) == 0);
            REQUIRE(s.find_first_not_of(FString(cstr("j"))) == 1);
            REQUIRE(s.find_first_not_of(FString(cstr("o")), 1) == 2);
            REQUIRE(s.find_first_not_of(FString(cstr("d")), 13) == npos);
            REQUIRE(s.find_first_not_of(FString(EMPTY), 0) == 0);
            REQUIRE(s.find_first_not_of(FString(EMPTY), 15) == npos);
            REQUIRE(s.find_first_not_of(FString(cstr("jopa nviy"))) == 11);
            REQUIRE(s.find_first_not_of(FString(cstr("og ")), 10) == 13);
            REQUIRE(s.find_first_not_of(FString(cstr("ogd ")), 10) == npos);
        }
        SECTION("find_last_of") {
            REQUIRE(s.find_last_of(FString(cstr("o"))) == 12);
            REQUIRE(s.find_last_of(FString(cstr("o")), 9999) == 12);
            REQUIRE(s.find_last_of(FString(cstr("o")), 10) == 6);
            REQUIRE(s.find_last_of(FString(cstr("o")), 1) == 1);
            REQUIRE(s.find_last_of(FString(cstr("o")), 0) == npos);
            REQUIRE(s.find_last_of(FString(EMPTY), 0) == npos);
            REQUIRE(s.find_last_of(FString(EMPTY), 15) == npos);
            REQUIRE(s.find_last_of(FString(cstr("pnv"))) == 7);
            REQUIRE(s.find_last_of(FString(cstr("pnv")), 6) == 5);
            REQUIRE(s.find_last_of(FString(cstr("pnv")), 4) == 2);
            REQUIRE(s.find_last_of(FString(cstr("pnv")), 1) == npos);
        }
        SECTION("find_last_not_of") {
            REQUIRE(s.find_last_not_of(FString(cstr("o"))) == 13);
            REQUIRE(s.find_last_not_of(FString(cstr("d"))) == 12);
            REQUIRE(s.find_last_not_of(FString(cstr("d")), 9999) == 12);
            REQUIRE(s.find_last_not_of(FString(cstr("d")), 12) == 12);
            REQUIRE(s.find_last_not_of(FString(cstr("o")), 12) == 11);
            REQUIRE(s.find_last_not_of(FString(cstr("j")), 0) == npos);
            REQUIRE(s.find_last_not_of(FString(EMPTY), 0) == 0);
            REQUIRE(s.find_last_not_of(FString(EMPTY), 13) == 13);
            REQUIRE(s.find_last_not_of(FString(EMPTY), 14) == 13);
            REQUIRE(s.find_last_not_of(FString(EMPTY), 15) == 13);
            REQUIRE(s.find_last_not_of(FString(cstr("nviy god"))) == 3);
            REQUIRE(s.find_last_not_of(FString(cstr("jpa ")), 4) == 1);
            REQUIRE(s.find_last_not_of(FString(cstr("jopa ")), 4) == npos);
        }
    }

    static void test_reserve () {
        get_allocs();
        SECTION("literal") {
            get_allocs();
            String s(LITERAL);
            SECTION(">len") {
                s.reserve(100);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, 100);
                REQUIRE_ALLOCS(1, BUF_CHARS+100);
            }
            SECTION("<len") {
                s.reserve(LITERAL_LEN-1);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, LITERAL_LEN);
                REQUIRE_ALLOCS(1, BUF_CHARS+LITERAL_LEN);
            }
            SECTION("=0") {
                s.reserve(0);
                REQUIRE_STR(s, LITERAL, LITERAL_LEN, LITERAL_LEN);
                REQUIRE_ALLOCS(1, BUF_CHARS+LITERAL_LEN);
            }
        }
        if (CHAR_SIZE == 1) {
        SECTION("sso") {
            get_allocs();
            auto exp = mstr("hello");
            SECTION("<= max sso") {
                String s(exp.c_str());
                s.reserve(0);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
                s.reserve(MAX_SSO_CHARS);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
            SECTION("> max sso") {
                String s(exp.c_str());
                s.reserve(MAX_SSO_CHARS+1);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS+1);
                REQUIRE_ALLOCS(1, BUF_CHARS+MAX_SSO_CHARS+1);
            }
            SECTION("offset, <= capacity") {
                String s((mstr("hi")+exp).c_str());
                s.offset(2);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS-2);
                s.reserve(MAX_SSO_CHARS-2);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS-2);
                REQUIRE_ALLOCS();
            }
            SECTION("offset, > capacity, <= max sso") {
                String s((mstr("hi")+exp).c_str());
                s.offset(2);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS-2);
                s.reserve(MAX_SSO_CHARS);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS);
                REQUIRE_ALLOCS(); // string should has been moved to the beginning, no allocs
            }
        }
        }
        SECTION("internal") {
            auto exp = mstr("abcde", 10);
            String s(exp.c_str());
            get_allocs();
            SECTION("detach cow") {
                String s2(s);
                s.reserve(exp.size()-1);
                REQUIRE_STR(s, exp);
                REQUIRE(s.use_count() == 1); // detached
                REQUIRE_ALLOCS(1, BUF_CHARS+exp.size());
                s = s2;
                get_allocs();
                s.offset(10, 30);
                auto tmp = exp.substr(10, 30);
                s.reserve(0);
                REQUIRE_STR(s, tmp);
                REQUIRE(s.use_count() == 1); // detached
                REQUIRE_ALLOCS(1, BUF_CHARS+tmp.size()); // detached with minimum required capacity
                s = s2;
                get_allocs();
                s.offset(10, 30);
                s.reserve(100);
                REQUIRE_STR(s, tmp, 100);
                REQUIRE(s.use_count() == 1); // detached
                REQUIRE_ALLOCS(1, BUF_CHARS+100);
            }
            SECTION("<= max capacity") {
                s.reserve(0);
                s.reserve(exp.size());
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS();
            }
            SECTION("> max capacity") {
                s.reserve(exp.size()*2);
                REQUIRE_STR(s, exp, exp.size()*2);
                REQUIRE_ALLOCS(0,0,0,0,1,exp.size());
            }
            SECTION("offset, <= capacity") {
                s.offset(10);
                s.reserve(40);
                REQUIRE_STR(s, exp.substr(10));
                REQUIRE_ALLOCS();
            }
            SECTION("offset, > capacity, <= max capacity") {
                s.offset(10);
                s.reserve(50);
                REQUIRE_STR(s, exp.substr(10), 50);
                REQUIRE_ALLOCS(); // str has been moved to the beginning
            }
            SECTION("offset, > max capacity") {
                s.offset(20);
                s.reserve(70);
                REQUIRE_STR(s, exp.substr(20), 70);
                REQUIRE_ALLOCS(1, BUF_CHARS+70, 1, BUF_CHARS+50);
            }
            SECTION("reserve to sso") {
                String s2(s);
                s.offset(0, 2);
                s.reserve(2);
                REQUIRE_STR(s, exp.substr(0,2), MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
        }
        SECTION("external") {
            auto exp = mstr("abcde", 10);
            String s = create_external<>(exp);
            get_allocs();
            SECTION("detach cow") {
                String s2(s);
                s.reserve(exp.size()-1);
                REQUIRE_STR(s, exp);
                REQUIRE(s.use_count() == 1); // detached
                REQUIRE_ALLOCS(1, BUF_CHARS+exp.size());
                s = s2;
                get_allocs();
                s.offset(10, 30);
                s.reserve(0);
                auto tmp = exp.substr(10,30);
                REQUIRE_STR(s, tmp);
                REQUIRE(s.use_count() == 1); // detached
                REQUIRE_ALLOCS(1, BUF_CHARS+30); // detached with minimum required capacity
                s = s2;
                get_allocs();
                s.offset(10, 30);
                s.reserve(100);
                REQUIRE_STR(s, tmp, 100);
                REQUIRE(s.use_count() == 1); // detached
                REQUIRE_ALLOCS(1, BUF_CHARS+100);
            }
            SECTION("<= max capacity") {
                s.reserve(0);
                s.reserve(exp.size());
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS();
            }
            SECTION("> max capacity") {
                s.reserve(exp.size()*2);
                REQUIRE_STR(s, exp, exp.size()*2);
                REQUIRE_ALLOCS(1, BUF_CHARS+exp.size()*2, 1, EBUF_CHARS, 0, 0, 1, exp.size());
            }
            SECTION("offset, <= capacity") {
                s.offset(10);
                s.reserve(40);
                REQUIRE_STR(s, exp.substr(10));
                REQUIRE_ALLOCS();
            }
            SECTION("offset, > capacity, <= max capacity") {
                s.offset(10);
                s.reserve(50);
                REQUIRE_STR(s, exp.substr(10), 50);
                REQUIRE_ALLOCS(); // str has been moved to the beginning
            }
            SECTION("offset, > max capacity") {
                s.offset(20);
                s.reserve(70);
                REQUIRE_STR(s, exp.substr(20), 70);
                REQUIRE_ALLOCS(1, BUF_CHARS+70, 1, EBUF_CHARS, 0,0, 1, exp.size());
            }
            SECTION("reserve to sso") {
                String s2(s);
                s.offset(0, 2);
                s.reserve(2);
                REQUIRE_STR(s, exp.substr(0, 2), MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
        }
    }

    static void test_resize () {
        get_allocs();
        SECTION("literal") {
            String s(LITERAL);
            SECTION("less") {
                s.resize(1);
                REQUIRE_STR(s, StdString(LITERAL, 1), 0);
                REQUIRE_ALLOCS();
            }
            SECTION("more") {
                s.resize(LITERAL_LEN+10);
                REQUIRE_STR(s, StdString(LITERAL) + StdString(10, (T)'\0'));
                REQUIRE_ALLOCS(1, BUF_CHARS + LITERAL_LEN + 10);
            }
        }
        if (CHAR_SIZE == 1) {
        SECTION("sso") {
            auto exp = mstr("world");
            String s(exp.c_str());
            SECTION("less") {
                s.resize(2);
                REQUIRE_STR(s, mstr("wo"), MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
            SECTION("more") {
                s.resize(7, (T)'!');
                REQUIRE_STR(s, mstr("world!!"), MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
        }
        }
        SECTION("internal") {
            auto exp = mstr("a", 50);
            String s(exp.c_str());
            get_allocs();
            SECTION("less") {
                s.resize(10);
                REQUIRE_STR(s, mstr("a", 10), exp.size());
                REQUIRE_ALLOCS();
            }
            SECTION("more") {
                s.resize(70, (T)'b');
                REQUIRE_STR(s, exp + mstr("b", 20));
                REQUIRE_ALLOCS(0,0,0,0,1,20);
            }
        }
        SECTION("external") {
            auto exp = mstr("a", 50);
            String s = create_external<>(exp);
            get_allocs();
            SECTION("less") {
                s.resize(10);
                REQUIRE_STR(s, mstr("a", 10), exp.size());
                REQUIRE_ALLOCS();
            }
            SECTION("more") {
                s.offset(40);
                s.resize(20, (T)'b');
                REQUIRE_STR(s, mstr("a", 10) + mstr("b", 10), 50);
                REQUIRE_ALLOCS(); // because offset has been eliminated
            }
        }
    }

    static void test_shrink_to_fit () {
        get_allocs();
        SECTION("literal") {
            auto s = String(LITERAL).substr(2,5);
            s.shrink_to_fit();
            REQUIRE(s.capacity() == 0); // noop
            REQUIRE_ALLOCS();
        }
        SECTION("sso") {
            String s(cstr("ab"));
            s.pop_back();
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a"), MAX_SSO_CHARS);
            REQUIRE_ALLOCS();
        }
        SECTION("internal owner") {
            String s(cstr("a", 50));
            get_allocs();
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 50));
            REQUIRE_ALLOCS();
            s.offset(0, 40);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 40));
            REQUIRE_ALLOCS(0,0,0,0,1,-10); //realloced
            s.offset(10);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 30));
            REQUIRE_ALLOCS(1,BUF_CHARS+30,1,BUF_CHARS+40); // dealloc+alloc
            s.offset(0,2);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("aa"), MAX_SSO_CHARS); // shrinked to sso
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+30);
        }
        SECTION("internal cow") {
            String s(cstr("a", 50));
            String tmp(s);
            get_allocs();
            s.offset(10, 30);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 30), 0, 40);
            REQUIRE_ALLOCS();
            s.offset(0, 2);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("aa"), MAX_SSO_CHARS); // shrinked to sso
            REQUIRE_ALLOCS();
        }
        SECTION("external owner") {
            String s = create_external<>(mstr("a", 50));
            get_allocs();
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 50));
            REQUIRE_ALLOCS();
            s.offset(0, 40);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 40)); // shrinked
            REQUIRE_ALLOCS(1, BUF_CHARS+40, 1, EBUF_CHARS, 0, 0, 1, 50); // moved to internal
            s = create_external<>(mstr("a", 50));
            get_allocs();
            s.offset(0,2);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("aa"), MAX_SSO_CHARS); // shrinked to sso
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,50);
        }
        SECTION("external cow") {
            String s = create_external<>(mstr("a", 50));
            get_allocs();
            String tmp(s);
            s.offset(10, 30);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("a", 30), 0, 40);
            REQUIRE_ALLOCS();
            s = create_external<>(mstr("a", 50));
            tmp = s;
            get_allocs();
            s.offset(0, 2);
            s.shrink_to_fit();
            REQUIRE_STR(s, mstr("aa"), MAX_SSO_CHARS); // shrinked to sso
            REQUIRE_ALLOCS();
        }
    }

    static void test_append () {
        String s(cstr("abcd"));
        SECTION("char") {
            s.append(5, (T)'x');
            REQUIRE_STRM(s, mstr("abcdxxxxx"));
        }
        SECTION("same class string") {
            s.append(String(cstr("1234")));
            REQUIRE_STRM(s, mstr("abcd1234"));
            s.append(String(cstr("qwerty")), 3);
            REQUIRE_STRM(s, mstr("abcd1234rty"));
            s.append(String(cstr("hello world")), 5, 4);
            REQUIRE_STRM(s, mstr("abcd1234rty wor"));
        }
        SECTION("foreign class string") {
            s.append(String2(cstr("1234")));
            REQUIRE_STRM(s, mstr("abcd1234"));
            s.append(String2(cstr("qwerty")), 3);
            REQUIRE_STRM(s, mstr("abcd1234rty"));
            s.append(String2(cstr("hello world")), 5, 4);
            REQUIRE_STRM(s, mstr("abcd1234rty wor"));
        }
        SECTION("ptr") {
            s.append(cstr("1234"));
            REQUIRE_STRM(s, mstr("abcd1234"));
            s.append(cstr("qwerty"), 3);
            REQUIRE_STRM(s, mstr("abcd1234qwe"));
        }
        SECTION("literal") {
            s.append(LITERAL);
            REQUIRE_STRM(s, mstr("abcd") + StdString(LITERAL));
        }
        SECTION("initializer list") {
            s.append({'1', '2', '3', '4'});
            REQUIRE_STRM(s, mstr("abcd1234"));
        }
        SECTION("string_view") {
            s.append(svstr("1234"));
            REQUIRE_STRM(s, mstr("abcd1234"));
        }
        SECTION("self append") {
            s = cstr("12345678901234567890");
            s.append(s);
            REQUIRE_STRM(s, mstr("1234567890123456789012345678901234567890"));
            s.append(s, 1, 6);
            REQUIRE_STRM(s, mstr("1234567890123456789012345678901234567890234567"));
        }
        SECTION("preserve_allocated_when_empty_but_reserved") {
            String s;
            String s2(cstr("a", 50));
            String s3(cstr("b", 10));
            get_allocs();
            s.reserve(100);
            REQUIRE_ALLOCS(1, BUF_CHARS+100);
            s.append(s2);
            REQUIRE_ALLOCS();
            s.append(s3);
            REQUIRE_ALLOCS();
            REQUIRE_STR(s, mstr("a",50)+mstr("b",10), 100);
        }
        SECTION("use_cow_when_empty_without_reserve") {
            String s;
            String s2(cstr("a", 50));
            String s3(cstr("b", 10));
            get_allocs();
            s.append(s2);
            REQUIRE_ALLOCS();
            REQUIRE(s2.use_count() == 2);
            s.append(s3);
            REQUIRE_ALLOCS(1, BUF_CHARS+60);
            REQUIRE_STR(s, mstr("a",50)+mstr("b",10));
        }
        SECTION("operator +=") {
            String s(cstr("abcd"));
            s += String(cstr("1234"));
            REQUIRE_STRM(s, mstr("abcd1234"));
            s += String2(cstr("qwerty"));
            REQUIRE_STRM(s, mstr("abcd1234qwerty"));
            s += cstr("hello world");
            REQUIRE_STRM(s, mstr("abcd1234qwertyhello world"));
            s += (T)'x';
            REQUIRE_STRM(s, mstr("abcd1234qwertyhello worldx"));
            s += s;
            REQUIRE_STRM(s, mstr("abcd1234qwertyhello worldxabcd1234qwertyhello worldx"));
        }
    }

    template <class FString>
    static void test_op_plus () {
        get_allocs();
        auto lexp = mstr("x", 30);
        auto rexp = mstr("y", 40);
        String empty;
        SECTION("str-str") {
            String  lhs(lexp.c_str());
            FString rhs(rexp.c_str());
            get_allocs();
            String s = lhs + rhs;
            REQUIRE_STR(s, lexp+rexp);
            REQUIRE(lhs.use_count() == 1); REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1); // no cows
            REQUIRE_ALLOCS(1, BUF_CHARS+70);
            s = EMPTY; get_allocs();
            s = lhs + empty;
            REQUIRE(lhs.use_count() == 2); REQUIRE(s.use_count() == 2); // cow
            REQUIRE_STR(s, lexp, 0, lexp.size());
            REQUIRE_ALLOCS();
            s = EMPTY;
            s = empty + rhs;
            REQUIRE(rhs.use_count() == 2); REQUIRE(s.use_count() == 2); // cow
            REQUIRE_STR(s, rexp, 0, rexp.size());
            REQUIRE_ALLOCS();
        }
        SECTION("ptr-str") {
            auto lhs = lexp.c_str();
            String rhs(rexp.c_str());
            get_allocs();
            String s = lhs + rhs;
            REQUIRE_STR(s, lexp+rexp);
            REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE_ALLOCS(1, BUF_CHARS+lexp.size()+rexp.size());
            s = EMPTY; get_allocs();
            s = lhs + empty;
            REQUIRE_STR(s, lexp);
            REQUIRE_ALLOCS(1, BUF_CHARS+lexp.size());
            REQUIRE(s.use_count() == 1);
            s = EMPTY; get_allocs();
            s = cstr("") + rhs;
            REQUIRE_STR(s, rexp, 0, rexp.size());
            REQUIRE(rhs.use_count() == 2); REQUIRE(s.use_count() == 2);
            REQUIRE_ALLOCS();
        }
        SECTION("char-str") {
            T lhs = (T)'x';
            String rhs(rexp.c_str());
            get_allocs();
            String s = lhs + rhs;
            REQUIRE_STR(s, lhs+rexp);
            REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE_ALLOCS(1, BUF_CHARS + rexp.size() + 1);
            s = EMPTY; get_allocs();
            s = lhs + empty;
            REQUIRE_STR(s, mstr("x"), MAX_SSO_CHARS);
            REQUIRE_ALLOCS();
        }
        SECTION("str-ptr") {
            String lhs(lexp.c_str());
            auto rhs = rexp.c_str();
            get_allocs();
            String s = lhs + rhs;
            REQUIRE_STR(s, lexp+rexp);
            REQUIRE(lhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE_ALLOCS(1, BUF_CHARS + lexp.size() + rexp.size());
            s = EMPTY; get_allocs();
            s = empty + rhs;
            REQUIRE_STR(s, rexp);
            REQUIRE(s.use_count() == 1);
            s = EMPTY; get_allocs();
            s = lhs + cstr("");
            REQUIRE_STR(s, lexp, 0, lexp.size());
            REQUIRE(lhs.use_count() == 2); REQUIRE(s.use_count() == 2);
            REQUIRE_ALLOCS();
        }
        SECTION("str-char") {
            String lhs(lexp.c_str());
            T rhs = (T)'y';
            get_allocs();
            String s = lhs + rhs;
            REQUIRE_STR(s, lexp+rhs);
            REQUIRE(lhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE_ALLOCS(1, BUF_CHARS + lhs.size() + 1);
            s = EMPTY; get_allocs();
            s = empty + rhs;
            REQUIRE_STR(s, mstr("y"), MAX_SSO_CHARS);
            REQUIRE_ALLOCS();
        }
        SECTION("mstr-str") {
            String  lhs(lexp.c_str());
            FString rhs(rexp.c_str());
            lhs.reserve(200);
            get_allocs();
            String s = std::move(lhs) + rhs;
            REQUIRE_STR(s, lexp+rexp, 200);
            REQUIRE(lhs.use_count() == 1); REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1); // no cows
            REQUIRE(!lhs); // lhs moved
            REQUIRE_STR(rhs, rexp);
            REQUIRE_ALLOCS();
        }
        SECTION("str-mstr") {
            String  lhs(lexp.c_str());
            FString rhs(rexp.c_str());
            rhs.reserve(250);
            get_allocs();
            String s = lhs + std::move(rhs);
            REQUIRE_STR(s, lexp+rexp, 250);
            REQUIRE(lhs.use_count() == 1); REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1); // no cows
            REQUIRE_STR(lhs, lexp);
            REQUIRE(!rhs);
            REQUIRE_ALLOCS();
        }
        SECTION("mstr-mstr") { // for now it's just lhs.append(rhs), i.e. the same as mstr-str
            String  lhs(lexp.c_str());
            FString rhs(rexp.c_str());
            lhs.reserve(150);
            get_allocs();
            String s = std::move(lhs) + std::move(rhs);
            REQUIRE_STR(s, lexp+rexp, 150);
            REQUIRE(lhs.use_count() == 1); REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1); // no cows
            REQUIRE(!lhs); // lhs moved
            REQUIRE_STR(rhs, rexp);
            REQUIRE_ALLOCS();
        }
        SECTION("ptr-mstr") {
            auto lhs = lexp.c_str();
            String rhs(rexp.c_str());
            rhs.reserve(100);
            get_allocs();
            String s = lhs + std::move(rhs);
            REQUIRE_STR(s, lexp+rexp, 100);
            REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE(!rhs);
            REQUIRE_ALLOCS();
        }
        SECTION("char-mstr") {
            T lhs = (T)'x';
            String rhs(rexp.c_str());
            rhs.reserve(120);
            get_allocs();
            String s = lhs + std::move(rhs);
            REQUIRE_STR(s, lhs+rexp, 120);
            REQUIRE(rhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE(!rhs);
            REQUIRE_ALLOCS();
        }
        SECTION("mstr-ptr") {
            String lhs(lexp.c_str());
            auto rhs = rexp.c_str();
            lhs.reserve(300);
            get_allocs();
            String s = std::move(lhs) + rhs;
            REQUIRE_STR(s, lexp+rexp, 300);
            REQUIRE(lhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE(!lhs);
            REQUIRE_ALLOCS();
        }
        SECTION("mstr-char") {
            String lhs(lexp.c_str());
            T rhs = (T)'y';
            lhs.reserve(400);
            get_allocs();
            String s = std::move(lhs) + rhs;
            REQUIRE_STR(s, lexp+rhs, 400);
            REQUIRE(lhs.use_count() == 1); REQUIRE(s.use_count() == 1);
            REQUIRE(!lhs);
            REQUIRE_ALLOCS();
        }
    }

    static void test_insert_impl (int cnt, bool is_external) {
        auto exp = mstr("a", cnt);
        String s = is_external ? create_external<>(exp) : String(exp.c_str());
        get_allocs();
        SECTION("end") {
            SECTION("has end space") {
                s.length(s.length() - 6);
                s.insert(s.length(), cstr(" world"));
                REQUIRE_STR(s, mstr("a", cnt-6)+mstr(" world"), cnt);
                REQUIRE_ALLOCS();
            }
            SECTION("has head space") {
                s.offset(cnt - 3);
                s.insert(s.length(), cstr(" world"));
                REQUIRE_STR(s, mstr("aaa world"), cnt);
                REQUIRE_ALLOCS();
            }
            SECTION("has both space") {
                s.offset(8, 5);
                REQUIRE(s.capacity() >= 7);
                s.insert(s.length(), cstr(" world"));
                REQUIRE_STR(s, mstr("aaaaa world"), cnt-8);
                REQUIRE_ALLOCS();
            }
            SECTION("has summary space") {
                s.offset(4, cnt-8); // 4 free from head and tail
                s.insert(s.length(), cstr("world")); // 5 inserted
                REQUIRE_STR(s, mstr("a", cnt-8)+mstr("world"), cnt); // moved to the beginning
                REQUIRE_ALLOCS();
            }
            SECTION("has no space") {
                s.offset(2, cnt-4); // 2 free from head and tail
                s.insert(s.length(), cstr("world")); // 5 insterted
                REQUIRE_STR(s, mstr("a", cnt-4)+mstr("world"), cnt+1); // moved to the beginning
                auto stat = get_allocs();
                REQUIRE(stat.allocated_cnt == 1);
                REQUIRE(stat.allocated == (int)BUF_CHARS+cnt+1);
            }
        }
        SECTION("begin") {
            SECTION("has end space") {
                s.length(s.length() - 6);
                s.insert(0, cstr("world "));
                REQUIRE_STR(s, mstr("world ")+mstr("a",cnt-6), cnt);
                REQUIRE_ALLOCS();
            }
            SECTION("has head space") {
                s.offset(cnt - 3);
                s.insert(0, cstr("world "));
                REQUIRE_STR(s, mstr("world aaa"), 9);
                REQUIRE_ALLOCS();
            }
            SECTION("has both space") {
                s.offset(8, 5);
                REQUIRE(s.capacity() >= 7);
                s.insert(0, cstr("world "));
                REQUIRE_STR(s, mstr("world aaaaa"), cnt-2);
                REQUIRE_ALLOCS();
            }
            SECTION("has summary space") {
                s.offset(4, cnt-8); // 4 free from head and tail
                s.insert(0, cstr("world")); // 5 insterted
                REQUIRE_STR(s, mstr("world")+mstr("a",cnt-8), cnt); // moved to the beginning
                REQUIRE_ALLOCS();
            }
            SECTION("has no space") {
                s.offset(2, cnt-4); // 2 free from head and tail
                s.insert(0, cstr("world")); // 5 insterted
                REQUIRE_STR(s, mstr("world")+mstr("a",cnt-4), cnt+1); // moved to the beginning
                auto stat = get_allocs();
                REQUIRE(stat.allocated_cnt == 1);
                REQUIRE(stat.allocated == (int)BUF_CHARS+cnt+1);
            }
        };
        SECTION("middle") {
            SECTION("has end space") {
                s.length(s.length() - 6);
                s.insert(2, cstr("world "));
                REQUIRE_STR(s, mstr("aaworld ")+mstr("a",cnt-8), cnt);
                REQUIRE_ALLOCS();
            }
            SECTION("has head space") {
                s.offset(cnt - 3);
                s.insert(2, cstr("world "));
                REQUIRE_STR(s, mstr("aaworld a"), 9);
                REQUIRE_ALLOCS();
            }
            SECTION("has both space, head is shorter") {
                s.offset(8, 5);
                REQUIRE(s.capacity() >= 7);
                s.insert(2, cstr(" world ")); // head is moved (7 bytes left)
                REQUIRE_STR(s, mstr("aa world aaa"), cnt-1);
                REQUIRE_ALLOCS();
            }
            SECTION("has both space, tail is shorter") {
                s.offset(8, 5);
                s.insert(3, cstr(" world ")); // tail is moved (7 bytes right)
                REQUIRE_STR(s, mstr("aaa world aa"), cnt-8);
                REQUIRE_ALLOCS();
            }
            SECTION("has summary space") {
                s.offset(4, cnt-8); // 4 free from head and tail
                s.insert(2, cstr("world")); // 5 insterted
                REQUIRE_STR(s, mstr("aaworld")+mstr("a",cnt-10), cnt); // moved to the beginning
                REQUIRE_ALLOCS();
            }
            SECTION("has no space") {
                s.offset(2, cnt-4); // 2 free from head and tail
                s.insert(2, cstr("world")); // 5 insterted
                REQUIRE_STR(s, mstr("aaworld")+mstr("a",cnt-6), cnt+1); // moved to the beginning
                auto stat = get_allocs();
                REQUIRE(stat.allocated_cnt == 1);
                REQUIRE(stat.allocated == (int)BUF_CHARS+cnt+1);
            }
        };
    }

    static void test_insert_cow (bool is_external) {
        auto exp = mstr("a", 50);
        String s = is_external ? create_external<>(exp) : String(exp.c_str());
        get_allocs();
        String tmp(s);

        SECTION("end") {
            s.length(s.length() - 10);
            s.insert(s.length(), cstr("hello"));
            REQUIRE_STR(s, mstr("a", 40)+mstr("hello"), 45);
            REQUIRE_ALLOCS(1, BUF_CHARS+45);
        };
        SECTION("begin") {
            s.offset(10, 30);
            s.insert(0, cstr("hello"));
            REQUIRE_STR(s, mstr("hello")+mstr("a",30), 35);
            REQUIRE_ALLOCS(1, BUF_CHARS+35);
        };
        SECTION("middle") {
            s.offset(10, 30);
            s.insert(5, cstr("hello"));
            REQUIRE_STR(s, mstr("aaaaahello")+mstr("a",25), 35);
            REQUIRE_ALLOCS(1, BUF_CHARS+35);
        };
    }

    static void test_insert () {
        get_allocs();

        SECTION("literal") {
            get_allocs();
            SECTION("end") {
                auto exp = mstr(" hello");
                String s(LITERAL);
                s.insert(s.length(), exp.c_str());
                REQUIRE_STR(s, StdString(LITERAL)+exp);
                REQUIRE_ALLOCS(1, BUF_CHARS + LITERAL_LEN + exp.size());
            }
            SECTION("begin") {
                auto exp = mstr("hello ");
                String s(LITERAL);
                s.insert(0, exp.c_str());
                REQUIRE_STR(s, exp + StdString(LITERAL));
                REQUIRE_ALLOCS(1, BUF_CHARS + LITERAL_LEN + exp.size());
            }
            SECTION("middle") {
                auto exp = mstr("epta");
                String s(LITERAL);
                s.insert(5, exp.c_str());
                auto tmp = StdString(LITERAL);
                tmp.insert(5, exp);
                REQUIRE_STR(s, tmp);
                REQUIRE_ALLOCS(1, BUF_CHARS+tmp.size());
            }
        }

        if (CHAR_SIZE == 1) SECTION("sso") { test_insert_impl(MAX_SSO_CHARS, false); }
        SECTION("internal") { test_insert_impl(50, false); }
        SECTION("external") { test_insert_impl(50, true); }

        String  s (cstr("hello, world"));
        String  a (cstr(" suka"));
        String2 a2(cstr(" suka"));

        SECTION("str") {
            s.insert(5, a);
            REQUIRE_STRM(s, mstr("hello suka, world"));
            REQUIRE_THROWS(s.insert(1000, a));
        }
        SECTION("fstr") {
            s.insert(6, a2);
            REQUIRE_STRM(s, mstr("hello, suka world"));
        }
        SECTION("str&pos") {
            s.insert(5, a, 2);
            REQUIRE_STRM(s, mstr("hellouka, world"));
        }
        SECTION("str&pos/len") {
            s.insert(5, a, 2, 2);
            REQUIRE_STRM(s, mstr("hellouk, world"));
        }
        SECTION("fstr&pos/len") {
            s.insert(6, a2, 1, 2);
            REQUIRE_STRM(s, mstr("hello,su world"));
        }
        SECTION("ptr") {
            s.insert(10, cstr("123"));
            REQUIRE_STRM(s, mstr("hello, wor123ld"));
        }
        SECTION("ptr&len") {
            s.insert(10, cstr("123"), 2);
            REQUIRE_STRM(s, mstr("hello, wor12ld"));
        }
        SECTION("=literal=") {
            s.insert(7, LITERAL);
            REQUIRE_STRM(s, mstr("hello, ")+StdString(LITERAL)+mstr("world"));
        }
        SECTION("count char") {
            s.insert(2, 5, (T)'x');
            REQUIRE_STRM(s, mstr("hexxxxxllo, world"));
        }
        SECTION("iterator count char") {
            auto it = s.insert(s.cbegin()+3, 5, (T)'y');
            REQUIRE(*it == (T)'y');
            REQUIRE(*(it-1) == (T)'l');
            REQUIRE_STRM(s, mstr("helyyyyylo, world"));
        }
        SECTION("iterator char") {
            auto it = s.insert(s.cbegin()+5, (T)'z');
            REQUIRE(*it == (T)'z');
            REQUIRE(*(it-1) == (T)'o');
            REQUIRE_STRM(s, mstr("helloz, world"));
        }
        SECTION("initializer list") {
            s.insert(s.cbegin()+1, {(T)'h', (T)'i'});
            REQUIRE_STRM(s, mstr("hhiello, world"));
        }
        SECTION("string_view") {
            s.insert(9, svstr("x", 5));
            REQUIRE_STRM(s, mstr("hello, woxxxxxrld"));
        }

        SECTION("internal cow") { test_insert_cow(false); }
        SECTION("external cow") { test_insert_cow(true);  }

        SECTION("self") {
            s = cstr("a", 20);
            s.insert(10, s);
            REQUIRE_STRM(s, mstr("a", 40));
        }
        SECTION("self&pos/len") {
            s = cstr("a", 20);
            s.insert(10, s, 5, 10);
            REQUIRE_STRM(s, mstr("a", 30));
        }
    }

    static void test_replace_impl (int cnt, bool is_external) {
        auto exp = mstr("a", cnt);
        String s = is_external ? create_external<>(exp) : String(exp.c_str());
        get_allocs();

        SECTION("shrink") {
            s.replace(5, 10, cstr("hello"));
            REQUIRE_STR(s, mstr("a",5)+mstr("hello")+mstr("a",cnt-15), cnt);
            REQUIRE_ALLOCS();
            s.replace(0, 5, EMPTY);
            REQUIRE_STR(s, mstr("hello")+mstr("a",cnt-15), cnt-5);
            REQUIRE_ALLOCS();
        }

        SECTION("grow") {
            SECTION("has end space") {
                s.length(s.length() - 3);
                s.replace(3, 3, cstr("world "));
                REQUIRE_STR(s, mstr("aaaworld ")+mstr("a",cnt-9), cnt);
                REQUIRE_ALLOCS();
            };
            SECTION("has head space") {
                s.offset(cnt - 10);
                s.replace(2, 2, cstr("world "));
                REQUIRE_STR(s, mstr("aaworld aaaaaa"), 14);
                REQUIRE_ALLOCS();
            };
            SECTION("has both space, head is shorter") {
                s.offset(8, 5);
                REQUIRE(s.capacity() >= 7);
                s.replace(1,2, cstr(" world ")); // head is moved (5 bytes to left)
                REQUIRE_STR(s, mstr("a world aa"), cnt-3);
                REQUIRE_ALLOCS();
            };
            SECTION("has both space, tail is shorter") {
                s.offset(8, 5);
                s.replace(2,2, cstr(" world ")); // tail is moved (5 bytes to right)
                REQUIRE_STR(s, mstr("aa world a"), cnt-8);
                REQUIRE_ALLOCS();
            };
            SECTION("has summary space") {
                s.offset(4, cnt-8); // 4 free from head and tail
                s.replace(4,6, cstr("hello world")); // 5 inserted
                REQUIRE_STR(s, mstr("aaaahello world")+mstr("a",cnt-18), cnt); // moved to the beginning
                REQUIRE_ALLOCS();
            };
            SECTION("has no space") {
                s.offset(2, cnt-4); // 2 free from head and tail
                s.replace(4,6, cstr("hello world")); // 5 insterted
                REQUIRE_STR(s, mstr("aaaahello world")+mstr("a",cnt-14), cnt+1); // moved to the beginning
                auto stat = get_allocs();
                REQUIRE(stat.allocated_cnt == 1);
                REQUIRE(stat.allocated == (int)BUF_CHARS+cnt+1);
            };
        }
    }

    static void test_replace () {
        SECTION("literal") {
            String    s  (LITERAL);
            StdString exp(LITERAL);
            SECTION("shrink") {
                exp.replace(5, 5, cstr("hi"));
                s.replace(5, 5, cstr("hi"));
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS(1, BUF_CHARS + exp.size());
            }
            SECTION("grow") {
                exp.replace(5, 10, cstr("epta"));
                s.replace(5, 10, cstr("epta"));
                REQUIRE_STR(s, exp);
                REQUIRE_ALLOCS(1, BUF_CHARS + exp.size());
            }
        }

        if (CHAR_SIZE == 1) SECTION("sso") { test_replace_impl(MAX_SSO_CHARS, false); }
        SECTION("internal") { test_replace_impl(50, false); }
        SECTION("external") { test_replace_impl(50, true); }

        String  s (cstr("hello, world"));
        String  a (cstr(" suka"));
        String2 a2(cstr(" suka"));

        SECTION("str") {
            s.replace(6, 6, a);
            REQUIRE_STRM(s, mstr("hello, suka"));
            s.replace(5, 1000, a);
            REQUIRE_STRM(s, mstr("hello suka"));
            REQUIRE_THROWS(s.replace(1000, 1, a));
        }
        SECTION("fstr") {
            s.replace(1, String::npos, a2);
            REQUIRE_STRM(s, mstr("h suka"));
        }
        SECTION("it/str") {
            s.replace(s.cbegin()+6, s.cbegin()+12, a);
            REQUIRE_STRM(s, mstr("hello, suka"));
            s.replace(s.cbegin()+5, s.cend()+100, a);
            REQUIRE_STRM(s, mstr("hello suka"));
            REQUIRE_THROWS(s.replace(s.cend()+1, s.end(), a));
        }

        SECTION("it/fstr") {
            s.replace(s.cbegin()+1, s.cend(), a2);
            REQUIRE_STRM(s, mstr("h suka"));
        }
        SECTION("str&pos/len") {
            s.replace(6, 6, a, 1, 2);
            REQUIRE_STRM(s, mstr("hello,su"));
            s.replace(6, 6, a, 1, 20);
            REQUIRE_STRM(s, mstr("hello,suka"));
            s.replace(6, 6, a, 1);
            REQUIRE_STRM(s, mstr("hello,suka"));
            REQUIRE_THROWS(s.replace(6,6,a,10));
        }
        SECTION("fstr&pos/len") {
            s.replace(6, 6, a2, 1, 2);
            REQUIRE_STRM(s, mstr("hello,su"));
        }
        SECTION("ptr") {
            s.replace(6, 6, cstr(" guy"));
            REQUIRE_STRM(s, mstr("hello, guy"));
        }
        SECTION("ptr&len") {
            s.replace(6, 6, cstr(" guy"), 3);
            REQUIRE_STRM(s, mstr("hello, gu"));
        }
        SECTION("=literal=") {
            s.replace(6,6, LITERAL);
            REQUIRE_STRM(s, mstr("hello,")+StdString(LITERAL));
        }
        SECTION("it/ptr") {
            s.replace(s.cbegin()+6, s.cbegin()+12, cstr(" guy"));
            REQUIRE_STRM(s, mstr("hello, guy"));
        }
        SECTION("it/ptr&len") {
            s.replace(s.cbegin()+6, s.cbegin()+12, cstr(" guy"), 3);
            REQUIRE_STRM(s, mstr("hello, gu"));
        }
        SECTION("it/=literal=") {
            s.replace(s.cbegin()+6, s.cbegin()+12, LITERAL);
            REQUIRE_STRM(s, mstr("hello,")+StdString(LITERAL));
        }
        SECTION("count char") {
            s.replace(6, 5, 10, (T)'x');
            REQUIRE_STRM(s, mstr("hello,xxxxxxxxxxd"));
        }
        SECTION("it/count char") {
            s.replace(s.cbegin()+6, s.cbegin()+11, 10, (T)'x');
            REQUIRE_STRM(s, mstr("hello,xxxxxxxxxxd"));
        }
        SECTION("initializer list") {
            s.replace(s.cbegin()+6, s.cbegin()+11, {(T)'h', (T)'i'});
            REQUIRE_STRM(s, mstr("hello,hid"));
        }
        SECTION("string_view") {
            s.replace(6, 6, svstr(" guy"));
            REQUIRE_STRM(s, mstr("hello, guy"));
        }
        SECTION("it/string_view") {
            s.replace(s.cbegin()+6, s.cbegin()+12, svstr(" guy"));
            REQUIRE_STRM(s, mstr("hello, guy"));
        }
        SECTION("self") {
            s = cstr("1234567890", 2);
            s.replace(3, 5, s);
            REQUIRE_STRM(s, mstr("123")+mstr("1234567890",2)+mstr("90")+mstr("1234567890"));
        }
        SECTION("self&pos/len") {
            s = cstr("1234567890", 2);
            s.replace(3, 5, s, 2, 15);
            REQUIRE_STRM(s, mstr("123")+mstr("345678901234567")+mstr("90")+mstr("1234567890"));
        }
        SECTION("it/self") {
            s = cstr("1234567890", 2);
            s.replace(s.cbegin()+3, s.cbegin()+8, s);
            REQUIRE_STRM(s, mstr("123")+mstr("1234567890",2)+mstr("90")+mstr("1234567890"));
        }
    }

    static void test_shared_detach () {
        get_allocs();
        SECTION("literal") {
            auto llen = LITERAL_LEN;
            String s(LITERAL);
            s.shared_buf();
            REQUIRE(s.capacity() == llen); // detached
            REQUIRE_ALLOCS(1, BUF_CHARS + LITERAL_LEN);
        }
        SECTION("sso") {
            auto msc = MAX_SSO_CHARS;
            String s(cstr("ab"));
            s.shared_buf();
            REQUIRE(s.capacity() == msc); // noop
            REQUIRE_ALLOCS();
        }
        SECTION("internal") {
            String s(cstr("a", 50));
            get_allocs();
            s.offset(0, 10);
            s.shared_buf();
            REQUIRE(s.capacity() == 50); // noop
            REQUIRE_ALLOCS();
            String tmp(s);
            s.shared_buf();
            REQUIRE(s.shared_capacity() == 50); // noop
            REQUIRE_ALLOCS();
        }
        SECTION("external") {
            String s = create_external(mstr("a",50));
            get_allocs();
            s.offset(0, 10);
            s.shared_buf();
            REQUIRE(s.capacity() == 50); // noop
            REQUIRE_ALLOCS();
            String tmp(s);
            s.shared_buf();
            REQUIRE(s.shared_capacity() == 50); // noop
            REQUIRE_ALLOCS();
        }
    }

    static void test_to_from_number () {
        if (CHAR_SIZE > 1) return;

        SECTION("to number") {
            string s("  1020asd");
            uint64_t val;

            auto res = s.to_number(val);
            REQUIRE(!res.ec);
            REQUIRE(val == 1020);

            res = s.to_number(val, (size_t)3);
            REQUIRE(!res.ec);
            REQUIRE(val == 20);

            res = s.to_number(val, 4, 1);
            REQUIRE(!res.ec);
            REQUIRE(val == 2);

            res = s.to_number(val, 0, 999, 16);
            REQUIRE(!res.ec);
            REQUIRE(val == 66058);

            res = s.to_number(val, 2, 9, 2);
            REQUIRE(!res.ec);
            REQUIRE(val == 2);

            res = s.to_number(val, (size_t)5);
            REQUIRE(!res.ec);
            REQUIRE(val == 0);

            REQUIRE(s.to_number(val, (size_t)6).ec);
        };

        SECTION("from number") {
            string s;
            REQUIRE(string::from_number(10) == "10");
            REQUIRE(string::from_number(10,8) == "12");
            REQUIRE(string::from_number(10, 16) == "a");
            REQUIRE_ALLOCS();
        };
    }

    static void test_foreign_allocator () {
        SECTION("from literal") {
            String2 src(LITERAL);
            String s(src);
            REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            s = EMPTY; src = EMPTY;
            REQUIRE_ALLOCS();
        };
        SECTION("from sso") {
            auto exp = mstr("ab");
            String2 src(exp.c_str());
            String s(src);
            REQUIRE_STR(s, exp, MAX_SSO_CHARS);
            s = EMPTY; src = EMPTY;
            REQUIRE_ALLOCS();
        };
        SECTION("from internal") {
            auto exp = mstr("a", 50);
            String2 src(exp.c_str());
            REQUIRE_ALLOCS(1, BUF_CHARS+exp.size());
            String s(src);
            REQUIRE_ALLOCS();
            REQUIRE_STR(s, exp, 0, exp.size());
            src = EMPTY;
            REQUIRE_ALLOCS();
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,BUF_CHARS+exp.size());
        };
        SECTION("from external") {
            auto exp = mstr("b", 50);
            String2 src = create_external<String2>(exp);
            REQUIRE_ALLOCS(1, EBUF_CHARS);
            String s(src);
            REQUIRE_ALLOCS();
            REQUIRE_STR(s, exp, 0, exp.size());
            src = EMPTY;
            REQUIRE_ALLOCS();
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,1,EBUF_CHARS,0,0,1,exp.size());
        };
        SECTION("from external with custom buf") {
            auto exp = mstr("b", 50);
            String2 src = create_external_cbuf<String2>(exp);
            String s(src);
            REQUIRE_ALLOCS();
            REQUIRE_STR(s, exp, 0, exp.size());
            src = EMPTY;
            REQUIRE_ALLOCS();
            s = EMPTY;
            REQUIRE_ALLOCS(0,0,0,0,0,0,1,exp.size(),1);
        };
    }

    static void test_cstr () {
        SECTION("empty") {
            String s;
            REQUIRE(s.c_str()[0] == 0);
            REQUIRE_STR(s, EMPTY);
            REQUIRE_ALLOCS();
        }
        SECTION("literal") {
            String s(LITERAL);
            REQUIRE(s.c_str()[LITERAL_LEN] == 0);
            REQUIRE_STR(s, LITERAL, LITERAL_LEN, 0);
            REQUIRE_ALLOCS();
        }
        SECTION("sso") {
            SECTION("self") {
                auto exp = mstr("ab");
                String s(exp.c_str());
                REQUIRE(s.c_str()[exp.length()] == 0);
                REQUIRE_STR(s, exp, MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
            SECTION("detach") {
                auto exp = mstr("a", 50);
                String src(exp.c_str());
                get_allocs();
                String s = src.substr(0, 2);
                REQUIRE(s.c_str()[2] == 0);
                REQUIRE_STR(s, mstr("aa"), MAX_SSO_CHARS);
                REQUIRE_ALLOCS();
            }
        }
        SECTION("internal") {
            SECTION("self") {
                auto exp = mstr("ab", 50);
                String s(exp.c_str());
                get_allocs();
                REQUIRE(s.c_str()[exp.length()] == 0);
                REQUIRE_STR(s, exp, exp.length() + 1);
                REQUIRE_ALLOCS(0,0,0,0,1,1);
                s.c_str();
                REQUIRE_ALLOCS();
            }
            SECTION("detach") {
                auto exp = mstr("ab", 50);
                String s(exp.c_str());
                get_allocs();
                String s2(s);
                REQUIRE(s.c_str()[exp.length()] == 0);
                REQUIRE_STR(s, exp, exp.length() + 1);
                REQUIRE_ALLOCS(1,BUF_CHARS+exp.size()+1,0,0,0,0);
                s.c_str();
                REQUIRE_ALLOCS();
            }
        }
    }

    static void run () {
        get_allocs();

        SECTION("ctor") { test_ctor(); }
        SECTION("copy ctor") {
            SECTION("local")   { test_copy_ctor<String>();  }
            SECTION("foreign") { test_copy_ctor<String2>(); }
        }
        SECTION("move ctor") {
            SECTION("local")   { test_move_ctor<String>();  }
            SECTION("foreign") { test_move_ctor<String2>(); }
        }
        SECTION("copy ctor with offset") {
            SECTION("local")   { test_copy_ctor_offset<String>(); }
            SECTION("foreign") { test_copy_ctor_offset<String2>(); }
        }
        SECTION("substr") { test_substr(); }
        SECTION("clear") { test_clear(); }
        SECTION("assign") {
            SECTION("local")   { test_assign<String>();  }
            SECTION("foreign") { test_assign<String2>(); }
        }
        SECTION("offset") { test_offset(); }
        SECTION("swap") {
            SECTION("local")   { test_swap<String>();  }
            SECTION("foreign") { test_swap<String2>(); }
        }
        SECTION("copy") { test_copy(); }
        SECTION("to_bool, empty") { test_bool_empty(); }
        SECTION("use_count") { test_use_count(); }
        SECTION("detach") { test_detach(); }

        SECTION("at/op[]/front/[pop_]back") { test_at_front_back(); }
        SECTION("iterator") { test_iterator(); }

        SECTION("erase") { test_erase(); }
        SECTION("compare") {
            SECTION("local")   { test_compare<String>(); }
            SECTION("foreign") { test_compare<String2>(); }
        }
        SECTION("find") {
            SECTION("local")   { test_find<String>(); }
            SECTION("foreign") { test_find<String2>(); }
        }
        SECTION("reserve") { test_reserve(); }
        SECTION("resize") { test_resize(); }
        SECTION("shrink_to_fit") { test_shrink_to_fit(); }
        SECTION("append") { test_append(); }
        SECTION("operator +") {
            SECTION("local")   { test_op_plus<String>(); }
            SECTION("foreign") { test_op_plus<String2>(); }
        }
        SECTION("insert") { test_insert(); }
        SECTION("replace") { test_replace(); }
        SECTION("shared_detach") { test_shared_detach(); }
        SECTION("to/from_number") { test_to_from_number(); }
        SECTION("from foreign allocator") { test_foreign_allocator(); }
        SECTION("c_str") { test_cstr(); }
    }
};

template <class T> const T                            test_string<T>::LITERAL[38] = {'h','e','l','l','o',' ','w','o','r','l','d',',',' ','t','h','i','s',' ','i','s',' ','a',' ','l','i','t','e','r','a','l',' ','s','t','r','i','n','g',0};
template <class T> const T                            test_string<T>::EMPTY[1]    = {0};
template <class T> typename test_string<T>::StdString test_string<T>::defexp      = test_string<T>::mstr("this string is definitely longer than max sso chars");
template <class T> size_t                             test_string<T>::defsz       = test_string<T>::BUF_CHARS + test_string<T>::defexp.size();

}
