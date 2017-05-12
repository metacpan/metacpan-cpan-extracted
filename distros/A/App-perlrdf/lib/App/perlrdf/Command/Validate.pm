package App::perlrdf::Command::Validate;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Validate::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Validate::VERSION   = '0.006';
}

use App::perlrdf -command;
use namespace::clean;

use constant abstract      => q (Check syntax of RDF files.);
use constant command_names => qw( validate val );
use constant description   => <<'DESCRIPTION';
Given inputs, parses them and reports any errors.

The output conforms to the Test Anything Protocol.
DESCRIPTION
use constant opt_spec     => (
	[ 'input|i=s@',        'Input filename or URL' ],
	[ 'input-spec|I=s@',   'Input file specification' ],
	[ 'input-format|p=s',  'Input format (mnemonic: parse)' ], 
	[ 'input-base|b=s',    'Input base URI' ],
);
use constant usage_desc   => '%c validate %o INPUT [INPUT ...]';

sub execute
{
	require App::perlrdf::FileSpec::InputRDF;
	require RDF::Trine;
	require App::perlrdf::DummyModel;
	
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
		unless @inputs;

	$self->output_tap_header(\@inputs);
	for my $in (@inputs)
	{
		my $model = App::perlrdf::DummyModel::->new;
		my $valid = eval {
			local $@ = undef;
			$in->parse_into_model($model);
			1;
		};
		$self->output_tap_result($in, $valid, $$model);
	}
	$self->output_tap_footer(\@inputs);
}

sub output_tap_header
{
	my ($self, $inputs) = @_;
	printf("1..%d\n", scalar @$inputs);
}

sub output_tap_result
{
	my ($self, $in, $valid, $size) = @_;
	
	my $parser_name = sub
	{
		my $f = shift;
		my $p = ref($f->parser);
		return $1 if $p =~ /^.+::([^:]+?)$/;
		return $p;
	};
	
	if ($valid)
	{
		++$self->{tap_pass};
		printf(
			"ok %d - %s is valid %s, %d triples\n",
			++$self->{tap_total},
			$in->uri,
			$in->$parser_name,
			$size,
		);
	}
	else
	{
		printf(
			"not ok %d - %s is broken %s, %d triples before failure\n",
			++$self->{tap_total},
			$in->uri,
			$in->$parser_name,
			$size,
		);
	}
}

sub output_tap_footer
{
	my $self = shift;
	
	my $n = $self->{tap_total} - $self->{tap_pass};
	$n = 254 if $n > 254;
	
	if ($n)
	{
		print "# Summary: $self->{tap_pass} ok; $n not ok.\n";
	}
	
	exit($n);
}

1;

