package Algorithm::Dependency::Source::Invert;

=pod

=head1 NAME

Algorithm::Dependency::Source::Invert - Logically invert a source

=head1 SYNOPSIS

  my $inverted = Algorithm::Dependency::Source::Invert->new( $source );

=head1 DESCRIPTION

This class creates a source from another source, but with all dependencies
reversed.

=cut

use 5.005;
use strict;
use Params::Util '_INSTANCE';
use Algorithm::Dependency::Source::HoA ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.110';
	@ISA     = 'Algorithm::Dependency::Source::HoA';
}





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my $source = _INSTANCE(shift, 'Algorithm::Dependency::Source') or return undef;

	# Derive a HoA from the original source
	my @items = $source->items;
	my %hoa   = map { $_->id => [ ] } @items;
	foreach my $item ( @items ) {
		my $id   = $item->id;
		my @deps = $item->depends;
		foreach my $dep ( @deps ) {
			push @{ $hoa{$dep} }, $id;
		}
	}

	# Hand off to the parent class
	$class->SUPER::new( \%hoa );
}

1;

=pod

=head1 SUPPORT

To file a bug against this module, use the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency>

For other comments, contact the author.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<Algorithm::Dependency::Source>, L<Algorithm::Dependency::Source::HoA>

=head1 COPYRIGHT

Copyright 2003 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
