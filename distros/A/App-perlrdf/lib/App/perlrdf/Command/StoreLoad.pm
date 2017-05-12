package App::perlrdf::Command::StoreLoad;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::StoreLoad::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::StoreLoad::VERSION   = '0.006';
}

use App::perlrdf -command;
use namespace::clean;

use constant abstract      => q (Load RDF data into an RDF::Trine::Store.);
use constant command_names => qw( store_load load );
use constant description   => <<'INTRO' . __PACKAGE__->store_help . <<'DESCRIPTION';
Load data into an RDF::Trine::Store. The store should have been previously
initialized (e.g. using the make_store command). 
INTRO

Input files are specified the same way as for the 'translate' command. See
'filespec' for more details. If a parsing error occurs in an input,
subsequent inputs will still be processed. It may be a good idea to check
the input files first using 'validate'.
DESCRIPTION

use constant opt_spec => (
	__PACKAGE__->store_opt_spec,
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'input|i=s@',        'Input filename or URL' ],
	[ 'input-spec|I=s@',   'Input file specification' ],
	[ 'input-format|p=s',  'Input format (mnemonic: parse)' ], 
	[ 'input-base|b=s',    'Input base URI' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'graph|g=s',         'Graph URI for input' ],
	[ 'autograph|G',       'Generate graph URI based on input URI' ],
);

sub execute
{
	require RDF::Trine;
	require App::perlrdf::FileSpec::InputRDF;
	
	my ($self, $opt, $arg) = @_;

	my $store = $self->get_store($opt);
	my $model = RDF::Trine::Model->new($store);

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

	for (@inputs)
	{
		printf STDERR "Loading %s\n", $_->uri;
		
		my %params = ();
		if ($opt->{autograph})
			{ $params{graph} = $_->uri }
		elsif ($opt->{graph})
			{ $params{graph} = $opt->{graph} }
			
		eval {
			local $@ = undef;
			$_->parse_into_model($model, %params);
			1;
		} or warn "$@\n";
	}
}

1;

