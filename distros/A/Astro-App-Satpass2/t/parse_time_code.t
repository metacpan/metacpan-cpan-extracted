package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;

use Astro::Coord::ECI::Utils 0.077 qw{ time_gm time_local };

use My::Module::Test::App;

require_ok 'Astro::App::Satpass2::ParseTime';

class 'Astro::App::Satpass2::ParseTime';

method new => class => 'Astro::App::Satpass2::ParseTime::Code',
    code	=> \&parser,
    INSTANTIATE, 'Instantiate';

method isa => 'Astro::App::Satpass2::ParseTime::Code', TRUE,
    'Object isa Astro::App::Satpass2::ParseTime::Code';

method isa => 'Astro::App::Satpass2::ParseTime', TRUE,
    'Object isa Astro::App::Satpass2::ParseTime';

method 'delegate',
    'Astro::App::Satpass2::ParseTime::Code',
    'Delegate is Astro::App::Satpass2::ParseTime::Code';

# method 'use_perltime', FALSE, 'Does not use perltime';

my $base = time_gm( 0, 0, 0, 1, 3, 2009 );	# April 1, 2009 GMT;
use constant ONE_DAY => 86400;			# One day, in seconds.
use constant HALF_DAY => 43200;			# 12 hours, in seconds.

method base => $base, TRUE, 'Set base time to 01-Apr-2009 GMT';

method parse => '+0', $base, 'Parse of +0 returns base time';

method parse => '+1', $base + ONE_DAY,
    'Parse of +1 returns one day later than base time';

method parse => '+0', $base + ONE_DAY,
    'Parse of +0 now returns one day later than base time';

method 'reset', TRUE, 'Reset to base time';

method parse => '+0', $base, 'Parse of +0 returns base time again';

method parse => '+0 12', $base + HALF_DAY,
    q{Parse of '+0 12' returns base time plus 12 hours};

method 'reset', TRUE, 'Reset to base time again';

method parse => '-0', $base, 'Parse of -0 returns base time';

method parse => '-0 12', $base - HALF_DAY,
    'Parse of \'-0 12\' returns 12 hours before base time';

method perltime => 1, TRUE, 'Set perltime true';

method parse => '2009-1-1',
    time_local( 0, 0, 0, 1, 0, 2009 ),
    q<Parse '2009-1-1'>;

method parse => '2009-7-1',
    time_local( 0, 0, 0, 1, 6, 2009 ),
    q<Parse '2009-7-1'>;

method perltime => 0, TRUE, 'Set perltime false';

method parse => '2009-1-1',
    time_local( 0, 0, 0, 1, 0, 2009 ),
    q<Parse '2009-1-1', no help from perltime>;

method parse => '2009-7-1',
    time_local( 0, 0, 0, 1, 6, 2009 ),
    q<Parse '2009-7-1', no help from perltime>;

method parse => '2009-1-1Z',
    time_gm( 0, 0, 0, 1, 0, 2009 ),
    q<Parse '2009-1-1Z'>;

method parse => '2009-7-1Z',
    time_gm( 0, 0, 0, 1, 6, 2009 ),
    q<Parse '2009-7-1Z'>;

method parse => '2009-7-2 16:23:37',
    time_local( 37, 23, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16:23:37'};

method parse => '2009-7-2 16:23:37Z',
    time_gm( 37, 23, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16:23:37Z'};

method parse => '2009-7-2 16:23',
    time_local( 0, 23, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16:23'};

method parse => '2009-7-2 16:23 Z',
    time_gm( 0, 23, 16, 2, 6, 2009 ),
    q{Parse ISO-8601 '2009-7-2 16:23 Z'};

method parse => '2009-7-2 16',
    time_local( 0, 0, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16'};

method parse => '2009-7-2 16Z',
    time_gm( 0, 0, 16, 2, 6, 2009 ),
    q{Parse '2009-7-2 16Z'};

method parse => '2009-7-2',
    time_local( 0, 0, 0, 2, 6, 2009 ),
    q{Parse '2009-7-2'};

method parse => '2009-7-2 Z',
    time_gm( 0, 0, 0, 2, 6, 2009 ),
    q{Parse '2009-7-2 Z'};

method parse => '2009-7',
    time_local( 0, 0, 0, 1, 6, 2009 ),
    q{Parse '2009-7'};

method parse => '2009-7Z',
    time_gm( 0, 0, 0, 1, 6, 2009 ),
    q{Parse '2009-7Z'};

method parse => '2009',
    time_local( 0, 0, 0, 1, 0, 2009 ),
    q{Parse '2009'};

method parse => '2009Z',
    time_gm( 0, 0, 0, 1, 0, 2009 ),
    q{Parse '2009Z'};

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
		my $code = $zulu ? \&time_gm : \&time_local;
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
