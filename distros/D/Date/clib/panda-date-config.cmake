if (NOT TARGET panda-date)
    find_package(panda-lib REQUIRED)
    include(${CMAKE_CURRENT_LIST_DIR}/panda-date-targets.cmake)
endif()
