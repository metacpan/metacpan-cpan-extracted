#include "test.h"

namespace test {

    int Tracer::copy_calls = 0;
    int Tracer::ctor_calls = 0;
    int Tracer::move_calls = 0;
    int Tracer::dtor_calls = 0;

    Stat allocs;
}
