TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

INCLUDEPATH += src ../CPP-catch/src

SOURCES += \
    src/panda/lib/from_chars.cc \
    src/panda/lib/hash.cc \
    src/panda/lib/memory.cc \
    src/panda/lib.cc \
    src/panda/log.cc \
    t/dispatcher.cc \
    t/from_chars.cc \
    t/function.cc \
    t/iptr.cc \
    t/owning_list.cc \
    t/string_containers.cc \
    t/test.cc \
    t/to_chars.cc \
    t/string_char.cc \
    t/string_wchar.cc \
    t/string_char16.cc \
    t/string_char32.cc \
    t/traits.cc \
    t/bench.cc \
    src/panda/refcnt.cc

HEADERS += \
    src/panda/lib/endian.h \
    src/panda/lib/from_chars.h \
    src/panda/lib/hash.h \
    src/panda/lib/memory.h \
    src/panda/basic_string.h \
    src/panda/basic_string_view.h \
    src/panda/cast.h \
    src/panda/iterator.h \
    src/panda/lib.h \
    src/panda/refcnt.h \
    src/panda/string.h \
    src/panda/string_map.h \
    src/panda/string_set.h \
    src/panda/string_view.h \
    src/panda/unordered_string_map.h \
    src/panda/unordered_string_set.h \
    src/panda/CallbackDispatcher.h \
    src/panda/function.h \
    src/panda/function_utils.h \
    src/panda/lib.h \
    src/panda/optional.h \
    src/panda/log.h \
    src/panda/lib/owning_list.h \
    src/panda/lib/integer_sequence.h \
    t/test.h \
    t/string_test.h \
    src/panda/lib/traits.h

DISTFILES += \
    Makefile.PL \
    t/xs.xs
