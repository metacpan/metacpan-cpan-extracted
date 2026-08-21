cmake_minimum_required(VERSION 3.15)

project(libhisto
    VERSION 0.1.0
    DESCRIPTION "Fast, portable, memory-safe 1D histogramming C library"
    LANGUAGES C
)

# Standard C99
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Export compile commands for language servers
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Project options
option(LIBHISTO_BUILD_TOOLS "Build CLI tools" ON)
option(LIBHISTO_BUILD_TESTS "Build test suite" ON)
option(LIBHISTO_BUILD_BENCHMARKS "Build benchmark suite" ON)
option(LIBHISTO_BUILD_EXAMPLES "Build example programs" ON)
option(LIBHISTO_ENABLE_SANITIZERS "Enable ASan and UBSan (Alias for LIBHISTO_ENABLE_ASAN)" OFF)
option(LIBHISTO_ENABLE_ASAN "Enable AddressSanitizer and UndefinedBehaviorSanitizer" OFF)
option(LIBHISTO_ENABLE_TSAN "Enable ThreadSanitizer" OFF)
option(LIBHISTO_ENABLE_MSAN "Enable MemorySanitizer (Clang only)" OFF)
option(LIBHISTO_ENABLE_FUZZING "Build fuzz testing harnesses and standalone corpus runners" OFF)
option(LIBHISTO_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ON)
option(LIBHISTO_BUILD_DOCS "Build Doxygen documentation" OFF)

# Alias handling
if(LIBHISTO_ENABLE_SANITIZERS)
    set(LIBHISTO_ENABLE_ASAN ON)
endif()

# Exclusivity check
set(_sanitizer_count 0)
if(LIBHISTO_ENABLE_ASAN)
    math(EXPR _sanitizer_count "${_sanitizer_count} + 1")
endif()
if(LIBHISTO_ENABLE_TSAN)
    math(EXPR _sanitizer_count "${_sanitizer_count} + 1")
endif()
if(LIBHISTO_ENABLE_MSAN)
    math(EXPR _sanitizer_count "${_sanitizer_count} + 1")
endif()

if(_sanitizer_count GREATER 1)
    message(FATAL_ERROR "Only one sanitizer (ASAN, TSAN, or MSAN) can be enabled at a time.")
endif()

# Standard Doxygen integration
find_package(Doxygen)
if(DOXYGEN_FOUND)
    set(LIBHISTO_BUILD_DOCS ON CACHE BOOL "Build Doxygen documentation" FORCE)
endif()

# Configure common warning flags
add_library(histo_compiler_flags INTERFACE)
if(MSVC)
    target_compile_options(histo_compiler_flags INTERFACE /W4)
    if(LIBHISTO_WARNINGS_AS_ERRORS)
        target_compile_options(histo_compiler_flags INTERFACE /WX)
    endif()
else()
    target_compile_options(histo_compiler_flags INTERFACE -Wall -Wextra -Wpedantic)
    if(LIBHISTO_WARNINGS_AS_ERRORS)
        target_compile_options(histo_compiler_flags INTERFACE -Werror)
    endif()
endif()

# Sanitizers configuration
if(NOT MSVC)
    if(LIBHISTO_ENABLE_ASAN)
        target_compile_options(histo_compiler_flags INTERFACE -fsanitize=address,undefined -fno-omit-frame-pointer)
        target_link_options(histo_compiler_flags INTERFACE -fsanitize=address,undefined)
    elseif(LIBHISTO_ENABLE_TSAN)
        target_compile_options(histo_compiler_flags INTERFACE -fsanitize=thread -fno-omit-frame-pointer)
        target_link_options(histo_compiler_flags INTERFACE -fsanitize=thread)
    elseif(LIBHISTO_ENABLE_MSAN)
        target_compile_options(histo_compiler_flags INTERFACE -fsanitize=memory -fno-omit-frame-pointer)
        target_link_options(histo_compiler_flags INTERFACE -fsanitize=memory)
    endif()
endif()

# Valgrind integration
find_program(VALGRIND_EXECUTABLE valgrind)
if(VALGRIND_EXECUTABLE)
    set(MEMORYCHECK_COMMAND ${VALGRIND_EXECUTABLE})
    set(MEMORYCHECK_COMMAND_OPTIONS "--leak-check=full --error-exitcode=1")
    set(CTEST_MEMORYCHECK_COMMAND ${VALGRIND_EXECUTABLE})
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--leak-check=full --error-exitcode=1")
endif()

# Core library target
add_subdirectory(src)

# CLI Tools
if(LIBHISTO_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

# Testing
if(LIBHISTO_BUILD_TESTS)
    include(CTest)
    enable_testing()
    add_subdirectory(tests)
    if(VALGRIND_EXECUTABLE)
        add_custom_target(memcheck
            COMMAND ${CMAKE_CTEST_COMMAND} -T memcheck -E "test_doc_examples|test_perl_dist" --output-on-failure
            COMMENT "Running tests under Valgrind"
        )

    endif()
elseif(LIBHISTO_ENABLE_FUZZING)
    include(CTest)
    enable_testing()
    add_subdirectory(tests/fuzz)
endif()

# Benchmarks
if(LIBHISTO_BUILD_BENCHMARKS)
    add_subdirectory(bench)
endif()

# Examples
if(LIBHISTO_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(LIBHISTO_BUILD_DOCS AND DOXYGEN_FOUND)
    set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
    set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
    if(EXISTS "${DOXYGEN_IN}")
        configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
        add_custom_target(docs
            COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMENT "Generating API documentation with Doxygen"
            VERBATIM
        )
    endif()
endif()

# ------------------------------------------------------------------------------
# Installation, Export Targets & Packaging
# ------------------------------------------------------------------------------
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Public Headers
install(DIRECTORY include/histo
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.h"
)

# pkg-config file
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/libhisto.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/libhisto.pc
    @ONLY
)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libhisto.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

if(LIBHISTO_BUILD_TOOLS)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/libhistocli.pc.in
        ${CMAKE_CURRENT_BINARY_DIR}/libhistocli.pc
        @ONLY
    )
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libhistocli.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
    )
endif()


# CMake export configuration
set(LIBHISTO_CMAKECONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/libhisto")

install(EXPORT libhistoTargets
    FILE libhistoTargets.cmake
    NAMESPACE libhisto::
    DESTINATION ${LIBHISTO_CMAKECONFIG_INSTALL_DIR}
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/libhistoConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/libhistoConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/libhistoConfig.cmake
    INSTALL_DESTINATION ${LIBHISTO_CMAKECONFIG_INSTALL_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/libhistoConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/libhistoConfigVersion.cmake
    DESTINATION ${LIBHISTO_CMAKECONFIG_INSTALL_DIR}
)

# CPack Packaging configuration
set(CPACK_PACKAGE_NAME "libhisto")
set(CPACK_PACKAGE_VENDOR "libhisto Contributors")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "High-performance, memory-safe ISO C99 histogramming and statistical analysis library")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
endif()
set(CPACK_GENERATOR "TGZ;DEB;RPM")
set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Steffen Mueller <github@steffen-mueller.net>")
set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
set(CPACK_RPM_PACKAGE_LICENSE "MIT")
set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")
include(CPack)

