package Data::AnyXfer::Elastic::Role::BucketSimplifier;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;

=head1 NAME

Data::AnyXfer::Elastic::Role::BucketSimplifier - simplify buckets

=head1 SYNOPSIS

  package MyPackage;

  use Moo;
use MooX::Types::MooseLike::Base qw(:all);


  with 'Data::AnyXfer::Elastic::Role::BucketSimplifier';

=head1 DESCRIPTION

This role provides a method for simplifying aggregated results.

Buckets are changed to hash references, where the keys are the keys to
the bucket items.

=head1 ATTRIBUTES

=head2 C<aggregations_key>

The top-level hash key that contains aggregated results. Defaults to
"aggreations".

=cut

has 'aggregations_key' => (
    is      => 'ro',
    isa     => Str,
    default => 'aggregations',
);

=head1 METHODS

=head2 C<simplify_bucket>

  $data = $self->simplify_bucket( $res );

=cut

sub simplify_bucket {
    my ( $self, $res ) = @_;
    $self->_row_to_hash( $res->{ $self->aggregations_key } );
}

sub _row_to_hash {
    my ( $self, $row ) = @_;

    my $rec = {};

    foreach my $key ( keys @{$row} ) {

        next if $key =~ m/^key(?:_as_string)?$/;    # redundant

        my $val  = $row->{$key};
        my $type = ref $val;

        if ( !$type ) {

            $rec->{$key} = $val;

        } elsif ( $type eq 'HASH' ) {

            if ( exists $val->{value} ) {

                $rec->{$key} = $val->{value};

            } elsif ( my $sub_buckets = $val->{buckets} ) {

                $rec->{$key} = $self->_bucket_to_hash($sub_buckets);

            }

        } else {

            croak "Don't know how to handle type ${type} in a bucket";

        }

    }

    $rec;
}

sub _bucket_to_hash {
    my ( $self, $buckets ) = @_;

    my %hash;

    foreach my $row ( @{$buckets} ) {

        $hash{ $row->{key_as_string} // $row->{key} }
            = $self->_row_to_hash($row);

    }

    return \%hash;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
