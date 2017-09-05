package Alien::FontForge;
# ABSTRACT: Alien package for the FontForge library
$Alien::FontForge::VERSION = '0.001';
use strict;
use warnings;

use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

use File::Spec;

sub pkg_config_path {
	my ($class) = @_;
	File::Spec->catfile($class->dist_dir, qw(lib pkgconfig));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::FontForge - Alien package for the FontForge library

=head1 VERSION

version 0.001

=head1 SEE ALSO

L<FontForge|http://fontforge.github.io/>

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Alien-FontForge/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
