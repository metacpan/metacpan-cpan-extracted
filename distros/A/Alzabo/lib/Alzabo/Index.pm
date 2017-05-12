package Alzabo::Index;

use strict;
use vars qw($VERSION);

use Alzabo;

use Tie::IxHash;

$VERSION = 2.0;

1;

sub columns
{
    my $self = shift;

    my @c;
    foreach my $c ($self->{columns}->Keys)
    {
        push @c, ($self->{columns}->FETCH($c))->{column};
    }

    return @c;
}

sub prefix
{
    my $self = shift;
    my $c = shift;

    Alzabo::Exception::Params->throw( error => "Column " . $c->name . " is not part of index." )
        unless $self->{columns}->EXISTS( $c->name );

    return ($self->{columns}->FETCH( $c->name ))->{prefix};
}

sub unique { $_[0]->{unique} }

sub fulltext { $_[0]->{fulltext} }

sub function { $_[0]->{function} }

sub id
{
    my $self = shift;

    my $function;

    if ( defined $self->function )
    {
        ($function) = $self->function =~ /^(\w+)/;
    }

    return join '___', ( $self->{table}->name,
# making this change would break schemas when the user tries to
# delete/drop the index.  save for later, maybe?

#                        ( $self->unique ? 'U' : () ),
#                        ( $self->fulltext ? 'F' : () ),
                         ( $function ? $function : () ),
                         ( map { $_->name, $self->prefix($_) || () }
                           $self->columns ),
                       );
}

sub table
{
    my $self = shift;

    return $self->{table};
}

__END__

=head1 NAME

Alzabo::Index - Index objects

=head1 SYNOPSIS

  foreach my $i ($table->indexes)
  {
     foreach my $c ($i->columns)
     {
        print $c->name;
        print '(' . $i->prefix($c) . ')' if $i->prefix($c);
    }
 }

=head1 DESCRIPTION

This object represents an index on a table.  Indexes consist of
columns and optional prefixes for each column.  The prefix specifies
how many characters of the columns should be indexes (the first X
chars).  Some RDBMS's do not have a concept of index prefixes.  Not
all column types are likely to allow prefixes though this depends on
the RDBMS.  The order of the columns is significant.

=head1 METHODS

=head2 columns

Returns an ordered list of the L<C<Alzabo::Column>|Alzabo::Column>
objects that are being indexed.

=head2 prefix (C<Alzabo::Column> object)

A column prefix is, to the best of my knowledge, a MySQL specific
concept, and as such cannot be set when using an RDBMSRules module for
a different RDBMS.  However, it is important enough for MySQL to have
the functionality be present.  It allows you to specify that the index
should only look at a certain portion of a field (the first N
characters).  This prefix is required to index any sort of BLOB column
in MySQL.

This method returns the prefix for the column in the index.  If there
is no prefix for this column in the index, then it returns undef.

=head2 unique

Returns a boolean value indicating whether the index is a unique
index.

=head2 fulltext

Returns a boolean value indicating whether the index is a fulltext
index.

=head2 function

For function indexes, this returns the function being indexed.

=head2 id

The id is generated from the table, column and prefix information for
the index.  This is useful as a canonical name for a hash key, for
example.

Returns a string that is the id which uniquely identifies the index in
this schema.

=head2 table

Returns the L<C<Alzabo::Table>|Alzabo::Table> object to which the
index belongs.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
