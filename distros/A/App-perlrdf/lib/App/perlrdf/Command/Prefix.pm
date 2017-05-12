package App::perlrdf::Command::Prefix;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Prefix::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Prefix::VERSION   = '0.006';
}

use App::perlrdf -command;

use namespace::clean;

use constant abstract      => q (Look up the full URIs for customary prefixes);
use constant command_names => qw( prefix prefixes pfx );
use constant description   => <<'DESCRIPTION';
Given one or more prefixes such as "foaf", "dc", looks up the most
commonly used full URI.
DESCRIPTION
use constant opt_spec     => (
	[ 'format|f=s' => 'Output format ("turtle", "xmlns", "sparql", "text")' ],
);
use constant usage_desc   => '%c prefix %o PREFIX [PREFIX ...]';

sub execute
{
	require RDF::NS;
	
	my ($self, $opt, $arg) = @_;
	
	my $method;
	for ($opt->{format} // '')
	{
		if    (/turtle|ttl/i) { $method = 'TTL' }
		elsif (/sparql/i)     { $method = 'SPARQL' }
		elsif (/xmlns|xml/i)  { $method = 'XMLNS' }
		else                  { $method = 'TXT' }
	}
	
	say for RDF::NS->new('any')->$method(join q<,>, @$arg);
}

1;

