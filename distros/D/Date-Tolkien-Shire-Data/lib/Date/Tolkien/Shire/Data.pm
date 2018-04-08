package Date::Tolkien::Shire::Data;

use 5.006002;

use strict;
use warnings;

use charnames qw{ :full };

use Carp ();
use POSIX ();
use Text::Abbrev();

# We can't use 'use Exporter qw{ import }' because we need to run under
# Perl 5.6.2, and since as I write this the Perl porters are working on
# a security flaw in 'use base', I'm doing a Paleolithic subclass.
use Exporter ();
our @ISA = qw{ Exporter };

our $VERSION = '0.005';

our @EXPORT_OK = qw{
    __am_or_pm
    __date_to_day_of_year
    __day_of_year_to_date
    __day_of_week
    __format
    __is_leap_year
    __holiday_abbr __holiday_name __holiday_narrow
    __holiday_name_to_number
    __month_name __month_name_to_number __month_abbr
    __on_date __on_date_accented
    __quarter __quarter_name __quarter_abbr
    __rata_die_to_year_day
    __trad_weekday_abbr __trad_weekday_name __trad_weekday_narrow
    __valid_date_class
    __weekday_abbr __weekday_name __weekday_narrow
    __week_of_year
    __year_day_to_rata_die
    DAY_OF_YEAR_MIDYEARS_DAY
    DAY_OF_YEAR_OVERLITHE
    GREGORIAN_RATA_DIE_TO_SHIRE
    HOLIDAY_2_YULE
    HOLIDAY_1_LITHE
    HOLIDAY_MIDYEARS_DAY
    HOLIDAY_OVERLITHE
    HOLIDAY_2_LITHE
    HOLIDAY_1_YULE
};
our %EXPORT_TAGS = (
    all		=> \@EXPORT_OK,
    subs	=> [ grep { m/ \A __ /smx } @EXPORT_OK ],
    consts	=> [ grep { m/ \A [[:upper:]] /smx } @EXPORT_OK ],
);

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};

use constant DAY_OF_YEAR_MIDYEARS_DAY	=> 183;
use constant DAY_OF_YEAR_OVERLITHE	=> 184;

use constant HOLIDAY_2_YULE		=> 1;
use constant HOLIDAY_1_LITHE		=> 2;
use constant HOLIDAY_MIDYEARS_DAY	=> 3;
use constant HOLIDAY_OVERLITHE		=> 4;
use constant HOLIDAY_2_LITHE		=> 5;
use constant HOLIDAY_1_YULE		=> 6;

# See the documentation below for where the value came from.

use constant GREGORIAN_RATA_DIE_TO_SHIRE	=> 1995694;

{
    my @name = qw{ AM PM };

    my $validate = _make_validator( qw{ UInt } );

    sub __am_or_pm {
	my ( $hour ) = $validate->( @_ );
	return $name[ $hour < 12 ? 0 : 1 ];
    }
}

{

    my @holiday = ( undef, 1, 7, 0, 0, 1, 7 );
    my @month_zero = ( undef, 0, 2, 4, 6, 1, 3, 0, 2, 4, 6, 1, 3 );

    my $validate = _make_validator( qw{ UInt UInt } );

    sub __day_of_week {
	my ( $month, $day ) = $validate->( @_ );
	$month
	    or return $holiday[$day];
	return ( $month_zero[$month] + $day ) % 7 + 1;
    }
}

{
    my @holiday_day = ( undef, 1, 182, 183, DAY_OF_YEAR_OVERLITHE, 185, 366 );
    my @month_zero = ( undef, 1, 31, 61, 91, 121, 151, 185, 215, 245,
	275, 305, 335 );

    my $validate_d2doy = _make_validator( qw{ UInt UInt UInt } );

    sub __date_to_day_of_year {
	my ( $year, $month, $day ) = $validate_d2doy->( @_ );

	my $yd = $month ? $month_zero[$month] + $day :
	$holiday_day[$day];

	unless ( __is_leap_year( $year ) ) {
	    not $month
		and HOLIDAY_OVERLITHE == $day
		and Carp::croak( 'Overlithe only occurs in a leap year' );
	    $yd >= DAY_OF_YEAR_OVERLITHE
		and --$yd;
	}
	return $yd;
    }

    my $validate_doy2d = _make_validator( qw{ UInt UInt } );

    sub __day_of_year_to_date {
	my ( $year, $yd ) = $validate_doy2d->( @_ );

	unless ( __is_leap_year( $year ) ) {
	    $yd >= DAY_OF_YEAR_OVERLITHE
		and $yd++;
	}
	$yd > 0
	    and $yd <= 366
	    or Carp::croak( "Invalid year day $yd" );

	for ( my $day = 1; $day < @holiday_day; $day++ ) {
	    $yd == $holiday_day[$day]
		and return ( 0, $day );
	}

	$yd -= 2;
	$yd > 180
	    and $yd -= 4;
	my $day = $yd % 30;
	my $month = ( $yd - $day ) / 30;
	return ( $month + 1, $day + 1 );
    }
}

{

    my $validate = _make_validator( qw{ Hash|Object Scalar } );

    sub __format {
	my ( $date, $tplt ) = $validate->( @_ );

	$date = _make_date_object( $date );

	my $ctx = {
	    prefix_new_line_unless_empty	=> 0,
	};

	$tplt =~ s/ % (?: [{]  ( \w+ ) [}]	# method ($1)
	    | [{]{2} ( .*? ) [}]{2}		# condition ($2)
	    | ( [-_0^#]* ) ( [0-9]* ) ( [EO]? . ) # conv spec ($3,$4,$5)
	) /
	    $1 ? ( $date->can( $1 ) ? $date->$1() : "%{$1}" ) :
	    $2 ? _fmt_cond( $date, $2 ) :
	    _fmt_conv( $date, $5, $3, $4, $ctx )
	/smxeg;

	return $tplt;
    }
}

sub _fmt_cond {
    my ( $date, $tplt ) = @_;
    my @cond = split qr< [|]{2} >smx, $tplt;
    foreach my $inx ( 1, 2 ) {
	defined $cond[$inx]
	    and '' ne $cond[$inx]
	    or $cond[$inx] = undef;
    }

    my $inx = 0;
    defined $cond[1]
	and not $date->__fmt_shire_month()
	and $inx = 1;
    defined $cond[2]
	and not __day_of_week( $date->__fmt_shire_month(), $date->__fmt_shire_day() )
	and $inx = 2;

    return __format( $date, $cond[$inx] );
}

{
    # NOTE - I _was_ using assignment to $_[2] followed by a goto to
    # dispatch _fmt_number__2() and _fmt_number_02(). But this produced
    # test failures under 5.8.5, which I was able to reproduce, though
    # not under -d:ptkdb, which suggests it was an optimizer problem.
    # Only _fmt_number__2() resulted in the failures, but I recoded
    # both, plus the couple dispatches directly to _fmt_number() since
    # the previous dispatch scheme for all three involved fiddling with
    # the contents of @_. There is still a goto inside _fmt_number__2(),
    # but since I no longer modify @_, I have let that stand.
    my %spec = (
	A	=> sub { $_[0]->__fmt_shire_traditional() ?
		    __trad_weekday_name( $_[0]->__fmt_shire_day_of_week() ) :
		    __weekday_name( $_[0]->__fmt_shire_day_of_week() );
		},
	a	=> sub { $_[0]->__fmt_shire_traditional() ?
		    __trad_weekday_abbr( $_[0]->__fmt_shire_day_of_week() ) :
		    __weekday_abbr( $_[0]->__fmt_shire_day_of_week() );
		},
	B	=> sub { __month_name( $_[0]->__fmt_shire_month() ) },
	b	=> sub { __month_abbr( $_[0]->__fmt_shire_month() ) },
	C	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			int( $_[0]->__fmt_shire_year() / 100 ) );
		},
	c	=> sub { __format( $_[0], '%{{%a %x||||%x}} %X' ) },
	D	=> sub { __format( $_[0], '%{{%m/%d||%Ee}}/%y' ) },
	d	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			$_[0]->__fmt_shire_day() );
		},
	Ea	=> sub { $_[0]->__fmt_shire_traditional() ?
		    __trad_weekday_narrow( $_[0]->__fmt_shire_day_of_week() ) :
		    __weekday_narrow( $_[0]->__fmt_shire_day_of_week() );
		},
	Ed	=> \&_fmt_on_date,
	EE	=> sub { __holiday_name( $_[0]->__fmt_shire_month() ? 0 :
		$_[0]->__fmt_shire_day() ) },
	Ee	=> sub { __holiday_abbr( $_[0]->__fmt_shire_month() ? 0 :
		$_[0]->__fmt_shire_day() ) },
	En	=> sub { $_[1]{prefix_new_line_unless_empty}++; '' },
	Eo	=> sub { __holiday_narrow( $_[0]->__fmt_shire_month() ? 0 :
		$_[0]->__fmt_shire_day() ) },
	Ex	=> sub { __format( $_[0],
		    '%{{%A %-e %B %Y||%A %EE %Y||%EE %Y}}' ) },
	e	=> sub {
		    return _fmt_number__2( @_[ 0, 1 ],
			$_[0]->__fmt_shire_day() );
		},
	F	=> sub { __format( $_[0], '%Y-%{{%m-%d||%Ee}}' ) },
#	G	Same as Y by definition of Shire calendar
	H	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			$_[0]->__fmt_shire_hour() );
		},
#	h	Same as b by definition of strftime()
	I	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			( $_[0]->__fmt_shire_hour() || 0 ) % 12 || 12,
		    );
		},
	j	=> sub {
		    defined $_[1]{wid}
			or $_[1]{wid} = 3;
		    return _fmt_number( @_[ 0, 1 ],
			__date_to_day_of_year(
			    $_[0]->__fmt_shire_year(),
			    $_[0]->__fmt_shire_month(),
			    $_[0]->__fmt_shire_day(),
			),
		    );
		},
	k	=> sub {
		    return _fmt_number__2( @_[ 0, 1 ],
			$_[0]->__fmt_shire_hour() );
		},
	l	=> sub {
		    return _fmt_number__2( @_[ 0, 1 ],
			( $_[0]->__fmt_shire_hour() || 0 ) % 12 || 12 );
		},
	M	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			$_[0]->__fmt_shire_minute() );
		},
	m	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			$_[0]->__fmt_shire_month() );
		},
	N	=> sub {
		    defined $_[1]{wid}
			or $_[1]{wid} = 9;
		    return _fmt_number( @_[ 0, 1 ],
			$_[0]->__fmt_shire_nanosecond(),
		    );
		},
	n	=> sub { "\n" },
	P	=> sub { lc __am_or_pm( $_[0]->__fmt_shire_hour() ) },
	p	=> sub { uc __am_or_pm( $_[0]->__fmt_shire_hour() ) },
	R	=> sub { __format( $_[0], '%H:%M' ) },
	r	=> sub { __format( $_[0], '%I:%M:%S %p' ) },
	S	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			$_[0]->__fmt_shire_second() );
		},
	s	=> sub { $_[0]->__fmt_shire_epoch() },
	T	=> sub { __format( $_[0], '%H:%M:%S' ) },
	t	=> sub { "\t" },
	U	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			__week_of_year(
			    $_[0]->__fmt_shire_month(),
			    $_[0]->__fmt_shire_day(),
			),
		    );
		},
	u	=> sub { $_[0]->__fmt_shire_day_of_week() },
#	V	Same as U by definition of Shire calendar
	v	=> sub { __format( $_[0], '%{{%e-%b-%Y||%Ee-%Y}}' ) },
#	W	Same as U by definition of Shire calendar
#	X	Same as r, I think
	x	=> sub { __format( $_[0], '%{{%e %b %Y||%Ee %Y}}' ) }, 
	Y	=> sub { $_[0]->__fmt_shire_year() },
	y	=> sub {
		    return _fmt_number_02( @_[ 0, 1 ],
			$_[0]->__fmt_shire_year() % 100 );
		},
	Z	=> sub { $_[0]->__fmt_shire_zone_name() },
	z	=> sub { _fmt_offset( $_[0]->__fmt_shire_zone_offset() ) },
	'%'	=> sub { '%' },
    );
    $spec{G} = $spec{Y};	# By definition of Shire calendar.
    $spec{h} = $spec{b};	# By definition of strftime().
    $spec{V} = $spec{U};	# By definition of Shire calendar.
    $spec{W} = $spec{U};	# By definition of Shire calendar.
    $spec{w} = $spec{u};	# Because the strftime() definition of
				# %w makes no sense to me in terms of
				# the Shire calendar.
    $spec{X} = $spec{r};	# I think this is right ...
    $spec{'{'} = $spec{'}'} = $spec{'|'} = $spec{'%'};

    my %modifier_map = (
	0	=> sub { $_[0]{pad} = '0' },
	'-'	=> sub { $_[0]{pad} = '' },
	_	=> sub { $_[0]{pad} = ' ' },
	'^'	=> sub { $_[0]{uc} = 1 },
	'#'	=> sub { $_[0]{change_case} = 1 },
    );

    my %case_change = map { $_ => sub { uc $_[0] } }
	qw{ A a B b EE Ee h };
    $case_change{p} = $case_change{Z} = sub { lc $_[0] };

    # Note that if I should choose to implement field widths, the width,
    # if specified, causes padding with spaces if '-' (no padding) was
    # specified.

    sub _fmt_conv {
	my ( $date, $conv, $mod, $wid, $ctx ) = @_;
	defined $mod
	    or $mod = '';
	$wid
	    and $ctx->{wid} = $wid;
	my $code;
	foreach my $char ( split qr{}, $mod ) {
	    $code = $modifier_map{$char}
		and $code->( $ctx );
	}
	if ( $wid ) {
	    $ctx->{wid} = $wid;
	    defined $ctx->{pad}
		and '' eq $ctx->{pad}
		and $ctx->{pad} = ' ';
	}
	my $rslt;
	if ( $code = $spec{$conv} ) {
	    $rslt = $code->( $date, $ctx );
	} elsif ( 1 < length $conv and $code = $spec{ substr $conv, 1 } ) {
	    $rslt = $code->( $date, $ctx );
	} else {
	    $rslt = "%$mod$wid$conv";
	}
	defined $rslt
	    or $rslt = '';
	if ( delete $ctx->{change_case} and $code = $case_change{$conv} ) {
	    delete $ctx->{uc};
	    $rslt = $code->( $rslt );
	}
	delete $ctx->{uc}
	    and $rslt = uc $rslt;
	my $need;
	$ctx->{wid}
	    and '' ne $ctx->{pad}
	    and ( $need = $ctx->{wid} - length $rslt ) > 0
	    and $rslt = ( $ctx->{pad} x $need ) . $rslt;
	delete @{ $ctx }{ qw{ pad wid } };
	return $rslt;
    }
}

sub _fmt_number {
    my ( undef, $ctx, $val ) = @_;	# Invocant unused
    defined $ctx->{pad}
	or $ctx->{pad} = '0';
    defined $ctx->{wid}
	or $ctx->{wid} = 2;
    return defined $val ? "$val" : '0';
}

*_fmt_number_02 = \&_fmt_number;

sub _fmt_number__2 {
    defined $_[1]{pad}
	or $_[1]{pad} = ' ';
    goto &_fmt_number;
}

sub _fmt_offset {
    my ( $offset ) = @_;
    defined $offset
	and $offset =~ m/ \A [+-]? [0-9]+ \z /smx
	or return '';
    my $sign = $offset < 0 ? '-' : '+';
    $offset = abs $offset;
    my $sec = $offset % 60;
    $offset = POSIX::floor( ( $offset - $sec ) / 60 );
    my $min = $offset % 60;
    my $hr = POSIX::floor( ( $offset - $min ) / 60 );
    return $sec ?
	sprintf( '%s%02d%02d%02d', $sign, $hr, $min, $sec ) :
	sprintf( '%s%02d%02d', $sign, $hr, $min );
}

sub _fmt_on_date {
    my ( $date, $ctx ) = @_;
    my $pfx = "\n" x $ctx->{prefix_new_line_unless_empty};
    $ctx->{prefix_new_line_unless_empty} = 0;
    my $month = $date->__fmt_shire_month();
    my $day = $date->__fmt_shire_day();
    defined( my $on_date = $date->__fmt_shire_accented() ?
	__on_date_accented( $month, $day ) :
	__on_date( $month, $day ) )
	or return undef;	## no critic (ProhibitExplicitReturnUndef)
    return "$pfx$on_date";
}

{
    my @name = ( '',
	'2Yu', '1Li', 'Myd', 'Oli', '2Li', '1Yu',
    );

    sub __holiday_abbr {
	return _lookup( $_[0], \@name );
    }
}

{
    my @name = ( '',
	'2 Yule', '1 Lithe', q<Midyear's day>, 'Overlithe', '2 Lithe',
	'1 Yule',
    );

    sub __holiday_name {
	return _lookup( $_[0], \@name );
    }

}

{
    my @name = ( '',
	'2Y', '1L', 'My', 'Ol', '2L', '1Y',
    );

    sub __holiday_narrow {
	return _lookup( $_[0], \@name );
    }
}

{
    # This code needs to come after both __holiday_name() and
    # __holiday_abbr(), because it calls them both and needs the name
    # arrays to be set up.
    my $lookup = _make_lookup_hash(
	__holiday_name(),
	__holiday_abbr(),
    );

    my $validate = _make_validator( qw{ Scalar } );

    sub __holiday_name_to_number {
	my ( $holiday ) = _normalize_for_lookup(
	    $validate->( @_ ) );

	$holiday =~ m/ \A [0-9]+ \z /smx
	    and return $holiday;
	return $lookup->{$holiday} || 0;
    }
}

{
    my $validate = _make_validator( qw{ UInt } );

    sub __is_leap_year {
	my ( $year ) = $validate->( @_ );
	return $year % 4 ? 0 : $year % 100 ? 1 : $year % 400 ? 0 : 1;
    }
}

{
    my @name = ( '',
	'Afteryule', 'Solmath', 'Rethe', 'Astron', 'Thrimidge',
	'Forelithe', 'Afterlithe', 'Wedmath', 'Halimath', 'Winterfilth',
	'Blotmath', 'Foreyule',
    );

    my $validate = _make_validator( qw{ UInt|Undef } );

    sub __month_name {
	my ( $month ) = $validate->( @_ );
	defined $month
	    or return [ @name ];
	return $name[ $month ];
    }

}

{
    my @name = ( '', 'Ayu', 'Sol', 'Ret', 'Ast', 'Thr', 'Fli', 'Ali',
	'Wed', 'Hal', 'Win', 'Blo', 'Fyu' );

    my $validate = _make_validator( qw{ UInt|Undef } );

    sub __month_abbr {
	my ( $month ) = $validate->( @_ );
	defined $month
	    or return [ @name ];
	return $name[ $month || 0 ];
    }
}

{
    my $lookup = _make_lookup_hash(
	__month_name(),
	__month_abbr(),
    );

    my $validate = _make_validator( qw{ Scalar } );

    sub __month_name_to_number {
	my ( $month ) = _normalize_for_lookup(
	    $validate->( @_ ) );

	$month =~ m/ \A [0-9]+ \z /smx
	    and return $month;
	return $lookup->{$month} || 0;
    }
}

{
    my @on_date;

    $on_date[0][3]   = "Wedding of King Elessar and Arwen, 1419.\n";

    $on_date[1][8]   = "The Company of the Ring reaches Hollin, 1419.\n";
    $on_date[1][13]  = "The Company of the Ring reaches the West-gate of Moria at nightfall, 1419.\n";
    $on_date[1][14]  = "The Company of the Ring spends the night in Moria hall 21, 1419.\n";
    $on_date[1][15]  = "The Bridge of Khazad-dum, and the fall of Gandalf, 1419.\n";
    $on_date[1][17]  = "The Company of the Ring comes to Caras Galadhon at evening, 1419.\n";
    $on_date[1][23]  = "Gandalf pursues the Balrog to the peak of Zirakzigil, 1419.\n";
    $on_date[1][25]  = "Gandalf casts down the Balrog, and passes away.\n" .
		       "His body lies on the peak of Zirakzigil, 1419.\n";

    $on_date[2][14]  = "Frodo and Sam look in the Mirror of Galadriel, 1419.\n" .
		       "Gandalf returns to life, and lies in a trance, 1419.\n";
    $on_date[2][16]  = "Company of the Ring says farewell to Lorien --\n" .
		       "Gollum observes departure, 1419.\n";
    $on_date[2][17]  = "Gwaihir the eagle bears Gandalf to Lorien, 1419.\n";
    $on_date[2][25]  = "The Company of the Ring pass the Argonath and camp at Parth Galen, 1419.\n" .
		       "First battle of the Fords of Isen -- Theodred son of Theoden slain, 1419.\n";
    $on_date[2][26]  = "Breaking of the Fellowship, 1419.\n" .
		       "Death of Boromir; his horn is heard in Minas Tirith, 1419.\n" .
		       "Meriadoc and Peregrin captured by Orcs -- Aragorn pursues, 1419.\n" .
		       "Eomer hears of the descent of the Orc-band from Emyn Muil, 1419.\n" .
		       "Frodo and Samwise enter the eastern Emyn Muil, 1419.\n";
    $on_date[2][27]  = "Aragorn reaches the west-cliff at sunrise, 1419.\n" .
		       "Eomer sets out from Eastfold against Theoden's orders to pursue the Orcs, 1419.\n";
    $on_date[2][28]  = "Eomer overtakes the Orcs just outside of Fangorn Forest, 1419.\n";
    $on_date[2][29]  = "Meriodoc and Pippin escape and meet Treebeard, 1419.\n" .
		       "The Rohirrim attack at sunrise and destroy the Orcs, 1419.\n" .
		       "Frodo descends from the Emyn Muil and meets Gollum, 1419.\n" .
		       "Faramir sees the funeral boat of Boromir, 1419.\n";
    $on_date[2][30]  = "Entmoot begins, 1419.\n" .
		       "Eomer, returning to Edoras, meets Aragorn, 1419.\n";

    $on_date[3][1]   = "Aragorn meets Gandalf the White, and they set out for Edoras, 1419.\n" .
		       "Faramir leaves Minas Tirith on an errand to Ithilien, 1419.\n";
    $on_date[3][2]   = "The Rohirrim ride west against Saruman, 1419.\n" .
		       "Second battle at the Fords of Isen; Erkenbrand defeated, 1419.\n" .
		       "Entmoot ends.  Ents march on Isengard and reach it at night, 1419.\n";
    $on_date[3][3]   = "Theoden retreats to Helm's Deep; battle of the Hornburg begins, 1419.\n" .
		       "Ents complete the destruction of Isengard.\n";
    $on_date[3][4]   = "Theoden and Gandalf set out from Helm's Deep for Isengard, 1419.\n" .
		       "Frodo reaches the slag mound on the edge of the of the Morannon, 1419.\n";
    $on_date[3][5]   = "Theoden reaches Isengard at noon; parley with Saruman in Orthanc, 1419.\n" .
		       "Gandalf sets out with Peregrin for Minas Tirith, 1419.\n";
    $on_date[3][6]   = "Aragorn overtaken by the Dunedain in the early hours, 1419.\n";
    $on_date[3][7]   = "Frodo taken by Faramir to Henneth Annun, 1419.\n" .
		       "Aragorn comes to Dunharrow at nightfall, 1419.\n";
    $on_date[3][8]   = "Aragorn takes the \"Paths of the Dead\", and reaches Erech at midnight, 1419.\n" .
		       "Frodo leaves Henneth Annun, 1419.\n";
    $on_date[3][9]   = "Gandalf reaches Minas Tirith, 1419.\n" .
		       "Darkness begins to flow out of Mordor, 1419.\n";
    $on_date[3][10]  = "The Dawnless Day, 1419.\n" .
		       "The Rohirrim are mustered and ride from Harrowdale, 1419.\n" .
		       "Faramir rescued by Gandalf at the gates of Minas Tirith, 1419.\n" .
		       "An army from the Morannon takes Cair Andros and passes into Anorien, 1419.\n";
    $on_date[3][11]  = "Gollum visits Shelob, 1419.\n" .
		       "Denethor sends Faramir to Osgiliath, 1419.\n" .
		       "Eastern Rohan is invaded and Lorien assaulted, 1419.\n";
    $on_date[3][12]  = "Gollum leads Frodo into Shelob's lair, 1419.\n" .
		       "Ents defeat the invaders of Rohan, 1419.\n";
    $on_date[3][13]  = "Frodo captured by the Orcs of Cirith Ungol, 1419.\n" .
		       "The Pelennor is overrun and Faramir is wounded, 1419.\n" .
		       "Aragorn reaches Pelargir and captures the fleet of Umbar, 1419.\n";
    $on_date[3][14]  = "Samwise finds Frodo in the tower of Cirith Ungol, 1419.\n" .
		       "Minas Tirith besieged, 1419.\n";
    $on_date[3][15]  = "Witch King breaks the gates of Minas Tirith, 1419.\n" .
		       "Denethor, Steward of Gondor, burns himself on a pyre, 1419.\n" .
		       "The battle of the Pelennor occurs as Theoden and Aragorn arrive, 1419.\n" .
		       "Thranduil repels the forces of Dol Guldur in Mirkwood, 1419.\n" .
		       "Lorien assaulted for second time, 1419.\n";
    $on_date[3][17]  = "Battle of Dale, where King Brand and King Dain Ironfoot fall, 1419.\n" .
		       "Shagrat brings Frodo's cloak, mail-shirt, and sword to Barad-dur, 1419.\n";
    $on_date[3][18]  = "Host of the west leaves Minas Tirith, 1419.\n" .
		       "Frodo and Sam overtaken by Orcs on the road from Durthang to Udun, 1419.\n";
    $on_date[3][19]  = "Frodo and Sam escape the Orcs and start on the road toward Mount Doom, 1419.\n";
    $on_date[3][22]  = "Lorien assaulted for the third time, 1419.\n";
    $on_date[3][24]  = "Frodo and Sam reach the base of Mount Doom, 1419.\n";
    $on_date[3][25]  = "Battle of the Host of the West on the slag hill of the Morannon, 1419.\n" .
		       "Gollum siezes the Ring of Power and falls into the Cracks of Doom, 1419.\n" .
		       "Downfall of Barad-dur and the passing of Sauron!, 1419.\n" .
		       "Birth of Elanor the Fair, daughter of Samwise, 1421.\n" .
		       "Fourth age begins in the reckoning of Gondor, 1421.\n";
    $on_date[3][27]  = "Bard II and Thorin III Stonehelm drive the enemy from Dale, 1419.\n";
    $on_date[3][28]  = "Celeborn crosses the Anduin and begins destruction of Dol Guldur, 1419.\n";

    $on_date[4][6]   = "The mallorn tree flowers in the Party Field, 1420.\n";
    $on_date[4][8]   = "Ring bearers are honored on the Field of Cormallen, 1419.\n";
    $on_date[4][12]  = "Gandalf arrives in Hobbiton, 1418\n";

    $on_date[5][1]   = "Crowning of King Elessar, 1419.\n" .
		       "Samwise marries Rose, 1420.\n";

    $on_date[6][20]  = "Sauron attacks Osgiliath, 1418.\n" .
		       "Thranduil is attacked, and Gollum escapes, 1418.\n";

    $on_date[7][4]   = "Boromir sets out from Minas Tirith, 1418\n";
    $on_date[7][10]  = "Gandalf imprisoned in Orthanc, 1418\n";
    $on_date[7][19]  = "Funeral Escort of King Theoden leaves Minas Tirith, 1419.\n";

    $on_date[8][10]  = "Funeral of King Theoden, 1419.\n";

    $on_date[9][18]  = "Gandalf escapes from Orthanc in the early hours, 1418.\n";
    $on_date[9][19]  = "Gandalf comes to Edoras as a beggar, and is refused admittance, 1418\n";
    $on_date[9][20]  = "Gandalf gains entrance to Edoras.  Theoden commands him to go:\n" .
		       "\"Take any horse, only be gone ere tomorrow is old\", 1418.\n";
    $on_date[9][21]  = "The hobbits return to Rivendell, 1419.\n";
    $on_date[9][22]  = "Birthday of Bilbo and Frodo.\n" .
		       "The Black Riders reach Sarn Ford at evening;\n" .
		       "  they drive off the guard of Rangers, 1418.\n" .
		       "Saruman comes to the Shire, 1419.\n";
    $on_date[9][23]  = "Four Black Riders enter the shire before dawn.  The others pursue \n" .
		       "the Rangers eastward and then return to watch the Greenway, 1418.\n" .
		       "A Black Rider comes to Hobbiton at nightfall, 1418.\n" .
		       "Frodo leaves Bag End, 1418.\n" .
		       "Gandalf having tamed Shadowfax rides from Rohan, 1418.\n";
    $on_date[9][26]  = "Frodo comes to Bombadil, 1418\n";
    $on_date[9][28]  = "The Hobbits are captured by a barrow-wight, 1418.\n";
    $on_date[9][29]  = "Frodo reaches Bree at night, 1418.\n" .
		       "Frodo and Bilbo depart over the sea with the three Keepers, 1421.\n" .
		       "End of the Third Age, 1421.\n";
    $on_date[9][30]  = "Crickhollow and the inn at Bree are raided in the early hours, 1418.\n" .
		       "Frodo leaves Bree, 1418.\n";

    $on_date[10][3]  = "Gandalf attacked at night on Weathertop, 1418.\n";
    $on_date[10][5]  = "Gandalf and the Hobbits leave Rivendell, 1419.\n";
    $on_date[10][6]  = "The camp under Weathertop is attacked at night and Frodo is wounded, 1418.\n";
    $on_date[10][11] = "Glorfindel drives the Black Riders off the Bridge of Mitheithel, 1418.\n";
    $on_date[10][13] = "Frodo crosses the Bridge of Mitheithel, 1418.\n";
    $on_date[10][18] = "Glorfindel finds Frodo at dusk, 1418.\n" .
		       "Gandalf reaches Rivendell, 1418.\n";
    $on_date[10][20] = "Escape across the Ford of Bruinen, 1418.\n";
    $on_date[10][24] = "Frodo recovers and wakes, 1418.\n" .
		       "Boromir arrives at Rivendell at night, 1418.\n";
    $on_date[10][25] = "Council of Elrond, 1418.\n";
    $on_date[10][30] = "The four Hobbits arrive at the Brandywine Bridge in the dark, 1419.\n";

    $on_date[11][3]  = "Battle of Bywater and passing of Saruman, 1419.\n" .
		       "End of the War of the Ring, 1419.\n";

    $on_date[12][25] = "The Company of the Ring leaves Rivendell at dusk, 1418.\n";

    my $validate = _make_validator( qw{ UInt UInt|Undef } );

    sub __on_date {
	my ( $month, $day ) = $validate->( @_ );
	defined $day
	    or ( $month, $day ) = ( 0, $month );
	return $on_date[$month][$day];
    }

    my @on_date_accented;

    sub __on_date_accented {
	my ( $month, $day ) = $validate->( @_ );
	defined $day
	    or ( $month, $day ) = ( 0, $month );

	unless ( @on_date_accented ) {

	    # This would be much easier with 'use utf8;', but
	    # unfortunately this was broken under Perl 5.6.
	    my $E_acute	= "\N{LATIN CAPITAL LETTER E WITH ACUTE}";
	    my $e_acute	= "\N{LATIN SMALL LETTER E WITH ACUTE}";
	    my $o_acute	= "\N{LATIN SMALL LETTER O WITH ACUTE}";
	    my $u_acute	= "\N{LATIN SMALL LETTER U WITH ACUTE}";
	    my $u_circ	= "\N{LATIN SMALL LETTER U WITH CIRCUMFLEX}";

	    foreach my $month ( @on_date ) {
		push @on_date_accented, [];
		foreach my $day ( @{ $month } ) {
		    if ( $day ) {
			$day =~ s/ \b Anorien \b /An${o_acute}rien/smxgo;
			$day =~ s/ \b Annun \b /Ann${u_circ}n/smxgo;
			$day =~ s/ \b Barad-dur \b /Barad-d${u_circ}r/smxgo;
			$day =~ s/ \b Dunedain \b /D${u_acute}nedain/smxgo;
			$day =~ s/ \b Eomer \b /${E_acute}omer/smxgo;
			$day =~ s/ \b Eowyn \b /${E_acute}owyn/smxgo;
			$day =~ s/ \b Khazad-dum \b /Khazad-d${u_circ}m/smxgo;
			$day =~ s/ \b Lorien \b /L${o_acute}rien/smxgo;
			$day =~ s/ \b Nazgul \b /Nazg${u_circ}l/smxgo;
			$day =~ s/ \b Theoden \b /Th${e_acute}oden/smxgo;
			$day =~ s/ \b Theodred \b /Th${e_acute}odred/smxgo;
			$day =~ s/ \b Udun \b /Ud${u_circ}n/smxgo;
		    }
		    push @{ $on_date_accented[-1] }, $day;
		}
	    }
	}

	return $on_date_accented[$month][$day];
    }
}

{
    my @holiday_quarter = ( undef, 1, 2, 0, 0, 3, 4 );

    my $validate = _make_validator( qw{ UInt UInt|Undef } );

    sub __quarter {
	my ( $month, $day ) = $validate->( @_ );
	defined $day
	    or ( $month, $day ) = ( 0, $month );
	return $month ?
	    POSIX::floor( ( $month - 1 ) / 3 ) + 1 :
	    $holiday_quarter[$day];
    }
}

{
    my @name = ( '', '1st quarter', '2nd quarter', '3rd quarter',
	'4th quarter' );

    my $validate = _make_validator( qw{ UInt } );

    sub __quarter_name {
	my ( $quarter ) = $validate->( @_ );
	return $name[ $quarter ];
    }
}

{
    my @name = ( '', qw{ Q1 Q2 Q3 Q4 } );

    my $validate = _make_validator( qw{ UInt } );

    sub __quarter_abbr {
	my ( $quarter ) = $validate->( @_ );
	return $name[ $quarter ];
    }
}

{
    my $validate = _make_validator( qw{ Int } );

    sub __rata_die_to_year_day {
	my ( $rata_die ) = $validate->( @_ );

	--$rata_die;	# The algorithm is simpler with zero-based days.
	my $cycle = POSIX::floor( $rata_die / 146097 );
	my $day_of_cycle = $rata_die - $cycle * 146097;
	my $year = POSIX::floor( ( $day_of_cycle -
		POSIX::floor( $day_of_cycle / 1460 ) +
		POSIX::floor( $day_of_cycle / 36524 ) -
		POSIX::floor( $day_of_cycle / 146096 ) ) / 365 ) +
		400 * $cycle + 1;
	# We pay here for the zero-based day by having to add back 2
	# rather than 1.
	my $year_day = $rata_die - __year_day_to_rata_die( $year ) + 2;
	return ( $year, $year_day );
    }
}

{
    my @name = ( '', 'Sterrendei', 'Sunnendei', 'Monendei',
	'Trewesdei', 'Hevenesdei', 'Meresdei', 'Highdei' );

    sub __trad_weekday_name {
	return _lookup( $_[0], \@name );
    }
}

{
    my @name = ( '', 'Ste', 'Sun', 'Mon', 'Tre', 'Hev', 'Mer', 'Hig' );

    sub __trad_weekday_abbr {
	return _lookup( $_[0], \@name );
    }
}

{
    my @name = ( '', 'St', 'Su', 'Mo', 'Tr', 'He', 'Me', 'Hi' );

    sub __trad_weekday_narrow {
	return _lookup( $_[0], \@name );
    }
}

{
    my @holiday = ( undef, 1, 26, 0, 0, 27, 52 );
    my @month_offset = ( undef, ( 0 ) x 6, ( 2 ) x 6 );

    my $validate = _make_validator( qw{ UInt UInt } );

    sub __week_of_year {
	my ( $month, $day ) = $validate->( @_ );
	$month
	    or return $holiday[$day];
	return int( (
		( $month - 1 ) * 30 + $month_offset[$month] + $day
	    ) / 7 ) + 1;
    }
}

{
    my @name = ( '', 'Sterday', 'Sunday', 'Monday', 'Trewsday',
	'Hevensday', 'Mersday', 'Highday' );

    sub __weekday_name {
	return _lookup( $_[0], \@name );
    }
}

{
    my @name = ( '', 'Ste', 'Sun', 'Mon', 'Tre', 'Hev', 'Mer', 'Hig' );

    sub __weekday_abbr {
	return _lookup( $_[0], \@name );
    }
}

{
    my @name = ( '', 'St', 'Su', 'Mo', 'Tr', 'He', 'Me', 'Hi' );

    sub __weekday_narrow {
	return _lookup( $_[0], \@name );
    }
}

{
    my $validate = _make_validator( qw{ Int UInt|Undef } );

    sub __year_day_to_rata_die {
	my ( $year, $day ) = $validate->( @_ );
	--$year;
	$day ||= 1;
	return $year * 365 + POSIX::floor( $year / 4 ) -
	    POSIX::floor( $year / 100 ) + POSIX::floor( $year / 400 ) +
	    $day;
    }
}

use constant FORMAT_DATE_ERROR => 'Date must be object or hash';
use constant DATE_CLASS => join '::', __PACKAGE__, 'Date';

sub _make_date_object {
    my ( $date ) = @_;

    my $ref = ref $date
	or Carp::croak( FORMAT_DATE_ERROR );

    HASH_REF eq $ref
	or return __valid_date_class( $date );

    my %hash = %{ $date };
    $hash{day} ||= 1;
    $hash{month} ||= $hash{day} < 7 ? 0 : 1;
    $hash{$_} ||= 0 for qw{
	hour minute second nanosecond epoch
    };
    defined $hash{zone_name}
	or $hash{zone_name} = '';
    return bless \%hash, DATE_CLASS;
}

{
    my %checked;

    sub __valid_date_class {
	my ( $obj ) = @_;
	my $pkg = ref $obj || $obj;

	local $" = ', ';
	@{ $checked{$pkg} ||= do {
	    unless ( ref $obj ) {
		( my $fn = $pkg ) =~ s{ :: }{/}smxg;
		$fn .= '.pm';
		$INC{$fn}
		    or require $fn;
	    }
	    my @missing;
	    foreach my $method ( qw{
		__fmt_shire_year
		__fmt_shire_month
		__fmt_shire_day
		__fmt_shire_hour
		__fmt_shire_minute
		__fmt_shire_second
		__fmt_shire_day_of_week
		__fmt_shire_nanosecond
		__fmt_shire_epoch
		__fmt_shire_zone_offset
		__fmt_shire_zone_name
		__fmt_shire_accented
		__fmt_shire_traditional
	    } ) {
		$pkg->can( $method )
		    or push @missing, $method;
	    }
	    \@missing;
	} }
	    and Carp::croak(
	    "$pkg lacks methods: @{ $checked{$pkg} }" );
	return $obj;
    }
}

# The arguments are multiple array references. The hash is set up so
# that all unique abbreviations of elements 0 return 0, and so on. The
# respective elements at the same index do not conflict with each other,
# so that (to take a not-so-random example) if two arrays are passed in,
# and the respective element 3s are (after normalization) 'midyearsday'
# and 'myd', and no other entries start with 'm', then key 'm' will
# exist and return value 3.
sub _make_lookup_hash {
    my @sources = @_;
    my %conflict;
    my %merged;
    my $source_count;
    foreach ( @sources ) {
	my @source = _normalize_for_lookup( @{ $_ } );
	my %value;
	foreach my $inx ( 0 .. $#source ) {
	    $value{ $source[$inx] } = $inx;
	}
	my %hash = Text::Abbrev::abbrev( @source );
	delete $hash{''};
	foreach ( values %hash ) {
	    $_ = $value{$_};
	}
	# Would use keys %merged here, but not sure how performant that
	# is under older Perls.
	if ( $source_count++ ) {
	    foreach my $key ( keys %hash ) {
		if ( $conflict{$key} ) {
		    # ignore it
		} elsif ( $merged{$key} ) {
		    if ( $merged{$key} != $hash{$key} ) {
			delete $merged{$key};
			$conflict{$key} = 1;
		    }
		} else {
		    $merged{$key} = $hash{$key};
		}
	    }
	} else {
	    %merged = %hash;
	}
    }
    return wantarray ? %merged : \%merged;
}

# I want this module to be light weight, but I also want to limit the
# arguments so I can add or change them with confidence that I don't
# break anything. So this is poor man's validation.
{
    my %type_def;

    BEGIN {
	# Type definitions expect the value begin validated to be in $_.
	# They return false if the value passes the validation, and a
	# brief description of what was expected (which must be a true
	# value as far as Perl is concerned) if the value fails
	# validation. They must not throw exceptions, because an
	# individual validator may be part of an alternation.
	#
	# We need the BEGIN block because we are manufacturing
	# validators in-line, above, and %type_def needs to be populated
	# before that happens.
	%type_def = (
	    # An array reference
	    Array	=> sub {
		ARRAY_REF eq ref $_ ? 0 : 'an ARRAY reference'
	    },
	    # A hash reference
	    Hash	=> sub { HASH_REF eq ref $_ ? 0 : 'a HASH reference' },
	    # An integer, optionally signed
	    Int	=> sub {
		( defined $_ && m/ \A [-+]? [0-9]+ \z /smx ) ? 0 :
		'an integer';
	    },
	    # An object (i.e. a blessed reference). I am not using
	    # Scalar::Util::blessed() here because of the desire to run
	    # under versions of Perl before this was released to core.
	    Object	=> sub {
		local $@ = undef;
		( ref $_ && eval { $_->can( 'isa' ) } ) ? ## no critic (RequireCheckingReturnValueOfEval)
		0 : 'an object' },
	    # A defined scalar (i.e. not a reference)
	    Scalar	=> sub { ( defined $_ && ! ref $_ ) ? 0 :
		'a non-reference' },
	    # An unsigned integer
	    UInt	=> sub {
		( defined $_ && m/ \A [0-9]+ \z /smx ) ? 0 :
		'an unsigned integer';
	    },
	    # Undefined. Necessary because all the other types reject an
	    # undefined value.
	    Undef	=> sub { defined $_ ? 'undefined' : 0 },
	);
    }

    # Take as arguments the type specifications of all arguments of the
    # subroutine to be validated, and return a reference to code that
    # checks its arguments against those specs. Type specifications must
    # appear in the above table, or be an alternation of items in the
    # above table (i.e. joined by '|', e.g. 'Scalar|Undef').
    #
    # There is currently no way to do slurpy arguments.
    sub _make_validator {
	my ( @spec ) = @_;
	foreach my $inx ( 0 .. $#spec ) {
	    foreach my $type ( split qr{ [|] }smx, $spec[$inx] ) {
		$type_def{$type}
		    or Carp::confess(
		    "Programming error - Argument $inx type '$spec[$inx]' is unknown" );
	    }
	}
	return sub {
	    my @args = @_;
	    @args > @spec
		and Carp::croak( 'Too many arguments' );
	ARGUMENT_LOOP:
	    foreach my $inx ( 0 .. $#spec ) {
		my @fail;
		local $_ = $args[$inx];
		foreach my $type ( split qr{ [|] }smx, $spec[$inx] ) {
		    my $error = $type_def{$type}->()
			or next ARGUMENT_LOOP;
		    push @fail, $error;
		}
		local $" = ' or ';
		Carp::croak( "Argument $inx ('$_') must be @fail" );
	    }
	    return @args;
	};
    }
}

sub _normalize_for_lookup {
    my @data = @_;
    foreach ( @data ) {
	defined $_
	    and ( $_ = lc $_ ) =~ s/ [\s[:punct:]]+ //smxg;
    }
    return @data;
}

# Create methods for the hash wrapper

{
    my %calc = (
	day_of_week	=> sub {
	    return __day_of_week( $_[0]->__fmt_shire_month(), $_[0]->__fmt_shire_day() );
	},
##	quarter		=> sub {
##	    return __quarter( $_[0]->__fmt_shire_month(), $_[0]->__fmt_shire_day() );
##	},
    );

    foreach my $field ( qw{
	year month day
	hour minute second nanosecond epoch
	zone_offset zone_name
	accented traditional
    }, keys %calc ) {
	my $fqn = join '::', __PACKAGE__, 'Date', "__fmt_shire_$field";
	if ( my $code = $calc{$field} ) {
	    no strict qw{ refs };
	    *$fqn = sub {
		defined $_[0]->{$field}
		    or $_[0]->{$field} = $code->( $_[0] );
		return $_[0]->{$field};
	    };
	} else {
	    no strict qw{ refs };
	    *$fqn = sub { $_[0]->{$field} };
	}
    }
}

{
    my $validate;

    BEGIN {
	$validate = _make_validator( qw{ UInt|Undef Array } );
    }

    sub _lookup {
	my ( $inx, $tbl ) = $validate->( @_ );
	defined $inx
	    and return $tbl->[ $inx ];
	__PACKAGE__ eq caller
	    or Carp::croak( 'Index not defined' );
	return $tbl;
    }
}

1;

__END__

=head1 NAME

Date::Tolkien::Shire::Data - Data functionality for Shire calendars.

=head1 SYNOPSIS

 use Date::Tolkien::Shire::Data;
 
 say __on_date( 1, 2 ) // "Nothing happened\n";

=head1 DESCRIPTION

This Perl module carries common functionality for implementations of the
Shire calendar as described in Appendix D of J. R. R. Tolkien's novel
"Lord Of The Rings". What it really contains is anything that was common
to L<Date::Tolkien::Shire|Date::Tolkien::Shire> and
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
and I felt like factoring out. You probably do not want to use this
module directly, at least not without looking into the other two.

The Shire calendar has 12 months of 30 days each, plus 5 holidays (6 in
a leap year) that are not part of any month. Two of these holidays
(Midyear's day and the Overlithe) are also part of no week.

In all of the following, years are counted from the founding of the
Shire. Months are numbered C<1-12>, and days in months from C<1-30>.
Holidays are specified by giving a month of C<0> and the holiday number,
as follows:

=over

=item 1 - 2 Yule

=item 2 - 1 Lithe

=item 3 - Midyear's day

=item 4 - Overlithe (which occurs in leap years only)

=item 5 - 2 Lithe (so numbered even in non-leap years)

=item 6 - 1 Yule

=back

This module is subroutine-based. Nothing is exported by default, but
everything public can be exported by name. In addition the following
export tags exist:

=over

=item C<:all> - export everything;

=item C<:consts> - export all manifest constants;

=item C<:subs> - export all subroutines.

=back

=head1 SUBROUTINES

This class supports the following public subroutines. Anything
documented below is public unless its documentation explicitly states
otherwise. The names begin with double underscores because it is
anticipated that, although they are public as far as this package is
concerned, they will be package-private for the purposes of any code
that uses this package.

All of the following are exportable to your name space, but none are
exported by default. They can all be exported using export tag C<:subs>.

=head2 __am_or_pm

This subroutine takes as input an hour of the day in the range 0 to 23
and returns C<'AM'> if the hour is less than 12, or C<'PM'> otherwise.

=head2 __date_to_day_of_year

 say __date_to_day_of_year( 1420, 3, 25 );

This subroutine takes as input a year, month, and day and returns the
day number in the year. An exception will be thrown if you specify the
Overlithe ("month" 0, day 4) and it is not a leap year.

=head2 __day_of_week

 say '3 Astron is day ', __day_of_week( 4, 3 );

Given a month number and day number in the month, computes the day of
the week that day falls on, as a number from 1 to 7, 1 being C<Sterday>.
If the day is Midyear's day or the Overlithe (month C<0>, days C<3> or
C<4>) the result is C<0>.

=head2 __day_of_year_to_date

 my ( $month, $day ) = __day_of_year_to_date( 1419, 182 );

Given a year and a day number in the year (from 1), compute the month
and day of month. An exception will be thrown unless the day number is
between C<1> and C<365>, or C<366> in a leap year.

=head2 __format

 say __format( $date, $pattern );

This method formats a date, in a manner similar to C<strftime()>. The
C<$date> is either an object that supports the necessary methods, or a
reference to a hash having the necessary keys (same as the
methods). The C<$pattern> is a string similar to the conversion
specification passed to C<POSIX::strftime()>; see below for a fuller
description.

The C<$date> methods used are:

=over

=item __fmt_shire_year

This method returns the Shire year, as a number.

=item __fmt_shire_month

This method returns the Shire month as a number in the range C<0> to
C<12>, with C<0> indicating a holiday.

=item __fmt_shire_day

This method returns the day of the month in the range C<1> to C<30>, or
the holiday number in the range C<1> to C<6>.

=item __fmt_shire_hour

This method returns the hour in the range C<0> to C<23>.

=item __fmt_shire_minute

This method returns the minute in the range C<0> to C<59>.

=item __fmt_shire_second

This method returns the second in the range C<0> to C<61>.

=item __fmt_shire_day_of_week

This method returns the day of the week as a number in the range C<0> to
C<7>, with C<0> indicating that the day is not part of any week.

=item __fmt_shire_nanosecond

This method returns the nanosecond (of the second) as a number.

=item __fmt_shire_epoch

This method returns the seconds since the epoch, as a number.

=item __fmt_shire_zone_offset

This method returns the seconds the current time zone is offset from
C<UTC>, as a number, or C<undef> is the offset is undefined.

=item __fmt_shire_zone_name

This method returns the name of the current time zone, or C<''> if the
zone is undefined.

=item __fmt_shire_accented

This method returns a true value if L<__on_date()|/__on_date> format is
to be accented.

=item __fmt_shire_traditional

This method returns a true value if traditional weekday names are to be
used.

=back

If you pass a hash, the keys are the above method names without the
leading C<'__fmt_shire_'> (i.e. C<'year'>, C<'month'>, and so on). The year
must be specified; everything else defaults, generally to C<0>, although
C<day_of_week>, if unspecified, will be computed from the date.

The following conversion specifications (to use C<strftime()>
terminology) or patterns (to use L<DateTime|DateTime> terminology) are
supported. Note that these have been extended by the use of C<'%E*'>
patterns, which generally represent holidays. E-prefixed patterns not
defined below are (consistent with C<strftime()>) implemented as if the
C<'E'> were not present, but this use is discouraged because additional
E-prefixed (or O-prefixed, which C<strftime()> also allows) patterns may
prove to be necessary.

=over

=item %A

The full weekday name, or C<''> for holidays that are part of no week.

=item %a

The abbreviated weekday name, or C<''> for holidays that are part of no
week.

=item %B

The full month name, or C<''> for holidays.

=item %b

The abbreviated month name, or C<''> for holidays.

=item %C

The century number (year/100) as a 2-digit integer.

=item %c

For normal days this is the abbreviated weekday name (C<'%a'>), the day
number (C<'%e'>), the abbreviated month name (C<%b>), and the full year
(C<'%Y'>), followed by the time of day.

For holidays the abbreviated holiday name (C<'%Ee'>) replaces the day
and month, and the weekday name is omitted if the holiday is part of no
week. So (assuming times for all events):

 Sun 25 Ret 1419  3:00:00 PM # Ring destroyed
 Myd 1419 12:00:OO PM        # Wedding of Aragorn and Arwen

=item %D

The equivalent of C<'%m/%d/%y'>, or C<'%Ee/%y'> on holidays. This format
is discouraged, because it may not be clear whether it is month/day/year
(as the United States does it) or day/month/year (as Europe does it).

=item %d

The day of the month as a decimal number, zero-filled (range C<01> to
C<30>). On holidays it is the holiday number, zero-filled (range C<01>
to C<06>).

=item %Ea

The narrow (2-character) weekday name, or C<''> for holidays that are
part of no week.

=item %Ed

The L<__on_date()|/__on_date> text for the given date.

You can get a leading C<"\n"> if there was an actual event using
C<'%En%Ed'>. So to mimic L<Date::Tolkien::Shire|Date::Tolkien::Shire>
L<on_date()|Date::Tolkien::Shire/on_date>, use C<'%Ex%n%En%Ed'>.

=item %EE

The full holiday name, or C<''> for non-holidays.

=item %Ee

The abbreviated holiday name, or C<''> for non-holidays.

=item %En

Inserts nothing, but causes the next C<%Ed> (and B<only> the next one)
to have a C<"\n"> prefixed if there was an actual event on the date.

=item %Eo

The narrow (2-character) holiday name, or C<''> for non-holidays.

=item %Ex

Like C<'%c'>, but without the time of day, and with full names rather
than abbreviations.

=item %e

The day of the month as a decimal number, space-filled (range C<' 1'> to
C<'30'>). On holidays it is the holiday number, space-filled (range
C<' 1'> to C<' 6'>).

=item %F

For normal dates this is equivalent to C<'%Y-%m-%d'> (i.e. the ISO 8601
date format). For holidays it is equivalent to C<'%Y-%Er'>, which is
something ISO had nothing to do with.

=item %G

The ISO 8601 year number. Given how the Shire calendar is defined, the
ISO year number is the same as the calendar year (i.e. C<'%Y'>).

=item %H

The hour, zero-filled, in the range C<'00'> to C<'23'>.

=item %h

Equivalent to C<'%b'>.

=item %I

The hour, zero-filled, in the range C<'01'> to C<'12'>.

=item %j

The day of the year, zero-filled, in the range C<'001'> to C<'366'>.

=item %k

The hour, blank-filed, in the range C<' 0'> to C<'23'>.

=item %l

The hour, blank-filled, in the range C<' 1'> to C<'12'>.

=item %M

The minute, zero-filled, in the range C<'00'> to C<'59'>.

=item %m

The month number, zero filled, in the range C<'01'> to C<'12'>. On
holidays it is C<'00'>.

=item %N

The fractional seconds. A decimal digit may appear between the percent
sign and the C<'N'> to specify the precision: C<'3'> gives milliseconds,
C<'6'> microseconds, and C<'9'> nanoseconds. The default is C<'9'>.

=item %n

A newline character.

=item %P

The meridian indicator, C<'am'> or C<'pm'>.

=item %p

The meridian indicator, C<'AM'> or C<'PM'>.

=item %R

The time in hours and minutes, on a 24-hour clock. Equivalent to
C<'%H:%M'>.

=item %r

The time in hours, minutes and seconds on a 12-hour clock. Equivalent
to C<'%I:%M:%S %p'>.

=item %S

The second, zero-filled, in the range C<'00'> to C<'61'>, though only to
C<'59'> unless you are dealing with times when the leap second has been
invented.

=item %s

The number of seconds since the epoch.

=item %T

The time in hours, minutes and seconds on a 24-hour clock. Equivalent to
C<'%H:%M:%S'>.

=item %t

A tab character.

=item %U

The week number in the current year, zero-filled, in the range C<'01'>
to C<'52'>, or C<''> if the day is not part of a week.

=item %u

The day of the week, as a number in the range C<'1'> to C<'7'>, or C<''>
if the day is not part of a week.

=item %V

I have made this the same as C<'%U'>, because all Shire years start on
the same day of the week, and I do not think the hobbits would
understand or condone the idea of different starting days to a week.

=item %v

This is from the BSD version of strftime(), and is equivalent to
C<'%{{%e %b %Y||%Ee %Y}}'>.

=item %W

I have made this the same as C<'%U'>. For my reasoning, see above under
C<'%V'>.

=item %w

I have made this the same as C<'%u'>, my argument being similar to the
argument for making C<'%V'> the same as C<'%U'>.

=item %X

I have made this the same as C<'%r'>. We know the hobbits had clocks,
because in "The Hobbit" Thorin Oakenshield left Bilbo Baggins a note
under the clock on the mantelpiece. We know they spoke of time as
"o'clock" because in the chapter "Of Herbs and Stewed Rabbit" in "The
Lord Of The Rings", Sam Gamgee speaks of the time as being nine o'clock.
But this was in the morning, and we have no evidence that I know of
whether mid-afternoon would be three o'clock or fifteen o'clock. But my
feeling is for the former. If I get evidence to the contrary this
implementation will change.

=item %x

I have made this day, abbreviated month, and full year. Holidays are
abbreviated holiday name and year.

=item %Y

The year number.

=item %y

Year of century, zero filled, in the range C<'00'> to C<'99'>.

=item %Z

The time zone abbreviation.

=item %z

The time zone offset.

=item %%

A literal percent sign.

=item %{

A literal left curly bracket.

=item %}

A literal right curly bracket.

=item %|

A literal vertical bar.

=item %{method_name}

Any method actually implemented by the C<$date> object can be specified.
This method will be called without arguments and its results replace the
conversion specification. If the method does not exist, the pattern is
left as-is.

=item %{{format||format||format}}

The formatter chooses the first format for normal days (i.e. part of a
month), the second for holidays that are part of a week (i.e. 2 Yule, 1
Lithe, 2 Lithe and 1 Yule), or the third for holidays that are not part
of a week (i.e. Midyear's day and the Overlithe). If the second or third
formats are omitted, the preceding format is used. Trailing C<||>
operators can also be omitted. If you need to specify more than one
right curly bracket or vertical bar as part of a format, separate them
with percent signs (i.e. C<'|%|%|'>).

=back

Some of the Glibc extensions are implemented on some of the conversion
specifications, typically where the author felt a need for them. The
following flag characters may be specified immediately after the C<'%'>:

=over

=item - (dash)

This flag specifies no padding at all. That is to say, on the first of
the month, both C<'%-d'> and C<'%-e'> produce C<'1'>, not C<'01'> or
C<' 1'> respectively.

If an explicit field width is specified (see below), this specifies
space padding.

=item _ (underscore)

This flag specifies padding with spaces. That is to say, on the first of
the month, C<'%_d'> produce C<' 1'>, not C<'01'>. So does C<'%_e'>, in
case you were wondering.

=item 0 (zero)

This flag specifies padding with zeroes. That is to say, on the first of
the month, C<'%0e'> produce C<'01'>, not C<' 1'>. So does C<'%0d'>, in
case you were wondering.

=item ^

This flag specifies making the result upper-case.

=item #

If applied to C<'%p'> or C<'%Z'>, this flag converts the output to lower
case. It also overrides the C<'^'> flag if both are specified,
regardless of order.

If applied to C<'%A'>, C<'%a'>, C<'%B'>, C<'%b'>, C<'%EE'>, C<'%Ee'>, or
C<'%h'>, this flag converts the output to upper case.

If applied to anything else, this flag has no effect.

=back

Immediately after the flags (if any) you can specify a field width that
overrides the default. If you explicitly specify field width, flag
C<'-'> pads with spaces, even in numeric fields.

=head2 __holiday_abbr

 say __holiday_abbr( 3 );

Given a holiday number C<(1-6)>, this subroutine returns that holiday's
three-letter abbreviation. If the holiday number is C<0> (i.e. the day
is not a holiday), an empty string is returned. Otherwise, C<undef> is
returned.

=head2 __holiday_name

 say __holiday_name( 3 );

Given a holiday number C<(1-6)>, this subroutine returns that holiday's
name. If the holiday number is C<0> (i.e. the day is not a holiday), an
empty string is returned. Otherwise, C<undef> is returned.

=head2 __holiday_name_to_number

 say __holiday_name_to_number( 'overlithe' );

Given a holiday name, this subroutine normalizes it by converting it to
lower case and removing spaces and punctuation, and then returns the
number of the holiday. Unique abbreviations of names or short names
(a.k,a. abbreviations) are allowed. Arguments consisting entirely of
digits are returned unmodified. Anything unrecognized causes C<0> to be
returned.

=head2 __holiday_narrow

 say __holiday_narrow( 3 );

Given a holiday number C<(1-6)>, this subroutine returns that holiday's
two-letter abbreviation. If the holiday number is C<0> (i.e. the day
is not a holiday), an empty string is returned. Otherwise, C<undef> is
returned.

=head2 __is_leap_year

 say __is_leap_year( 1420 );  # 1

Given a year number, this subroutine returns C<1> if it is a leap year
and C<0> if it is not.

=head2 __month_name

 say __month_name( 3 );

Given a month number C<(1-12)>, this subroutine returns that month's
name. If the month number is C<0> (i.e. a holiday), the empty string is
returned. Otherwise C<undef> is returned.

=head2 __month_name_to_number

 say __month_name_to_number( 'forelithe' );

Given a month name, this subroutine normalizes it by converting it to
lower case and removing spaces and punctuation, and then returns the
number of the month. Unique abbreviations of names or short names
(a.k,a. abbreviations) are allowed. Arguments consisting entirely of
digits are returned unmodified. Anything unrecognized causes C<0> to be
returned.

=head2 __month_abbr

 say __month_abbr( 3 );

Given a month number C<(1-12)>, this subroutine returns that month's
three-letter abbreviation. If the month number is C<0> (i.e. a holiday),
the empty string is returned. Otherwise C<undef> is returned.


=head2 __on_date

 say __on_date( $month, $day ) // '';
 say __on_date( $holiday ) // '';

Given month and day numbers (or a holiday number), returns text
representing the events during and around the War of the Ring that
occurred on that date. If nothing happened or any argument is out of
range, C<undef> is returned.

The actual text returned is from Appendix B of "Lord Of The Rings", and
is copyright J. R. R. Tolkien, renewed by Christopher R. Tolkien et al.
Specifically, I use the Houghton Mifflin trade paperback. I find no date
of publication, but believe it to be the early 2000s because the cover
illustrations appear to be movie tie-ins.

=head2 __on_date_accented

 binmode STDOUT, ':encoding(utf-8)';
 say __on_date_accented( $month, $day ) // '';
 say __on_date( $holiday ) // '';

This wrapper for L<__on_date()|/__on_date()> accents those names and
words that are accented in the text of the Lord Of The Rings. How these
display depends on how your Perl is configured. Note that the example
above assumes Perl 5.10 (for C<say()> and C<//>). Even without those,
the two-argument C<binmode()> requires 5.8. Your mileage may vary.

Note that the first call incurs the overhead of accenting all events.

=head2 __quarter

 say __quarter( $month, $day );

Given month and day numbers, returns the relevant quarter number. If the
date specified is Midyear's day or the Overlithe ("month" C<0>, days
C<3-4>), the result is C<0>; otherwise it is a number in the range
C<1-4>.

There is nothing I know of about hobbits using calendar quarters in
anything Tolkien wrote. But if they did use them I suspect they would be
rationalized this way.

=head2 __quarter_name

Given the quarter number, return the name of the quarter. If the quarter
number is C<0> (i.e. Midyear's day or Overlithe), C<''> is returned.

=head2 __quarter_abbr

Given the quarter number, return the abbreviated name of the quarter. If
the quarter number is C<0> (i.e. Midyear's day or Overlithe), C<''> is
returned.

=head2 __rata_die_to_year_day

 my ( $year, $day ) = __rata_die_to_year_day( $rata_die );

Given a Rata Die day, returns the year and day of the year corresponding
to that Rata Die day.

The algorithm used was inspired by Howard Hinnant's "C<chrono>-Compatible
Low-Level Date Algorithms" at
L<http://howardhinnant.github.io/date_algorithms.html>, and in
particular his C<civil_from_days()> algorithm at
L<http://howardhinnant.github.io/date_algorithms.html#civil_from_days>.

This subroutine assumes no particular calendar, though it does assume
the Gregorian year-length rules, which have also been adopted for the
Shire calendar. If you feed it am honest-to-God Rata Die day (i.e. days
since December 31 of proleptic Gregorian year 0) you get back the
Gregorian year and the day of that year (C<1-366>). If you feed it a
so-called Shire Rata Die (i.e. days since 1 Yule of Shire year 0) you
get back the Shire year and the day of that year.

=head2 __trad_weekday_name

 say 'Day 1 is ', __trad_weekday_name( 1 );

This subroutine computes the traditional (i.e. old-style) name of a
weekday given its number (1-7). If the weekday number is C<0> (i.e.
Midyear's day or the Overlithe) the empty string is returned. Otherwise,
C<undef> is returned.

=head2 __trad_weekday_abbr

 say 'Day 1 is ', __trad_weekday_abbr( 1 );

This subroutine computes the three-letter abbreviation of a traditional
(i.e. old-style) weekday given its number (1-7). If the weekday number
is C<0> (i.e.  Midyear's day or the Overlithe) the empty string is
returned. Otherwise, C<undef> is returned.

=head2 __trad_weekday_narrow

 say 'Day 1 is ', __trad_weekday_narrow( 1 );

This subroutine computes the two-letter abbreviation of a traditional
(i.e. old-style) weekday given its number (1-7). If the weekday number
is C<0> (i.e.  Midyear's day or the Overlithe) the empty string is
returned. Otherwise, C<undef> is returned.

=head2 __valid_date_class

 eval {
     __valid_date_class( $class );
     print "$class OK\n";
     1;
 } or print $@;

This subroutine takes as its argument either an object or a class name.
If a class name, it is loaded if needed and possible. Then the class is
checked to see if it has all the methods required of a date object
passed to L<__format()|/__format>. If any missing methods are found an
exception is thrown naming the missing methods; otherwise it returns its
argument.

If you intend to use a class that autoloads requisite methods, that
class will need to properly override L<can()|UNIVERSAL/can>, or provide
forward references to autoloaded methods.

This subroutine is used internally to validate the date argument to
L<__format()|/__format>. It is exposed for troubleshooting purposes.
See also F<tools/valid-date-class>.

=head2 __weekday_name

 say 'Day 1 is ', __weekday_name( 1 );

This subroutine computes the name of a weekday given its number (1-7).
If the weekday number is C<0> (i.e. Midyear's day or the Overlithe) the
empty string is returned. Otherwise, C<undef> is returned.

=head2 __weekday_abbr

 say 'Day 1 is ', __weekday_abbr( 1 );

This subroutine computes the three-letter abbreviation of a weekday
given its number (1-7). If the weekday number is C<0> (i.e. Midyear's
day or the Overlithe) the empty string is returned. Otherwise, C<undef>
is returned.

=head2 __weekday_narrow

 say 'Day 1 is ', __weekday_narrow( 1 );

This subroutine computes the two-letter abbreviation of a weekday
given its number (1-7). If the weekday number is C<0> (i.e. Midyear's
day or the Overlithe) the empty string is returned. Otherwise, C<undef>
is returned.

=head2 __week_of_year

 say '25 Rethe is in week ', __week_of_year( 3, 25 );

This subroutine computes the week number of the given month and day.
Weeks start on Sterday, and the first week of the year is week 1. If the
date is part of no week (i.e. Midyear's day or the Overlithe), C<0> is
returned.

=head2 __year_day_to_rata_die

 my $rata_die = __year_day_to_rata_die(
     $year, $day_of_year );

Given the year and day of the year, this subroutine returns the Rata Die
day of the given year and day. The day of the year defaults to C<1>.

This subroutine assumes no particular calendar, though it does assume
the Gregorian year-length rules, which have also been adopted for the
Shire calendar. If you feed it a Gregorian year, you get an
honest-to-God Rata Die, as in days since December 31 of proleptic
Gregorian year 0. If you feed it a Shire year, you get a so-called Shire
Rata Die, as in the days since 1 Yule of Shire year 0.

=head1 MANIFEST CONSTANTS

The following manifest constants are exportable to your name space. None
is exported by default. They can all be exported using export tag
C<:consts>.

=head2 DAY_OF_YEAR_MIDYEARS_DAY

This manifest constant represents the day number of C<Midyear's day> in
the year, i.e. C<183>.

=head2 DAY_OF_YEAR_OVERLITHE

This manifest constant represents the day number of C<Overlithe> in the
year, i.e. C<184>. Be aware that day C<184> is C<Overlithe> only in a
leap year; otherwise day C<184> is C<2 Lithe>.

=head2 GREGORIAN_RATA_DIE_TO_SHIRE

This manifest constant represents the number of days to add to a real
Rata Die value (days since December 31 of proleptic Gregorian year 0) to
get a so-called Shire Rata Die (days since 1 Yule of Shire year 0.)

The value was determined by the following computation.

  my $dts = DateTime::Fiction::JRRTolkien::Shire->new(
      year    => 1,
      holiday => 1,
  );
  my $gdt = DateTime->new(
      year    => 1,
      month   => 1,
      day     => 1,
  );
  my $rd_to_shire = ( $gdt->utc_rd_values() )[0] -
      ( $dts->utc_rd_values() )[0];

using
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
version 0.21. This is after I adopted that module but before I started
messing with the computational internals.

=head3 HOLIDAY_2_YULE

This manifest constant represents the holiday number of <2 Yule>, i.e.
C<1>.

=head3 HOLIDAY_1_LITHE

This manifest constant represents the holiday number of <1 Lithe>, i.e.
C<2>.

=head3 HOLIDAY_MIDYEARS_DAY

This manifest constant represents the holiday number of <Midyear's day>,
i.e. C<3>.

=head3 HOLIDAY_OVERLITHE

This manifest constant represents the holiday number of <Overlithe>,
i.e. C<4>.

=head3 HOLIDAY_2_LITHE

This manifest constant represents the holiday number of <2 Lithe>, i.e.
C<5>.

=head3 HOLIDAY_1_YULE

This manifest constant represents the holiday number of <1 Yule>, i.e.
C<6>.

=head1 SEE ALSO

L<Date::Tolkien::Shire|Date::Tolkien::Shire>

L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
