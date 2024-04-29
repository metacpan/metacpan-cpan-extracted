package DBIx::DataModel::Carp;
use strict;
use warnings;
use Carp::Object -reexport => qw/carp croak/;

our %CARP_OBJECT_CONSTRUCTOR = (clan => qw[^(DBIx::DataModel::|SQL::Abstract)]);

1;

__END__

=encoding ISO8859-1

=head1 NAME

DBIx::DataModel::Carp - custom carping module for DBIx::DataModel

=head1 DESCRIPTION

Used by all modules in DBIx::DataModel for ignoring stack frames in
DBIx::DataModel or in SQL::Abstract while croaking or carping.

