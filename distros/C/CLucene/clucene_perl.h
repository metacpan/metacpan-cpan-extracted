// clucene_perl.h
// declarations for swig to generate perl wrapper

#ifndef clucene_perl
#define clucene_perl 1

#ifdef __cplusplus
extern "C" {
#endif

#define size_t unsigned int
#define bool	char
#define true	((bool)1)
#define false	((bool)0)
#define NULL	(0)

#include "clucene_dllp.h"



	// Opens a new CLucene directory, returns a resource
int		CL_OPEN (char * path, int create = 1);
	// Closes a CLucene directory
int		CL_CLOSE (int resource);
	// Reloads the resources reader to reflect changes to the index
int		CL_RELOAD (int resource);
	// Optimizes a Clucene index directory
int		CL_OPTIMIZE (int resource);
	// Deletes documents returned from query, returns number deleted or -1 on error
int		CL_DELETE (int resource, const char * qry, const char * fld);
	// Returns the error string
void		CL_ERRSTR (int resource, char * errbuf, int len);
//CL_ERROR
	// Returns the global error string
//void		CL_ERRSTRGLOBAL (char *errbuf, int len);
	// Creates a new document
int		CL_NEW_DOCUMENT (int resource);
	// Adds a field to the current document
int		CL_ADD_FIELD (int resource, char * fld, char * val, int val_len, int store, int index, int token);
	// Adds a date field to the current document
int		CL_ADD_DATE (int resource, char * fld, long time, int store, int index, int token);
	// Add a file field to the current document
int		CL_ADD_FILE (int resource, char * fld, char * filename, int store, int index, int token);
	// Inserts the current document
int		CL_INSERT_DOCUMENT (int resource);
	// Returns text about document info
//void		CL_DOCUMENT_INFO (int resource, char *msg, int len=511);
	// Search one field
int		CL_SEARCH (int resource, char * qry, char * fld);
	// Search multiple fields
int		CL_SEARCHMULTIFIELDS (int resource, char * qry, const char ** flds, const int num_flds);
	// Search multiple fields and get flags
//int		CL_SEARCHMULTIFIELDSFLAGGED (int resource, char * query, char ** fields, const int fieldsLen, const unsigned char * flags);
//OBSOLETE // Query search info
//void		CL_QUERY (int resource, char * qry, int qry_len);
	// Get query string
//void		CL_SEARCH_INFO (int resource, char * pl, int len);
	// Get search hits
int		CL_HITCOUNT (int resource);
	// Retrieve next hit
int		CL_NEXTHIT (int resource);
	// Go to specified hit
int		CL_GOTOHIT (int resource, int hitnum);
	// Get hit score of current search result document
float		CL_HITSCORE (int resource);
	// Clear search
void		CL_CLEARSEARCH (int resource);
	// Get field for current hit
//int		CL_GETFIELD (int resource, char * fld, char ** val, int * val_len);
	// Get date field for current hit
long		CL_GETDATEFIELD (int resource, char * fld);
	// Unlock CLucene index directory
int		CL_UNLOCK (char * path);
	// Cleanup resources
void		CL_CLEANUP();

#endif
