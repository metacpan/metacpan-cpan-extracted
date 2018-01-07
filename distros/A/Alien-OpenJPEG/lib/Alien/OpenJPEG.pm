package Alien::OpenJPEG;
# ABSTRACT: Alien package for the OpenJPEG library
$Alien::OpenJPEG::VERSION = '0.002';
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

Alien::OpenJPEG - Alien package for the OpenJPEG library

=head1 VERSION

version 0.002

=head1 SEE ALSO

L<OpenJPEG|http://www.openjpeg.org/>

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Alien-OpenJPEG/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
