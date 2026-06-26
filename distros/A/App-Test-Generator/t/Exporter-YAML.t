#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempfile);
use YAML::XS qw(LoadFile);

use_ok('App::Test::Generator::Exporter::YAML');

my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

subtest 'export() writes a plan hashref to disk as YAML' => sub {
	my (undef, $file) = tempfile(UNLINK => 1);

	my $plan = { module => 'Foo::Bar', function => 'baz', iterations => 100 };
	is($exporter->export($plan, $file), undef, 'export() returns nothing');

	my $loaded = LoadFile($file);
	is_deeply($loaded, $plan, 'round-tripped plan matches the original');
};

subtest 'export() rejects a non-hashref plan' => sub {
	my (undef, $file) = tempfile(UNLINK => 1);

	throws_ok { $exporter->export('not a hashref', $file) }
		qr/hashref/i,
		'croaks when plan is not a hashref';
};

subtest 'export() rejects a missing or empty file path' => sub {
	my $plan = { a => 1 };

	throws_ok { $exporter->export($plan, undef) }
		qr/\S/,
		'croaks when file is undef';

	throws_ok { $exporter->export($plan, '') }
		qr/\S/,
		'croaks when file is an empty string';
};

done_testing();
