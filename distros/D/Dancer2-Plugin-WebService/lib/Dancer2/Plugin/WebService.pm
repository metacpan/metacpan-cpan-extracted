# ABSTRACT: Rapid creation of RESTful Web Services with sessions and persistent data
# Provides Routes for authentication and persistent session data
# It can handle the formats : JSON , XML , YAML, PERL , HUMAN
#
# INTERNAL authorization methods must be named as __AUTH_SomeName
# where the SomeName is the same as in config.yml e.g. __AUTH_simple
#
# George Bouras
# george.mpouras@yandex.com
# 24 May 2018
# Athens - Greece


package Dancer2::Plugin::WebService;
use		Dancer2::Plugin;
use		Storable;
use		strict;
use		warnings;
our		$VERSION = '3.101';

if ($^O=~/(?i)MSWin/) {warn "Sorry this operating system is not supported (and it will never be)\n"; exit 1}

has from				=> (is=>'rw', from_config=>'Default format',     default=> sub{'json'});
has Session_idle_timout	=> (is=>'ro', from_config=>'Session idle timout',default=> sub{ 3600 });
has rules				=> (is=>'ro', from_config=>'Allowed hosts',      default=> sub{ ['127.*', '192.168.*', '10.*', '172.16.*'] });
has groups				=> (is=>'ro', from_config=>'User must belong to one or more of the groups', default=> sub{ [] });
has rules_compiled		=> (is=>'ro', default=> sub {my $array = [@{$_[0]->rules}]; for (@{$array}) { s/([^?*]+)/\Q$1\E/g; s|\?|.|g; s|\*+|.*?|g; $_ = qr/^$_$/i } $array});
has dir_session			=> (is=>'ro', default=> sub {if (exists $_[0]->config->{'Session directory'}) { $_[0]->config->{'Session directory'}."/$_[0]->{app}->{name}" } else { ($_= $_[0]->{app}->{config}->{appdir}) =~s/\/*$//; $_ .= '/session' } });
has formats				=> (is=>'ro', default=> sub{{json=> 'application/json', xml=> 'text/xml', yaml=> 'text/x-yaml', perl=> 'text/html', human=> 'text/html'}});
has formats_regex		=> (is=>'ro', default=> sub{ $_=join '|', sort keys %{ $_[0]->formats }; $_ = qr/^($_)$/; $_ });
has sudo				=> (is=>'ro', default=> sub{for (split /:/,$ENV{PATH}) {return "$_/sudo" if -f "$_/sudo" && -x "$_/sudo"} warn "Sorry, could not found shell utility sudo\n"; exit 1});
has rm					=> (is=>'ro', default=> sub{for (split /:/,$ENV{PATH}) {return "$_/rm"   if -f "$_/rm"   && -x "$_/rm"  } warn "Sorry, could not found shell utility rm\n";   exit 1});
has to					=> (is=>'rw', default=> sub{ $_[0]->from });
has error				=> (is=>'rw', default=> 0);
has errormessage		=> (is=>'rw', default=> 'ok');
has ClientIP			=> (is=>'rw', default=> '');
has route_name			=> (is=>'rw', default=> '');
has data_from			=> (is=>'rw', default=> '');		# string of send data 
has data_to				=> (is=>'rw', default=> '');		# string of send data rebuilded
has data				=> (is=>'rw', default=> sub{ {} });	# hash   of the string a data_from
has auth_method			=> (is=>'rw', default=> '');
has auth_command		=> (is=>'rw', default=> '');
has auth_config			=> (is=>'rw', default=> sub{ {} });
has auth_member_of		=> (is=>'rw', default=> sub{ [] });
has auth_result			=> (is=>'rw', default=> 0);
has auth_message		=> (is=>'rw', default=> '');




sub BUILD
{
my $plugin = shift;

# Security of the built in Routes
$plugin->config->{Routes}->{info}	= 'public';
$plugin->config->{Routes}->{login}	= 'public';
$plugin->config->{Routes}->{logout}	= 'private';

# Default settings
$plugin->{app}->{config}->{content_type}									= 'application/json';
$plugin->{app}->{config}->{charset}											//= 'UTF-8';
$plugin->{app}->{config}->{encoding}										//= 'UTF-8';
$plugin->{app}->{config}->{show_errors}										//= 1;
$plugin->{app}->{config}->{plugins}->{WebService}->{'Default format'}		//= 'json';
$plugin->{app}->{config}->{plugins}->{WebService}->{'Session idle timout'}	//= 3600;

unless( __MKDIR($plugin->dir_session) ) {warn 'Could not create the session directory '.$plugin->dir_session." because $!\n"; exit 1}
(my $module_dir =__FILE__) =~s|/[^/]+$||;
unless (-d $module_dir) {warn "Sorry could not find the Dancer2::Plugin::WebService installation directory\n"; exit 1}

print STDOUT "\nWebService version   : $VERSION\n";
print STDOUT "Application          : $plugin->{app}->{name}\n";
print STDOUT 'Session storage      : ', $plugin->dir_session ,"/\n";
print STDOUT 'Session idle timeout : ', $plugin->Session_idle_timout ,"\n";
print STDOUT 'Run as user          : ', (getpwuid($>))[0] ,"\n";
print STDOUT 'Start time           : ', scalar(localtime $^T) ,"\n";
print STDOUT "Module dir           : $module_dir\n";
print STDOUT "Process identifier   : $$\n";

# Use the first active authentication method

	foreach my $method (@{$plugin->config->{'Authentication methods'}})
	{
	next unless ( exists $method->{Active} ) && ( $method->{Active} =~/(?i)y/ );
	$plugin->auth_method( $method->{Name} );
	unless (exists $method->{Command}) {warn "\nThe active Authentication method \"".$plugin->auth_method."\" does not know what to do\n"; exit 1}

		# Internal
		if ( $method->{Command} eq 'INTERNAL' ) {

			unless ( __PACKAGE__->can( '__AUTH_'.$plugin->auth_method ) ) {
			warn 'Sorry, for '. $plugin->auth_method .' authorization could not found the method '.   __PACKAGE__ .'::__AUTH_'.$plugin->auth_method ."\n";
			exit 1
			}

		$plugin->auth_command( $method->{Command} )
		}

		# External script
		else {
		$method->{Command} =~s/^MODULE_INSTALL_DIR/$module_dir/;
		unless (-f $method->{Command}) {warn "Sorry, could not found the external authorization utility $method->{Command}\n"; exit 1}
		unless (-x $method->{Command}) {warn "Sorry, the external authorization utility $method->{Command} is not executable from user ". getpwuid($>) ."\n"; exit 1}

			if ( $method->{'Use sudo'} =~/(?i)y/ ) {
			$plugin->auth_command( $plugin->sudo ." \Q$method->{Command}\E" )
			}
			else {
			$plugin->auth_command( "\Q$method->{Command}\E" );
			}
		}

	delete @{$method}{ qw/Active Name Command/ };
	$plugin->auth_config($method);
	last
	}

delete $plugin->config->{'Authentication methods'};

# Check if there is an active auth method if there are private routes

	foreach (keys %{$plugin->config->{Routes}}) {
	next if $plugin->config->{Routes}->{$_} =~/(?i)public/;
		if ($plugin->auth_method eq '') {
		warn "While there is at least one private route ( $_ ) there are not any active authorization methods\n";
		exit 1
		}
	last
	}

print STDOUT 'Authorization method : ',$plugin->auth_method	,"\n";
print STDOUT 'Authorization command: ',$plugin->auth_command,"\n\n";

# Clear expired stored sessions
$_ = $plugin->dir_session;
opendir __SESSIONDIR, $_ or die "Could not list session directory $_ because $!\n";

	foreach my $session (grep ! /^\.+$/, readdir __SESSIONDIR) {

		if (-f "$_/$session") {
		unlink "$_/$session";
		next
		}

		unless ((-f "$_/$session/__clientip") && (-f "$_/$session/__lastaccess") && (-f "$_/$session/__logintime") && (-f "$_/$session/__user")) {
		print STDERR "Delete corrupt session: $session\n";
		system $plugin->rm, '--recursive', '--force', "$_/$session";
		next
		}

		my $lastaccess = ${ Storable::retrieve "$_/$session/__lastaccess" };

		if (time - $lastaccess > $plugin->config->{'Session idle timout'}) {
		print STDOUT "Delete expired session: $session\n";
		system $plugin->rm, '--recursive', '--force', "$_/$session"
		}
		else {
		print STDOUT "Found stored session  : $session\n"
		}
	}

closedir __SESSIONDIR;


# <after hook>
# Reset any posted data
# Not needed any more because we do it while parsing posted data later

	# $plugin->app->add_hook( Dancer2::Core::Hook->new(name => 'after', code => sub { $plugin->data({}) }) );


# <before hook> to realtime process the request

	$plugin->app->add_hook(Dancer2::Core::Hook->new(
	name => 'before',
	code => sub {

	# Find the route name
	($_) = $plugin->dsl->request->{route}->{spec_route} =~/^\/*([^:?]*)/; s|/*$||;
	$plugin->route_name($_);

	# If a route is not defined at the configuration file it will be considered as public
	$plugin->config->{Routes}->{ $plugin->route_name } = 'public' unless exists $plugin->config->{Routes}->{ $plugin->route_name };

	$plugin->from($plugin->app->request->query_parameters->{from}	// $plugin->config->{'Default format'});
	$plugin->to(  $plugin->app->request->query_parameters->{to}		// $plugin->from);
	if ( $plugin->from	!~ $plugin->formats_regex ) { $plugin->error(20); $plugin->errormessage('property from '.$plugin->from.' is not one of the supported : '. join(', ',keys %{$plugin->formats})); $plugin->to('json'); $plugin->dsl->halt( $plugin->reply ) }
	if ( $plugin->to	!~ $plugin->formats_regex ) { $plugin->error(21); $plugin->errormessage('property to '.  $plugin->to.  ' is not one of the supported : '. join(', ',keys %{$plugin->formats})); $plugin->to('json'); $plugin->dsl->halt( $plugin->reply ) }

	# add header
	$plugin->dsl->request->header('Content-Type'=> $plugin->formats->{$plugin->to});

	# Parse user's posted/sent data
	# if user did not send any data are are reseting our properties

		if ( $plugin->app->request->body ) { 
		$plugin->data_from( $plugin->app->request->body );
		my $hash = $plugin->__CONVERT_STRING_TO_HASHREF;

			if ( $plugin->error ) {			
			$plugin->to('json');
			$plugin->dump_user_properties( { error=>$plugin->error, errormessage=>$plugin->errormessage, description=>'Data conversion error from '.$plugin->from.' to '.$plugin->to } );
			$plugin->data( {} );
			die "DataStructure internal error : ". $plugin->errormessage."\n" if $plugin->error;
			$plugin->dsl->halt( $plugin->data_to )
			}

		$plugin->data($hash)
		}
		else {
		$plugin->data_from('');
		$plugin->data({})
		}

	# Setup the remote IP address, even if the web service is running from a reverse proxy
	$plugin->ClientIP( $plugin->dsl->request->env->{HTTP_X_REAL_IP} // $plugin->dsl->request->address // '127.0.0.1' );

	# For public routes there is nothing else to do
	return if 'public' eq $plugin->config->{Routes}->{$plugin->route_name};

	# If we get this far, the route is private ( needs login )
	# if the session is expired halt, otherelse update the __lastaccess

		unless (exists $plugin->data->{SessionID}) {
		$plugin->error(2);
		$plugin->errormessage('You must be logged in for using private route '.$plugin->route_name);
		$plugin->data({description=>'Get SessionID via login route'});
		$plugin->dsl->halt( $plugin->reply )
		}

	$_ = $plugin->dir_session.'/'.$plugin->data->{SessionID};

		unless (-d $_) {
		$plugin->error(3);
		$plugin->errormessage('invalid or expired SessionID');
		$plugin->dsl->halt( $plugin->reply(SessionID=>$plugin->data->{SessionID}, help=>'Get a valid SessionID via login route') )
		}

	my $lastaccess = ${ Storable::retrieve "$_/__lastaccess" };

		if (time - $lastaccess > $plugin->config->{'Session idle timout'}) {
		$plugin->error(4);
		$plugin->errormessage('Session '.$plugin->data->{SessionID}.' expired because its idle time '.(time - $lastaccess).' secs is more than the allowed '.$plugin->config->{'Session idle timout'}.' secs');
		system $plugin->rm, '--recursive', '--force', $_;
		$plugin->dsl->halt( $plugin->reply )
		}
		else {
		Storable::lock_store(\ time, "$_/__lastaccess")
		}

	}));


# Built in route /info redirects to /info/version

	$plugin->app->add_route(
	regexp	=> '/info',
	method	=> 'get',
	code	=> sub { $_[0]->forward('/info/version') }
	);

# Built in route /info/:what

	$plugin->app->add_route(
	method => 'get',
	regexp => '/info/:what',
	code   => sub {

		my $app= shift;

			if ( $app->request->param('what') =~/(?i)v/ ) {

				$plugin->reply(
				Application			=> $plugin->{app}->{name},			
				Os					=> eval{ local $_ = undef; local $/ = undef; open __F, -f '/etc/redhat-release' ? '/etc/redhat-release' : '/etc/issue'; if (fileno __F) { ($_= <__F>)=~s/\s*$//s; $_ = join ' ', split /v/, $_ } close __F; $_ // $^O },
				Bind				=> sub { $_={}; @{$_}{qw/Address Port/} = split /:/, $app->request->host; $_ }->(),
				'WebService uptime'	=> time - $^T,
				Epoch				=> time,
				'Session idle timeout'=> $plugin->Session_idle_timout,
				'Authorization method'=> $plugin->auth_method,
				Version				=> {
					Dancer			=> $Dancer2::VERSION,
					Perl			=> $],
					WebService		=> $VERSION
					}
				)
			}
			elsif ( $app->request->param('what') =~/(?i)cl/ ) {

				$plugin->reply(
				'Address'			=> $plugin->ClientIP,
				'Port'				=> $app->request->env->{REMOTE_PORT},
				'Agent'				=> $app->request->agent,
				'Is secure'			=> $app->request->secure,
				'Protocol'			=> $app->request->protocol,
				'Http method'		=> $app->request->method,
				'Header accept'		=> $app->request->header('accept'),
				'Parameters url'	=> join(' ', $app->request->params('query')),
				'Parameters route'	=> join(' ', $app->request->params('route')),
				'Parameters body'	=> join(' ', $app->request->params('body'))
				)
			}
			else {
				$plugin->reply(
				error=>5,
				errormessage=>'Not existing internal route /info/'. $plugin->dsl->route_parameters->get('what')
				)
			}
		}
	);

# logout and delete the session

	$plugin->app->add_route(
	method => $_,
	regexp => '/logout',
	code   => sub {
		$plugin->error(0);
		$plugin->errormessage('You are logged out');
		$plugin->__Delete_session;
		$plugin->reply('SessionID')
		}

	) foreach 'get', 'post';


#	Authenticate users using external custom scripts or internal methods
#
#		curl --data '{"user":"user2", "password":"pass2"}' 0:3000/login
#
#	With custom scripts/programs you can authenticate against
#	LDAP, kerberus, Active Directory, SQL, or what ever else.
#	It is very easy to write your own scripts and define them at config.yml
#
#	The external scripts expects three arguments
#
#		1) username as hex string
#		2) password as hex string
#		3) comma delimited groups that the user should belong at least to one of them
#
#	The hex strings is for avoiding shell attacks using strange wildcards and paths as username !
#	Remember at linux the maximum length of a shell command is   getconf ARG_MAX
#
#	The result is stored at
#
#		$plugin->auth_result     1 for successful login, or 0 fail
#		$plugin->auth_message    Descriptive short message usually the fail reason
#		$plugin->auth_member_of  In case of successful login, the groups that the user belongs (from the ones we have specify)

	$plugin->app->add_route(
	method => $_,
	regexp => '/login',
	code   => sub {

		my $app = shift;

		# Check client IP address against the access rules
		$plugin->error(13);
		for (my $i=0; $i<@{ $plugin->rules_compiled }; $i++)
		{
			if ( $plugin->ClientIP =~ $plugin->rules_compiled->[$i] ) {
			$plugin->error(0);		
			$plugin->errormessage('ok');
			$plugin->data->{'IP access'} = 'Match client IP '. $plugin->ClientIP .' from rule '. $plugin->rules->[$i];
			last
			}
		}

		if ($plugin->error) {
		$plugin->errormessage('Client IP address '. $plugin->ClientIP .' is not allowed from any IP access rule');
		$plugin->dsl->halt( $plugin->reply('user') )
		}

		# Check the input parameters
		foreach ('user','password') {unless (exists $plugin->data->{$_}) { $plugin->error(6); $plugin->errormessage("Login failed, you did not pass the mandatory key $_"); $plugin->dsl->halt( $plugin->reply ) }}
		if ( $plugin->data->{user} =~ /^\s*$/ ) { $plugin->error(7); $plugin->errormessage("Login failed because the user is blank");     $plugin->dsl->halt( $plugin->reply ) }
		if ( $plugin->data->{password} eq ''  ) { $plugin->error(8); $plugin->errormessage("Login failed because the password is blank"); $plugin->dsl->halt( $plugin->reply('user')  ) }
		if ( 0 == @{ $plugin->groups }        ) { $plugin->error(9); $plugin->errormessage("Login failed because the required group list is empty"); $plugin->dsl->halt( $plugin->reply('user') ) }

		$plugin->auth_result(0);
		$plugin->auth_message('Unknown authentication error');
		$plugin->auth_member_of([]);


		# Internal
		if ( 'INTERNAL' eq $plugin->auth_command ) {

		# We always call the internal authorization methods with the 4 arguments :
		#
		#   * username
		#   * password
		#   * groups that user should belong (as an array reference)
		#   * configuration properties of the method as defined at the config.xml
		#
		# They must return the 3 items
		#
		#  * 1 (success) or 0 (fail)
		#  * a message usually explain why the login failed
		#  * Which groups of the defined the user belongs (reference)

		my ($result, $message, $groups) = __PACKAGE__->can('__AUTH_'.$plugin->auth_method )->( $plugin->data->{user}, $plugin->data->{password}, $plugin->groups, $plugin->auth_config );
		$plugin->auth_result($result);
		$plugin->auth_message($message);
		$plugin->auth_member_of($groups) if $plugin->auth_result
		}
		

		# External script
		else {
		my $user	= unpack 'H*', $plugin->data->{user};
		my $password= unpack 'H*', $plugin->data->{password};
		my $groups	= join   ',',  @{$plugin->groups};
		my @output	= ();
		my $command	= $plugin->auth_command ." $user $password \Q$groups\E";
	
		# print STDERR "arguments after pack : $user $password $groups\ncommand              : $command\n\n";
		# Execute the external authorization utility and capture its 3 lines output at @output array
		open   SHELL, '-|', "$command 2> /dev/null" or die "Could run auth shell command \"$command\" because \"$?\"\n";
		while(<SHELL>) { s/^\s*(.*?)\s*$/$1/; push @output, $_ }
		close  SHELL;
		$plugin->auth_result( $output[0]);
		$plugin->auth_message($output[1]);
		$plugin->auth_member_of( [ split /,/, $output[2] ] ) if $plugin->auth_result
		}

			if ($plugin->auth_result) {
			$plugin->auth_message('ok') if $plugin->auth_message eq '';
			$plugin->auth_member_of(['emptylist']) unless @{ $plugin->auth_member_of }
			}
			else {
			$plugin->auth_message('Unknown authentication error') if $plugin->auth_message eq '';
			$plugin->auth_member_of([])
			}

		$plugin->error( $plugin->auth_result == 0 ? 10 : 0 );
		$plugin->errormessage( $plugin->auth_message );
		$plugin->dsl->halt( $plugin->reply('user') ) if $plugin->error;

		# User authenticated successfully, create his permanent session
		my $SessionID = ''; $SessionID .= sprintf("%08x", int rand 800_000_000) for 1..4;

			if (-e $plugin->dir_session ."/$SessionID") {
			my $i=1;
			while ( -e $plugin->dir_session ."/$i.$SessionID" ) {$i++}
			$SessionID = "$i.$SessionID"
			}

			unless (mkdir $plugin->dir_session ."/$SessionID") {
			$plugin->error(12);
			$plugin->errormessage("Login failed . Could not create session directory $SessionID because $!");
			$plugin->dsl->halt( $plugin->reply('user') )
			}

		$plugin->data->{SessionID} = $SessionID;
		$plugin->set_data_session('__clientip'=> $plugin->ClientIP, '__lastaccess'=> time, '__logintime'=> time, '__user'=> $plugin->data->{user});

		$plugin->reply(
		'IP access'			=> $plugin->data->{'IP access'},
		'user'				=> $plugin->data->{user},
		'SessionID'			=> $SessionID,
		'Max idle seconds'	=> $plugin->config->{'Session idle timout'},
		'auth_message'		=> $plugin->auth_message,
		'auth_member_of'	=> $plugin->auth_member_of )
		}

	) foreach 'get', 'post';
}





use JSON::XS;
my $obj_json = JSON::XS->new;
$obj_json->utf8(1);
$obj_json->max_depth(1024);
$obj_json->indent(1);
$obj_json->pretty(1);
$obj_json->space_before(0);
$obj_json->space_after(0);
$obj_json->max_size(0);
$obj_json->relaxed(0);
$obj_json->shrink(0);
$obj_json->allow_tags(1);
$obj_json->allow_nonref(0);
$obj_json->allow_unknown(0);
$obj_json->allow_blessed(1);
$obj_json->convert_blessed(1);

use XML::Hash::XS;
$XML::Hash::XS::root='Data';
$XML::Hash::XS::utf8=1;
$XML::Hash::XS::encoding='utf8';
$XML::Hash::XS::xml_decl=0;
$XML::Hash::XS::indent=2;
$XML::Hash::XS::canonical=1;
$XML::Hash::XS::doc=0;
$XML::Hash::XS::version='1.1';

use YAML::XS;
$YAML::XS::QuoteNumericStrings=1;

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Purity=1;
$Data::Dumper::Indent=2;
$Data::Dumper::Deepcopy=1;
$Data::Dumper::Trailingcomma=0;


#	This is my custom Perl Data Structures recursive walker
#	it is usefull when you want to view a Complex data structure at human format

my %Handler;
%Handler= (
SCALAR => sub { $Handler{WALKER}->(${$_[0]}, $_[1], @{$_[2]} )},
ARRAY  => sub { $Handler{WALKER}->($_, $_[1], @{$_[2]}) for @{$_[0]} },
HASH   => sub { $Handler{WALKER}->($_[0]->{$_}, $_[1], @{$_[2]}, $_) for sort keys %{$_[0]} },
''     => sub { $_[1]->($_[0], @{$_[2]}) },
WALKER => sub { my $data = shift; $Handler{ref $data}->($data, shift, \@_) }
);



#	Convert a string ( data_from ) to a Perl hash reference 
#	as the $obj->{from} defines : json, xml, yaml, perl, human

sub __CONVERT_STRING_TO_HASHREF
{
my $obj = $_[0];
@{$obj}{qw/error errormessage/}=(0,'ok');

	if (( ! defined $obj->{data_from} ) || ( $obj->{data_from} =~/^\s*$/ )) {
	@{$obj}{qw/error errormessage/} = (1, "There are not any data to convert at property data_from");	
	return {}
	}

my $hash={};

	eval  {
	if    ($obj->{from} eq 'json' ) {$hash = JSON::XS::decode_json   $obj->{data_from} }
	elsif ($obj->{from} eq 'xml'  ) {$hash = XML::Hash::XS::xml2hash $obj->{data_from} }
	elsif ($obj->{from} eq 'yaml' ) {$hash = YAML::XS::Load          $obj->{data_from} }
	elsif ($obj->{from} eq 'perl' ) {$hash = eval                    $obj->{data_from} }
	elsif ($obj->{from} eq 'human') {my $arrayref;

			while ( $obj->{data_from} =~/(.*)$/gm ) {
			my @array = split /\s*(?:\,| |\t|-->|==>|=>|->|=|;|\|)+\s*/, $1;
			next unless @array;

				if (@array % 2 == 0) {
				push @{$arrayref}, { @array }
				}
				else {
				push @{$arrayref}, { shift @array => [ @array ] }
				}
			}

		$hash = 1==scalar @{$arrayref} ? $arrayref->[0] : { 'Data' => $arrayref }
		}
	};

	if ($@) {
	$hash={};
	$obj->{error}=1;
	($obj->{errormessage}="The data parsing as $obj->{from} failed. Are you sure your data are at $obj->{from} format ? The low level error is : $@") =~s/[\v\h]+/ /g
	}
$hash
}


#	Convert hash reference $_[0] to text and store it at $obj->{data_to}
#	format of "data_to" is depended from "to" : json xml yaml perl human
#
#	__CONVERT_HASHREF_TO_STRING( $hash_reference )
#	print $obj->{error} ? "ERROR : $obj->{errormessage}" : $obj->{data_to};

sub __CONVERT_HASHREF_TO_STRING
{
my $obj=shift;
@{$obj}{qw/error errormessage/}=(0,'ok');
$obj->{data_to}='';

	eval {
	if    ($obj->{to} eq 'json' ) { $obj->{data_to} = $obj_json->encode($_[0]) }
	elsif ($obj->{to} eq 'xml'  ) { $obj->{data_to} = XML::Hash::XS::hash2xml $_[0] }
	elsif ($obj->{to} eq 'yaml' ) { $obj->{data_to} = YAML::XS::Dump $_[0] }
	elsif ($obj->{to} eq 'perl' ) { $obj->{data_to} = Data::Dumper::Dumper $_[0] }
	elsif ($obj->{to} eq 'human') { $Handler{WALKER}->($_[0], sub {my $val=shift; $val =~s/^\s*(.*?)\s*$/$1/; $obj->{data_to} .= join('.', @_) ." = $val\n"}) }
	};

	if ($@) {
	@{$obj}{qw/data_to error errormessage/}=('', 1, "The encoding of data hash to $obj->{to} failed. The low level error is : $@");
	$obj->{errormessage} =~s/[\v\h]+/ /g
	}

$obj->{data_to}
}


#	Returns a reply as: json, xml, yaml, perl or human
#	It always include the error and errormessage
#
#	reply						error and errormessage
#	reply(k1 => 'v1', ...)		specific keys , values
#	reply('SEND_DATA')			send data

sub reply :PluginKeyword
{
my $plugin = shift;

	if (@_) {

		if (1 == @_) {

			if ('SEND_DATA' eq $_[0]) {
			$plugin->dump_user_properties($_[0])
			}
			else {
			$plugin->dump_user_properties({error=>$plugin->error, errormessage=>$plugin->errormessage, $_[0]=> exists $plugin->data->{$_[0]} ? $plugin->data->{$_[0]} : 'MISSING KEY' })
			}
		}
		else {
		# This the normal operation
		$plugin->dump_user_properties( {error=> $plugin->error, errormessage=> $plugin->errormessage, @_} )
		}
	}
	else {
	# if no argument passed then we return only error, errormessage and if exists description
	$plugin->dump_user_properties({ error=>$plugin->error, errormessage=>$plugin->errormessage, exists $plugin->data->{description} ? ( 'description' , $plugin->data->{description} ) : () })
	}

	if ( $plugin->error ) {
	$plugin->to('json');
	$plugin->dump_user_properties( { error=>$plugin->error, errormessage=>$plugin->errormessage, description=>'Data conversion error from '.$plugin->from.' to '.$plugin->to } );
	$plugin->data( {} );
	die "DataStructure internal error : ". $plugin->errormessage."\n" if $plugin->error;
	$plugin->dsl->halt( $plugin->data_to )
	}

$plugin->data_to
}



#	$plugin->dump_user_properties( { k1 => 'v1', ... } );	# specific key/values
#	$plugin->dump_user_properties( 'SEND_DATA'  );			# posted data
#
#	produce a string formatted as    $plugin->to(  json|yaml|xml|perl|human)
#	stored at $plugin->data_to

sub dump_user_properties
{
my $plugin = shift;

	# some
	if ('HASH' eq ref $_[0]) {
	$plugin->__CONVERT_HASHREF_TO_STRING($_[0]);
	}

	# all
	elsif ('SEND_DATA' eq $_[0]) {

		if ($plugin->from eq $plugin->to) {
		$_= $plugin->data_from;
		s/^\s*(.*?)\s*$/$1/s;
		$plugin->data_to($_)
		}
		else {
		my $hash=
		$plugin->__CONVERT_STRING_TO_HASHREF;	# $plugin->data_from string to hash
		$plugin->__CONVERT_HASHREF_TO_STRING($hash)
		}
	}

$plugin->data_to
}



#	Create nested directories like the  mdkir -p ...

sub __MKDIR {
my @Mkdir = split /(?:\\|\/)+/, $_[0];
return $_[0] unless @Mkdir;
splice(@Mkdir, 0, 2, "/$Mkdir[1]") if (($Mkdir[0] eq '') && (scalar @Mkdir > 0));
my $i;

	for($i=$#Mkdir; $i>=0; $i--) {
	last if -d join '/', @Mkdir[0..$i]
	}

	for(my $j=$i+1; $j<=$#Mkdir; $j++) {
	mkdir join('/', @Mkdir[0 .. $j]) or return undef
	}
$_[0]
} 


#	Delete session directory and property

sub __Delete_session {
my $plugin	= shift;
my $dir		= $plugin->dir_session.'/'.$plugin->data->{SessionID};

	if (-d $dir) {
	my $exit_code = system $plugin->rm, '--recursive', '--force', $dir;

		if ($exit_code) {
		$plugin->error(11);
		$plugin->errormessage('Could not delete session '. $plugin->data->{SessionID} ." because $!")
		}
	}
}



#	Internal authorization code : simple
#	Receive the 4 arguments
#
#		* username
#		* password
#		* groups that user should belong (as an array reference)
#		* configuration properties of the method as defined at the config.xml
#
#	And return the 3 items
#
#		* 1 (success) or 0 (fail)
#		* a message usually explain why the login failed
#		* Which groups of the defined the user belongs (reference)

sub __AUTH_simple
{
my $user   = $_[0];
my $pass   = $_[1];
my $groups = $_[2];
my $conf   = $_[3];
my $result = 0;
my $message= 'Authentication error';

	if ( exists $conf->{Users}->{$user} )
	{
		if ( $conf->{Users}->{$user} eq '<any>' )
		{
		($result, $message) = (1, 'success using global password')
		}
		elsif ( $conf->{Users}->{$user} eq $pass )
		{
		($result, $message) = (1, 'success')
		}
		elsif ( exists $conf->{Users}->{'<any>'} )
		{
			if ( $conf->{Users}->{'<any>'} eq '<any>' )
			{
			($result, $message) = (1, 'correct user and global password for global user')
			}
			elsif ( $conf->{Users}->{'<any>'} eq $pass )
			{
			($result, $message) = (1, 'correct user and password for global user')
			}
			else
			{
			($result, $message) = (0, 'wrong password for global user')
			}
		}
		else
		{
		($result, $message) = (0, 'wrong password')
		}
	}
	elsif ( exists $conf->{Users}->{'<any>'} )
	{
		if ( $conf->{Users}->{'<any>'} eq '<any>' )
		{
		($result, $message) = (1, 'success for global user and global password')
		}
		elsif ( $conf->{Users}->{'<any>'} eq $pass )
		{
		($result, $message) = (1, 'success for global user and password')
		}
		else
		{
		($result, $message) = (0, 'wrong password for global user')
		}
	}
	else
	{
	($result, $message) = (0, 'invalid user')
	}

$result,$message,$groups
}



#	Returns the posted data
#	my ($var1, $var2) = get_data_post('k1', 'k2');    # returns the selected keys
#	my %hash          = get_data_post();              # returns all data as hash

sub get_data_post :PluginKeyword
{
my $plugin=shift;

	if (@_) {
	map {exists $plugin->data->{$_} ? $plugin->data->{$_} : 'MISSING KEY'} @_
	}
	else {
	%{ $plugin->data }
	}
}


#	Check if user send a valid SessionID
#	and if its corresponded session directory exists

sub __Session_info
{
	unless (exists $_[0]->data->{SessionID}) {
	$_[0]->error(2);
	$_[0]->errormessage('You must login for using persistent session data');
	$_[0]->data->{description} = 'Get SessionID via login route';
	$_[0]->dsl->halt( $_[0]->reply )
	}

my $id  = $_[0]->data->{SessionID};
my $dir	= $_[0]->dir_session."/$id";

	unless (-d $dir) {
	$_[0]->error(3);
	$_[0]->errormessage("Invalid or expired SessionID $id");
	$_[0]->data->{description} = 'Get SessionID via login route';
	$_[0]->dsl->halt( $_[0]->reply )
	}

$id,$dir
}


#	Retrieves stored session data
#
#	my %data = get_data_session( 'k1', 'k2', ...);	# return only the selected keys
#	my %data = get_data_session();					# returs all keys

sub get_data_session :PluginKeyword
{
my $plugin		= shift;
my ($id, $dir)	= $plugin->__Session_info;
my %hash;

	if (@_) {

		foreach (@_) {

			unless (-f "$dir/$_") {
			$hash{$_} = "NOT EXISTING SESSION RECORD $_";
			next
			}

			if ( $hash{$_} = Storable::retrieve "$dir/$_" ) {
			$hash{$_} = ${ $hash{$_} } if 'SCALAR' eq ref $hash{$_}
			}
			else {
			$plugin->error(1);
			$plugin->errormessage("Could not retrieve from session $id the property $_ because $!");
			$plugin->dsl->halt( $plugin->reply('error') )
			}
		}

	@hash{@_}
	}
	else {
	opendir __SESSIONDIR, $dir;

		foreach (grep ! /^\.+$/, readdir __SESSIONDIR) {
		next if -d "$dir/$_";

			if ( $hash{$_} = Storable::retrieve "$dir/$_" ) {
			$hash{$_} = ${ $hash{$_} } if 'SCALAR' eq ref $hash{$_}
			}
			else {
			$plugin->error(1);
			$plugin->errormessage("Could not retrieve from session $id the property $_ because $!");
			$plugin->dsl->halt( $plugin->reply() )
			}
		}

	closedir __SESSIONDIR;
	%hash
	}
}




#   Set session data
#   Session data are not volatile like the user data.
#   They are persistent between requests
#
#   set_data_session(  new1 => 'foo1', new2 => 'foo2'  ); 
#   set_data_session( {new1 => 'foo1', new2 => 'foo2'} );

sub set_data_session :PluginKeyword
{
my $plugin		= shift;
my ($id, $dir)	= $plugin->__Session_info;

	if (( 1 == @_ ) && ( 'HASH' eq ref $_[0] )) {
	@_ = %{ $_[0] }
	}

	for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2)
	{	
	my $data = $_[$j];	
	$data = \ "$data" unless ref $data;

		unless ( Storable::lock_store $data, "$dir/$_[$i]" )
		{
		$plugin->error(1);
		$plugin->errormessage("Could not store at session $id the property $_[$i] because $!");
		$plugin->dsl->halt( $plugin->reply )
		}
	}
}




#	Delete session data (not sessions)
#	It never deletes the built in records : __lastaccess, __logintime, __clientip, __user
#
#		del_data_session( 'k1', 'k2', ... );    # delete only the selected keys
#		del_data_session();                     # delete all keys

sub del_data_session :PluginKeyword
{
my $plugin		= shift;
my ($id, $dir)	= $plugin->__Session_info;

	if (@_) {

		foreach (@_) {
		next if /^__logintime|__lastaccess|__user|__clientip$/;
		next unless -f "$dir/$_";
		unless (unlink "$dir/$_") { $plugin->error(5); $plugin->errormessage("Could not delete from session $id the record $_ because $!"); $plugin->dsl->halt( $plugin->reply ) }
		}
	}
	else {
	opendir __SESSIONDIR, $dir;

		foreach (grep ! /^\.+$/, readdir __SESSIONDIR) {
		next if /^__logintime|__lastaccess|__user|__clientip$/;
		next unless -f "$dir/$_";
		unless (unlink "$dir/$_") { $plugin->error(5); $plugin->errormessage("Could not delete from session $id the record $_ because $!"); $plugin->dsl->halt( $plugin->reply ) }
		}

	closedir __SESSIONDIR
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebService - Rapid creation of RESTful Web Services with sessions and persistent data

=head1 VERSION

version 3.101

=head1 SYNOPSIS

At your Application/service you can use all Dancer2 core methods

All replies have the extra keys B<error> and B<errormessage> . At success B<error> will be 0 . At fail the B<error> will be non 0 while the B<errormessage> will contain a description of the error

=head2 Route examples

using the curl as client

  curl 0:3000/info
  curl 0:3000/info/client
  curl 0:3000/info/version
  curl 0:3000/info/version?to=json
  curl 0:3000/info/version?to=yaml
  curl 0:3000/info/version?to=xml
  curl 0:3000/info/version?to=perl
  curl 0:3000/info/version?to=human

  curl 0:3000/route1
  curl 0:3000/route2
  curl -d '{"k1":"v1"}' 0:3000/route2
  curl 0:3000/route3
  curl 0:3000/error

  curl -d '{"k1":"v1", "k2":"v2"}'  0:3000/get1
  curl -d '{"k1":"v1" }'            0:3000/get2?to=human
  curl -d '{"k1":"v1", "k2":"v2"}'  0:3000/get2?to=xml

  curl -d '{"k1":"v1", "k2":"v2"}'  0:3000/mirror
  curl -d '{"k1":"v1", "k2":"v2"}' '0:3000/mirror?to=xml'
  curl -d '{"k1":"v1", "k2":"v2"}' '0:3000/mirror?to=yaml'
  curl -d '{"k1":"v1", "k2":"v2"}' '0:3000/mirror?to=perl'
  curl -d '<D><k1>v1</k1></D>'     '0:3000/mirror?from=xml;to=human'

  curl -d '{"k1":"v1", "k2":"v2"}'               0:3000/secure
  curl -d '{"user":"user2", "password":"pass2"}' 0:3000/login
  curl -d '{"SessionID":"2d85b82b158e", "k1":"v1", "k2":"v2"}' 0:3000/secure
  curl -d '{"SessionID":"2d85b82b158e"                      }' 0:3000/secure
  curl -d '{"SessionID":"2d85b82b158e"}' 0:3000/logout

=head2 Service example

implementing the above routes

  package TestService;
  use     Dancer2;
  use     Dancer2::Plugin::WebService;
  use     strict;
  use     warnings;

  any '/mirror' => sub { reply 'SEND_DATA' };
  get '/route1' => sub { reply };
  any '/route2' => sub { reply 'k1' };
  get '/route3' => sub { reply 'k1'=>'v1', 'k2'=>'v2' };

  get '/error'  => sub { reply 'k1', 'v1', 'error', '37', 'errormessage', 'fever' };

  any '/get1'   => sub { my  %all = get_data_post;
                   reply %all };

  any '/get2'   => sub { my ($v1, $v2) = get_data_post('k1', 'k2');
                   reply 'foo'=>$v1 , 'boo'=>$v2
                   };

  any '/secure' => sub {
                   my %send = get_data_post;
                              set_data_session('s1'=>'L1', 's2'=>'L2', 's3'=>['A', 'B']);
                              del_data_session('s2', 's8', 's9');
                   my %All  = get_data_session();
                   my @Some = get_data_session('s1', 's7');

                   reply( send=>{%send}, ses_all=>{%All}, s1=>$Some[0], s7=>$Some[1] )
                   };
  dance;

=head1 NAME

Dancer2::Plugin::WebService - Rapid creation of RESTful Web Services with login/logout, sessions and persistent data

=head1 VERSION

version 3.101

=head1 POLYMORPHISM

Dancer2::Plugin::WebService can handle as input or output multiple formats

  json
  xml
  yaml
  perl
  human

Define input/output format using the url parameters "to" and "from".
If missing the default is json. The "to" is the same as "from" if missing. e.g.

  curl 0:3000/SomeRoute?to=json
  curl 0:3000/SomeRoute?to=xml
  curl 0:3000/SomeRoute?to=yaml
  curl 0:3000/SomeRoute?to=perl
  curl 0:3000/SomeRoute?to=human

  curl -d '{"k1":"3", "k2":"30"}'               0:3000/SomeRoute
  curl -d '{"k1":"3", "k2":"30"}'              '0:3000/SomeRoute?to=xml'
  curl -d '{"k1":"3", "k2":"30"}'              '0:3000/SomeRoute?to=yaml'
  curl -d '{"k1":"3", "k2":"30"}'              '0:3000/SomeRoute?to=perl'
  curl -d '{"k1":"3", "k2":"30"}'              '0:3000/SomeRoute?from=json;to=human'
  curl -d '<Data><k1>3</k1><k2>30</k2></Data>' '0:3000/SomeRoute?from=xml'
  curl -d '<Data><k1>3</k1><k2>30</k2></Data>' '0:3000/SomeRoute?from=xml;to=human'
  curl -d '<Data><k1>3</k1><k2>30</k2></Data>' '0:3000/SomeRoute?from=xml;to=yaml'

=head1 ROUTES

Your routes can be either B<public> or B<private>

B<public> are the routes that anyone can use freely without B<login> , they do not support persistent data, but you can post data and access them using the B<get_data_post>

B<private> are the routes that they need user to B<login> .
At B<private> routes you can  I<read>, I<write>, I<delete>, I<update> persistent data using the 
methods B<get_data_session> , B<set_data_session> , B<del_data_session>

Persistent session data are auto deleted when you B<logout> or if your session expired.

You can flag a route as B<private> either at the I<config.yml>

  plugins:
    WebService:
      Routes:
        SomeRoute: private

or at your main script

  setting('plugins')->{'WebService'}->{'Routes'}->{'SomeRoute'} = 'private';

=head1 BUILT-IN ROUTES

There are some built in routes for your convenience.
You can use the "from" and "to" format modifiers if you want

=head2 info/version

Service information (public route)

  curl 0:3000/info/version
  curl 0:3000/info/version?to=yaml
  curl 0:3000/info/version?to=xml
  curl 0:3000/info/version?to=perl
  curl 0:3000/info/version?to=human

=head2 info/client

Client information (public route)

  curl 0:3000/info/client

=head2 info

Redirects to /info/version

=head2 login

Login for using private routes and storing persistent data. It is a public route.

  curl --data '{"user":"dancer","password":"password"}' 0:3000/login

You can control which clients are allowed to login by editing the file I<config.yml>

  plugins:
    WebService:
      Allowed hosts:

          - 127.*
          - 10.*
          - 192.168.1.23
          - 172.20.*
          - 32.??.34.4?
          - 4.?.?.??
          - ????:????:????:6d00:20c:29ff:*:ffa3
          - "*"

=head2 logout

It is private route as you can not logout without login . In order to logout you must know the SessionID . If you logout you can not use the private routes and all coresponded session data are deleted.

  curl -X GET --data '{"SessionID":"0a1ad34505076d930c3f"}'  0:3000/logout
  curl -X GET --data '{"SessionID":"0a8e4f0523dafa980ec3"}' '0:3000/logout?from=json;to=xml'

=head1 SESSIONS

The sessions auto expired after some seconds of inactivity. You can change the amount of seconds either at the I<config.yml>

  plugins:
    WebService:     
      Session idle timout : 3600

or at your main script

  setting('plugins')->{'WebService'}->{'Session idle timout'} = 3600;

You can change Session persistent data storage directory at the I<config.yml>

  plugins:
    WebService:
      Session directory : /var/lib/WebService

=head1 METHODS

=head2 reply

send the reply to the client, performing any necessary format convertions
This should be the last route's statement

  reply                           only the error and errormessage
  reply    k1 => 'v1', ...        anything you want
  reply( { k1 => 'v1', ... } )    anything you want
  reply('SEND_DATA')              data send by the user
  reply('k1')                     data send by the user only one key

=head2 get_data_post

Retrieves data user send to WebService with his client e.g curl. Use this to do something usefull with user's data.

  my ($var1, $var2) = get_data_post('k1', 'k2');      return the selected keys
  my %hash          = get_data_post();                return all data as hash

=head2 get_data_session

Retrieves session data. You have to be logged in.

  my %data = get_data_session( 'k1', 'k2', ... );     return only the selected keys
  my %data = get_data_session();                      returs all data as hash

=head2 set_data_session

Store persistent session data. Session data are not volatile like the user data between service calls. You have to be logged in

  set_data_session(   new1 => 'foo1', new2 => 'foo2'   );
  set_data_session( { new1 => 'foo1', new2 => 'foo2' } );

=head2 del_data_session

Deletes session data. You have to be logged in.

  del_data_session( 'k1', 'k2', ... );                 deletes only the selected keys
  del_data_session();                                  deletes all keys

=head1 INSTALLATION

After install I<Dancer2::Plugin::WebService> you should run it as a non privileged user e.g. I<dancer> . Be careful, non root users can not bind ports up to 1024

  getent group  dancer >/dev/null || groupadd dancer
  getent passwd dancer >/dev/null || useradd -g dancer -l -M -c "Dancer2 WebService" -s $(which nologin) dancer

  mkdir /var/lib/WebService ; chown -R dancer:dancer /var/lib/WebService
  mkdir /var/log/WebService ; chown -R dancer:dancer /var/log/WebService

If you have a firewall running you should create a rule for the listening port e.g. at Redhat

  firewall-cmd --zone=public --permanent --add-port=3000/tcp
  firewall-cmd --reload
  firewall-cmd --list-all

create your application e.g I<TestService> inside e.g. the I</opt> folder

  dancer2 gen --application TestService --directory TestService --path /opt --overwrite
  chown -R dancer:dancer /opt/TestService

If you want compressed replies edit the file
I</opt/TestService/bin/app.psgi>

  #!/usr/bin/env perl
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use TestService;
  use Plack::Builder;
  builder { enable 'Deflater'; TestService->to_app }

Edit the file
I<.../environments/production.yml>

  # logger    : file, console
  # log level : core, debug, info, warning, error

  startup_info     : 1
  show_errors      : 1
  warnings         : 1
  no_server_tokens : 0

  logger           : 'file'
  log              : 'core'
  engines:
    logger:
      file:
        log_format : '{"ts":"%{%Y-%m-%d %H:%M:%S}t","host":"%h","level":"%L","message":"%m"}'
        log_dir    : '/var/log/WebService'
        file_name  : 'TestService.log'
      console:
        log_format : '{"ts":"%{%Y-%m-%d %H:%M:%S}t","host":"%h","level":"%L","message":"%m"}'

Edit the file as needed to match your code

Notice that the firse Active authorization method will be used, also the Allowed hosts are matched from top to bottom

I</opt/TestService/config.yml>

  environment             : production
  plugins                 :
    WebService            :
      Session directory   : /var/lib/WebService
      Session idle timout : 3600
      Default format      : json
      Routes              :
        secure            : private
        mirror            : public
        route1            : public
        route2            : public
        route3            : public
        error             : public
        get1              : public
        get2              : public

      Allowed hosts:
  
        - 127.*
        - 10.*
        - 172.??.?.*
        - 192.168.1.23
        - 4.?.?.??
        - ????:????:????:6d00:20c:29ff:*:ffa3
        - "*"
  
      User must belong to one or more of the groups:
  
        - power
        - storage
        - network

    Authentication methods:

      - Name     : simple
        Active   : yes
        Command  : INTERNAL
        Users    :
          <any>  : secret4all
          user1  : <any>		
          user2  : pass2

      - Name     : Linux native users
        Active   : yes
        Command  : MODULE_INSTALL_DIR/scripts/LinuxOS/AuthUser.pl
        Use sudo : yes

      - Name     : Basic Apache auth for simple users
        Active   : no
        Command  : MODULE_INSTALL_DIR/scripts/HttpBasic/users.pl
        Use sudo : no

      - Name     : Basic Apache auth for admins
        Active   : no
        Command  : MODULE_INSTALL_DIR/scripts/HttpBasic/admins.pl
        Use sudo : no

Write your code e.g at the file
I</opt/TestService/lib/TestService.pm>

Check the example at the the start of this page

Start the service as user I<dancer> listening at port e.g I<3000> and I<10> threads

  sudo -u dancer /usr/local/bin/plackup --host 0.0.0.0 --port 3000 --server Starman --workers=10 --env production -a /opt/TestService/bin/app.psgi

or during development

  sudo -u dancer /usr/local/bin/plackup --host 0.0.0.0 --port 3000 --server Starman --workers=1 --env production --Reload /opt/Dancer2-Plugin-WebService/lib/Dancer2/Plugin,/opt/TestService/lib,/opt/TestService/config.yml,/opt/TestService/environments -a /opt/TestService/bin/app.psgi
  sudo -u dancer /usr/local/bin/plackup --host 0.0.0.0 --port 3000 -a /opt/TestService/bin/app.psgi

or without Plack

  sudo -u dancer  perl /opt/TestService/bin/app.psgi

if you want to install your WebService application as Linux service please readme the INSTALL

=head1 AUTHENTICATION

For using B<private> methods and persistent session data you have to login. B<login> is handled from internal or external authentication methods. The external are using custom scripts/programs.
The available authentication methods are defined at your config.xml
Only the first Active Authentication method will be used.
The external scripts must be executable from the user running the service.

It is very easy to write a custom script and have any authentication you want. For writing your own scripts please read the AUTHENTICATION_SCRIPTS and review the existing scripts

If your authentication method needs sudo, you must add the user running the WebService ( I<dancer> ) on a sudoers file e.g.

  vi /etc/sudoers.d/WebService

    dancer ALL=NOPASSWD: /usr/local/share/perl5/Dancer2/Plugin/scripts/LinuxOS/AuthUser.pl

Lets view as an example the native Linux mechanism. We have

      User must belong to one or more of the groups:

        - powerusers
        - postfix
        - tape

      Authentication methods:

        - Name     : Linux native users
          Active   : yes
          Command  : MODULE_INSTALL_DIR/scripts/LinuxOS/AuthUser.pl
          Use sudo : yes

        ...

That means that if a user do not belong to any of the groups I<powerusers, postfix, tape> the login will fail. Also because this work only with root priviliges we have I<Use sudo : yes>

There are also built in authentication methods that do not need external scripts.

For example the B<simple> method define the users and their passwords directly the B<config.yml> file. It can be configured like 

        - Name     : simple
          Active   : yes
          Command  : INTERNAL
          Users    :
            <any>  : secret4all
            user1  : <any>		
            user2  : pass2

The <any> means ... any ! So if you want to allow logins no matter the username or the password you could have, write

            <any>  : <any>

This make sense if you want to give anyone the ability for persistent data

=head1 SEE ALSO

B<Plack::Middleware::REST> Route PSGI requests for RESTful web applications

B<Dancer2::Plugin::REST> A plugin for writing RESTful apps with Dancer2

B<RPC::pServer> Perl extension for writing pRPC servers

B<RPC::Any> A simple, unified interface to XML-RPC and JSON-RPC

B<XML::RPC> Pure Perl implementation for an XML-RPC client and server.

B<JSON::RPC> JSON RPC 2.0 Server Implementation 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George Bouras

It is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
