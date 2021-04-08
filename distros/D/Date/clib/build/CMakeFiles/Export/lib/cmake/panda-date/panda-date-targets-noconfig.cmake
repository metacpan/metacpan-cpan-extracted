#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "panda-date" for configuration ""
set_property(TARGET panda-date APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(panda-date PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libpanda-date.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS panda-date )
list(APPEND _IMPORT_CHECK_FILES_FOR_panda-date "${_IMPORT_PREFIX}/lib/libpanda-date.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
