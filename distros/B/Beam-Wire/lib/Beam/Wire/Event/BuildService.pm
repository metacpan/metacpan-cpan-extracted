package Beam::Wire::Event::BuildService;
our $VERSION = '1.026';
# ABSTRACT: Event fired when building a new service

#pod =head1 SYNOPSIS
#pod
#pod     my $wire = Beam::Wire->new( ... );
#pod     $wire->on( build_service => sub {
#pod         my ( $event ) = @_;
#pod         print "Built service named " . $event->service_name;
#pod     } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This event is fired when a service is built. See
#pod L<Beam::Wire/build_service>.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod This class inherits from L<Beam::Event> and adds the following attributes.
#pod
#pod =cut

use Moo;
use Types::Standard qw( Any Str );
extends 'Beam::Event';

#pod =attr emitter
#pod
#pod The container that is listening for the event.
#pod
#pod =attr service_name
#pod
#pod The name of the service being built.
#pod
#pod =cut

has service_name => (
    is => 'ro',
    isa => Str,
);

#pod =attr service
#pod
#pod The newly-built service.
#pod
#pod =cut

has service => (
    is => 'ro',
    isa => Any,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Beam::Wire::Event::BuildService - Event fired when building a new service

=head1 VERSION

version 1.026

=head1 SYNOPSIS

    my $wire = Beam::Wire->new( ... );
    $wire->on( build_service => sub {
        my ( $event ) = @_;
        print "Built service named " . $event->service_name;
    } );

=head1 DESCRIPTION

This event is fired when a service is built. See
L<Beam::Wire/build_service>.

=head1 ATTRIBUTES

This class inherits from L<Beam::Event> and adds the following attributes.

=head2 emitter

The container that is listening for the event.

=head2 service_name

The name of the service being built.

=head2 service

The newly-built service.

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
