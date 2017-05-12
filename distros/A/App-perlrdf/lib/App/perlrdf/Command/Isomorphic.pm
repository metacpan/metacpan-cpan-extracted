package App::perlrdf::Command::Isomorphic;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Isomorphic::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Isomorphic::VERSION   = '0.006';
}

use App::perlrdf -command;
sub graph (_) { RDF::Trine::Graph->new(shift) };
use namespace::clean;

use constant abstract      => q (Determine if two graphs are isomorphic.);
use constant command_names => qw( isomorphic );

use constant opt_spec      => (
	[ 'input|i=s@',        'Input filename or URL' ],
	[ 'input-spec|I=s@',   'Input file specification' ],
	[ 'input-format|p=s',  'Input format (mnemonic: parse)' ], 
	[ 'input-base|b=s',    'Input base URI' ],
);
use constant usage_desc    => '%c isomorphic %o INPUT1 INPUT2';

sub execute
{
	require App::perlrdf::FileSpec::InputRDF;
	require RDF::Trine::Graph;
	
	my ($self, $opt, $arg) = @_;
	
	my @inputs = $self->get_filespecs(
		'App::perlrdf::FileSpec::InputRDF',
		input => $opt,
	);
	
	push @inputs, map {
		App::perlrdf::FileSpec::InputRDF->new_from_filespec(
			$_,
			$opt->{input_format},
			$opt->{input_base},
		)
	} @$arg;

	push @inputs,
		App::perlrdf::FileSpec::InputRDF->new_from_filespec(
			'-',
			$opt->{input_format},
			$opt->{input_base},
		)
		unless @inputs >= 2;

	$self->usage_error("Must provide exactly two inputs!")
		unless @inputs == 2;
	
	my ($i1, $i2) = @inputs;
	my ($m1, $m2) = map {
		my $m = RDF::Trine::Model->new;
		$_->parse_into_model($m);
		$m;
	} $i1, $i2;
	my ($g1, $g2) = map graph, $m1, $m2;
	
	no warnings;
	if ($m1->size == $m2->size)
	{
		say $g1->equals($g2)
			? "graphs are isomorphic"
			: sprintf("graphs differ: %s", $g1->error);
	}
	elsif ($m1->size < $m2->size)
	{
		say $g1->is_subgraph_of($g2)
			? sprintf("%s is a subgraph of %s", $i1->uri, $i2->uri)
			: sprintf("graphs differ: %s", $g1->error);
	}
	else
	{
		say $g2->is_subgraph_of($g1)
			? sprintf("%s is a supergraph of %s", $i1->uri, $i2->uri)
			: sprintf("graphs differ: %s", $g2->error);
	}
}

1;

