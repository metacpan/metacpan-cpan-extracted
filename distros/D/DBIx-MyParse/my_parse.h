

#define MYPARSE_QUERY_CLASS	"DBIx::MyParse::Query"
#define MYPARSE_ITEM_CLASS	"DBIx::MyParse::Item"

typedef void perl_object;

extern int my_parse_init(int my_argc, char** my_argv, char** my_groups);

extern void * my_parse_outer(perl_object * parser, char * db, char * query);

perl_object * my_parse_bless(perl_object * array_ref, const char * bless);

void * my_parse_create_array ();
void my_parse_free_array (perl_object * array_ref);

void * my_parse_create_string (const char * string, size_t length);

void * my_parse_get_string ( perl_object * array_ref, int index );
void * my_parse_get_array ( perl_object * array_ref, int index );

void * my_parse_set_array ( perl_object * array_ref, int index, void * item_ref, int item_type );

/*
 * If you change those constants, also update the corresponding constants in the .pm files
 */

#define MYPARSE_COMMAND		0
#define MYPARSE_ORIG_COMMAND	1
#define MYPARSE_QUERY_OPTIONS	2
#define MYPARSE_SELECT_ITEMS	3
#define MYPARSE_INSERT_FIELDS	4
#define MYPARSE_UPDATE_FIELDS	5
#define MYPARSE_INSERT_VALUES	6
#define MYPARSE_UPDATE_VALUES	7

#define MYPARSE_TABLES	8
#define MYPARSE_ORDER	9
#define MYPARSE_GROUP	10
#define MYPARSE_WHERE	11
#define MYPARSE_HAVING	12
#define MYPARSE_LIMIT	13
#define MYPARSE_ERROR	14
#define MYPARSE_ERRNO	15
#define MYPARSE_ERRSTR	16
#define MYPARSE_SQLSTATE	17

/* This is only used in multiple-table DELETE */

#define MYPARSE_DELETE_TABLES		18

#define MYPARSE_SAVEPOINT 20

#define MYPARSE_SCHEMA_SELECT	21
#define MYPARSE_WILD		22
#define MYPARSE_VARIABLES	23

#define MYPARSE_ITEM_ITEM_TYPE	0
#define MYPARSE_ITEM_ALIAS	1

#define MYPARSE_ITEM_FUNC_TYPE	2
#define MYPARSE_ITEM_FUNC_NAME	3
#define MYPARSE_ITEM_ARGUMENTS		4

#define MYPARSE_ITEM_VALUE	2
#define MYPARSE_ITEM_CHARSET	3

#define MYPARSE_ITEM_FIELD_NAME	2
#define MYPARSE_ITEM_TABLE_NAME	3
#define MYPARSE_ITEM_DB_NAME	4
#define MYPARSE_ITEM_DIR	5
#define MYPARSE_ITEM_USE_INDEX		6
#define MYPARSE_ITEM_IGNORE_INDEX	7
#define MYPARSE_ITEM_FORCE_INDEX	8

#define MYPARSE_ITEM_INTERVAL		2

#define MYPARSE_ITEM_VAR_TYPE		2
#define MYPARSE_ITEM_VAR_NAME		3
#define MYPARSE_ITEM_VAR_COMPONENT	4

#define MYPARSE_ITEM_SUBSELECT_TYPE	2
#define MYPARSE_ITEM_SUBSELECT_EXPR	3
#define MYPARSE_ITEM_SUBSELECT_COND	4
#define MYPARSE_ITEM_SUBSELECT_QUERY	5


#define MYPARSE_ITEM_JOIN_TYPE		2
#define MYPARSE_ITEM_JOIN_ITEMS		3
#define MYPARSE_ITEM_JOIN_COND		4
#define MYPARSE_ITEM_JOIN_FIELDS	5



#define MYPARSE_LIMIT_SELECT	0
#define MYPARSE_LIMIT_OFFSET	1


#define MYPARSE_ARRAY_APPEND	-1
#define MYPARSE_ARRAY_PREPEND	-2
#define MYPARSE_ARRAY_STRING	0
#define MYPARSE_ARRAY_REF	1
#define MYPARSE_ARRAY_LONG	2
#define MYPARSE_ARRAY_INT	3
#define MYPARSE_ARRAY_SV	4

#define MYPARSE_DB		0
#define MYPARSE_OPTIONS		1
#define MYPARSE_GROUPS		2

