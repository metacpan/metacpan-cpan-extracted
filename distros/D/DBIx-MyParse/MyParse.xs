#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "my_parse.h"

#include "assert.h"

MODULE = DBIx::MyParse		PACKAGE = DBIx::MyParse

SV *
init_xs(parser_perl, options_perl, groups_perl)
	SV * parser_perl
	SV * options_perl
	SV * groups_perl
CODE:
	I32 num_options = av_len((AV *) SvRV(options_perl));

	static char *server_groups[255];
	static char *server_options[255];

	server_options[0] = "myparse";
	int i;
	for (i = 0; i <= num_options; i++) {
		server_options[i+1] = (char *) my_parse_get_string( options_perl, i );
	};
	server_options[num_options + 2] = NULL;

	I32 num_groups = av_len((AV *) SvRV(groups_perl));
	int q;
	for (q = 0; q <= num_groups; q++) {
		server_groups[q] = (char *) my_parse_get_string( groups_perl, q );
	};
	server_groups[num_groups + 1] = NULL;

	int ret = my_parse_init(num_options + 2, (char **) server_options, (char **) server_groups);
	RETVAL = newSViv(ret);
OUTPUT:
	RETVAL

SV *
parse_xs(parser_perl, sv_db, sv_query)
	SV * parser_perl
	SV * sv_db
	SV * sv_query
CODE:

	assert(parser_perl);
	assert(sv_query);

	char * query = SvPV_nolen(sv_query);
	char * db = SvPV_nolen(sv_db);
	RETVAL = (SV *) my_parse_outer( (void *) parser_perl, db, query );
OUTPUT:
	RETVAL	

