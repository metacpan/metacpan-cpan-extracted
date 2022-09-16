use App::Games::Keno;
use Test2::V0;

ok(
	lives {
		App::Games::Keno->new(
			spots => [ 45, 33, 12, 7, 8, 9, 77 ],
			draws => 1000
		);
	},
	"'I choose my spots' with draws did not die"
) or note($@);

ok(
	lives {
		App::Games::Keno->new(
			num_spots => 5,
			draws     => 1000
		);
	},
	"'House chooses spots' with draws did not die"
) or note($@);

like(
	dies {
		App::Games::Keno->new();
	},
	qr/Didn't get the number of draws you want/,
	"No draws dies as expected",
);

like(
	dies {
		App::Games::Keno->new(
			spots     => [ 45, 33, 12, 7, 8, 9, 77 ],
			num_spots => 5,
			draws     => 1
		);
	},
	qr/not both/,
	"Not both dies as expected",
);

like(
	dies {
		App::Games::Keno->new( draws => 1000 );
	},
	qr/Need spots or number of spots/,
	"No spots dies as expected",
);

ok(
	lives {
		App::Games::Keno->new(
			spots   => [80],
			draws   => 1000,
			verbose => 1
		);
	},
	"Verbose level 1 did not die"
) or note($@);

ok(
	lives {
		App::Games::Keno->new(
			spots => [80],
			draws => 1000
		);
	},
	"Choosing spot '80' did not die"
) or note($@);

ok(
	lives {
		App::Games::Keno->new(
			spots => [1],
			draws => 1000
		);
	},
	"Choosing spot '1' did not die"
) or note($@);

like(
	dies {
		App::Games::Keno->new(
			spots => [0],
			draws => 1000
		);
	},
	qr/You chose a spot that is out of the 1 to 80 range/,
	"Choosing spot 0 dies as expected",
);

like(
	dies {
		App::Games::Keno->new(
			spots => [81],
			draws => 1000
		);
	},
	qr/You chose a spot that is out of the 1 to 80 range/,
	"Choosing spot 81 dies as expected",
);

like(
	dies {
		App::Games::Keno->new(
			spots => [ 1, 1 ],
			draws => 1000
		);
	},
	qr/You appear to have chosen two or more of the same spots/,
	"Choosing spots 1 and 1 dies as expected",
);
like(
	dies {
		App::Games::Keno->new(
			spots => [],
			draws => 1000
		);
	},
	qr/You must choose at least one spot/,
	"Choosing 0 spots dies as expected",
);
like(
	dies {
		App::Games::Keno->new(
			spots => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ],
			draws => 1000
		);
	},
	qr/You must choose between 1 and 10 spots/,
	"Choosing 11 spots dies as expected",
);

like(
	dies {
		App::Games::Keno->new(
			spots => [ 81, 81 ],
			draws => 1000
		);
	},
	qr/You chose a spot that is out of the 1 to 80 range/,
	"Choosing 81 and 81 (both out of range and the same) dies as expected",
);

like(
	dies {
		App::Games::Keno->new(
			spots => [1],
			draws => 'asdf'
		);
	},
	qr/does not pass the type constraint/,
	"non numeric draws dies as expected",
);

like(
	dies {
		App::Games::Keno->new(
			spots => ['f'],
			draws => 1
		);
	},
	qr/One of the spots you chose doesn't look like a number/,
	"non numeric chosen spot dies as expected",
);

ok(
	lives {
		App::Games::Keno->new(
			spots   => [1],
			draws   => 1,
			verbose => -2
		);
	},
	"negative verbose level does not die",
) or note($@);

ok(
	lives {
		App::Games::Keno->new(
			spots   => [1],
			draws   => 1,
			verbose => 40
		);
	},
	"Verbose level out of range does not die",
) or note($@);

done_testing;
