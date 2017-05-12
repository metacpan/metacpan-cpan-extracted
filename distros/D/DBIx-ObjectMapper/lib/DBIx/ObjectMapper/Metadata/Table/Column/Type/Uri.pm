package DBIx::ObjectMapper::Metadata::Table::Column::Type::Uri;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type::Text);
use URI;

sub from_storage {
    my ( $self, $val ) = @_;
    return $val if !defined $val or ref $val;
    return URI->new($val);
}

sub to_storage {
    my ( $self, $val ) = @_;
    return $val unless defined $val and ref($val);
    return $val->as_string;
}


1;
