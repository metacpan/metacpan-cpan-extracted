package Alien::UDUNITS2;
$Alien::UDUNITS2::VERSION = '0.007';
use strict;
use warnings;

require Alien::Base;
require Exporter;
our @ISA = qw(Alien::Base Exporter);
our @EXPORT_OK = qw(Inline);
use Perl::OSType qw(os_type);
use File::Spec;

sub inline_auto_include {
	[ 'udunits2.h' ];
}

sub cflags {
	my ($class) = @_;

	$class->install_type eq 'share'
		? '-I' . File::Spec->catfile($class->dist_dir, qw(include))
		: $class->SUPER::cflags;
}

sub libs {
	my ($class) = @_;

	my $path = $class->install_type eq 'share'
		? '-L' . File::Spec->catfile($class->dist_dir, qw(lib))
		: $class->SUPER::cflags;

	join ' ', (
		$path,
		'-ludunits2',
		( $^O eq 'darwin' || $^O eq 'MSWin32' ? '-lexpat' : '')
	);

}

sub Inline {
	my ($class, $lang) = @_;
	return unless $lang eq 'C'; # Inline's error message is good
	my $params = Alien::Base::Inline(@_);

	# Use static linking instead of dynamic linking. This works
	# better on some platforms. On macOS, to use dynamic linking,
	# the `install_name` of the library must be set, but since this
	# is the final path by default, linking to the `.dylib` under
	# `blib/` at test time does not work without using `@rpath`.
	if( $^O eq 'darwin' and $class->install_type eq 'share' ) {
		$params->{MYEXTLIB} .= ' ' .
			join( " ",
				map { File::Spec->catfile(
					File::Spec->rel2abs($class->dist_dir),
					'lib',  $_ ) }
				qw(libudunits2.a)
			);
		$params->{LIBS} =~ s/-ludunits2//g;
	}

	$params;
}

sub units_xml {
	my ($self) = @_;

	my ($file) = grep
		{ -f }
		map {
			(
				"$_/share/xml/udunits/udunits2.xml",
				"$_/share/udunits/udunits2.xml",
				"$_/lib/udunits2.xml"
			)
		} (
			$self->install_type eq 'share'
			? $self->dist_dir
			: "/usr"
		);

	$file;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::UDUNITS2 - Alien package for the UDUNITS-2 physical unit manipulation and conversion library

=head1 VERSION

version 0.007

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<UDUNITS-2|http://www.unidata.ucar.edu/software/udunits/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: Alien package for the UDUNITS-2 physical unit manipulation and conversion library

