package Beam::Wire::Event::ConfigService;
our $VERSION = '1.024';
# ABSTRACT: Event fired when configuring a new service

#pod =head1 SYNOPSIS
#pod
#pod     my $wire = Beam::Wire->new( ... );
#pod     $wire->on( configure_service => sub {
#pod         my ( $event ) = @_;
#pod         print "Configuring service named " . $event->service_name;
#pod     } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This event is fired when a service is configured. See
#pod L<Beam::Wire/configure_service>.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod This class inherits from L<Beam::Event> and adds the following attributes.
#pod
#pod =cut

use Moo;
use Types::Standard qw( HashRef Str );
extends 'Beam::Event';

#pod =attr emitter
#pod
#pod The container that is listening for the event.
#pod
#pod =attr service_name
#pod
#pod The name of the service being configured.
#pod
#pod =cut

has service_name => (
    is => 'ro',
    isa => Str,
);

#pod =attr config
#pod
#pod The normalized configuration for the service (see L<Beam::Wire/normalize_config>).
#pod
#pod =cut

has config => (
    is => 'ro',
    isa => HashRef,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Beam::Wire::Event::ConfigService - Event fired when configuring a new service

=head1 VERSION

version 1.024

=head1 SYNOPSIS

    my $wire = Beam::Wire->new( ... );
    $wire->on( configure_service => sub {
        my ( $event ) = @_;
        print "Configuring service named " . $event->service_name;
    } );

=head1 DESCRIPTION

This event is fired when a service is configured. See
L<Beam::Wire/configure_service>.

=head1 ATTRIBUTES

This class inherits from L<Beam::Event> and adds the following attributes.

=head2 emitter

The container that is listening for the event.

=head2 service_name

The name of the service being configured.

=head2 config

The normalized configuration for the service (see L<Beam::Wire/normalize_config>).

=head1 AUTHORS

=over 4

=item *

Doug Bell <preaction@cpan.org>

=item *

Al Newkirk <anewkirk@ana.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
