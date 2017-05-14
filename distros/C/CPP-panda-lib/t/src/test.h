#pragma once
#include <cstring>
#include <typeinfo>
#include <cxxabi.h>
#include <panda/string.h>
#include <panda/string_map.h>
#include <panda/string_set.h>
#include <panda/lib/memory.h>
#include <panda/basic_string.h>
#include <panda/lib/from_chars.h>
#include <panda/unordered_string_map.h>
#include <panda/unordered_string_set.h>

using std::string_view;
using namespace panda::lib;

inline SV* error_sv (const std::exception& err) {
    dTHX;

    int status;
    char* class_name = abi::__cxa_demangle(typeid(err).name(), NULL, NULL, &status);
    if (status != 0) croak("[error_sv] !critical! abi::__cxa_demangle error");
    SV* errsv = newSVpvs("[");
    sv_catpv(errsv, class_name);
    sv_catpv(errsv, "] ");
    sv_catpv(errsv, err.what());
    free(class_name);

    return errsv;
}

#define PXS_TRY(code) {                                                                       \
    try { code; }                                                                             \
    catch (const std::exception& err) { croak_sv(error_sv(err)); }                            \
    catch (const char* err)           { croak_sv(newSVpv(err, 0)); }                          \
    catch (const std::string& err)    { croak_sv(newSVpvn(err.data(), err.length())); }       \
    catch (const panda::string& err)  { croak_sv(newSVpvn(err.data(), err.length())); }       \
    catch (...)                       { croak_sv(newSVpvs("unknown c++ exception thrown")); } \
}

#define XS_HV_ITER(hv,code) {                                                       \
    STRLEN hvmax = HvMAX(hv);                                                       \
    HE** hvarr = HvARRAY(hv);                                                       \
    if (HvUSEDKEYS(hv))                                                             \
        for (STRLEN bucket_num = 0; bucket_num <= hvmax; ++bucket_num)              \
            for (const HE* he = hvarr[bucket_num]; he; he = HeNEXT(he)) { code }    \
}
#define XS_HV_ITER_NU(hv,code) XS_HV_ITER(hv,{if(!SvOK(HeVAL(he))) continue; code})

#define XS_AV_ITER(av,code) {                                           \
    SV** list = AvARRAY(av);                                            \
    SSize_t fillp = AvFILLp(av);                                        \
    for (SSize_t i = 0; i <= fillp; ++i) { SV* elem = *list++; code }   \
}
#define XS_AV_ITER_NE(av,code) XS_AV_ITER(av,{if(!elem) continue; code})
#define XS_AV_ITER_NU(av,code) XS_AV_ITER(av,{if(!elem || !SvOK(elem)) continue; code})

namespace test {

    namespace string {

        struct AllocsStat {
            int allocated;
            int allocated_cnt;
            int deallocated;
            int deallocated_cnt;
            int reallocated;
            int reallocated_cnt;
            int ext_deallocated;
            int ext_deallocated_cnt;
            int ext_shbuf_deallocated;
        };

        static AllocsStat allocs[2];

        static const char literal_char[] = "hello world, this is a literal string";

        template <class T, int N = 0>
        struct TestAllocator {
            typedef T value_type;

            static T* allocate (size_t n) {
                //std::cout << "allocate " << n << std::endl;
                void* mem = malloc(n * sizeof(T));
                if (!mem) throw std::bad_alloc();
                allocs[N].allocated += n;
                allocs[N].allocated_cnt++;
                return (T*)mem;
            }

            static void deallocate (T* mem, size_t n) {
                //std::cout << "deallocate " << n << std::endl;
                allocs[N].deallocated += n;
                allocs[N].deallocated_cnt++;
                free(mem);
            }

            static T* reallocate (T* mem, size_t need, size_t old) {
                //std::cout << "reallocate need=" << need << " old=" << old << std::endl;
                void* new_mem = realloc(mem, need * sizeof(T));
                allocs[N].reallocated += (need - old);
                allocs[N].reallocated_cnt++;
                return (T*)new_mem;
            }
        };

        template <class T, int N = 0>
        void ext_free (T* mem, size_t n) {
            allocs[N].ext_deallocated += n;
            allocs[N].ext_deallocated_cnt++;
            free(mem);
        }

        template <class T>
        T* shared_buf_alloc () {
            return (T*)panda::lib::StaticMemoryPool<100>::instance()->allocate();
        }

        template <class T, int N = 0>
        void shared_buf_free (T* mem, size_t) {
            panda::lib::StaticMemoryPool<100>::instance()->deallocate(mem);
            allocs[N].ext_shbuf_deallocated++;
        }

        panda::wstring string_view_to_wstring (string_view v) {
            panda::wstring ret(v.length());
            for (size_t i = 0; i < v.length(); ++i) ret[i] = v[i];
            ret.length(v.length());
            return ret;
        }

    }

    typedef panda::basic_string<char, std::char_traits<char>, test::string::TestAllocator<char>> String;
    typedef panda::basic_string<char, std::char_traits<char>, test::string::TestAllocator<char,1>> String2;

    panda::string_map<test::String, panda::string> smap;
    const decltype(smap)* csmap = &smap;
    panda::string_multimap<test::String, panda::string> smmap;
    const decltype(smmap)* csmmap = &smmap;
    panda::unordered_string_map<test::String, panda::string> usmap;
    const decltype(usmap)* cusmap = &usmap;
    panda::unordered_string_multimap<test::String, panda::string> usmmap;
    const decltype(usmmap)* cusmmap = &usmmap;
    panda::string_set<test::String> sset;
    const decltype(sset)* csset = &sset;
    panda::string_multiset<test::String> smset;
    const decltype(smset)* csmset = &smset;
    panda::unordered_string_set<test::String> usset;
    const decltype(usset)* cusset = &usset;
    panda::unordered_string_multiset<test::String> usmset;
    const decltype(usmset)* cusmset = &usmset;
}

typedef test::String  testString;
typedef test::String2 testString2;
typedef panda::string pandaString;

class MyObject : public AllocatedObject<MyObject, false> {
public:
    int a;
    MyObject () : a(0) {}
};

class MyObjectThr : public AllocatedObject<MyObject, true> {
public:
    int a;
    MyObjectThr () : a(0) {}
};

class MyObjectDyn : public MyObject {
public:
    int b;
    MyObjectDyn () : b(0) {}
};

class MyObjectDynThr : public MyObjectThr {
public:
    int b;
    MyObjectDynThr () : b(0) {}
};

static inline uint64_t _test_on_thread_start () {
    static const int cnt = 10000;
    uint64_t ret = 0;
    for (int i = 0; i < cnt; ++i) {
        void* mem = ObjectAllocator::tls_instance()->allocate(16);
        ret += (uint64_t) mem;
        ObjectAllocator::tls_instance()->deallocate(mem, 16);
        mem = StaticMemoryPool<16>::tls_instance()->allocate();
        ret += (uint64_t) mem;
        StaticMemoryPool<16>::tls_instance()->deallocate(mem);
    }
    return ret;
}

#ifdef _WIN32
static inline DWORD WINAPI test_on_thread_start (LPVOID lpParameter) { return (DWORD)_test_on_thread_start(); }
#else
static inline void* test_on_thread_start (void*) { return (void*)_test_on_thread_start(); }
#endif
