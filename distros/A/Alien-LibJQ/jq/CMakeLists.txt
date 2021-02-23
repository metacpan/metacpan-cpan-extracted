cmake_minimum_required(VERSION 3.13)
project(jq C)

set(PACKAGE jq)
set(PACKAGE_VERSION "1.6")
set(SO_VERSION "1:4:0")

# interface target holding all compile flags, includes and link dependencies
add_library(jq_compiler_flags INTERFACE)
target_compile_features(jq_compiler_flags INTERFACE c_std_11)
target_compile_options(jq_compiler_flags INTERFACE
  "$<$<COMPILE_LANG_AND_ID:C,GNU>:$<BUILD_INTERFACE:-Wall;-Wextra;-Wno-missing-field-initializers;-Wno-unused-parameter;-Wno-unused-function>>"
  "$<$<COMPILE_LANG_AND_ID:C,MSVC>:$<BUILD_INTERFACE:-W4>>"
)
target_include_directories(jq_compiler_flags INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)

# control where the static and shared libraries are built so that on windows
# we don't need to tinker with the path to run the executable
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
#if(APPLE)
#  set(CMAKE_INSTALL_RPATH "@executable_path/../lib")
#elseif(UNIX)
#  set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
#endif()

function(target_compile_definitions_if_true)
  foreach(arg IN LISTS ARGN)
    if(${arg})
      #message(STATUS "define ${arg}")
      target_compile_definitions(jq_compiler_flags INTERFACE ${arg}=1)
    endif()
  endforeach()
endfunction()

#option(BUILD_SHARED_LIBS "Build using shared libraries" ON)
#if(MSVC)
#  option(MSVC_STATIC_RUNTIME "Build with static runtime" OFF)
#endif()
option(ENABLE_MAINTAINER_MODE "Enable maintainer mode" ON)
option(ENABLE_VALGRIND "Run tests under Valgrind" ON)
option(ENABLE_ASAN "Enable address sanitizer" OFF)
option(ENABLE_UBSAN "Enable undefined behavior sanitizer" OFF)
option(ENABLE_GCOV "Enable gcov code coverage tool" OFF)
option(ENABLE_DOCS "Build docs" ON)
option(ENABLE_ERROR_INJECTION "Build and test with error injection" OFF)
option(ENABLE_ALL_STATIC "Link jq with static libraries only" OFF)
option(ENABLE_PTHREAD_TLS "Enable use of pthread thread local storage" OFF)
option(WITH_ONIGURUMA "Try this for a non-standard install prefix of the oniguruma library" "yes")

# maintainer mode requires bison and flex
if(ENABLE_MAINTAINER_MODE)
  find_package(BISON 3.0 REQUIRED)
  find_package(FLEX REQUIRED)
endif()

find_program(VALGRIND_cmd valgrind DOC "valgrind is required to test jq")
if(NOT VALGRIND_cmd)
  option(ENABLE_VALGRIND "Run tests under Valgrind" OFF)
endif()

if(ENABLE_DOCS)
  find_program(BUNDLE_cmd bundle DOC "bundle is required to build jq documentation")
  if(NOT BUNDLE_cmd)
    option(ENABLE_DOCS "Build docs" OFF)
    message(WARNING "Ruby dependencies for building jq documentation not found")
  endif()
endif()

set(VERSION ${PACKAGE_VERSION})
target_compile_definitions(jq_compiler_flags INTERFACE PACKAGE=${PACKAGE} VERSION=${VERSION})

include(modules/oniguruma/cmake/dist.cmake)
include(CheckCSourceCompiles)
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckStructHasMember)
include(TestBigEndian)

if(MINGW OR WIN32)
  set(HAVE_WIN32 1)
  target_compile_definitions(jq_compiler_flags INTERFACE WIN32=1)
endif()
check_include_files("stdlib.h;stdarg.h;string.h;float.h" STDC_HEADERS)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
check_include_files(sys/stat.h  HAVE_SYS_STAT_H)
check_include_files(stdlib.h    HAVE_STDLIB_H)
check_include_files(string.h    HAVE_STRING_H)
check_include_files(memory.h    HAVE_MEMORY_H)
check_include_files(strings.h   HAVE_STRINGS_H)
check_include_files(inttypes.h  HAVE_INTTYPES_H)
check_include_files(stdint.h    HAVE_STDINT_H)
check_include_files(unistd.h    HAVE_UNISTD_H)
target_compile_definitions_if_true(
  STDC_HEADERS
  HAVE_SYS_TYPES_H
  HAVE_SYS_STAT_H
  HAVE_STDLIB_H
  HAVE_STRING_H
  HAVE_MEMORY_H
  HAVE_STRINGS_H
  HAVE_INTTYPES_H
  HAVE_STDINT_H
  HAVE_UNISTD_H
)

#set(CMAKE_REQUIRED_LIBRARIES "c")
check_function_exists(memmem   HAVE_MEMMEM)
check_function_exists(mkstemp  HAVE_MKSTEMP)
check_include_files(alloca.h   HAVE_ALLOCA_H)
check_function_exists(alloca   HAVE_ALLOCA)
#check_include_files(shlwapi.h  WIN32)
target_compile_definitions_if_true(
  HAVE_MEMMEM
  HAVE_MKSTEMP
  HAVE_ALLOCA_H
  HAVE_ALLOCA
)

check_symbol_exists(isatty       "unistd.h"  HAVE_ISATTY)
check_symbol_exists(_isatty      "io.h"      HAVE__ISATTY)
check_symbol_exists(strptime     "time.h"    HAVE_STRPTIME)
check_symbol_exists(strftime     "time.h"    HAVE_STRFTIME)
check_symbol_exists(timegm       "time.h"    HAVE_TIMEGM)
check_symbol_exists(gmtime_r     "time.h"    HAVE_GMTIME_R)
check_symbol_exists(gmtime       "time.h"    HAVE_GMTIME)
check_symbol_exists(localtime_r  "time.h"    HAVE_LOCALTIME_R)
check_symbol_exists(localtime    "time.h"    HAVE_LOCALTIME)
check_symbol_exists(gettimeofday "time.h"    HAVE_GETTIMEOFDAY)
target_compile_definitions_if_true(
  HAVE_ISATTY
  HAVE__ISATTY
  HAVE_STRPTIME
  HAVE_STRFTIME
  HAVE_TIMEGM
  HAVE_GMTIME_R
  HAVE_GMTIME
  HAVE_LOCALTIME_R
  HAVE_LOCALTIME
  HAVE_GETTIMEOFDAY
)

CHECK_STRUCT_HAS_MEMBER("struct tm"  tm_gmtoff    time.h   HAVE_TM_TM_GMT_OFF    LANGUAGE C)
CHECK_STRUCT_HAS_MEMBER("struct tm"  __tm_gmtoff  time.h   HAVE_TM___TM_GMT_OFF  LANGUAGE C)
target_compile_definitions_if_true(
  HAVE_TM_TM_GMT_OFF
  HAVE_TM___TM_GMT_OFF
)

if(ENABLE_PTHREAD_TLS)
  set(THREADS_PREFER_PTHREAD_FLAG TRUE)
  find_package(Threads)
  if(CMAKE_USE_PTHREADS_INIT)
    #set(CMAKE_REQUIRED_LIBRARIES "pthread")
    check_symbol_exists(pthread_key_create  "pthread.h"  HAVE_PTHREAD_KEY_CREATE)
    check_symbol_exists(pthread_once        "pthread.h"  HAVE_PTHREAD_ONCE)
    check_symbol_exists(atexit              "stdlib.h"   HAVE_ATEXIT)
    target_compile_definitions_if_true(
      HAVE_PTHREAD_KEY_CREATE
      HAVE_PTHREAD_ONCE
      HAVE_ATEXIT
    )
    target_link_libraries(jq_compiler_flags Threads::Threads)
  endif()
endif()

set(CMAKE_REQUIRED_LIBRARIES "m")
check_symbol_exists(acos         "math.h"  HAVE_ACOS)
check_symbol_exists(acosh        "math.h"  HAVE_ACOSH)
check_symbol_exists(asin         "math.h"  HAVE_ASIN)
check_symbol_exists(asinh        "math.h"  HAVE_ASINH)
check_symbol_exists(atan2        "math.h"  HAVE_ATAN2)
check_symbol_exists(atan         "math.h"  HAVE_ATAN)
check_symbol_exists(atanh        "math.h"  HAVE_ATANH)
check_symbol_exists(cbrt         "math.h"  HAVE_CBRT)
check_symbol_exists(ceil         "math.h"  HAVE_CEIL)
check_symbol_exists(copysign     "math.h"  HAVE_COPYSIGN)
check_symbol_exists(cos          "math.h"  HAVE_COS)
check_symbol_exists(cosh         "math.h"  HAVE_COSH)
check_symbol_exists(drem         "math.h"  HAVE_DREM)
check_symbol_exists(erf          "math.h"  HAVE_ERF)
check_symbol_exists(erfc         "math.h"  HAVE_ERFC)
check_symbol_exists(exp10        "math.h"  HAVE_EXP10)
check_symbol_exists(exp2         "math.h"  HAVE_EXP2)
check_symbol_exists(exp          "math.h"  HAVE_EXP)
check_symbol_exists(expm1        "math.h"  HAVE_EXPM1)
check_symbol_exists(fabs         "math.h"  HAVE_FABS)
check_symbol_exists(fdim         "math.h"  HAVE_FDIM)
check_symbol_exists(floor        "math.h"  HAVE_FLOOR)
check_symbol_exists(fma          "math.h"  HAVE_FMA)
check_symbol_exists(fmax         "math.h"  HAVE_FMAX)
check_symbol_exists(fmin         "math.h"  HAVE_FMIN)
check_symbol_exists(fmod         "math.h"  HAVE_FMOD)
check_symbol_exists(frexp        "math.h"  HAVE_FREXP)
check_symbol_exists(gamma        "math.h"  HAVE_GAMMA)
check_symbol_exists(hypot        "math.h"  HAVE_HYPOT)
check_symbol_exists(j0           "math.h"  HAVE_J0)
check_symbol_exists(j1           "math.h"  HAVE_J1)
check_symbol_exists(jn           "math.h"  HAVE_JN)
check_symbol_exists(ldexp        "math.h"  HAVE_LDEXP)
check_symbol_exists(lgamma       "math.h"  HAVE_LGAMMA)
check_symbol_exists(log10        "math.h"  HAVE_LOG10)
check_symbol_exists(log1p        "math.h"  HAVE_LOG1P)
check_symbol_exists(log2         "math.h"  HAVE_LOG2)
check_symbol_exists(log          "math.h"  HAVE_LOG)
check_symbol_exists(logb         "math.h"  HAVE_LOGB)
check_symbol_exists(modf         "math.h"  HAVE_MODF)
check_symbol_exists(lgamma_r     "math.h"  HAVE_LGAMMA_R)
check_symbol_exists(nearbyint    "math.h"  HAVE_NEARBYINT)
check_symbol_exists(nextafter    "math.h"  HAVE_NEXTAFTER)
check_symbol_exists(nexttoward   "math.h"  HAVE_NEXTTOWARD)
check_symbol_exists(pow10        "math.h"  HAVE_POW10)
check_symbol_exists(pow          "math.h"  HAVE_POW)
check_symbol_exists(remainder    "math.h"  HAVE_REMAINDER)
check_symbol_exists(rint         "math.h"  HAVE_RINT)
check_symbol_exists(round        "math.h"  HAVE_ROUND)
check_symbol_exists(scalb        "math.h"  HAVE_SCALB)
check_symbol_exists(scalbln      "math.h"  HAVE_SCALBLN)
check_symbol_exists(significand  "math.h"  HAVE_SIGNIFICAND)
check_symbol_exists(sin          "math.h"  HAVE_SIN)
check_symbol_exists(sinh         "math.h"  HAVE_SINH)
check_symbol_exists(sqrt         "math.h"  HAVE_SQRT)
check_symbol_exists(tan          "math.h"  HAVE_TAN)
check_symbol_exists(tanh         "math.h"  HAVE_TANH)
check_symbol_exists(tgamma       "math.h"  HAVE_TGAMMA)
check_symbol_exists(trunc        "math.h"  HAVE_TRUNC)
check_symbol_exists(y0           "math.h"  HAVE_Y0)
check_symbol_exists(y1           "math.h"  HAVE_Y1)
check_symbol_exists(yn           "math.h"  HAVE_YN)
unset(CMAKE_REQUIRED_LIBRARIES)
target_compile_definitions_if_true(
  HAVE_ACOSH
  HAVE_ACOS
  HAVE_ASIN
  HAVE_ASINH
  HAVE_ATAN2
  HAVE_ATAN
  HAVE_ATANH
  HAVE_CBRT
  HAVE_CEIL
  HAVE_COPYSIGN
  HAVE_COS
  HAVE_COSH
  HAVE_DREM
  HAVE_ERF
  HAVE_ERFC
  HAVE_EXP10
  HAVE_EXP2
  HAVE_EXP
  HAVE_EXPM1
  HAVE_FABS
  HAVE_FDIM
  HAVE_FLOOR
  HAVE_FMA
  HAVE_FMAX
  HAVE_FMIN
  HAVE_FMOD
  HAVE_FREXP
  HAVE_GAMMA
  HAVE_HYPOT
  HAVE_J0
  HAVE_J1
  HAVE_JN
  HAVE_LDEXP
  HAVE_LGAMMA
  HAVE_LOG10
  HAVE_LOG1P
  HAVE_LOG2
  HAVE_LOG
  HAVE_LOGB
  HAVE_MODF
  HAVE_LGAMMA_R
  HAVE_NEARBYINT
  HAVE_NEXTAFTER
  HAVE_NEXTTOWARD
  HAVE_POW10
  HAVE_POW
  HAVE_REMAINDER
  HAVE_RINT
  HAVE_ROUND
  HAVE_SCALB
  HAVE_SCALBLN
  HAVE_SIGNIFICAND
  HAVE_SIN
  HAVE_SINH
  HAVE_SQRT
  HAVE_TAN
  HAVE_TANH
  HAVE_TGAMMA
  HAVE_TRUNC
  HAVE_Y0
  HAVE_Y1
  HAVE_YN
)

CHECK_C_SOURCE_COMPILES("static __thread int x = 1; int main() { return x; }" HAVE___THREAD)
target_compile_definitions_if_true(HAVE___THREAD)

TEST_BIG_ENDIAN(TEST_BYTE_ORDER_BIG_ENDIAN)
if(TEST_BYTE_ORDER_BIG_ENDIAN)
  target_compile_definitions(jq_compiler_flags INTERFACE IEEE_MC68k=1)
else()
  target_compile_definitions(jq_compiler_flags INTERFACE IEEE_8087=1)
endif()

set(HAVE_LIBONIG 0)
if(WITH_ONIGURUMA STREQUAL "builtin")
  message(STATUS "build and link builtin oniguruma library")
  add_subdirectory(modules/oniguruma)
  set(HAVE_LIBONIG 1)
elseif(IS_DIRECTORY ${WITH_ONIGURUMA})
  message(STATUS "link oniguruma library from ${WITH_ONIGURUMA}")
  find_package(oniguruma REQUIRED PATHS ${WITH_ONIGURUMA} NO_DEFAULT_PATH)
else()
  find_package(oniguruma)
endif()
if(oniguruma_FOUND)
  set(HAVE_LIBONIG 1)
endif()
target_compile_definitions_if_true(HAVE_LIBONIG)

add_library(jq
  src/builtin.c src/bytecode.c src/compile.c src/execute.c
  src/jq_test.c src/jv.c src/jv_alloc.c src/jv_aux.c
  src/jv_dtoa.c src/jv_file.c src/jv_parse.c src/jv_print.c
  src/jv_unicode.c src/linker.c src/locfile.c src/util.c
  src/builtin.h src/bytecode.h src/compile.h
  src/exec_stack.h src/jq_parser.h src/jv_alloc.h src/jv_dtoa.h
  src/jv_unicode.h src/jv_utf8_tables.h src/lexer.l src/libm.h
  src/linker.h src/locfile.h src/opcode_list.h src/parser.y
  src/util.h
)
target_link_libraries(jq PUBLIC "$<BUILD_INTERFACE:jq_compiler_flags>")
target_link_libraries(jq PUBLIC -lm)
target_link_options(jq PRIVATE -export-symbols-regex '^j[qv]_' -version-info ${SO_VERSION})
#target_link_options(jq PRIVATE -export-symbols-regex '^j[qv]_')
set_target_properties(jq PROPERTIES
  VERSION ${VERSION}
  SOVERSION ${SO_VERSION}
)
if(HAVE_WIN32)
  target_link_libraries(jq PUBLIC -lshlwapi)
endif()

if(ENABLE_MAINTAINER_MODE)
  FLEX_TARGET(jq_lexer src/lexer.l ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.c
    COMPILE_FLAGS --warnings=all -d
    DEFINES_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.h
  )
  target_sources(jq PRIVATE
    ${FLEX_JQ_LEXER_OUTPUTS} ${FLEX_JQ_LEXER_OUTPUT_HEADER}
    src/parser.h src/parser.c
    src/builtin.inc src/version.h
  )
else()
  target_sources(jq PRIVATE
    src/lexer.h src/lexer.c
    src/parser.h src/parser.c
    src/builtin.inc src/version.h
  )
endif()

if(ENABLE_UBSAN)
  target_compile_options(jq PUBLIC -fsanitize=undefined)
endif()

if(ENABLE_ASAN)
  target_compile_options(jq PUBLIC -fsanitize=address)
  set(NO_VALGRIND ON)
  if(ENABLE_VALGRIND)
    set(NO_VALGRIND OFF)
  else()
    set(NO_VALGRIND ON)
  endif()
endif()

if(ENABLE_GCOV)
  target_compile_options(jq PUBLIC --coverage --no-inline)
endif()

if(ENABLE_ERROR_INJECTION)
  add_library(jq_inject_errors src/inject_errors.c)
  target_link_libraries(jq_inject_errors PRIVATE dl)
  target_link_options(jq_inject_errors PRIVATE -module)
endif()

# TODO: remake src/version.h if and only if the git ID has changed

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/src/builtin.inc
  DEPENDS src/builtin.jq
  COMMENT "making src/builtin.inc from src/builtin.jq"
  COMMAND perl ${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_builtin_inc.pl ${CMAKE_CURRENT_SOURCE_DIR}/src/builtin.jq > ${CMAKE_CURRENT_SOURCE_DIR}/src/builtin.inc
)
set_source_files_properties(src/builtin.c PROPERTIES OBJECT_DEPENDS src/builtin.inc)

if(${WITH_ONIGURUMA} STREQUAL "builtin")
  target_link_libraries(jq PUBLIC onig)
  target_include_directories(jq PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/modules/oniguruma/src>
  $<INSTALL_INTERFACE:include>
  )
elseif(HAVE_LIBONIG)
  target_link_libraries(jq PUBLIC oniguruma::onig)
endif()

# src/builtin.c calls setenv, which is not portable on windows
# below check will add a local implementation and compile
if(WIN32 AND MINGW)
  check_symbol_exists(setenv  "stdlib.h"  HAVE_SETENV)
  target_compile_definitions_if_true(HAVE_SETENV)
  if(NOT HAVE_SETENV)
    target_sources(jq PRIVATE
      src/setenv.h src/setenv.c
    )
    message(STATUS "patching src/builtin.c")
    execute_process(
      COMMAND patch -p0 -N --binary -i builtin.c.patch
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
  endif()
endif()

add_executable(jq_bin src/main.c src/version.h)
set_target_properties(jq_bin PROPERTIES OUTPUT_NAME jq)
target_link_libraries(jq_bin PRIVATE jq)

if(ENABLE_ALL_STATIC)
  target_link_options(jq_bin PRIVATE -all-static)
endif()

# TODO: support test and build manpage
if(ENABLE_DOCS)
endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/jq.pc.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/jq.pc @ONLY)

# TODO: support full packaging
install_library(jq)
install_executable(jq_bin)
install_header(src/jv.h src/jq.h)
install_data(AUTHORS COPYING NEWS README)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/jq.pc DESTINATION lib/pkgconfig)