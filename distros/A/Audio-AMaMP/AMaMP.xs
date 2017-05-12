#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include "ppport.h" */  /* Disabled as it caused problems on Win32. */
#include "amamp_binding/amamp_binding.h"


MODULE = Audio::AMaMP		PACKAGE = Audio::AMaMP

AMAMP_CORE *
amampStartCore(corePath, instructionFile)
	char *corePath
	char *instructionFile

int
amampSendRawMessage(core, rawMessage)
	AMAMP_CORE *core
	char *rawMessage

char*
amampGetRawMessage(core, block)
	AMAMP_CORE *core
	int block

int
amampIsCoreAlive(core)
	AMAMP_CORE *core


MODULE = Audio::AMaMP		PACKAGE = AMAMP_COREPtr		PREFIX = amampAC_

void
amampAC_DESTROY(core)
	AMAMP_CORE *core
  CODE:
  	amampFreeCore(core);

