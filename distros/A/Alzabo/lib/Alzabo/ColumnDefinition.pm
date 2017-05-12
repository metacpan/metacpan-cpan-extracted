package Alzabo::ColumnDefinition;

use strict;
use vars qw($VERSION);

use Alzabo;

$VERSION = 2.0;

1;

sub type
{
    my $self = shift;

    return $self->{type};
}

sub length
{
    my $self = shift;

    return $self->{length};
}

sub precision
{
    my $self = shift;

    return $self->{precision};
}

sub owner
{
    my $self = shift;

    return $self->{owner};
}

__END__

=head1 NAME

Alzabo::ColumnDefinition - Holds the type attribute for a column

=head1 SYNOPSIS

  my $def = $column->definition;

  print $def->type;

=head1 DESCRIPTION

This object holds information on a column that might need to be shared
with another column.  The reason for this is that if a column is a key
in two or more tables, then some of the information related to that
column should change automatically for all tables (and all columns)
whenever it is changed anywhere.  Right now this is only type
('VARCHAR', 'NUMBER', etc) information.  This object also has an
'owner', which is the column which created it.

=head1 METHODS

=head2 type

Returns the object's type as a string.

=head2 length

Returns the length attribute of the column, or undef if there is none.

=head2 precision

Returns the precision attribute of the column, or undef if there is
none.

=head2 owner

Returns the L<C<Alzabo::Column>|Alzabo::Column> object that owns this
definitions (the column that created it).

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
