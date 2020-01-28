#include "test.h"
#include <panda/endian.h>

using namespace panda;

TEST_CASE("endian", "[endian]") {
    auto r1 = h2be16(999);
    auto r2 = h2be32(888);
    auto r3 = h2be64(777);
    CHECK(be2h16(r1) == 999);
    CHECK(be2h32(r2) == 888);
    CHECK(be2h64(r3) == 777); 
}

