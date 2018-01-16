#include <panda/lib/memory.h>
#include <string.h>
#include <iostream>

namespace panda { namespace lib {

static const int START_SIZE = 16;

ObjectAllocator ObjectAllocator::_inst;

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

ObjectAllocator* ObjectAllocator::tls_instance()
{
    //std::cerr << "tls_instance for thread " << std::this_thread::get_id() << std::endl;
    static thread_local ObjectAllocator* ptr;
    if (!ptr) {
        static thread_local ObjectAllocator inst;
        ptr = &inst;
    }
    return ptr;

}

ObjectAllocator::ObjectAllocator () {
    memset(small_pools,  0, POOLS_CNT*sizeof(MemoryPool*));
    memset(medium_pools, 0, POOLS_CNT*sizeof(MemoryPool*));
    memset(big_pools,    0, POOLS_CNT*sizeof(MemoryPool*));
    small_pools[0] = small_pools[1] = new MemoryPool(8); // min bytes = 8, make 4-byte and 8-byte requests shared
}

ObjectAllocator::~ObjectAllocator () {
    for (int i = 0; i < POOLS_CNT; ++i) {
        if (i) delete small_pools[i];
        delete medium_pools[i];
        delete big_pools[i];
    }
}

}}
