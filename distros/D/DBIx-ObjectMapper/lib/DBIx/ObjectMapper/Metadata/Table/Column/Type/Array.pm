package DBIx::ObjectMapper::Metadata::Table::Column::Type::Array;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type);

sub _init {
    my $self = shift;
    $self->{array_type} = shift || undef;
}

sub to_storage {
    my ( $self, $val ) = @_;
    return $val unless defined $val and ref($val);

    if( ref($val) eq 'ARRAY' ) {
        return \$val;
    }
    else {
        return $val;
    }
}

1;
