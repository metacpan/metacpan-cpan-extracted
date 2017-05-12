FIND_PACKAGE(QScintilla REQUIRED)

include_directories( ${QT_INCLUDES} ${QSCINTILLA_INCLUDE_DIR} )

########### next target ###############

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/smokedata.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_1.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_2.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_3.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_4.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_5.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_6.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_7.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_8.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_9.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_10.cpp

    COMMAND smokegen
    ARGS -config "${CMAKE_CURRENT_BINARY_DIR}/../qtgui/config.xml" -smokeconfig "${CMAKE_CURRENT_SOURCE_DIR}/smokeconfig.xml"
         -I "${QSCINTILLA_INCLUDE_DIR}" -- ${CMAKE_CURRENT_SOURCE_DIR}/qscintilla2_includes.h
    DEPENDS smokegen generator_smoke WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

macro_add_file_dependencies( ${CMAKE_CURRENT_BINARY_DIR}/smokedata.cpp ${CMAKE_CURRENT_BINARY_DIR}/x_1.cpp )

include_directories (${CMAKE_SOURCE_DIR}/smoke ${CMAKE_SOURCE_DIR}/smoke/qt/qsci )

set(smokeqsci_LIB_SRCS ${CMAKE_CURRENT_BINARY_DIR}/smokedata.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_1.cpp 
	${CMAKE_CURRENT_BINARY_DIR}/x_2.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_3.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_4.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_5.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_6.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_7.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_8.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_9.cpp
	${CMAKE_CURRENT_BINARY_DIR}/x_10.cpp)

IF(CMAKE_CXX_FLAGS MATCHES "-fvisibility")
    ADD_DEFINITIONS(-DGCC_VISIBILITY)
ENDIF(CMAKE_CXX_FLAGS MATCHES "-fvisibility")
add_library(smokeqsci SHARED ${smokeqsci_LIB_SRCS})

target_link_libraries(smokeqsci smokeqtcore smokeqtgui ${QT_QTCORE_LIBRARY} ${QT_QTGUI_LIBRARY} ${QSCINTILLA_LIBRARIES})

set_target_properties(smokeqsci PROPERTIES VERSION 3.0.0 SOVERSION 3 )

install(TARGETS smokeqsci DESTINATION ${CMAKE_INSTALL_PREFIX}/lib${LIB_SUFFIX} )
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/../qsci_smoke.h DESTINATION include/smoke)
