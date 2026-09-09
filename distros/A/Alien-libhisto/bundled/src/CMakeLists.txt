add_library(histo
    histo.c
    histo2d.c
    fit.c
    kde.c
    simd.c
    sketch.c
    serialize.c
    serialize_2d.c
    vendor/cJSON/cJSON.c
)

include(CheckCCompilerFlag)

# Detect host / target architecture
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|AMD64|i[3-6]86|x86")
    set(LIBHISTO_ARCH_X86 TRUE)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64")
    set(LIBHISTO_ARCH_ARM64 TRUE)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv[0-9].*|arm")
    set(LIBHISTO_ARCH_ARM32 TRUE)
endif()

# Check compiler flag compatibility
if(MSVC)
    check_c_compiler_flag("/arch:AVX2" COMPILER_SUPPORTS_AVX2)
    check_c_compiler_flag("/arch:AVX512" COMPILER_SUPPORTS_AVX512)
    set(AVX2_FLAGS "/arch:AVX2")
    set(AVX512_FLAGS "/arch:AVX512")
else()
    check_c_compiler_flag("-mavx2 -mfma" COMPILER_SUPPORTS_AVX2)
    check_c_compiler_flag("-mavx512f -mfma" COMPILER_SUPPORTS_AVX512)
    set(AVX2_FLAGS "-mavx2 -mfma")
    set(AVX512_FLAGS "-mavx512f -mfma")
endif()

# Default options based on architecture and compiler capability
if(LIBHISTO_ARCH_X86 AND COMPILER_SUPPORTS_AVX2)
    set(_DEFAULT_AVX2 ON)
else()
    set(_DEFAULT_AVX2 OFF)
endif()

if(LIBHISTO_ARCH_X86 AND COMPILER_SUPPORTS_AVX512)
    set(_DEFAULT_AVX512 ON)
else()
    set(_DEFAULT_AVX512 OFF)
endif()

# NEON double precision vector kernels (float64x2_t) are supported on AArch64 / ARM64 and x86 bridge
if(LIBHISTO_ARCH_ARM64 OR LIBHISTO_ARCH_X86)
    set(_DEFAULT_NEON ON)
else()
    set(_DEFAULT_NEON OFF)
endif()

option(LIBHISTO_ENABLE_AVX2 "Enable AVX2 vectorization" ${_DEFAULT_AVX2})
option(LIBHISTO_ENABLE_AVX512 "Enable AVX-512 vectorization" ${_DEFAULT_AVX512})
option(LIBHISTO_ENABLE_NEON "Enable ARM NEON vectorization" ${_DEFAULT_NEON})

if(LIBHISTO_ENABLE_AVX2 AND COMPILER_SUPPORTS_AVX2)
    target_sources(histo PRIVATE simd_avx2.c)
    set_source_files_properties(simd_avx2.c PROPERTIES COMPILE_FLAGS "${AVX2_FLAGS}")
    target_compile_definitions(histo PUBLIC LIBHISTO_ENABLE_AVX2)
endif()

if(LIBHISTO_ENABLE_AVX512 AND COMPILER_SUPPORTS_AVX512)
    target_sources(histo PRIVATE simd_avx512.c)
    set_source_files_properties(simd_avx512.c PROPERTIES COMPILE_FLAGS "${AVX512_FLAGS}")
    target_compile_definitions(histo PUBLIC LIBHISTO_ENABLE_AVX512)
endif()

if(LIBHISTO_ENABLE_NEON)
    target_sources(histo PRIVATE simd_neon.c)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64" OR CMAKE_C_COMPILER_ID MATCHES "ARM")
        # Native ARM64 (NEON double-precision float64x2_t is standard on AArch64)
    elseif(LIBHISTO_ARCH_X86)
        if(NOT MSVC)
            set_source_files_properties(simd_neon.c PROPERTIES COMPILE_FLAGS "-msse4.1")
        endif()
    endif()
    target_compile_definitions(histo PUBLIC LIBHISTO_ENABLE_NEON)
endif()

target_link_libraries(histo
    PUBLIC
        $<BUILD_INTERFACE:histo_compiler_flags>
)




if(UNIX AND NOT APPLE)
    target_link_libraries(histo PUBLIC m)
endif()

target_include_directories(histo
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/vendor/cJSON
)

install(TARGETS histo
    EXPORT libhistoTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

