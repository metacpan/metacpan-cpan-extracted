package App::perlrdf::Command::Canonicalize;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Canonicalize::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Canonicalize::VERSION   = '0.006';
}

use App::perlrdf -command;
use namespace::clean;

use constant abstract      => q (Generate canonical N-Triples from an input file.);
use constant command_names => qw( canonicalize canonicalise );
use constant description   => <<'DESCRIPTION';
Converts an input file into canonical N-Triples. The idea of canonical
N-Triples is that blank node identifiers are normalised to a predictable
pattern; and statements are serialized in a predictable order. It is
useful as a canonical serialization for graph signing or generating a
SHA1/MD5 digest of a graph.

Not all RDF graphs can be fully canonicalized. The on-fail option allows
you to decide what is done with the extra triples left over from
canonicalization. May be set to "truncate" (the default), "append",
"space" or "die". See RDF::Trine::Serializer::NTriples::Canonical
for more details.

See <http://www.hpl.hp.com/techreports/2003/HPL-2003-142.pdf>.
DESCRIPTION
use constant opt_spec      => (
	[ 'input|i=s',         'Input filename or URL' ],
	[ 'input-spec|I=s',    'Input file specification' ],
	[ 'input-format|p=s',  'Input format (mnemonic: parse)' ], 
	[ 'input-base|b=s',    'Input base URI' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>
	[ 'output|o=s',        'Output filename or URL' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>
	[ 'on-fail|x=s',       'Behaviour when graphs cannot be canonicalized' ],	
);

use constant usage_desc    => '%c canonicalize %o INPUT [OUTPUT]';

sub execute
{
	require App::perlrdf::FileSpec::InputRDF;
	require App::perlrdf::FileSpec::OutputRDF;
	require RDF::Trine::Serializer::NTriples::Canonical;
	
	my ($self, $opt, $arg) = @_;
	
	$opt->{output_format} = 'RDF::Trine::Serializer::NTriples::Canonical';
	$opt->{on_fail}     //= 'truncate';
	
	my @inputs = $self->get_filespecs(
		'App::perlrdf::FileSpec::InputRDF',
		input => $opt,
	);
	
	@inputs = App::perlrdf::FileSpec::InputRDF->new_from_filespec(
		(shift(@$arg) // '-'),
		$opt->{input_format},
		$opt->{input_base},
	) unless @inputs;

	my @outputs = $self->get_filespecs(
		'App::perlrdf::FileSpec::OutputRDF',
		output => $opt,
	);
	
	@outputs = App::perlrdf::FileSpec::OutputRDF->new_from_filespec(
		(shift(@$arg) // '-'),
		$opt->{output_format},
		undef,
	) unless @outputs;
	
	$self->usage_error("Need exactly one input source and one output destination")
		unless @inputs==1 and @outputs==1;
	
	my $in = RDF::Trine::Model->new;
	$inputs[0]->parse_into_model($in);
	
	my $ser = RDF::Trine::Serializer::NTriples::Canonical::->new(
		onfail => $opt->{on_fail},
	);
	
	$ser->serialize_model_to_file($outputs[0]->handle, $in);
}

1;

