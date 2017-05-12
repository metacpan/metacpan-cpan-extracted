package Data::Riak::Request;
{
  $Data::Riak::Request::VERSION = '2.0';
}
# ABSTRACT: A request to Riak

use Moose::Role;
use MooseX::StrictConstructor;
use namespace::autoclean;


has result_class => (
    is      => 'ro',
    isa     => 'ClassName',
    default => Data::Riak::Result::,
    handles => {
        new_result  => 'new',
        result_does => 'does',
    },
);


requires qw(as_http_request_args);

has retval_mangler => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        sub { $_[0] };
    },
);

sub _mangle_retval {
    my ($self, $ret) = @_;
    $self->retval_mangler->($_[1]);
}

1;

__END__

=pod

=head1 NAME

Data::Riak::Request - A request to Riak

=head1 VERSION

version 2.0

=head1 DESCRIPTION

This role is implemented by all available request classes in Data::Riak. Please
see below for a list of all request classes and their associated result classes.

Refer to the specialised request and result classes for their respective
documentation.

=head1 REQUEST CLASSES

=over 4

=item L<Data::Riak::Request::GetBucketProps>

L<Data::Riak::Result::SingleJSONValue>

=item L<Data::Riak::Request::GetObject>

L<Data::Riak::Result::SingleObject>

=item L<Data::Riak::Request::LinkWalk>

L<Data::Riak::Result::Object>

=item L<Data::Riak::Request::ListBucketKeys>

L<Data::Riak::Result::SingleJSONValue>

=item L<Data::Riak::Request::ListBuckets>

L<Data::Riak::Result::SingleJSONValue>

=item L<Data::Riak::Request::MapReduce>

L<Data::Riak::Result>

=item L<Data::Riak::Request::Ping>

L<Data::Riak::Result::SingleValue>

=item L<Data::Riak::Request::RemoveObject>

L<Data::Riak::Result::MaybeVClock>

=item L<Data::Riak::Request::SetBucketProps>

L<Data::Riak::Result>

=item L<Data::Riak::Request::Status>

L<Data::Riak::Result::SingleJSONValue>

=item L<Data::Riak::Request::StoreObject>

L<Data::Riak::Result::SingleObject>

=back

=head1 REQUIRED METHODS

=head2 as_http_request_args

In order to be able to send requests through the HTTP backend,
L<Data::Riak::HTTP>, requests need to be able to describe themselfs as
L<HTTP::Request>s.

This method is required to return constructor arguments for L<HTTP::Request>.

=head1 ATTRIBUTES

=head2 result_class

Class describing the result of a given request. See L<Data::Riak::Result>.

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
