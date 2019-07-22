#pragma once
#include <vector>
#include <memory>
#include <assert.h>
#include <stdexcept>

namespace panda {

namespace detail {
    void* __get_global_ptr     (const std::type_info& ti, const char* name, void* val);
    void* __get_global_tls_ptr (const std::type_info& ti, const char* name, void* val);
}

template <class CLASS, class T>
inline T* get_global_ptr (T* val, const char* name = NULL) {
    return reinterpret_cast<T*>(detail::__get_global_ptr(typeid(CLASS), name, reinterpret_cast<void*>(val)));
}

template <class CLASS, class T>
inline T* get_global_tls_ptr (T* val, const char* name = NULL) {
    return reinterpret_cast<T*>(detail::__get_global_tls_ptr(typeid(CLASS), name, reinterpret_cast<void*>(val)));
}

#define PANDA_GLOBAL_MEMBER_PTR(CLASS, TYPE, accessor, defval)              \
    static TYPE accessor () {                                               \
        static TYPE ptr;                                                    \
        if (!ptr) ptr = panda::get_global_ptr<CLASS>(defval, #accessor);    \
        return ptr;                                                         \
    }

#define PANDA_GLOBAL_MEMBER(CLASS, TYPE, accessor, defval)          \
    static TYPE& accessor () {                                      \
        static TYPE* ptr;                                           \
        if (!ptr) {                                                 \
            static TYPE val = defval;                               \
            ptr = panda::get_global_ptr<CLASS>(&val, #accessor);    \
        }                                                           \
        return *ptr;                                                \
    }

#define PANDA_GLOBAL_MEMBER_AS_PTR(CLASS, TYPE, accessor, defval)   \
    static TYPE* accessor () {                                      \
        static TYPE* ptr;                                           \
        if (!ptr) {                                                 \
            static TYPE val = defval;                               \
            ptr = panda::get_global_ptr<CLASS>(&val, #accessor);    \
        }                                                           \
        return ptr;                                                 \
    }

#define PANDA_TLS_MEMBER_PTR(CLASS, TYPE, accessor, defval)                         \
    static TYPE accessor () {                                                       \
        static thread_local TYPE _ptr;                                              \
        TYPE ptr = _ptr;                                                            \
        if (!ptr) ptr = _ptr = panda::get_global_tls_ptr<CLASS>(defval, #accessor); \
        return ptr;                                                                 \
    }

#define PANDA_TLS_MEMBER(CLASS, TYPE, accessor, defval)                     \
    static TYPE& accessor () {                                              \
        static thread_local TYPE* _ptr;                                     \
        TYPE* ptr = _ptr;                                                   \
        if (!ptr) {                                                         \
            static thread_local TYPE val = defval;                          \
            ptr = _ptr = panda::get_global_tls_ptr<CLASS>(&val, #accessor); \
        }                                                                   \
        return *ptr;                                                        \
    }

#define PANDA_TLS_MEMBER_AS_PTR(CLASS, TYPE, accessor, defval)              \
    static TYPE* accessor () {                                              \
        static thread_local TYPE* _ptr;                                     \
        TYPE* ptr = _ptr;                                                   \
        if (!ptr) {                                                         \
            static thread_local TYPE val = defval;                          \
            ptr = _ptr = panda::get_global_tls_ptr<CLASS>(&val, #accessor); \
        }                                                                   \
        return ptr;                                                         \
    }

struct MemoryPool {
    MemoryPool (size_t blocksize) : first_free(NULL) {
        this->blocksize = round_up(blocksize);
    }

    void* allocate () {
        if (!first_free) grow();
        void* ret = first_free;
        first_free = *((void**)ret);
        return ret;
    }

    void deallocate (void* elem) {
        #ifdef TEST_FULL
        if(!is_mine(elem)) abort(); // protection for debugging, normally you MUST NEVER pass a pointer that wasn't created via current mempool
        #endif
        *((void**)elem) = first_free;
        first_free = elem;
    }

    ~MemoryPool ();

private:
    struct Pool {
        char*  list;
        size_t size;
        size_t len;
    };
    size_t            blocksize;
    std::vector<Pool> pools;
    void*             first_free;

    void grow    ();
    bool is_mine (void* elem);

    inline static size_t round_up (size_t size) {
        assert(size > 0);
        const size_t factor = sizeof(void*);
        if ((size & (factor-1)) == 0) return size;
        size += factor;
        size &= ~((size_t)(factor-1));
        return size;
    }
};

template <int BLOCKSIZE>
struct StaticMemoryPool {
    PANDA_GLOBAL_MEMBER_PTR(StaticMemoryPool, MemoryPool*, global_instance, new MemoryPool(BLOCKSIZE));
    PANDA_TLS_MEMBER_PTR   (StaticMemoryPool, MemoryPool*, instance,        new MemoryPool(BLOCKSIZE));

    static void* allocate   ()        { return instance()->allocate(); }
    static void  deallocate (void* p) { instance()->deallocate(p); }
};

template <> struct StaticMemoryPool<7> : StaticMemoryPool<8> {};
template <> struct StaticMemoryPool<6> : StaticMemoryPool<8> {};
template <> struct StaticMemoryPool<5> : StaticMemoryPool<8> {};
template <> struct StaticMemoryPool<4> : StaticMemoryPool<8> {};
template <> struct StaticMemoryPool<3> : StaticMemoryPool<8> {};
template <> struct StaticMemoryPool<2> : StaticMemoryPool<8> {};
template <> struct StaticMemoryPool<1> : StaticMemoryPool<8> {};


struct DynamicMemoryPool {
    static DynamicMemoryPool* global_instance () { return _global_instance; }

    PANDA_TLS_MEMBER_PTR(DynamicMemoryPool, DynamicMemoryPool*, instance, new DynamicMemoryPool());

    DynamicMemoryPool ();

    void* allocate (size_t size) {
        if (size == 0) return NULL;
        MemoryPool* pool;
        if (size <= 1024) {
            pool = small_pools[(size-1)>>2];
            if (!pool) pool = small_pools[(size-1)>>2] = new MemoryPool((((size-1)>>2) + 1)<<2);
        }
        else if (size <= 16384) {
            pool = medium_pools[(size-1)>>6];
            if (!pool) pool = medium_pools[(size-1)>>6] = new MemoryPool((((size-1)>>6) + 1)<<6);
        }
        else if (size <= 262144) {
            pool = big_pools[(size-1)>>10];
            if (!pool) pool = big_pools[(size-1)>>10] = new MemoryPool((((size-1)>>10) + 1)<<10);
        }
        else throw std::invalid_argument("ObjectAllocator: object size cannot exceed 256k");

        return pool->allocate();
    }

    void deallocate (void* ptr, size_t size) {
        if (ptr == NULL || size == 0) return;
        MemoryPool* pool;
        if      (size <= 1024)   pool = small_pools[(size-1)>>2];
        else if (size <= 16384)  pool = medium_pools[(size-1)>>6];
        else if (size <= 262144) pool = big_pools[(size-1)>>10];
        else throw std::invalid_argument("ObjectAllocator: object size cannot exceed 256k");
        pool->deallocate(ptr);
    }

    ~DynamicMemoryPool ();

private:
    static constexpr const int POOLS_CNT = 256;
    static DynamicMemoryPool* _global_instance;
    MemoryPool* small_pools[POOLS_CNT];
    MemoryPool* medium_pools[POOLS_CNT];
    MemoryPool* big_pools[POOLS_CNT];

};

template <class TARGET, bool THREAD_SAFE = true>
struct AllocatedObject {
    static void* operator new (size_t size) {
        if (size == sizeof(TARGET)) return StaticMemoryPool<sizeof(TARGET)>::allocate();
        else                        return DynamicMemoryPool::instance()->allocate(size);
    }

    static void operator delete (void* p, size_t size) {
        if (size == sizeof(TARGET)) StaticMemoryPool<sizeof(TARGET)>::deallocate(p);
        else                        DynamicMemoryPool::instance()->deallocate(p, size);
    }
};

template <class TARGET>
struct AllocatedObject<TARGET, false> {
    static void* operator new (size_t size) {
        if (size == sizeof(TARGET)) return StaticMemoryPool<sizeof(TARGET)>::global_instance()->allocate();
        else                        return DynamicMemoryPool::global_instance()->allocate(size);
    }

    static void operator delete (void* p, size_t size) {
        if (size == sizeof(TARGET)) StaticMemoryPool<sizeof(TARGET)>::global_instance()->deallocate(p);
        else                        DynamicMemoryPool::global_instance()->deallocate(p, size);
    }
};

}
