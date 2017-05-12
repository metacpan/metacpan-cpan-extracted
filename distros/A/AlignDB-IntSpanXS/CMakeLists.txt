cmake_minimum_required(VERSION 3.5)
project(intspan)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
    benchmark/test_c.c
    intspan.c)

include_directories(.)

add_executable(test_c ${SOURCE_FILES})
