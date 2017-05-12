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
*
*  AMaMP: http://amamp.sourceforge.net/
*  ************************************************************************ */


    /* One code to bring the core! And to the Perl language.....bind it!
	   J.R.R. Tolkien                                                  */


#if defined(WIN32)
#define AMAMP_BINDING_WIN32 1
#include <windows.h>
#include <winbase.h>
#else
#include <fcntl.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "amamp_binding.h"

#if AMAMP_BINDING_WIN32 == 1
struct _amamp_binding_win32core {
	HANDLE coreReadPipe;
	HANDLE coreWritePipe;
};
# else
struct _amamp_binding_posixcore {
	int pid;
	int coreReadPipe;
	int coreWritePipe;
};
#endif


/* Define internal stuff here so we can use it throughout the public stuff. */
char* _amampExtractLine(char *buffer, int n);
char* _amampStrip0x13(char *buffer);


/* startCore invokes the AMaMP core executable with the given instruction
 * file, at the same time initialising an appropriate AMAMP_CORE structure. */
AMAMP_CORE* amampStartCore(char *corePath, char *instructionFile)
{
	/* Allocate an AMAMP_CORE structure. */
	AMAMP_CORE *core = malloc(sizeof(AMAMP_CORE));
	if (core == NULL)
		return NULL;

	/* We have to do things completely differently depending on whether
	   we're in Win32 or a POSIX-y place. Then, what's new? :-)  */
#if AMAMP_BINDING_WIN32 == 1
	/* Win32. if(1) hack so I can declare some variables inside here. */
	if (1) {
		/* Create some working variables/structures. */
		HANDLE coreRead, localWrite, coreWrite, localRead;
		SECURITY_ATTRIBUTES sa;
		STARTUPINFO startInfo;
		PROCESS_INFORMATION procInfo;
		BOOL retVal;
		struct _amamp_binding_win32core *handle = malloc(sizeof(struct _amamp_binding_win32core));
		char *commandLine;
		int commandLength;

		/* Set up security attributes. */
		sa.nLength = sizeof(SECURITY_ATTRIBUTES);
		sa.lpSecurityDescriptor = NULL;
		sa.bInheritHandle = TRUE;

		/* Create pipes. */
		retVal = CreatePipe(&coreRead, &localWrite, &sa, 0);
		if (retVal == 0) {
			free(core);
			return NULL;
		}
		retVal = CreatePipe(&localRead, &coreWrite, &sa, 0);
		if (retVal == 0) {
			free(core);
			return NULL;
		}

		/* Set stuff up to run the core. */
		memset(&startInfo, 0, sizeof(STARTUPINFO));
		startInfo.cb = sizeof(STARTUPINFO);
		startInfo.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
		startInfo.wShowWindow = SW_HIDE;
		startInfo.hStdOutput = coreWrite;
		startInfo.hStdError = coreWrite;
		startInfo.hStdInput = coreRead;

		/* Prepare the command line. */
		commandLength = strlen(corePath) + strlen(instructionFile) + 6;
		commandLine = malloc(commandLength);
		memset(commandLine, 0, commandLength);
		*commandLine = '"';
		strcpy(commandLine + 1, corePath);
		strcpy(commandLine + strlen(corePath) + 1, "\" \"");
		strcpy(commandLine + strlen(corePath) + 4, instructionFile);
		strcpy(commandLine + commandLength - 2, "\"");

		/* Attempt to invoke the core. */
		retVal = CreateProcess(NULL, commandLine, &sa, &sa, TRUE, NORMAL_PRIORITY_CLASS, NULL, NULL, &startInfo, &procInfo);
		if (retVal == 0) {
			free(core);
			return NULL;
		}

		/* Close our copy of the core's handles. */
		CloseHandle(coreRead);
		CloseHandle(coreWrite);

		/* Stash our info. */
		handle->coreReadPipe = localRead;
		handle->coreWritePipe = localWrite;
		core->handle = handle;
	}
#else
	/* Standard popen stuff. if(1) hack so I can declare some variables inside here. */
	if (1) {
		/* Declare a few variables. */
		int retVal = 0;
		int pipeToCore[2];
		int pipeFromCore[2];
		int pid;
		struct _amamp_binding_posixcore *handle;

		/* Use pipe system call to create a couple of pipes. */
		retVal = pipe(pipeToCore);
		if (retVal != 0)
		{
			free(core);
			return NULL;
		}
		retVal = pipe(pipeFromCore);
		if (retVal != 0)
		{
			free(core);
			return NULL;
		}

		/* Now attempt to spawn the core. */
		pid = fork();
		if (pid == -1)
		{
			free(core);
			return NULL;
		}
		if (pid == 0)
		{
			/* This is the spawned child. Set file handles and transfer control. */
			char *argv[3];
			argv[0] = corePath;
			argv[1] = instructionFile;
			argv[2] = NULL;
			dup2(pipeToCore[0], fileno(stdin));
			dup2(pipeFromCore[1], fileno(stdout));
			retVal = execve(corePath, argv, NULL);
			if (retVal == -1)
			{
				/* Send message back to parent and exit. */
				printf("error:\n\tmodule: parser\n\tmessage: Instruction file not found\n\n");
				fflush(stdout);
				exit(1);
			}
		}

		/* If we reach here, this is the parent process. Stash handles. */
		handle = malloc(sizeof(struct _amamp_binding_posixcore));
		handle->pid = pid;
		handle->coreReadPipe = pipeFromCore[0];
		handle->coreWritePipe = pipeToCore[1];
		core->handle = handle;
	}
#endif

	/* Create empty message buffer. */
	core->messageBuffer = malloc(1);
	if (core->messageBuffer == NULL) {
		amampFreeCore(core);
		return NULL;
	}
	*(core->messageBuffer) = 0;
	core->coreAlive = 1;

	/* Return core structure. */
	return core;
}


/* sendRawMessage takes a message as a string and sends it to the core.     */
int amampSendRawMessage(AMAMP_CORE *core, char *rawMessage)
{
	/* Check we actually have a message and a core structure. */
	if (core == NULL || rawMessage == NULL)
		return 0;

	/* Now we have to jump into platform specific stuff. */
#if AMAMP_BINDING_WIN32 == 1
	/* Win32. Call WriteFile to send the mesage. */
	if (1) {
		struct _amamp_binding_win32core *handle = core->handle;
		int bytesWritten;
		if (WriteFile(handle->coreWritePipe, rawMessage, strlen(rawMessage), &bytesWritten, NULL) == 0)
		{
			/* If it fails, the core has most likely terminated. */
			core->coreAlive = 0;
			return 0;
		}
	}
#else
	/* POSIX.  Use write system call. */
	if (1) {
		struct _amamp_binding_posixcore *handle = core->handle;
		if (write(handle->coreWritePipe, rawMessage, strlen(rawMessage)) == -1)
		{
			/* If it fails, the core has most likely terminated. */
			core->coreAlive = 0;
			return 0;
		}
	}
#endif

	/* If we get here, things worked out so return success. */
	return 1;
}


/* getRawMessage gets the latest message from the AMaMP core, It returns
 * null if there is no message, or the message as a char * if there is one. */
char* amampGetRawMessage(AMAMP_CORE *core, int block)
{
	/* Declare any variables. */
	int completeMessage = 0;
	int noMessage = 0;
	char *message = NULL;
	int line = 0;
	int haveMessageAvailable = 0;

	/* If we are blocking, do a check to see if there are any more
	   messages available in the queue. */
	if (block != 0)
	{
		char *curChar = core->messageBuffer;
		while (haveMessageAvailable == 0 && *curChar != 0)
		{
			if (*curChar == '\n' && *(curChar + 1) == '\n')
			{
				haveMessageAvailable = 1;
			}
		}
	}

	/* Do the native stuff to grab anything from the pipe into our buffer. */
#if AMAMP_BINDING_WIN32 == 1
	/* Win32. I'm really starting to hate the if(1) hack now. */
	if (1) {
		/* Get us some working variables. */
		struct _amamp_binding_win32core *handle = core->handle;
		int bytesRead = 0;
		int bytesAvailable = 0;
		int bytesRemaining = 0;
		int retVal;
		char test[1];

		/* See if there is any data to read. */
		retVal = PeekNamedPipe(handle->coreReadPipe, &test[0], 1, &bytesRead, &bytesAvailable, &bytesRemaining);
		if ((retVal != 0 && bytesAvailable != 0) || (block != 0 && haveMessageAvailable == 0))
		{
			/* There's stuff to read. Add it to internal buffer. */
			int curLen = strlen(core->messageBuffer);
			int newLen = curLen + (bytesAvailable != 0 ? bytesAvailable : 32768) + 1;
			char *newBuffer = realloc(core->messageBuffer, newLen);
			if (newBuffer == NULL)
				return NULL;
			retVal = ReadFile(handle->coreReadPipe, newBuffer + curLen, (bytesAvailable != 0 ? bytesAvailable : 32768), &bytesRead, NULL);
			*(newBuffer + curLen + bytesRead) = 0;
			_amampStrip0x13(newBuffer + curLen); /* Strip \r's. */
			core->messageBuffer = newBuffer;
		}
		else if (retVal == 0)
		{
			/* Read error. Broken pipe most likely. */
			core->coreAlive = 0;
		}
	}
#else
	/* POSIX. */
	if (1) {
		/* Deplete the pipe. First declare some variables. */
		struct _amamp_binding_posixcore *handle = core->handle;
		char *tmpBuffer;
		int bytesRead;
		int curLen;
		int newLen;
		char *newBuffer;

		/* Handle blocking settings. */
		if (block == 0 || (block != 0 && haveMessageAvailable == 0))
		{
			/* Turn off blocking. */
			int flags = fcntl(handle->coreReadPipe, F_GETFL, 0);	/* get current file status flags */
			flags |= O_NONBLOCK;						/* set non-blocking flag */
			fcntl(handle->coreReadPipe, F_SETFL, flags);      /* set up non-blocking read */
		}
		else
		{
			/* Turn on blocking. */
			int flags = fcntl(handle->coreReadPipe, F_GETFL, 0);	/* get current file status flags */
			flags &= ~O_NONBLOCK;						/* clear non-blocking flag */
			fcntl(handle->coreReadPipe, F_SETFL, flags);      /* set up non-blocking read */
		}

		/* Grab data from the pipe. Assume there will never be more than 32K in there. */
		tmpBuffer = malloc(32768);
		if (tmpBuffer == NULL)
			return NULL;
		bytesRead = read(handle->coreReadPipe, tmpBuffer, 32768);
		if (bytesRead > 0)
		{
			_amampStrip0x13(tmpBuffer);
			curLen = strlen(core->messageBuffer);
			newLen = curLen + bytesRead + 1;
			newBuffer = realloc(core->messageBuffer, newLen);
			if (newBuffer == NULL)
			{
				free(tmpBuffer);
				return NULL;
			}
			memcpy(newBuffer + curLen, tmpBuffer, bytesRead);
			*(newBuffer + newLen) = 0;
			core->messageBuffer = newBuffer;
		}
		else if (bytesRead < 0)
		{
			/* Broken pipe. */
			core->coreAlive = 0;
		}
		free(tmpBuffer);
	}
#endif

	/* Now we need to get the first message from the pipe. */
	message = malloc(1);
	*message = 0;
	while (completeMessage == 0 && noMessage == 0)
	{
		/* Get the next line. */
		char *lineText = _amampExtractLine(core->messageBuffer, line);

		/* If there is nothing returned, we have an incomplete message. */
		if (lineText == NULL || strlen(lineText) == 0)
		{
			noMessage = 1;
		}
		else
		{
			/* Allocate memory to append this line to the message. */
			int oldMessageLen = strlen(message);
			int newMessageLen = oldMessageLen + strlen(lineText) + 1;
			char *newMessage = realloc(message, newMessageLen);
			if (newMessage != NULL)
			{
				/* Copy the message. */
				strcpy(newMessage + oldMessageLen, lineText);
				message = newMessage;

				/* If it has is just a newline char, then this is the end of the message. */
				if (strcmp(lineText, "\n") == 0)
					completeMessage = 1;
			}
			else
			{
				noMessage = 1;
			}
		}

		/* Free the line we've been working on. */
		if (lineText != NULL)
			free(lineText);
		line++;
	}

	/* See if we have a message to return. */
	if (completeMessage == 1)
	{
		/* Before returning the message, we need to remove it from the buffer. */
		int newBufferLen = 1 + strlen(core->messageBuffer) - strlen(message);
		char *newBuffer = malloc(newBufferLen < 1 ? 1 : newBufferLen);
		memcpy(newBuffer, core->messageBuffer + strlen(message), newBufferLen);
		*(newBuffer + newBufferLen - 1) = 0;	/* To ensure we're null terminated. */
		free(core->messageBuffer);
		core->messageBuffer = newBuffer;

		/* Return it. */
		return message;
	}
	else
	{
		free(message);
		return NULL;
	}
}


/* amampFreeCore takes a core structure and frees all memory associated with it. Note that you
 * need to free any messages seperately.                                                       */
void amampFreeCore(AMAMP_CORE *core)
{
	if (core != NULL)
	{
		/* Free stuff. Here we need to go look at platform stuff. */
#if AMAMP_BINDING_WIN32 == 1
		/* Win32. Close handles, Free structure. */
		struct _amamp_binding_win32core *handle = core->handle;
		CloseHandle(handle->coreReadPipe);
		CloseHandle(handle->coreWritePipe);
		free(handle);
#else
		/* POSIX. pclose to clean up the file handle. */
		struct _amamp_binding_posixcore *handle = core->handle;
		close(handle->coreReadPipe);
		close(handle->coreWritePipe);
		free(handle);
#endif

		/* Free buffer and the core structure itself. */
		if (core->messageBuffer != NULL)
			free(core->messageBuffer);
		free(core);
	}
}


/* Checks if the core is still alive. Returns zero if it is not and a non-zero value
   otherwise. */
int amampIsCoreAlive(AMAMP_CORE *core)
{
	/* If we know it's dead, return 0 right away. */
	if (core == NULL || core->coreAlive == 0)
		return 0;

	/* Otherwise, do something to check it. Go native. */
#if AMAMP_BINDING_WIN32 == 1
	/* Win32. We can simply do a peek pipe operation. */
	if (1) {
		/* Get us some working variables. */
		struct _amamp_binding_win32core *handle = core->handle;
		int bytesRead = 0;
		int bytesAvailable = 0;
		int bytesRemaining = 0;
		int retVal;
		char test[1];

		/* Check return value of peek operation. */
		retVal = PeekNamedPipe(handle->coreReadPipe, &test[0], 1, &bytesRead, &bytesAvailable, &bytesRemaining);
		if (retVal == 0)
			core->coreAlive = 0;
	}
#else
	/* POSIX. We're just going to try doing a read. Of course, if we get anything we
	   will have to put it into the message queue. Hopefully one day I'll find a far
	   eaiser way of doing this bit. */
	if (1)
	{
		/* First declare some variables. */
		struct _amamp_binding_posixcore *handle = core->handle;
		char *tmpBuffer;
		int bytesRead;
		int curLen;
		int newLen;
		char *newBuffer;

		/* Turn off blocking. This check should never block. */
		int flags = fcntl(handle->coreReadPipe, F_GETFL, 0);	/* get current file status flags */
		flags |= O_NONBLOCK;					/* set non-blocking flag */
		fcntl(handle->coreReadPipe, F_SETFL, flags);      /* set up non-blocking read */

		/* Grab data from the pipe. Assume there will never be more than 32K in there. */
		tmpBuffer = malloc(32768);
		if (tmpBuffer == NULL)
			return core->coreAlive;
		bytesRead = read(handle->coreReadPipe, tmpBuffer, 32768);
		if (bytesRead > 0)
		{
			_amampStrip0x13(tmpBuffer);
			curLen = strlen(core->messageBuffer);
			newLen = curLen + bytesRead + 1;
			newBuffer = realloc(core->messageBuffer, newLen);
			if (newBuffer == NULL)
			{
				free(tmpBuffer);
				return core->coreAlive;
			}
			memcpy(newBuffer + curLen, tmpBuffer, bytesRead);
			*(newBuffer + newLen) = 0;
			core->messageBuffer = newBuffer;
		}
		else if (bytesRead < 0)
		{
			/* Broken pipe. */
			core->coreAlive = 0;
		}
		free(tmpBuffer);
	}
#endif

	/* Return status. */
	return core->coreAlive;
}


/* _amampExtractLine extracts the nth line from a buffer. */
char* _amampExtractLine(char *buffer, int n)
{
	/* Set up some variables, including position markers. */
	char *lineStartPos = buffer;
	char *lineEndPos = buffer;
	char *line = NULL;
	int linesSeen = 0;

	/* Loop through, looking for the line we want. */
	while (line == NULL)
	{
		/* See what we've got. */
		if (*lineEndPos == '\n')
		{
			/* We found an end of line. But is it the one we want? */
			if (linesSeen == n)
			{
				/* Yes! Copy it to a new buffer. */
				char *copyPos;
				char *destPos;
				line = malloc(2 + lineEndPos - lineStartPos);
				if (line == NULL)
					return NULL;
				copyPos = lineStartPos;
				destPos = line;
				while (copyPos <= lineEndPos)
				{
					*destPos = *copyPos;
					destPos ++;
					copyPos ++;
				}
				*destPos = 0;
			}
			else
			{
				/* No, but registier the fact we saw it and reset lineStartPos. */
				linesSeen ++;
				lineStartPos = lineEndPos + 1;
			}
		}
		else if (*lineEndPos == 0)
		{
			/* End of string. Break out. */
			break;
		}

		/* Move to next character. */
		lineEndPos ++;
	}

	/* Return line. */
	return line;
}


/* _amampStrip0x13 removes all \r's from a string buffer. */
char* _amampStrip0x13(char *buffer)
{
	/* Simply search through, over-writing \r's with later data. */
	char *copyPos = buffer;
	char *destPos = buffer;
	while(1)
	{
		*destPos = *copyPos;
		if (*destPos == 0)
			break;
		copyPos ++;
		destPos ++;
		if (*copyPos == '\r')
			copyPos ++;
	}
	return buffer;
}

