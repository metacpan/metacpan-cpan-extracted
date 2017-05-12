CMAKE_MINIMUM_REQUIRED (VERSION 2.6)

project(digest CXX)

set(CMAKE_MACOSX_RPATH 1)

if (MINGW)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libgcc")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++")
    set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "${CMAKE_SHARED_LIBRARY_LINK_C_FLAGS} -static-libgcc")
    set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS} -static-libstdc++")
endif()

if(DEFINED ENV{COVERAGE} AND NOT ENV{COVERAGE} STREQUAL "0")
    message("Enabling code coverage")
    set(GCC_COVERAGE_COMPILE_FLAGS "-g -O0 -fprofile-arcs -ftest-coverage")
    set(GCC_COVERAGE_LINK_FLAGS    "-lgcov --coverage")
    set( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${GCC_COVERAGE_COMPILE_FLAGS}" )
    set( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${GCC_COVERAGE_LINK_FLAGS}" )
endif()

set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_IMPORT_LIBRARY_PREFIX "")

set(LIBSASS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.." CACHE PATH "Path to libsass directory")
set(LIBSASS_LIBRARY_DIR "${LIBSASS_DIR}/lib" CACHE PATH "Path to libsass libraries")
set(LIBSASS_INCLUDE_DIR "${LIBSASS_DIR}/include" CACHE PATH "Path to libsass includes")

link_directories("${LIBSASS_LIBRARY_DIR}")
include_directories("${LIBSASS_INCLUDE_DIR}")
include_directories("vendor/b64")
include_directories("vendor/md5")
include_directories("vendor/crc")
include_directories("vendor")

find_library(SASS_LIBRARY NAMES sass
    HINTS "${CMAKE_CURRENT_SOURCE_DIR}/../lib"
)

add_library(digest SHARED vendor/b64/cencode.cpp vendor/b64/cdecode.cpp vendor/md5/md5.cpp vendor/crc/crc_16.cpp vendor/crc/crc_32.cpp src/digest.cpp)
target_link_libraries(digest LINK_PUBLIC sass)

# errors wrongly sometimes?
# if(NOT SASS_LIBRARY)
# 	message( FATAL_ERROR "sass library was not found" )
# endif()
