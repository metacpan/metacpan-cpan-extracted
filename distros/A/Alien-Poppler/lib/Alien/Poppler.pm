package Alien::Poppler;
# ABSTRACT: Alien package for the Poppler PDF rendering library
$Alien::Poppler::VERSION = '0.002';
use strict;
use warnings;

use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

use File::Spec;
use File::Which;
use ExtUtils::PkgConfig;

sub pdftotext_path {
	my ($class) = @_;
	if( $class->install_type eq 'share' ) {
		return File::Spec->catfile( File::Spec->rel2abs($class->dist_dir) , qw(bin pdftotext) );
	} else {
		return which('pdftotext');
	}
}

sub pkg_config_path {
	my ($class) = @_;
	if( $class->install_type eq 'share' ) {
		return File::Spec->catfile( File::Spec->rel2abs($class->dist_dir), qw(lib pkgconfig) );
	} else {
		return ExtUtils::PkgConfig->variable('poppler', 'pcfiledir');
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Poppler - Alien package for the Poppler PDF rendering library

=head1 VERSION

version 0.002

=head1 METHODS

=head2 pdftotext_path

Returns a C<Str> which contains the absolute path
to the C<pdftotext> binary.

=head1 SEE ALSO

L<Poppler|https://poppler.freedesktop.org/>

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Alien-Poppler/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
