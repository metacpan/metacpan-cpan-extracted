CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(Panda-Lib VERSION 1.1.5 LANGUAGES CXX)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 14)

file(GLOB_RECURSE libPandaHeader RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/*.h")
file(GLOB_RECURSE libPandaSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/*.cc")

add_library(panda-lib SHARED ${libPandaSource})
target_include_directories(panda-lib PRIVATE src)
set_target_properties(panda-lib PROPERTIES LINKER_LANGUAGE CXX)
set_property(TARGET panda-lib PROPERTY POSITION_INDEPENDENT_CODE ON)

add_library(panda-lib-static STATIC ${libPandaSource})
target_include_directories(panda-lib-static PRIVATE src)
set_target_properties(panda-lib-static PROPERTIES LINKER_LANGUAGE CXX OUTPUT_NAME "panda-lib")
set_property(TARGET panda-lib-static PROPERTY POSITION_INDEPENDENT_CODE ON)
