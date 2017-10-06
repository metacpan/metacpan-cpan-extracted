package Apache::Session::Browseable::Store::Postgres;

use strict;

use Apache::Session::Browseable::Store::DBI;
use Apache::Session::Store::Postgres;

our @ISA =
  qw(Apache::Session::Browseable::Store::DBI Apache::Session::Store::Postgres);
our $VERSION = '1.2.2';

sub connection {
    my($self,$session)=@_;
    $self->SUPER::connection($session);
    $self->{dbh}->{pg_enable_utf8} = 1;
}

1;

