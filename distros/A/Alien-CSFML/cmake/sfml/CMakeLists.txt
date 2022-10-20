cmake_minimum_required(VERSION 3.21)
project(CMakeSFMLProject LANGUAGES CXX)
include(FetchContent)

FetchContent_Declare(
    SFML
    GIT_REPOSITORY  https://github.com/SFML/SFML.git
    GIT_TAG         2.6.x
)

FetchContent_MakeAvailable(SFML)
