package Crop::Config;

=pod

=head1 NAME

Crop::Config - Configuration management for the Crop framework

=head1 VERSION

0.1.26

=head1 SYNOPSIS

    use Crop::Config;
    my $config = Crop::Config->data;

=head1 DESCRIPTION

Crop::Config provides configuration data for the Crop framework. It loads, validates, and parses the main configuration XML file, supporting environment-based overrides and schema validation.

=head1 CONSTANTS

=over 4

=item * CONF_PATH
Directory containing configuration files. Defaults to C<~/.crop>, can be overridden by the C<CROP_CONFIG> environment variable.

=item * CONFIG_FILE
Name of the main configuration file (default: C<global.xml>).

=item * SCHEMA_FILE
Name of the schema file for validating the main config (default: C<global.xsd>).

=item * SCHEMA_ORIGIN
URL to the original schema. This is the only constant you MUST set to the actual value.

=back

=head1 METHODS

=head2 data

    my $config = Crop::Config->data;

Returns a hash reference containing all configuration parameters from the config file.

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 DEPENDENCIES

=over 4

=item * XML::LibXML
=item * Time::Stamp
=item * Clone
=item * XML::LibXSLT
=item * JSON
=item * CGI::Cookie
=item * CGI::Fast

=back

=head1 AUTHORS

Euvgenio (Core Developer)

Alex (Contributor)

=head1 COPYRIGHT AND LICENSE

Apache 2.0

See also: L<https://creazilla.com/pages/creazilla-on-perl>

=cut

use v5.14;
use warnings;

use XML::LibXML;
use XML::LibXML::XPathContext;

sub the;

=begin nd
Constant: CONF_PATH
	Directory name contains configuration files.
	
	Default value is '~/.crop'.
	Could be redefined by enviroment variable CROP_CONFIG to run several projects.
	
	To use the Apache Server You need to set 'FcgidInitialEnv CROP_CONFIG /home/ms/back/.crop' in
	Apache config file.

Constant: CONFIG_FILE
	Name of the main configuration file.

Constant: SCHEMA_FILE
	Name of the Schema file for check XML of main config.

Constant: SHEMA_ORIGIN
	The URL to original Shema.
	
	This is ONLY constant what you MUST set to the actual value.
=cut
use constant {
	CONF_PATH     => $ENV{CROP_CONFIG} || "$ENV{HOME}/.crop",
	CONFIG_FILE   => '/global.xml',
	SCHEMA_FILE   => '/global.xsd',
	SCHEMA_ORIGIN => 'http://example.org/schema/MSC',  # SET TO THE ACTUAL VALUE !!!
};

=begin nd
Variable: my $Schema_ns;
	Namespace of the given schema for use in the config.xml.
	
	It is evaluated by lowercasing last part of <SCHEMA_ORIGIN>.
=cut
my ($Schema_ns) = SCHEMA_ORIGIN =~ /(\w+)$/;
$Schema_ns = lc $Schema_ns;

my $conf_path = CONF_PATH . CONFIG_FILE;
-e $conf_path or die "No main config '$conf_path' file found.";

# read config, validate
my $dom = XML::LibXML->load_xml(location => $conf_path) or die "Can not load xml";  
my $schema = XML::LibXML::Schema->new(location => CONF_PATH . SCHEMA_FILE);
eval {$schema->validate($dom)};
if ($@) {
	print STDERR "File global.xml does not match a given schema. Error message: $@\n";
	exit;
}

my $xpc = XML::LibXML::XPathContext->new($dom);
$xpc->registerNs($Schema_ns, SCHEMA_ORIGIN);

=begin nd
Variable: my $Data
	A prepared hash contains all the configuration parameters from the config file.
=cut
my %Data = (
	install   => {
		path => the("$Schema_ns:project/$Schema_ns:install/$Schema_ns:path")->to_literal,
		url  => the("$Schema_ns:project/$Schema_ns:install/$Schema_ns:url") ->to_literal,
		mode => the("$Schema_ns:project/$Schema_ns:install/$Schema_ns:mode")->to_literal,
	},
	warehouse => {
		db       => {},
		relation => {},
	},
	upload   => {
		dir  => the("$Schema_ns:project/$Schema_ns:upload/$Schema_ns:dir") ->to_literal,
		path => the("$Schema_ns:project/$Schema_ns:upload/$Schema_ns:path")->to_literal,
		url  => the("$Schema_ns:project/$Schema_ns:upload/$Schema_ns:url") ->to_literal,
	},
	logLevel => the("/$Schema_ns:project/$Schema_ns:logLevel")->to_literal,
	debug    => {
		output => the("/$Schema_ns:project/$Schema_ns:debug/$Schema_ns:output")->to_literal,
		layer  => [],
	},
);

# build perl-structure
for my $db ($xpc->findnodes("/$Schema_ns:project/$Schema_ns:warehouse/$Schema_ns:db")) {
	my $id     = the './@id',               $db;
	my $name   = the "./$Schema_ns:name",   $db;
	my $driver = the "./$Schema_ns:driver", $db;
	
	my $server = the "./$Schema_ns:server", $db;
	my $host   = the "./$Schema_ns:host", $server;
	my $port   = the "./$Schema_ns:port", $server;

	my $cur_db = $Data{warehouse}{db}{$id->to_literal} = {
		name   => $name->to_literal,
		server => {
			host => $host->to_literal,
			port => $port->to_literal,
		},
		driver => $driver->to_literal,
		role => {
			user  => undef,
			admin => undef,
		},
	};
	
	for (qw/ user admin /) {
		my $role  = the "./$Schema_ns:role/$Schema_ns:$_", $db;
		
		my $login = the "./$Schema_ns:login", $role;
		my $pass  = the "./$Schema_ns:pass",  $role;
		
		$cur_db->{role}{$_}{login} = $login->to_literal;
		$cur_db->{role}{$_}{pass}  = $pass->to_literal;
	}
}

for (@{$xpc->findnodes("/$Schema_ns:project/$Schema_ns:warehouse/$Schema_ns:relation")}) {
	my $name = the './@name', $_;
	my $db   = the "./$Schema_ns:db", $_;
	
	$Data{warehouse}{relation}{$name->to_literal} = $db->to_literal;
}

for (@{$xpc->findnodes("/$Schema_ns:project/$Schema_ns:test/$Schema_ns:url")}) {
	my $name = the './@name', $_;
	my $db   = the "./$Schema_ns:path", $_;
	
	$Data{test}{url}{$name->to_literal} = $db->to_literal;
}

push @{$Data{debug}{layer}}, $_->to_literal for $xpc->findnodes("/$Schema_ns:project/$Schema_ns:debug/$Schema_ns:layer");

=begin nd
Function: the ($item, $base)
	Get single value from XML-struct.
=cut
sub the {
	my ($item, $base) = @_;
	
	if (defined $base) {
		shift @{$xpc->findnodes($item, $base)};
	} else {
		shift @{$xpc->findnodes($item)};
	}
}

=begin nd
Function: data ( )
	Get Singlton.
=cut
sub data {
	return \%Data;
}

1;
