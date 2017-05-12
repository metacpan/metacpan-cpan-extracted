package Archive::Chm;

our $VERSION = '0.06';

use strict;
use warnings;
use diagnostics;
use Inline (
	    C => Config => LIBS => '-lchm', 
	    VERSION => '0.06',
	    NAME => __PACKAGE__,
	    CLEAN_AFTER_BUILD => 0
	   );
use Inline 'C';


1;

=head1 NAME

Archive::Chm - Performs some read-only operations on HTML help (.chm) files. 
Range of operations includes enumerating contents, extracting contents and 
getting information about one certain part of the archive.

The module supersedes Text::Chm written by Domenico Delle Side. The method
get_filelist() and all it's dependencies are taken nearly "as-is" from 
Text::Chm as written by Domenico.

=head1 SYNOPSIS

 my $test = Archive::Chm->new("TestPrj.chm");

 #make the module log it's activity
 $test->set_verbose(1);
 $test->set_logfile("chmfile.log");

 #set the auto-overwrite function to off
 $test->set_overwrite(0);

 #enumerate the contents of the archive
 $test->enum_files("listing.txt", 1);

 #extract all items in a certain directory
 $test->extract_all("./out");

 #extract a single item from the archive
 $item = $test->("/Secret of Monkey Island Solution.html";

 #or just get the length of the item
 $test->get_item_length("/Secret of Monkey Island Solution.html");
 
 #get complete information about the chm archive
 @content = $test->get_filelist();
 foreach (@content) {
	print $_->{title} . "\n" if defined $_->{title};
	print $_->{path} . "\n";
	print $_->{size} . "\n";
 }

 #p.s. There are ways to check for errors, just look up each method and see. :)
 

=head1 DESCRIPTION

L<Archive::Chm> is a module that provides access to Microsoft Compiled HTML Help 
files (chm files). A lot of today's software ships with documentation in .chm 
format. However Microsoft only provides viewing tools for their own OS and the 
company doesn't disclose the format specification.

Unofficial specs can be found at Matthew T. Russotto's site: 
L<http://www.speakeasy.org/~russotto/chm/chmformat.html>

The module is basically a wrapper of Jed Wing's chmlib, a C library that 
provides access to all ITSS archives, though .chm is the only ITSS type 
file in use today. To use this module you need chmlib installed on your system.
You can get it at: L<http://66.93.236.84/~jedwin/projects/chmlib/>

Currently access to .chm files is read-only and this will change over time if 
Jed Wing upgrades his library. Supported operations are getting a listing of the 
contents, extracting one or all items in the archive and retrieving an item's length.


=head1 METHODS

Archive::Chm has various methods, which can be divided into two categories: methods for working with the chm archive and methods that control how the module works (i.e. logging, overwrite).

=cut


=head2 Archive Handling Methods

These are methods to effectively work with the archive. All operations that can be performed on the archive are contained herein.

=cut

	

__DATA__
__C__


#include "chm_lib.h"

#define ALL_FILES (1)
#define BASE_FILES (2)


typedef struct 
{
    char* filename;
    struct chmFile* target;
	int	is_open;
	int	error;
	char* errmsg;
} ChmFile;


struct ChmObjData
{
  char *path;
  char *title;
  size_t size;
  struct ChmObjData *next;
};

struct ChmObjData *data = NULL;



struct extract_context
{
    const char 	*base_path;
};



int _enum_print_ui(struct chmFile *h, struct chmUnitInfo *ui, void *context);
int _enum_get_ui(struct chmFile *h, struct chmUnitInfo *ui, void *context);
int _extract_callback(struct chmFile *h, struct chmUnitInfo *ui, void *context);
static FILE* _set_outfile(FILE *newfile);
static FILE* _set_logfile(char *filename);
static int _rmkdir(char *path);
static int _dir_exists(const char *path);
static int file_is_normal(const char *filename);
static int file_is_html(const char *path);
static struct ChmObjData *chm_data_add(char *path, char *title, size_t size);
static char *get_html_title(SV *obj, const char *filename);
static char *find_title(char *s);

char* set_logfile(char* class, char* filename);
int set_overwrite(char* class, int owr);
int set_verbose(char* class, int verb);
void _set_errmsg(SV* obj, char* msg);
int	err(SV* obj, int error);
char* errmsg(SV* obj);
static char * my_strndup(const char *src, size_t len);



/********************************************************************************
 *																				*
 *		THE PUBLIC INTERFACE FOR THE CHMFILE CLASS										*
 *																				*
 ********************************************************************************/

=head3  new

 $chmobj = Archive::Chm->new($filename)

Constructor of the Archive::Chm class. It only takes the filename as input and opens the target file, checking for errors. The name of the file is also saved.

=cut
SV* new(char* class, char* filename) 
{
    ChmFile* chmfile = malloc(sizeof(ChmFile));
    SV*      obj_ref = newSViv(0);
    SV*      obj = newSVrv(obj_ref, class);

    chmfile->target = chm_open(filename);
    if (!(chmfile->target))
		return NULL;

	chmfile->is_open = 1;
	chmfile->error = 0;
	_set_errmsg("No error whatsoever");
    chmfile->filename = strdup(filename);
        
    sv_setiv(obj, (IV)chmfile);
    SvREADONLY_on(obj);
    return obj_ref;
}


/*-------------------------------------------------------------------------------
// 	 Destructor for the Archive::Chm class. It closes the .chm file and frees
// the space occupied by the filename.
//------------------------------------------------------------------------------*/
void DESTROY(SV* obj)
{
    ChmFile* chmfile = (ChmFile*)SvIV(SvRV(obj));
    free(chmfile->filename);
	if (chmfile->errmsg)
		free(chmfile->errmsg);
	if (chmfile->is_open)
    	chm_close(chmfile->target);
    _set_logfile("stdout");
}


=head3 enum_files

 $chmobj->enum_files($out_file, $mode)

Method for enumerating files in the archive. It takes as its input the
output file (if NULL then stdout) and the mode. There are two modes currently
supported: mode 1 prints all files, including dependencies and mode 2 prints only the base .html files, without their dependencies, like pictures and such.

Return values and meanings are: 0 (All OK!), 1 (file exists, not overwriting due to AUTO_OVERWRITE = 0), 2 (output file cannot be created/overwritten), 3 (unkown error in enumeration API), 4 (unknown mode requested), 5 (no chm archive open).

Note that the method was "successfull" with a return value of 1 as well. The err variable is set to the return value unless that value is 0 or 1.

=cut
int enum_files(SV* obj, char *out_file, int mode)
{
    ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
	FILE*	fout;
    
    //get the "static" data members VERBOSE, AUTO_OVERWRITE and log
    FILE*	log = _set_logfile(NULL);
    int		VERBOSE = set_verbose("Archive::Chm", -1);
    int		AUTO_OVERWRITE = set_overwrite("Archive::Chm", -1);
	
	//if there is no open .chm archive
	if (!(chm->is_open)) 
	{
		chm->error = 5;
		_set_errmsg(obj, "No archive open.");
		return 5;
	}
    //if no output file is specified, just use stdout
    if (!strcmp(out_file,""))
	{
		/*errno = 0;
		register IO*	io = GvIOn(PL_defoutgv);
		PerlIO*	ofp = IoOFP(io);
		PerlIO_printf(ofp, "This is... evolution!");
        fout = PerlIO_exportFILE(ofp, "w");*/
		fout = stdout;
	}
    else 
    {
        //if the file exists and we don't want to overwrite, abort
		if (!AUTO_OVERWRITE && _dir_exists(out_file))
		{
			if (VERBOSE)
				fprintf(log, "%s already exists. Operation aborted.\n\n", out_file);
			return 1;
		}
	
		if ((fout = fopen(out_file, "w")) == NULL)
		{
			char *msg = (char*)malloc(strlen(out_file) + 
								strlen(" could not be opened for writing."));
			chm->error = 2;
			sprintf(msg, "%s could not be opened for writing.", out_file);
			_set_errmsg(obj, msg);
			if (VERBOSE)
				fprintf(log, "Operation failed.\n\n");
			return 2;
		}
    }
    
    if (strcmp(out_file, "") && VERBOSE)
		fprintf(log, "Outputting structure of %s to %s\n", chm->filename, out_file);
    //print the header
    fprintf(fout, " %s:\n\n", chm->filename);
    fprintf(fout, " spc    start   length   name\n");
    fprintf(fout, " ===    =====   ======   ====\n");
    _set_outfile(fout);

    //use the enumerate API to print the contents, according to the chosen mode
    switch (mode)
    {
		case BASE_FILES:
		{
			if (!chm_enumerate_dir(chm->target,"/", CHM_ENUMERATE_ALL, _enum_print_ui, NULL))
			{
				chm->error = 3;
				_set_errmsg(obj, "Error in the enumeration API.");
				fclose(fout);
				if (VERBOSE)
					fprintf(log, "Operation failed.\n\n");
				return 3;
			}
			break;
		}
		case ALL_FILES:
		{
			if (!chm_enumerate(chm->target, CHM_ENUMERATE_ALL, _enum_print_ui, NULL))
			{
				chm->error = 3;
				_set_errmsg(obj, "Error in the enumeration API.");
				fclose(fout);
				if (VERBOSE)
					fprintf(log, "Operation failed.\n\n");
				return 3;
			}
			break;
		}
		default:
		{
			chm->error = 4;
			_set_errmsg(obj, "Uknown mode for enum_files.");
			if (VERBOSE)
				fprintf(log, "Operation failed.\n\n");
			return 4;
		}
    }

    if (strcmp(out_file, ""))
        fclose(fout);
    if (VERBOSE)
		fprintf(log, "Operation succesfull\n\n");
    return 0;
}


=head3 extract_all

 $chmobj->extract_all($out_dir)

Method for extracting all files from the .chm archive to a given directory. It returns 0 when all went well, 1 when there was an unkown error in enumeration API and 2 when there is no open archive. The err value is set to the return value unless all went well.

=cut
int extract_all(SV* obj, char *out_dir)
{
    ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
    struct 	extract_context ec;
    
    //get the "static" data members VERBOSE and log
    FILE*	log = _set_logfile(NULL);
    int		VERBOSE = set_verbose("Archive::Chm", -1);

	if (!(chm->is_open))
	{
		chm->error = 2;
		_set_errmsg(obj, "No archive open.");
		return 2;
	}		

    if (VERBOSE)
		fprintf(log, "Extracting contents of %s to %s\n", chm->filename, out_dir);
    ec.base_path = out_dir;
    if (!chm_enumerate(chm->target, CHM_ENUMERATE_ALL, _extract_callback, (void *)&ec))
    {
		if (VERBOSE)
			fprintf(log, "Operation failed\n\n");
		chm->error = 1;
		_set_errmsg(obj, "Error in enumeration API.");
		return 1;
    }

    if (VERBOSE)
		fprintf(log, "Operation succesfull\n\n");
    return 0;
}


=head3 extract_item

 $html = $chmobj->extract_item($item_path)

Method for retrieving an item, transmitted by it's relative path from the
.chm archive's root. It returns a string with the file's contents. If there
was an error, returns NULL and sets the error flag and message.

=cut 
unsigned char* extract_item(SV* obj, char *item_name)
{
    ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
    struct 	chmUnitInfo ui;

    //get the "static" data members VERBOSE, AUTO_OVERWRITE and log
    FILE*	log = _set_logfile(NULL);
    int		VERBOSE = set_verbose("Archive::Chm", -1);
    int		AUTO_OVERWRITE = set_overwrite("Archive::Chm", -1);
    
    if (!(chm->is_open))
	{
		chm->error = 1;
		_set_errmsg(obj, "No archive open.");
		return NULL;
	}
    //resolve the given item
    if (VERBOSE)
		fprintf(log, "Resolving %s...", item_name);
    if (CHM_RESOLVE_SUCCESS == chm_resolve_object(chm->target, item_name, &ui))
    {
		#ifdef WIN32
			unsigned char *buffer = (unsigned char *)alloca((unsigned int)ui.length);
		#else
			unsigned char buffer[ui.length];
		#endif
		LONGINT64	gotLen;
		
		//object succesfully resolved, so print info about it
		if (VERBOSE)
			fprintf(log, " object <space=%d, start=%lu, length=%lu>\n", ui.space, 
			(unsigned long)ui.start, (unsigned long)ui.length);
		gotLen = chm_retrieve_object(chm->target, &ui, buffer, 0, ui.length);
	
		if (gotLen == 0)
		{
			chm->error = 3;
			_set_errmsg(obj, "Extract failed.");
			if (VERBOSE)
				fprintf(log, "Operation failed\n\n");
			return NULL;
		}
		else
		{
			if (VERBOSE)
				fprintf(log, "Operation succesfull\n\n");
			return (unsigned char*)strdup((char*) buffer);
		}
    }
    //if the resolve failed say so
    else
    {
		chm->error = 2;
		_set_errmsg(obj, "Could not resolve item.");
		if (VERBOSE)
	    	fprintf(log, "failed\n\n");
		return NULL;
    }
}


=head3 get_filelist

 @contents = $chmobj->get_filelist()

Metod for getting a list of hash references for all elements of the
archive. Each hash has a maximum of 3 keys, "title", "path" and "size".
They are self-explanatory.

=cut
void get_filelist(SV* obj)
{
	struct ChmObjData* contents = NULL;
	ChmFile* chm = (ChmFile*)SvIV(SvRV(obj));
	HV* hash;
	int i = 0;

	contents = chm_data_add("start", "start", 0);
	data = contents;

	if (!chm_enumerate(chm->target, CHM_ENUMERATE_ALL, _enum_get_ui, obj))
    	croak("Errors getting filelist\n");

	data = contents->next;
	Inline_Stack_Vars;
	Inline_Stack_Reset;
	while (data)
	{
		SV* refr;
		hash = newHV();
		hv_store(hash, "path", 4, newSVpv(data->path, strlen(data->path)), 0);
		hv_store(hash, "size", 4, newSViv(data->size), 0);
		if (data->title)
			hv_store(hash, "title", 5, newSVpv(data->title, strlen(data->title)), 0);
		else
			hv_store(hash, "title", 5, newSV(0), 0);

		Inline_Stack_Push(sv_2mortal(newRV((SV*) hash)));
		data = data->next; i++;
	}
	Inline_Stack_Done;
}



=head3 get_item_length

 $length = $chmobj->get_item_length($item_path)

Method for getting a certain item's length. The item is transmitted by it's
relative path from the archive's root. The return value is 0 and the error variable set to 1 if the item could not be resolved, otherwise the return value is the actual length of the item.

=cut
unsigned long get_item_length(SV* obj, char *item_name)
{
    ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
    struct 	chmUnitInfo ui;
    
    //get the "static" data members VERBOSE, AUTO_OVERWRITE and log
    FILE*	log = _set_logfile(NULL);
    int		VERBOSE = set_verbose("Archive::Chm", -1);
    int		AUTO_OVERWRITE = set_overwrite("Archive::Chm", -1);


	if (!(chm->is_open))
	{
		chm->error = 2;
		_set_errmsg(obj, "No archive open.");
		return 2;
	}
    //resolve the given item
    if (VERBOSE)
		fprintf(log, "Resolving %s...", item_name);
    if (CHM_RESOLVE_SUCCESS == chm_resolve_object(chm->target, item_name, &ui))
    {
    	//object succesfully resolved, so print info about it
		if (VERBOSE)
	    	fprintf(log, " object <space=%d, start=%lu, length=%lu>\n", ui.space, 
			(unsigned long)ui.start, (unsigned long)ui.length);
	
		return (unsigned long)ui.length;
    }
    //if the resolve failed say so
    else
    {
		chm->error = 1;
		_set_errmsg(obj, "Could not resolve item.");
		if (VERBOSE)
    	    fprintf(log, "failed\n\n");
		return 0;
    }
}


=head3 get_name

 $filename = $chmobj->get_name()

Method for getting the filename of the attached .chm file.

=cut
char* get_name(SV* obj)
{
    ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
    char 		*ret = strdup(chm->filename);

    return ret;
}


=head3 close_file

 $chmobj->close_file();

Sometimes you may want to close the associated .chm file while letting
the Archive::Chm object live on. If you do so, you'll need to open it again
by using open_file.

=cut
void close_file(SV* obj)
{
    ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
	if (chm->is_open)
	{
		chm_close(chm->target);
		chm->is_open = 0;
		if (set_verbose("Archive::Chm", -1))
			fprintf(_set_logfile(NULL), "Closed %s\n\n", get_name(obj));
	}
}


=head3 open_file

 $chmobj->open_file();

While the file is automatically opened at object creation, if you close
it during the object's lifetime, you will need to reopen it using this
method. Returns 0 on success, 1 on error.

=cut
int open_file(SV* obj)
{
	ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
	if (!(chm->is_open))
	{
		chm->target = chm_open(chm->filename);
		if (!(chm->target))
		{
			chm->error = 1;
			_set_errmsg(obj, "Could not open target archive.");
			return 1;
		}
		chm->is_open = 1;
		if (set_verbose("Archive::Chm", -1))
			fprintf(_set_logfile(NULL), "Opened %s\n\n", get_name(obj));
	}
	return 0;
}


=head2 Control Methods

Methods for module control. It should be noted that the error flag is never reset by the module and should be manually reset after it has been checked. Archive::Chm only sets the error flag when an error occurs.

=cut


=head3 err

 $chmobj->err($code);

Gets the current error code if $code = -1, otherwise sets it to $code.

=cut
int err(SV* obj, int error)
{
	ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
	if (error != -1)
		chm->error = error;
	return chm->error;
}


=head3 errmsg

 $chmobj->errmsg();

Gets the string containing the error message corresponding to the last error encountered.

=cut
char* errmsg(SV* obj)
{
	ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
	return chm->errmsg;
}




/********************************************************************************
 *																				*
 *		SIMULATED STATIC MEMBERS WITH GETTERS/SETTERS										*
 *																				*
 ********************************************************************************/

/*-------------------------------------------------------------------------------
// 	 Function used to encapsulate the "global" outfile needed for the extract-
// callback function. It can set the outfile or get it (if the parameter is NULL).
// This function is needed so that we don't make outfile global and cause problems
// with multithreading (i.e. polluting the namespace).
//------------------------------------------------------------------------------*/
static FILE* _set_outfile(FILE *newfile)
{
    static FILE* out = NULL;
    
    if (newfile)
		out = newfile;
    return out;
}


/*-------------------------------------------------------------------------------
//	Another function similar to _set_outfile. This one is used to get/set the
// log file used to output the result of operations.
//------------------------------------------------------------------------------*/
static FILE* _set_logfile(char *filename)
{
    static FILE* log = NULL;

    if (!log)
		log = stdout;

    //if we wanted to set the logfile, do it
    if (filename)
    {
		//if we had another logfile open, close it
		if (log && log != stdout)
			fclose(log);
		//we can set the logging to stdout, also used as a finishing routine
		if (!strcmp(filename, "stdout"))
			return log = stdout;
	    
		//now open the new logfile and if we are verbose, note the change
		if ((log = fopen(filename, "a")) == NULL)
		{
			fprintf(stderr, "Error opening logfile %s.\n", filename);
			fprintf(stderr, "Log is reset to stdout.\n");
			log = stdout;
		}
		else
			if (set_verbose("Archive::Chm", -1))
				fprintf(log, "Succesfully switched to new logfile %s.\n\n", filename);
    }
    
    return log;
}


=head3 set_logfile

 $chmobj->set_logfile($log_filename);
 $log_filename = $chmobj->set_logfile();

Method used to get/set the logfile of the module. Notable that this is actually a static data member and as such common for all the Archive::Chm objects.

=cut
char* set_logfile(char* class, char* filename)
{
    static char* logfile_name = NULL;
    
    //check for proper usage    
    if (strstr(class, "Archive::Chm") != class)
    {
		fprintf(stderr, "Warning! Improper usage of set_logfile.\n");
		fprintf(stderr, "Usage: Archive::Chm->set_logfile(char* logname)\n");
    }
    
    if (strcmp(filename, ""))
    {
		logfile_name = strdup(filename);
		_set_logfile(filename);
    }
    return strdup(logfile_name);
}



=head3 set_overwrite

 $chmobj->set_overwrite($owr);
 $owr = $chmobj->set_overwrite(-1);

Method used to get/set the static AUTO_OVERWRITE flag. Works just 
like the logfile function above, except that getting the flag requires a value 
of -1 to be passed.

=cut
int set_overwrite(char* class, int owr)
{
    static int AUTO_OVERWRITE = 1;
    
    if (strstr(class, "Archive::Chm") != class)
    {
		fprintf(stderr, "Class is: '%s'\n", class);
		fprintf(stderr, "Warning! Improper usage of set_overwrite.\n");
		fprintf(stderr, "Usage: Archive::Chm->set_overwrite(int owr)\n");
    }
    if (owr != -1)
	AUTO_OVERWRITE = owr;
    return AUTO_OVERWRITE;
}


=head3 set_verbose

 $chmobj->set_verbose($verb)
 $verb = $chmobj->set_verbose(-1)

Yet another function to get/set the VERBOSE flag. Works just like
the previous one for AUTO_OVERWRITE.

=cut
int set_verbose(char* class, int verb)
{
    static int VERBOSE = 0;
    
    if (strstr(class, "Archive::Chm") != class)
    {
		fprintf(stderr, "Warning! Improper usage of set_verbose.\n");
		fprintf(stderr, "Usage: Archive::Chm->set_verbose(int verb)\n");
    }
    if (verb != -1)
	VERBOSE = verb;
    return VERBOSE;
}




/********************************************************************************
 *																				*
 *			PRIVATE METHODS AND OTHER FUNCTIONS									*
 *																				*
 ********************************************************************************/


/*-------------------------------------------------------------------------------
//   This function creates a new node for the linked list containing the
// filelist of the chm file.
//------------------------------------------------------------------------------*/
static struct ChmObjData *chm_data_add(char *path, char *title, size_t size)
{
	struct ChmObjData *tmp = NULL;

	tmp = calloc(1, sizeof(struct ChmObjData));
	if (tmp == NULL)
		croak("Out of memory\n");

	tmp->path  = my_strndup(path, strlen(path));
	tmp->title = title;
	tmp->size  = size;
	tmp->next  = NULL;
    
	return tmp;
}


/*-------------------------------------------------------------------------------
//   Check that the file at "path" is an html one, taking this decision
// depending on the extension of the file.
//------------------------------------------------------------------------------*/
static int file_is_html(const char *path)
{
  	char *tmp;

  	if ((int)strlen(path) < 4) /* Path must be at least 5 char long. */
    	return 0;

  	if (NULL != (tmp = strrchr(path, '.')))
		if (0 == strncasecmp(++tmp, "htm", (size_t)3) || 
			0 == strncasecmp(tmp, "html", (size_t)4))
		return 1;

  	return 0;
}


/*-------------------------------------------------------------------------------
// 	 For the moment, we are intrested only on normal files, such as html, css, 
// images, etc... So we limit to look to these.
//------------------------------------------------------------------------------*/
static int file_is_normal(const char *filename)
{  
	if ( '/' == *filename ) /* SPECIAL or NORMAL file */
    {
    	if ( ('#' == *(filename + 1)) || ('$' == *(filename + 1)) ) /* SPECIAL file */
			return 0;
      	else /* NORMAL file */
			return 1;
    }
  	else /* META file */
    	return 0;
}


/*-------------------------------------------------------------------------------
//    Glue-function for getting the title of an html file and returning it.
//------------------------------------------------------------------------------*/
static char *get_html_title(SV *obj, const char *filename)
{
	char *content, *title;
	size_t len;
  
	content = extract_item(obj, filename);
	title = find_title(content);

	return title;
}


/*-------------------------------------------------------------------------------
//    Traverse the content of the string "s", which contains html code,
// to find the text between <title> and </title>, and return it.
//------------------------------------------------------------------------------*/
static char *find_title(char *s)
{
	char *tmp = s;
	size_t len;

	while ( tmp++ )
	{
    	tmp = strchr(tmp, '<');
      
    	if ( 0 == strncasecmp(tmp, "<title>", (size_t)7) )
		{
			tmp += 7;
			len = (size_t) (strchr(tmp, '<') - tmp);
			return my_strndup(tmp, len);
		}
      	else
			continue;
    }
  return NULL;  
}      




/*-------------------------------------------------------------------------------
// 	 Function for use by the enumeration API when used to output the file names
// from the archive.
//------------------------------------------------------------------------------*/
int _enum_print_ui(struct chmFile *h, struct chmUnitInfo *ui, void *context)
{
    fprintf(_set_outfile(NULL), "   %1d %8d %8d   %s\n",
           (int)ui->space,
           (int)ui->start,
           (int)ui->length,
           ui->path);

    return CHM_ENUMERATOR_CONTINUE;
}



/*-------------------------------------------------------------------------------
//   Callback function to be passed to chm_enumerate(), in order to build a linked 
// list of ChmObjData structures that contains some informations about the "normal"
// members (html, css, xml and image files) of the chm file.
//------------------------------------------------------------------------------*/
int _enum_get_ui(struct chmFile *h, struct chmUnitInfo *ui, void *context)
{
	char *title;
	struct ChmObjData *tmp;
	SV* chm = (SV*) context;
	
	if (file_is_normal(ui->path))
	{
		title = ((file_is_html(ui->path)) ? get_html_title(chm, ui->path) : NULL);
		tmp = chm_data_add(ui->path, title, ui->length);
		
		data->next = tmp;
		data = data->next;    
		tmp = NULL;
	}
	
	return CHM_ENUMERATOR_CONTINUE;
}


/*-------------------------------------------------------------------------------
// 	 Function for use by the enumeration API when used to extract all files from
// the archive.
//------------------------------------------------------------------------------*/
int _extract_callback(struct chmFile *h, struct chmUnitInfo *ui, void *context)
{
    unsigned char buffer[32768];
    struct extract_context *ctx = (struct extract_context *)context;
    char *i;

    if (ui->path[0] != '/')
        return CHM_ENUMERATOR_CONTINUE;

    if (snprintf((char*)buffer, sizeof(buffer), "%s%s", ctx->base_path, ui->path) > 1024)
        return CHM_ENUMERATOR_FAILURE;

    if (ui->length != 0)
    {
        FILE *fout;
        LONGINT64 len, remain=ui->length;
        LONGUINT64 offset = 0;

		if (set_verbose("Archive::Chm", -1))
			fprintf(_set_logfile(NULL), "--> %s\n", ui->path);
		if ((fout = fopen((const char*)buffer, "wb")) == NULL)
		{
			/* make sure that it isn't just a missing directory before we abort */ 
			unsigned char newbuf[32768];
			strcpy((char*)newbuf, (const char*)buffer);
			i = rindex((const char*)newbuf, '/');
			*i = '\0';
			_rmkdir((char*)newbuf);
			if ((fout = fopen((const char*)buffer, "wb")) == NULL)
				return CHM_ENUMERATOR_FAILURE;
		}

        while (remain != 0)
        {
            len = chm_retrieve_object(h, ui, buffer, offset, 32768);
            if (len > 0)
            {
                fwrite(buffer, 1, (size_t)len, fout);
                offset += len;
                remain -= len;
            }
            else
            {
                fprintf(stderr, "incomplete file: %s\n", ui->path);
                break;
            }
        }

        fclose(fout);
    }
    else
    {
        if (_rmkdir((char*)buffer) == -1)
            return CHM_ENUMERATOR_FAILURE;
    }

    return CHM_ENUMERATOR_CONTINUE;
}


/*-------------------------------------------------------------------------------
// 	 Function that checks if the file/directory given as an argument exists.
//------------------------------------------------------------------------------*/
static int _dir_exists(const char *path)
{
    struct stat statbuf;
    if (stat(path, &statbuf) != -1)
    	return 1;
    else
    	return 0;
}


/*-------------------------------------------------------------------------------
// 	 Function to make a given directory for use when extracting to a path.
//------------------------------------------------------------------------------*/
static int _rmkdir(char *path)
{
    //strip off trailing components unless we can stat the directory, or we
    //have run out of components

    char *i = rindex(path, '/');

    if(path[0] == '\0'  ||  _dir_exists(path))
        return 0;

    if (i != NULL)
    {
        *i = '\0';
        _rmkdir(path);
        *i = '/';
        mkdir(path, 0777);
    }

#ifdef WIN32
    return 0;
#else
    if (_dir_exists(path))
        return 0;
    else
        return -1;
#endif
}


/*-------------------------------------------------------------------------------
//	Function to set the error message associated with the Archive::Chm object.
//------------------------------------------------------------------------------*/
void _set_errmsg(SV* obj, char* msg)
{
	ChmFile*	chm = (ChmFile*)SvIV(SvRV(obj));
	if (chm->errmsg)
		free(chm->errmsg);
	chm->errmsg = strdup(msg);
}


/*-------------------------------------------------------------------------------
//  Get rid of faulty strndup implementations...
//------------------------------------------------------------------------------*/
static char * my_strndup(const char *src, size_t len)
{
	char *ret = NULL;

	ret = calloc(len + (size_t)1, sizeof(char));
	if ( !ret )
		croak("Out of memory\n");
	strncpy(ret, src, len);
	*(ret + (int)len) = '\0';
	return ret;
}

	


=head1 See Also

ChmLIB: http://66.93.236.84/~jedwin/projects/chmlib/

HMTL Help specs: http://www.speakeasy.org/~russotto/chm/chmformat.html

Domenico Delle Side's module, Text::Chm. It is simpler than  Archive::Chm, 
but still offers good support for HTML Help archives, including the very
useful get_filelist() method.

=cut

=head1 Author

Alexandru Palade <apalade@netsoft.ro>, Netsoft S.R.L.

The Text::Chm functions are the work of Domenico Delle Side <dds@gnulinux.it>

=cut

=head1 Copyright

Copyright (C) 2005 Alexandru Palade, Netsoft S.R.L.

All rights reserved.

=cut