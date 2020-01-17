package My::Module::Recommend;

use strict;
use warnings;

use Carp;
use Config;

use My::Module::Recommend::Any qw{ __any };
use My::Module::Recommend::All qw{ __all };

my ( $is_5_010, $is_5_012 );

if ( $] ge '5.012' ) {
    $is_5_012 = $is_5_010 = 1;
} elsif ( $] ge '5.010' ) {
    $is_5_010 = 1;
};

my %misbehaving_os = map { $_ => 1 } qw{ MSWin32 cygwin };

my @optionals = (
    __any( 'Astro::Coord::ECI::TLE::Iridium'	=> <<'EOD' ),
      This module is needed if you wish to compute Iridium Classic flare
      events. If you do not intend to do this, this module is not
      needed.
EOD
    __any( 'Astro::SIMBAD::Client'	=> <<'EOD' ),
      This module is required for the 'lookup' subcommand of the
      Astro::App::Satpass2 sky() method, which retrieves astronomical
      objects from the SIMBAD database. If you do not intend to use
      this functionality, Astro::SIMBAD::Client is not needed.
EOD
    __any( 'Astro::SpaceTrack=0.105'	=> <<'EOD' ),
      This module is required for the Astro::App::Satpass2 spacetrack()
      method, which retrieves satellite TLE data from Space Track and
      other web sites. Version 0.105 is needed because of a change in
      the way help is displayed. If you intend to get your TLEs
      externally to this package (say, with a web browser or curl),
      Astro::SpaceTrack is not needed.
EOD
    __any( 'Browser::Open'		=> <<'EOD' ),
      This module is being phased in as the only supported way to
      display web-based help. If you intend to leave the 'webcmd'
      attribute false, this module is not needed.
EOD
    __any( 'Date::Manip'		=> <<'EOD' .
      This module is not required, but the alternative to installing it
      is to specify times in ISO 8601 format.  See 'SPECIFYING TIMES' in
      the 'Astro::App::Satpass2' documentation for the details.
EOD
	( $is_5_010 ? '' : <<'EOD' ) ),

      Unfortunately, the current Date::Manip requires Perl 5.10. Since
      you are running an earlier Perl, you can try installing Date-Manip
      5.54, which is the most recent version that does _not_ require
      Perl 5.10. This version of Date::Manip does not understand summer
      time (a.k.a. daylight saving time).
EOD
    __all( qw{ DateTime DateTime::TimeZone }	=> <<'EOD' ),
      These modules are used to format times, and provide full time zone
      support. If they are not installed, POSIX::strftime() will be
      used, and you may find that you can not display correct local
      times for zones other than your system's default zone or GMT. They
      will also be used (if available) by the ISO8601 time parser
      because they go farther into the past than Time::Local does.
EOD

    # CAVEAT:
    #
    # Unfortunately as things currently stand, the version needs to be
    # maintained three places:
    # - lib/Astro/App/Satpass2/Utils.pm
    # - inc/My/Module/Recommend.pm
    # - inc/My/Module/Test/App.pm
    # These all need to stay the same. Sigh.

    __any( 'DateTime::Calendar::Christian=0.06'	=> <<'EOD' ),
      This module is used to parse (maybe) and format dates that might
      be either Julian or Gregorian. Currently the only parser that has
      this capability is ISO8601. If historical dates in the proleptic
      Gregorian calendar are fine with you, you do not need this module.
EOD
    __any( 'Geo::Coder::OSM'		=> <<'EOD' ),
      This module is required for the Astro::App::Satpass2 geocode()
      method, which computes latitude and longitude based on street
      address. If you do not intend to determine your observing
      locations this way, this module is not needed.
EOD
    __any( 'Geo::WebService::Elevation::USGS'	=> <<'EOD' ),
      This module is required for the Astro::App::Satpass2 height()
      method, which determines height above the reference ellipsoid for
      a given latitude and longitude.  If you do not intend to determine
      your observing locations this way, this module is not needed.
EOD
    __all( qw{ LWP::UserAgent LWP::Protocol URI } => <<'EOD' ),
      These modules are required if you want to use URLs in the init(),
      load(), or source() methods. If you do not intend to use URLs
      there, you do not need these packages. All three packages are
      requirements for most of the other Internet-access functionality,
      so you may get them implicitly if you install some of the other
      optional modules.
EOD
	$is_5_012 ? () : __any( 'Time::y2038' => <<'EOD' .
      This module is not required, but if installed allows you to do
      computations for times outside the usual range of system epoch to
      system epoch + 0x7FFFFFFF seconds.
EOD
	( $misbehaving_os{$^O} ? <<"EOD" : '' ) .

      Unfortunately, Time::y2038 has been known to misbehave when
      running under $^O, so you may be better off just accepting the
      restricted time range.
EOD
	( ( $Config{use64bitint} || $Config{use64bitall} ) ? <<'EOD' : '' )

      Since your Perl appears to support 64-bit integers, you may well
      not need Time::y2038 to do computations for times outside the
      so-called 'usual range.' Time::y2038 will be used, though, if it
      is available.
EOD
    ),
    __any( 'Time::HiRes'		=> <<'EOD' ),
      This module is required only for the time() command/method. If
      you do not plan to use this method you do not need this module.
EOD
);

sub make_optional_modules_tests {
    eval {
	require Test::Without::Module;
	1;
    } or return;
    my $dir = 'xt/author/optionals';
    -d $dir
	or mkdir $dir
	or die "Can not create $dir: $!\n";
    opendir my $dh, 't'
	or die "Can not access t/: $!\n";
    while ( readdir $dh ) {
	m/ \A [.] /smx
	    and next;
	m/ [.] t \z /smx
	    or next;
	my $fn = "$dir/$_";
	-e $fn
	    and next;
	print "Creating $fn\n";
	open my $fh, '>:encoding(utf-8)', $fn
	    or die "Can not create $fn: $!\n";
	print { $fh } <<"EOD";
package main;

use strict;
use warnings;

use Test::More 0.88;

use lib qw{ inc };

use My::Module::Recommend;

BEGIN {
    eval {
	require Test::Without::Module;
	Test::Without::Module->import(
	    My::Module::Recommend->optionals() );
	1;
    } or plan skip_all => 'Test::Without::Module not available';
}

do 't/$_';

1;

__END__

# ex: set textwidth=72 :
EOD
    }
    closedir $dh;

    return $dir;
}

sub optionals {
    return ( map { $_->modules() } @optionals );
}

sub recommend {
    my $need_some;
    foreach my $mod ( @optionals ) {
	defined( my $msg = $mod->recommend() )
	    or next;
	$need_some++
	    or warn <<'EOD';

The following optional modules were not available:
EOD
	warn "\n$msg";
    }
    $need_some
	and warn <<'EOD';

It is not necessary to install these now. If you decide to install them
later, this software will make use of them when it finds them.

EOD

    return;
}

1;

__END__

=head1 NAME

My::Module::Recommend - Recommend modules to install. 

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Recommend;
 My::Module::Recommend->recommend();

=head1 DETAILS

This package generates the recommendations for optional modules. It is
intended to be called by the build system. The build system's own
mechanism is not used because we find its output on the Draconian side.

=head1 METHODS

This class supports the following public methods:

=head2 make_optional_modules_tests

 My::Module::Recommend->make_optional_modules_tests()

This static method creates the optional module tests. These are stub
files in F<xt/author/optionals/> that use C<Test::Without::Module> to
hide all the optional modules and then invoke the normal tests in F<t/>.
The aim of these tests is to ensure that we get no test failures if the
optional modules are missing.

This method is idempotent; that is, it only creates the directory and
the individual stub files if they are missing.

On success this method returns the name of the optional tests directory.
If C<Test::Without::Module> can not be loaded this method returns
nothing. If the directory or any file can not be created, an exception
is thrown.

=head2 optionals

 say for My::Module::Recommend->optionals();

This static method simply returns the names of the optional modules.

=head2 recommend

 My::Module::Recommend->recommend();

This static method examines the current Perl to see which optional
modules are installed. If any are not installed, a message is printed to
standard out explaining the benefits to be gained from installing the
module, and any possible problems with installing it.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
