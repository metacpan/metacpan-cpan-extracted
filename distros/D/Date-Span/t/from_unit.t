use Date::Span;
use Test::More;

eval { require Time::Local; };
if ($@) {
	plan skip_all => "default range_from_unit requires Time::Local";
	exit;
} else {
	plan tests => 11;
}

## some boring cases
is_deeply(
	[ range_from_unit(2003)  ],
	[ 1041379200, 1072915199 ],
	"expand 2003"
);

is_deeply(
	[ range_from_unit(2004)  ],
	[ 1072915200, 1104537599 ],
	"expand 2004"
);

is_deeply(
	[ range_from_unit(2004,0) ],
	[ 1072915200, 1075593599  ],
	"expand 2004-01"
);

is_deeply(
	[ range_from_unit(2004,0,17) ],
	[ 1074297600, 1074383999     ],
	"expand 2004-01-17"
);

is_deeply(
	[ range_from_unit(2004,0,17,12) ],
	[ 1074340800, 1074344399        ],
	"expand 2004-01-17 12hr"
);

is_deeply(
	[ range_from_unit(2004,0,17,12,30) ],
	[ 1074342600, 1074342659           ],
	"expand 2004-01-17 12:30"
);

## februaries!
is_deeply(
	[ range_from_unit(2004,1)       ],
	[ 1075593600, 1078099199        ],
	"expand 2004-02: leap year"
);

is_deeply(
	[ range_from_unit(2002,1)       ],
	[ 1012521600, 1014940799        ],
	"expand 2002-02: not leap year"
);

is_deeply(
	[ range_from_unit(2000,1)       ],
	[ 949363200, 951868799          ],
	"expand 2000-02: leap year"
);

is_deeply(
	[ range_from_unit(1900,1, sub { 0 }) ],
	[ 0, 2419199 ],
	"expand 1900-02: not leap year; bogus begin_secs sub"
);

is(range_from_unit(), undef, "can't expand empty unit");
