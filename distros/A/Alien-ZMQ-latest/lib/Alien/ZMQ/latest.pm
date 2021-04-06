package Alien::ZMQ::latest;
# ABSTRACT: Alien package for the ZeroMQ library
$Alien::ZMQ::latest::VERSION = '0.005';
use strict;
use warnings;

use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::ZMQ::latest - Alien package for the ZeroMQ library

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Installs the latest release of ZeroMQ.

=head1 SEE ALSO

L<ZeroMQ|http://zeromq.org/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
