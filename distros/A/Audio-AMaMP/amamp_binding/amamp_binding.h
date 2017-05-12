/* ************************************************************************
*  AMaMP
*  Copyright Jonathan Worthington 2004
*  ************************************************************************
*  This file was written as part of the AMaMP project. It provides a Perl
*  binding for the AMaMP core.  While the AMaMP core is released under the
*  GNU/GPL license, this binding may be used in any any program distributed
*  in source and/or binary from so long as:-
*
*    1) This notice is maintained.
*    2) Usage of the core executable and its source is in compliance with
*       the GNU/GPL license.
*    3) You accept that this code is provided AS IS and without warranty.
*       You agree that the author(s) of this code cannot be held liable
*       for any loss of any form arising from usage of the code contained
*       in this file.
*  AMaMP: http://amamp.sourceforge.net/
*  ************************************************************************ */

/* Define binding structures. */
typedef struct _amamp_core {
	void *handle;			/* Handle (internal use) */
	char *messageBuffer;		/* Internal message buffer. */
	int coreAlive;			/* Has the core terminated? */
} AMAMP_CORE;

/* Export functions. */
extern AMAMP_CORE* amampStartCore(char *corePath, char *instructionFile);
extern int amampSendRawMessage(AMAMP_CORE *core, char *rawMessage);
extern char* amampGetRawMessage(AMAMP_CORE *core, int block);
extern void amampFreeCore(AMAMP_CORE *core);
extern int amampIsCoreAlive(AMAMP_CORE *core);

