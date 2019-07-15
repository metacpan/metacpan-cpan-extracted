#include "memory.h"
#include "../string.h"
#include <map>
#include <mutex>
#include <string.h>

namespace panda { namespace lib {

static std::map<string, void*> global_ptrs;
static std::mutex              global_ptrs_mutex;

static thread_local std::map<string, void*> global_tls_ptrs;

static const int START_SIZE = 16;

DynamicMemoryPool* DynamicMemoryPool::_global_instance = new DynamicMemoryPool();

void* detail::__get_global_ptr (const std::type_info& ti, const char* name, void* val) {
    string key(ti.name());
    if (name) key += name;

    std::lock_guard<std::mutex> guard(global_ptrs_mutex);
    auto it = global_ptrs.find(key);
    if (it != global_ptrs.end()) return it->second;

    global_ptrs.emplace(key, val);
    return val;
}

void* detail::__get_global_tls_ptr (const std::type_info& ti, const char* name, void* val) {
    string key(ti.name());
    if (name) key += name;

    auto it = global_tls_ptrs.find(key);
    if (it != global_tls_ptrs.end()) return it->second;

    global_tls_ptrs.emplace(key, val);
    return val;
}

void MemoryPool::grow () {
    size_t pools_cnt = pools.size();
    if (pools_cnt) {
        pools.resize(pools_cnt+1);
        pools[pools_cnt].size = pools[pools_cnt-1].size*2;
    } else {
        pools.resize(1);
        pools[0].size = START_SIZE;
    }
    Pool* pool = &pools.back();
    pool->len = pool->size * blocksize;
    char* elem = pool->list = new char[pool->len];
    char* end  = elem + pool->len;
    while (elem < end) {
        *((void**)elem) = elem + blocksize; // set next free for each free element
        elem += blocksize;
    }
    *((void**)(elem-blocksize)) = NULL; // last element has no next free
    first_free = pool->list;
}

bool MemoryPool::is_mine (void* elem) {
    Pool* first = &pools.front();
    Pool* pool  = &pools.back();
    while (pool >= first) { // from last to first, because most possibility that elem is in latest pools
        if (elem >= pool->list && elem < pool->list + pool->len) return true;
        pool--;
    }
    return false;
}

MemoryPool::~MemoryPool () {
    if (!pools.size()) return;
    Pool* pool = &pools.front();
    Pool* last = &pools.back();
    while (pool <= last) {
        delete[] pool->list;
        pool++;
    }
}

DynamicMemoryPool::DynamicMemoryPool () {
    memset(small_pools,  0, POOLS_CNT*sizeof(MemoryPool*));
    memset(medium_pools, 0, POOLS_CNT*sizeof(MemoryPool*));
    memset(big_pools,    0, POOLS_CNT*sizeof(MemoryPool*));
    small_pools[0] = small_pools[1] = new MemoryPool(8); // min bytes = 8, make 4-byte and 8-byte requests shared
}

DynamicMemoryPool::~DynamicMemoryPool () {
    for (int i = 0; i < POOLS_CNT; ++i) {
        if (i) delete small_pools[i];
        delete medium_pools[i];
        delete big_pools[i];
    }
}

}}
