/* 	se.h:	for Empress */

#include <limits.h>		/* se_Prepare(): INT_MAX */

struct _SeRecord
{
	char		attr_name [33];
	char		table_name [33];
	int		attr_type;
	int		index;	
	int		nullable;
	int		is_money;
	int		is_updatable;
	int		is_signed;
	long		precision;
	int		scale;
	int		display_size;	
	long		maxlen;
	long		maxchunk;
	long		length;
	void*		binhandle;	/* used with DSQL only */	
	unsigned char*	value;
	struct	_SeRecord*	next;
};
typedef	struct	_SeRecord SeRecord;

typedef	int	se_return;
typedef	int	se_boolean;

#define	SE_FAIL		(se_return)0
#define	SE_OK		(se_return)1
#define	SE_WARN		(se_return)2
#define SE_NOREC	(se_return)(-2)
#define SE_LOCKEDREC	(se_return)(-1)
#define SE_TRUE		(se_boolean)1
#define SE_FALSE	(se_boolean)0

/* Script Engine Data Types */
#define	SE_BINARY	1
#define	SE_CHAR		2
#define	SE_DATE		3
#define	SE_DECIMAL	4
#define	SE_FLOAT	5
#define	SE_INTEGER	6
#define	SE_TEXT		7
#define	SE_TIME		8
#define	SE_TIMESTAMP	9


/* global variables */
extern	int	se_errcode;
extern	char	*se_errmsg;
extern  char	se_state [];

/* global functions */
extern se_return se_Debug (int level);		/* debug level for se layer */

extern se_return se_Autocommit (
		se_boolean state,	/* Autocommit on or off */
		int	   c_num);

extern se_return se_BindAttributes (int st_num, 
				    int	longbuffer,
				    int* num_attrs);

extern	se_return       se_BindParameter (
     		int	st_num, 
        	int     index,
		int	type,
        	unsigned char*  buffer,
      		int    	buffer_len,
		long*	param_len);

extern se_return se_Init (void);

extern se_return se_Exit (void);

extern se_return se_Connect (
		char	*db,		/* Name of database */
		int	*connect_num);	/* connection number */

extern se_return       se_ConnectUser (
		char*   db,     /* Name of database */
		char*   uid,    /* User ID */
		char*   pword,  /* Password */
		int*    connect_num);    /* connection number  */

extern void	se_DestroyStatement (int st_num);

extern se_return se_Disconnect (
		int	c_num);		/* Connection number */

extern se_return se_DisconnectAll ();

extern se_return se_Commit (
		int	c_num);		/* Connection number */

extern se_return se_Rollback (
		int	c_num);		/* Connection number */

extern int se_Prepare (
		int	c_num,		/* Connection number */
		char	*str,		/* SQL statement */
		int	maxlength);	/* Maximum retrieved length for text */
					/*  or bulk */
extern se_return se_Execute (
		int	st_num,		/* Statement handler */
		int	longbuffer,
		int	*p_ncols,	/* no of attributes */
		int	*p_nrec);	/* no. affected records */

extern se_return se_Fetch (
		int	st_num,		/* Statement handler */
		SeRecord **valuesp,	/* Pointer to array of values */
		int	*nitems);	/* no. items from fetch operation */

extern se_return       se_FetchChunk (
	      	int		st_num, 
		int		attr_num,
       	 	long            offset,
        	long            length,
        	SeRecord**      attr_val);

extern se_return se_Finish (
		int	st_num);		/* Statement handler */

extern	SeRecord*	se_GetAttributeInfo (
		int	st_num);

extern	se_return       se_Get (
	        int             st_num,
		int             index,
		SeRecord**      valuesp);

extern	char*	se_GetCursorName (
		int	st_num);

extern se_return se_SetCursorName (int st_num, char* crs_name);

extern	se_return       se_Next (int st_num); /* Statement Number  */

extern se_return se_GetDBInt16Info (int connect_num, int option, int* buffer);

extern se_return se_GetDBInt32Info (int connect_num, int option, int* buffer);

extern se_return se_GetDBStringInfo (
		int connection_num, 
		int option,
        	unsigned char*  buffer,
        	int     buf_len);

extern int	se_Tables (int connect_num, 
			char* qualifier, char* owner,
			char* tab_names, char* tab_types);

extern int     se_TablePrivileges (int connect_num, 
			char* qualifier, char* owner,
			char* tab_names);

extern int     se_Attributes (int connect_num, 
			char* qualifier, char* owner,
			char* tab_names, char* attr_names);

extern int     se_AttributePrivileges (int connect_num, 
			char* qualifier, char* owner,
			char* tab_names, char* attr_names);

extern int     se_PrimaryKeys (int connect_num, 
			char* qualifier, char* owner,
			char* tab_name);

extern int     se_ForeignKeys (int connect_num, 
			char* exp_qualifier, char* exp_owner, char* exp_table, 
			char* imp_qualifier, char* imp_owner, char* imp_table);

extern int 	se_Statistics (int connect_num, char* qualifier,
        		char* owner, char* tab_names,
        		int is_unique, int is_approx);

extern int 	se_Procedures (int connect_num, char* qualifier,
        		char* owner, char* proc_names);

extern int 	se_ProcedureColumns (int connect_num, char* qualifier,
        		char* owner, char* proc_names, char* col_names);

extern int	se_SpecialColumns (int connect_num, char* qualifier,
			char* owner, char* tab_names,
			int scale, se_boolean nullable, int option);
	
extern int 	se_GetTypeInfo (int connection_num);

extern se_return se_Delete (
		int	st_num,		/* Statement handler */
		char	*tabname);	/* Table name */

extern se_return se_Update (
		int	st_num,		/* Statement handler */
		char	*tabname,	/* Table name */
		int	nattr,		/* Number of attributes to update */
		char	**attrs,	/* Array of attribute names */
		char	**vals,		/* Array of attribute values */
		se_boolean autoquote);	/* true: put quotes around values */

extern se_return se_Strquote (
		char	*source,	/* source string */
		char	**destination);	/* address of result string */

extern	char*	se_Version ();

/**** end of se.h ****/
