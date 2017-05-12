package Data::Riak::HTTP::Request;
{
  $Data::Riak::HTTP::Request::VERSION = '2.0';
}

use strict;
use warnings;

use Moose;

use HTTP::Headers::ActionPack::LinkList;

with 'Data::Riak::Transport::Request';

has method => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has uri => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has query => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_query'
);

has data => (
    is => 'ro',
    isa => 'Str',
    default => ''
);

has links => (
    is => 'ro',
    isa => 'HTTP::Headers::ActionPack::LinkList',
    # TODO: make this coerce
    default => sub {
        return HTTP::Headers::ActionPack::LinkList->new;
    }
);

has indexes => (
    is => 'ro',
    isa => 'ArrayRef[HashRef]'
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    default => 'text/plain'
);

has accept => (
    is => 'ro',
    isa => 'Str',
    default => '*/*'
);

has headers => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_headers',
);

sub _build_headers { +{} }

sub BUILD {
    my ($self) = @_;
    $self->headers;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Data::Riak::HTTP::Request

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
