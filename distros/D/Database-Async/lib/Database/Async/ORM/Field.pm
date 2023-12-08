package Database::Async::ORM::Field;

use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub table { shift->{table} }
sub name { shift->{name} }
sub attributes { shift->{attributes} }
sub type { shift->{type} }
sub nullable { shift->{nullable} }
sub default { shift->{default} }

1;

