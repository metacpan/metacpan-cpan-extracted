package App::perlrdf::Command::Query;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Query::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Query::VERSION   = '0.004';
}

use App::perlrdf -command;
use namespace::clean;

use constant abstract      => q (query stores, files or remote endpoints with SPARQL);
use constant command_names => qw( query sparql q );
use constant description   => <<'DESCRIPTION';
Use SPARQL to query:

	* an RDF::Trine::Store;
	* a remote SPARQL Protocol (1.0/1.1) endpoint; or
	* one or more input files;

But not a combination of the above.
DESCRIPTION

use constant opt_spec => (
	__PACKAGE__->store_opt_spec,
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'input|i=s@',        'Input filename or URL' ],
	[ 'input-spec|I=s@',   'Input file specification' ],
	[ 'input-format|p=s',  'Input format (mnemonic: parse)' ], 
	[ 'input-base|b=s',    'Input base URI' ],
	[ 'graph|g=s',         'Graph URI for input' ],
	[ 'autograph|G',       'Generate graph URI based on input URI' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'endpoint=s',        'Remote SPARQL Protocol endpoint' ],
	[ 'query_method=s',    'Query method (GET/POST/etc)' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'execute|e=s',       'Query to execute' ],
	[ 'sparql-file|f=s',   'File containing query to execute' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>
	[ 'output|o=s@',       'Output filename or URL' ],
	[ 'output-spec|O=s@',  'Output file specification' ],
	[ 'output-format|s=s', 'Output format (mnemonic: serialise)' ],
);

sub validate_args
{
	my ($self, $opt, $arg) = @_;
	
	my %exclusions = (
		execute  => ['sparql_file'],
		endpoint => [
			qw[ store dbi sqlite username password host port dbname database ],
			qw[ input input_spec input_format input_base ],
		],
		query_method => [
			qw[ store dbi sqlite username password host port dbname database ],
			qw[ input input_spec input_format input_base ],
		],
		map { ; $_ => [
			qw[ store dbi sqlite username password host port dbname database ],
			qw[ endpoint ],
		] } qw( input input_spec input_format input_base )
	);
	
	foreach my $k (keys %exclusions)
	{
		next unless exists $opt->{$k};
		foreach my $e (@{ $exclusions{$k} })
		{
			next unless exists $opt->{$e};
			$self->usage_error("Must not provide both '$k' and '$e' options.");
		}
	}
}

sub _sparql
{
	require App::perlrdf::FileSpec::InputFile;
	my ($self, $opt, $arg) = @_;
	
	# SPARQL provided on command line
	#
	return $opt->{execute}
		if $opt->{execute};
	
	# SPARQL from input file
	#
	App::perlrdf::FileSpec::InputFile::
		-> new_from_filespec(
			($opt->{sparql_file} // shift @$arg),
			'SPARQL',
		)
		-> content;
}

sub _model
{
	require App::perlrdf::FileSpec::InputRDF;
	my ($self, $opt, $arg) = @_;
	
	if (grep { exists $opt->{$_} } qw[ store dbi sqlite dbname database ])
	{
		return RDF::Trine::Model->new( $self->get_store($opt) );
	}

	my $model = RDF::Trine::Model->new;
		
	my @inputs = $self->get_filespecs(
		'App::perlrdf::FileSpec::InputRDF',
		input => $opt,
	);
	
	push @inputs, map {
		App::perlrdf::FileSpec::InputRDF::->new_from_filespec(
			$_,
			$opt->{input_format},
			$opt->{input_base},
		)
	} @$arg;

	push @inputs,
		App::perlrdf::FileSpec::InputRDF::->new_from_filespec(
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

	return $model;
}

sub _outputs
{
	require App::perlrdf::FileSpec::OutputRDF;
	require App::perlrdf::FileSpec::OutputBindings;
	
	my ($self, $opt, $arg, $class) = @_;
	
	my @outputs = $self->get_filespecs(
		$class,
		output => $opt,
	);
	push @outputs,
		$class->new_from_filespec(
			'-',
			$opt->{output_format}||'text',
			undef,
		)
		unless @outputs;
	
	return @outputs;
}

sub _process_sparql
{
	require RDF::Query;
	require RDF::Query::Client;	
	my ($self, $opt, $arg, $sparql, $model) = @_;
	
	my $qclass = ref $model ? 'RDF::Query' : 'RDF::Query::Client';
	my @params = ref $model ? () : ({
		QueryMethod => ($opt->{query_method} // $ENV{PERLRDF_QUERY_METHOD} // "POST"),
	});
	my $query  = $qclass->new($sparql) or die RDF::Query->error;
	if ($query->can('useragent')) {
		$query->useragent->max_redirect(5);
		$query->useragent->agent(
			sprintf(
				'%s/%s (%s) %s',
				ref($self),
				$self->VERSION,
				$self->AUTHORITY,
				$query->useragent->agent,
			),
		);
	}
	my $result = $query->execute($model, @params) or do { 
		if (($ENV{PERLRDF_QUERY_DEBUG}//'') and $query->can('http_response')) {
			warn $query->http_response->request->as_string;
			for my $redir ($query->http_response->redirects) {
				warn $redir->status_line;
			}
			warn $query->http_response->as_string;
		}
		die $query->error;
	};
	
	if ($result->is_graph)
	{
		my $m = RDF::Trine::Model->new;
		$m->add_iterator($m);
		
		my (@outputs) = $self->_outputs(
			$opt,
			$arg,
			'App::perlrdf::FileSpec::OutputRDF',
		);
		
		foreach my $out (@outputs)
		{
			$out->serialize_model($m);
			$out->handle->close;
		}
	}
	
	if ($result->is_bindings)
	{
		if (($ENV{PERLRDF_QUERY_DEBUG}//'') and $query->can('http_response')) {
			warn $query->http_response->as_string;
		}
		
		my $mat = $result->materialize;
		
		my (@outputs) = $self->_outputs(
			$opt,
			$arg,
			'App::perlrdf::FileSpec::OutputBindings',
		);
		
		foreach my $out (@outputs)
		{
			$out->serialize_iterator($mat);
			$mat->reset;
		}
	}
}

sub execute
{
	require RDF::Trine;
	my ($self, $opt, $arg) = @_;
	
	my $sparql = $self->_sparql($opt, $arg);

	if (exists $opt->{endpoint})
	{
		return $self->_process_sparql($opt, $arg, $sparql, $opt->{endpoint});
	}

	my $model = $self->_model($opt, $arg);
	$self->_process_sparql($opt, $arg, $sparql, $model);
}

1;


__END__

=head1 NAME

App::perlrdf::Command::Query - SPARQL extension for App-perlrdf

=head1 SYNOPSIS

 $ perlrdf query -e 'SELECT * WHERE { ?s ?p ?o }' -i data.rdf

 $ perlrdf query -e 'SELECT * WHERE { ?s ?p ?o }' -Q store.sqlite

=head1 DESCRIPTION

This module adds query abilities to the C<perlrdf> command-line client.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=App-perlrdf-Command-Query>.

=head1 ENVIRONMENT

Set C<PERLRDF_QUERY_METHOD> to "GET" or "POST" specify a query method.

=head1 SEE ALSO

L<App::perlrdf>, L<RDF::Query>, L<RDF::Query::Client>, L<Spreadsheet::Wright>.

The L<rqsh> tool that comes with RDF::Query.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

