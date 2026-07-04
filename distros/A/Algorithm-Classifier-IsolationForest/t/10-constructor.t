#!perl
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest;

# A dependency-free equivalent of Test::Fatal::exception so the suite needs
# nothing beyond Test::More (matching the dist's TEST_REQUIRES).
sub exception (&) {
	my $code = shift;
	my $ok   = eval { $code->(); 1 };
	return $ok ? undef : ( $@ // 'died' );
}

my $CLASS = 'Algorithm::Classifier::IsolationForest';

subtest 'basic construction' => sub {
	my $f = $CLASS->new;
	isa_ok( $f, $CLASS, 'new() with no args returns an object' );
	can_ok(
		$f,
		qw(new fit score_samples predict path_lengths decision_threshold
			to_json from_json save load)
	);
};

subtest 'defaults' => sub {
	my $f = $CLASS->new;
	is( $f->{n_trees},          100,    'n_trees defaults to 100' );
	is( $f->{sample_size},      256,    'sample_size defaults to 256' );
	is( $f->{mode},             'axis', 'mode defaults to axis' );
	is( $f->{max_depth},        undef,  'max_depth defaults to undef (auto)' );
	is( $f->{seed},             undef,  'seed defaults to undef' );
	is( $f->{contamination},    undef,  'contamination defaults to undef' );
	is( $f->decision_threshold, undef,  'decision_threshold is undef before fit / without contamination' );
}; ## end 'defaults' => sub

subtest 'custom args are honoured' => sub {
	my $f = $CLASS->new(
		n_trees     => 50,
		sample_size => 64,
		max_depth   => 8,
		seed        => 123,
		mode        => 'extended',
	);
	is( $f->{n_trees},     50,         'n_trees set' );
	is( $f->{sample_size}, 64,         'sample_size set' );
	is( $f->{max_depth},   8,          'max_depth set' );
	is( $f->{seed},        123,        'seed set' );
	is( $f->{mode},        'extended', 'mode set' );
}; ## end 'custom args are honoured' => sub

subtest 'mode validation' => sub {
	is( exception { $CLASS->new( mode => 'axis' ) },     undef, "mode => 'axis' is accepted" );
	is( exception { $CLASS->new( mode => 'extended' ) }, undef, "mode => 'extended' is accepted" );
	like(
		exception { $CLASS->new( mode => 'banana' ) },
		qr/mode must be 'axis' or 'extended'/,
		'an unknown mode croaks'
	);
};

subtest 'numeric argument validation' => sub {
	like( exception { $CLASS->new( n_trees     => 0 ) }, qr/n_trees must be >= 1/,     'n_trees => 0 croaks' );
	like( exception { $CLASS->new( sample_size => 0 ) }, qr/sample_size must be >= 1/, 'sample_size => 0 croaks' );
	like(
		exception { $CLASS->new( extension_level => -1 ) },
		qr/extension_level must be >= 0/,
		'negative extension_level croaks'
	);
	is( exception { $CLASS->new( extension_level => 0 ) }, undef, 'extension_level => 0 is accepted' );
}; ## end 'numeric argument validation' => sub

subtest 'contamination validation' => sub {
	is( exception { $CLASS->new( contamination => 0.1 ) }, undef, 'contamination => 0.1 is accepted' );
	is( exception { $CLASS->new( contamination => 0.5 ) },
		undef, 'contamination => 0.5 (upper bound) is accepted' );
	like(
		exception { $CLASS->new( contamination => 0 ) },
		qr/contamination must be a number in \(0, 0\.5\]/,
		'contamination => 0 croaks (must be > 0)'
	);
	like(
		exception { $CLASS->new( contamination => 0.75 ) },
		qr/contamination must be a number in \(0, 0\.5\]/,
		'contamination => 0.75 croaks (must be <= 0.5)'
	);
	like(
		exception { $CLASS->new( contamination => -0.1 ) },
		qr/contamination must be a number in \(0, 0\.5\]/,
		'negative contamination croaks'
	);
}; ## end 'contamination validation' => sub

done_testing;
