package Data::AnyXfer::From::JSON;

use v5.16.3;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Path::Class;

use Data::AnyXfer::JSON qw/ decode_json /;

=head1 NAME

Data::AnyXfer::From::JSON - transfer from json sources

=head1 SYNOPSIS

    use Moo;
use MooX::Types::MooseLike::Base qw(:all);


    extends 'Data::AnyXfer';
    with 'Data::AnyXfer::From::JSON';

    ...

    # Path::Class::File
    has '+json' => ( default => sub { file('example.json'); } );

    # Json string
    has '+json' => ( default => sub { return '{"documents": [{"author": "Douglas Adams"}]'});

    # Direct hash structure
    has '+json' => ( default => sub { return { documents => [ { author => "Douglas Adams"}]}});

    has '+documents_location' ( default => sub { [qw/data documents/] });

=head1 DESCRIPTION

The role configures L<Data::AnyXfer> to use json as a data source.

=head1 ATTRIBUTES

=head2 json

Accepts hash refs, JSON strings or L<Path::Class::File> to a json file.

The json structure must have a array where the documents for population
are stored, the default location is "documents" : [], but this can be overriden
with the attribute C<documents_location>.

=cut

has json => (
    is       => 'ro',
    isa      => HashRef,
    coerce   => sub {
      my $value = $_[1];

      # if this is a ref that isn't a HASH it must be a Path::Class::File
      # object
      $value = $value->slurp if ref $value;

      return decode_json($value);
    },
    required => 1,
);

=head2 documents_location

Defines the hash key where documents are stored in the json structure. Defaults
to I<documents>.

If documents are in a same layer then:

    {
        "buckets" : []
    }

    documents_location => [ 'buckets' ]

If documents are in a sub layer then:

    {
        "buckets": {
            "data": {
                "documents": [...]
            }
        }
    }

    documents_location => [qw/buckets data documents/]

=cut

has documents_location => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { ['documents'] },
);

has _json_index => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => Int,
    default  => -1,
    init_arg => undef,
    handles  => { inc_counter => 'inc' }
);

around 'fetch_next' => sub {
    my ( $orig, $self ) = @_;
    $self->$orig or return;
    return $self->_get_documents->[ $self->inc_counter ];
};

# this is required for populating documents
around 'transform' => sub {
    my ( $orig, $self, $res ) = @_;
    $self->$orig();
    return $res;
};

# method fetches the documents array from the json via the find method

sub _get_documents {
    my $self = shift;

    my $docs = $self->_find( $self->json, @{ $self->documents_location } );

    if ( ref($docs) ne 'ARRAY' ) {
        croak "Population documents must stored in an array";
    }

    # TODO: Warn if $docs are empty

    return $docs;
}

# recusive function to find the a desired value from keys

sub _find {
    my ( $self, $docs, @keys ) = @_;

    return unless $docs;

    foreach my $key ( @keys ) {
        # go down a level, or croak if missing
        $docs = $docs->{$key} // croak "Error could not find key: ${key}";
    }

    return $docs;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

