add_definitions(-DSMOKE_BUILDING)

include_directories(${CMAKE_SOURCE_DIR}/smoke/qt ${CMAKE_SOURCE_DIR}/generator)

add_subdirectory(qtcore)
macro_optional_add_bindings(QT_QTNETWORK_FOUND "QtNetwork" qtnetwork)
macro_optional_add_bindings(QT_QTDBUS_FOUND "QtDBus" qtdbus)
macro_optional_add_bindings(QT_QTDECLARATIVE_FOUND "QtDeclarative" qtdeclarative)
macro_optional_add_bindings(QT_QTGUI_FOUND "QtGui" qtgui)
macro_optional_add_bindings(QT_QTSVG_FOUND "QtSvg" qtsvg)
macro_optional_add_bindings(QT_QTSQL_FOUND "QtSql" qtsql)
macro_optional_add_bindings(QT_QTXML_FOUND "QtXml" qtxml)
macro_optional_add_bindings(QT_QTXMLPATTERNS_FOUND "QtXmlPatterns" qtxmlpatterns)
macro_optional_add_bindings(QT_QTOPENGL_FOUND "QtOpenGL" qtopengl)
macro_optional_add_bindings(QT_QTWEBKIT_FOUND "QtWebKit" qtwebkit)
macro_optional_add_bindings(QT_QTSCRIPT_FOUND "QtScript" qtscript)
macro_optional_add_bindings(QT_QTUITOOLS_FOUND "QtUiTools" qtuitools)
macro_optional_add_bindings(QT_QTTEST_FOUND "QtTest" qttest)
macro_optional_add_bindings(QT_QTMULTIMEDIA_FOUND "QtMultimedia" qtmultimedia)
macro_optional_add_bindings(QT_QT3SUPPORT_FOUND "Qt3Support" qt3support)
macro_optional_add_bindings(QT_QTHELP_FOUND "QtHelp" qthelp)

macro_optional_add_bindings(PHONON_FOUND "Phonon" phonon)

macro_optional_add_bindings(QSCINTILLA_FOUND "QScintilla" qsci)

macro_optional_add_bindings(Qwt5_Qt4_FOUND "Qwt" qwt)

macro_optional_add_bindings(QIMAGEBLITZ_FOUND "QImageBlitz" qimageblitz)

# for qtguess.pl
if (APPLE)
set(qt_test_threshold 15)
else (APPLE)
set(qt_test_threshold 10)
endif (APPLE)

macro_display_bindings_log()
