/// \file NeuralNet.cpp
/// \brief defines the entry point for NeuralNetwork.dll
/// 
/// \author Kyle Schlansker
/// \date August 2004
///////////////////////////////////////////////////////////

#include "NeuralNet.h"

#ifdef WIN32

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
					 )
{
    switch (ul_reason_for_call)
	{
		case DLL_PROCESS_ATTACH:
		case DLL_THREAD_ATTACH:
		case DLL_THREAD_DETACH:
		case DLL_PROCESS_DETACH:
			break;
    }
    return TRUE;
}

#endif
