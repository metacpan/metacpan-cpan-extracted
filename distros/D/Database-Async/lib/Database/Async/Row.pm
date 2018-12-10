package Database::Async::Row;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

sub new {
    my $self = shift;
    bless { @_ }, $self
}

sub field {
    my ($self, $name) = @_;
    $self->{data}[$self->{index_by_name}{$name} // die 'unknown field ' . $name]->{data}
}

1;

