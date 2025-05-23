cmake_minimum_required(VERSION 3.10)

if(NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(IS_SUBPROJECT TRUE)
    set(NOT_SUBPROJECT FALSE)
else()
    set(NOT_SUBPROJECT TRUE)
endif()

project(panda-date VERSION 2.1.1 LANGUAGES CXX)

set(LIB_TYPE STATIC)
option(PANDA_DATE_TESTS OFF)
option(PANDA_DATE_TESTS_IN_ALL ${NOT_SUBPROJECT})
if (${PANDA_DATE_TESTS_IN_ALL})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
list(APPEND libSource "src/panda/date/parse-date.cc" "src/panda/date/parse-relative.cc" "src/panda/date/strptime.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)

target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)
set_source_files_properties(src/panda/date/parse-date.cc     PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")
set_source_files_properties(src/panda/date/parse-relative.cc PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")
set_source_files_properties(src/panda/date/strptime.cc       PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")

set(ZONE_INFO ${CMAKE_INSTALL_PREFIX}/share/zoneinfo)
if (IS_SUBPROJECT)
    set(ZONE_INFO ${CMAKE_CURRENT_SOURCE_DIR}/zoneinfo)
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE
    PANDA_DATE_ZONEINFO_DIR="${ZONE_INFO}"
)
message(STATUS ${CMAKE_SYSTEM_PREFIX_PATH})

find_program(ragel_bin ragel)
if (ragel_bin)
    set(RL_DIR "src/panda/date")
    foreach(fpath ${RL_DIR}/parse-date ${RL_DIR}/parse-relative ${RL_DIR}/strptime)
        add_custom_command(
            OUTPUT  ${CMAKE_CURRENT_SOURCE_DIR}/${fpath}.cc
            COMMAND ragel -C -G2 ${fpath}.rl -o ${fpath}.cc
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${fpath}.rl
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
    endforeach()
endif()

if (NOT TARGET panda-lib)
    find_package(panda-lib REQUIRED)
endif()
target_link_libraries(${PROJECT_NAME} panda-lib)

########################tests#######################################
if (${PANDA_DATE_TESTS})
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")
set_source_files_properties(tests/relative/operations.cc PROPERTIES COMPILE_FLAGS "-Wno-self-assign-overloaded")
if(WIN32)
    list(FILTER testSource EXCLUDE REGEX "tests/time/full.cc")
endif()

add_library(${PROJECT_NAME}-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(${PROJECT_NAME}-tests PUBLIC ${PROJECT_NAME})

find_package(Catch2)
find_package(Threads)
target_link_libraries(${PROJECT_NAME}-tests PUBLIC Catch2::Catch2 Threads::Threads)

########################ctests######################################
enable_testing()
add_executable(${PROJECT_NAME}-runtests ${EXCLUDE_TEST} ${testSource} "tests/main.cc")
target_link_libraries(${PROJECT_NAME}-runtests ${PROJECT_NAME}-tests Catch2::Catch2WithMain)
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME}-runtests WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

endif()#if (${PANDA_DATE_TESTS})

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
install(DIRECTORY zoneinfo DESTINATION share)
