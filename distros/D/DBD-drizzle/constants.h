#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libdrizzle/drizzle_client.h>

static double drizzle_constant(char* name, char* arg) {
  errno = 0;
  arg= arg;
  switch (*name) {
  case 'B':
    if (strEQ(name, "BLOB_FLAG"))
      return DRIZZLE_COLUMN_FLAGS_BLOB;
    break;
  case 'F':
    if (strnEQ(name, "DRIZZLE_COLUMN_TYPE_", 11)) {
      char* n = name+11;
      switch(*n) {
      case 'B':
	if (strEQ(n, "BLOB"))
	  return DRIZZLE_COLUMN_TYPE_BLOB;
	break;
      case 'C':
	if (strEQ(n, "CHAR"))
	  return DRIZZLE_COLUMN_TYPE_VARCHAR;
	break;
      case 'D':
	if (strEQ(n, "DECIMAL"))
	  return DRIZZLE_COLUMN_TYPE_NEWDECIMAL;
	if (strEQ(n, "DATE"))
	  return DRIZZLE_COLUMN_TYPE_DATETIME;
	if (strEQ(n, "DATETIME"))
	  return DRIZZLE_COLUMN_TYPE_DATETIME;
	if (strEQ(n, "DOUBLE"))
	  return DRIZZLE_COLUMN_TYPE_DOUBLE;
	break;
      case 'F':
	if (strEQ(n, "FLOAT"))
	  return DRIZZLE_COLUMN_TYPE_DOUBLE;
	break;
      case 'I':
	if (strEQ(n, "INT24"))
	  return DRIZZLE_COLUMN_TYPE_LONG;
	break;
      case 'L':
	if (strEQ(n, "LONGLONG"))
	  return DRIZZLE_COLUMN_TYPE_LONGLONG;
	if (strEQ(n, "LONG_BLOB"))
	  return DRIZZLE_COLUMN_TYPE_BLOB;
	if (strEQ(n, "LONG"))
	  return DRIZZLE_COLUMN_TYPE_LONG;
	break;
      case 'M':
	if (strEQ(n, "MEDIUM_BLOB"))
	  return DRIZZLE_COLUMN_TYPE_BLOB;
	break;
      case 'N':
	if (strEQ(n, "NULL"))
	  return DRIZZLE_COLUMN_TYPE_NULL;
	break;
      case 'S':
	if (strEQ(n, "SHORT"))
	  return DRIZZLE_COLUMN_TYPE_LONG;
	if (strEQ(n, "STRING"))
	  return DRIZZLE_COLUMN_TYPE_VARCHAR;
	break;
      case 'T':
	if (strEQ(n, "TINY"))
	  return DRIZZLE_COLUMN_TYPE_TINY;
	if (strEQ(n, "TINY_BLOB"))
	  return DRIZZLE_COLUMN_TYPE_BLOB;
	if (strEQ(n, "TIMESTAMP"))
	  return DRIZZLE_COLUMN_TYPE_TIMESTAMP;
	if (strEQ(n, "TIME"))
	  return DRIZZLE_COLUMN_TYPE_TIME;
	break;
      case 'V':
	if (strEQ(n, "VAR_STRING"))
	  return DRIZZLE_COLUMN_TYPE_VARCHAR;
	break;
      }
    }
    break;
  case 'N':
    if (strEQ(name, "NOT_NULL_FLAG"))
      return DRIZZLE_COLUMN_FLAGS_NOT_NULL;
    break;
  case 'P':
    if (strEQ(name, "PRI_KEY_FLAG"))
      return DRIZZLE_COLUMN_FLAGS_PRI_KEY;
    break;
  }
  errno = EINVAL;
  return 0;
}
