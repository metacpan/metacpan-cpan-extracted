#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Pod::Snippets;
use With::Roles;

my @modules = qw/
	AI::TensorFlow::Libtensorflow
	AI::TensorFlow::Libtensorflow::ApiDefMap
	AI::TensorFlow::Libtensorflow::Buffer
	AI::TensorFlow::Libtensorflow::DataType
	AI::TensorFlow::Libtensorflow::Graph
	AI::TensorFlow::Libtensorflow::Tensor

	AI::TensorFlow::Libtensorflow::Manual::Quickstart
/;

plan tests => 0 + @modules;

package # hide from PAUSE
	Test::Pod::Snippets::Role::PodLocatable {

	use Moose::Role;
	use Pod::Simple::Search;

	around _parse => sub {
		my $orig = shift;
		my ($self, $type, $input) = @_;

		my $output = eval { $orig->(@_); };
		my $error = $@;
		if( $error =~ /not found in \@INC/ && $type eq 'module' ) {
			my $pod_file = Pod::Simple::Search->new->find($input);
			if( -f $pod_file ) {
				return $orig->($self, 'file', $pod_file )
			} else {
				die "$error\nUnable to find POD file for $input\n";
			}
		}

		return $output;
	};
}

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
	my $tps = Test::Pod::Snippets->with::roles('+PodLocatable')->new(
		parser => $parser,
	);
	$parser->{tps} = $tps;
	subtest "Testing module $_ snippets" => sub {
		$tps->runtest( module => $_, testgroup => 0 );
	};
}
