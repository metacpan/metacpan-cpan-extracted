project(kdebindings)

cmake_minimum_required(VERSION 2.6)

add_subdirectory(generator)
add_subdirectory(cmake/modules)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake/modules )

# search packages used by Qt
find_package(Qt4 REQUIRED)
include(MacroOptionalFindPackage)
include(MacroOptionalAddBindings)
include(MacroOptionalAddSubdirectory)
include(MacroLogFeature)

add_definitions (${QT_DEFINITIONS})
include_directories (${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
if(WITH_QT3_SUPPORT)
    add_definitions(-DQT3_SUPPORT)
endif(WITH_QT3_SUPPORT)

macro_optional_find_package(QImageBlitz)
macro_log_feature(QIMAGEBLITZ_FOUND "QImageBlitz" "QImageBlitz library" "http://www.kde.org" FALSE "" "Needed to compile QImageBlitz bindings")

macro_optional_find_package(Qwt5)
macro_log_feature(Qwt5_Qt4_FOUND "Qwt5 for Qt4" "Qwt5 libraries for Qt4" "http://qwt.sourceforge.net" FALSE "" "Needed to compile Qwt5 bindings")

macro_optional_find_package(Phonon)
macro_log_feature(PHONON_FOUND "Phonon" "Phonon multimedia framework" "http://www.kde.org" FALSE "" "Needed to compile Phonon bindings")

macro_optional_find_package(QScintilla)
macro_log_feature(QSCINTILLA_FOUND "QScintilla2" "QScintilla2 libraries" "http://www.riverbankcomputing.co.uk/software/qscintilla/intro" FALSE "" "Needed to compile QScintilla2 bindings")

macro_optional_add_subdirectory(smoke)

install( FILES lib/Alien/SmokeQt.pm DESTINATION ${CMAKE_INSTALL_PREFIX}/../ )

ENABLE_TESTING()
macro_display_feature_log()
