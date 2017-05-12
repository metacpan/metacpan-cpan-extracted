#! perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Differences;
use Test::Fatal;

use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath rmtree/;

use Build::Simple;

my $spew = sub { my %info = @_; next_is($info{name}); spew($info{name}, $info{name}) };
my $poke = sub { next_is('poke') };
my $noop = sub { my %args = @_; next_is($args{name}) };

my $dirname = '_testing';
END { rmtree $dirname }
$SIG{INT} = sub { rmtree $dirname; die "Interrupted!\n"};

my $graph = Build::Simple->new;

my $source1_filename = catfile($dirname, 'source1');
$graph->add_file($source1_filename, action => sub { $poke->(); $spew->(@_)});

my $source2_filename = catfile($dirname, 'source2');
$graph->add_file($source2_filename, action => $spew, dependencies => [ $source1_filename ]);

$graph->add_phony('build', action => $noop, dependencies => [ $source1_filename, $source2_filename ]);
$graph->add_phony('test', action => $noop, dependencies => [ 'build' ]);
$graph->add_phony('install', action => $noop, dependencies => [ 'build' ]);

$graph->add_phony('loop1', dependencies => ['loop2']);
$graph->add_phony('loop2', dependencies => ['loop1']);

my @sorted = $graph->_sort_nodes('build');

eq_or_diff \@sorted, [ $source1_filename, $source2_filename, 'build' ], 'topological sort is ok';

my @runs     = qw/build test install/;
my %expected = (
	build => [
		[qw{poke _testing/source1 _testing/source2 build}],
		[qw/build/],

		sub { rmtree $dirname },
		[qw{poke _testing/source1 _testing/source2 build}],
		[qw/build/],

		sub { unlink $source2_filename or die "Couldn't remove $source2_filename: $!" },
		[qw{_testing/source2 build}],
		[qw/build/],

		sub { unlink $source1_filename; sleep 1 },
		[qw{poke _testing/source1 _testing/source2 build}],
		[qw/build/],
	],
	test    => [
		[qw{poke _testing/source1 _testing/source2 build test}],
		[qw/build test/],
	],
	install => [
		[qw{poke _testing/source1 _testing/source2 build install}],
		[qw/build install/],
	],
);

my $run;
our @got;
sub next_is {
	my $gotten = shift;
	push @got, $gotten;
}

for my $runner (sort keys %expected) {
	rmtree $dirname;
	$run = $runner;
	my $count = 1;
	for my $runpart (@{ $expected{$runner} }) {
		if (ref($runpart) eq 'CODE') {
			$runpart->();
		}
		else {
			my @expected = map { catfile(File::Spec::Unix->splitdir($_)) } @{$runpart};
			local @got;
			$graph->run($run, verbosity => 1);
			eq_or_diff \@got, \@expected, "\@got is @expected in run $run-$count";
			$count++;
		}
	}
}

like(exception { $graph->run('loop1') }, qr/loop1 has a circular dependency, aborting/, 'Looping gives an error');

done_testing();

sub spew {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or croak "Couldn't open file '$filename' for writing: $!\n";
	print $fh $content;
	close $fh or croak "couldn't close $filename: $!\n";
	return;
}

