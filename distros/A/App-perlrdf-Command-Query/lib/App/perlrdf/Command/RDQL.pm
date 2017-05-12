package App::perlrdf::Command::RDQL;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::RDQL::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::RDQL::VERSION   = '0.004';
}

use base 'App::perlrdf::Command::Query';
use namespace::clean;

use constant abstract      => q (query stores, files or remote endpoints with RDQL);
use constant command_names => qw( rdql );
use constant description   => <<'DESCRIPTION';
Use RDQL to query:

	* an RDF::Trine::Store;
	* a remote SPARQL Protocol (1.0/1.1) endpoint; or
	* one or more input files;

But not a combination of the above.
DESCRIPTION

sub opt_spec
{
	map {
		$_->[0] =~ s/sparql/rdql/ if @$_;
		$_;
	} shift->SUPER::opt_spec
}

sub validate_args
{
	my ($self, $opt, $arg) = @_;
	$self->usage_error("Must not provide both 'rdql_file' and 'execute' options.")
		if exists $opt->{rdql_file} && exists $opt->{execute};
	$self->SUPER::validate_args($opt, $arg);
}

sub _sparql
{
	require RDF::Query;
	my ($self, $opt, $arg) = @_;
	my $rdql  = $self->SUPER::_sparql($opt, $arg);
	my $query = RDF::Query::->new($rdql, { lang => 'rdql' })
		or die RDF::Query->error;
	return $query->as_sparql;
}

1;

