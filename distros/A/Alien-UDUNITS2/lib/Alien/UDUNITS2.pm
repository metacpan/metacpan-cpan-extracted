package Alien::UDUNITS2;
$Alien::UDUNITS2::VERSION = '0.006';
use strict;
use warnings;

require Alien::Base;
require Exporter;
our @ISA = qw(Alien::Base Exporter);
our @EXPORT_OK = qw(Inline);
use Perl::OSType qw(os_type);
use File::Spec;

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $self = __PACKAGE__->new;
	+{
		LIBS => $self->libs,
		INC => $self->cflags,
		AUTO_INCLUDE => '#include "udunits2.h"',
	};
}

sub libs {
	my ($self) = @_;
	if( os_type() eq 'Windows' ) {
		my $libs = $self->SUPER::libs;
		$libs .= " -lexpat";
		return $libs;
	}
	$self->SUPER::libs;
}

sub units_xml {
	my ($self) = @_;
	my ($file) = grep { -f } map { ( "$_/share/udunits/udunits2.xml", "$_/lib/udunits2.xml" ) } ($self->dist_dir);

	$file;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::UDUNITS2 - Alien package for the UDUNITS-2 physical unit manipulation and conversion library

=head1 VERSION

version 0.006

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

