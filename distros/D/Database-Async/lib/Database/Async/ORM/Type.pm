package Database::Async::ORM::Type;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

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

sub qualified_name { ($_[0]->is_builtin ? $_[0]->name : $_[0]->schema->name . '.' . $_[0]->name) }

1;

