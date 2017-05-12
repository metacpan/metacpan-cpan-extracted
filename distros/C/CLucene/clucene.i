%module "CLuceneWrap"
%{
#include "clucene_dllp.h"
%}


// our definitions for CLucene variables and functions
%include "clucene_perl.h"
//%include "clucene_dll.h" // could use this but then would need to call CL_N_Search not CL_SEARCH etc.

%include typemaps.i

%include argv.i

// helper functions where pointers to result buffers are expected
// would be better done with a %typemap(out) if I knew enough about perlguts

%inline %{

int val_len;
char * val;

int CL_GetField1(int resource, char * field)
{
	return CL_GETFIELD(resource,field,&val,&val_len);
}

char errstr[256];

char * CL_ErrStr1(int resource)
{
	errstr[0] = '\0';
	CL_ERRSTR(resource, errstr, (sizeof errstr)-1);
	return errstr;
}

char * CL_ErrStrGlobal1()
{
	errstr[0] = '\0';
	CL_ERRSTRGLOBAL(errstr, (sizeof errstr)-1);
	return errstr;
}

char docinfobuf[2048];

char * CL_Document_Info1(int resource)
{
	CL_DOCUMENT_INFO(resource, docinfobuf, (sizeof docinfobuf)-1);
	return docinfobuf;
}

char searchinfobuf[2048];

char * CL_Search_Info1(int resource)
{
	CL_SEARCHINFO(resource, searchinfobuf, (sizeof searchinfobuf)-1);
	return searchinfobuf;
}

int CL_SearchMultiFieldsFlagged1(int resource, char * query, char ** fields, const int num_fields, char * flags)
{
	return CL_SEARCHMULTIFIELDSFLAGGED(resource,query,(const char **)fields,num_fields,(const unsigned char *)flags);
}

#ifdef HIGHLIGHTING
char highlightbuf[50000];

char * CL_Highlight1(int resource, char * text, int text_is_filename)
{
	CL_HIGHLIGHT(resource, text, text_is_filename, highlightbuf, (sizeof highlightbuf)-1);
	return highlightbuf;
}

char * CL_Highlight_X1(int resource, char * text, int text_is_filename, char * separator, int max_fragments, int fragment_size, int type, char * html_start, char * html_end)
{
	CL_HIGHLIGHT_X(resource, text, text_is_filename, highlightbuf, (sizeof highlightbuf)-1, separator, max_fragments, fragment_size, type, html_start, html_end);
	return highlightbuf;
}
#endif

%}
