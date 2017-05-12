package Data::Riak::Request::SetBucketProps;
{
  $Data::Riak::Request::SetBucketProps::VERSION = '2.0';
}

use Moose;
use JSON 'encode_json';
use Data::Riak::Result::SingleJSONValue;
use namespace::autoclean;

has props => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub as_http_request_args {
    my ($self) = @_;

    return {
        method       => 'PUT',
        uri          => sprintf('buckets/%s/props', $self->bucket_name),
        content_type => 'application/json',
        data         => encode_json $self->props,
    };
}

with 'Data::Riak::Request::WithBucket';

has '+result_class' => (
    default => Data::Riak::Result::,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::SetBucketProps

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
