package Catalyst::TraitFor::Request::GeoIP;
our $VERSION = '0.01';

# ABSTRACT: Geo lookups for Catalyst::Requests via Geo::IP

use Moose::Role;
use Geo::IP;
use namespace::autoclean;

has geoip_by_addr => (is => 'ro', isa => 'Maybe[Geo::IP::Record]', lazy => 1, builder => '_build_geoip_by_addr');

has geoip => (
    is      => 'ro',
    isa     => 'Geo::IP',
    lazy    => 1,
    default => sub { Geo::IP->open("/usr/local/share/GeoIP/GeoIPCity.dat", GEOIP_MEMORY_CACHE) },
);

requires 'address';

sub _build_geoip_by_addr {
    my ($self) = @_;
    my $r = $self->geoip->record_by_addr($self->address);
    return unless $r;
    return $r;
}

1;


__END__
=pod

=head1 NAME

Catalyst::TraitFor::Request::GeoIP - Geo lookups for Catalyst::Requests via Geo::IP

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use namespace::autoclean;

    use Catalyst;
    use CatalystX::RoleApplicator;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::GeoIP
    /);

    __PACKAGE__->setup;

=head1 DESCRIPTION

Extend request objects with a method for geo lookups.

=head1 ATTRIBUTES

=head2 geoip_by_addr

    my $record = $ctx->request->geoip_by_addr;

Returns an C<Geo::IP::Record> instance for the request. This allows you to
get information about the client's location.

=head1 AUTHOR

Matthias Dietrich <perl@rainboxx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Matthias Dietrich.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

