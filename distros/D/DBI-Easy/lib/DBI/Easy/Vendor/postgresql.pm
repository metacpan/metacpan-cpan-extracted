package DBI::Easy::Vendor::postgresql;

use Class::Easy;

use base qw(DBI::Easy::Vendor::Base);

# Style Specification	Description	Example
# ISO	ISO 8601/SQL standard	1997-12-17 07:37:16-08
# SQL	traditional style	12/17/1997 07:37:16.00 PST
# POSTGRES	original style	Wed Dec 17 07:37:16 1997 PST
# German	regional style	17.12.1997 07:37:16.00 PST

# datestyle Setting	Input Ordering	Example Output
# SQL, DMY	day/month/year	17/12/1997 15:37:16.00 CET
# SQL, MDY	month/day/year	12/17/1997 07:37:16.00 PST
# Postgres, DMY	day/month/year	Wed 17 Dec 07:37:16 1997 PST
# interval output looks like the input format, except that units like
# century or week are converted to years and days and ago is converted
# to an appropriate sign. In ISO mode the output looks like
# 
# [ quantity unit [ ... ] ] [ days ] [ hours:minutes:seconds ]
# The date/time styles can be selected by the user using the SET datestyle
# command, the DateStyle parameter in the postgresql.conf configuration file,
# or the PGDATESTYLE environment variable on the server or client.
# The formatting function to_char (see Section 9.8) is also available as a
# more flexible way to format the date/time output.

# SHOW DateStyle;
#  DateStyle
# -----------
#  ISO, MDY



sub vendor_schema {
	# please refer to http://www.postgresql.org/docs/current/static/ddl-schemas.html

	# SHOW search_path;
	# In the default setup this returns:
	# 
	#  search_path
	# --------------
	#  "$user",public
	# 
	# SET search_path TO myschema,public;

	return;
}

1;