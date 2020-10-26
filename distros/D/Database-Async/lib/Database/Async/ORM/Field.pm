package Database::Async::ORM::Field;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub table { shift->{table} }
sub name { shift->{name} }
sub type { shift->{type} }
sub nullable { shift->{nullable} }

1;

