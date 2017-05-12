require 'dbconn.pl';
use DBI;

 DBIx::Recordset -> Delete ({
     '!DataSource'   =>  dbh(),
     '!Table'        =>  'person'
     });
