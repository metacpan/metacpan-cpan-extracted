package My::Module::Test;

use 5.006002;

use strict;
use warnings;

our $VERSION = '0.128';

use Exporter qw{ import };

use Astro::Coord::ECI::TLE qw{ :constants };
use Astro::Coord::ECI::Utils qw{ rad2deg };
use Test::More 0.88;

use constant CODE_REF	=> ref sub {};

our @EXPORT_OK = qw{
    magnitude
};
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub magnitude {
    my ( $tle, @arg ) = @_;
    my ( $time, $want, $name ) = splice @arg, -3;
    my $got;
    eval {
	$got = $tle->universal( $time )->magnitude( @arg );
	defined $got
	    and $got = sprintf '%.1f', $got;
	1;
    } or do {
	@_ = "$name failed: $@";
	goto &fail;
    };
    if ( defined $want ) {
	$want = sprintf '%.1f', $want;
	@_ = ( $got, 'eq', $want, $name );
	goto &cmp_ok;
    } else {
	@_ = ( ! defined $got, $name );
	goto &ok;
    }
}

1;

__END__

=head1 NAME

My::Module::Test - Useful subroutines for testing

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test qw{ :all };
 
 magnitude( $tle, $time, -3.0, 'Magnitude of satellite' );

=head1 DESCRIPTION

This module is private to the My::Module package. The author
reserves the right to change or revoke it without notice.

This module is a repository for subroutines used in testing
L<My::Module|My::Module>.

=head1 SUBROUTINES

The following public subroutines are exported by this module. None of
them are exported by default, but export tag C<:all> exports all of
them.

=head2 magnitude

 magnitude( $tle, $station, $time, $want, $name );
 magnitude( $tle, $time, $want, $name );

This subroutine tests whether the magnitude of the satellite specified
by C<$tle>, seen from the given C<$station> at the given C<$time>, has
the value C<$want> to one decimal place. Argument C<$name> is the name
of the test.

If argument C<$station> is omitted, the C<station> attribute of the TLE
is used.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
