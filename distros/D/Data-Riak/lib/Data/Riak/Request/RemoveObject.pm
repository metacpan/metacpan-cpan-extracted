package Data::Riak::Request::RemoveObject;
{
  $Data::Riak::Request::RemoveObject::VERSION = '2.0';
}

use Moose;
use Data::Riak::Result::MaybeVClock;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'DELETE',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
    };
}

sub _build_http_exception_classes {
    return {
        404 => undef,
    };
}

with 'Data::Riak::Request::WithObject',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::MaybeVClock::,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::RemoveObject

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
