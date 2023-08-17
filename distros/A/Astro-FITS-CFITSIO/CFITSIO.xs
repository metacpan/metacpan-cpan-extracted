#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "fitsio2.h"
#include "util.h"

/* use the C std lib malloc/free */
#ifdef malloc
#undef malloc
#endif
#ifdef free
#undef free
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ANGLE_TOO_BIG"))
#ifdef ANGLE_TOO_BIG
	    return ANGLE_TOO_BIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ANY_HDU"))
#ifdef ANY_HDU
	    return ANY_HDU;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ARRAY_TOO_BIG"))
#ifdef ARRAY_TOO_BIG
	    return ARRAY_TOO_BIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ASCII_TBL"))
#ifdef ASCII_TBL
	    return ASCII_TBL;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BAD_ATABLE_FORMAT"))
#ifdef BAD_ATABLE_FORMAT
	    return BAD_ATABLE_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_BITPIX"))
#ifdef BAD_BITPIX
	    return BAD_BITPIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_BTABLE_FORMAT"))
#ifdef BAD_BTABLE_FORMAT
	    return BAD_BTABLE_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_C2D"))
#ifdef BAD_C2D
	    return BAD_C2D;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_C2F"))
#ifdef BAD_C2F
	    return BAD_C2F;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_C2I"))
#ifdef BAD_C2I
	    return BAD_C2I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_COL_NUM"))
#ifdef BAD_COL_NUM
	    return BAD_COL_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_DATATYPE"))
#ifdef BAD_DATATYPE
	    return BAD_DATATYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_DATA_FILL"))
#ifdef BAD_DATA_FILL
	    return BAD_DATA_FILL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_DATE"))
#ifdef BAD_DATE
	    return BAD_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_DECIM"))
#ifdef BAD_DECIM
	    return BAD_DECIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_DIMEN"))
#ifdef BAD_DIMEN
	    return BAD_DIMEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_DOUBLEKEY"))
#ifdef BAD_DOUBLEKEY
	    return BAD_DOUBLEKEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_ELEM_NUM"))
#ifdef BAD_ELEM_NUM
	    return BAD_ELEM_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_F2C"))
#ifdef BAD_F2C
	    return BAD_F2C;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_FILEPTR"))
#ifdef BAD_FILEPTR
	    return BAD_FILEPTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_FLOATKEY"))
#ifdef BAD_FLOATKEY
	    return BAD_FLOATKEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_GCOUNT"))
#ifdef BAD_GCOUNT
	    return BAD_GCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_GROUP_ID"))
#ifdef BAD_GROUP_ID
	    return BAD_GROUP_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_HDU_NUM"))
#ifdef BAD_HDU_NUM
	    return BAD_HDU_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_HEADER_FILL"))
#ifdef BAD_HEADER_FILL
	    return BAD_HEADER_FILL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_I2C"))
#ifdef BAD_I2C
	    return BAD_I2C;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_INTKEY"))
#ifdef BAD_INTKEY
	    return BAD_INTKEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_KEYCHAR"))
#ifdef BAD_KEYCHAR
	    return BAD_KEYCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_LOGICALKEY"))
#ifdef BAD_LOGICALKEY
	    return BAD_LOGICALKEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_NAXES"))
#ifdef BAD_NAXES
	    return BAD_NAXES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_NAXIS"))
#ifdef BAD_NAXIS
	    return BAD_NAXIS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_OPTION"))
#ifdef BAD_OPTION
	    return BAD_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_ORDER"))
#ifdef BAD_ORDER
	    return BAD_ORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_PCOUNT"))
#ifdef BAD_PCOUNT
	    return BAD_PCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_PIX_NUM"))
#ifdef BAD_PIX_NUM
	    return BAD_PIX_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_ROW_NUM"))
#ifdef BAD_ROW_NUM
	    return BAD_ROW_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_ROW_WIDTH"))
#ifdef BAD_ROW_WIDTH
	    return BAD_ROW_WIDTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_SIMPLE"))
#ifdef BAD_SIMPLE
	    return BAD_SIMPLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_TBCOL"))
#ifdef BAD_TBCOL
	    return BAD_TBCOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_TDIM"))
#ifdef BAD_TDIM
	    return BAD_TDIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_TFIELDS"))
#ifdef BAD_TFIELDS
	    return BAD_TFIELDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_TFORM"))
#ifdef BAD_TFORM
	    return BAD_TFORM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_TFORM_DTYPE"))
#ifdef BAD_TFORM_DTYPE
	    return BAD_TFORM_DTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_URL_PREFIX"))
#ifdef BAD_URL_PREFIX
	    return BAD_URL_PREFIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_WCS_PROJ"))
#ifdef BAD_WCS_PROJ
	    return BAD_WCS_PROJ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_WCS_VAL"))
#ifdef BAD_WCS_VAL
	    return BAD_WCS_VAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BINARY_TBL"))
#ifdef BINARY_TBL
	    return BINARY_TBL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BYTE_IMG"))
#ifdef BYTE_IMG
	    return BYTE_IMG;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "CASEINSEN"))
#ifdef CASEINSEN
	    return CASEINSEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CASESEN"))
#ifdef CASESEN
	    return CASESEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CFITSIO_MAJOR"))
#ifdef CFITSIO_MAJOR
	    return CFITSIO_MAJOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CFITSIO_MINOR"))
#ifdef CFITSIO_MINOR
	    return CFITSIO_MINOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "COL_NOT_FOUND"))
#ifdef COL_NOT_FOUND
	    return COL_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "COL_NOT_UNIQUE"))
#ifdef COL_NOT_UNIQUE
	    return COL_NOT_UNIQUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "COL_TOO_WIDE"))
#ifdef COL_TOO_WIDE
	    return COL_TOO_WIDE;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DOUBLENULLVALUE"))
#ifdef DOUBLENULLVALUE
	    return DOUBLENULLVALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOUBLE_IMG"))
#ifdef DOUBLE_IMG
	    return DOUBLE_IMG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRIVER_INIT_FAILED"))
#ifdef DRIVER_INIT_FAILED
	    return DRIVER_INIT_FAILED;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "END_JUNK"))
#ifdef END_JUNK
	    return END_JUNK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "END_OF_FILE"))
#ifdef END_OF_FILE
	    return END_OF_FILE;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "FALSE"))
#ifdef FALSE
	    return FALSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FILE_NOT_CLOSED"))
#ifdef FILE_NOT_CLOSED
	    return FILE_NOT_CLOSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FILE_NOT_CREATED"))
#ifdef FILE_NOT_CREATED
	    return FILE_NOT_CREATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FILE_NOT_OPENED"))
#ifdef FILE_NOT_OPENED
	    return FILE_NOT_OPENED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_CARD"))
#ifdef FLEN_CARD
	    return FLEN_CARD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_COMMENT"))
#ifdef FLEN_COMMENT
	    return FLEN_COMMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_ERRMSG"))
#ifdef FLEN_ERRMSG
	    return FLEN_ERRMSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_FILENAME"))
#ifdef FLEN_FILENAME
	    return FLEN_FILENAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_KEYWORD"))
#ifdef FLEN_KEYWORD
	    return FLEN_KEYWORD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_STATUS"))
#ifdef FLEN_STATUS
	    return FLEN_STATUS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLEN_VALUE"))
#ifdef FLEN_VALUE
	    return FLEN_VALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLOATNULLVALUE"))
#ifdef FLOATNULLVALUE
	    return FLOATNULLVALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLOAT_IMG"))
#ifdef FLOAT_IMG
	    return FLOAT_IMG;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	if (strEQ(name, "GROUP_NOT_FOUND"))
#ifdef GROUP_NOT_FOUND
	    return GROUP_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GT_ID_ALL"))
#ifdef GT_ID_ALL
	    return GT_ID_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GT_ID_ALL_URI"))
#ifdef GT_ID_ALL_URI
	    return GT_ID_ALL_URI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GT_ID_POS"))
#ifdef GT_ID_POS
	    return GT_ID_POS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GT_ID_POS_URI"))
#ifdef GT_ID_POS_URI
	    return GT_ID_POS_URI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GT_ID_REF"))
#ifdef GT_ID_REF
	    return GT_ID_REF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GT_ID_REF_URI"))
#ifdef GT_ID_REF_URI
	    return GT_ID_REF_URI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GZIP_1"))
#ifdef GZIP_1
	    return GZIP_1;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	if (strEQ(name, "HDU_ALREADY_MEMBER"))
#ifdef HDU_ALREADY_MEMBER
	    return HDU_ALREADY_MEMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HDU_ALREADY_TRACKED"))
#ifdef HDU_ALREADY_TRACKED
	    return HDU_ALREADY_TRACKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HEADER_NOT_EMPTY"))
#ifdef HEADER_NOT_EMPTY
	    return HEADER_NOT_EMPTY;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	if (strEQ(name, "IDENTICAL_POINTERS"))
#ifdef IDENTICAL_POINTERS
	    return IDENTICAL_POINTERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IMAGE_HDU"))
#ifdef IMAGE_HDU
	    return IMAGE_HDU;
#else
	    goto not_there;
#endif
	if (strEQ(name, "InputCol"))
#ifdef InputCol
	    return InputCol;
#else
	    goto not_there;
#endif
	if (strEQ(name, "InputOutputCol"))
#ifdef InputOutputCol
	    return InputOutputCol;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	if (strEQ(name, "KEY_NO_EXIST"))
#ifdef KEY_NO_EXIST
	    return KEY_NO_EXIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "KEY_OUT_BOUNDS"))
#ifdef KEY_OUT_BOUNDS
	    return KEY_OUT_BOUNDS;
#else
	    goto not_there;
#endif
	break;
    case 'L':
	if (strEQ(name, "LONG_IMG"))
#ifdef LONG_IMG
	    return LONG_IMG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LONGLONG_IMG"))
#ifdef LONGLONG_IMG
	    return LONGLONG_IMG;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	if (strEQ(name, "MAXHDU"))
#ifdef MAXHDU
	    return MAXHDU;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MEMBER_NOT_FOUND"))
#ifdef MEMBER_NOT_FOUND
	    return MEMBER_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MEMORY_ALLOCATION"))
#ifdef MEMORY_ALLOCATION
	    return MEMORY_ALLOCATION;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NEG_AXIS"))
#ifdef NEG_AXIS
	    return NEG_AXIS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEG_BYTES"))
#ifdef NEG_BYTES
	    return NEG_BYTES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEG_FILE_POS"))
#ifdef NEG_FILE_POS
	    return NEG_FILE_POS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEG_ROWS"))
#ifdef NEG_ROWS
	    return NEG_ROWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEG_WIDTH"))
#ifdef NEG_WIDTH
	    return NEG_WIDTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_ASCII_COL"))
#ifdef NOT_ASCII_COL
	    return NOT_ASCII_COL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_ATABLE"))
#ifdef NOT_ATABLE
	    return NOT_ATABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_BTABLE"))
#ifdef NOT_BTABLE
	    return NOT_BTABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_GROUP_TABLE"))
#ifdef NOT_GROUP_TABLE
	    return NOT_GROUP_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_IMAGE"))
#ifdef NOT_IMAGE
	    return NOT_IMAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_LOGICAL_COL"))
#ifdef NOT_LOGICAL_COL
	    return NOT_LOGICAL_COL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_POS_INT"))
#ifdef NOT_POS_INT
	    return NOT_POS_INT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_TABLE"))
#ifdef NOT_TABLE
	    return NOT_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_VARI_LEN"))
#ifdef NOT_VARI_LEN
	    return NOT_VARI_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_BITPIX"))
#ifdef NO_BITPIX
	    return NO_BITPIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_END"))
#ifdef NO_END
	    return NO_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_GCOUNT"))
#ifdef NO_GCOUNT
	    return NO_GCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_MATCHING_DRIVER"))
#ifdef NO_MATCHING_DRIVER
	    return NO_MATCHING_DRIVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_NAXES"))
#ifdef NO_NAXES
	    return NO_NAXES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_NAXIS"))
#ifdef NO_NAXIS
	    return NO_NAXIS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_NULL"))
#ifdef NO_NULL
	    return NO_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_PCOUNT"))
#ifdef NO_PCOUNT
	    return NO_PCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_QUOTE"))
#ifdef NO_QUOTE
	    return NO_QUOTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_SIMPLE"))
#ifdef NO_SIMPLE
	    return NO_SIMPLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_TBCOL"))
#ifdef NO_TBCOL
	    return NO_TBCOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_TFIELDS"))
#ifdef NO_TFIELDS
	    return NO_TFIELDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_TFORM"))
#ifdef NO_TFORM
	    return NO_TFORM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_WCS_KEY"))
#ifdef NO_WCS_KEY
	    return NO_WCS_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_XTENSION"))
#ifdef NO_XTENSION
	    return NO_XTENSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NULL_INPUT_PTR"))
#ifdef NULL_INPUT_PTR
	    return NULL_INPUT_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NUM_OVERFLOW"))
#ifdef NUM_OVERFLOW
	    return NUM_OVERFLOW;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strEQ(name, "OPT_CMT_MBR"))
#ifdef OPT_CMT_MBR
	    return OPT_CMT_MBR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_CMT_MBR_DEL"))
#ifdef OPT_CMT_MBR_DEL
	    return OPT_CMT_MBR_DEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_GCP_ALL"))
#ifdef OPT_GCP_ALL
	    return OPT_GCP_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_GCP_GPT"))
#ifdef OPT_GCP_GPT
	    return OPT_GCP_GPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_GCP_MBR"))
#ifdef OPT_GCP_MBR
	    return OPT_GCP_MBR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MCP_ADD"))
#ifdef OPT_MCP_ADD
	    return OPT_MCP_ADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MCP_MOV"))
#ifdef OPT_MCP_MOV
	    return OPT_MCP_MOV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MCP_NADD"))
#ifdef OPT_MCP_NADD
	    return OPT_MCP_NADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MCP_REPL"))
#ifdef OPT_MCP_REPL
	    return OPT_MCP_REPL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MRG_COPY"))
#ifdef OPT_MRG_COPY
	    return OPT_MRG_COPY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MRG_MOV"))
#ifdef OPT_MRG_MOV
	    return OPT_MRG_MOV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_RM_ALL"))
#ifdef OPT_RM_ALL
	    return OPT_RM_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_RM_ENTRY"))
#ifdef OPT_RM_ENTRY
	    return OPT_RM_ENTRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_RM_GPT"))
#ifdef OPT_RM_GPT
	    return OPT_RM_GPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_RM_MBR"))
#ifdef OPT_RM_MBR
	    return OPT_RM_MBR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OVERFLOW_ERR"))
#ifdef OVERFLOW_ERR
	    return OVERFLOW_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OutputCol"))
#ifdef OutputCol
	    return OutputCol;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "PARSE_BAD_COL"))
#ifdef PARSE_BAD_COL
	    return PARSE_BAD_COL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARSE_BAD_OUTPUT"))
#ifdef PARSE_BAD_OUTPUT
	    return PARSE_BAD_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARSE_BAD_TYPE"))
#ifdef PARSE_BAD_TYPE
	    return PARSE_BAD_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARSE_LRG_VECTOR"))
#ifdef PARSE_LRG_VECTOR
	    return PARSE_LRG_VECTOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARSE_NO_OUTPUT"))
#ifdef PARSE_NO_OUTPUT
	    return PARSE_NO_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARSE_SYNTAX_ERR"))
#ifdef PARSE_SYNTAX_ERR
	    return PARSE_SYNTAX_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLIO_1"))
#ifdef PLIO_1
	    return PLIO_1;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "READONLY"))
#ifdef READONLY
	    return READONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "READONLY_FILE"))
#ifdef READONLY_FILE
	    return READONLY_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "READWRITE"))
#ifdef READWRITE
	    return READWRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "READ_ERROR"))
#ifdef READ_ERROR
	    return READ_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RICE_1"))
#ifdef RICE_1
	    return RICE_1;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SAME_FILE"))
#ifdef SAME_FILE
	    return SAME_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SEEK_ERROR"))
#ifdef SEEK_ERROR
	    return SEEK_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SHORT_IMG"))
#ifdef SHORT_IMG
	    return SHORT_IMG;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TBIT"))
#ifdef TBIT
	    return TBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TBYTE"))
#ifdef TBYTE
	    return TBYTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TSBYTE"))
#ifdef TSBYTE
	    return TSBYTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCOMPLEX"))
#ifdef TCOMPLEX
	    return TCOMPLEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TDBLCOMPLEX"))
#ifdef TDBLCOMPLEX
	    return TDBLCOMPLEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TDOUBLE"))
#ifdef TDOUBLE
	    return TDOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TFLOAT"))
#ifdef TFLOAT
	    return TFLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TINT"))
#ifdef TINT
	    return TINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TLOGICAL"))
#ifdef TLOGICAL
	    return TLOGICAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TLONG"))
#ifdef TLONG
	    return TLONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TLONGLONG"))
#ifdef TLONGLONG
	    return TLONGLONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TOO_MANY_DRIVERS"))
#ifdef TOO_MANY_DRIVERS
	    return TOO_MANY_DRIVERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TOO_MANY_FILES"))
#ifdef TOO_MANY_FILES
	    return TOO_MANY_FILES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TOO_MANY_HDUS_TRACKED"))
#ifdef TOO_MANY_HDUS_TRACKED
	    return TOO_MANY_HDUS_TRACKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TRUE"))
#ifdef TRUE
	    return TRUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TSHORT"))
#ifdef TSHORT
	    return TSHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TSTRING"))
#ifdef TSTRING
	    return TSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TUINT"))
#ifdef TUINT
	    return TUINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TULONG"))
#ifdef TULONG
	    return TULONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TUSHORT"))
#ifdef TUSHORT
	    return TUSHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_STRUC_KEY"))
#ifdef TYP_STRUC_KEY
	    return TYP_STRUC_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_CMPRS_KEY"))
#ifdef TYP_CMPRS_KEY
	    return TYP_CMPRS_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_SCAL_KEY"))
#ifdef TYP_SCAL_KEY
	    return TYP_SCAL_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_NULL_KEY"))
#ifdef TYP_NULL_KEY
	    return TYP_NULL_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_DIM_KEY"))
#ifdef TYP_DIM_KEY
	    return TYP_DIM_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_RANG_KEY"))
#ifdef TYP_RANG_KEY
	    return TYP_RANG_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_UNIT_KEY"))
#ifdef TYP_UNIT_KEY
	    return TYP_UNIT_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_DISP_KEY"))
#ifdef TYP_DISP_KEY
	    return TYP_DISP_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_HDUID_KEY"))
#ifdef TYP_HDUID_KEY
	    return TYP_HDUID_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_CKSUM_KEY"))
#ifdef TYP_CKSUM_KEY
	    return TYP_CKSUM_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_WCS_KEY"))
#ifdef TYP_WCS_KEY
	    return TYP_WCS_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_REFSYS_KEY"))
#ifdef TYP_REFSYS_KEY
	    return TYP_REFSYS_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_COMM_KEY"))
#ifdef TYP_COMM_KEY
	    return TYP_COMM_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_CONT_KEY"))
#ifdef TYP_CONT_KEY
	    return TYP_CONT_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYP_USER_KEY"))
#ifdef TYP_USER_KEY
	    return TYP_USER_KEY;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	if (strEQ(name, "ULONG_IMG"))
#ifdef ULONG_IMG
	    return ULONG_IMG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UNKNOWN_EXT"))
#ifdef UNKNOWN_EXT
	    return UNKNOWN_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UNKNOWN_REC"))
#ifdef UNKNOWN_REC
	    return UNKNOWN_REC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "URL_PARSE_ERROR"))
#ifdef URL_PARSE_ERROR
	    return URL_PARSE_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USE_MEM_BUFF"))
#ifdef USE_MEM_BUFF
	    return USE_MEM_BUFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USHORT_IMG"))
#ifdef USHORT_IMG
	    return USHORT_IMG;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	if (strEQ(name, "VALIDSTRUC"))
#ifdef VALIDSTRUC
	    return VALIDSTRUC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VALUE_UNDEFINED"))
#ifdef VALUE_UNDEFINED
	    return VALUE_UNDEFINED;
#else
	    goto not_there;
#endif
	break;
    case 'W':
	if (strEQ(name, "WCS_ERROR"))
#ifdef WCS_ERROR
	    return WCS_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WRITE_ERROR"))
#ifdef WRITE_ERROR
	    return WRITE_ERROR;
#else
	    goto not_there;
#endif
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	if (strEQ(name, "ZERO_SCALE"))
#ifdef ZERO_SCALE
	    return ZERO_SCALE;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

#define NewFitsFile(fptr) \
do \
{	New(0, fptr, 1, FitsFile);\
	fptr->perlyunpacking = -1;\
	fptr->is_open = 1;\
} while(0)

#define AbortFitsFile(fptr) \
do \
{	Safefree(fptr);\
	fptr = 0;\
} while(0)

MODULE = Astro::FITS::CFITSIO		PACKAGE = Astro::FITS::CFITSIO

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

int
sizeof_datatype(type)
	int type

int
PerlyUnpacking(...)
	CODE:
	        RETVAL = PerlyUnpacking( items > 0 ? SvIV((ST(0))) : -1 );
	OUTPUT:
		RETVAL

int
perlyunpacking(fptr, ...)
        FitsFile * fptr
	ALIAS:
		fitsfilePtr::perlyunpacking = 1
        CODE:
	        if( items > 1 )
                  fptr->perlyunpacking = SvIV((ST(1)));
                RETVAL = fptr->perlyunpacking;
	OUTPUT:
		RETVAL

int
_is_open(fptr, ...)
        FitsFile * fptr
	ALIAS:
		fitsfilePtr::_is_open = 1
        CODE:
	        if( items > 1 )
                  fptr->is_open = SvIV((ST(1)));
                RETVAL = fptr->is_open;
	OUTPUT:
		RETVAL

int
PERLYUNPACKING(fptr)
        FitsFile * fptr
	ALIAS:
		fitsfilePtr::PERLYUNPACKING = 1
        CODE:
                RETVAL = PERLYUNPACKING(fptr->perlyunpacking);
	OUTPUT:
		RETVAL

void
DESTROY(fptr)
        FitsFile * fptr
	ALIAS:
		fitsfilePtr::DESTROY = 1
        PREINIT:
                int status = 0;
	CODE:
                if ( fptr->is_open )
                {
		  ffclos( fptr->fptr, &status );
		  if ( status )
		  {
		    char * err_text = get_mortalspace(FLEN_ERRMSG,TBYTE);
		    ffgerr(status,err_text);
		    Safefree(fptr);
		    croak( "fitsfilePtr::DESTROY: error closing FITS file: %s",
		            err_text );
	          }
		}
                Safefree(fptr);

int
ffgtam(gfptr,mfptr,hdupos,status)
	fitsfile * gfptr
	fitsfile * mfptr = NO_INIT
	int hdupos
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_add_group_member = 1
		fitsfilePtr::add_group_member = 2
	CODE:
		/*
		 * (mfptr == NULL) => member HDU is identified by hdupos
		 */
		if (ST(1)==&PL_sv_undef)
			mfptr = NULL;
		else if (sv_derived_from(ST(1),"fitsfilePtr"))
			mfptr = fitsfileSV(ST(1));
		else
			croak("mfptr is not of type fitsfilePtr");
		RETVAL = ffgtam(gfptr,mfptr,hdupos,&status);
	OUTPUT:
		status
		RETVAL

int
ffasfm(tform,typecode,width,decimals,status)
	char * tform
	int typecode = NO_INIT
	long width = NO_INIT
	int decimals = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_ascii_tform = 1
	CODE:
		RETVAL = ffasfm(tform,&typecode,&width,&decimals,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),typecode);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),width);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),decimals);
	OUTPUT:
		status
		RETVAL

int
ffbnfm(tform,typecode,repeat,width,status)
	char * tform
	int typecode = NO_INIT
	long repeat  = NO_INIT
	long width = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_binary_tform = 1
	CODE:
		RETVAL = ffbnfm(tform,&typecode,&repeat,&width,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),typecode);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),repeat);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),width);
	OUTPUT:
		status
		RETVAL

int
ffbnfmll(tform,typecode,repeat,width,status)
	char * tform
	int typecode = NO_INIT
	LONGLONG repeat  = NO_INIT
	long width = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_binary_tformll = 1
	CODE:
		RETVAL = ffbnfmll(tform,&typecode,&repeat,&width,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),typecode);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),repeat);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),width);
	OUTPUT:
		status
		RETVAL

int
ffcrow(fptr,datatype,expr,firstrow,nelements,nulval,array,anynul,status)
	FitsFile * fptr
	int datatype
	char * expr
	long firstrow
	long nelements
	SV * nulval
	void * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_calc_rows = 1
		fitsfilePtr::calc_rows = 2
	CODE:
		array = get_mortalspace(nelements,datatype);
		RETVAL=ffcrow(
			fptr->fptr,datatype,expr,firstrow,nelements,
			(nulval!=&PL_sv_undef) ? pack1D(nulval,datatype):NULL,
			array,&anynul,&status
		);
		FIXME("ffcrow: I should be calling fftexp (no harm done, however)");
		unpack1D(ST(6),array,nelements,datatype,fptr->perlyunpacking);
	OUTPUT:
		anynul
		status
		RETVAL

int
ffcalc(infptr, expr, outfptr, parName, parInfo, status)
	fitsfile * infptr
	char * expr
	fitsfile * outfptr
	char * parName
	char * parInfo
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_calculator = 1
		fitsfilePtr::calculator = 2
	OUTPUT:
		status

int
ffcalc_rng(infptr, expr, outfptr, parName, parInfo, nranges, firstrow, lastrow, status)
	fitsfile * infptr
	char * expr
	fitsfile * outfptr
	char * parName
	char * parInfo
	int nranges
	long * firstrow
	long * lastrow
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_calculator_rng = 1
		fitsfilePtr::calculator_rng = 2
	OUTPUT:
		status

int
ffgtch(gfptr,grouptype,status)
	fitsfile * gfptr
	int grouptype
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_change_group = 1
		fitsfilePtr::change_group = 2
	OUTPUT:
		status

void
ffpmrk()
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_errmark = 1

void
ffcmrk()
	ALIAS:
		Astro::FITS::CFITSIO::fits_clear_errmark = 1

void
ffcmsg()
	ALIAS:
		Astro::FITS::CFITSIO::fits_clear_errmsg = 1

int
ffclos(fptr, status)
	FitsFile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_close_file = 1
		fitsfilePtr::close_file = 2
	CODE: 
                RETVAL = ffclos(fptr->fptr, &status);
                fptr->is_open = 0;
	OUTPUT:
		RETVAL
		status

int
ffgtcm(gfptr,cmopt,status)
	fitsfile * gfptr
	int cmopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_compact_group = 1
		fitsfilePtr::compact_group = 2
	OUTPUT:
		status

void
ffcmps(templt,string,casesen,match,exact)
	char * templt
	char * string
	int casesen
	int &match
	int &exact
	ALIAS:
		Astro::FITS::CFITSIO::fits_compare_str = 1
	OUTPUT:
		match
		exact

int
ffcmph(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_compress_heap = 1
		fitsfilePtr::compress_heap = 2
	OUTPUT:
		status

int
ffcpcl(infptr,outfptr,incolnum,outcolnum,create_col,status)
	fitsfile * infptr
	fitsfile * outfptr
	int incolnum
	int outcolnum
	int create_col
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_col = 1
		fitsfilePtr::copy_col = 2
	OUTPUT:
		status

int
ffccls(infptr,outfptr,incolnum,outcolnum,ncols,create_col,status)
	fitsfile * infptr
	fitsfile * outfptr
	int incolnum
	int outcolnum
	int ncols
	int create_col
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_cols = 1
		fitsfilePtr::copy_cols = 2
	OUTPUT:
		status

int
ffcprw(infptr,outfptr,firstrow,nrows,status)
	fitsfile * infptr
	fitsfile * outfptr
	LONGLONG firstrow
	LONGLONG nrows
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_rows = 1
		fitsfilePtr::copy_rows = 2
	OUTPUT:
		status

int
ffcpsr(infptr,outfptr,firstrow,nrows,row_status,status)
	fitsfile * infptr
	fitsfile * outfptr
	LONGLONG firstrow
	LONGLONG nrows
	logical * row_status
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_selrows = 1
		fitsfilePtr::copy_selrows = 2
	OUTPUT:
		status

int
ffcpdt(infptr,outfptr,status)
	fitsfile * infptr
	fitsfile * outfptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_data = 1
		fitsfilePtr::copy_data = 2
	OUTPUT:
		status

int
ffwrhdu(infptr, stream, status)
	fitsfile * infptr
	FILE * stream
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_hdu = 1
		fitsfilePtr::write_hdu = 2
	OUTPUT:
		status

int
ffgtcp(infptr,outfptr,cpopt,status)
	fitsfile * infptr
	fitsfile * outfptr
	int cpopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_group = 1
		fitsfilePtr::copy_group = 2
	OUTPUT:
		status

int
ffcpfl(infptr,outfptr,previous,current,following,status)
	fitsfile * infptr
	fitsfile * outfptr
	int previous
	int current
	int following
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_file = 1
		fitsfilePtr::copy_file = 2
	OUTPUT:
		status

int
ffcopy(infptr,outfptr,morekeys,status)
	fitsfile * infptr
	fitsfile * outfptr
	int morekeys
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_hdu = 1
		fitsfilePtr::copy_hdu = 2
	OUTPUT:
		status

int
ffcphd(infptr,outfptr,status)
	fitsfile * infptr
	fitsfile * outfptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_header = 1
		fitsfilePtr::copy_header = 2
	OUTPUT:
		status

int
ffcpky(infptr,outfptr,innum,outnum,keyroot,status)
	fitsfile * infptr
	fitsfile * outfptr
	int innum
	int outnum
	char * keyroot
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_key = 1
		fitsfilePtr::copy_key = 2
	OUTPUT:
		status

int
ffgmcp(gfptr,mfptr,member,cpopt,status)
	fitsfile * gfptr
	fitsfile * mfptr
	long member
	int cpopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_member = 1
		fitsfilePtr::copy_member = 2
	OUTPUT:
		status

FitsFile *
create_file(name,status)
	char * name
	int status
	PREINIT:
		FitsFile* fptr;
	CODE:
		NewFitsFile(fptr);
		if (ffinit(&(fptr->fptr),name,&status))
		  AbortFitsFile(fptr);
		RETVAL = fptr;

	OUTPUT:
		RETVAL
		status

int
ffinit(fptr,name,status)
	FitsFile * fptr = NO_INIT
	char * name
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_file = 1
	CODE:
		NewFitsFile(fptr);
		RETVAL = ffinit(&(fptr->fptr),name,&status);
		if (RETVAL)
		  AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffdkinit(fptr,name,status)
	FitsFile * fptr = NO_INIT
	char * name
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_diskfile = 1
	CODE:
		NewFitsFile(fptr);
		RETVAL = ffdkinit(&(fptr->fptr),name,&status);
		if (RETVAL)
		  AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffgtcr(fptr,grpname,grouptype,status)
	fitsfile * fptr
	char * grpname
	int grouptype
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_group = 1
		fitsfilePtr::create_group = 2
	OUTPUT:
		status

int
ffcrhd(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_hdu = 1
		fitsfilePtr::create_hdu = 2
	OUTPUT:
		status

int
ffcrim(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	long * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_img = 1
		fitsfilePtr::create_img = 2
	OUTPUT:
		status

int
ffcrimll(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	LONGLONG * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_imgll = 1
		fitsfilePtr::create_imgll = 2
	OUTPUT:
		status

int
ffcrtb(fptr,tbltype,naxis2,tfields,ttype,tform,tunit,extname,status)
	fitsfile * fptr
	int tbltype
	LONGLONG naxis2
	int tfields
	char ** ttype
	char ** tform
	char ** tunit
	char * extname
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_tbl = 1
		fitsfilePtr::create_tbl = 2
	OUTPUT:
		status

int
ffcpht(infptr,outfptr,firstrow,nrows,status)
	fitsfile * infptr
	fitsfile * outfptr
	LONGLONG firstrow
	LONGLONG nrows
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_copy_hdutab = 1
		fitsfilePtr::copy_hdutab = 2
	OUTPUT:
		status

FitsFile *
create_template(filename,tpltfile,status)
	char * filename
	char * tpltfile
	int status
	PREINIT:
		FitsFile * fptr;
	CODE:
		NewFitsFile(fptr);
		if (fftplt(&(fptr->fptr),filename,tpltfile,&status))
		   AbortFitsFile(fptr);
		RETVAL = fptr;
	OUTPUT:
		RETVAL
		status

int
fftplt(fptr,filename,tpltfile,status)
	FitsFile * &fptr = NO_INIT
	char * filename
	char * tpltfile
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_create_template = 1
	CODE:
		NewFitsFile(fptr);
		RETVAL = fftplt(&(fptr->fptr),filename,tpltfile,&status);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffdt2s(year,month,day,datestr,status)
	int year
	int month
	int day
	char * datestr = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_date2str = 1
	CODE:
		datestr = get_mortalspace(11,TBYTE); /* YYYY-MM-DD or dd/mm/yy */
		RETVAL=ffdt2s(year,month,day,datestr,&status);
	OUTPUT:
		datestr
		status
		RETVAL

unsigned long
ffdsum(ascii,complm,sum)
	char * ascii
	int complm
	unsigned long &sum
	ALIAS:
		Astro::FITS::CFITSIO::fits_decode_chksum = 1
	OUTPUT:
		sum

int
ffdtdm(fptr,tdimstr,colnum,naxis,naxes,status)
	FitsFile * fptr
	char * tdimstr
	int colnum
	int naxis = NO_INIT
	long * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_decode_tdim = 1
		fitsfilePtr::decode_tdim = 2
	CODE:
		if (ST(4)!=&PL_sv_undef) { /* caller wants naxes set */
			ffdtdm(fptr->fptr,tdimstr,colnum,0,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONG);
		}
		else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=ffdtdm(fptr->fptr,tdimstr,colnum,naxis,&naxis,naxes,&status);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),naxis);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),naxes,naxis,TLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
ffdtdmll(fptr,tdimstr,colnum,naxis,naxes,status)
	FitsFile * fptr
	char * tdimstr
	int colnum
	int naxis = NO_INIT
	LONGLONG * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_decode_tdimll = 1
		fitsfilePtr::decode_tdimll = 2
	CODE:
		if (ST(4)!=&PL_sv_undef) { /* caller wants naxes set */
			ffdtdmll(fptr->fptr,tdimstr,colnum,0,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONGLONG);
		}
		else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=ffdtdmll(fptr->fptr,tdimstr,colnum,naxis,&naxis,naxes,&status);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),naxis);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),naxes,naxis,TLONGLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
fits_decomp_img(infptr,outfptr,status)
	fitsfile * infptr
	fitsfile * outfptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_decompress_img = 1
		fitsfilePtr::decompress_img = 2
	OUTPUT:
		status

int
ffdcol(fptr,colnum,status)
	fitsfile * fptr
	int colnum
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_col = 1
		fitsfilePtr::delete_col = 2
	OUTPUT:
		status

int
ffdelt(fptr,status)
	FitsFile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_file = 1
		fitsfilePtr::delete_file = 2
	CODE:
		RETVAL = ffdelt(fptr->fptr, &status );
		fptr->is_open = 0;
	OUTPUT:
		RETVAL
		status

int
ffdhdu(fptr,hdutype,status)
	fitsfile * fptr
	int hdutype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_hdu = 1
		fitsfilePtr::delete_hdu = 2
	CODE:
		RETVAL = ffdhdu(fptr,&hdutype,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),hdutype);
	OUTPUT:
		status
		RETVAL

int
ffdkey(fptr,keyname,status)
	fitsfile * fptr
	char * keyname
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_key = 1
		fitsfilePtr::delete_key = 2
	OUTPUT:
		status

int
ffdrec(fptr,keynum,status)
	fitsfile * fptr
	int keynum
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_record  = 1
		fitsfilePtr::delete_record  = 2
	OUTPUT:
		status

int
ffdrrg(fptr,rangelist,status)
	fitsfile * fptr
	char * rangelist
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_rowrange = 1
		fitsfilePtr::delete_rowrange = 2
	OUTPUT:
		status

int
ffdrws(fptr,rowlist,nrows,status)
	fitsfile * fptr
	long * rowlist
	long nrows
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_rowlist = 1
		fitsfilePtr::delete_rowlist = 2
	OUTPUT:
		status

int
ffdrwsll(fptr,rowlist,nrows,status)
	fitsfile * fptr
	LONGLONG* rowlist
	LONGLONG nrows
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_rowlistll = 1
		fitsfilePtr::delete_rowlistll = 2
	OUTPUT:
		status

int
ffdrow(fptr,firstrow,nrows,status)
	fitsfile * fptr
	LONGLONG firstrow
	LONGLONG nrows
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_rows = 1
		fitsfilePtr::delete_rows = 2
	OUTPUT:
		status

void
ffesum(sum,complm,ascii)
	unsigned long sum
	int complm
	char * ascii = NO_INIT
	ALIAS:
		Astro::FITS::CFITSIO::fits_encode_chksum = 1
	CODE:
		ascii = get_mortalspace(17,TBYTE);
		ffesum(sum,complm,ascii);
	OUTPUT:
		ascii

int
ffexist(filename, exists, status)
	char* filename
	int &exists = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_file_exists = 1
	OUTPUT:
		exists
		status

int
ffflmd(fptr,iomode,status)
	fitsfile * fptr
	int &iomode = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_file_mode = 1
		fitsfilePtr::file_mode = 2
	OUTPUT:
		iomode
		status

int
ffflnm(fptr,filename,status)
	fitsfile * fptr
	char * filename = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_file_name = 1
		fitsfilePtr::file_name = 2
	CODE:
		filename = get_mortalspace(FLEN_FILENAME,TBYTE);
		RETVAL=ffflnm(fptr,filename,&status);
	OUTPUT:
		filename
		status
		RETVAL

int
ffgnxk(fptr,inclist,ninc,exclist,nexc,card,status)
	fitsfile * fptr
	char ** inclist
	int ninc
	char ** exclist
	int nexc
	char * card = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_find_nextkey = 1
		fitsfilePtr::find_nextkey = 2
	CODE:
		card = get_mortalspace(FLEN_CARD,TBYTE);
		RETVAL=ffgnxk(fptr,inclist,ninc,exclist,nexc,card,&status);
	OUTPUT:
		card
		status
		RETVAL

int
ffffrw(fptr, expr, rownum, status)
	fitsfile * fptr
	char * expr
	long &rownum = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_find_first_row = 1
		fitsfilePtr::find_first_row = 2
	OUTPUT:
		rownum
		status

int
fffrow(fptr,expr,firstrow,nrows,n_good_rows,row_status,status)
	FitsFile * fptr
	char * expr
	long firstrow
	long nrows
	long n_good_rows = NO_INIT
	logical * row_status = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_find_rows = 1
		fitsfilePtr::find_rows = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nrows*sizeof_datatype(TLOGICAL));
			RETVAL=fffrow(fptr->fptr,expr,firstrow,nrows,&n_good_rows,(logical*)SvPV(ST(5),PL_na),&status);
		}
		else {
			row_status = get_mortalspace(nrows,TLOGICAL);
			RETVAL=fffrow(fptr->fptr,expr,firstrow,nrows,&n_good_rows,row_status,&status);
			unpack1D(ST(5),row_status,nrows,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4), n_good_rows); /* value-added */
	OUTPUT:
		status
		RETVAL

int
ffflus(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_flush_file = 1
		fitsfilePtr::flush_file = 2
	OUTPUT:
		status

int
ffihtps()
	ALIAS:
		Astro::FITS::CFITSIO::fits_init_https = 1

int
ffchtps()
	ALIAS:
		Astro::FITS::CFITSIO::fits_cleanup_https = 1

void
ffvhtps(flag)
	int flag
	ALIAS:
		Astro::FITS::CFITSIO::fits_verbose_https = 1

void
ffshdwn(flag)
	int flag
	ALIAS:
		Astro::FITS::CFITSIO::fits_show_download_progress = 1

int
ffgtmo()
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_timeout = 1

int
ffstmo(seconds, status)
	int seconds
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_timeout = 1
	OUTPUT:
		status

int
ffflsh(fptr, clearbuf, status)
	fitsfile * fptr
	int clearbuf
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_flush_buffer = 1
		fitsfilePtr::flush_buffer = 2
	OUTPUT:
		status

int
ffgacl(fptr,colnum,ttype,tbcol,tunit,tform,scale,zero,nulstr,tdisp,status)
	fitsfile * fptr
	int colnum
	char * ttype = NO_INIT
	long tbcol = NO_INIT
	char * tunit = NO_INIT
	char * tform = NO_INIT
	double scale = NO_INIT
	double zero = NO_INIT
	char * nulstr = NO_INIT
	char * tdisp = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_acolparms = 1
		fitsfilePtr::get_acolparms = 2
	CODE:
		ttype = (ST(2) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tunit = (ST(4) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tform = (ST(5) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		nulstr= (ST(8) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tdisp = (ST(9) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		RETVAL=ffgacl(fptr,colnum,ttype,&tbcol,tunit,tform,&scale,&zero,nulstr,tdisp,&status);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),tbcol);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),scale);
		if (ST(7) != &PL_sv_undef) sv_setnv(ST(7),zero);
	OUTPUT:
		ttype
		tunit
		tform
		nulstr
		tdisp
		status
		RETVAL

int
ffgbcl(fptr,colnum,ttype,tunit,dtype,repeat,scale,zero,nulval,tdisp,status)
	fitsfile * fptr
	int colnum
	char * ttype = NO_INIT
	char * tunit = NO_INIT
	char * dtype = NO_INIT
	long repeat = NO_INIT
	double scale = NO_INIT
	double zero = NO_INIT
	long nulval = NO_INIT
	char * tdisp = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_bcolparms = 1
		fitsfilePtr::get_bcolparms = 2
	CODE:
		ttype = (ST(2) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tunit = (ST(3) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		dtype = (ST(4) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tdisp = (ST(9) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		RETVAL=ffgbcl(fptr,colnum,ttype,tunit,dtype,&repeat,&scale,&zero,&nulval,tdisp,&status);
		if (ST(5) != &PL_sv_undef) sv_setiv(ST(5),repeat);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),scale);
		if (ST(7) != &PL_sv_undef) sv_setnv(ST(7),zero);
		if (ST(8) != &PL_sv_undef) sv_setiv(ST(8),nulval);
	OUTPUT:
		ttype
		tunit
		dtype
		tdisp
		status
		RETVAL

int
ffgbclll(fptr,colnum,ttype,tunit,dtype,repeat,scale,zero,nulval,tdisp,status)
	fitsfile * fptr
	int colnum
	char * ttype = NO_INIT
	char * tunit = NO_INIT
	char * dtype = NO_INIT
	LONGLONG repeat = NO_INIT
	double scale = NO_INIT
	double zero = NO_INIT
	LONGLONG nulval = NO_INIT
	char * tdisp = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_bcolparmsll = 1
		fitsfilePtr::get_bcolparmsll = 2
	CODE:
		ttype = (ST(2) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tunit = (ST(3) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		dtype = (ST(4) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		tdisp = (ST(9) != &PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		RETVAL=ffgbclll(fptr,colnum,ttype,tunit,dtype,&repeat,&scale,&zero,&nulval,tdisp,&status);
		if (ST(5) != &PL_sv_undef) sv_setiv(ST(5),repeat);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),scale);
		if (ST(7) != &PL_sv_undef) sv_setnv(ST(7),zero);
		if (ST(8) != &PL_sv_undef) sv_setiv(ST(8),nulval);
	OUTPUT:
		ttype
		tunit
		dtype
		tdisp
		status
		RETVAL

int
ffgcks(fptr,datasum,hdusum,status)
	fitsfile * fptr
	unsigned long datasum = NO_INIT
	unsigned long hdusum = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_chksum = 1
		fitsfilePtr::get_chksum = 2
	CODE:
		RETVAL = ffgcks(fptr,&datasum,&hdusum,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1), datasum); /* value-added */
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2), hdusum); /* value-added */
	OUTPUT:
		status
		RETVAL

int
ffgcnn(fptr,casesen,templt,colname,colnum,status)
	fitsfile * fptr
	int casesen
	char * templt
	char * colname = NO_INIT
	int colnum = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_colname = 1
		fitsfilePtr::get_colname = 2
	CODE:
		colname = get_mortalspace(FLEN_KEYWORD,TBYTE);
		RETVAL=ffgcnn(fptr,casesen,templt,colname,&colnum,&status);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),colnum); /* value-added */
	OUTPUT:
		colname
		status
		RETVAL

int
ffgcno(fptr,casesen,templt,colnum,status)
	fitsfile * fptr
	int casesen
	char * templt
	int colnum = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_colnum = 1
		fitsfilePtr::get_colnum = 2
	CODE:
		RETVAL = fits_get_colnum(fptr,casesen,templt,&colnum,&status);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),colnum);
	OUTPUT:
		status
		RETVAL

int
ffgtcl(fptr,colnum,typecode,repeat,width,status)
	fitsfile * fptr
	int colnum
	int typecode = NO_INIT
	long repeat = NO_INIT
	long width = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_coltype = 1
		fitsfilePtr::get_coltype = 2
	CODE:
		RETVAL = ffgtcl(fptr,colnum,&typecode,&repeat,&width,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),typecode);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),repeat);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),width);
	OUTPUT:
		status
		RETVAL

int
ffgtclll(fptr,colnum,typecode,repeat,width,status)
	fitsfile * fptr
	int colnum
	int typecode = NO_INIT
	LONGLONG repeat = NO_INIT
	LONGLONG width = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_coltypell = 1
		fitsfilePtr::get_coltypell = 2
	CODE:
		RETVAL = ffgtclll(fptr,colnum,&typecode,&repeat,&width,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),typecode);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),repeat);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),width);
	OUTPUT:
		status
		RETVAL

int
ffeqty(fptr,colnum,typecode,repeat,width,status)
	fitsfile * fptr
	int colnum
	int typecode = NO_INIT
	long repeat = NO_INIT
	long width = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_eqcoltype = 1
		fitsfilePtr::get_eqcoltype = 2
	CODE:
		RETVAL = ffeqty(fptr,colnum,&typecode,&repeat,&width,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),typecode);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),repeat);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),width);
	OUTPUT:
		status
		RETVAL

int
ffeqtyll(fptr,colnum,typecode,repeat,width,status)
	fitsfile * fptr
	int colnum
	int typecode = NO_INIT
	LONGLONG repeat = NO_INIT
	LONGLONG width = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_eqcoltypell = 1
		fitsfilePtr::get_eqcoltypell = 2
	CODE:
		RETVAL = ffeqtyll(fptr,colnum,&typecode,&repeat,&width,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),typecode);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),repeat);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),width);
	OUTPUT:
		status
		RETVAL

int
fits_get_compression_type(fptr, comptype, status)
	fitsfile *fptr
	int &comptype = NO_INIT
	int &status
	ALIAS:
		fitsfilePtr::get_compression_type = 1
	OUTPUT:
		comptype
		status

void
ffgerr(status,err_text)
	int status
	char * err_text = NO_INIT
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_errstatus = 1
	CODE:
		err_text = get_mortalspace(FLEN_ERRMSG,TBYTE);
		ffgerr(status,err_text);
	OUTPUT:
		err_text

int
ffghps(fptr,keysexist,keynum,status)
	fitsfile * fptr
	int keysexist = NO_INIT
	int keynum = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hdrpos = 1
		fitsfilePtr::get_hdrpos = 2
	CODE:
		RETVAL = ffghps(fptr,&keysexist,&keynum,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),keysexist); /* value-added */
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),keynum); /* value-added */
	OUTPUT:
		status
		RETVAL

int
ffghsp(fptr,keysexist,morekeys,status)
	fitsfile * fptr
	int keysexist = NO_INIT
	int morekeys = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hdrspace = 1
		fitsfilePtr::get_hdrspace = 2
	CODE:
		RETVAL = ffghsp(fptr,&keysexist,&morekeys,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),keysexist); /* value-added */
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),morekeys); /* value-added */
	OUTPUT:
		status
		RETVAL

int 
ffghdn(fptr,hdunum)
	fitsfile * fptr
	int hdunum = NO_INIT
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hdu_num = 1
		fitsfilePtr::get_hdu_num = 2
	CODE:
		RETVAL = ffghdn(fptr,&hdunum);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),hdunum);
	OUTPUT:
		RETVAL

int
ffghdt(fptr,hdutype,status)
	fitsfile * fptr
	int &hdutype = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hdu_type = 1
		fitsfilePtr::get_hdu_type = 2
	OUTPUT:
		hdutype
		status

int
ffghad(fptr,headstart,datastart,dataend,status)
	fitsfile * fptr
	long headstart = NO_INIT
	long datastart = NO_INIT
	long dataend = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hduaddr = 1
		fitsfilePtr::get_hduaddr = 2
	CODE:
		RETVAL = ffghad(fptr,&headstart,&datastart,&dataend,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),headstart);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),datastart);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),dataend);
	OUTPUT:
		status
		RETVAL

int
ffghadll(fptr,headstart,datastart,dataend,status)
	fitsfile * fptr
	LONGLONG headstart = NO_INIT
	LONGLONG datastart = NO_INIT
	LONGLONG dataend = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hduaddrll = 1
		fitsfilePtr::get_hduaddrll = 2
	CODE:
		RETVAL = ffghadll(fptr,&headstart,&datastart,&dataend,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),headstart);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),datastart);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),dataend);
	OUTPUT:
		status
		RETVAL

int
ffghof(fptr, headstart, datastart, dataend, status)
	fitsfile * fptr
	OFF_T headstart = NO_INIT	
	OFF_T datastart = NO_INIT	
	OFF_T dataend = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_hduoff = 1
		fitsfilePtr::get_hduoff = 2
	CODE:
		RETVAL = ffghof(fptr,&headstart,&datastart,&dataend,&status);
		if (ST(1) != &PL_sv_undef) sv_setuv(ST(1),headstart);
		if (ST(2) != &PL_sv_undef) sv_setuv(ST(2),datastart);
		if (ST(3) != &PL_sv_undef) sv_setuv(ST(3),dataend);
	OUTPUT:
		status
		RETVAL


int
ffgknm(card,name,len,status)
	char * card
	char * name = NO_INIT
	int len = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_keyname = 1
	CODE:
		name = get_mortalspace(FLEN_KEYWORD,TBYTE);
		RETVAL = ffgknm(card,name,&len,&status);
		if (ST(2) != &PL_sv_undef)
			sv_setiv(ST(2), len);
	OUTPUT:
		name
		status
		RETVAL

int
ffdtyp(value,dtype,status)
	char * value
	char &dtype = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_keytype = 1
	OUTPUT:
		dtype
		status

int
ffgidt(fptr,bitpix,status)
	fitsfile * fptr
	int &bitpix = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_type = 1
		fitsfilePtr::get_img_type = 2
	OUTPUT:
		bitpix
		status

int
ffinttyp(value,inttype,neg,status)
	char * value
	int &inttype = NO_INIT
	int &neg = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_inttype = 1
	OUTPUT:
		inttype
		neg
		status

int
ffgiet(fptr,bitpix,status)
	fitsfile * fptr
	int &bitpix = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_equivtype = 1
		fitsfilePtr::get_img_equivtype = 2
	OUTPUT:
		bitpix
		status

int
ffgidm(fptr,naxis,status)
	fitsfile * fptr
	int &naxis = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_dim = 1
		fitsfilePtr::get_img_dim = 2
	OUTPUT:
		naxis
		status

int
ffgisz(fptr,naxes,status)
	FitsFile * fptr
	long *naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_size = 1
		fitsfilePtr::get_img_size = 2
	PREINIT:
		int nlen;
	CODE:
		RETVAL = ffgidm(fptr->fptr,&nlen,&status);
		if (RETVAL <= 0) {
			naxes = get_mortalspace(nlen,TLONG);
			RETVAL = ffgisz(fptr->fptr,nlen,naxes,&status);
			/* unpack as Perl array */
			unpack1D(ST(1),naxes,nlen,TLONG,1);
		}
	OUTPUT:
		status
		RETVAL

int
ffgiszll(fptr,naxes,status)
	FitsFile * fptr
	LONGLONG *naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_sizell = 1
		fitsfilePtr::get_img_sizell = 2
	PREINIT:
		int nlen;
	CODE:
		RETVAL = ffgidm(fptr->fptr,&nlen,&status);
		if (RETVAL <= 0) {
			naxes = get_mortalspace(nlen,TLONGLONG);
			RETVAL = ffgiszll(fptr->fptr,nlen,naxes,&status);
			/* unpack as Perl array */
			unpack1D(ST(1),naxes,nlen,TLONGLONG,1);
		}
	OUTPUT:
		status
		RETVAL

int
fits_get_noise_bits(fptr, noisebits, status)
	fitsfile *fptr
	int &noisebits = NO_INIT
	int &status
	ALIAS:
		fitsfilePtr::get_noise_bits = 1
	OUTPUT:
		noisebits
		status

int
ffgncl(fptr,ncols,status)
	fitsfile * fptr
	int &ncols = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_num_cols = 1
		fitsfilePtr::get_num_cols = 2
	OUTPUT:
		ncols
		status

int
ffgmng(mfptr,nmembers,status)
	fitsfile * mfptr
	long &nmembers = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_num_groups = 1
		fitsfilePtr::get_num_groups = 2
	OUTPUT:
		nmembers
		status

int
ffthdu(fptr,hdunum,status)
	fitsfile * fptr
	int &hdunum = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_num_hdus = 1
		fitsfilePtr::get_num_hdus = 2
	OUTPUT:
		hdunum
		status

int
ffgtnm(gfptr,nmembers,status)
	fitsfile * gfptr
	long &nmembers = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_num_members = 1
		fitsfilePtr::get_num_members = 2
	OUTPUT:
		nmembers
		status

int
ffgnrw(fptr,nrows,status)
	fitsfile * fptr
	long &nrows = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_num_rows = 1
		fitsfilePtr::get_num_rows = 2
	OUTPUT:
		nrows
		status

int
ffgnrwll(fptr,nrows,status)
	fitsfile * fptr
	LONGLONG &nrows = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_num_rowsll = 1
		fitsfilePtr::get_num_rowsll = 2
	OUTPUT:
		nrows
		status

int
ffgrsz(fptr,nrows,status)
	fitsfile * fptr
	long &nrows = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_rowsize = 1
		fitsfilePtr::get_rowsize = 2
	OUTPUT:
		nrows
		status

int
ffgstm(timestr,timeref,status)
	char * timestr = NO_INIT
	int timeref = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_system_time = 1
	CODE:
		timestr = get_mortalspace(20,TBYTE); /* YYYY-MM-DDThh:mm:ss */
		RETVAL=ffgstm(timestr,&timeref,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),timeref);
	OUTPUT:
		timestr
		status
		RETVAL

int
ffgabc(tfields,tform,space,rowlen,tbcol,status)
	int tfields
	char ** tform
	int space
	long rowlen = NO_INIT
	long * tbcol = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_tbcol = 1
	CODE:
		tbcol = get_mortalspace(tfields,TLONG);
		RETVAL=ffgabc(tfields,tform,space,&rowlen,tbcol,&status);
		unpack1D(ST(4),tbcol,tfields,TLONG,-1);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),rowlen); /* value-added */
	OUTPUT:
		status
		RETVAL

int
fits_get_tile_dim(fptr, ndim, tilesize, status)
	FitsFile *fptr
	int ndim
	long *naxes = NO_INIT
	int status
	ALIAS:
		fitsfilePtr::get_tile_dim = 1
	CODE:
		naxes = get_mortalspace(ndim,TLONG);
		RETVAL=fits_get_tile_dim(fptr->fptr,ndim,naxes,&status);
		if (ST(2)!=&PL_sv_undef) unpack1D(ST(2),naxes,ndim,TLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

float
ffvers(version)
	float version = NO_INIT
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_version = 1
	CODE:
		RETVAL = ffvers(&version);
		if (ST(0) != &PL_sv_undef) sv_setnv(ST(0),version); /* value-added */
	OUTPUT:
		RETVAL

int
ffhdr2str(fptr, nocomments, header, nkeys, status)
	FitsFile *fptr
	int nocomments
	char *header = NO_INIT
	int nkeys = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_hdr2str = 1
		fitsfilePtr::hdr2str = 2
	CODE:
		RETVAL=fits_hdr2str(fptr->fptr,nocomments,NULL,0,&header,&nkeys,&status);
		if (ST(2)!=&PL_sv_undef) unpackScalar(ST(2), header, TSTRING);
		if (ST(3)!=&PL_sv_undef) unpackScalar(ST(3), &nkeys, TINT);
		fffree(header, &status);
	OUTPUT:
		status
		RETVAL

int
ffcnvthdr2str(fptr, nocomments, header, nkeys, status)
	FitsFile *fptr
	int nocomments
	char *header = NO_INIT
	int nkeys = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_convert_hdr2str = 1
		fitsfilePtr::convert_hdr2str = 2
	CODE:
		RETVAL=fits_hdr2str(fptr->fptr,nocomments,NULL,0,&header,&nkeys,&status);
		if (ST(2)!=&PL_sv_undef) unpackScalar(ST(2), header, TSTRING);
		if (ST(3)!=&PL_sv_undef) unpackScalar(ST(3), &nkeys, TINT);
		fffree(header, &status);
	OUTPUT:
		status
		RETVAL

int
ffitab(fptr,rowlen,nrows,tfields,ttype,tbcol,tform,tunit,extname,status)
	fitsfile * fptr
	LONGLONG rowlen
	LONGLONG nrows
	int tfields
	char ** ttype
	long * tbcol
	char ** tform
	char ** tunit
	char * extname
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_atbl = 1
		fitsfilePtr::insert_atbl = 2
	OUTPUT:
		status

int
ffibin(fptr,nrows,tfields,ttype,tform,tunit,extname,pcount,status)
	fitsfile * fptr
	LONGLONG nrows 
	int tfields
	char ** ttype
	char ** tform
	char ** tunit
	char * extname
	LONGLONG pcount
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_btbl = 1
		fitsfilePtr::insert_btbl = 2
	OUTPUT:
		status

int
fficol(fptr,colnum,ttype,tform,status)
	fitsfile * fptr
	int colnum
	char * ttype
	char * tform
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_col = 1
		fitsfilePtr::insert_col = 2
	OUTPUT:
		status

int
fficls(fptr,colnum,ncols,ttype,tform,status)
	fitsfile * fptr
	int colnum
	int ncols
	char ** ttype
	char ** tform
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_cols = 1
		fitsfilePtr::insert_cols = 2
	OUTPUT:
		status

int
ffgtis(fptr,grpname,grouptype,status)
	fitsfile * fptr
	char * grpname
	int grouptype
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_group = 1
		fitsfilePtr::insert_group = 2
	OUTPUT:
		status

int
ffiimg(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	long * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_img = 1
		fitsfilePtr::insert_img = 2
	OUTPUT:
		status

int
ffiimgll(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	LONGLONG * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_imgll = 1
		fitsfilePtr::insert_imgll = 2
	OUTPUT:
		status

int
ffikyu(fptr,keyname,comment,status)
	fitsfile * fptr
	char * keyname
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_null = 1
		fitsfilePtr::insert_key_null = 2
	OUTPUT:
		status

int
ffikys(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	char * value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_str = 1
		fitsfilePtr::insert_key_str = 2
	OUTPUT:
		status

int
ffikyl(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	int value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_log = 1
		fitsfilePtr::insert_key_log = 2
	OUTPUT:
		status

int
ffikyj(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	LONGLONG value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_lng = 1
		fitsfilePtr::insert_key_lng = 2
	OUTPUT:
		status

int
ffikye(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_flt = 1
		fitsfilePtr::insert_key_flt = 2
	OUTPUT:
		status

int
ffikyf(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_fixflt = 1
		fitsfilePtr::insert_key_fixflt = 2
	OUTPUT:
		status

int
ffikyd(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_dbl = 1
		fitsfilePtr::insert_key_dbl = 2
	OUTPUT:
		status

int
ffikyg(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_fixdbl = 1
		fitsfilePtr::insert_key_fixdbl = 2
	OUTPUT:
		status

int
ffikyc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_cmp = 1
		fitsfilePtr::insert_key_cmp = 2
	OUTPUT:
		status

int
ffikfc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_fixcmp = 1
		fitsfilePtr::insert_key_fixcmp = 2
	OUTPUT:
		status

int
ffikym(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_dblcmp = 1
		fitsfilePtr::insert_key_dblcmp = 2
	OUTPUT:
		status

int
ffikfm(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_fixdblcmp = 1
		fitsfilePtr::insert_key_fixdblcmp = 2
	OUTPUT:
		status

int
ffirec(fptr,keynum,card,status)
	fitsfile * fptr
	int keynum
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_record = 1
		fitsfilePtr::insert_record = 2
	OUTPUT:
		status

int
ffikey(fptr,card,status)
	fitsfile * fptr
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_card = 1
		fitsfilePtr::insert_card = 2
	OUTPUT:
		status

int
ffirow(fptr,firstrow,nrows,status)
	fitsfile * fptr
	LONGLONG firstrow
	LONGLONG nrows
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_rows = 1
		fitsfilePtr::insert_rows = 2
	OUTPUT:
		status

int
ffkeyn(keyroot,value,keyname,status)
	char * keyroot
	int value
	char * keyname = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_make_keyn = 1
	CODE:
		keyname = get_mortalspace(FLEN_KEYWORD,TBYTE);
		RETVAL=ffkeyn(keyroot,value,keyname,&status);
	OUTPUT:
		keyname
		status
		RETVAL

int
ffnkey(value,keyroot,keyname,status)
	int value
	char * keyroot
	char * keyname = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_make_nkey = 1
	CODE:
		keyname = get_mortalspace(FLEN_KEYWORD,TBYTE);
		RETVAL=ffnkey(value,keyroot,keyname,&status);
	OUTPUT:
		keyname
		status
		RETVAL

int
ffmkky(keyname, value, comm, card, status)
	const char * keyname
	char * value
	const char * comm
	char * card = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_make_key = 1
	CODE:
		card = get_mortalspace(FLEN_CARD, TBYTE);
		RETVAL=ffmkky(keyname, value, comm, card, &status);
	OUTPUT:
		card
		status
		RETVAL

int
ffgtmg(infptr,outfptr,mgopt,status)
	fitsfile * infptr
	fitsfile * outfptr
	int mgopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_merge_groups = 1
		fitsfilePtr::merge_groups = 2
	OUTPUT:
		status

int
ffmbyt(fptr, bytepos, err_mode, status)
	fitsfile * fptr
	LONGLONG bytepos
	int err_mode
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_seek = 1
		fitsfilePtr::seek = 2
	OUTPUT:
		status

int
ffmcrd(fptr,keyname,card,status)
	fitsfile * fptr
	char * keyname
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_card = 1
		fitsfilePtr::modify_card = 2
	OUTPUT:
		status

int
ffmcom(fptr,keyname,comment,status)
	fitsfile * fptr
	char * keyname
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_comment = 1
		fitsfilePtr::modify_comment = 2
	OUTPUT:
		status

int
ffmkyu(fptr,keyname,comment,status)
	fitsfile * fptr
	char * keyname
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_null = 1
		fitsfilePtr::modify_key_null = 2
	OUTPUT:
		status

int
ffmkys(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	char * value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_str = 1
		fitsfilePtr::modify_key_str = 2
	OUTPUT:
		status

int
ffmkyl(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	int value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_log = 1
		fitsfilePtr::modify_key_log = 2
	OUTPUT:
		status

int
ffmkyj(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	LONGLONG value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_lng = 1
		fitsfilePtr::modify_key_lng = 2
	OUTPUT:
		status

int
ffmkye(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_flt = 1
		fitsfilePtr::modify_key_flt = 2
	OUTPUT:
		status

int
ffmkyf(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_fixflt = 1
		fitsfilePtr::modify_key_fixflt = 2
	OUTPUT:
		status

int
ffmkyd(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_dbl = 1
		fitsfilePtr::modify_key_dbl = 2
	OUTPUT:
		status

int
ffmkyg(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_fixdbl = 1
		fitsfilePtr::modify_key_fixdbl = 2
	OUTPUT:
		status

int
ffmkyc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_cmp = 1
		fitsfilePtr::modify_key_cmp = 2
	OUTPUT:
		status

int
ffmkfc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_fixcmp = 1
		fitsfilePtr::modify_key_fixcmp = 2
	OUTPUT:
		status

int
ffmkym(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_dblcmp = 1
		fitsfilePtr::modify_key_dblcmp = 2
	OUTPUT:
		status

int
ffmkfm(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_fixdblcmp = 1
		fitsfilePtr::modify_key_fixdblcmp = 2
	OUTPUT:
		status

int
ffmnam(fptr,oldname,newname,status)
	fitsfile * fptr
	char * oldname
	char * newname
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_name = 1
		fitsfilePtr::modify_name = 2
	OUTPUT:
		status

int
ffmrec(fptr,keynum,card,status)
	fitsfile * fptr
	int keynum
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_record = 1
		fitsfilePtr::modify_record = 2
	OUTPUT:
		status

int
ffmvec(fptr,colnum,newveclen,status)
	fitsfile * fptr
	int colnum
	LONGLONG newveclen
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_vector_len = 1
		fitsfilePtr::modify_vector_len = 2
	OUTPUT:
		status

int
ffmahd(fptr,hdunum,hdutype,status)
	fitsfile * fptr
	int hdunum
	int hdutype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_movabs_hdu = 1
		fitsfilePtr::movabs_hdu = 2
	CODE:
		RETVAL = ffmahd(fptr,hdunum,&hdutype,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),hdutype);
	OUTPUT:
		status
		RETVAL

int
ffmnhd(fptr,hdutype,extname,extvers,status)
	fitsfile * fptr
	int hdutype
	char * extname
	int extvers
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_movnam_hdu = 1
		fitsfilePtr::movnam_hdu = 2
	OUTPUT:
		status

int
ffmrhd(fptr,nmove,hdutype,status)
	fitsfile * fptr
	int nmove
	int hdutype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_movrel_hdu = 1
		fitsfilePtr::movrel_hdu = 2
	CODE:
		RETVAL = ffmrhd(fptr,nmove,&hdutype,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),hdutype);
	OUTPUT:
		status
		RETVAL

int
ffnchk(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_null_check = 1
		fitsfilePtr::null_check = 2
	OUTPUT:
		status

FitsFile*
open_file(filename,iomode,status)
	char * filename
	int iomode
	int status
	ALIAS:
		Astro::FITS::CFITSIO::open_diskfile = 1
		Astro::FITS::CFITSIO::open_data     = 2
		Astro::FITS::CFITSIO::open_image    = 3
		Astro::FITS::CFITSIO::open_table    = 4
	PREINIT:
		FitsFile * fptr;
		static int (*fits_open[5])(fitsfile **, const char *, int , int *) = { ffopen, ffdkopn, ffdopn, ffiopn, fftopn };
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		if (fits_open[ix](&(fptr->fptr),filename,iomode,&status))
		   AbortFitsFile(fptr);
		RETVAL = fptr;
	OUTPUT:
		RETVAL
		status

int
ffopen(fptr,filename,iomode,status)
	FitsFile * fptr = NO_INIT
	char * filename
	int iomode
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_file = 1
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		RETVAL = ffopen(&(fptr->fptr),filename,iomode,&status);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffdkopn(fptr,filename,iomode,status)
	FitsFile * fptr = NO_INIT
	char * filename
	int iomode
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_diskfile = 1
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		RETVAL = ffdkopn(&(fptr->fptr),filename,iomode,&status);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffdopn(fptr,filename,iomode,status)
	FitsFile * fptr = NO_INIT
	char * filename
	int iomode
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_data = 1
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		RETVAL = ffdopn(&(fptr->fptr),filename,iomode,&status);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffiopn(fptr,filename,iomode,status)
	FitsFile * fptr = NO_INIT
	char * filename
	int iomode
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_image = 1
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		RETVAL = ffiopn(&(fptr->fptr),filename,iomode,&status);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
fftopn(fptr,filename,iomode,status)
	FitsFile * fptr = NO_INIT
	char * filename
	int iomode
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_table = 1
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		RETVAL = fftopn(&(fptr->fptr),filename,iomode,&status);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffeopn(fptr,filename,iomode,extlist,hdutype,status)
	FitsFile * fptr = NO_INIT
	char * filename
	int iomode
	char * extlist
	int hdutype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_extlist = 1
	CODE:
		if (!filename) /* undef passed */
			filename = "";
		NewFitsFile(fptr);
		RETVAL = ffeopn(&(fptr->fptr),filename,iomode,extlist,&hdutype,&status);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),hdutype);
		if (RETVAL)
		   AbortFitsFile(fptr);
	OUTPUT:
		RETVAL
		fptr
		status

int
ffgtop(mfptr,group,gfptr,status)
	fitsfile * mfptr
	int group
	FitsFile * gfptr = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_group = 1
		fitsfilePtr::open_group = 2
	CODE:
		NewFitsFile(gfptr);
		RETVAL = ffgtop(mfptr,group,&(gfptr->fptr),&status);
		if (RETVAL)
		   AbortFitsFile(gfptr);
	OUTPUT:
		RETVAL
		gfptr
		status

int
ffgmop(gfptr,member,mfptr,status)
	fitsfile * gfptr
	long member
	FitsFile * mfptr = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_open_member = 1
		fitsfilePtr::open_member = 2
	CODE:
		NewFitsFile(mfptr);
		RETVAL = ffgmop(gfptr,member,&(mfptr->fptr),&status);
		if (RETVAL)
		   AbortFitsFile(mfptr);
	OUTPUT:
		status
		mfptr
		RETVAL

int
ffextn(filename,hdunum,status)
	char * filename
	int &hdunum = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_extnum = 1
	OUTPUT:
		hdunum
		status

int
ffiurl(filename,urltype,infile,outfile,extspec,filter,binspec,colspec,status)
	char * filename
	char * urltype = NO_INIT
	char * infile = NO_INIT
	char * outfile = NO_INIT
	char * extspec = NO_INIT
	char * filter = NO_INIT
	char * binspec = NO_INIT
	char * colspec = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_input_url = 1
	CODE:
		urltype = get_mortalspace(FLEN_FILENAME,TBYTE);
		infile = get_mortalspace(FLEN_FILENAME,TBYTE);
		outfile = get_mortalspace(FLEN_FILENAME,TBYTE);
		extspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		filter = get_mortalspace(FLEN_FILENAME,TBYTE);
		binspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		colspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		RETVAL = ffiurl(filename,urltype,infile,outfile,extspec,filter,binspec,colspec,&status);
	OUTPUT:
		urltype
		infile
		outfile
		extspec
		filter
		binspec
		colspec
		status
		RETVAL

int
ffifile(filename,filetype,infile,outfile,extspec,filter,binspec,colspec,pixspec,status)
	char * filename
	char * filetype = NO_INIT
	char * infile = NO_INIT
	char * outfile = NO_INIT
	char * extspec = NO_INIT
	char * filter = NO_INIT
	char * binspec = NO_INIT
	char * colspec = NO_INIT
	char * pixspec = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_input_filename = 1
	CODE:
		filetype = get_mortalspace(FLEN_FILENAME,TBYTE);
		infile = get_mortalspace(FLEN_FILENAME,TBYTE);
		outfile = get_mortalspace(FLEN_FILENAME,TBYTE);
		extspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		filter = get_mortalspace(FLEN_FILENAME,TBYTE);
		binspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		colspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		pixspec = get_mortalspace(FLEN_FILENAME,TBYTE);
		RETVAL = ffifile(filename,filetype,infile,outfile,extspec,filter,binspec,colspec,pixspec,&status);
	OUTPUT:
		filetype
		infile
		outfile
		extspec
		filter
		binspec
		colspec
		pixspec
		status
		RETVAL

int
fits_copy_cell2image(infptr, outfptr, colname, rownum, status)
	fitsfile* infptr
	fitsfile* outfptr
	char* colname
	long rownum
	int &status
	ALIAS:
		fitsfilePtr::copy_cell2image = 1
	OUTPUT:
		status

int
fits_copy_image2cell(infptr, outfptr, colname, rownum, copykeyflag, status)
	fitsfile* infptr
	fitsfile* outfptr
	char* colname
	long rownum
	int copykeyflag
	int &status
	ALIAS:
		fitsfilePtr::copy_image2cell = 1
	OUTPUT:
		status

int
ffrwrg(rowlist, maxrows, maxranges, numranges, rangemin, rangemax, status)
	char * rowlist
	LONGLONG maxrows
	int maxranges
	int numranges = NO_INIT
	long * rangemin = NO_INIT
	long * rangemax = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_range = 1
	CODE:
		if (ST(4)!=&PL_sv_undef || ST(5)!=&PL_sv_undef) {
			rangemin = get_mortalspace(maxranges,TLONG);
			rangemax = get_mortalspace(maxranges,TLONG);
		}
		else {
			rangemin = rangemax = 0;
			maxranges = 0;
		}

		RETVAL=ffrwrg(rowlist, maxrows, maxranges, &numranges,
			rangemin, rangemax, &status);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),numranges);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),rangemin,numranges,TLONG,-1);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),rangemax,numranges,TLONG,-1);
	OUTPUT:
		status
		RETVAL

int
ffrwrgll(rowlist, maxrows, maxranges, numranges, rangemin, rangemax, status)
	char * rowlist
	LONGLONG maxrows
	int maxranges
	int numranges = NO_INIT
	LONGLONG * rangemin = NO_INIT
	LONGLONG * rangemax = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_rangell = 1
	CODE:
		if (ST(4)!=&PL_sv_undef || ST(5)!=&PL_sv_undef) {
			rangemin = get_mortalspace(maxranges,TLONG);
			rangemax = get_mortalspace(maxranges,TLONG);
		}
		else {
			rangemin = rangemax = 0;
			maxranges = 0;
		}

		RETVAL=ffrwrgll(rowlist, maxrows, maxranges, &numranges,
			rangemin, rangemax, &status);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),numranges);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),rangemin,numranges,TLONGLONG,-1);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),rangemax,numranges,TLONGLONG,-1);
	OUTPUT:
		status
		RETVAL

int
ffrtnm(url,rootname,status)
	char * url 
	char * rootname = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_rootname = 1
	CODE:
		rootname = get_mortalspace(FLEN_FILENAME,TBYTE);
		RETVAL = ffrtnm(url,rootname,&status);
	OUTPUT:
		rootname
		status
		RETVAL

int
ffgthd(templt,card,keytype,status)
	char * templt
	char * card = NO_INIT
	int keytype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_template = 1
	CODE:
		card = get_mortalspace(FLEN_CARD,TBYTE);
		RETVAL = ffgthd(templt,card,&keytype,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),keytype);
	OUTPUT:
		card
		status
		RETVAL

int
fits_translate_keyword(inrec, outrec, inpatterns, outpatterns, npat, n_value, n_offset, n_range, pat_num, i, j, m, n, status)
	char* inrec
	char* outrec = NO_INIT
	char** inpatterns
	char** outpatterns
	int npat
	int n_value
	int n_offset
	int n_range
	int pat_num = NO_INIT
	int i = NO_INIT
	int j = NO_INIT
	int m = NO_INIT
	int n = NO_INIT
	int status
	PREINIT:
		char* (*patterns)[2];
		int ii;
	CODE:
		patterns = malloc(npat * sizeof(*patterns));
		for (ii=0; ii<npat; ++ii) {
		    patterns[ii][0] = inpatterns[ii];
		    patterns[ii][1] = outpatterns[ii];
		}
		outrec = get_mortalspace(strlen(inrec)+1,TBYTE);
		RETVAL = fits_translate_keyword(inrec,
						outrec,
						patterns,
						npat,
						n_value,
						n_offset,
						n_range,
						&pat_num,
						&i,
						&j,
						&m,
						&n,
						&status);
		if (ST(1) != &PL_sv_undef) sv_setpv(ST(1),outrec);
		if (ST(8) != &PL_sv_undef) sv_setiv(ST(8),pat_num);
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),i);
		if (ST(10) != &PL_sv_undef) sv_setiv(ST(10),j);
		if (ST(11) != &PL_sv_undef) sv_setiv(ST(11),m);
		if (ST(12) != &PL_sv_undef) sv_setiv(ST(12),n);
		free(patterns);
	OUTPUT:
		status
		RETVAL

int
fits_translate_keywords(infptr, outfptr, firstkey, inpatterns, outpatterns, npat, n_value, n_offset, n_range, status)
	FitsFile* infptr
	FitsFile* outfptr
	int firstkey
	char** inpatterns
	char** outpatterns
	int npat
	int n_value
	int n_offset
	int n_range
	int status
	ALIAS:
		fitsfilePtr::translate_keywords = 1
	PREINIT:
		char* (*patterns)[2];
		int ii;
	CODE:
		patterns = malloc(npat * sizeof(*patterns));
		for (ii=0; ii<npat; ++ii) {
		    patterns[ii][0] = inpatterns[ii];
		    patterns[ii][1] = outpatterns[ii];
		}
		RETVAL = fits_translate_keywords(infptr->fptr,
						 outfptr->fptr,
						 firstkey,
						 patterns,
						 npat,
						 n_value,
						 n_offset,
						 n_range,
						 &status);
		free(patterns);
	OUTPUT:
		status
		RETVAL

int
ffpsvc(card,value,comment,status)
	char * card
	char * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_parse_value = 1
	CODE:
		value = get_mortalspace(FLEN_VALUE,TBYTE);
		comment = get_mortalspace(FLEN_COMMENT,TBYTE);
		RETVAL = ffpsvc(card,value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffwldp(xpix,ypix,xrefval,yrefval,xrefpix,yrefpix,xinc,yinc,rot,coordtype,xpos,ypos,status)
	double xpix
	double ypix
	double xrefval
	double yrefval
	double xrefpix
	double yrefpix
	double xinc
	double yinc
	double rot
	char * coordtype
	double &xpos = NO_INIT
	double &ypos = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_pix_to_world = 1
	OUTPUT:
		xpos
		ypos
		status

int
ffg2db(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	byte nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	byte * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_byt = 1
		fitsfilePtr::read_2d_byt = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TBYTE));
			RETVAL=ffg2db(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(byte*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TBYTE);
			RETVAL=ffg2db(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TBYTE,fptr->perlyunpacking);
		}
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2dsb(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	byte nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	signed char* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_sbyt = 1
		fitsfilePtr::read_2d_sbyt = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TSBYTE));
			RETVAL=ffg2dsb(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(signed char*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TSBYTE);
			RETVAL=ffg2dsb(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TSBYTE,fptr->perlyunpacking);
		}
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2dui(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	unsigned short nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	unsigned short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_usht = 1
		fitsfilePtr::read_2d_usht = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TUSHORT));
			RETVAL=ffg2dui(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(unsigned short*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TUSHORT);
			RETVAL=ffg2dui(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TUSHORT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2di(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	short nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_sht = 1
		fitsfilePtr::read_2d_sht = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TSHORT));
			RETVAL=ffg2di(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(short*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TSHORT);
			RETVAL=ffg2di(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TSHORT,fptr->perlyunpacking);
		}
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2duk(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	unsigned int nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	unsigned int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_uint = 1
		fitsfilePtr::read_2d_uint = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TUINT));
			RETVAL=ffg2duk(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(unsigned int*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TUINT);
			RETVAL=ffg2duk(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TUINT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2dk(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	int nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_int = 1
		fitsfilePtr::read_2d_int = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TINT));
			RETVAL=ffg2dk(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(int*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TINT);
			RETVAL=ffg2dk(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TINT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2duj(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	unsigned long nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	unsigned long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_ulng = 1
		fitsfilePtr::read_2d_ulng = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TULONG));
			RETVAL=ffg2duj(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(unsigned long*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TULONG);
			RETVAL=ffg2duj(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TULONG,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2dj(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	long nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_lng = 1
		fitsfilePtr::read_2d_lng = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TLONG));
			RETVAL=ffg2dj(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(long*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TLONG);
			RETVAL=ffg2dj(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TLONG,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2djj(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	long nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_lnglng = 1
		fitsfilePtr::read_2d_lnglng = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TLONGLONG));
			RETVAL=ffg2djj(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(LONGLONG*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TLONGLONG);
			RETVAL=ffg2djj(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TLONGLONG,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2de(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	float nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	float * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_flt = 1
		fitsfilePtr::read_2d_flt = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TFLOAT));
			RETVAL=ffg2de(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(float*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TFLOAT);
			RETVAL=ffg2de(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TFLOAT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg2dd(fptr,group,nulval,dim1,naxis1,naxis2,array,anynul,status)
	FitsFile * fptr
	long group
	double nulval
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	double * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_2d_dbl = 1
		fitsfilePtr::read_2d_dbl = 2
	PREINIT:
		LONGLONG dims[2];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),naxis2*dim1*sizeof_datatype(TDOUBLE));
			RETVAL=ffg2dd(fptr->fptr,group,nulval,dim1,naxis1,naxis2,(double*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis2; dims[1] = dim1;
			array = get_mortalspace(naxis2*dim1,TDOUBLE);
			RETVAL=ffg2dd(fptr->fptr,group,nulval,dim1,naxis1,naxis2,array,&anynul,&status);
			unpack2D(ST(6),array,dims,TDOUBLE,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3db(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	byte nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	byte * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_byt = 1
		fitsfilePtr::read_3d_byt = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TBYTE));
			RETVAL=ffg3db(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(byte*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TBYTE);
			RETVAL=ffg3db(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TBYTE,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3dsb(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	signed char nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	signed char* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_sbyt = 1
		fitsfilePtr::read_3d_sbyt = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TSBYTE));
			RETVAL=ffg3dsb(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(signed char*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TSBYTE);
			RETVAL=ffg3dsb(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TSBYTE,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3dui(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	unsigned short nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	unsigned short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_usht = 1
		fitsfilePtr::read_3d_usht = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TUSHORT));
			RETVAL=ffg3dui(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(unsigned short*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TUSHORT);
			RETVAL=ffg3dui(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TUSHORT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3di(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	short nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_sht = 1
		fitsfilePtr::read_3d_sht = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TSHORT));
			RETVAL=ffg3di(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(short*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TSHORT);
			RETVAL=ffg3di(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TSHORT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3duk(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	unsigned int nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	unsigned int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_uint = 1
		fitsfilePtr::read_3d_uint = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TUINT));
			RETVAL=ffg3duk(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(unsigned int*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TUINT);
			RETVAL=ffg3duk(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TUINT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3dk(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	int nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_int = 1
		fitsfilePtr::read_3d_int = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TINT));
			RETVAL=ffg3dk(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(int*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TINT);
			RETVAL=ffg3dk(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TINT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3duj(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	unsigned long nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	unsigned long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_ulng = 1
		fitsfilePtr::read_3d_ulng = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TULONG));
			RETVAL=ffg3duj(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(unsigned long*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TULONG);
			RETVAL=ffg3duj(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TULONG,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3dj(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	long nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_lng = 1
		fitsfilePtr::read_3d_lng = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TLONG));
			RETVAL=ffg3dj(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(long*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TLONG);
			RETVAL=ffg3dj(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TLONG,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3djj(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	LONGLONG* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_lnglng = 1
		fitsfilePtr::read_3d_lnglng = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TLONGLONG));
			RETVAL=ffg3djj(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(LONGLONG*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TLONGLONG);
			RETVAL=ffg3djj(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TLONGLONG,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3de(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	float nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	float * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_flt = 1
		fitsfilePtr::read_3d_flt = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TFLOAT));
			RETVAL=ffg3de(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(float*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TFLOAT);
			RETVAL=ffg3de(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TFLOAT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffg3dd(fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,anynul,status)
	FitsFile * fptr
	long group
	double nulval
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	double * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_3d_dbl = 1
		fitsfilePtr::read_3d_dbl = 2
	PREINIT:
		LONGLONG dims[3];
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),naxis3*dim2*dim1*sizeof_datatype(TDOUBLE));
			RETVAL=ffg3dd(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,(double*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			dims[0]=naxis3; dims[1] = dim2; dims[2] = dim1;
			array = get_mortalspace(dim1*dim2*naxis3,TDOUBLE);
			RETVAL=ffg3dd(fptr->fptr,group,nulval,dim1,dim2,naxis1,naxis2,naxis3,array,&anynul,&status);
			unpack3D(ST(8),array,dims,TDOUBLE,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcdw(fptr, colnum, dispwidth, status)
	fitsfile *fptr
	int colnum
	int &dispwidth = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_col_display_width = 1
		fitsfilePtr::get_col_display_width = 2
	OUTPUT:
		dispwidth
		status

int
ffghtb(fptr,rowlen,nrows,tfields,ttype,tbcol,tform,tunit,extname,status)
	FitsFile * fptr
	long rowlen = NO_INIT
	long nrows = NO_INIT
	int tfields = NO_INIT
	char ** ttype = NO_INIT
	long * tbcol = NO_INIT
	char ** tform = NO_INIT
	char ** tunit = NO_INIT
	char * extname = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_atblhdr = 1
		fitsfilePtr::read_atblhdr = 2
	PREINIT:
		int i;
	CODE:
		ffghtb(fptr->fptr,0,&rowlen,&nrows,&tfields,NULL,NULL,NULL,NULL,NULL,&status);

		tbcol = (ST(5)!=&PL_sv_undef) ? get_mortalspace(tfields,TLONG) : NULL;
		extname = (ST(8)!=&PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		if (ST(4)!=&PL_sv_undef) {
			ttype = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				ttype[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else ttype = NULL;
		if (ST(6)!=&PL_sv_undef) {
			tform = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tform[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tform = NULL;
		if (ST(7)!=&PL_sv_undef) {
			tunit = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tunit[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tunit = NULL;

		RETVAL=ffghtb(fptr->fptr,tfields,&rowlen,&nrows,&tfields,ttype,tbcol,tform,tunit,extname,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),rowlen);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),nrows);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),tfields);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),ttype,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),tbcol,tfields,TLONG,fptr->perlyunpacking);
		if (ST(6)!=&PL_sv_undef) unpack1D(ST(6),tform,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(7)!=&PL_sv_undef) unpack1D(ST(7),tunit,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(8)!=&PL_sv_undef) sv_setpv(ST(8),extname);
	OUTPUT:
		status
		RETVAL

int
ffghtbll(fptr,rowlen,nrows,tfields,ttype,tbcol,tform,tunit,extname,status)
	FitsFile * fptr
	LONGLONG rowlen = NO_INIT
	LONGLONG nrows = NO_INIT
	int tfields = NO_INIT
	char ** ttype = NO_INIT
	LONGLONG * tbcol = NO_INIT
	char ** tform = NO_INIT
	char ** tunit = NO_INIT
	char * extname = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_atblhdrll = 1
		fitsfilePtr::read_atblhdrll = 2
	PREINIT:
		int i;
	CODE:
		ffghtbll(fptr->fptr,0,&rowlen,&nrows,&tfields,NULL,NULL,NULL,NULL,NULL,&status);

		tbcol = (ST(5)!=&PL_sv_undef) ? get_mortalspace(tfields,TLONGLONG) : NULL;
		extname = (ST(8)!=&PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		if (ST(4)!=&PL_sv_undef) {
			ttype = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				ttype[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else ttype = NULL;
		if (ST(6)!=&PL_sv_undef) {
			tform = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tform[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tform = NULL;
		if (ST(7)!=&PL_sv_undef) {
			tunit = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tunit[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tunit = NULL;

		RETVAL=ffghtbll(fptr->fptr,tfields,&rowlen,&nrows,&tfields,ttype,tbcol,tform,tunit,extname,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),rowlen);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),nrows);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),tfields);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),ttype,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),tbcol,tfields,TLONGLONG,fptr->perlyunpacking);
		if (ST(6)!=&PL_sv_undef) unpack1D(ST(6),tform,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(7)!=&PL_sv_undef) unpack1D(ST(7),tunit,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(8)!=&PL_sv_undef) sv_setpv(ST(8),extname);
	OUTPUT:
		status
		RETVAL

int
ffghbn(fptr,nrows,tfields,ttype,tform,tunit,extname,pcount,status)
	FitsFile * fptr
	long nrows = NO_INIT
	int tfields = NO_INIT
	char ** ttype = NO_INIT
	char ** tform = NO_INIT
	char ** tunit = NO_INIT
	char * extname = NO_INIT
	long pcount = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_btblhdr = 1
		fitsfilePtr::read_btblhdr = 2
	PREINIT:
		int i;
	CODE:
		ffghbn(fptr->fptr,0,&nrows,&tfields,NULL,NULL,NULL,NULL,&pcount,&status);
		extname = (ST(7)!=&PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		if (ST(4) != &PL_sv_undef) {
			ttype = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				ttype[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else ttype = NULL;
		if (ST(5) != &PL_sv_undef) {
			tform = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tform[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tform = NULL;
		if (ST(6) != &PL_sv_undef) {
			tunit = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tunit[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tunit = NULL;
		RETVAL=ffghbn(fptr->fptr,tfields,&nrows,&tfields,ttype,tform,tunit,extname,&pcount,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),nrows);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),tfields);
		if (ST(3)!=&PL_sv_undef) unpack1D(ST(3),ttype,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),tform,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),tunit,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(6)!=&PL_sv_undef) sv_setpv(ST(6),extname);
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),pcount);
	OUTPUT:
		status
		RETVAL

int
ffghbnll(fptr,nrows,tfields,ttype,tform,tunit,extname,pcount,status)
	FitsFile * fptr
	LONGLONG nrows = NO_INIT
	int tfields = NO_INIT
	char ** ttype = NO_INIT
	char ** tform = NO_INIT
	char ** tunit = NO_INIT
	char * extname = NO_INIT
	LONGLONG pcount = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_btblhdrll = 1
		fitsfilePtr::read_btblhdrll = 2
	PREINIT:
		int i;
	CODE:
		ffghbnll(fptr->fptr,0,&nrows,&tfields,NULL,NULL,NULL,NULL,&pcount,&status);
		extname = (ST(7)!=&PL_sv_undef) ? get_mortalspace(FLEN_VALUE,TBYTE) : NULL;
		if (ST(4) != &PL_sv_undef) {
			ttype = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				ttype[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else ttype = NULL;
		if (ST(5) != &PL_sv_undef) {
			tform = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tform[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tform = NULL;
		if (ST(6) != &PL_sv_undef) {
			tunit = get_mortalspace(tfields,TSTRING);
			for (i=0; i<tfields; i++)
				tunit[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		} else tunit = NULL;
		RETVAL=ffghbnll(fptr->fptr,tfields,&nrows,&tfields,ttype,tform,tunit,extname,&pcount,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),nrows);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),tfields);
		if (ST(3)!=&PL_sv_undef) unpack1D(ST(3),ttype,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),tform,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),tunit,tfields,TSTRING,fptr->perlyunpacking);
		if (ST(6)!=&PL_sv_undef) sv_setpv(ST(6),extname);
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),pcount);
	OUTPUT:
		status
		RETVAL

int
ffgcrd(fptr,keyname,card,status)
	fitsfile * fptr
	char * keyname
	char * card = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_card = 1
		fitsfilePtr::read_card = 2
	CODE:
		card = get_mortalspace(FLEN_CARD,TBYTE);
		RETVAL=ffgcrd(fptr,keyname,card,&status);
	OUTPUT:
		card
		status
		RETVAL

int
ffgcv(fptr,datatype,colnum,firstrow,firstelem,nelements,nulval,array,anynul,status)
	FitsFile * fptr
	int datatype
	int colnum
	LONGLONG firstrow
	LONGLONG firstelem
	LONGLONG nelements
	SV * nulval
	void * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col = 1
		fitsfilePtr::read_col = 2
	PREINIT:
		long col_width;
		LONGLONG i;
		int storage_datatype;
	CODE:
		storage_datatype = datatype;
		if (datatype == TBIT)
			storage_datatype = TLOGICAL;
		if (!PERLYUNPACKING(fptr->perlyunpacking) && datatype != TSTRING) {
			SvGROW(ST(7),nelements*sizeof_datatype(storage_datatype));
			RETVAL=ffgcv(fptr->fptr,datatype,colnum,firstrow,firstelem,nelements,pack1D(nulval,storage_datatype),(void*)SvPV(ST(7),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelements,storage_datatype);
			if (datatype == TSTRING) {
				col_width = column_width(fptr->fptr,colnum);
				for (i=0;i<nelements;i++)
					*((char**)array+i)=get_mortalspace(col_width+1,TBYTE);
			}
			RETVAL=ffgcv(fptr->fptr,datatype,colnum,firstrow,firstelem,nelements,pack1D(nulval,storage_datatype),array,&anynul,&status);
			unpack1D(ST(7),array,nelements,storage_datatype,fptr->perlyunpacking);
		}
		if (ST(8) != &PL_sv_undef) sv_setiv(ST(8),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcx(fptr,colnum,frow,fbit,nbit,larray,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG fbit
	LONGLONG nbit
	logical * larray = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_bit = 1
		fitsfilePtr::read_col_bit = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nbit*sizeof_datatype(TLOGICAL));
			RETVAL = ffgcx(fptr->fptr,colnum,frow,fbit,nbit,(logical*)SvPV(ST(5),PL_na),&status);
		}
		else {
			larray = get_mortalspace(nbit,TLOGICAL);
			RETVAL=ffgcx(fptr->fptr,colnum,frow,fbit,nbit,larray,&status);
			unpack1D(ST(5),larray,nbit,TLOGICAL,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffgcxui(fptr,colnum,frow,nrows,fbit,nbits,array,status)
	FitsFile *fptr
	int colnum
	LONGLONG frow
	LONGLONG nrows
	long fbit
	int nbits
	unsigned short *array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_bit_usht = 1
		fitsfilePtr::read_col_bit_usht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nrows*sizeof_datatype(TUSHORT));
			RETVAL = ffgcxui(fptr->fptr,colnum,frow,nrows,fbit,nbits,(unsigned short*)SvPV(ST(6),PL_na),&status);
		}
		else {
			array = get_mortalspace(nrows,TUSHORT);
			RETVAL = ffgcxui(fptr->fptr,colnum,frow,nrows,fbit,nbits,array,&status);
			unpack1D(ST(6),array,nrows,TUSHORT,fptr->perlyunpacking);
		}
	OUTPUT:
		RETVAL
		status

int
ffgcxuk(fptr,colnum,frow,nrows,fbit,nbits,array,status)
	FitsFile *fptr
	int colnum
	LONGLONG frow
	LONGLONG nrows
	long fbit
	int nbits
	unsigned int *array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_bit_uint = 1
		fitsfilePtr::read_col_bit_uint = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nrows*sizeof_datatype(TUINT));
			RETVAL = ffgcxuk(fptr->fptr,colnum,frow,nrows,fbit,nbits,(unsigned int*)SvPV(ST(6),PL_na),&status);
		}
		else {
			array = get_mortalspace(nrows,TUINT);
			RETVAL = ffgcxuk(fptr->fptr,colnum,frow,nrows,fbit,nbits,array,&status);
			unpack1D(ST(6),array,nrows,TUINT,fptr->perlyunpacking);
		}
	OUTPUT:
		RETVAL
		status

int
ffgcvs(fptr,colnum,firstrow,firstelem,nelements,nulstr,array,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG firstrow
	LONGLONG firstelem
	LONGLONG nelements
	char * nulstr
	char ** array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_str = 1
		fitsfilePtr::read_col_str = 2
	PREINIT:
		LONGLONG i;
		long col_size;
	CODE:
		col_size = column_width(fptr->fptr,colnum);
		array = get_mortalspace(nelements,TSTRING);
		for (i=0;i<nelements;i++)
			array[i] = get_mortalspace(col_size+1,TBYTE);
		RETVAL=ffgcvs(fptr->fptr,colnum,firstrow,firstelem,nelements,nulstr,array,&anynul,&status);
		unpack1D(ST(6),array,nelements,TSTRING,fptr->perlyunpacking);
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvl(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	logical nulval
	logical * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_log = 1
		fitsfilePtr::read_col_log = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
			RETVAL=ffgcvl(fptr->fptr,cnum,frow,felem,nelem,nulval,(logical*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcvl(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvb(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	byte nulval
	byte * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_byt = 1
		fitsfilePtr::read_col_byt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TBYTE));
			RETVAL=ffgcvb(fptr->fptr,cnum,frow,felem,nelem,nulval,(byte*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TBYTE);
			RETVAL=ffgcvb(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TBYTE,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvsb(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	signed char nulval
	signed char* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_sbyt = 1
		fitsfilePtr::read_col_sbyt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TSBYTE));
			RETVAL=ffgcvsb(fptr->fptr,cnum,frow,felem,nelem,nulval,(signed char*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSBYTE);
			RETVAL=ffgcvsb(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TSBYTE,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvui(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned short nulval
	unsigned short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_usht = 1
		fitsfilePtr::read_col_usht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TUSHORT));
			RETVAL=ffgcvui(fptr->fptr,cnum,frow,felem,nelem,nulval,(unsigned short*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUSHORT);
			RETVAL=ffgcvui(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TUSHORT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvi(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	short nulval
	short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_sht = 1
		fitsfilePtr::read_col_sht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TSHORT));
			RETVAL=ffgcvi(fptr->fptr,cnum,frow,felem,nelem,nulval,(short*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSHORT);
			RETVAL=ffgcvi(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TSHORT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvuk(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned int nulval
	unsigned int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_uint = 1
		fitsfilePtr::read_col_uint = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TUINT));
			RETVAL=ffgcvuk(fptr->fptr,cnum,frow,felem,nelem,nulval,(unsigned int*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUINT);
			RETVAL=ffgcvuk(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TUINT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvk(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	int nulval
	int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_int = 1
		fitsfilePtr::read_col_int = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TINT));
			RETVAL=ffgcvk(fptr->fptr,cnum,frow,felem,nelem,nulval,(int*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TINT);
			RETVAL=ffgcvk(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TINT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvuj(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned long nulval
	unsigned long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_ulng = 1
		fitsfilePtr::read_col_ulng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TULONG));
			RETVAL=ffgcvuj(fptr->fptr,cnum,frow,felem,nelem,nulval,(unsigned long*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TULONG);
			RETVAL=ffgcvuj(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TULONG,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvj(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	long nulval
	long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_lng = 1
		fitsfilePtr::read_col_lng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TLONG));
			RETVAL=ffgcvj(fptr->fptr,cnum,frow,felem,nelem,nulval,(long*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONG);
			RETVAL=ffgcvj(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TLONG,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvjj(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	LONGLONG nulval
	LONGLONG* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_lnglng = 1
		fitsfilePtr::read_col_lnglng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TLONGLONG));
			RETVAL=ffgcvjj(fptr->fptr,cnum,frow,felem,nelem,nulval,(LONGLONG*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONGLONG);
			RETVAL=ffgcvjj(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TLONGLONG,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcve(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float nulval
	float * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_flt = 1
		fitsfilePtr::read_col_flt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TFLOAT));
			RETVAL=ffgcve(fptr->fptr,cnum,frow,felem,nelem,nulval,(float*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TFLOAT);
			RETVAL=ffgcve(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TFLOAT,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvd(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double nulval
	double * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_dbl = 1
		fitsfilePtr::read_col_dbl = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TDOUBLE));
			RETVAL=ffgcvd(fptr->fptr,cnum,frow,felem,nelem,nulval,(double*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TDOUBLE);
			RETVAL=ffgcvd(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TDOUBLE,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvc(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float nulval
	float * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_cmp = 1
		fitsfilePtr::read_col_cmp = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TCOMPLEX));
			RETVAL=ffgcvc(fptr->fptr,cnum,frow,felem,nelem,nulval,(float*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TCOMPLEX);
			RETVAL=ffgcvc(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TCOMPLEX,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcvm(fptr,cnum,frow,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double nulval
	double * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_col_dblcmp = 1
		fitsfilePtr::read_col_dblcmp = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),nelem*sizeof_datatype(TDBLCOMPLEX));
			RETVAL=ffgcvm(fptr->fptr,cnum,frow,felem,nelem,nulval,(double*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TDBLCOMPLEX);
			RETVAL=ffgcvm(fptr->fptr,cnum,frow,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(6),array,nelem,TDBLCOMPLEX,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcf(fptr,datatype,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int datatype
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	void * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull = 1
		fitsfilePtr::read_colnull = 2
	PREINIT:
		int storage_datatype;
	CODE:
		storage_datatype = datatype;
		if (datatype == TBIT)
			storage_datatype = TLOGICAL;
		if (!PERLYUNPACKING(fptr->perlyunpacking) && datatype != TSTRING) {
			if (ST(6)!=&PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(storage_datatype));
				array = (void*)SvPV(ST(6),PL_na);
			}
			else
				array = get_mortalspace(nelem,storage_datatype);
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(7),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcf(fptr->fptr,datatype,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,storage_datatype);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcf(fptr->fptr,datatype,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(6)!=&PL_sv_undef)
				unpack1D(ST(6),array,nelem,storage_datatype,fptr->perlyunpacking);
			if (ST(7)!=&PL_sv_undef)
				unpack1D(ST(7),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(8)!=&PL_sv_undef)
			sv_setiv(ST(8),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfs(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	char ** array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_str = 1
		fitsfilePtr::read_colnull_str = 2
	PREINIT:
		long col_size;
		LONGLONG i;
	CODE:
		col_size = column_width(fptr->fptr,colnum);
		array = get_mortalspace(nelem,TSTRING);
		for (i=0;i<nelem;i++)
			array[i] = get_mortalspace(col_size+1,TBYTE);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);

			RETVAL=ffgcfs(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfs(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TSTRING,fptr->perlyunpacking);
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfl(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	logical * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_log = 1
		fitsfilePtr::read_colnull_log = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				array = (logical*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TLOGICAL);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfl(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLOGICAL);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfl(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TLOGICAL,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfb(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	byte * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_byt = 1
		fitsfilePtr::read_colnull_byt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TBYTE));
				array = (byte*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TBYTE);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfb(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TBYTE);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfb(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TBYTE,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfsb(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	signed char* array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_sbyt = 1
		fitsfilePtr::read_colnull_sbyt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TSBYTE));
				array = (signed char*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TSBYTE);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfsb(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSBYTE);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfsb(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TSBYTE,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfui(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned short * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_usht = 1
		fitsfilePtr::read_colnull_usht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TUSHORT));
				array = (unsigned short*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TUSHORT);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfui(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUSHORT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfui(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TUSHORT,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfi(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	short * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_sht = 1
		fitsfilePtr::read_colnull_sht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TSHORT));
				array = (short*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TSHORT);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfi(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSHORT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfi(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TSHORT,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfk(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	int * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_int = 1
		fitsfilePtr::read_colnull_int = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TINT));
				array = (int*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TINT);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfk(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TINT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfk(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TINT,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfuk(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned int * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_uint = 1
		fitsfilePtr::read_colnull_uint = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TUINT));
				array = (unsigned int*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TUINT);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfuk(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUINT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfuk(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TUINT,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfj(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	long * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_lng = 1
		fitsfilePtr::read_colnull_lng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLONG));
				array = (long*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TLONG);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfj(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONG);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfj(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TLONG,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfjj(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	LONGLONG* array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_lnglng = 1
		fitsfilePtr::read_colnull_lnglng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLONGLONG));
				array = (LONGLONG*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TLONGLONG);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfjj(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONGLONG);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfjj(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TLONGLONG,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfuj(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned long * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_ulng = 1
		fitsfilePtr::read_colnull_ulng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TULONG));
				array = (unsigned long*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TULONG);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfuj(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TULONG);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfuj(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TULONG,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfe(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_flt = 1
		fitsfilePtr::read_colnull_flt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TFLOAT));
				array = (float*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TFLOAT);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfe(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TFLOAT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfe(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TFLOAT,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfd(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_dbl = 1
		fitsfilePtr::read_colnull_dbl = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TDOUBLE));
				array = (double*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TDOUBLE);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfd(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TDOUBLE);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfd(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TDOUBLE,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfc(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_cmp = 1
		fitsfilePtr::read_colnull_cmp = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TCOMPLEX));
				array = (float*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TCOMPLEX);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfc(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TCOMPLEX);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfc(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TCOMPLEX,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgcfm(fptr,colnum,frow,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_colnull_dblcmp = 1
		fitsfilePtr::read_colnull_dblcmp = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TDBLCOMPLEX));
				array = (double*)SvPV(ST(5),PL_na);
			}
			else
				array = get_mortalspace(nelem,TDBLCOMPLEX);
			if (ST(6) != &PL_sv_undef) {
				SvGROW(ST(6),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(6),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfm(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TDBLCOMPLEX);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgcfm(fptr->fptr,colnum,frow,felem,nelem,array,nularray,&anynul,&status);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),array,nelem,TDBLCOMPLEX,fptr->perlyunpacking);
			if (ST(6) != &PL_sv_undef) unpack1D(ST(6),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef) sv_setiv(ST(7),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgdes(fptr,colnum,rownum,repeat,offset,status)
	fitsfile * fptr
	int colnum
	LONGLONG rownum
	long repeat = NO_INIT
	long offset = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_descript = 1
		fitsfilePtr::read_descript = 2
	CODE:
		RETVAL = ffgdes(fptr,colnum,rownum,&repeat,&offset,&status);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),repeat);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),offset);
	OUTPUT:
		status
		RETVAL

int
ffgdesll(fptr,colnum,rownum,repeat,offset,status)
	fitsfile * fptr
	int colnum
	LONGLONG rownum
	LONGLONG repeat = NO_INIT
	LONGLONG offset = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_descriptll = 1
		fitsfilePtr::read_descriptll = 2
	CODE:
		RETVAL = ffgdesll(fptr,colnum,rownum,&repeat,&offset,&status);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),repeat);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),offset);
	OUTPUT:
		status
		RETVAL

int
ffgdess(fptr,colnum,frow,nrows,repeat,offset,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG nrows
	long * repeat = NO_INIT
	long * offset = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_descripts = 1
		fitsfilePtr::read_descripts = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nrows*sizeof_datatype(TLONG));
				repeat = (long*)SvPV(ST(4),PL_na);
			}
			else
				repeat = get_mortalspace(nrows,TLONG);

			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nrows*sizeof_datatype(TLONG));
				offset = (long*)SvPV(ST(5),PL_na);
			}
			else
				offset = get_mortalspace(nrows,TLONG);
			RETVAL=ffgdess(fptr->fptr,colnum,frow,nrows,repeat,offset,&status);
		}
		else {
			repeat = get_mortalspace(nrows,TLONG);
			offset = get_mortalspace(nrows,TLONG);
			RETVAL=ffgdess(fptr->fptr,colnum,frow,nrows,repeat,offset,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),repeat,nrows,TLONG,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),offset,nrows,TLONG,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffgdessll(fptr,colnum,frow,nrows,repeat,offset,status)
	FitsFile * fptr
	int colnum
	LONGLONG frow
	LONGLONG nrows
	LONGLONG* repeat = NO_INIT
	LONGLONG* offset = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_descriptsll = 1
		fitsfilePtr::read_descriptsll = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nrows*sizeof_datatype(TLONGLONG));
				repeat = (LONGLONG*)SvPV(ST(4),PL_na);
			}
			else
				repeat = get_mortalspace(nrows,TLONGLONG);

			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nrows*sizeof_datatype(TLONGLONG));
				offset = (LONGLONG*)SvPV(ST(5),PL_na);
			}
			else
				offset = get_mortalspace(nrows,TLONGLONG);
			RETVAL=ffgdessll(fptr->fptr,colnum,frow,nrows,repeat,offset,&status);
		}
		else {
			repeat = get_mortalspace(nrows,TLONGLONG);
			offset = get_mortalspace(nrows,TLONGLONG);
			RETVAL=ffgdessll(fptr->fptr,colnum,frow,nrows,repeat,offset,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),repeat,nrows,TLONGLONG,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),offset,nrows,TLONGLONG,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffgmsg(err_msg)
	char * err_msg = NO_INIT
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_errmsg = 1
	CODE:
		err_msg = get_mortalspace(FLEN_ERRMSG,TBYTE);
		RETVAL = fits_read_errmsg(err_msg);
	OUTPUT:
		err_msg
		RETVAL

int
ffggpb(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	byte * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_byt = 1
		fitsfilePtr::read_grppar_byt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TBYTE));
			RETVAL=ffggpb(fptr->fptr,group,felem,nelem,(byte*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TBYTE);
			RETVAL=ffggpb(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TBYTE,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpsb(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	signed char* array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_sbyt = 1
		fitsfilePtr::read_grppar_sbyt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TSBYTE));
			RETVAL=ffggpsb(fptr->fptr,group,felem,nelem,(signed char*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TSBYTE);
			RETVAL=ffggpsb(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TSBYTE,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpi(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	short * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_sht = 1
		fitsfilePtr::read_grppar_sht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TSHORT));
			RETVAL=ffggpi(fptr->fptr,group,felem,nelem,(short*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TSHORT);
			RETVAL=ffggpi(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TSHORT,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpui(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	unsigned short * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_usht = 1
		fitsfilePtr::read_grppar_usht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TUSHORT));
			RETVAL=ffggpui(fptr->fptr,group,felem,nelem,(unsigned short*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TUSHORT);
			RETVAL=ffggpui(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TUSHORT,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpk(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	int * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_int = 1
		fitsfilePtr::read_grppar_int = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TINT));
			RETVAL=ffggpk(fptr->fptr,group,felem,nelem,(int*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TINT);
			RETVAL=ffggpk(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TINT,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpuk(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	unsigned int * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_uint = 1
		fitsfilePtr::read_grppar_uint = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TUINT));
			RETVAL=ffggpuk(fptr->fptr,group,felem,nelem,(unsigned int*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TUINT);
			RETVAL=ffggpuk(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TUINT,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpj(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	long * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_lng = 1
		fitsfilePtr::read_grppar_lng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TLONG));
			RETVAL=ffggpj(fptr->fptr,group,felem,nelem,(long*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TLONG);
			RETVAL=ffggpj(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TLONG,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpjj(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	LONGLONG* array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_lnglng = 1
		fitsfilePtr::read_grppar_lnglng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TLONGLONG));
			RETVAL=ffggpjj(fptr->fptr,group,felem,nelem,(LONGLONG*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TLONGLONG);
			RETVAL=ffggpjj(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TLONGLONG,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpuj(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	unsigned long * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_ulng = 1
		fitsfilePtr::read_grppar_ulng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TULONG));
			RETVAL=ffggpuj(fptr->fptr,group,felem,nelem,(unsigned long*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TULONG);
			RETVAL=ffggpuj(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TULONG,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpe(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	float * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_flt = 1
		fitsfilePtr::read_grppar_flt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TFLOAT));
			RETVAL=ffggpe(fptr->fptr,group,felem,nelem,(float*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TFLOAT);
			RETVAL=ffggpe(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TFLOAT,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffggpd(fptr,group,felem,nelem,array,status)
	FitsFile * fptr
	long group
	long felem
	long nelem
	double * array = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_grppar_dbl = 1
		fitsfilePtr::read_grppar_dbl = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nelem*sizeof_datatype(TDOUBLE));
			RETVAL=ffggpd(fptr->fptr,group,felem,nelem,(double*)SvPV(ST(4),PL_na),&status);
		}
		else {
			array = get_mortalspace(nelem,TDOUBLE);
			RETVAL=ffggpd(fptr->fptr,group,felem,nelem,array,&status);
			unpack1D(ST(4),array,nelem,TDOUBLE,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffgpv(fptr,datatype,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	int datatype
	LONGLONG felem
	LONGLONG nelem
	SV * nulval
	void * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img = 1
		fitsfilePtr::read_img = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(datatype));
			RETVAL=ffgpv(fptr->fptr,datatype,felem,nelem,pack1D(nulval,datatype),(void*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,datatype);
			RETVAL=ffgpv(fptr->fptr,datatype,felem,nelem,pack1D(nulval,datatype),array,&anynul,&status);
			unpack1D(ST(5),array,nelem,datatype,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgics(fptr,xrefval,yrefval,xrefpix,yrefpix,xinc,yinc,rot,coordtype,status)
	fitsfile * fptr
	double xrefval = NO_INIT
	double yrefval = NO_INIT
	double xrefpix = NO_INIT
	double yrefpix = NO_INIT
	double xinc = NO_INIT
	double yinc = NO_INIT
	double rot = NO_INIT
	char * coordtype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_coord = 1
		fitsfilePtr::read_img_coord = 2
	CODE:
		coordtype = get_mortalspace(FLEN_VALUE,TBYTE);
		RETVAL=ffgics(fptr,&xrefval,&yrefval,&xrefpix,&yrefpix,&xinc,&yinc,&rot,coordtype,&status);
		if (ST(1) != &PL_sv_undef) sv_setnv(ST(1),xrefval);
		if (ST(2) != &PL_sv_undef) sv_setnv(ST(2),yrefval);
		if (ST(3) != &PL_sv_undef) sv_setnv(ST(3),xrefpix);
		if (ST(4) != &PL_sv_undef) sv_setnv(ST(4),yrefpix);
		if (ST(5) != &PL_sv_undef) sv_setnv(ST(5),xinc);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),yinc);
		if (ST(7) != &PL_sv_undef) sv_setnv(ST(7),rot);
	OUTPUT:
		coordtype
		status
		RETVAL

int
ffgicsa(fptr,version,xrefval,yrefval,xrefpix,yrefpix,xinc,yinc,rot,coordtype,status)
	fitsfile * fptr
	char version
	double xrefval = NO_INIT
	double yrefval = NO_INIT
	double xrefpix = NO_INIT
	double yrefpix = NO_INIT
	double xinc = NO_INIT
	double yinc = NO_INIT
	double rot = NO_INIT
	char * coordtype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_coord_version = 1
		fitsfilePtr::read_img_coord_version = 2
	CODE:
		coordtype = get_mortalspace(FLEN_VALUE,TBYTE);
		RETVAL=ffgics(fptr,&xrefval,&yrefval,&xrefpix,&yrefpix,&xinc,&yinc,&rot,coordtype,&status);
		if (ST(2) != &PL_sv_undef) sv_setnv(ST(2),xrefval);
		if (ST(3) != &PL_sv_undef) sv_setnv(ST(3),yrefval);
		if (ST(4) != &PL_sv_undef) sv_setnv(ST(4),xrefpix);
		if (ST(5) != &PL_sv_undef) sv_setnv(ST(5),yrefpix);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),xinc);
		if (ST(7) != &PL_sv_undef) sv_setnv(ST(7),yinc);
		if (ST(8) != &PL_sv_undef) sv_setnv(ST(8),rot);
	OUTPUT:
		coordtype
		status
		RETVAL

int
ffgpvb(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	byte nulval
	byte * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_byt = 1
		fitsfilePtr::read_img_byt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TBYTE));
			RETVAL=ffgpvb(fptr->fptr,group,felem,nelem,nulval,(byte*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TBYTE);
			RETVAL=ffgpvb(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TBYTE,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvsb(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	signed char nulval
	signed char* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_sbyt = 1
		fitsfilePtr::read_img_sbyt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TSBYTE));
			RETVAL=ffgpvsb(fptr->fptr,group,felem,nelem,nulval,(signed char*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSBYTE);
			RETVAL=ffgpvsb(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TSBYTE,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvi(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	short nulval
	short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_sht = 1
		fitsfilePtr::read_img_sht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TSHORT));
			RETVAL=ffgpvi(fptr->fptr,group,felem,nelem,nulval,(short*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSHORT);
			RETVAL=ffgpvi(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TSHORT,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvui(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned short nulval
	unsigned short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_usht = 1
		fitsfilePtr::read_img_usht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TUSHORT));
			RETVAL=ffgpvui(fptr->fptr,group,felem,nelem,nulval,(unsigned short*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUSHORT);
			RETVAL=ffgpvui(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TUSHORT,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvk(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	int nulval
	int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_int = 1
		fitsfilePtr::read_img_int = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TINT));
			RETVAL=ffgpvk(fptr->fptr,group,felem,nelem,nulval,(int*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TINT);
			RETVAL=ffgpvk(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TINT,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvuk(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned int nulval
	unsigned int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_uint = 1
		fitsfilePtr::read_img_uint = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TUINT));
			RETVAL=ffgpvuk(fptr->fptr,group,felem,nelem,nulval,(unsigned int*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUINT);
			RETVAL=ffgpvuk(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TUINT,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvj(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	long nulval
	long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_lng = 1
		fitsfilePtr::read_img_lng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TLONG));
			RETVAL=ffgpvj(fptr->fptr,group,felem,nelem,nulval,(long*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONG);
			RETVAL=ffgpvj(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TLONG,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvjj(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	LONGLONG nulval
	LONGLONG* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_lnglng = 1
		fitsfilePtr::read_img_lnglng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TLONGLONG));
			RETVAL=ffgpvjj(fptr->fptr,group,felem,nelem,nulval,(LONGLONG*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONGLONG);
			RETVAL=ffgpvjj(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TLONGLONG,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvuj(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned long nulval
	unsigned long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_ulng = 1
		fitsfilePtr::read_img_ulng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TULONG));
			RETVAL=ffgpvuj(fptr->fptr,group,felem,nelem,nulval,(unsigned long*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TULONG);
			RETVAL=ffgpvuj(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TULONG,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpve(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	float nulval
	float * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_flt = 1
		fitsfilePtr::read_img_flt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TFLOAT));
			RETVAL=ffgpve(fptr->fptr,group,felem,nelem,nulval,(float*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TFLOAT);
			RETVAL=ffgpve(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TFLOAT,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpvd(fptr,group,felem,nelem,nulval,array,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	double nulval
	double * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_img_dbl = 1
		fitsfilePtr::read_img_dbl = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(TDOUBLE));
			RETVAL=ffgpvd(fptr->fptr,group,felem,nelem,nulval,(double*)SvPV(ST(5),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TDOUBLE);
			RETVAL=ffgpvd(fptr->fptr,group,felem,nelem,nulval,array,&anynul,&status);
			unpack1D(ST(5),array,nelem,TDOUBLE,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffghpr(fptr,simple,bitpix,naxis,naxes,pcount,gcount,extend,status)
	FitsFile * fptr
	int simple = NO_INIT
	int bitpix = NO_INIT
	int naxis = NO_INIT
	long * naxes = NO_INIT
	long pcount = NO_INIT
	long gcount = NO_INIT
	int extend = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imghdr = 1
		fitsfilePtr::read_imghdr = 2
	CODE:

		if (ST(4)!=&PL_sv_undef) { /* caller wants naxes to be set */
			ffghpr(fptr->fptr,0,NULL,NULL,&naxis,NULL,NULL,NULL,NULL,&status);
			naxes = get_mortalspace(naxis,TLONG);
		} else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=ffghpr(fptr->fptr,naxis,&simple,&bitpix,&naxis,naxes,&pcount,&gcount,&extend,&status);

		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),simple);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),bitpix);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),naxis);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),naxes,naxis,TLONG,
						  fptr->perlyunpacking);
		if (ST(5)!=&PL_sv_undef) sv_setiv(ST(5),pcount);
		if (ST(6)!=&PL_sv_undef) sv_setiv(ST(6),gcount);
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),extend);
	OUTPUT:
		status
		RETVAL

int
ffghprll(fptr,simple,bitpix,naxis,naxes,pcount,gcount,extend,status)
	FitsFile * fptr
	int simple = NO_INIT
	int bitpix = NO_INIT
	int naxis = NO_INIT
	LONGLONG * naxes = NO_INIT
	long pcount = NO_INIT
	long gcount = NO_INIT
	int extend = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imghdrll = 1
		fitsfilePtr::read_imghdrll = 2
	CODE:

		if (ST(4)!=&PL_sv_undef) { /* caller wants naxes to be set */
			ffghprll(fptr->fptr,0,NULL,NULL,&naxis,NULL,NULL,NULL,NULL,&status);
			naxes = get_mortalspace(naxis,TLONGLONG);
		} else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=ffghprll(fptr->fptr,naxis,&simple,&bitpix,&naxis,naxes,&pcount,&gcount,&extend,&status);

		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),simple);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),bitpix);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),naxis);
		if (ST(4)!=&PL_sv_undef) unpack1D(ST(4),naxes,naxis,TLONGLONG,
						  fptr->perlyunpacking);
		if (ST(5)!=&PL_sv_undef) sv_setiv(ST(5),pcount);
		if (ST(6)!=&PL_sv_undef) sv_setiv(ST(6),gcount);
		if (ST(7)!=&PL_sv_undef) sv_setiv(ST(7),extend);
	OUTPUT:
		status
		RETVAL

int
ffgpf(fptr,datatype,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	int datatype
	LONGLONG felem
	LONGLONG nelem
	void * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull = 1
		fitsfilePtr::read_imgnull = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4)!=&PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(datatype));
				array = (void*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,datatype);
			if (ST(5)!=&PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpf(fptr->fptr,datatype,felem,nelem,array,nularray,&anynul,&status);

		}
		else {
			array = get_mortalspace(nelem,datatype);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpf(fptr->fptr,datatype,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4)!=&PL_sv_undef)
				unpack1D(ST(4),array,nelem,datatype,fptr->perlyunpacking);
			if (ST(5)!=&PL_sv_undef)
				unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6)!=&PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfb(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	byte * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_byt = 1
		fitsfilePtr::read_imgnull_byt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TBYTE));
				array = (byte*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TBYTE);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfb(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TBYTE);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfb(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TBYTE,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfsb(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	signed char* array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_sbyt = 1
		fitsfilePtr::read_imgnull_sbyt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TSBYTE));
				array = (signed char*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TSBYTE);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfsb(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSBYTE);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfsb(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TSBYTE,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfi(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	short * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_sht = 1
		fitsfilePtr::read_imgnull_sht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TSHORT));
				array = (short*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TSHORT);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfi(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TSHORT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfi(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TSHORT,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfui(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned short * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_usht = 1
		fitsfilePtr::read_imgnull_usht = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TUSHORT));
				array = (unsigned short*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TUSHORT);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfui(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUSHORT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfui(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TUSHORT,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfk(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	int * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_int = 1
		fitsfilePtr::read_imgnull_int = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TINT));
				array = (int*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TINT);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfk(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TINT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfk(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TINT,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfuk(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned int * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_uint = 1
		fitsfilePtr::read_imgnull_uint = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TUINT));
				array = (unsigned int*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TUINT);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfuk(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TUINT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfuk(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TUINT,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfj(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	long * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_lng = 1
		fitsfilePtr::read_imgnull_lng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TLONG));
				array = (long*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TLONG);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfj(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONG);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfj(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TLONG,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfjj(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	LONGLONG* array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_lnglng = 1
		fitsfilePtr::read_imgnull_lnglng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TLONGLONG));
				array = (LONGLONG*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TLONGLONG);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfjj(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TLONGLONG);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfjj(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TLONGLONG,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfuj(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned long * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_ulng = 1
		fitsfilePtr::read_imgnull_ulng = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TULONG));
				array = (unsigned long*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TULONG);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfuj(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TULONG);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfuj(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TBYTE,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfe(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	float * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_flt = 1
		fitsfilePtr::read_imgnull_flt = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TFLOAT));
				array = (float*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TFLOAT);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfe(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TFLOAT);
			nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfe(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TFLOAT,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpfd(fptr,group,felem,nelem,array,nularray,anynul,status)
	FitsFile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	double * array = NO_INIT
	logical * nularray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_imgnull_dbl = 1
		fitsfilePtr::read_imgnull_dbl = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(TDOUBLE));
				array = (double*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem,TDOUBLE);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nularray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nularray = get_mortalspace(nelem,TLOGICAL);
			RETVAL=ffgpfd(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
		}
		else {
			array = get_mortalspace(nelem,TDOUBLE);
			nularray = get_mortalspace(nelem,TLOGICAL);
				RETVAL=ffgpfd(fptr->fptr,group,felem,nelem,array,nularray,&anynul,&status);
			if (ST(4) != &PL_sv_undef) unpack1D(ST(4),array,nelem,TDOUBLE,fptr->perlyunpacking);
			if (ST(5) != &PL_sv_undef) unpack1D(ST(5),nularray,nelem,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgstr(fptr, string, card, status)
	fitsfile * fptr
	char * string
	char * card = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_str = 1
		fitsfilePtr::read_str = 2
	OUTPUT:
		card
		status

int
ffgksl(fptr,keyname,length,status)
	fitsfile * fptr
	const char * keyname
	int &length = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_key_strlen = 1
		fitsfilePtr::get_key_strlen = 2
	OUTPUT:
		length
		status

int
ffgsky(fptr,keyname,firstchar,maxchar,value,valuelen,comm,status)
	fitsfile * fptr
	const char * keyname
	int firstchar
	int maxchar
	char * value = NO_INIT
	int valuelen = NO_INIT
	char * comm = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_string_key = 1
		fitsfilePtr::read_key_string = 2
	CODE:
		value = (ST(4) != &PL_sv_undef) ? get_mortalspace(maxchar+1,TBYTE) : NULL;
		comm = (ST(6) != &PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgsky(fptr,keyname,firstchar,maxchar,value,&valuelen,comm,&status);
		if (ST(5) != &PL_sv_undef) sv_setiv(ST(5),valuelen);
	OUTPUT:
		value
		comm
		status
		RETVAL

int
ffdstr(fptr, string, status)
	fitsfile * fptr
	char * string
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_delete_str = 1
		fitsfilePtr::delete_str = 2
	OUTPUT:
		status

int
ffgky(fptr,datatype,keyname,value,comment,status)
	fitsfile * fptr
	int datatype
	char * keyname
	void * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key = 1
		fitsfilePtr::read_key = 2
	CODE:
		comment=(ST(4)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		switch (datatype) {
			case TSTRING:
				value = get_mortalspace(FLEN_VALUE,TBYTE); break;
			case TLOGICAL:
				value = get_mortalspace(1,TINT); break;
			default:
				value = get_mortalspace(1,datatype);
		}
		RETVAL=ffgky(fptr,datatype,keyname,value,comment,&status);
		if (datatype == TLOGICAL)
			datatype = TINT;
		unpackScalar(ST(3),value,datatype);
	OUTPUT:
		comment
		status
		RETVAL

int
ffgkyt(fptr,keyname,intval,frac,comment,status)
	fitsfile * fptr
	char * keyname
	long intval = NO_INIT
	double frac = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_triple = 1
		fitsfilePtr::read_key_triple = 2
	CODE:
		comment=(ST(4)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyt(fptr,keyname,&intval,&frac,comment,&status);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),intval);
		if (ST(3) != &PL_sv_undef) sv_setnv(ST(3),frac);
	OUTPUT:
		comment
		status
		RETVAL

int
ffgunt(fptr,keyname,unit,status)
	fitsfile * fptr
	char * keyname
	char * unit = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_unit = 1
		fitsfilePtr::read_key_unit = 2
	CODE:
		unit = get_mortalspace(FLEN_VALUE,TBYTE);
		RETVAL=ffgunt(fptr,keyname,unit,&status);
	OUTPUT:
		unit
		status
		RETVAL

int
ffgkcsl(fptr, keyname, length, comlength, status)
	fitsfile * fptr
	const char * keyname
	int &length
	int &comlength
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_key_com_strlen = 1
		fitsfilePtr::get_key_com_strlen = 2
	OUTPUT:
		length
		comlength
		status

int
ffgkls(fptr,keyname,longstr,comment,status)
	fitsfile * fptr
	char * keyname
	char * longstr = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_longstr = 1
		fitsfilePtr::read_key_longstr = 2
	CODE:
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkls(fptr,keyname,&longstr,comment,&status);
		sv_setpv(ST(2),longstr);
		fffree(longstr, &status);
	OUTPUT:
		comment
		status
		RETVAL

int
ffgskyc(fptr,keyname,firstchar,maxchar,maxcomchar,value,valuelen,comm,comlen,status)
	fitsfile *fptr
	const char *keyname
	int firstchar
	int maxchar
	int maxcomchar
	char * value = NO_INIT
	int valuelen = NO_INIT
	char * comm = NO_INIT
	int comlen = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_string_key_com = 1
		fitsfilePtr::read_string_key_com = 2
	CODE:
		value = (ST(5) != &PL_sv_undef) ? get_mortalspace(maxchar+1,TBYTE) : NULL;
		comm = (ST(7) != &PL_sv_undef) ? get_mortalspace(maxcomchar+1,TBYTE) : NULL;
		RETVAL=ffgskyc(fptr,keyname,firstchar,maxchar,maxcomchar,value,&valuelen,comm,&comlen,&status);
		if (ST(6) != &PL_sv_undef) sv_setiv(ST(6),valuelen);
		if (ST(8) != &PL_sv_undef) sv_setiv(ST(8),comlen);
	OUTPUT:
		value
		comm
		status
		RETVAL

int
fffree(value, status)
	void * value
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_free_memory = 1
	OUTPUT:
		status

int
ffgkys(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	char * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_str = 1
		fitsfilePtr::read_key_str = 2
	CODE:
		value = get_mortalspace(FLEN_VALUE,TBYTE);
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkys(fptr,keyname,value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgkyl(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	int value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_log = 1
		fitsfilePtr::read_key_log = 2
	CODE:
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyl(fptr,keyname,&value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgkyj(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	long value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_lng = 1
		fitsfilePtr::read_key_lng = 2
	CODE:
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyj(fptr,keyname,&value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgkyjj(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	LONGLONG value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_lnglng = 1
		fitsfilePtr::read_key_lnglng = 2
	CODE:
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyjj(fptr,keyname,&value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgkye(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	float value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_flt = 1
		fitsfilePtr::read_key_flt = 2
	CODE:
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkye(fptr,keyname,&value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgkyd(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	double value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_dbl = 1
		fitsfilePtr::read_key_dbl = 2
	CODE:
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyd(fptr,keyname,&value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgkyc(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	float * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_cmp = 1
		fitsfilePtr::read_key_cmp = 2
	CODE:
		value = get_mortalspace(1,TCOMPLEX);
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyc(fptr,keyname,value,comment,&status);
		unpackScalar(ST(2),value,TCOMPLEX);
	OUTPUT:
		status
		comment
		RETVAL

int
ffgkym(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	double * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_key_dblcmp = 1
		fitsfilePtr::read_key_dblcmp = 2
	CODE:
		value = get_mortalspace(1,TDBLCOMPLEX);
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkym(fptr,keyname,value,comment,&status);
		unpackScalar(ST(2),value,TDBLCOMPLEX);
	OUTPUT:
		comment
		status
		RETVAL

int
ffgkyn(fptr,keynum,keyname,value,comment,status)
	fitsfile * fptr
	int keynum
	char * keyname = NO_INIT
	char * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keyn = 1
		fitsfilePtr::read_keyn = 2
	CODE:
		keyname = get_mortalspace(FLEN_KEYWORD,TBYTE);
		value = get_mortalspace(FLEN_VALUE,TBYTE);
		comment=(ST(4)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkyn(fptr,keynum,keyname,value,comment,&status);
	OUTPUT:
		keyname
		value
		comment
		status
		RETVAL

int
ffgkns(fptr,keyname,nstart,nkeys,value,nfound,status)
	FitsFile * fptr
	char * keyname
	int nstart
	int nkeys
	char ** value = NO_INIT
	int nfound = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keys_str = 1
		fitsfilePtr::read_keys_str = 2
	PREINIT:
		int i;
	CODE:
		value=get_mortalspace(nkeys,TSTRING);
		for (i=0; i<nkeys; i++)
			value[i] = get_mortalspace(FLEN_VALUE,TBYTE);
		RETVAL=ffgkns(fptr->fptr,keyname,nstart,nkeys,value,&nfound,&status);
		unpack1D(ST(4),value,(nkeys>nfound) ? nfound : nkeys,TSTRING,fptr->perlyunpacking);
	OUTPUT:
		nfound
		status
		RETVAL

int
ffgknl(fptr,keyname,nstart,nkeys,value,nfound,status)
	FitsFile * fptr
	char * keyname
	int nstart
	int nkeys
	int * value = NO_INIT
	int nfound = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keys_log = 1
		fitsfilePtr::read_keys_log = 2
	CODE:
		value=get_mortalspace(nkeys,TINT);
		RETVAL=ffgknl(fptr->fptr,keyname,nstart,nkeys,value,&nfound,&status);
		unpack1D(ST(4),value,(nkeys>nfound) ? nfound : nkeys,TINT,fptr->perlyunpacking);
	OUTPUT:
		nfound
		status
		RETVAL

int
ffgknj(fptr,keyname,nstart,nkeys,value,nfound,status)
	FitsFile * fptr
	char * keyname
	int nstart
	int nkeys
	long * value = NO_INIT
	int nfound = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keys_lng = 1
		fitsfilePtr::read_keys_lng = 2
	CODE:
		value=get_mortalspace(nkeys,TLONG);
		RETVAL=ffgknj(fptr->fptr,keyname,nstart,nkeys,value,&nfound,&status);
		unpack1D(ST(4),value,(nkeys>nfound) ? nfound : nkeys,TLONG,fptr->perlyunpacking);
	OUTPUT:
		nfound
		status
		RETVAL

int
ffgknjj(fptr,keyname,nstart,nkeys,value,nfound,status)
	FitsFile * fptr
	char * keyname
	int nstart
	int nkeys
	LONGLONG * value = NO_INIT
	int nfound = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keys_lnglng = 1
		fitsfilePtr::read_keys_lnglng = 2
	CODE:
		value=get_mortalspace(nkeys,TLONGLONG);
		RETVAL=ffgknjj(fptr->fptr,keyname,nstart,nkeys,value,&nfound,&status);
		unpack1D(ST(4),value,(nkeys>nfound) ? nfound : nkeys,TLONGLONG, fptr->perlyunpacking);
	OUTPUT:
		nfound
		status
		RETVAL

int
ffgkne(fptr,keyname,nstart,nkeys,value,nfound,status)
	FitsFile * fptr
	char * keyname
	int nstart
	int nkeys
	float * value = NO_INIT
	int nfound = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keys_flt = 1
		fitsfilePtr::read_keys_flt = 2
	CODE:
		value=get_mortalspace(nkeys,TFLOAT);
		RETVAL=ffgkne(fptr->fptr,keyname,nstart,nkeys,value,&nfound,&status);
		unpack1D(ST(4),value,(nkeys>nfound) ? nfound : nkeys,TFLOAT,fptr->perlyunpacking);
	OUTPUT:
		nfound
		status
		RETVAL

int
ffgknd(fptr,keyname,nstart,nkeys,value,nfound,status)
	FitsFile * fptr
	char * keyname
	int nstart
	int nkeys
	double * value = NO_INIT
	int nfound = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keys_dbl = 1
		fitsfilePtr::read_keys_dbl = 2
	CODE:
		value=get_mortalspace(nkeys,TDOUBLE);
		RETVAL=ffgknd(fptr->fptr,keyname,nstart,nkeys,value,&nfound,&status);
		unpack1D(ST(4),value,(nkeys>nfound) ? nfound : nkeys,TDOUBLE,fptr->perlyunpacking);
	OUTPUT:
		nfound
		status
		RETVAL

int
ffgkey(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	char * value = NO_INIT
	char * comment = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_keyword = 1
		fitsfilePtr::read_keyword = 2
	CODE:
		value = get_mortalspace(FLEN_VALUE,TBYTE);
		comment=(ST(3)!=&PL_sv_undef) ? get_mortalspace(FLEN_COMMENT,TBYTE) : NULL;
		RETVAL=ffgkey(fptr,keyname,value,comment,&status);
	OUTPUT:
		value
		comment
		status
		RETVAL

int
ffgrec(fptr,keynum,card,status)
	fitsfile * fptr
	int keynum
	char * card = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_record = 1
		fitsfilePtr::read_record = 2
	CODE:
		card = get_mortalspace(FLEN_CARD,TBYTE);
		RETVAL=ffgrec(fptr,keynum,card,&status);
	OUTPUT:
		card
		status
		RETVAL

int
ffgsv(fptr, dtype, blc, trc, inc, nulval, array, anynul, status)
	FitsFile * fptr
	int dtype
	long * blc
	long * trc
	long * inc
	SV * nulval
	void * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset = 1
		fitsfilePtr::read_subset = 2
	PREINIT:
		long ndata, *naxes;
		int i, naxis, storage_dtype;
	CODE:
		storage_dtype = dtype;
		if (dtype == TBIT)
			storage_dtype = TLOGICAL;

		/* get the size of the image */
		RETVAL = ffgidm(fptr->fptr, &naxis, &status);
		naxes = get_mortalspace(naxis, TLONG);
		RETVAL = ffgisz(fptr->fptr, naxis, naxes, &status);

		/* determine the number of pixels to be read */
		ndata = 1;
		for (i=0; i<naxis; i++)
		ndata *= (trc[i]-blc[i]+1)/inc[i] +
			(((trc[i]-blc[i]+1) % inc[i]) ? 1 : 0);

		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(6),ndata*sizeof_datatype(storage_dtype));
			RETVAL=ffgsv(fptr->fptr,dtype,blc,trc,inc,(nulval!=&PL_sv_undef ? pack1D(nulval,storage_dtype) : NULL),(void*)SvPV(ST(6),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,storage_dtype);
			RETVAL=ffgsv(fptr->fptr,dtype,blc,trc,inc,(nulval != &PL_sv_undef ? pack1D(nulval,storage_dtype) : NULL),array,&anynul,&status);
			unpack1D(ST(6),array,ndata,storage_dtype,fptr->perlyunpacking);
		}
		if (ST(7) != &PL_sv_undef)
			sv_setiv(ST(7),anynul);
	OUTPUT:
		RETVAL
		status

int
ffgsvb(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	byte nulval
	byte * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_byt = 1
		fitsfilePtr::read_subset_byt = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TBYTE));
			RETVAL=ffgsvb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(byte*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TBYTE);
			RETVAL=ffgsvb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TBYTE,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvsb(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	signed char nulval
	signed char* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_sbyt = 1
		fitsfilePtr::read_subset_sbyt = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TSBYTE));
			RETVAL=ffgsvsb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(signed char*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TSBYTE);
			RETVAL=ffgsvsb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TSBYTE,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvi(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	short nulval
	short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_sht = 1
		fitsfilePtr::read_subset_sht = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TSHORT));
			RETVAL=ffgsvi(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(short*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TSHORT);
			RETVAL=ffgsvi(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TSHORT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvui(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	unsigned short nulval
	unsigned short * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_usht = 1
		fitsfilePtr::read_subset_usht = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TUSHORT));
			RETVAL=ffgsvui(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(unsigned short*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TUSHORT);
			RETVAL=ffgsvui(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TUSHORT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvk(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	int nulval
	int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_int = 1
		fitsfilePtr::read_subset_int = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TINT));
			RETVAL=ffgsvk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(int*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TINT);
			RETVAL=ffgsvk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TINT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvuk(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	unsigned int nulval
	unsigned int * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_uint = 1
		fitsfilePtr::read_subset_uint = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TUINT));
			RETVAL=ffgsvuk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(unsigned int*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TUINT);
			RETVAL=ffgsvuk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TUINT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvj(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	long nulval
	long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_lng = 1
		fitsfilePtr::read_subset_lng = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TLONG));
			RETVAL=ffgsvj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(long*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TLONG);
			RETVAL=ffgsvj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TLONG,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvjj(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	LONGLONG nulval
	LONGLONG* array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_lnglng = 1
		fitsfilePtr::read_subset_lnglng = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TLONGLONG));
			RETVAL=ffgsvjj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(LONGLONG*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TLONGLONG);
			RETVAL=ffgsvjj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TLONGLONG,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvuj(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	unsigned long nulval
	unsigned long * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_ulng = 1
		fitsfilePtr::read_subset_ulng = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TULONG));
			RETVAL=ffgsvuj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(unsigned long*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TULONG);
			RETVAL=ffgsvuj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TULONG,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsve(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	float nulval
	float * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_flt = 1
		fitsfilePtr::read_subset_flt = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TFLOAT));
			RETVAL=ffgsve(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(float*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TFLOAT);
			RETVAL=ffgsve(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TFLOAT,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsvd(fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	double nulval
	double * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subset_dbl = 1
		fitsfilePtr::read_subset_dbl = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(8),ndata*sizeof_datatype(TDOUBLE));
			RETVAL=ffgsvd(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,(double*)SvPV(ST(8),PL_na),&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TDOUBLE);
			RETVAL=ffgsvd(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,nulval,array,&anynul,&status);
			unpack1D(ST(8),array,ndata,TDOUBLE,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfb(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	byte * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_byt = 1
		fitsfilePtr::read_subsetnull_byt = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TBYTE));
				array = (byte*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TBYTE);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TBYTE);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TBYTE,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfsb(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	signed char* array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_sbyt = 1
		fitsfilePtr::read_subsetnull_sbyt = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TSBYTE));
				array = (signed char*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TSBYTE);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfsb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TSBYTE);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfsb(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TSBYTE,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfi(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	short * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_sht = 1
		fitsfilePtr::read_subsetnull_sht = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TSHORT));
				array = (short*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TSHORT);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfi(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TSHORT);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfi(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TSHORT,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfui(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	unsigned short * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_usht = 1
		fitsfilePtr::read_subsetnull_usht = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TUSHORT));
				array = (unsigned short*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TUSHORT);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfui(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TUSHORT);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfui(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TUSHORT,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfk(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	int * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_int = 1
		fitsfilePtr::read_subsetnull_int = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TINT));
				array = (int*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TINT);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TINT);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TINT,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfuk(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	unsigned int * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_uint = 1
		fitsfilePtr::read_subsetnull_uint = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TUINT));
				array = (unsigned int*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TUINT);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfuk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TUINT);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfuk(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TUINT,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfj(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	long * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_lng = 1
		fitsfilePtr::read_subsetnull_lng = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TLONG));
				array = (long*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TLONG);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TLONG);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TLONG,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfjj(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	LONGLONG* array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_lnglng = 1
		fitsfilePtr::read_subsetnull_lnglng = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TLONGLONG));
				array = (LONGLONG*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TLONGLONG);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfjj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TLONGLONG);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfjj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TLONGLONG,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfuj(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	unsigned long * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_ulng = 1
		fitsfilePtr::read_subsetnull_ulng = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TULONG));
				array = (unsigned long*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TULONG);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfuj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TULONG);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfuj(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TULONG,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfe(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	float * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_flt = 1
		fitsfilePtr::read_subsetnull_flt = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TFLOAT));
				array = (float*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TFLOAT);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfe(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TFLOAT);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfe(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TFLOAT,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgsfd(fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,anynul,status)
	FitsFile * fptr
	int group
	int naxis
	long * naxes
	long * fpixels
	long * lpixels
	long * inc
	double * array = NO_INIT
	logical * nularr = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_subsetnull_dbl = 1
		fitsfilePtr::read_subsetnull_dbl = 2
	PREINIT:
		long ndata;
		int i;
	CODE:
		ndata = 1;
		for (i=0; i<naxis; i++)
			ndata *= (lpixels[i]-fpixels[i]+1)/inc[i] +
				(((lpixels[i]-fpixels[i]+1) % inc[i]) ? 1 : 0);
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(7) != &PL_sv_undef) {
				SvGROW(ST(7),ndata*sizeof_datatype(TDOUBLE));
				array = (double*)SvPV(ST(7),PL_na);
			}
			else
				array = get_mortalspace(ndata,TDOUBLE);
			if (ST(8) != &PL_sv_undef) {
				SvGROW(ST(8),ndata*sizeof_datatype(TLOGICAL));
				nularr = (logical*)SvPV(ST(8),PL_na);
			}
			else
				nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfd(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
		}
		else {
			array = get_mortalspace(ndata,TDOUBLE);
			nularr = get_mortalspace(ndata,TLOGICAL);
			RETVAL=ffgsfd(fptr->fptr,group,naxis,naxes,fpixels,lpixels,inc,array,nularr,&anynul,&status);
			if (ST(7) != &PL_sv_undef) unpack1D(ST(7),array,ndata,TDOUBLE,fptr->perlyunpacking);
			if (ST(8) != &PL_sv_undef) unpack1D(ST(8),nularr,ndata,TLOGICAL,fptr->perlyunpacking);
		}
		if (ST(9) != &PL_sv_undef) sv_setiv(ST(9),anynul);
	OUTPUT:
		status
		RETVAL

int
ffgtcs(fptr,xcol,ycol,xrefval,yrefval,xrefpix,yrefpix,xinc,yinc,rot,coordtype,status)
	fitsfile * fptr
	int xcol
	int ycol
	double xrefval = NO_INIT
	double yrefval = NO_INIT
	double xrefpix = NO_INIT
	double yrefpix = NO_INIT
	double xinc = NO_INIT
	double yinc = NO_INIT
	double rot = NO_INIT
	char * coordtype = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_tbl_coord = 1
		fitsfilePtr::read_tbl_coord = 2
	CODE:
		coordtype = get_mortalspace(FLEN_VALUE,TBYTE);
		RETVAL=ffgtcs(fptr,xcol,ycol,&xrefval,&yrefval,&xrefpix,&yrefpix,&xinc,&yinc,&rot,coordtype,&status);
		if (ST(3) != &PL_sv_undef) sv_setnv(ST(3),xrefval);  /* value-added, all around */
		if (ST(4) != &PL_sv_undef) sv_setnv(ST(4),yrefval);
		if (ST(5) != &PL_sv_undef) sv_setnv(ST(5),xrefpix);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),yrefpix);
		if (ST(7) != &PL_sv_undef) sv_setnv(ST(7),xinc);
		if (ST(8) != &PL_sv_undef) sv_setnv(ST(8),yinc);
		if (ST(9) != &PL_sv_undef) sv_setnv(ST(9),rot);
	OUTPUT:
		coordtype
		status
		RETVAL

int
ffgtbb(fptr,frow,fchar,nchars,values,status)
	FitsFile * fptr
	LONGLONG frow
	LONGLONG fchar
	LONGLONG nchars
	byte * values = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_tblbytes = 1
		fitsfilePtr::read_tblbytes = 2
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(4),nchars*sizeof_datatype(TBYTE));
			RETVAL=ffgtbb(fptr->fptr,frow,fchar,nchars,(byte*)SvPV(ST(4),PL_na),&status);
		}
		else {
			values = get_mortalspace(nchars,TBYTE);
			RETVAL=ffgtbb(fptr->fptr,frow,fchar,nchars,values,&status);
			unpack1D(ST(4),values,nchars,TBYTE,fptr->perlyunpacking);
		}
	OUTPUT:
		status
		RETVAL

int
ffgtdm(fptr,colnum,naxis,naxes,status)
	FitsFile * fptr
	int colnum
	int naxis = NO_INIT
	long * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_tdim = 1
		fitsfilePtr::read_tdim = 2
	CODE:
		if (ST(3)!=&PL_sv_undef) {
			ffgtdm(fptr->fptr,colnum,0,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONG);
		}
		else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=ffgtdm(fptr->fptr,colnum,naxis,&naxis,naxes,&status);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),naxis);
		if (ST(3)!=&PL_sv_undef) unpack1D(ST(3),naxes,naxis,TLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
ffgtdmll(fptr,colnum,naxis,naxes,status)
	FitsFile * fptr
	int colnum
	int naxis = NO_INIT
	LONGLONG * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_tdimll = 1
		fitsfilePtr::read_tdimll = 2
	CODE:
		if (ST(3)!=&PL_sv_undef) {
			ffgtdmll(fptr->fptr,colnum,0,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONGLONG);
		}
		else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=ffgtdmll(fptr->fptr,colnum,naxis,&naxis,naxes,&status);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),naxis);
		if (ST(3)!=&PL_sv_undef) unpack1D(ST(3),naxes,naxis,TLONGLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
ffgtrm(gfptr,rmopt,status)
	fitsfile * gfptr
	int rmopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_remove_group = 1
		fitsfilePtr::remove_group = 2
	OUTPUT:
		status

int
ffgmrm(fptr,member,rmopt,status)
	fitsfile * fptr
	long member
	int rmopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_remove_member = 1
		fitsfilePtr::remove_member = 2
	OUTPUT:
		status

int
ffreopen(openfptr,newfptr,status)
	fitsfile * openfptr
	FitsFile * newfptr = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_reopen_file = 1
		fitsfilePtr::reopen_file = 2
	CODE:
		NewFitsFile(newfptr);
		RETVAL = ffreopen(openfptr,&(newfptr->fptr),&status);
		if (RETVAL)
		   AbortFitsFile(newfptr);
	OUTPUT:
		status
		newfptr
		RETVAL

void
ffrprt(stream, status)
	FILE * stream
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_report_error = 1

int
ffrsim(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	long * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_resize_img = 1
		fitsfilePtr::resize_img = 2
	OUTPUT:
		status

int
ffrsimll(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	LONGLONG * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_resize_imgll = 1
		fitsfilePtr::resize_imgll = 2
	OUTPUT:
		status

int
ffsrow(infptr,outfptr,expr,status)
	fitsfile * infptr
	fitsfile * outfptr
	char * expr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_select_rows = 1
		fitsfilePtr::select_rows = 2
	OUTPUT:
		status

int
ffpscl(fptr,scale,zero,status)
	fitsfile * fptr
	double scale
	double zero
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_bscale = 1
		fitsfilePtr::set_bscale = 2
	OUTPUT:
		status

int
ffsnul(fptr,colnum,nulstr,status)
	fitsfile * fptr
	int colnum
	char * nulstr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_atblnull = 1
		fitsfilePtr::set_atblnull = 2
	OUTPUT:
		status

int
fftnul(fptr,colnum,nulval,status)
	fitsfile * fptr
	int colnum
	LONGLONG nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_btblnull = 1
		fitsfilePtr::set_btblnull = 2
	OUTPUT:
		status

int
fits_set_compression_type(fptr, comptype, status)
	fitsfile *fptr	
	int comptype
	int &status
	ALIAS:
		fitsfilePtr::set_compression_type = 1
	OUTPUT:
		status

int
ffhdef(fptr,morekeys,status)
	fitsfile * fptr
	int morekeys
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_hdrsize = 1
		fitsfilePtr::set_hdrsize = 2
	OUTPUT:
		status

int
ffrdef(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_hdustruc = 1
		fitsfilePtr::set_hdustruc = 2
	OUTPUT:
		status

int
ffpnul(fptr,nulval,status)
	fitsfile * fptr
	LONGLONG nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_imgnull = 1
		fitsfilePtr::set_imgnull = 2
	OUTPUT:
		status

int
fits_set_noise_bits(fptr, noisebits, status)
	fitsfile *fptr	
	int noisebits
	int &status
	ALIAS:
		fitsfilePtr::set_noise_bits = 1
	OUTPUT:
		status

int
fits_set_tile_dim(fptr, ndim, tilesize, status)
	fitsfile *fptr
	int ndim
	long *tilesize
	int &status
	ALIAS:
		fitsfilePtr::set_tile_dim = 1
	OUTPUT:
		status

int
fftscl(fptr,colnum,scale,zero,status)
	fitsfile * fptr
	int colnum
	double scale
	double zero
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_set_tscale = 1
		fitsfilePtr::set_tscale = 2
	OUTPUT:
		status

int
ffs2dt(datestr,year,month,day,status)
	char * datestr
	int year = NO_INIT
	int month = NO_INIT
	int day = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_str2date = 1
	CODE:
		RETVAL = ffs2dt(datestr,&year,&month,&day,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),year);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),month);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),day);
	OUTPUT:
		status
		RETVAL

int
ffs2tm(datestr,year,month,day,hour,minute,second,status)
	char * datestr
	int year = NO_INIT
	int month = NO_INIT
	int day = NO_INIT
	int hour = NO_INIT
	int minute = NO_INIT
	double second = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_str2time = 1
	CODE:
		RETVAL = ffs2tm(datestr,&year,&month,&day,&hour,&minute,&second,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),year);
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),month);
		if (ST(3) != &PL_sv_undef) sv_setiv(ST(3),day);
		if (ST(4) != &PL_sv_undef) sv_setiv(ST(4),hour);
		if (ST(5) != &PL_sv_undef) sv_setiv(ST(5),minute);
		if (ST(6) != &PL_sv_undef) sv_setnv(ST(6),second);
	OUTPUT:
		status
		RETVAL

int
fftexp(fptr,expr,datatype,nelem,naxis,naxes,status)
	FitsFile * fptr
	char * expr
	int datatype = NO_INIT
	long nelem = NO_INIT
	int naxis = NO_INIT
	long * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_test_expr = 1
		fitsfilePtr::test_expr = 2
	CODE:
		if (ST(5)!=&PL_sv_undef) {
			fftexp(fptr->fptr,expr,0,&datatype,&nelem,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONG);
		}
		else {
			naxes = NULL;
			naxis = 0;
		}
		RETVAL=fftexp(fptr->fptr,expr,naxis,&datatype,&nelem,&naxis,naxes,&status);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),datatype);
		if (ST(3)!=&PL_sv_undef) sv_setiv(ST(3),nelem);
		if (ST(4)!=&PL_sv_undef) sv_setiv(ST(4),naxis);
		if (ST(5)!=&PL_sv_undef) unpack1D(ST(5),naxes,naxis,TLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
fftheap(fptr,heapsize,unused,overlap,validheap,status)
	fitsfile * fptr
	LONGLONG &heapsize = NO_INIT
	LONGLONG &unused = NO_INIT
	LONGLONG &overlap = NO_INIT
	int &validheap = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_test_heap = 1
		fitsfilePtr::test_heap = 2
	OUTPUT:
		heapsize
		unused
		overlap
		validheap
		status

int
fftkey(keyname,status)
	char * keyname
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_test_keyword = 1
	OUTPUT:
		status

int
fftrec(card,status)
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_test_record = 1
	OUTPUT:
		status

int
fftm2s(year,month,day,hr,min,sec,decimals,datestr,status)
	int year
	int month
	int day
	int hr
	int min
	double sec
	int decimals
	char * datestr = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_time2str = 1
	PREINIT:
		int datestrlen;
	CODE:
		datestrlen=21; /* YYYY-MM-DDThh:mm:ss.[ddd...] */
		if (decimals > 0) datestrlen += decimals;
		datestr = get_mortalspace(datestrlen,TBYTE);
		RETVAL=fftm2s(year,month,day,hr,min,sec,decimals,datestr,&status);
	OUTPUT:
		datestr
		status
		RETVAL

int
ffgmtf(infptr,outfptr,member,tfopt,status)
	fitsfile * infptr
	fitsfile * outfptr
	long member
	int tfopt
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_transfer_member = 1
		fitsfilePtr::transfer_member = 2
	OUTPUT:
		status

int
ffucrd(fptr,keyname,card,status)
	fitsfile *fptr
	char * keyname
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_card = 1
		fitsfilePtr::update_card = 2
	OUTPUT:
		status

int
ffupck(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_chksum = 1
		fitsfilePtr::update_chksum = 2
	OUTPUT:
		status

int
ffuky(fptr,datatype,keyname,value,comm,status)
	fitsfile * fptr
	int datatype
	char * keyname
	void * value = NO_INIT
	char * comm
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key = 1
		fitsfilePtr::update_key = 2
	CODE:
		value = pack1D(ST(3),(datatype == TLOGICAL) ? TINT : datatype);
		RETVAL=ffuky(fptr,datatype,keyname,value,comm,&status);
	OUTPUT:
		status
		RETVAL

int
ffukyu(fptr,keyname,comment,status)
	fitsfile * fptr
	char * keyname
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_null = 1
		fitsfilePtr::update_key_null = 2
	OUTPUT:
		status

int
ffukys(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	char * value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_str = 1
		fitsfilePtr::update_key_str = 2
	OUTPUT:
		status

int
ffukyl(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	int value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_log = 1
		fitsfilePtr::update_key_log = 2
	OUTPUT:
		status

int
ffukyj(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	LONGLONG value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_lng = 1
		fitsfilePtr::update_key_lng = 2
	OUTPUT:
		status

int
ffukye(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_flt = 1
		fitsfilePtr::update_key_flt = 2
	OUTPUT:
		status

int
ffukyd(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_dbl = 1
		fitsfilePtr::update_key_dbl = 2
	OUTPUT:
		status

int
ffukyf(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_fixflt = 1
		fitsfilePtr::update_key_fixflt = 2
	OUTPUT:
		status

int
ffukyg(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_fixdbl = 1
		fitsfilePtr::update_key_fixdbl = 2
	OUTPUT:
		status

int
ffukyc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_cmp = 1
		fitsfilePtr::update_key_cmp = 2
	OUTPUT:
		status

int
ffukym(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_dblcmp = 1
		fitsfilePtr::update_key_dblcmp = 2
	OUTPUT:
		status

int
ffukfc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	cmp * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_fixcmp = 1
		fitsfilePtr::update_key_fixcmp = 2
	OUTPUT:
		status

int
ffukfm(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	dblcmp * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_fixdblcmp = 1
		fitsfilePtr::update_key_fixdblcmp = 2
	OUTPUT:
		status

void
ffupch(string)
	char * string
	ALIAS:
		Astro::FITS::CFITSIO::fits_uppercase = 1
	OUTPUT:
		string

int
ffurlt(fptr,urlType,status)
	fitsfile *fptr
	char *urlType = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_url_type = 1
		fitsfilePtr::url_type = 2
	CODE:
		urlType = get_mortalspace(FLEN_FILENAME,TBYTE);
		RETVAL = ffurlt(fptr,urlType,&status);
	OUTPUT:
		urlType
		status
		RETVAL
		
	
int
ffvcks(fptr,dataok,hduok,status)
	fitsfile * fptr
	int dataok = NO_INIT
	int hduok = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_verify_chksum = 1
		fitsfilePtr::verify_chksum = 2
	CODE:
		RETVAL = ffvcks(fptr,&dataok,&hduok,&status);
		if (ST(1) != &PL_sv_undef) sv_setiv(ST(1),dataok); /* value-added */
		if (ST(2) != &PL_sv_undef) sv_setiv(ST(2),hduok); /* value-added */
	OUTPUT:
		status
		RETVAL

int
ffgtvf(gfptr,firstfailed,status)
	fitsfile * gfptr
	long &firstfailed = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_verify_group = 1
		fitsfilePtr::verify_group = 2
	OUTPUT:
		firstfailed
		status

int
ffxypx(xpos,ypos,xrefval,yrefval,xrefpix,yrefpix,xinc,yinc,rot,coordtype,xpix,ypix,status)
	double xpos
	double ypos
	double xrefval
	double yrefval
	double xrefpix
	double yrefpix
	double xinc
	double yinc
	double rot
	char * coordtype
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_world_to_pix = 1
	OUTPUT:
		xpix
		ypix
		status

int
ffp2db(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	byte * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_byt = 1
		fitsfilePtr::write_2d_byt = 2
	OUTPUT:
		status

int
ffp2dsb(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	signed char* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_sbyt = 1
		fitsfilePtr::write_2d_sbyt = 2
	OUTPUT:
		status

int
ffp2di(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_sht = 1
		fitsfilePtr::write_2d_sht = 2
	OUTPUT:
		status

int
ffp2dui(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	unsigned short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_usht = 1
		fitsfilePtr::write_2d_usht = 2
	OUTPUT:
		status

int
ffp2dk(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_int = 1
		fitsfilePtr::write_2d_int = 2
	OUTPUT:
		status

int
ffp2duk(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	unsigned int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_uint = 1
		fitsfilePtr::write_2d_uint = 2
	OUTPUT:
		status

int
ffp2dj(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_lng = 1
		fitsfilePtr::write_2d_lng = 2
	OUTPUT:
		status

int
ffp2djj(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_lnglng = 1
		fitsfilePtr::write_2d_lnglng = 2
	OUTPUT:
		status

int
ffp2duj(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	unsigned long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_ulng = 1
		fitsfilePtr::write_2d_ulng = 2
	OUTPUT:
		status

int
ffp2de(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_flt = 1
		fitsfilePtr::write_2d_flt = 2
	OUTPUT:
		status

int
ffp2dd(fptr,group,dim1,naxis1,naxis2,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG naxis1
	LONGLONG naxis2
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_2d_dbl = 1
		fitsfilePtr::write_2d_dbl = 2
	OUTPUT:
		status

int
ffp3db(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	byte * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_byt = 1
		fitsfilePtr::write_3d_byt = 2
	OUTPUT:
		status

int
ffp3dsb(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	signed char* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_sbyt = 1
		fitsfilePtr::write_3d_sbyt = 2
	OUTPUT:
		status

int
ffp3di(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_sht = 1
		fitsfilePtr::write_3d_sht = 2
	OUTPUT:
		status

int
ffp3dui(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	unsigned short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_usht = 1
		fitsfilePtr::write_3d_usht = 2
	OUTPUT:
		status

int
ffp3dk(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_int = 1
		fitsfilePtr::write_3d_int = 2
	OUTPUT:
		status

int
ffp3duk(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	unsigned int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_uint = 1
		fitsfilePtr::write_3d_uint = 2
	OUTPUT:
		status

int
ffp3dj(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_lng = 1
		fitsfilePtr::write_3d_lng = 2
	OUTPUT:
		status

int
ffp3djj(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	LONGLONG* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_lnglng = 1
		fitsfilePtr::write_3d_lnglng = 2
	OUTPUT:
		status

int
ffp3duj(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	unsigned long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_ulng = 1
		fitsfilePtr::write_3d_ulng = 2
	OUTPUT:
		status

int
ffp3de(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_flt = 1
		fitsfilePtr::write_3d_flt = 2
	OUTPUT:
		status

int
ffp3dd(fptr,group,dim1,dim2,naxis1,naxis2,naxis3,array,status)
	fitsfile * fptr
	long group
	LONGLONG dim1
	LONGLONG dim2
	LONGLONG naxis1
	LONGLONG naxis2
	LONGLONG naxis3
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_3d_dbl = 1
		fitsfilePtr::write_3d_dbl = 2
	OUTPUT:
		status

int
ffphtb(fptr,rowlen,nrows,tfields,ttype,tbcol,tform,tunit,extname,status)
	fitsfile * fptr
	LONGLONG rowlen
	LONGLONG nrows
	int tfields
	char ** ttype
	long * tbcol
	char ** tform
	char ** tunit
	char * extname
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_atblhdr = 1
		fitsfilePtr::write_atblhdr = 2
	OUTPUT:
		status

int
ffphbn(fptr,nrows,tfields,ttype,tform,tunit,extname,pcount,status)
	fitsfile * fptr
	LONGLONG nrows
	int tfields
	char ** ttype
	char ** tform
	char ** tunit
	char * extname
	LONGLONG pcount
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_btblhdr = 1
		fitsfilePtr::write_btblhdr = 2
	OUTPUT:
		status

int
ffphext(fptr, xtension, bitpix, naxis, naxes, pcount, gcount, status)
	fitsfile * fptr
	char * xtension
	int bitpix
	int naxis
	long * naxes
	LONGLONG pcount
	LONGLONG gcount
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_exthdr = 1
		fitsfilePtr::write_exthdr = 2
	OUTPUT:
		status

int
ffpcks(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_chksum = 1
		fitsfilePtr::write_chksum = 2
	OUTPUT:
		status

int
ffprwu(fptr,firstrow,nelem,status)
	fitsfile * fptr
	LONGLONG firstrow
	LONGLONG nelem
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_nullrows = 1
		fitsfilePtr::write_nullrows = 2
	OUTPUT:
		status

int
ffpclu(fptr,colnum,frow,felem,nelem,status)
	fitsfile * fptr
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_null = 1
		fitsfilePtr::write_col_null = 2
	OUTPUT:
		status

int
ffpcl(fptr,datatype,colnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int datatype
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	SV * array
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col = 1
		fitsfilePtr::write_col = 2
	PREINIT:
		int storage_datatype;
	CODE:
		storage_datatype = datatype;
		if (datatype == TBIT)
			storage_datatype = TLOGICAL;
		RETVAL=ffpcl(fptr,datatype,colnum,frow,felem,nelem,packND(array,storage_datatype),&status);
	OUTPUT:
		status
		RETVAL

int
ffpclx(fptr,cnum,frow,fbit,nbits,larray,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	long fbit
	long nbits
	logical * larray
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_bit = 1
		fitsfilePtr::write_col_bit = 2
	OUTPUT:
		status

int
ffpcls(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	char ** array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_str = 1
		fitsfilePtr::write_col_str = 2
	OUTPUT:
		status

int
ffpcll(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	logical * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_log = 1
		fitsfilePtr::write_col_log = 2
	OUTPUT:
		status

int
ffpclb(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	byte * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_byt = 1
		fitsfilePtr::write_col_byt = 2
	OUTPUT:
		status

int
ffpclsb(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	signed char* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_sbyt = 1
		fitsfilePtr::write_col_sbyt = 2
	OUTPUT:
		status

int
ffpclui(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_usht = 1
		fitsfilePtr::write_col_usht = 2
	OUTPUT:
		status

int
ffpcli(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_sht = 1
		fitsfilePtr::write_col_sht = 2
	OUTPUT:
		status

int
ffpcluk(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_uint = 1
		fitsfilePtr::write_col_uint = 2
	OUTPUT:
		status

int
ffpclk(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_int = 1
		fitsfilePtr::write_col_int = 2
	OUTPUT:
		status

int
ffpcluj(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_ulng = 1
		fitsfilePtr::write_col_ulng = 2
	OUTPUT:
		status

int
ffpclj(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_lng = 1
		fitsfilePtr::write_col_lng = 2
	OUTPUT:
		status

int
ffpcljj(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	LONGLONG* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_lnglng = 1
		fitsfilePtr::write_col_lnglng = 2
	OUTPUT:
		status

int
ffpcle(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_flt = 1
		fitsfilePtr::write_col_flt = 2
	OUTPUT:
		status

int
ffpcld(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_dbl = 1
		fitsfilePtr::write_col_dbl = 2
	OUTPUT:
		status

int
ffpclc(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_cmp = 1
		fitsfilePtr::write_col_cmp = 2
	OUTPUT:
		status

int
ffpclm(fptr,cnum,frow,felem,nelem,array,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_col_dblcmp = 1
		fitsfilePtr::write_col_dblcmp = 2
	OUTPUT:
		status

int
ffpcn(fptr,datatype,colnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int datatype
	int colnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	SV * array
	SV * nulval
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull = 1
		fitsfilePtr::write_colnull = 2
	PREINIT:
		int storage_datatype;
	CODE:
		storage_datatype = datatype;
		if (datatype == TBIT)
			storage_datatype = TLOGICAL;
		RETVAL=ffpcn(
			fptr,
			datatype,
			colnum,
			frow, felem, nelem,
			packND(array,storage_datatype),
			(nulval!=&PL_sv_undef) ? pack1D(nulval, storage_datatype) : NULL,
			&status);
	OUTPUT:
		status
		RETVAL

int
ffpcns(fptr,cnum,frow,felem,nelem,array,nulstr,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	char ** array
	char * nulstr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_str = 1
		fitsfilePtr::write_colnull_str = 2
	OUTPUT:
		status

int
ffpcnl(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	logical * array
	logical nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_log = 1
		fitsfilePtr::write_colnull_log = 2
	OUTPUT:
		status

int
ffpcnb(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	byte * array
	byte nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_byt = 1
		fitsfilePtr::write_colnull_byt = 2
	OUTPUT:
		status

int
ffpcnsb(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	signed char* array
	signed char nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_sbyt = 1
		fitsfilePtr::write_colnull_sbyt = 2
	OUTPUT:
		status

int
ffpcnui(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned short * array
	unsigned short nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_usht = 1
		fitsfilePtr::write_colnull_usht = 2
	OUTPUT:
		status

int
ffpcni(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	short * array
	short nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_sht = 1
		fitsfilePtr::write_colnull_sht = 2
	OUTPUT:
		status

int
ffpcnuk(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned int * array
	unsigned int nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_uint = 1
		fitsfilePtr::write_colnull_uint = 2
	OUTPUT:
		status

int
ffpcnk(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	int * array
	int nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_int = 1
		fitsfilePtr::write_colnull_int = 2
	OUTPUT:
		status

int
ffpcnuj(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	unsigned long * array
	unsigned long nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_ulng = 1
		fitsfilePtr::write_colnull_ulng = 2
	OUTPUT:
		status

int
ffpcnj(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	long * array
	long nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_lng = 1
		fitsfilePtr::write_colnull_lng = 2
	OUTPUT:
		status

int
ffpcnjj(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	LONGLONG* array
	LONGLONG nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_lnglng = 1
		fitsfilePtr::write_colnull_lnglng = 2
	OUTPUT:
		status

int
ffpcne(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	float * array
	float nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_flt = 1
		fitsfilePtr::write_colnull_flt = 2
	OUTPUT:
		status

int
ffpcnd(fptr,cnum,frow,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int cnum
	LONGLONG frow
	LONGLONG felem
	LONGLONG nelem
	double * array
	double nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_colnull_dbl = 1
		fitsfilePtr::write_colnull_dbl = 2
	OUTPUT:
		status

int
ffpcom(fptr,comment,status)
	fitsfile * fptr
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_comment = 1
		fitsfilePtr::write_comment = 2
	OUTPUT:
		status

int
ffpdat(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_date = 1
		fitsfilePtr::write_date = 2
	OUTPUT:
		status

int
ffpdes(fptr,colnum,rownum,repeat,offset,status)
	fitsfile * fptr
	int colnum
	LONGLONG rownum
	LONGLONG repeat
	LONGLONG offset
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_descript = 1
		fitsfilePtr::write_descript = 2
	OUTPUT:
		status

void
ffpmsg(err_msg)
	char * err_msg
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_errmsg = 1

int
ffpgpb(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	byte * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_byt = 1
		fitsfilePtr::write_grppar_byt = 2
	OUTPUT:
		status

int
ffpgpsb(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	signed char* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_sbyt = 1
		fitsfilePtr::write_grppar_sbyt = 2
	OUTPUT:
		status

int
ffpgpui(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	unsigned short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_usht = 1
		fitsfilePtr::write_grppar_usht = 2
	OUTPUT:
		status

int
ffpgpi(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_sht = 1
		fitsfilePtr::write_grppar_sht = 2
	OUTPUT:
		status

int
ffpgpuk(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	unsigned int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_uint = 1
		fitsfilePtr::write_grppar_uint = 2
	OUTPUT:
		status

int
ffpgpk(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_int = 1
		fitsfilePtr::write_grppar_int = 2
	OUTPUT:
		status

int
ffpgpuj(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	unsigned long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_ulng = 1
		fitsfilePtr::write_grppar_ulng = 2
	OUTPUT:
		status

int
ffpgpj(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_lng = 1
		fitsfilePtr::write_grppar_lng = 2
	OUTPUT:
		status

int
ffpgpjj(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	LONGLONG* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_lnglng = 1
		fitsfilePtr::write_grppar_lnglng = 2
	OUTPUT:
		status

int
ffpgpe(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_flt = 1
		fitsfilePtr::write_grppar_flt = 2
	OUTPUT:
		status

int
ffpgpd(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	long felem
	long nelem
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grppar_dbl = 1
		fitsfilePtr::write_grppar_dbl = 2
	OUTPUT:
		status

int
ffphis(fptr,history,status)
	fitsfile * fptr
	char * history
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_history = 1
		fitsfilePtr::write_history = 2
	OUTPUT:
		status

int
ffppr(fptr,datatype,firstelem,nelem,array,status)
	fitsfile * fptr
	int datatype
	LONGLONG firstelem
	LONGLONG nelem
	SV * array
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img = 1
		fitsfilePtr::write_img = 2
	CODE:
		RETVAL=ffppr(fptr,datatype,firstelem,nelem,packND(array,datatype),&status);
	OUTPUT:
		status
		RETVAL

int
ffppru(fptr,group,felem,nelem,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_null = 1
		fitsfilePtr::write_img_null = 2
	OUTPUT:
		status

int
ffpprb(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	byte * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_byt = 1
		fitsfilePtr::write_img_byt = 2
	OUTPUT:
		status

int
ffpprsb(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	signed char* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_sbyt = 1
		fitsfilePtr::write_img_sbyt = 2
	OUTPUT:
		status

int
ffpprui(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	unsigned short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_usht = 1
		fitsfilePtr::write_img_usht = 2
	OUTPUT:
		status

int
ffppri(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_sht = 1
		fitsfilePtr::write_img_sht = 2
	OUTPUT:
		status

int
ffppruk(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	unsigned int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_uint = 1
		fitsfilePtr::write_img_uint = 2
	OUTPUT:
		status

int
ffpprk(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_int = 1
		fitsfilePtr::write_img_int = 2
	OUTPUT:
		status

int
ffppruj(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	unsigned long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_ulng = 1
		fitsfilePtr::write_img_ulng = 2
	OUTPUT:
		status

int
ffpprj(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_lng = 1
		fitsfilePtr::write_img_lng = 2
	OUTPUT:
		status

int
ffpprjj(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	LONGLONG* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_lnglng = 1
		fitsfilePtr::write_img_lnglng = 2
	OUTPUT:
		status

int
ffppre(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_flt = 1
		fitsfilePtr::write_img_flt = 2
	OUTPUT:
		status

int
ffpprd(fptr,group,felem,nelem,array,status)
	fitsfile * fptr
	long group
	LONGLONG nelem
	LONGLONG felem
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_img_dbl = 1
		fitsfilePtr::write_img_dbl = 2
	OUTPUT:
		status

int
ffphps(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	long * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imghdr = 1
		fitsfilePtr::write_imghdr = 2
	OUTPUT:
		status

int
ffphpsll(fptr,bitpix,naxis,naxes,status)
	fitsfile * fptr
	int bitpix
	int naxis
	LONGLONG * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imghdrll = 1
		fitsfilePtr::write_imghdrll = 2
	OUTPUT:
		status

int
ffphpr(fptr,simple,bitpix,naxis,naxes,pcount,gcount,extend,status)
	fitsfile * fptr
	int simple
	int bitpix
	int naxis
	long * naxes
	LONGLONG pcount
	LONGLONG gcount
	int extend
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grphdr = 1
		fitsfilePtr::write_grphdr = 2
	OUTPUT:
		status

int
ffphprll(fptr,simple,bitpix,naxis,naxes,pcount,gcount,extend,status)
	fitsfile * fptr
	int simple
	int bitpix
	int naxis
	LONGLONG* naxes
	LONGLONG pcount
	LONGLONG gcount
	int extend
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_grphdrll = 1
		fitsfilePtr::write_grphdrll = 2
	OUTPUT:
		status

int
ffppn(fptr,datatype,felem,nelem,array,nulval,status)
	fitsfile * fptr
	int datatype
	LONGLONG felem
	LONGLONG nelem
	SV * array
	SV * nulval
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull = 1
		fitsfilePtr::write_imgnull = 2
	CODE:
		RETVAL=ffppn(fptr,datatype,felem,nelem,packND(array,datatype),pack1D(nulval,datatype),&status);
	OUTPUT:
		status
		RETVAL

int
ffppnb(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	byte * array
	byte nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_byt = 1
		fitsfilePtr::write_imgnull_byt = 2
	OUTPUT:
		status

int
ffppnsb(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	signed char* array
	signed char nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_sbyt = 1
		fitsfilePtr::write_imgnull_sbyt = 2
	OUTPUT:
		status

int
ffppnui(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned short * array
	unsigned short nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_usht = 1
		fitsfilePtr::write_imgnull_usht = 2
	OUTPUT:
		status

int
ffppni(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	short * array
	short nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_sht = 1
		fitsfilePtr::write_imgnull_sht = 2
	OUTPUT:
		status

int
ffppnuk(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned int * array
	unsigned int nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_uint = 1
		fitsfilePtr::write_imgnull_uint = 2
	OUTPUT:
		status

int
ffppnk(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	int * array
	int nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_int = 1
		fitsfilePtr::write_imgnull_int = 2
	OUTPUT:
		status

int
ffppnuj(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	unsigned long * array
	unsigned long nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_ulng = 1
		fitsfilePtr::write_imgnull_ulng = 2
	OUTPUT:
		status

int
ffppnj(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	long * array
	long nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_lng = 1
		fitsfilePtr::write_imgnull_lng = 2
	OUTPUT:
		status

int
ffppnjj(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	LONGLONG* array
	LONGLONG nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_lnglng = 1
		fitsfilePtr::write_imgnull_lnglng = 2
	OUTPUT:
		status

int
ffppne(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	float * array
	float nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_flt = 1
		fitsfilePtr::write_imgnull_flt = 2
	OUTPUT:
		status

int
ffppnd(fptr,group,felem,nelem,array,nulval,status)
	fitsfile * fptr
	long group
	LONGLONG felem
	LONGLONG nelem
	double * array
	double nulval
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_imgnull_dbl = 1
		fitsfilePtr::write_imgnull_dbl = 2
	OUTPUT:
		status

int
ffpky(fptr,datatype,keyname,value,comment,status)
	fitsfile * fptr
	int datatype
	char * keyname
	void * value = NO_INIT
	char * comment
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key = 1
		fitsfilePtr::write_key = 2
	CODE:
		value = pack1D(ST(3),(datatype == TLOGICAL) ? TINT : datatype);
		RETVAL=ffpky(fptr,datatype,keyname,value,comment,&status);
	OUTPUT:
		status
		RETVAL

int
ffpkls(fptr,keyname,longstr,comment,status)
	fitsfile * fptr
	char * keyname
	char * longstr
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_longstr = 1
		fitsfilePtr::write_key_longstr = 2
	OUTPUT:
		status

int
ffukls(fptr,keynam,value,comm,status)
	fitsfile * fptr
	char * keynam
	char * value
	char * comm
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_update_key_longstr = 1
		fitsfilePtr::update_key_longstr = 2
	OUTPUT:
		status

int
ffikls(fptr,keynam,value,comm,status)
	fitsfile * fptr
	char * keynam
	char * value
	char * comm
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_insert_key_longstr = 1
		fitsfilePtr::insert_key_longstr = 2
	OUTPUT:
		status

int
ffmkls(fptr,keynam,value,comm,status)
	fitsfile * fptr
	char * keynam
	char * value
	char * comm
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_modify_key_longstr = 1
		fitsfilePtr::modify_key_longstr = 2
	OUTPUT:
		status

int
ffplsw(fptr,status)
	fitsfile * fptr
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_longwarn = 1
		fitsfilePtr::write_key_longwarn = 2
	OUTPUT:
		status

int
ffpkyu(fptr,keyname,comment,status)
	fitsfile * fptr
	char * keyname
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_null = 1
		fitsfilePtr::write_key_null = 2
	OUTPUT:
		status

int
ffpktp(fptr,filename,status)
	fitsfile * fptr
	char * filename
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_template = 1
		fitsfilePtr::write_key_template = 2
	OUTPUT:
		status

int
ffpkyt(fptr,keyname,intval,frac,comment,status)
	fitsfile * fptr
	char * keyname
	long intval
	double frac
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_triple = 1
		fitsfilePtr::write_key_triple = 2
	OUTPUT:
		status

int
ffpunt(fptr,keyname,unit,status)
	fitsfile * fptr
	char * keyname
	char * unit
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_unit = 1
		fitsfilePtr::write_key_unit = 2
	OUTPUT:
		status

int
ffpkys(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	char * value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_str = 1
		fitsfilePtr::write_key_str = 2
	OUTPUT:
		status

int
ffpkyl(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	int value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_log = 1
		fitsfilePtr::write_key_log = 2
	OUTPUT:
		status

int
ffpkyj(fptr,keyname,value,comment,status)
	fitsfile * fptr
	char * keyname
	LONGLONG value
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_lng = 1
		fitsfilePtr::write_key_lng = 2
	OUTPUT:
		status

int
ffpkye(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_flt = 1
		fitsfilePtr::write_key_flt = 2
	OUTPUT:
		status

int
ffpkyf(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_fixflt = 1
		fitsfilePtr::write_key_fixflt = 2
	OUTPUT:
		status

int
ffpkyd(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_dbl = 1
		fitsfilePtr::write_key_dbl = 2
	OUTPUT:
		status

int
ffpkyg(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_fixdbl = 1
		fitsfilePtr::write_key_fixdbl = 2
	OUTPUT:
		status

int
ffpkyc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_cmp = 1
		fitsfilePtr::write_key_cmp = 2
	OUTPUT:
		status

int
ffpkfc(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	float * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_fixcmp = 1
		fitsfilePtr::write_key_fixcmp = 2
	OUTPUT:
		status

int
ffpkym(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_dblcmp = 1
		fitsfilePtr::write_key_dblcmp = 2
	OUTPUT:
		status

int
ffpkfm(fptr,keyname,value,decimals,comment,status)
	fitsfile * fptr
	char * keyname
	double * value
	int decimals
	char * comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_key_fixdblcmp = 1
		fitsfilePtr::write_key_fixdblcmp = 2
	OUTPUT:
		status

int
ffpkns(fptr,keyroot,nstart,nkeys,value,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	char ** value
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_str = 1
		fitsfilePtr::write_keys_str = 2
	OUTPUT:
		status

int
ffpknl(fptr,keyroot,nstart,nkeys,value,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	int * value
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_log = 1
		fitsfilePtr::write_keys_log = 2
	OUTPUT:
		status

int
ffpknj(fptr,keyroot,nstart,nkeys,value,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	long * value
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_lng = 1
		fitsfilePtr::write_keys_lng = 2
	OUTPUT:
		status

int
ffpknjj(fptr,keyroot,nstart,nkeys,value,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	LONGLONG * value
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_lnglng = 1
		fitsfilePtr::write_keysll = 2
	OUTPUT:
		status

int
ffpkne(fptr,keyroot,nstart,nkeys,value,decimals,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	float * value
	int decimals
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_flt = 1
		fitsfilePtr::write_keys_flt = 2
	OUTPUT:
		status

int
ffpknf(fptr,keyroot,nstart,nkeys,value,decimals,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	float * value
	int decimals
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_fixflt = 1
		fitsfilePtr::write_keys_fixflt = 2
	OUTPUT:
		status

int
ffpknd(fptr,keyroot,nstart,nkeys,value,decimals,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	double * value
	int decimals
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_dbl = 1
		fitsfilePtr::write_keys_dbl = 2
	OUTPUT:
		status

int
ffpkng(fptr,keyroot,nstart,nkeys,value,decimals,comment,status)
	fitsfile * fptr
	char * keyroot
	int nstart
	int nkeys
	double * value
	int decimals
	char ** comment
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_keys_fixdbl = 1
		fitsfilePtr::write_keys_fixdbl = 2
	OUTPUT:
		status

int
ffpprn(fptr,felem,nelem,status)
	fitsfile * fptr
	LONGLONG felem
	LONGLONG nelem
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_null_img = 1
		fitsfilePtr::write_null_img = 2
	OUTPUT:
		status

int
ffprec(fptr,card,status)
	fitsfile * fptr
	char * card
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_record = 1
		fitsfilePtr::write_record = 2
	OUTPUT:
		status

int
ffpss(fptr, dtype, fpix, lpix, nelem, array, status)
	fitsfile *fptr
	int dtype
	long *fpix
	long *lpix
	SV *array
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset = 1
		fitsfilePtr::write_subset = 2
	PREINIT:
		int storage_dtype;
	CODE:
		storage_dtype = dtype;
		if (dtype == TBIT)
			storage_dtype = TLOGICAL;
		RETVAL = ffpss(fptr,dtype,fpix,lpix,packND(array,storage_dtype),&status);
	OUTPUT:
		RETVAL
		status

int
ffpssb(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	byte * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_byt = 1
		fitsfilePtr::write_subset_byt = 2
	OUTPUT:
		status

int
ffpsssb(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	signed char* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_sbyt = 1
		fitsfilePtr::write_subset_sbyt = 2
	OUTPUT:
		status

int
ffpssui(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	unsigned short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_usht = 1
		fitsfilePtr::write_subset_usht = 2
	OUTPUT:
		status

int
ffpssi(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	short * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_sht = 1
		fitsfilePtr::write_subset_sht = 2
	OUTPUT:
		status

int
ffpssuk(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	unsigned int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_uint = 1
		fitsfilePtr::write_subset_uint = 2
	OUTPUT:
		status

int
ffpssk(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	int * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_int = 1
		fitsfilePtr::write_subset_int = 2
	OUTPUT:
		status

int
ffpssuj(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	unsigned long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_ulng = 1
		fitsfilePtr::write_subset_ulng = 2
	OUTPUT:
		status

int
ffpssj(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	long * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_lng = 1
		fitsfilePtr::write_subset_lng = 2
	OUTPUT:
		status

int
ffpssjj(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	LONGLONG* array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_lnglng = 1
		fitsfilePtr::write_subset_lnglng = 2
	OUTPUT:
		status

int
ffpsse(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	float * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_flt = 1
		fitsfilePtr::write_subset_flt = 2
	OUTPUT:
		status

int
ffpssd(fptr,group,naxis,naxes,fpixel,lpixel,array,status)
	fitsfile * fptr
	long group
	long naxis
	long * naxes
	long * fpixel
	long * lpixel
	double * array
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_subset_dbl = 1
		fitsfilePtr::write_subset_dbl = 2
	OUTPUT:
		status

int
ffptbb(fptr,frow,fchar,nchars,values,status)
	fitsfile * fptr
	LONGLONG frow
	LONGLONG fchar
	LONGLONG nchars
	byte * values;
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_tblbytes = 1
		fitsfilePtr::write_tblbytes = 2
	OUTPUT:
		status

int
ffptdm(fptr,colnum,naxis,naxes,status)
	fitsfile * fptr
	int colnum
	int naxis
	long * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_tdim = 1
		fitsfilePtr::write_tdim = 2
	OUTPUT:
		status

int
ffptdmll(fptr,colnum,naxis,naxes,status)
	fitsfile * fptr
	int colnum
	int naxis
	LONGLONG * naxes
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_tdimll = 1
		fitsfilePtr::write_tdimll = 2
	OUTPUT:
		status

int
ffpthp(fptr,theap,status)
	fitsfile * fptr
	long theap
	int &status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_theap = 1
		fitsfilePtr::write_theap = 2
	OUTPUT:
		status

int
ffgiwcs(fptr,header,status)
	fitsfile * fptr
	char * header = NO_INIT
	int status

	ALIAS:
		Astro::FITS::CFITSIO::fits_get_image_wcs_keys = 1
		fitsfilePtr::get_image_wcs_keys = 2
	CODE:
		RETVAL = ffgiwcs(fptr,&header,&status);
		if (status == 0) {
			if (ST(1) != &PL_sv_undef)
				unpackScalar(ST(1),header,TSTRING);
			fffree(header, &status);
		}
	OUTPUT:
		RETVAL
		status

int
ffgtwcs(fptr,xcol,ycol,header,status)
	fitsfile * fptr
	int xcol
	int ycol
	char * header = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_table_wcs_keys = 1
		fitsfilePtr::get_table_wcs_keys = 2
	CODE:
		RETVAL = ffgtwcs(fptr,xcol,ycol,&header,&status);
		if (status == 0) {
			if (ST(3)!=&PL_sv_undef)
				unpackScalar(ST(3),header,TSTRING);
			fffree(header, &status);
		}
	OUTPUT:
		RETVAL
		status

int
ffgipr(fptr,bitbix,naxis,naxes,status)
	FitsFile * fptr
	int bitpix = NO_INIT
	int naxis = NO_INIT
	long * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_parm = 1
		fitsfilePtr::get_img_parm = 2
	CODE:
		if (ST(3)!=&PL_sv_undef) {
			RETVAL = ffgipr(fptr->fptr,0,&bitpix,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONG);
		}
		else {
			naxis = 0;
			naxes = NULL;
		}
		RETVAL = ffgipr(fptr->fptr,naxis,&bitpix,&naxis,naxes,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),bitpix);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),naxis);
		if (ST(3)!=&PL_sv_undef) unpack1D(ST(3),naxes,naxis,TLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
ffgiprll(fptr,bitbix,naxis,naxes,status)
	FitsFile * fptr
	int bitpix = NO_INIT
	int naxis = NO_INIT
	LONGLONG * naxes = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_img_parmll = 1
		fitsfilePtr::get_img_parmll = 2
	CODE:
		if (ST(3)!=&PL_sv_undef) {
			RETVAL = ffgiprll(fptr->fptr,0,&bitpix,&naxis,NULL,&status);
			naxes = get_mortalspace(naxis,TLONGLONG);
		}
		else {
			naxis = 0;
			naxes = NULL;
		}
		RETVAL = ffgiprll(fptr->fptr,naxis,&bitpix,&naxis,naxes,&status);
		if (ST(1)!=&PL_sv_undef) sv_setiv(ST(1),bitpix);
		if (ST(2)!=&PL_sv_undef) sv_setiv(ST(2),naxis);
		if (ST(3)!=&PL_sv_undef) unpack1D(ST(3),naxes,naxis,TLONGLONG,fptr->perlyunpacking);
	OUTPUT:
		status
		RETVAL

int
ffgkcl(card)
	char * card
	ALIAS:
		Astro::FITS::CFITSIO::fits_get_keyclass = 1

int
ffgpxv(fptr, dtype, fpix, nelem, nulval, array, anynul, status)
	FitsFile * fptr
	int dtype
	long * fpix
	LONGLONG nelem
	SV * nulval
	void * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_pix = 1
		fitsfilePtr::read_pix = 2
	PREINIT:
		int naxis;
		long *naxes;
		OFF_T nelem_all;
		int i;
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(dtype));
			RETVAL = ffgpxv(fptr->fptr, dtype, fpix, nelem, (nulval!=&PL_sv_undef ? pack1D(nulval, dtype) : NULL), (void*)SvPV(ST(5),PL_na), &anynul, &status);
		}
		else {
			/* find out how many elements are in the image,
			 * allocate space, read, unpack
			 */
			RETVAL = ffgidm(fptr->fptr, &naxis, &status);
			if (status == 0) {
				naxes = get_mortalspace(naxis, TLONG);
				RETVAL = ffgisz(fptr->fptr, naxis, naxes, &status);
				nelem_all = 1;
				for (i=0; i<naxis; i++)
					nelem_all *= naxes[i];
				array=get_mortalspace(nelem_all,dtype);
				RETVAL=ffgpxv(fptr->fptr, dtype, fpix, nelem, (nulval!=&PL_sv_undef ?  pack1D(nulval, dtype) : NULL), array, &anynul, &status);
				if (status == 0) {
					order_reverse(naxis, naxes);
					unpackND(ST(5), array, naxis, naxes, dtype, fptr->perlyunpacking);
				}
			}
		}
		if (ST(6) != &PL_sv_undef)
			sv_setiv(ST(6), anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpxvll(fptr, dtype, fpix, nelem, nulval, array, anynul, status)
	FitsFile * fptr
	int dtype
	LONGLONG * fpix
	LONGLONG nelem
	SV * nulval
	void * array = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_pixll = 1
		fitsfilePtr::read_pixll = 2
	PREINIT:
		int naxis;
		LONGLONG *naxes;
		OFF_T nelem_all;
		int i;
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			SvGROW(ST(5),nelem*sizeof_datatype(dtype));
			RETVAL = ffgpxvll(fptr->fptr, dtype, fpix, nelem, (nulval!=&PL_sv_undef ? pack1D(nulval, dtype) : NULL), (void*)SvPV(ST(5),PL_na), &anynul, &status);
		}
		else {
			/* find out how many elements are in the image,
			 * allocate space, read, unpack
			 */
			RETVAL = ffgidm(fptr->fptr, &naxis, &status);
			if (status == 0) {
				naxes = get_mortalspace(naxis, TLONGLONG);
				RETVAL = ffgiszll(fptr->fptr, naxis, naxes, &status);
				nelem_all = 1;
				for (i=0; i<naxis; i++)
					nelem_all *= naxes[i];
				array=get_mortalspace(nelem_all,dtype);
				RETVAL=ffgpxvll(fptr->fptr, dtype, fpix, nelem, (nulval!=&PL_sv_undef ?  pack1D(nulval, dtype) : NULL), array, &anynul, &status);
				if (status == 0) {
					order_reversell(naxis, naxes);
					unpackNDll(ST(5), array, naxis, naxes, dtype,fptr->perlyunpacking);
				}
			}
		}
		if (ST(6) != &PL_sv_undef)
			sv_setiv(ST(6), anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpxf(fptr, dtype, fpix, nelem, array, nullarray, anynul, status)
	FitsFile * fptr
	int dtype
	long * fpix
	LONGLONG nelem
	void * array = NO_INIT
	logical * nullarray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_pixnull = 1
		fitsfilePtr::read_pixnull = 2
	PREINIT:
		int naxis;
		long *naxes;
		OFF_T nelem_all;
		int i;
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(dtype));
				array = (void*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem, dtype);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nullarray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nullarray = get_mortalspace(nelem,TLOGICAL);
			RETVAL = ffgpxf(fptr->fptr,dtype,fpix,nelem,array,nullarray, &anynul,&status);
		}
		else {
			/* find out how many elements are in the image,
			 * allocate space, read, unpack
			 */
			RETVAL = ffgidm(fptr->fptr, &naxis, &status);
			if (status == 0) {
				naxes = get_mortalspace(naxis, TLONG);
				RETVAL = ffgisz(fptr->fptr, naxis, naxes, &status);
				nelem_all = 1;
				for (i=0; i<naxis; i++)
					nelem_all *= naxes[i];
				array=get_mortalspace(nelem_all,dtype);
				nullarray=get_mortalspace(nelem_all,TLOGICAL);
				RETVAL=ffgpxf(fptr->fptr,dtype,fpix,nelem,array,nullarray,&anynul,&status);
				if (status == 0) {
					order_reverse(naxis, naxes);
					if (ST(4)!=&PL_sv_undef)
						unpackND(ST(4),array,naxis,naxes,dtype,fptr->perlyunpacking);
					if (ST(5)!=&PL_sv_undef)
						unpackND(ST(5),nullarray,naxis,naxes,TLOGICAL,fptr->perlyunpacking);
				}
			}
		}
		if (ST(6) != &PL_sv_undef)
			sv_setiv(ST(6), anynul);
	OUTPUT:
		status
		RETVAL

int
ffgpxfll(fptr, dtype, fpix, nelem, array, nullarray, anynul, status)
	FitsFile * fptr
	int dtype
	LONGLONG * fpix
	LONGLONG nelem
	void * array = NO_INIT
	logical * nullarray = NO_INIT
	int anynul = NO_INIT
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_read_pixnullll = 1
		fitsfilePtr::read_pixnullll = 2
	PREINIT:
		int naxis;
		LONGLONG *naxes;
		OFF_T nelem_all;
		int i;
	CODE:
		if (!PERLYUNPACKING(fptr->perlyunpacking)) {
			if (ST(4) != &PL_sv_undef) {
				SvGROW(ST(4),nelem*sizeof_datatype(dtype));
				array = (void*)SvPV(ST(4),PL_na);
			}
			else
				array = get_mortalspace(nelem, dtype);
			if (ST(5) != &PL_sv_undef) {
				SvGROW(ST(5),nelem*sizeof_datatype(TLOGICAL));
				nullarray = (logical*)SvPV(ST(5),PL_na);
			}
			else
				nullarray = get_mortalspace(nelem,TLOGICAL);
			RETVAL = ffgpxfll(fptr->fptr,dtype,fpix,nelem,array,nullarray, &anynul,&status);
		}
		else {
			/* find out how many elements are in the image,
			 * allocate space, read, unpack
			 */
			RETVAL = ffgidm(fptr->fptr, &naxis, &status);
			if (status == 0) {
				naxes = get_mortalspace(naxis, TLONGLONG);
				RETVAL = ffgiszll(fptr->fptr, naxis, naxes, &status);
				nelem_all = 1;
				for (i=0; i<naxis; i++)
					nelem_all *= naxes[i];
				array=get_mortalspace(nelem_all,dtype);
				nullarray=get_mortalspace(nelem_all,TLOGICAL);
				RETVAL=ffgpxfll(fptr->fptr,dtype,fpix,nelem,array,nullarray,&anynul,&status);
				if (status == 0) {
					order_reversell(naxis, naxes);
					if (ST(4)!=&PL_sv_undef)
						unpackNDll(ST(4),array,naxis,naxes,dtype,fptr->perlyunpacking);
					if (ST(5)!=&PL_sv_undef)
						unpackNDll(ST(5),nullarray,naxis,naxes,TLOGICAL,fptr->perlyunpacking);
				}
			}
		}
		if (ST(6) != &PL_sv_undef)
			sv_setiv(ST(6), anynul);
	OUTPUT:
		status
		RETVAL

int
ffppx(fptr, dtype, fpix, nelem, array, status)
	fitsfile * fptr
	int dtype
	long * fpix
	LONGLONG nelem
	SV * array
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_pix = 1
		fitsfilePtr::write_pix = 2
	PREINIT:
		int storage_dtype;
	CODE:
		storage_dtype = dtype;
		if (dtype == TBIT)
			storage_dtype = TLOGICAL;
		RETVAL = ffppx(fptr,dtype,fpix,nelem,packND(array,storage_dtype),&status);
	OUTPUT:
		RETVAL
		status

int
ffppxll(fptr, dtype, fpix, nelem, array, status)
	fitsfile * fptr
	int dtype
	LONGLONG * fpix
	LONGLONG nelem
	SV * array
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_pixll = 1
		fitsfilePtr::write_pixll = 2
	PREINIT:
		int storage_dtype;
	CODE:
		storage_dtype = dtype;
		if (dtype == TBIT)
			storage_dtype = TLOGICAL;
		RETVAL = ffppxll(fptr,dtype,fpix,nelem,packND(array,storage_dtype),&status);
	OUTPUT:
		RETVAL
		status

int
ffppxn(fptr, dtype, fpix, nelem, array, nulval, status)
	fitsfile * fptr
	int dtype
	long * fpix
	LONGLONG nelem
	SV * array
	SV * nulval
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_pixnull = 1
		fitsfilePtr::write_pixnull = 2
	PREINIT:
		int storage_dtype;
	CODE:
		storage_dtype = dtype;
		if (dtype == TBIT)
			storage_dtype = TLOGICAL;
		RETVAL = ffppxn(fptr,dtype,fpix,nelem,packND(array,storage_dtype),(nulval!=&PL_sv_undef ? pack1D(nulval,storage_dtype) : NULL), &status);
	OUTPUT:
		RETVAL
		status

int
ffppxnll(fptr, dtype, fpix, nelem, array, nulval, status)
	fitsfile * fptr
	int dtype
	LONGLONG * fpix
	LONGLONG nelem
	SV * array
	SV * nulval
	int status
	ALIAS:
		Astro::FITS::CFITSIO::fits_write_pixnullll = 1
		fitsfilePtr::write_pixnullll = 2
	PREINIT:
		int storage_dtype;
	CODE:
		storage_dtype = dtype;
		if (dtype == TBIT)
			storage_dtype = TLOGICAL;
		RETVAL = ffppxnll(fptr,dtype,fpix,nelem,packND(array,storage_dtype),(nulval!=&PL_sv_undef ? pack1D(nulval,storage_dtype) : NULL), &status);
	OUTPUT:
		RETVAL
		status

int
fits_copy_pixlist2image(infptr, outfptr, firstkey, naxis, colnum, status)
	fitsfile *infptr
	fitsfile *outfptr
	int firstkey
	int naxis
	int *colnum
	int &status
	ALIAS:
		fitsfilePtr::copy_pixlist2image = 1
	OUTPUT:
		status

int
fits_write_keys_histo(fptr, histptr, naxis, colnum, status)
	fitsfile *fptr
	fitsfile *histptr
	int naxis
	int *colnum
	int &status
	ALIAS:
		fitsfilePtr::write_keys_histo = 1
	OUTPUT:
		status

int
fits_rebin_wcs(fptr, naxis, amin, binsize, status)
	fitsfile *fptr
	int naxis
	float *amin
	float *binsize
	int &status
	ALIAS:
		fitsfilePtr::rebin_wcs = 1
	OUTPUT:
		status

int
fits_rebin_wcsd(fptr, naxis, amin, binsize, status)
	fitsfile *fptr
	int naxis
	double *amin
	double *binsize
	int &status
	ALIAS:
		fitsfilePtr::rebin_wcsd = 1
	OUTPUT:
		status

int
fits_make_hist(fptr,histptr,bitpix,naxis,naxes,colnum,amin,amax,binsize,weight,wtcolnum,recip,selectrow,status)
	fitsfile *fptr
	fitsfile *histptr
	int bitpix
	int naxis
	long *naxes
	int *colnum
	float *amin
	float *amax
	float *binsize
	float weight
	int wtcolnum
	int recip
	logical *selectrow
	int &status
	ALIAS:
		fitsfilePtr::make_hist = 1
	OUTPUT:
		status

int
fits_make_histd(fptr,histptr,bitpix,naxis,naxes,colnum,amin,amax,binsize,weight,wtcolnum,recip,selectrow,status)
	fitsfile *fptr
	fitsfile *histptr
	int bitpix
	int naxis
	long *naxes
	int *colnum
	double *amin
	double *amax
	double *binsize
	double weight
	int wtcolnum
	int recip
	logical *selectrow
	int &status
	ALIAS:
		fitsfilePtr::make_histd = 1
	OUTPUT:
		status

int
fits_make_histde(fptr,histptr,datatypes,bitpix,naxis,naxes,colnum,colexpr,amin,amax,binsize,weight,wtcolnum,wtexpr,recip,selectrow,status)
	fitsfile *fptr
	fitsfile *histptr
	int *datatypes
	int bitpix
	int naxis
	long *naxes
	int *colnum
	char **colexpr
	double *amin
	double *amax
	double *binsize
	double weight
	int wtcolnum
	char *wtexpr
	int recip
	logical *selectrow
	int &status
	ALIAS:
		fitsfilePtr::make_histde = 1
	OUTPUT:
		status
