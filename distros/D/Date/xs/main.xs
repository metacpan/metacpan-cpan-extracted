#include <xs/date.h>
#include <xs/export.h>
#include <panda/endian.h>
#include "private.h"

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

MODULE = Date                PACKAGE = Date::strict
PROTOTYPES: DISABLE

void import (SV*) {
    Scope::Hints::set(strict_hint_name, Simple(1));
}

void unimport (SV*) {
    Scope::Hints::remove(strict_hint_name);
}

INCLUDE: DateRel.xsi

INCLUDE: serialize.xsi

INCLUDE: Timezone.xsi
