#pragma once
#include <xs/Hash.h>
#include <xs/Array.h>

namespace xs {

struct MergeFlags {
    static constexpr const int ARRAY_CONCAT =  1;
    static constexpr const int ARRAY_MERGE  =  2;
    static constexpr const int COPY_DEST    =  4;
    static constexpr const int LAZY         =  8;
    static constexpr const int SKIP_UNDEF   = 16;
    static constexpr const int DELETE_UNDEF = 32;
    static constexpr const int COPY_SOURCE  = 64;
    static constexpr const int COPY_ALL     = COPY_DEST | COPY_SOURCE;
};

Hash   merge (Hash   dest, const  Hash& source, int flags = 0);
Array  merge (Array  dest, const Array& source, int flags = 0);
Sv     merge (Sv     dest, const    Sv& source, int flags = 0);

}
