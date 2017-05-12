package Alzabo::Runtime::JoinCursor;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions;
use Alzabo::Runtime;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

use base qw( Alzabo::Runtime::Cursor );

$VERSION = 2.0;

use constant NEW_SPEC => { statement => { isa => 'Alzabo::DriverStatement' },
                           tables => { type => ARRAYREF },
                         };

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = validate( @_, NEW_SPEC );

    my $self = bless { %p,
                       count => 0,
                     }, $class;

    return $self;
}

sub next
{
    my $self = shift;

    my @rows;

    my @data = $self->{statement}->next;

    return unless @data;

    my $i = 0;
    foreach my $t ( @{ $self->{tables} } )
    {

        my %pk;
        my $def = 0;
        foreach my $c ( $t->primary_key )
        {
            $pk{ $c->name } = $data[$i];

            $def = 1 if defined $data[$i];

            $i++;
        }

        unless ($def)
        {
            push @rows, undef;

            my @pre;
            if ( @pre = $t->prefetch )
            {
                $i += @pre;
            }

            next;
        }

        my %prefetch;
        {
            my @pre;
            if ( @pre = $t->prefetch )
            {
                @prefetch{@pre} = @data[ $i .. ($i + $#pre) ];
                $i += @pre;
            }
        }

        my $row = $t->row_by_pk( pk => \%pk,
                                 prefetch => \%prefetch,
                                 @_,
                               );

        push @rows, $row;
    }

    $self->{count}++;

    return @rows;
}

sub all_rows
{
    my $self = shift;

    my @all;
    while ( my @rows = $self->next )
    {
        push @all, [@rows];
    }

    $self->{count} = scalar @all;

    return @all;
}

1;

__END__

=head1 NAME

Alzabo::Runtime::JoinCursor - Cursor that returns arrays of C<Alzabo::Runtime::Row> objects

=head1 SYNOPSIS

  use Alzabo::Runtime::JoinCursor;

  my $cursor = $schema->join( tables => [ $foo, $bar ],
                              where => [ $foo->column('foo_id'), '=', 1 ] );

  while ( my @rows = $cursor->next )
  {
      print $rows[0]->select('foo'), "\n";
      print $rows[1]->select('bar'), "\n";
  }

=head1 DESCRIPTION

Objects in this class are used to return arrays of
Alzabo::Runtime::Row objects when requested.  The cursor does not
preload objects but rather creates them on demand, which is much more
efficient.  For more details on the rational please see L<the
RATIONALE FOR CURSORS section in
Alzabo::Design|Alzabo::Design/RATIONALE FOR CURSORS>.

=head1 INHERITS FROM

L<C<Alzabo::Runtime::Cursor>|Alzabo::Runtime::Cursor>

=head1 METHODS

=head2 next

Returns the next array of
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> objects or an empty
list if no more are available.

If an individual row could not be fetched, then the array may contain
some C<undef> values.  For outer joins, this is normal behavior, but
for regular joins, this probably indicates a data error.

=head2 all_rows

This method fetches all the rows available from the current point
onwards.  This means that if there are five set of rows that will be
returned when the object is created and you call C<next()> twice,
calling C<all_rows()> after it will only return three sets.

The return value is an array of array references.  Each of these
references represents a single set of rows as they would be returned
from the C<next> method.

=head2 reset

Resets the cursor so that the next L<C<next()>|next> call will return
the first row of the set.

=head2 count

Returns the number of rowsets returned by the cursor so far.

=head2 next_as_hash

Returns the next rows in a hash, where the hash keys are the table
names and the hash values are the row object.  If a table has been
included in the join via an outer join, then it is only included in
the hash if there is a row for that table.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
