#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if !defined(LIB_SKIN)
#define LIB_SKIN
#include "libskin/skin.h"
#endif

#if !defined(TREE_WALKER)
#define TREE_WALKER
#include "tree_walker.h"
#endif


extern struct tnode * first_node;

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Class::Skin		PACKAGE = Class::Skin		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

void
xs_parse (self, hash_ref, lines) 
        SV* self;
	SV* hash_ref;	
        char *lines;        
    PREINIT:
	HV* vars;
        struct tnode * syntax_tree;
        SV* buffer;
        char log_message[256];
    PPCODE:	
	/* check that the reference we got is a real reference */
	if (!SvROK(hash_ref)) {
	  vars = newHV();
	}
        else if ( SvTYPE( SvRV( hash_ref ) ) != SVt_PVHV) {
          /* send a message to the log file that hash_ref is not a 
	     reference to hash */   
	  sprintf(log_message, 
		  "The second argument is not a hash reference");
	  write_log(self, log_message, 3);
        }
        else {
          /* get the hash out of the reference */
          vars = (HV*)SvRV(hash_ref);
        }
        /* parse the text in lines, and get the syntax tree */
        syntax_tree = parse_skin(lines);

        /* create empty buffer */
        buffer = newSVpvn("", 0);
        /* walk the tree */
/*show_tnode(syntax_tree, 1);*/
        walk_the_tree(self, buffer, syntax_tree, vars);
/*show_tnode(syntax_tree, 5);*/
        /* free the tree */
        free_tnode(syntax_tree);
        EXTEND(SP, 1);
        PUSHs(buffer);



	





