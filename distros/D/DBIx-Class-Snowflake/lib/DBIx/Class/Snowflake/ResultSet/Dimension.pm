package DBIx::Class::Snowflake::ResultSet::Dimension;
our $VERSION = '0.10';


=head1 NAME

=head1 ABSTRACT

=head1 VERSION

version 0.10

DBIx::Class::Snowflake::ResultSet::Dimension - Custom resultset that allows you to get the attributes of a dimension

=cut

use strict;
use warnings;
use base qw(DBIx::Class::ResultSet);
__PACKAGE__->load_components('Snowflake');

=head1 METHODS

=head2 attributes

Please see DBIx::Class::Snowflake::Dimension::attributes for details

=cut

1;