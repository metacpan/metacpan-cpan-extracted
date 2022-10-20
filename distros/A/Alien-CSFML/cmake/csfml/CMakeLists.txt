cmake_minimum_required(VERSION 3.21)
project(CMakeCSFMLProject LANGUAGES CXX)
include(FetchContent)

set(CSFML_VER "2.5.1")

FetchContent_Declare(
    CSFML
    GIT_REPOSITORY https://github.com/SFML/CSFML.git
    #GIT_TAG        "${CSFML_VER}"
)

FetchContent_MakeAvailable(CSFML)

#add_executable(CMakeCSFMLProject src/main.cpp)

#target_link_libraries(CMakeCSFMLProject PRIVATE sfml-graphics)
#target_compile_features(CMakeCSFMLProject PRIVATE cxx_std_17)

#if (WIN32 AND BUILD_SHARED_LIBS)
#    add_custom_command(TARGET CMakeCSFMLProject POST_BUILD
#        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:CMakeCSFMLProject> $<TARGET_FILE_DIR:CMakeCSFMLProject> COMMAND_EXPAND_LISTS)
#endif()

#install(TARGETS CMakeCSFMLProject)
