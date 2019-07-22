package My::Module::Test::Geocode;

use 5.008;

use strict;
use warnings;

use Exporter ();
our @ISA = qw{ Exporter };

use Astro::App::Satpass2::Utils qw{ load_package };
use Test::More 0.88;

our $VERSION = '0.040';

our @EXPORT_OK = qw{ setup geocode };
our @EXPORT = @EXPORT_OK;

my $wrapper_class;
my $wrapper_object;

sub setup ($) {
    ( $wrapper_class ) = @_;

    load_package( $wrapper_class )
	or plan skip_all => "Unable to load $wrapper_class: $@";

    my $geocoder_class = $wrapper_class->GEOCODER_CLASS();

    load_package( $geocoder_class )
	or plan skip_all => "$geocoder_class not available";

    load_package( 'LWP::UserAgent' )
	or plan skip_all => 'LWP::UserAgent not available';

    my $url = $wrapper_class->GEOCODER_SITE();
    my $rslt = LWP::UserAgent->new()->get( $url )
	or plan skip_all => "No access to $url: " . $@ || 'Unknown error';
    $rslt->is_success
	or plan skip_all => "No access to $url: ", $rslt->status_line();

    eval {
	$wrapper_object = $wrapper_class->new();
    } or do {
	@_ = ( "Failed to instantiate $wrapper_class: $@" );
	goto &fail;
    };

    @_ = ( "Instantiate $wrapper_class" );
    goto &pass;
}

sub geocode ($;$) {
    my ( $loc, $tests ) = @_;
    defined $tests
	or $tests = 1;

    $wrapper_object
	or skip "$wrapper_class instantiation failed", 1;

    () = eval {	# Force eval() to be in list context.
	$wrapper_object->geocode( $loc )
    } and do {
	@_ = ( "Geocode '$loc'" );
	goto &pass;
    };

    my $resp = $wrapper_object->geocoder()->response();
    my $msg = sprintf '%s - %s',
    $wrapper_object->GEOCODER_SITE(),
    $resp->status_line();

    500 == $resp->code()
	and skip $msg, $tests;

    @_ = ( $msg );
    goto &fail;
}


1;

__END__

=head1 NAME

My::Module::Test::Geocode - Tests for geocode wrappers

=head1 SYNOPSIS

 use lib qw{ inc };
 use Test::More 0.88;
 use My::Module::Test::Geocode;
 setup 'Astro::App::Satpass2::Geocode::OSM';
 SKIP: {
     geocode '1600 Pennsylvania Ave, Washington DC', 1;
 }
 done_testing;

=head1 DESCRIPTION

This package provides the boiler plate for testing the geocode wrapper
objects.

=head1 SUBROUTINES

The following subroutines are both prototyped and exported by default.

=head2 setup

 setup 'Astro::App::Satpass2::Geocoder::OSM';

This subroutine loads both the specified class and the class
it wraps. Then it probes the web site that provides the geocoding
service. If any of these actions fails, a C<plan skip_all => $reason> is
issued, and no testing is done.

If we get this far, a test is run to see if the desired class can be
instantiated.

The prototype for this subroutine is C<($)>.

=head2 geocode

 SKIP: {
     geocode '1600 Pennsylvania Ave, Washington DC', 1;
 }

This subroutine attempts to geocode a location. The arguments are the
location to geocode and the number of tests to skip if the logic decides
a skip is called for. Yes, this subroutine must be wrapped in a SKIP
block.

The returned geocoding is not checked, because of the difficulty of
tracking database changes, and because if the wrapped class does not do
this (e.g.  L<Geo::Coder::OSM|Geo::Coder::OSM>) why should I?

The cases checked for and their outcomes are:

=over

=item setup failed or not called: skip

=item geocoding succeeded: pass

=item 500 error: skip

=item any other error: fail

=back

The prototype for this subroutine is C<($;$)>. The default for the
second argument (number of tests to skip) is C<1>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
