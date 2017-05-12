package Data::Riak::Request::StoreObject;
{
  $Data::Riak::Request::StoreObject::VERSION = '2.0';
}

use Moose;
use Data::Riak::Result::SingleObject;
use Data::Riak::Exception::ConditionFailed;
use Data::Riak::Exception::MultipleSiblingsAvailable;
use namespace::autoclean;

has value => (
    is       => 'ro',
    required => 1,
);

has links => (
    is       => 'ro',
    isa      => 'HTTP::Headers::ActionPack::LinkList',
    required => 1,
);

has return_body => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has content_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_content_type',
);

has indexes => (
    is        => 'ro',
    isa       => 'ArrayRef',
    predicate => 'has_indexes',
);

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'PUT',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
        data   => $self->value,
        links  => $self->links,
        ($self->return_body ?
             (query => { returnbody => 'true' })
             : ()),
        ($self->has_content_type
             ? (content_type => $self->content_type) : ()),
        ($self->has_indexes
             ? (indexes => $self->indexes) : ()),
        headers => {
            ($self->has_vector_clock
                 ? ('x-riak-vclock' => $self->vector_clock) : ()),
            ($self->has_if_unmodified_since
                 ? ('if-unmodified-since' => $self->if_unmodified_since) : ()),
            ($self->has_if_match
                 ? ('if-match' => $self->if_match) : ()),
        },
    };
}

sub _build_http_exception_classes {
    return {
        300 => Data::Riak::Exception::MultipleSiblingsAvailable::,
        412 => Data::Riak::Exception::ConditionFailed::,
    };
}

with 'Data::Riak::Request::WithObject',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleObject::,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::StoreObject

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
