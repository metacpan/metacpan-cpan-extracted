cmake_minimum_required(VERSION 3.10)
project(alien_ngtcp2_picotls C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(OpenSSL 1.1.1 REQUIRED COMPONENTS Crypto)
find_package(Threads REQUIRED)

set(PICOTLS_CORE_SOURCES
    lib/picotls.c
    lib/hpke.c
    lib/pembase64.c
)

if(MSVC)
    list(APPEND PICOTLS_CORE_SOURCES lib/wintimeofday.c)
endif()

add_library(picotls-core STATIC ${PICOTLS_CORE_SOURCES})

target_include_directories(picotls-core
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(picotls-core PUBLIC Threads::Threads)

add_library(picotls-openssl STATIC
    lib/openssl.c
)

target_include_directories(picotls-openssl
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(picotls-openssl
    PUBLIC
        picotls-core
        OpenSSL::Crypto
        ${CMAKE_DL_LIBS}
)

if(WIN32)
    target_include_directories(picotls-core
        PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/lib"
    )
    target_include_directories(picotls-openssl
        PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/lib"
    )
    target_compile_definitions(
        picotls-core
        PRIVATE
            _WINDOWS
    )
    target_compile_definitions(
        picotls-openssl
        PRIVATE
            _WINDOWS
            OPENSSL_NO_ASYNC
    )
endif()

install(
    TARGETS picotls-core picotls-openssl
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

install(
    DIRECTORY include/
    DESTINATION include
)

if(WIN32)
    install(
        FILES lib/wincompat.h
        DESTINATION include
    )
endif()
