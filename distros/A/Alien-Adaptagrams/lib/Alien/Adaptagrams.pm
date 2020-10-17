package Alien::Adaptagrams;
# ABSTRACT: Alien package for the Adaptagrams adaptive diagram library
$Alien::Adaptagrams::VERSION = '0.001';
use strict;
use warnings;

use parent qw(Alien::Base);

sub pkg_config_path {
	my ($class) = @_;
	if( $class->install_type eq 'share' ) {
		return File::Spec->catfile( File::Spec->rel2abs($class->dist_dir), qw(lib pkgconfig) );
	} else {
		return ExtUtils::PkgConfig->variable('libcola', 'pcfiledir');
	}
}

sub Inline {
	my ($self, $lang) = @_;

	my @libs = qw(avoid vpsc dialect topology cola);
	if( $lang =~ /^CPP$/ ) {
		my $params = Alien::Base::Inline(@_);

		# Use static linking instead of dynamic linking. This works
		# better on some platforms. On macOS, to use dynamic linking,
		# the `install_name` of the library must be set, but since this
		# is the final path by default, linking to the `.dylib` under
		# `blib/` at test time does not work without using `@rpath`.
		if( $^O eq 'darwin' and $self->install_type eq 'share' ) {
			$params->{MYEXTLIB} .= ' ' .
				join( " ",
					map { File::Spec->catfile(
						File::Spec->rel2abs(Alien::Adaptagrams->dist_dir),
						'lib',  "lib$_.a" ) }
					@libs
				);
			$params->{LIBS} =~ s/-l$_//g for @libs;
		}

		$params->{PRE_HEAD} = <<'		EOF';
		#if defined(_MSC_VER) || defined(__MINGW32__)
		#  define NO_XSLOCKS /* To avoid Perl wrappers of C library */
		#endif
		EOF


		return $params;
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Adaptagrams - Alien package for the Adaptagrams adaptive diagram library

=head1 VERSION

version 0.001

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<Adaptagrams|http://www.adaptagrams.org/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
