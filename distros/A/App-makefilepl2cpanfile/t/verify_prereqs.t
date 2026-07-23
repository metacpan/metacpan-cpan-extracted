use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use Path::Tiny;

BEGIN { use_ok('App::makefilepl2cpanfile') }

my $dir = tempdir(CLEANUP => 1);
chdir $dir;

path('Makefile.PL')->spew_utf8(<<'END_MF');
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME      => 'Test::Dummy',
	PREREQ_PM => {
		'Foo::Bar' => 0,
		'Baz::Qux' => '1.23',
	},
	TEST_REQUIRES => {
		'Test::More'      => 0,
		'Test::Exception' => 0,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',
	},
	MIN_PERL_VERSION => '5.008',
);
END_MF

my $out = App::makefilepl2cpanfile::generate(
	makefile     => 'Makefile.PL',
	with_develop => 0,
);

# Use parse_prereqs() to enumerate expected modules — avoids duplicating
# the extraction regex in the test.
my $content  = path('Makefile.PL')->slurp_utf8;
my $expected = App::makefilepl2cpanfile::parse_prereqs($content);

for my $phase (sort keys %{$expected}) {
	for my $rel (sort keys %{ $expected->{$phase} }) {
		for my $mod (sort keys %{ $expected->{$phase}{$rel} }) {
			like $out, qr/\b\Q$mod\E\b/,
				"module '$mod' ($phase/$rel) appears in output";
		}
	}
}

like $out, qr/requires 'Baz::Qux', '1\.23'/, 'Baz::Qux version constraint emitted';
like $out, qr/'perl', '5\.008'/,              'MIN_PERL_VERSION emitted';

done_testing;
