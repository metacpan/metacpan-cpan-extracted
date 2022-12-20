#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Pod::Snippets;

my @modules = qw/
	AI::TensorFlow::Libtensorflow
	AI::TensorFlow::Libtensorflow::ApiDefMap
	AI::TensorFlow::Libtensorflow::Buffer
	AI::TensorFlow::Libtensorflow::DataType
	AI::TensorFlow::Libtensorflow::Graph
	AI::TensorFlow::Libtensorflow::Tensor
/;

plan tests => 0 + @modules;


package # hide from PAUSE
	My::Test::Pod::Snippets::Parser {
	use Moose;
	extends 'Test::Pod::Snippets::Parser';

	sub FOREIGNBUILDARGS { () }

	around command => sub {
		my $orig = shift;
		my ($parser, $command, $paragraph, $line_nbr ) = @_;
		if($paragraph =~ /COPYRIGHT AND LICENSE/) {
			$parser->{tps_ignore} = 1;
			return;
		};
		my $return = $orig->(@_);
		$return;
	}
}

for (@modules) {
	my $parser = My::Test::Pod::Snippets::Parser->new;
	my $tps = Test::Pod::Snippets->new(
		parser => $parser,
	);
	$parser->{tps} = $tps;
	subtest "Testing module $_ snippets" => sub {
		$tps->runtest( module => $_, testgroup => 0 );
	};
}
