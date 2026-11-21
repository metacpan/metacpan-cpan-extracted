#!/usr/bin/env perl

# Declared prerequisites must match what the code loads.  A module used at
# run time but declared only for tests breaks a clean install.

use v5.36;
use Test::Most;
use IPC::Run3 qw(run3);
use Module::CoreList;
use Path::Tiny;

my $root = path(__FILE__)->parent->parent;
my $lib  = $root->child('lib')->stringify;

# Perl version we promise to support (MIN_PERL_VERSION)
my $MIN_PERL = 5.036;

# Modules that must never be required at run time, even though tests use them
my @TEST_ONLY = qw(IPC::System::Simple Capture::Tiny IPC::Run3 Test::Most Test::Exception Test::Needs);

# Modules named by "use X" / "require X" in code, ignoring POD and heredocs
sub modules_used(@files) {
	my %seen;
	for my $file (@files) {
		my ($pod, $here) = (0, undef);
		for my $line (path($file)->lines_utf8) {
			if (defined $here) { undef $here if $line =~ /^\s*\Q$here\E\s*$/; next }
			if ($line =~ /^=(\w+)/) { $pod = $1 ne 'cut'; next }
			next if $pod;
			$here = $1 if $line =~ /<<~?\s*['"]?([A-Z_]+)['"]?/;
			$seen{$1}++ if $line =~ /^\s*(?:use|require)\s+([A-Z][\w:]*)/;
		}
	}
	return [ sort grep { !/\AApp::GHGen\b/ && !Module::CoreList::is_core($_, undef, $MIN_PERL) } keys %seen ];
}

# "requires 'X'" names inside one named section of the cpanfile
sub cpanfile_requires($section) {
	my $text = $root->child('cpanfile')->slurp_utf8;
	my %part = (runtime => qr/\A(.*?)(?:^on\s)/ms, test => qr/^on 'test'.*?\n(.*?)^\};/ms);
	my ($body) = $text =~ $part{$section} or return [];
	return [ sort grep { $_ ne 'perl' } $body =~ /^\s*requires\s+'([\w:]+)'/mg ];
}

# Keys of one hash in Makefile.PL, e.g. PREREQ_PM or TEST_REQUIRES
sub makefile_requires($key) {
	my ($body) = $root->child('Makefile.PL')->slurp_utf8 =~ /\b\Q$key\E\s*=>\s*\{(.*?)\}/s;
	return [ sort $body =~ /'([\w:]+)'\s*=>/g ];
}

my @code_files;
$root->child('lib')->visit(sub { push @code_files, $_->stringify if /\.pm\z/ }, { recurse => 1 });
push @code_files, $root->child('bin/ghgen')->stringify;
my @test_files = map { $_->stringify } $root->child('t')->children(qr/\.t\z/);

subtest 'runtime modules are declared as runtime prerequisites' => sub {
	my $used = modules_used(@code_files);
	my %declared = map { $_ => 1 } @{ cpanfile_requires('runtime') };
	ok(scalar @{$used}, 'found runtime modules: ' . join(', ', @{$used}));
	ok($declared{$_}, "$_ is in the cpanfile runtime section") for @{$used};

	my %make = map { $_ => 1 } @{ makefile_requires('PREREQ_PM') };
	ok($make{$_}, "$_ is in Makefile.PL PREREQ_PM") for @{$used};
};

subtest 'test-only modules are not runtime prerequisites' => sub {
	my %runtime = map { $_ => 1 } @{ cpanfile_requires('runtime') }, @{ makefile_requires('PREREQ_PM') };
	ok(!$runtime{$_}, "$_ is not a runtime prerequisite") for @TEST_ONLY;
};

subtest 'cpanfile and Makefile.PL agree' => sub {
	is_deeply(cpanfile_requires('runtime'), makefile_requires('PREREQ_PM'), 'runtime');
	is_deeply(cpanfile_requires('test'),    makefile_requires('TEST_REQUIRES'), 'test');
};

subtest 'modules used by the tests are declared for tests or runtime' => sub {
	my %declared = map { $_ => 1 } @{ cpanfile_requires('runtime') }, @{ cpanfile_requires('test') };
	ok($declared{$_}, "$_ is declared") for @{ modules_used(@test_files) };
};

subtest 'every module and the CLI load without the test-only modules' => sub {
	my @hidden = map { "-MTest::Without::Module=$_" } @TEST_ONLY;
	for my $file (@code_files) {
		my ($out, $err);
		my @check = $file =~ m{/ghgen\z} ? ('-c', $file) : ('-e', 'use ' . _module_name($file) . '; print qq{ok\n}');
		run3([ $^X, "-I$lib", @hidden, @check ], \undef, \$out, \$err);
		is($? >> 8, 0, "loads: $file") or diag $err;
	}
};

# lib/App/GHGen/Foo.pm -> App::GHGen::Foo
sub _module_name($file) {
	(my $name = path($file)->relative($lib)) =~ s{/}{::}g;
	$name =~ s/\.pm\z//;
	return $name;
}

done_testing();
