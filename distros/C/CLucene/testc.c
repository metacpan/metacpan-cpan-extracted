// testc.c
// C equivalent of clucene_test.pl to verify CLucene library installed and works correctly

#define size_t unsigned int
#define bool	char
#define true	((bool)1)
#define false	((bool)0)
#define NULL	(0)

#include "clucene_dllp.h"

/*

// clucene_perl.h
// declarations for swig to generate perl wrapper

	// Opens a new CLucene directory, returns a resource
long		CL_OPEN (char * path, bool create = false);
	// Closes a CLucene directory
bool		CL_CLOSE (long resource);
	// Optimizes a Clucene directory
bool		CL_OPTIMIZE (long resource);
	// Deletes documents returned from query
long		CL_DELETE (long resource, char * qry, char * fld);
	// Returns the error string
void		CL_ERRSTR (long resource, char * errbuf, long len);
//CL_ERROR
	// Returns the global error string
void		CL_ERRSTRGLOBAL (char *errbuf, long len);
	// Creates a new document
bool		CL_NEW_DOCUMENT (long resource);
	// Adds a field to the current document
bool		CL_ADD_FIELD (long resource, char * fld, char * val, int val_len, 
						int store = 0, int index = 1, int token = 1);
	// Adds a date field to the current document
bool		CL_ADD_DATE (long resource, char * fld, int = 0, int store = 0, int index = 1, int token = 1);
	// Inserts the current document
bool		CL_INSERT_DOCUMENT (long resource);
	// Returns text about document info
void		CL_DOCUMENT_INFO (long resource, char * buf, long len);
	// Search one field
bool		CL_SEARCH (long resource, char * qry, char * fld);
	// Search multiple fields
bool		CL_SEARCHMULTIFIELDS (long resource, char * qry, char *flds[], int num_flds);
	// Search multiple fields and get flags
long		CL_SEARCHMULTIFIELDS_FLAGGED (long resource, char * query, 
					char ** fields, int fieldsLen, char ** flags);
	// Query search info
void		CL_QUERY (long resource, char * qry, int qry_len);
	// Get query string
void		CL_SEARCH_INFO (long resource, char *pl, int len);
	// Get search hits
long		CL_HITCOUNT (long resource);
	// Retrieve next hit
bool		CL_NEXTHIT (long resource);
	// Clear search
void		CL_CLEARSEARCH (long resource);
	// Get field for current hit
bool		CL_GETFIELD (long resource, char * fld, char * val, int * val_len);
	// Get date field for current hit
long		CL_GETDATEFIELD (long resource, char * fld);
	// Deletes the documents returned from the specified query
long		CL_DELETE (long resource, char * qry, char * fld);
	// Unlock directory
long		CL_UNLOCK (const char * path);
	// Add a file field to the current document
long		CL_ADD_FILE (long resource, const char * fld, const char * filename, 
					const int store, const int index, const int token);
	// Cleanup resources
void	CL_CLEANUP();

*/

void fail(char *s)
{
	if ( s == NULL )
	{
		s = "Unknown";
	}
	printf("Fatal Error: %s\n",s);
	exit(1);
}

void ckfail(bool b, char *s)
{
	if ( b == true )
		return;
	fail(s);
}

void ckfailr(bool b, char *s, long resource)
{
	char errmsg[256];
	if ( b == true )
		return;
	CL_ERRSTR(resource, errmsg, 255);
	printf("Error: %s\n", errmsg);
	fail(s);
}

int main(int argc, char **argv)
{
	char *path = "./index";
	long resource;
	bool create = true;
	int rc;
	char errmsg[256];
	char bigbuf[2048];
	long numhit = 0;
	int gothit = 0;

	char * docref = "doc1";
	char * doccnt = "some content"; // "some more content", "content for third document"};
	
	resource = CL_OPEN(path,create);
	if (resource==NULL)
	{
		CL_ERRSTRGLOBAL(errmsg,(sizeof errmsg)-1);
		printf("Error: %s\n", errmsg);
		fail("CL_Open");
	}
	printf("Opened %s\n",path);


	ckfail( CL_NEW_DOCUMENT(resource), "CL_New_Document" );
	ckfailr( CL_ADD_FIELD(resource, "ref", docref, strlen(docref), 1, 1, 1), "CL_Add_Field", resource );
	ckfailr( CL_ADD_FIELD(resource, "cnt", doccnt, strlen(doccnt), 1, 1, 1), "CL_Add_Field", resource );

	CL_DOCUMENT_INFO(resource,bigbuf,(sizeof bigbuf)-1);
	printf("Document to add: %s\n", bigbuf);

	ckfail( CL_INSERT_DOCUMENT(resource), "CL_Insert_Document" );
	printf("Document added\n");


	ckfail( CL_SEARCH(resource, "some", "cnt"), "CL_Search" );
	numhit = CL_HITCOUNT(resource);
	printf("Found %d hits on 'some'\n", numhit);

	gothit = numhit ? 1 : 0;
	while (gothit)
	{
		char * val = NULL;
		size_t val_len = 0;
		
		ckfail( CL_GETFIELD(resource, "ref", &val, &val_len), "CL_GetField" );
		printf ("Document: %s\n", (val ? val : "NULL") );
		gothit = CL_NEXTHIT(resource);
	}

	rc = CL_CLOSE(resource);
	printf("CL_CLOSE returned %d\n",rc);
	exit(0);
}
