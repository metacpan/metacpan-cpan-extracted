package Dancer::OO::Object;
use strict;
use Dancer::OO::Dancer qw( debug );

our $VERSION = '0.01';

# this module actually installs deferred and properly stacked uri handlers

sub _build_tree {
	my ($package) = @_;
	return unless $package;
	no strict 'refs';
	return map { $_, _build_tree($_) } @{"$package\::ISA"};
}

# delay declarations
sub import {
	my ( $self, $prefix ) = @_;
	no strict 'refs';
	${"$self\::_prefix"} = $prefix;
	my @tree = ($self, _build_tree($self));
	my %seen;
	foreach my $isa (@tree) {
		foreach ( @{ ${"$isa\::_handler"} } ) {
			my $path = join( '', $_->[0], $prefix, $_->[1] ) || '/';
			next if $seen{$path};
			debug( 'for', $self, $_->[0], $prefix . $_->[1], 'in', $isa);
			$seen{$path} = 1;
			foreach my $handler (@Dancer::OO::Dancer::route_handler) {
				&{"Dancer\::$handler"}( $prefix . $_->[1], $_->[2]->($self) );
			}
		}
	}
}

=head1 NAME

Dancer::OO::Object - root object for all packages

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    use parent 'Dancer::OO::Object';

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=cut

=head1 AUTHOR

Roman Galeev, C<< <jamhedd at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-scoped at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-OO-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::OO::Object

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-OO-Object>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-OO-Object>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-OO-Object>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-OO-Object/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Roman Galeev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dancer::OO::Object
