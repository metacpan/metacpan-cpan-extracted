#! perl

use v5.10;
package    #
  DBD::MyTestDBD;
use Exporter::Shiny 'MTDB_INTEGER', 'MTDB_REAL';

use constant { MTDB_INTEGER => 1111, MTDB_REAL => 2222 };

our %EXPORT_TAGS = ( sql_types => [qw( MTDB_INTEGER MTDB_REAL )], );


1;
