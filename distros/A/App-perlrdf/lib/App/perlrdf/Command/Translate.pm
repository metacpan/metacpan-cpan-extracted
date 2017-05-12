package App::perlrdf::Command::Translate;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Translate::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Translate::VERSION   = '0.006';
}

use App::perlrdf -command;

sub skolem ($)
{
	require Data::UUID;
	require RDF::Trine;
	
	my $model = shift;
	my %map;
	my $uuid = Data::UUID->new;
	my @statements = 
		grep { $_->has_blanks }
		$model->get_statements(undef, undef, undef, undef)->get_all;
	$model->remove_statement($_) for @statements;
	$model->add_statement($_)
		for map {
			my $st = $_;
			my @nodes =
				map {
					if ($_->is_blank)
					{
						$map{ $_->blank_identifier }
						||= RDF::Trine::Node::Resource->new(
							sprintf 'urn:uuid:%s', lc $uuid->create_str
						)
					}
					else
					{
						$_
					}
				}
				$st->nodes;
			@nodes==4
				? RDF::Trine::Statement::Quad->new(@nodes)
				: RDF::Trine::Statement->new(@nodes)
		}
		@statements;
}

use namespace::clean;

use constant abstract      => q (Parse/serialise some RDF.);
use constant command_names => qw( translate tr parse serialise serialize );
use constant description   => <<'DESCRIPTION';
Parses the input as RDF in various serialisations, and re-serialises it
in your choice of serialisation.

Input may be a URL, filename or STDIN. If multiple inputs are sepcified,
these are merged into a single graph.

Output may be a URL (for HTTP POST), filename of STDOUT. If multiple
outputs are specified, the entire graph is written to each of them.
DESCRIPTION
use constant opt_spec     => (
	[ 'input|i=s@',        'Input filename or URL' ],
	[ 'input-spec|I=s@',   'Input file specification' ],
	[ 'input-format|p=s',  'Input format (mnemonic: parse)' ], 
	[ 'input-base|b=s',    'Input base URI' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>
	[ 'output|o=s@',       'Output filename or URL' ],
	[ 'output-spec|O=s@',  'Output file specification' ],
	[ 'output-format|s=s', 'Output format (mnemonic: serialise)' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>
	[ 'skolem|k',        'Transform blank nodes into URIs' ],
);

sub execute
{
	require App::perlrdf::FileSpec::InputRDF;
	require App::perlrdf::FileSpec::OutputRDF;
	require RDF::Trine;
	
	my ($self, $opt, $arg) = @_;
	
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
	
	my $model = RDF::Trine::Model->new;
	$_->parse_into_model($model) for @inputs;	
	skolem $model if $opt->{skolem};
	$_->serialize_model($model) for @outputs;
	0;
}

1;

