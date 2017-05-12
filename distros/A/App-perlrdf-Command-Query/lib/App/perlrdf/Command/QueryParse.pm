package App::perlrdf::Command::QueryParse;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::QueryParse::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::QueryParse::VERSION   = '0.004';
}

use base 'App::perlrdf::Command::Query';
use namespace::clean;

use constant abstract      => q (dumps SPARQL in other formats);
use constant command_names => qw( query_parse );
use constant description   => <<'DESCRIPTION';
Output formats are: SSE (default), JSON, YAML, SPARQL.
DESCRIPTION

use constant opt_spec => (
	[ 'execute|e=s',       'Query to parse' ],
	[ 'sparql-file|f=s',   'File containing query to parse' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>
	[ 'output|o=s@',       'Output filename or URL' ],
	[ 'output-spec|O=s@',  'Output file specification' ],
	[ 'output-format|s=s', 'Output format (mnemonic: serialise)' ],
);

sub validate_args
{
	my ($self, $opt, $arg) = @_;
	$self->usage_error("Must not provide both 'sparql_file' and 'execute' options.")
		if exists $opt->{sparql_file} && exists $opt->{execute};
}

sub execute
{
	require JSON;
	require YAML::XS;
	require RDF::Query;
	
	my ($self, $opt, $arg) = @_;
	
	my $sparql = $self->_sparql($opt, $arg);
	my $query  = RDF::Query::->new($sparql)
		or die RDF::Query::->error;

	my (@outputs) = $self->_outputs(
		$opt,
		$arg,
		'App::perlrdf::FileSpec::OutputFile',
	);
	
	foreach my $out (@outputs)
	{
		my $str;
		
		if ($out->format =~ /json/i)
			{ $str = JSON::to_json( $query->as_hash, {pretty=>1,canonical=>1} ) }
		elsif ($out->format =~ /ya?ml/i)
			{ $str = YAML::XS::Dump( $query->as_hash ) }
		elsif ($out->format =~ /sparql/i)
			{ $str = $query->as_sparql }
		else
			{ $str = $query->sse }
		
		$out->handle->print($str);
		$out->handle->close;
	}
}

1;

