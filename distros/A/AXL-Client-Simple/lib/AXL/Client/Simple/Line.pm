package AXL::Client::Simple::Line;
use Moose;

has stash => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has extn => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    lazy_build => 1,
);

sub _build_extn { return (shift)->stash->{pattern} }

has alertingName => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    lazy_build => 1,
);

sub _build_alertingName { return (shift)->stash->{alertingName} }

__PACKAGE__->meta->make_immutable;
no Moose;
1;
