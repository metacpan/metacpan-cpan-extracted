#include <xs.h>
#include <xs/clone.h>
#include <xs/merge.h>
#include <xs/export.h>
#include <xs/compare.h>

using namespace xs;

MODULE = Data::Recursive                PACKAGE = Data::Recursive
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    xs::exp::create_constants(s, {
        {"TRACK_REFS",   CloneFlags::TRACK_REFS},
        {"ARRAY_CONCAT", MergeFlags::ARRAY_CONCAT},
        {"ARRAY_MERGE",  MergeFlags::ARRAY_MERGE},
        {"COPY_DEST",    MergeFlags::COPY_DEST},
        {"LAZY",         MergeFlags::LAZY},
        {"SKIP_UNDEF",   MergeFlags::SKIP_UNDEF},
        {"DELETE_UNDEF", MergeFlags::DELETE_UNDEF},
        {"COPY_SOURCE",  MergeFlags::COPY_SOURCE},
        {"COPY_ALL",     MergeFlags::COPY_ALL}
    });
}

Scalar lclone (SV* source) {
    RETVAL = clone(source, 0);
}

Scalar clone (SV* source, int flags = CloneFlags::TRACK_REFS) {
    RETVAL = clone(source, flags);
}

Scalar merge (SV* dest, SV* source, int flags = 0) {
    RETVAL = merge(Sv(dest), Sv(source), flags);
}

Scalar hash_merge (Hash dest, Hash source, int flags = 0) {
    auto result = merge(dest, source, flags);
    if (result == dest) RETVAL = ST(0); // hash not changed - return the same Ref for speed
    else                RETVAL = Ref::create(result);
}

Scalar array_merge (Array dest, Array source, int flags = 0) {
    auto result = merge(dest, source, flags);
    if (result == dest) RETVAL = ST(0); // array not changed - return the same Ref for speed
    else                RETVAL = Ref::create(result);
}

bool compare (Sv first, Sv second)
