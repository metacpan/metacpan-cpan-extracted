package Apache::Session::Browseable::Store::Sybase;

use strict;

use Apache::Session::Browseable::Store::DBI;
use Apache::Session::Store::Sybase;

our @ISA =
  qw(Apache::Session::Browseable::Store::DBI Apache::Session::Store::Sybase);
our $VERSION = '1.2.2';

1;

