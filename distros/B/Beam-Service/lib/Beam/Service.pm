package Beam::Service;
our $VERSION = '0.001';
# ABSTRACT: Role for services to access Beam::Wire features

#pod =head1 SYNOPSIS
#pod
#pod     package My::Object;
#pod     use Role::Tiny::With; # or Moo, or Moose
#pod     with 'Beam::Service';
#pod
#pod     package main;
#pod     use Beam::Wire;
#pod     my $wire = Beam::Wire->new(
#pod         config => {
#pod             my_object => {
#pod                 '$class' => 'My::Object',
#pod             },
#pod         },
#pod     );
#pod
#pod     print $wire->get( 'my_object' )->name; # my_object
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role adds extra functionality to an object that is going to be used
#pod as a service in a L<Beam::Wire> container. While any object can be
#pod configured with Beam::Wire, consuming the Beam::Service role allows an
#pod object to know its own name and to access the container it was
#pod configured in to fetch other objects that it needs.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Wire>
#pod
#pod =cut

use strict;
use warnings;
use Moo::Role;
use Types::Standard qw( Str InstanceOf );

#pod =attr name
#pod
#pod The name of the service. This is the name used in the L<Beam::Wire>
#pod configuration file for this service.
#pod
#pod =cut

has name => (
    is => 'ro',
    isa => Str,
);

#pod =attr container
#pod
#pod The L<Beam::Wire> container object that contained this service. Using
#pod this container we can get other services as-needed.
#pod
#pod =cut

has container => (
    is => 'ro',
    isa => InstanceOf['Beam::Wire'],
);

1;

__END__

=pod

=head1 NAME

Beam::Service - Role for services to access Beam::Wire features

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package My::Object;
    use Role::Tiny::With; # or Moo, or Moose
    with 'Beam::Service';

    package main;
    use Beam::Wire;
    my $wire = Beam::Wire->new(
        config => {
            my_object => {
                '$class' => 'My::Object',
            },
        },
    );

    print $wire->get( 'my_object' )->name; # my_object

=head1 DESCRIPTION

This role adds extra functionality to an object that is going to be used
as a service in a L<Beam::Wire> container. While any object can be
configured with Beam::Wire, consuming the Beam::Service role allows an
object to know its own name and to access the container it was
configured in to fetch other objects that it needs.

=head1 ATTRIBUTES

=head2 name

The name of the service. This is the name used in the L<Beam::Wire>
configuration file for this service.

=head2 container

The L<Beam::Wire> container object that contained this service. Using
this container we can get other services as-needed.

=head1 SEE ALSO

L<Beam::Wire>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
