package Alien::MuPDF;
$Alien::MuPDF::VERSION = '0.010';
use strict;
use warnings;

use parent qw(Alien::Base);
use File::Spec;

sub mutool_path {
	my ($self) = @_;
	File::Spec->catfile( File::Spec->rel2abs($self->dist_dir) , 'bin', 'mutool' );
}

sub inline_auto_include {
	return  [ 'mupdf/fitz.h' ];
}

sub cflags {
	my ($self) = @_;
	my $top_include = File::Spec->catfile( File::Spec->rel2abs($self->dist_dir), qw(include) );
	# We do not include $self->SUPER::cflags() because that adds too many
	# header files to the path. In particular, it adds -Imupdf/fitz, which
	# leads to "mupdf/fitz/math.h" being included when trying to include
	# the C standard "math.h" header.
	return "-I$top_include";
}

sub libs {
	# third party
	"-lcrypto";
}

sub Inline {
	my ($self, $lang) = @_;

	if('C') {
		my $params = Alien::Base::Inline(@_);
		$params->{MYEXTLIB} .= ' ' .
			join( " ",
				map { File::Spec->catfile(
					File::Spec->rel2abs(Alien::MuPDF->dist_dir),
					'lib',  $_ ) }
				qw(libmupdf.a libmupdfthird.a)
			);
		$params->{PRE_HEAD} = <<'		EOF';
		#if defined(_MSC_VER) || defined(__MINGW32__)
		#  define NO_XSLOCKS /* To avoid PerlProc_setjmp/PerlProc_longjmp unresolved symbols */
		#endif
		EOF

		return $params;
	}
}

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::MuPDF - Alien package for the MuPDF PDF rendering library

=head1 VERSION

version 0.010

=head1 METHODS

=head2 mutool_path

Returns a C<Str> which contains the absolute path
to the C<mutool> binary.

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<MuPDF|http://mupdf.com/>

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Alien-MuPDF/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: Alien package for the MuPDF PDF rendering library

