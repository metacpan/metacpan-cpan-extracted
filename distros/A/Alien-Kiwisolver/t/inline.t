#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 2;

use Test::Needs qw(Inline::CPP);

subtest "Testing version" => sub {
	Inline->import( with => 'Alien::Kiwisolver' );
	Inline->bind( CPP => <<'EOF' );
char* kiwi_version() {
	return KIWI_VERSION;
}
EOF

	note kiwi_version();
	like kiwi_version(), qr/^[\d.]+$/, 'Got version';
};

subtest "Testing constraints" => sub {
	Inline->import( with => 'Alien::Kiwisolver' );
	Inline->bind( CPP => <<'EOF' );
using namespace kiwi;

SV* kiwi_constraints() {
	Variable x1("x1");
	Variable x2("x2");
	Variable xm("xm");

	Constraint constraints[] = {
		Constraint {x1 >= 0},
		Constraint {x2 <= 100},
		Constraint {x2 >= x1 + 20},
		Constraint {xm == (x1 + x2) / 2}
	};

	Solver solver;

	for(auto& constraint : constraints) {
		solver.addConstraint(constraint);
	}

	solver.addConstraint( Constraint( x1 == 40, strength::weak ) );
	solver.addEditVariable(xm, strength::strong);
	solver.suggestValue(xm, 60);

	solver.updateVariables();

	HV* variables = newHV();
	Variable vs[] = {x1, x2, xm};
	for( auto& v : vs ) {
		const char* v_name = v.name().c_str();
		hv_store( variables, v_name, strlen(v_name), newSVnv(v.value()), 0);
	}

	return newRV_noinc((SV*) variables);
}
EOF

	is_deeply kiwi_constraints(), {
		xm => 60,
		x1 => 40,
		x2 => 80,
	}, 'solution variables';
};

done_testing;
