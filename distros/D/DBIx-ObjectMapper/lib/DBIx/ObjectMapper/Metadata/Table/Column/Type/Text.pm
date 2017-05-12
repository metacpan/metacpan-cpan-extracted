package DBIx::ObjectMapper::Metadata::Table::Column::Type::Text;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type::String);

sub _init {
    my $self = shift;
    my @opt = @_;
    $self->{utf8} = 1 if grep { defined $_ and $_ eq 'utf8' } @opt;
}

1;
