/*  Last edited: Jan 19 18:10 1996 (mieg) */
#ifndef _ACECLIENT_
#define _ACECLIENT_

/* $Id: aceclient.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#define DEFAULT_PORT 0x20000101

#define ACE_UNRECOGNIZED 100
#define ACE_OUTOFCONTEXT 200
#define ACE_INVALID      300
#define ACE_SYNTAXERROR  400

#define HAVE_ENCORE   -1
#define WANT_ENCORE   -1
#define DROP_ENCORE   -2

struct ace_handle {
	int clientId;
	int magic;
	void *clnt;
};
typedef struct ace_handle ace_handle;

extern ace_handle *openServer(char *host, unsigned long rpc_port, int timeOut);
extern void closeServer(ace_handle *handle);
extern int askServer(ace_handle *handle, char *request, char **answerPtr, int chunkSize) ; 
extern int askServerBinary(ace_handle *handle, char *request, unsigned char **answerPtr, 
			   int *answerLength, int *encorep, int chunkSize) ; 

/* do not write behind this line */
#endif /* _ACECLIENT_ */

