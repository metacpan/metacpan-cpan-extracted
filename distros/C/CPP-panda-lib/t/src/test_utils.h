#pragma once

#include <panda/CallbackDispatcher.h>
#include <panda/optional.h>

namespace test {

struct Tracer {
    static int copy_calls;
    static int ctor_calls;
    static int move_calls;
    static int dtor_calls;

    static void refresh() {
        copy_calls = 0;
        ctor_calls = 0;
        move_calls = 0;
        dtor_calls = 0;
    }

    static int ctor_total() {
        return move_calls + copy_calls + ctor_calls;
    }


    int value;
    Tracer(int v) : value(v){ctor_calls++;}
    Tracer(const Tracer& oth) : value(oth.value) {copy_calls++;}
    Tracer(Tracer&& oth) : value(oth.value) {move_calls++;}
    ~Tracer() {dtor_calls++;}
    int operator()(int a) {
        return a + value;
    }
    int operator()(panda::CallbackDispatcher<int(int)>::Event&, int a) {
        return a + value;
    }

    bool operator ==(const Tracer& oth) const {
        return value == oth.value;
    }
};
}
