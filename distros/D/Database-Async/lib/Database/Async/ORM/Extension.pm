package Database::Async::ORM::Extension;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

sub new {
    my ($class) = shift;
    bless { @_ }, $class
}

sub name { shift->{name} }
sub defined_in { shift->{defined_in} }
sub description { shift->{description} }
sub optional { shift->{optional} }
sub is_optional { shift->{optional} ? 1 : 0 }

1;

