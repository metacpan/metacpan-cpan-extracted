package Algorithm::Dependency::Source::Invert;
# ABSTRACT: Logically invert a source

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   my $inverted = Algorithm::Dependency::Source::Invert->new( $source );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class creates a source from another source, but with all dependencies
#pod reversed.
#pod
#pod =cut

use 5.005;
use strict;
use Params::Util '_INSTANCE';
use Algorithm::Dependency::Source::HoA ();

our $VERSION = '1.112';
our @ISA     = 'Algorithm::Dependency::Source::HoA';


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Dependency::Source::Invert - Logically invert a source

=head1 VERSION

version 1.112

=head1 SYNOPSIS

  my $inverted = Algorithm::Dependency::Source::Invert->new( $source );

=head1 DESCRIPTION

This class creates a source from another source, but with all dependencies
reversed.

=head1 SEE ALSO

L<Algorithm::Dependency::Source>, L<Algorithm::Dependency::Source::HoA>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Dependency>
(or L<bug-Algorithm-Dependency@rt.cpan.org|mailto:bug-Algorithm-Dependency@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
