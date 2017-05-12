package Alzabo::Runtime::RowCursor;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions;
use Alzabo::Runtime;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

use base qw( Alzabo::Runtime::Cursor );

$VERSION = 2.0;

use constant NEW_SPEC => { statement => { isa => 'Alzabo::DriverStatement' },
                           table => { isa => 'Alzabo::Runtime::Table' },
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

    my $row;

    # This loop is intended to allow the end caller to ignore rows
    # that can't be created because they're not in the table.
    #
    # For example, imagine that query in the statement is looking at
    # table 'foo' to get PK values for table 'bar'.  If table 'foo'
    # has a record indicating that there is a row in 'bar' where PK ==
    # 1 but no such row actually exists then we want to skip this.
    #
    # If they really want to know we do save the exception.
    until ( defined $row )
    {
        my @row = $self->{statement}->next;

        last unless @row && grep { defined } @row;

        my %hash;
        my @pk = $self->{table}->primary_key;
        @hash{ map { $_->name } @pk } = @row[0..$#pk];

        my %prefetch;
        if ( (my @pre = $self->{table}->prefetch) && @row > @pk )
        {
            @prefetch{@pre} = @row[$#pk + 1 .. $#row];
        }

        $row = $self->{table}->row_by_pk( @_,
                                          pk => \%hash,
                                          prefetch => \%prefetch,
                                          %{ $self->{row_params} },
                                        );
    }

    return unless $row;
    $self->{count}++;

    return $row;
}

sub all_rows
{
    my $self = shift;

    my @rows;
    while ( my $row = $self->next )
    {
        push @rows, $row;
    }


    $self->{count} = scalar @rows;

    return @rows;
}


1;

__END__

=head1 NAME

Alzabo::Runtime::RowCursor - Cursor that returns C<Alzabo::Runtime::Row> objects

=head1 SYNOPSIS

  use Alzabo::Runtime::RowCursor;

  my $cursor = $schema->table('foo')->all_rows;

  while ( my $row = $cursor->next )
  {
      print $row->select('foo'), "\n";
  }

=head1 DESCRIPTION

Objects in this class are used to return
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> objects for queries.
The cursor does not preload objects but creates them on demand, which
is much more efficient.  For more details on the rational please see
L<the RATIONALE FOR CURSORS section in
Alzabo::Design|Alzabo::Design/RATIONALE FOR
CURSORS>.

=head1 INHERITS FROM

L<C<Alzabo::Runtime::Cursor>|Alzabo::Runtime::Cursor>

=head1 METHODS

=head2 next

Returns the next L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>
object or undef if no more are available.

=head2 all_rows

Returns all the rows available from the current point onwards.  This
means that if there are five rows that will be returned when the
object is created and you call C<next> twice, calling all_rows
after it will only return three.

=head2 reset

Resets the cursor so that the next L<C<next>|next> call will
return the first row of the set.

=head2 count

Returns the number of rows returned by the cursor so far.

=head2 next_as_hash

Return the next row in a hash, where the hash key is the table name
and the hash value is the row object.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
