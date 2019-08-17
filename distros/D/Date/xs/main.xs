#include <xs/time.h>
#include <xs/date/util.h>
#include <panda/endian.h>

using namespace xs;
using namespace xs::date;
using namespace panda::time;
using panda::string;
using panda::string_view;

MODULE = Date                PACKAGE = Date
PROTOTYPES: DISABLE

BOOT {
    XS_BOOT(Date__Date);
}

INCLUDE: DateRel.xsi

INCLUDE: DateInt.xsi

INCLUDE: serialize.xsi
