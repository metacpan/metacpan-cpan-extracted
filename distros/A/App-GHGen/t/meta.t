#!/usr/bin/env perl

# The generated CPAN META must be valid and list every module we ship.
# It only exists after "perl Makefile.PL" (MYMETA) or in a built
# distribution (META), so the test skips itself in a bare checkout.

use v5.36;
use Test::Most;
use CPAN::Meta;
use Path::Tiny;

my $root = path(__FILE__)->parent->parent;
my ($file) = grep { $_->exists } map { $root->child($_) } qw(META.json MYMETA.json);
plan skip_all => 'no META.json or MYMETA.json (run perl Makefile.PL)' unless $file;

my $meta;
lives_ok { $meta = CPAN::Meta->load_file($file->stringify) } "$file is valid CPAN::Meta";

subtest 'provides lists every module under lib/' => sub {
	my $provides = $meta->provides;
	my @modules;
	$root->child('lib')->visit(
		sub { push @modules, $_->relative($root->child('lib'))->stringify if /\.pm\z/ },
		{ recurse => 1 });
	for my $path (@modules) {
		(my $name = $path) =~ s{/}{::}g;
		$name =~ s/\.pm\z//;
		ok($provides->{$name}, "$name is provided");
		is($provides->{$name}{file}, "lib/$path", "$name file") if $provides->{$name};
	}
	is(scalar keys %{$provides}, scalar @modules, 'nothing extra is provided');
};

subtest 'declared prerequisites' => sub {
	my $runtime = $meta->effective_prereqs->requirements_for('runtime', 'requires')->as_string_hash;
	ok(exists $runtime->{Readonly}, 'Readonly is a runtime prerequisite');
	ok(!exists $runtime->{'IPC::System::Simple'}, 'IPC::System::Simple is not a runtime prerequisite');
	is($runtime->{perl}, '5.036', 'minimum Perl');
};

done_testing();
