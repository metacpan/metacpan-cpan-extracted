package App::perlrdf::Command::StoreDump;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::StoreDump::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::StoreDump::VERSION   = '0.006';
}

use App::perlrdf -command;
use namespace::clean;

use constant abstract      => q (Dump RDF data from an RDF::Trine::Store.);
use constant command_names => qw( store_dump dump );
use constant description   => <<'INTRO' . __PACKAGE__->store_help . <<'DESCRIPTION';
Dump data from an RDF::Trine::Store.
INTRO

Output files are specified the same way as for the 'translate' command. See
'filespec' for more details.
DESCRIPTION

use constant opt_spec => (
	__PACKAGE__->store_opt_spec,
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'output|o=s@',       'Output filename or URL' ],
	[ 'output-spec|O=s@',  'Output file specification' ],
	[ 'output-format|s=s', 'Output format (mnemonic: serialise)' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'graph|g=s@',        'Graph(s) to dump (default: all graphs)' ],
);

sub execute
{
	require RDF::Trine;
	require App::perlrdf::FileSpec::OutputRDF;
	
	my ($self, $opt, $arg) = @_;

	my $store = $self->get_store($opt);
	my $model = RDF::Trine::Model->new($store);

	if ($opt->{graph})
	{
		my $orig = $model;
		$model   = RDF::Trine::Model->new;
		for (@{ $opt->{graph} })
		{
			my $graph = RDF::Trine::Node::Resource->new($_);
			$model->add_iterator( scalar $orig->get_statements((undef)x3, $graph) );
		}
	}

	my @outputs = $self->get_filespecs(
		'App::perlrdf::FileSpec::OutputRDF',
		output => $opt,
	);
	
	push @outputs, map {
		App::perlrdf::FileSpec::OutputRDF->new_from_filespec(
			$_,
			$opt->{output_format},
			$opt->{output_base},
		)
	} @$arg;
	
	push @outputs,
		App::perlrdf::FileSpec::OutputRDF->new_from_filespec(
			'-',
			($opt->{output_format} // 'NQuads'),
			$opt->{output_base},
		)
		unless @outputs;
	
	for (@outputs)
	{
		printf STDERR "Writing %s\n", $_->uri;
		
		eval {
			local $@ = undef;
			$_->serialize_model($model);
			1;
		} or warn "$@\n";
	}
}

1;