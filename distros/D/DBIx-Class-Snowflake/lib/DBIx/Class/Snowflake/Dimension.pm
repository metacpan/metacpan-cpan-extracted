package DBIx::Class::Snowflake::Dimension;
our $VERSION = '0.10';


=head1 NAME

DBIx::Class::Snowflake::Dimension

=head1 VERSION

version 0.10

=head1 ABSTRACT

 DBIx::Class::Snowflake::Dimension - Load this for any dimension tables.

=cut

use strict;
use warnings;
use diagnostics;

use base 'DBIx::Class::Snowflake';

=head1 METHODS

=head2 attributes

If this is a snowflake schema it returns the dimensions and
attributes of the dimension, if it is a star schema it returns
the attributes of the dimension.  This works very similarly
to B<DBIx::Class::Snowflake::Fact::dimensions>

=cut

=head2 attrs

Convenience alias to attributes.

=cut
sub attrs
{
    my $self = shift;
    return $self->attributes(@_);
}
1;