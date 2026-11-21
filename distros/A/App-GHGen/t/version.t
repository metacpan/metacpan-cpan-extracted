#!/usr/bin/env perl

# The release version must agree everywhere: every module, the CLI, the
# top Changes entry and the README.  PAUSE rejects an upload whose
# version it has already seen, so drift here is a release blocker.

use v5.36;
use Test::DescribeMe qw(author);
use Test::Most;
use IPC::Run3 qw(run3);
use Path::Tiny;

my $root = path(__FILE__)->parent->parent;
my $lib  = $root->child('lib')->stringify;
my $bin  = $root->child('bin/ghgen')->stringify;

# Every .pm under lib/ is expected to declare its own $VERSION
my @modules;
$root->child('lib')->visit(sub { push @modules, $_->stringify if /\.pm\z/ }, { recurse => 1 });
@modules = sort @modules;

use_ok('App::GHGen');
my $release = App::GHGen->VERSION;

subtest 'the primary module declares a plain release number' => sub {
	like($release, qr/\A\d+\.\d+\z/, "version is '$release'");
	is(scalar @modules, 9, 'nine modules under lib/');
};

subtest 'every module declares exactly the release version' => sub {
	for my $file (@modules) {
		my ($declared) = path($file)->slurp_utf8 =~ /^our \$VERSION\s*=\s*'([^']+)'/m;
		is($declared, $release, $file);
	}
};

subtest 'the loaded modules agree' => sub {
	for my $file (@modules) {
		(my $name = path($file)->relative($lib)) =~ s{/}{::}g;
		$name =~ s/\.pm\z//;
		require_ok($name);
		is($name->VERSION, $release, "$name->VERSION");
	}
};

subtest 'ghgen --version reports the release version' => sub {
	my ($out, $err);
	run3([ $^X, "-I$lib", $bin, '--version' ], \undef, \$out, \$err);
	is($? >> 8, 0, 'exit 0');
	is($out, "ghgen version $release\n", 'output');
};

subtest 'the top Changes entry is this release, and dated' => sub {
	my ($first) = grep { /^\d/ } $root->child('Changes')->lines_utf8({ chomp => 1 });
	my ($version, $date) = $first =~ /^(\S+)\s*(.*)\z/;
	is($version, $release, 'version matches');
	like($date, qr/\b20\d\d\b/, "dated: '$date'");
};

subtest 'the README names the release version' => sub {
	like($root->child('README.md')->slurp_utf8, qr/^Version \Q$release\E$/m, 'README version line');
};

subtest 'the POD VERSION section names the release version' => sub {
	like($root->child('lib/App/GHGen.pm')->slurp_utf8, qr/^Version \Q$release\E$/m, 'POD version line');
};

done_testing();
