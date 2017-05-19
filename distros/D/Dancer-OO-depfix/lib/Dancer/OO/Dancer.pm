package Dancer::OO::Dancer;
use strict;
use Dancer ();
use YAML;

our $VERSION = '0.01';

our @route_handler = qw( get post any patch del options put );

sub debug {
	Dancer::debug( join( ' ', map { ref $_ ? Dump($_) : $_ } map { $_ ? $_ : '_' } @_ ) );
}

sub import {
	my ($self) = @_;
	my $class = caller;
	no strict 'refs';

	# redefine router handlers
	foreach my $handler (@route_handler) {
		*{"$class\::$handler"} = sub {
			push @{ ${"$class\::_handler"} }, [ $handler, @_ ];
		};
	}

	# dancer improvements
	*{"$class\::template"} = sub {
		my ( $self, $template, $args ) = @_;
		$args = {} unless $args;
		$args->{uri} = sub { join( '', ${"$self\::_prefix"}, $_[0] ) };
		my $k = join( '/', ${"$self\::_prefix"}, 'pager' );
		$args->{c} ||= Dancer::session($k) || {};
		return Dancer::template( join( '/', ${"$self\::_prefix"}, $template ), $args );
	};

	*{"$class\::wrap"}         = sub (&) {
		my ($handler) = @_;
		return sub {
			my ($self) = @_;
			return sub {
				my $params	= Dancer::params;
				my $context	= Dancer::session;
				my $ret     = $handler->( $self, $context, $params );
				Dancer::session( $context );
				return $ret;
			  }
		  }
	};

	*{"$class\::debug"} = \&debug;

	# suck in all Dancer methods
	for my $method (@Dancer::EXPORT) {
		*{"$class\::$method"} = *{"Dancer\::$method"} if not defined &{"$class\::$method"};
	}
}

=head1 NAME

Dancer::OO::Dancer - Allows to set params variables in scope of route handler

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    use Dancer::OO::Dancer;

=head1 EXPORT

All Dancer methods

=head1 SUBROUTINES/METHODS

=head2 debug

A replacement for default Dancer debug with automatic objects dumping with YAML::Dump method.

=cut

=head1 AUTHOR

Roman Galeev, C<< <jamhedd at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-scoped at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-OO-Dancer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::OO::Dancer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-OO-Dancer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-OO-Dancer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-OO-Dancer>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-OO-Dancer/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Roman Galeev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dancer::OO::Dancer
