#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "libsecp256k1::secp256k1" for configuration "RelWithDebInfo"
set_property(TARGET libsecp256k1::secp256k1 APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(libsecp256k1::secp256k1 PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib64/libsecp256k1.so.5.0.0"
  IMPORTED_SONAME_RELWITHDEBINFO "libsecp256k1.so.5"
  )

list(APPEND _IMPORT_CHECK_TARGETS libsecp256k1::secp256k1 )
list(APPEND _IMPORT_CHECK_FILES_FOR_libsecp256k1::secp256k1 "${_IMPORT_PREFIX}/lib64/libsecp256k1.so.5.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
