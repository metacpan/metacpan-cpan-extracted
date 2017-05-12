# 01-basic.t -- basic tests for Acme::DonMartin
#
# Copyright (C) 2005-2006 David Landgren

use Test::More tests => 6;

use strict;
my %fail;

BEGIN {
	for my $module (qw(Test::Cmd Test::File::Contents File::Copy)) {
		eval "use $module"; $@ and $fail{$module}++;
	}
	# the following is merely for CPANTS stats
	if (0) {
		eval 'use Test::Cmd';
		eval 'use Test::File::Contents';
		eval 'use File::Copy';
	}
}

SKIP: {
	if (%fail) {
		diag( "$_ not found" ) for sort keys %fail;
		skip( "Not all modules required for testing were found, skipping encode/decode tests", 4 );
	}

    copy('eg/freq.orig', 'freq.pl') or
		skip( "Unable to prepare test file: $!", 4 );

	my $t = Test::Cmd->new(
        interpreter => $^X,
		prog        => 'eg/freq.pl',
		workdir     => '',
		subdir      => 'sub',
		verbose     => 0,
	);
	ok($t, 'Test::Cmd object built for Acme::DonMartin');

	$t->run;
	is($?, 0, 'encoding pass');

	$t->run(args => 'eg/freq.orig');
	is($?, 0, 'decoding pass');

	(my $res = $t->stdout) =~ s/\s+/_/g;
	my $baseline = do {
	    if (open my $in, '<', 'eg/freq.out') {
	        local $/ = undef;
	        (my $slurp = <$in>) =~ s/\s+/_/g;
	        close $in;
	        $slurp;
	    }
	    else {
	        "cannot open $in for input: $!"
	    }
	};
	cmp_ok( $baseline, 'eq', $res, "acmed output" );

}

SKIP: {
    skip( 'Test::Pod not installed on this system', 1 )
        unless do {
            eval "use Test::Pod";
            $@ ? 0 : 1;
        };

    pod_file_ok( 'DonMartin.pm' );
}

SKIP: {
    skip( 'Test::Pod::Coverage cannot deal with this module', 1 )
        unless do {
            eval "use Test::Pod::Coverage";
            0; # always short-circuit
        };
    pod_coverage_ok( "Acme::DonMartin", "POD coverage is go!" );
}
