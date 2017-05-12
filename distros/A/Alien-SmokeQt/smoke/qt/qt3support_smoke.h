#ifndef QT3SUPPORT_SMOKE_H
#define QT3SUPPORT_SMOKE_H

#include <smoke.h>

// Defined in smokedata.cpp, initialized by init_qt3support_Smoke(), used by all .cpp files
extern "C" SMOKE_EXPORT Smoke* qt3support_Smoke;
extern "C" SMOKE_EXPORT void init_qt3support_Smoke();
extern "C" SMOKE_EXPORT void delete_qt3support_Smoke();

#ifndef QGLOBALSPACE_CLASS
#define QGLOBALSPACE_CLASS
class QGlobalSpace { };
#endif

#endif
