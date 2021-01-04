package My::Module::Recommend;

use strict;
use warnings;

use Carp;
use Config;
use My::Module::Recommend::Any qw{ __any };
use My::Module::Recommend::All qw{ __all };

my %misbehaving_os = map { $_ => 1 } qw{ MSWin32 cygwin };

my @optionals = (
    __any( 'Astro::Coord::ECI::TLE::Iridium'	=> <<'EOD' ),
      This module is needed if you wish to compute Iridium Classic flare
      events. If you do not intend to do this, this module is not
      needed.
EOD
    __any( 'Astro::SIMBAD::Client'	=> <<'EOD' ),
      This module is required for the 'satpass' script's 'sky lookup'
      command, but is otherwise unused by this package. If you do not
      intend to use this functionality, this module is not needed.
EOD
    __any( [ 'Astro::SpaceTrack' => 0.052 ]	=> <<'EOD' ),
      This module is required for the 'satpass' script's 'st' command,
      but is otherwise unused by this package. If you do not intend to
      use this functionality, this module is not needed.
EOD
    __any( 'Date::Manip'		=> <<'EOD'
      This module is not required, but the alternative to installing it
      is to specify times to the 'satpass' script in ISO 8601 format.
      See 'SPECIFYING TIMES' in the 'satpass' documentation for the
      details.
EOD
	. ( $] < 5.010 ? <<'EOD' : '' ) ),

      Unfortunately, the current Date::Manip requires Perl 5.10. Since
      you are running an earlier Perl, you can try installing Date-Manip
      5.54, which is the most recent version that does _not_ require
      Perl 5.10.
EOD
    __any( 'Geo::Coder::OSM'			=> <<'EOD' ),
      This module is required for the 'satpass' script's 'geocode'
      command, but is otherwise unused by this package. If you do not
      intend to use this functionality, this module is not needed.
EOD
    __any( 'Geo::WebService::Elevation::USGS'	=> <<'EOD' ),
      This module is required for the 'satpass' script's 'height'
      command, but is otherwise unused by this package. If you do not
      intend to use this functionality, this module is not needed.
EOD
    ( ( $] >= 5.008 && $Config{useperlio} ) ? () :
    __any( 'IO::String'				=> <<'EOD' ) ),
      You appear to have a version of Perl earlier than 5.8, or one
      which is not configured to use perlio. Under this version of Perl
      IO::String is required by the 'satpass' script if you wish to pass
      commands on the command line, or to define macros. If you do not
      intend to do these things, this module is not needed.
EOD
    __any( 'JSON'				=> <<'EOD' ),
      This module is required for Astro::Coord::ECI::TLE to parse
      orbital data in JSON format. If you do not intend to do this, this
      module is not needed.
EOD
    ( $] >= 5.012 ? () :
    __any( 'Time::y2038'			=> <<'EOD'
      This module is not required, but if installed allows you to do
      computations for times outside the usual range of system epoch to
      system epoch + 0x7FFFFFFF seconds.
EOD
	. ( $misbehaving_os{$^O} ? <<"EOD" : '' )

      Unfortunately, Time::y2038 has been known to misbehave when
      running under $^O, so you may be better off just accepting the
      restricted time range.
EOD
	. ( ( $Config{use64bitint} || $Config{use64bitall} ) ? <<'EOD' : '' ) ) ),
	    and $recommendation .= <<'EOD';

      Since your Perl appears to support 64-bit integers, you may well
      not need Time::y2038 to do computations for times outside the
      so-called 'usual range.' It will be used, though, if it is
      available.
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
    local $_ = undef;
    while ( defined( $_ = readdir $dh ) ) {
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
	    My::Module::Recommend->test_without() );
	1;
    } or plan skip_all => 'Test::Without::Module not available';
}

do './t/$_';

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

sub test_without {
    return ( map { $_->test_without() } @optionals );
}

1;

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
standard error explaining the benefits to be gained from installing the
module, and any possible problems with installing it.

=head2 test_without

 say for My::Module::Recommend->test_without();

This static method simply returns the names of the modules to be tested
without.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-Astro-Coord-ECI/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

__END__

# ex: set textwidth=72 :
