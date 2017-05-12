package Apache::Session::Browseable::Store::Informix;

use strict;

use Apache::Session::Browseable::Store::DBI;
use Apache::Session::Store::Informix;

our @ISA =
  qw(Apache::Session::Browseable::Store::DBI Apache::Session::Store::Informix);
our $VERSION = '1.2.2';

1;

