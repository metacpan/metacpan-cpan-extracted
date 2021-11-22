#include <upb/upb.h>
#include <google/protobuf/descriptor.upb.h>
#include <stdio.h>

using namespace upb;
using namespace std;

int main(int argc, char **argv) {
    upb::Arena arena;

    printf("%p\n", arena.allocator());
}
