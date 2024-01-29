package main;

use strict;
use warnings;

use Test::More 0.88;

use Astro::Coord::ECI::Utils 0.112 qw{ greg_time_gm greg_time_local };
use Astro::App::Satpass2::ParseTime;

use lib qw{ inc };

use My::Module::Test::App;


klass( 'Astro::App::Satpass2::ParseTime' );

call_m( new => class => 'Astro::App::Satpass2::ParseTime::Code',
    code	=> \&parser,
    INSTANTIATE, 'Instantiate' );

isa_ok invocant, 'Astro::App::Satpass2::ParseTime::Code';

isa_ok invocant, 'Astro::App::Satpass2::ParseTime';

call_m( 'delegate',
    'Astro::App::Satpass2::ParseTime::Code',
    'Delegate is Astro::App::Satpass2::ParseTime::Code' );

# call_m( 'use_perltime', FALSE, 'Does not use perltime' );

my $base = greg_time_gm( 0, 0, 0, 1, 3, 2009 );	# April 1, 2009 GMT;
use constant ONE_DAY => 86400;			# One day, in seconds.
use constant HALF_DAY => 43200;			# 12 hours, in seconds.

call_m( base => $base, TRUE, 'Set base time to 01-Apr-2009 GMT' );

call_m( parse => '+0', $base, 'Parse of +0 returns base time' );

call_m( parse => '+1', $base + ONE_DAY,
    'Parse of +1 returns one day later than base time' );

call_m( parse => '+0', $base + ONE_DAY,
    'Parse of +0 now returns one day later than base time' );

call_m( 'reset', TRUE, 'Reset to base time' );

call_m( parse => '+0', $base, 'Parse of +0 returns base time again' );

call_m( parse => '+0 12', $base + HALF_DAY,
    q{Parse of '+0 12' returns base time plus 12 hours} );

call_m( 'reset', TRUE, 'Reset to base time again' );

call_m( parse => '-0', $base, 'Parse of -0 returns base time' );

call_m( parse => '-0 12', $base - HALF_DAY,
    'Parse of \'-0 12\' returns 12 hours before base time' );

call_m( perltime => 1, TRUE, 'Set perltime true' );

call_m( parse => '2009-1-1',
    greg_time_local( 0, 0, 0, 1, 0, 2009 ),
    q<Parse '2009-1-1'> );

call_m( parse => '2009-7-1',
    greg_time_local( 0, 0, 0, 1, 6, 2009 ),
    q<Parse '2009-7-1'> );

call_m( perltime => 0, TRUE, 'Set perltime false' );

call_m( parse => '2009-1-1',
    greg_time_local( 0, 0, 0, 1, 0, 2009 ),
    q<Parse '2009-1-1', no help from perltime> );

call_m( parse => '2009-7-1',
    greg_time_local( 0, 0, 0, 1, 6, 2009 ),
    q<Parse '2009-7-1', no help from perltime> );

call_m( parse => '2009-1-1Z',
    greg_time_gm( 0, 0, 0, 1, 0, 2009 ),
    q<Parse '2009-1-1Z'> );

call_m( parse => '2009-7-1Z',
    greg_time_gm( 0, 0, 0, 1, 6, 2009 ),
    q<Parse '2009-7-1Z'> );

call_m( parse => '2009-7-2 16:23:37',
    greg_time_local( 37, 23, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16:23:37'} );

call_m( parse => '2009-7-2 16:23:37Z',
    greg_time_gm( 37, 23, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16:23:37Z'} );

call_m( parse => '2009-7-2 16:23',
    greg_time_local( 0, 23, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16:23'} );

call_m( parse => '2009-7-2 16:23 Z',
    greg_time_gm( 0, 23, 16, 2, 6, 2009 ),
    q{Parse ISO-8601 '2009-7-2 16:23 Z'} );

call_m( parse => '2009-7-2 16',
    greg_time_local( 0, 0, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16'} );

call_m( parse => '2009-7-2 16Z',
    greg_time_gm( 0, 0, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16Z'} );

call_m( parse => '2009-7-2',
    greg_time_local( 0, 0, 0, 2, 6, 2009 ),
    q{Parse '2009-7-2'} );

call_m( parse => '2009-7-2 Z',
    greg_time_gm( 0, 0, 0, 2, 6, 2009 ),
    q{Parse '2009-7-2 Z'} );

call_m( parse => '2009-7',
    greg_time_local( 0, 0, 0, 1, 6, 2009 ),
    q{Parse '2009-7'} );

call_m( parse => '2009-7Z',
    greg_time_gm( 0, 0, 0, 1, 6, 2009 ),
    q{Parse '2009-7Z'} );

call_m( parse => '2009',
    greg_time_local( 0, 0, 0, 1, 0, 2009 ),
    q{Parse '2009'} );

call_m( parse => '2009Z',
    greg_time_gm( 0, 0, 0, 1, 0, 2009 ),
    q{Parse '2009Z'} );

done_testing;

{

    my %handler;

    BEGIN {
	%handler = (
	    parse	=> sub {
		my ( $self, $str ) = @_;
		my $zulu = $str =~ s/ \s* z \z //smxi;
		my @time = split qr{ [^0-9]+ }smx, $str;
		$time[1] ||= 1;
		$time[2] ||= 1;
		@time < 6
		    and push @time, ( 0 ) x ( 6 - @time );
		splice @time, 6;
		--$time[1];
		my $code = $zulu ? \&greg_time_gm : \&greg_time_local;
		return $code->( reverse @time );
	    },
	);
    }

    sub parser {
	my ( $self, undef, $name, $val ) = @_;
	my $code = $handler{$name}
	    or return;
	return $code->( $self, $val );
    }
}

1;

# ex: set textwidth=72 :
