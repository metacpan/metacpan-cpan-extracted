#pragma once
#include <cstring>
#include <catch.hpp>
#include <panda/string.h>
#include <panda/optional.h>
#include <panda/memory.h>
#include <panda/CallbackDispatcher.h>

namespace test {

    struct Tracer {
        static int copy_calls;
        static int ctor_calls;
        static int move_calls;
        static int dtor_calls;

        static void reset () {
            copy_calls = 0;
            ctor_calls = 0;
            move_calls = 0;
            dtor_calls = 0;
        }

        static void refresh () { reset(); }

        static int ctor_total () {
            return move_calls + copy_calls + ctor_calls;
        }

        int value;

        Tracer (int v = 0)         : value(v)         {ctor_calls++;}
        Tracer (const Tracer& oth) : value(oth.value) {copy_calls++;}
        Tracer (Tracer&& oth)      : value(oth.value) {move_calls++;}

        virtual ~Tracer () {dtor_calls++;}

        int operator() (int a) {
            return a + value;
        }

        int operator() (panda::CallbackDispatcher<int(int)>::Event&, int a) {
            return a + value;
        }

        bool operator== (const Tracer& oth) const {
            return value == oth.value;
        }
    };

    struct Stat {
        int allocated;
        int allocated_cnt;
        int deallocated;
        int deallocated_cnt;
        int reallocated;
        int reallocated_cnt;
        int ext_deallocated;
        int ext_deallocated_cnt;
        int ext_shbuf_deallocated;

        bool is_empty () const {
            return !allocated && !allocated_cnt && !deallocated && !deallocated_cnt && !reallocated && !reallocated_cnt && !ext_deallocated &&
                   !ext_deallocated_cnt && !ext_shbuf_deallocated;
        }
    };

    extern Stat allocs;

    inline Stat get_allocs () {
        auto ret = allocs;
        std::memset(&allocs, 0, sizeof(Stat));
        return ret;
    }

    template <class T = char, int N = 0>
    struct Allocator {
        typedef T value_type;

        static T* allocate (size_t n) {
            //std::cout << "allocate " << n << std::endl;
            void* mem = malloc(n * sizeof(T));
            if (!mem) throw std::bad_alloc();
            allocs.allocated += n;
            allocs.allocated_cnt++;
            return (T*)mem;
        }

        static void deallocate (T* mem, size_t n) {
            //std::cout << "deallocate " << n << std::endl;
            allocs.deallocated += n;
            allocs.deallocated_cnt++;
            free(mem);
        }

        static T* reallocate (T* mem, size_t need, size_t old) {
            //std::cout << "reallocate need=" << need << " old=" << old << std::endl;
            void* new_mem = realloc(mem, need * sizeof(T));
            allocs.reallocated += (need - old);
            allocs.reallocated_cnt++;
            return (T*)new_mem;
        }

        static void ext_free (T* mem, size_t n) {
            allocs.ext_deallocated += n;
            allocs.ext_deallocated_cnt++;
            free(mem);
        }

        static void shared_buf_free (T* mem, size_t size) {
            panda::DynamicMemoryPool::instance()->deallocate(mem, size * sizeof(T));
            allocs.ext_shbuf_deallocated++;
        }
    };

}
