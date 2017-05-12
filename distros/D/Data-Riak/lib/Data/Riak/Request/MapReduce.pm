package Data::Riak::Request::MapReduce;
{
  $Data::Riak::Request::MapReduce::VERSION = '2.0';
}

use Moose;
use Data::Riak::Result::Object;
use Data::Riak::Exception::FunctionFailed;
use Data::Riak::Exception::Timeout;
use JSON 'encode_json';
use namespace::autoclean;

has data => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has chunked => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub as_http_request_args {
    my ($self) = @_;

    return +{
        method       => 'POST',
        uri          => 'mapred',
        content_type => 'application/json',
        data         => encode_json($self->data),
        ($self->chunked ? (query => { chunked => 'true' }) : ()),
    };
}

sub _build_http_exception_classes {
    return {
        500 => Data::Riak::Exception::FunctionFailed::,
        503 => Data::Riak::Exception::Timeout::,
    };
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::MapReduce

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
