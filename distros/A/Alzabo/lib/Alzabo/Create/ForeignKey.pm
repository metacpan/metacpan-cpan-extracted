package Alzabo::Create::ForeignKey;

use strict;
use vars qw($VERSION);

use Alzabo::Create;
use Alzabo::Exceptions ( abbr => 'params_exception' );
use Alzabo::Utils;

use Params::Validate qw( :all );
Params::Validate::validation_options
    ( on_fail => sub { params_exception join '', @_ } );

use base qw(Alzabo::ForeignKey);

$VERSION = 2.0;

1;

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    validate( @_, { columns_from => { type => ARRAYREF | OBJECT },
                    columns_to   => { type => ARRAYREF | OBJECT },
                    cardinality  => { type => ARRAYREF },
                    from_is_dependent => { type => SCALAR },
                    to_is_dependent   => { type => SCALAR },
                    comment => { type => UNDEF | SCALAR,
                                 default => '' },
                  } );
    my %p = @_;

    my $self = bless {}, $class;

    $self->set_columns_from( $p{columns_from} );
    $self->set_columns_to( $p{columns_to} );

    $self->set_cardinality( @{ $p{cardinality} } );
    $self->set_from_is_dependent( $p{from_is_dependent} );
    $self->set_to_is_dependent( $p{to_is_dependent} );

    $self->set_comment( $p{comment} );

    return $self;
}

sub set_columns_from
{
    my $self = shift;

    my $c = Alzabo::Utils::is_arrayref( $_[0] ) ? shift : [ shift ];
    validate_pos( @$c, ( { isa => 'Alzabo::Create::Column' } ) x @$c );

    if ( exists $self->{columns_to} )
    {
        params_exception
            "The number of columns in each part of the relationship must be the same"
                unless @{ $self->{columns_to} } == @$c;
    }

    $self->{columns_from} = $c;
}

sub set_columns_to
{
    my $self = shift;

    my $c = Alzabo::Utils::is_arrayref( $_[0] ) ? shift : [ shift ];
    validate_pos( @$c, ( { isa => 'Alzabo::Create::Column' } ) x @$c );

    if ( exists $self->{columns_from} )
    {
        params_exception
            "The number of columns in each part of the relationship must be the same"
                unless @{ $self->{columns_from} } == @$c;
    }

    $self->{columns_to} = $c;
}

sub set_cardinality
{
    my $self = shift;

    my @card = @_;

    params_exception "Incorrect number of elements for cardinality"
        unless scalar @card == 2;

    foreach my $c ( @card )
    {
        params_exception "Invalid cardinality piece: $c"
            unless $c =~ /^[1n]$/i;
    }

    params_exception "Invalid cardinality: $card[0]..$card[1]"
        if $card[0] eq 'n' && $card[1] eq 'n';

    $self->{cardinality} = \@card;
}

sub set_from_is_dependent
{
    my $self = shift;

    $self->{from_is_dependent} = shift;
}

sub set_to_is_dependent
{
    my $self = shift;

    $self->{to_is_dependent} = shift;
}

sub set_comment { $_[0]->{comment} = defined $_[1] ? $_[1] : '' }

__END__

=head1 NAME

Alzabo::Create::ForeignKey - Foreign key objects for schema creation.

=head1 SYNOPSIS

  use Alzabo::Create::ForeignKey;

=for pod_merge DESCRIPTION

=head1 INHERITS FROM

C<Alzabo::ForeignKey>

=for pod_merge merged

=head1 METHODS

=head2 new

The constructor takes the following parameters:

=over 4

=item * columns_from => C<Alzabo::Create::Column> object(s)

=item * columns_to => C<Alzabo::Create::Column> object(s)

These two parameters may be either a single column or a reference to
an array columns.  The number of columns in the two parameters must
match.

=item * cardinality => [1, 1], [1, 'n'], or ['n', 1]

=item * from_is_dependent => $boolean

=item * to_is_dependent => $boolean

=item * comment => $comment

An optional comment.

=back

It returns a new
L<C<Alzabo::Create::ForeignKey>|Alzabo::Create::ForeignKey> object.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=for pod_merge table_from

=for pod_merge table_to

=for pod_merge columns_from

=for pod_merge columns_to

=for pod_merge column_pairs

=head2 set_columns_from (C<Alzabo::Create::Column> object(s))

Sets the column(s) that the relation is from.  This can be either a
single column object or a reference to an array of column objects.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 set_columns_to (C<Alzabo::Create::Column> object(s))

Sets the column(s) that the relation is to.  This can be either a
single column object or a reference to an array of column objects.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=for pod_merge cardinality

=for pod_merge from_is_dependent

=for pod_merge to_is_dependent

=for pod_merge is_one_to_one

=for pod_merge is_one_to_many

=for pod_merge is_many_to_one

=head2 set_cardinality (\@cardinality) see above for details

Sets the cardinality of the foreign key.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 set_from_is_dependent ($boolean)

Indicates whether or not the first table in the foreign key is
dependent on the other (i.e. whether the 'from' table is dependent on
the 'to' table).

=head2 set_to_is_dependent ($boolean)

Indicates whether or not the second table in the foreign key is
dependent on the other (i.e. whether the 'to' table is dependent on
the 'from' table).

=for pod_merge id

=for pod_merge is_same_relationship_as ($fk)

=for pod_merge comment

=head2 set_comment ($comment)

Sets the comment for the foreign key object.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
