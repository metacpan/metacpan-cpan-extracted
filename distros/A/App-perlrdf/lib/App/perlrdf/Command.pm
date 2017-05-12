package App::perlrdf::Command;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::VERSION   = '0.006';
}

use App::Cmd::Setup -command;

use constant store_opt_spec => (
	[ 'database|t=s'      => '"sqlite", "mysql" or "pg"' ],
	[ 'dbname|d=s'        => 'Database name (file name for SQLite)' ],
	[ 'host|h=s'          => 'Database server host name or IP address' ],
	[ 'port=i'            => 'Database server port' ],
	[ 'username|u=s'      => 'User name for database login' ],
	[ 'password=s'        => 'Password for database login' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'dbi|D=s'           => 'DBI DSN' ],
	[ 'sqlite|Q=s'        => 'SQLite file name' ],
	[]=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>=>,
	[ 'store|T=s'         => 'Trine store configuration string' ],
	[ 'model|M=s'         => 'Database model name (defaults to "")' ],
);

use constant store_help => q(
The database to connect to can be specified using the 'database', 'dbname',
'host', 'port', 'username' and 'password' options. Alternatively you can
specify an exact DBI DSN (in which case the 'database', 'dbname', 'host' and
'port' options must not be specified). The 'sqlite' option is a shortcut for
setting the 'database' option to  'sqlite', and setting the 'dbname' option.

Alternatively, you may specify an RDF::Trine::Store configuration string.
If you want to connect to a non-DBI store, this is the only way to specify
it.

Several DBI-based stores can share the same SQL database. This is achieved
by giving them each a different model name (which confusingly has nothing to
do with the RDF::Trine::Model class!).
);

sub get_filespecs
{
	my ($self, $class, $name, $opt) = @_;
	
	my @specs = map {
		$class->new_from_filespec(
			$_,
			$opt->{$name.'_format'},
			$opt->{$name.'_base'},
		)
	} do {
		if (ref $opt->{$name.'_spec'} eq 'ARRAY')
			{ @{$opt->{$name.'_spec'}} }
		elsif (defined $opt->{$name.'_spec'})
			{ ($opt->{$name.'_spec'}) }
		else
			{ qw() }
	};
	
	push @specs, map {
		$class->new_from_filespec(
			"{}$_",
			$opt->{$name.'_format'},
			$opt->{$name.'_base'},
		)
	} do {
		if (ref $opt->{$name} eq 'ARRAY')
			{ @{$opt->{$name}} }
		elsif (defined $opt->{$name})
			{ ($opt->{$name}) }
		else
			{ qw() }
	};

	return @specs;
}

sub get_store
{
	require RDF::Trine;
	
	my ($self, $opt) = @_;
	
	my %exclusions = (
		store  => [qw[ dbi sqlite username password host port dbname database ]],
		sqlite => [qw[ dbi username password host port dbname database ]],
		dbi    => [qw[ host port dbname database ]],
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
	
	if (exists $opt->{dbname} or exists $opt->{database})
	{
		$self->usage_error("'dbname' and 'database' options must be used in conjunction.")
			unless exists $opt->{dbname} && exists $opt->{database};
	}
	
	return RDF::Trine::store($opt->{store}) if exists $opt->{store};
	
	my $dsn = exists $opt->{dbi}
		? $opt->{dbi}
		: do {
			my ($database, $dbname, $host, $port) =
				map { $opt->{$_} }
				qw(database dbname host port);
			if ($opt->{sqlite})
			{
				$database = 'sqlite';
				$dbname   = $opt->{sqlite};
			}
			
			my $d;
			if (lc $database eq 'sqlite')
			{
				$d = "DBI:SQLite:dbname=${dbname}";
				$self->usage_error("SQLite does not support 'host' and 'port'.")
					if $opt->{host} || $opt->{port};
			}
			elsif (lc $database eq 'mysql')
			{
				$d = "DBI:mysql:database=${dbname}";
				$d .= ";host=$host" if $host;
				$d .= ";port=$port" if $port;
			}
			elsif ($database =~ m{^(pg|psql|pgsql|postgres|postgresql)$}i)
			{
				$d = "DBI:Pg:dbname=${dbname}";
				$d .= ";host=$host" if $host;
				$d .= ";port=$port" if $port;
			}
			$d;
		};
	
	if (length $dsn)
	{
		no warnings;
		return RDF::Trine::Store::DBI->new(
			"$opt->{model}",
			$dsn,
			$opt->{username},
			$opt->{password},
		);
	}
	
	return RDF::Trine::store($ENV{PERLRDF_STORE})
		if defined $ENV{PERLRDF_STORE};
	
	$self->usage_error("No SQLite, MySQL or Pg database specified.");
}

sub AUTHORITY
{
	my $class = ref($_[0]) || $_[0];
	no strict qw(refs);
	${"$class\::AUTHORITY"};
}

1;