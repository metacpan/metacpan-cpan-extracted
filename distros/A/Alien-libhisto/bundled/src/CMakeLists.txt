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

option(LIBHISTO_ENABLE_AVX2 "Enable AVX2 vectorization" ON)
option(LIBHISTO_ENABLE_AVX512 "Enable AVX-512 vectorization" ON)
option(LIBHISTO_ENABLE_NEON "Enable ARM NEON vectorization" ON)

if(LIBHISTO_ENABLE_AVX2)
    target_sources(histo PRIVATE simd_avx2.c)
    set_source_files_properties(simd_avx2.c PROPERTIES COMPILE_FLAGS "-mavx2 -mfma")
    target_compile_definitions(histo PUBLIC LIBHISTO_ENABLE_AVX2)
endif()

if(LIBHISTO_ENABLE_AVX512)
    target_sources(histo PRIVATE simd_avx512.c)
    set_source_files_properties(simd_avx512.c PROPERTIES COMPILE_FLAGS "-mavx512f -mfma")
    target_compile_definitions(histo PUBLIC LIBHISTO_ENABLE_AVX512)
endif()

if(LIBHISTO_ENABLE_NEON)
    target_sources(histo PRIVATE simd_neon.c)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64" OR CMAKE_C_COMPILER_ID MATCHES "ARM")
        # Native ARM64 (NEON standard)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm" OR CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
        set_source_files_properties(simd_neon.c PROPERTIES COMPILE_FLAGS "-mfpu=neon")
    else()
        set_source_files_properties(simd_neon.c PROPERTIES COMPILE_FLAGS "-msse4.1")
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

