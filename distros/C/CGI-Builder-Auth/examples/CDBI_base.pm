#=====================================================================
# BASE CLASS DERIVED FROM Class::DBI
#=====================================================================
package CDBI_base;
use base Class::DBI;
# For 0.96 use 'connection' instead
# NOTE: /tmp is a BAD place to store your passwd file!
__PACKAGE__->set_db('Main', 'DBI:SQLite:dbname=/tmp/htpasswd.sqlite', '', '');


"Copyright 2004 by Vincent Veselosky [[http://www.control-escape.com]]";
