package BioX::Workflow::Command::run::Rules::Directives::Types::List;

use Moose::Role;

=head2 Iterables

Lists to iterate by

Chunks and chroms are included by default

=cut

=head2 chunks

Special iterable. Iterate through a list of numbers

=cut

has 'chunks' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

has 'chunk' => ( is => 'rw' );

has 'use_chunks' => (
    is      => 'rw',
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => {
        'no_chunks' => 'not',
    }
);

has 'chunk_list' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ( !exists $self->chunks->{start} || !exists $self->chunks->{end} ) {
            return [];
        }
        my @array = ();
        for (
            my $x = $self->chunks->{start} ;
            $x <= $self->chunks->{end} ;
            $x = $x + $self->chunks->{step}
          )
        {
            push( @array, $x );
        }
        return \@array;
    },
    handles => {
        'all_chunk_lists' => 'elements',
    },
);

=head2 chroms_list

Iterate by chroms. Default is human chromosomes.

To change create a first rule with the template

=cut

has 'chroms_list' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        return [ 1 .. 22, 'X', 'Y', 'MT' ];
    },
    handles => {
        'all_chrom_lists' => 'elements',
    },
);

has 'chrom' => ( is => 'rw' );

has 'use_chroms' => (
    is      => 'rw',
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => {
        'no_chroms' => 'not',
    }
);

=head3 create_ITERABLE_attr

For every argument that ends in _list, create an array, a single val, and a boolean

If iterable is

  some_list

We get an array 'some_list', boolean value 'use_somes', and blank/placeholder of 'some'

The boolean value is set to 0

You can only use one iterable per flow

=cut

sub create_ITERABLE_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    my $t = $k;
    $t =~ s/_list//;

    $self->create_ARRAY_attr( $meta, $k );
    $self->create_blank_attr( $meta, $t );
    $self->create_BOOL_attr( $meta, $t );
}

sub create_BOOL_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    $meta->add_attribute(
            'use_'
          . $k
          . 's' => (
            traits  => ['Bool'],
            is      => 'rw',
            isa     => 'Bool',
            default => 0,
            handles => {
                'no_' . $k . 's' => 'not',
            }
          )
    );
}

=head3 create_blank_attr

placeholder for ITERABLE

=cut

sub create_blank_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    $meta->add_attribute(
        $k => (
            is      => 'rw',
            default => '',
        )
    );
}

=head2 Set Register Types

When we are iterating over the local variables, we can create types based on regular expressions

INPUT, OUTPUT, *_dir, indir, outdir all create paths - but only the leaves of the data structure
*_list transforms the whole data structure

=cut

after 'BUILD' => sub {
    my $self = shift;

    $self->set_register_types( 'list',
        { builder => 'create_ITERABLE_attr', lookup => ['.*_list$'] } );
};

1;
