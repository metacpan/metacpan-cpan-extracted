package Database::Async::ORM::Type;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub schema { shift->{schema} }
sub description { shift->{description} }
sub defined_in { shift->{defined_in} }
sub type { shift->{type} }
sub name { shift->{name} }
sub basis { shift->{basis} }
sub is_builtin { shift->{is_builtin} }
sub values : method { (shift->{values} // [])->@* }
sub fields { (shift->{fields} // [])->@* }

1;

