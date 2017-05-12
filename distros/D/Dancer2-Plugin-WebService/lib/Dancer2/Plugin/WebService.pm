# ABSTRACT: Rapid creation of RESTful Web Services with sessions and persistent data
# Provides Routes for authentication, persistent session data
# It can handle the formats : JSON , XML , YAML, PERL , HUMAN
#
# The subroutines of INTERNAL authorization methods must be named as __AUTH_SomeName
# where SomeName is what you have write at the config.yml   e.g.     __AUTH_simple
#
# Quick diffences between plugin and Dancer2 core
#
#   main                             plugin                        
#   -----------------------------------------------------------
#   DancerMethod                     $plugin->app->DancerMethod    
#   setting('Key') or config->{Key}  $plugin->config->{key} ,  $plugin->app->{name}
#
#   Change rw property        : $plugin->SomeProperty('new value');
#   change setting (two ways) : $plugin->{app}->{config}->{plugins}->{WebService}->{SomeSetting}->{$_}->{Active} = 'foo';
#                               $plugin->config->{SomeSetting}->{$_}->{Active} = 'foo';
#
# George Bouras, george.mpouras@yandex.com
# 25 Sep 2016, Athens - Greece


package Dancer2::Plugin::WebService;
use	Dancer2::Plugin;
use	Storable;
use	strict;
use	warnings;
our	$VERSION = '3.014';

if ($^O =~ /(?i)MSWin/) {warn "Sorry windows operating system is not supported\n"; exit 1}

# Make available the following functions to applications
plugin_keywords qw/

	get_data_user
	set_data_user
	del_data_user
	get_data_session
	set_data_session
	del_data_session
	RestReply
/;


has dir_root            => (is=>'ro', default=> sub{ ($_=$_[0]->{app}->{config}->{appdir}) =~s/\/*$//; if (-d $_) { $_ } else { warn "Could not define root directory\n"; exit 1 }});
has formats             => (is=>'ro', default=> sub{{ json => 'application/json', xml => 'text/xml', yaml => 'text/x-yaml', perl => 'text/html', human => 'text/html' }});
has formats_regex       => (is=>'ro', default=> sub{ $_=join '|', sort keys %{ $_[0]->formats }; $_ = qr/^($_)$/; $_ });
has ClientIP            => (is=>'rw', default=> '');
has route_name          => (is=>'rw', default=> '');
has error               => (is=>'rw', default=> 0);
has errormessage        => (is=>'rw', default=> 'ok');
has data_from           => (is=>'rw', default=> '');		# string of user data
has data_to             => (is=>'rw', default=> '');		# string of user data rebuilded
has data_user           => (is=>'rw', default=> sub{ {} });	# hash   of user data, send to us at "data_from"
has auth_method         => (is=>'rw', default=> '');
has auth_command        => (is=>'rw', default=> '');
has auth_member_of      => (is=>'rw', default=> sub{ [] });
has auth_result         => (is=>'rw', default=> 0);
has auth_message        => (is=>'rw', default=> '');
has sudo                => (is=>'ro', from_config=>'Command sudo',       default=> sub{'/usr/bin/sudo'});
has rm                  => (is=>'ro', from_config=>'Command rm',         default=> sub{'/usr/bin/rm'});
has rules               => (is=>'ro', from_config=>'Allowed hosts',      default=> sub{ ['127.*', '192.168.*', '10.*', '172.16.*'] });
has Session_idle_timout => (is=>'ro', from_config=>'Session idle timout',default=> sub{ 3600 });
has from                => (is=>'rw', from_config=>'Default format',     default=> sub{'json'});
has to                  => (is=>'rw', default=> sub{ $_[0]->from });
has rules_compiled      => (is=>'ro', default=> sub {my $array = [@{$_[0]->rules}]; for (@{$array}) { s/([^?*]+)/\Q$1\E/g; s|\?|.|g; s|\*+|.*?|g; $_ = qr/^$_$/i } $array});
has dir_session         => (is=>'ro', default=> sub {$_ = exists $_[0]->{app}->{config}->{plugins}->{WebService}->{'Session directory'} ? $_[0]->{app}->{config}->{plugins}->{WebService}->{'Session directory'} : $_[0]->dir_root .'/sessions'; $_ .= "/$_[0]->{app}->{config}->{appname}" if $_ !~/$_[0]->{app}->{config}->{appname}$/; $_});
has groups              => (is=>'ro', from_config=>'User must belong to one or more of the groups', default=> sub{ [] });



sub BUILD
{
my $plugin = shift;

# Define the built in Routes
$plugin->config->{Routes}->{info}	= 'public';
$plugin->config->{Routes}->{login}	= 'public';
$plugin->config->{Routes}->{logout}	= 'private';

# Default settings
$plugin->{app}->{config}->{content_type}= 'application/json';
$plugin->{app}->{config}->{charset}	= 'utf-8'  if $plugin->{app}->{config}->{charset} eq '';
$plugin->{app}->{config}->{encoding}	//= 'UTF-8';
$plugin->{app}->{config}->{show_errors}	//= 1;
$plugin->{app}->{config}->{auto_page}	//= 0;
$plugin->{app}->{config}->{traces}	//= 0;
$plugin->{app}->{config}->{layout}	//= 'main';
$plugin->{app}->{config}->{behind_proxy}//= 0;
$plugin->{app}->{config}->{plugins}->{WebService}->{'Default format'}	//= 'json';
$plugin->{app}->{config}->{plugins}->{WebService}->{'Command sudo'}	//= '/usr/bin/sudo';
$plugin->{app}->{config}->{plugins}->{WebService}->{'Command rm'}	//= '/usr/bin/rm';
$plugin->{app}->{config}->{plugins}->{WebService}->{'Owner'}		//= 'Joe Lunchbucket';
$plugin->{app}->{config}->{plugins}->{WebService}->{'Session idle timout'}//= 3600;

__MKDIR($plugin->dir_session) or die 'Could not create the session directory '.$plugin->dir_session." because $!\n";

(my $module_dir =__FILE__) =~s/\/(?>[^\/]+)$//;
unless (-d $module_dir) {warn "Sorry could not define the Dancer2::Plugin::WebService installation directory\n"; exit 1}

print STDOUT "Application name     : $plugin->{app}->{config}->{appname}\n";
print STDOUT "Application version  : $plugin->{app}->{config}->{plugins}->{WebService}->{Version}\n";
print STDOUT 'Run as user          : ', (getpwuid($>))[0] ,"\n";
print STDOUT 'Started at           : ', scalar(localtime $^T) ,"\n";
print STDOUT "Process identifier   : $$\n";
print STDOUT "WebService version   : $VERSION\n";
print STDOUT "Module dir           : $module_dir\n";


	# do not bother with the non active authentication methods
	foreach (keys %{$plugin->config->{'Authentication methods'}}) {
	delete $plugin->config->{'Authentication methods'}->{$_} unless ( exists $plugin->config->{'Authentication methods'}->{$_}->{Active} ) && ( $plugin->config->{'Authentication methods'}->{$_}->{Active} =~/(?i)y/ )
	}

	# Use the first active authentication method
	foreach (keys %{$plugin->config->{'Authentication methods'}}) {
	$plugin->auth_method($_);
	unless (exists $plugin->config->{'Authentication methods'}->{$_}->{Command}) {warn "\nThe active Authentication method \"".$plugin->auth_method."\" does not know what to do\n"; exit 1}
	delete $plugin->config->{'Authentication methods'}->{$_}->{Active};

		# Internal
		if ( $plugin->config->{'Authentication methods'}->{$_}->{Command} =~ /(?i)^INTERNAL$/ ) {
		$plugin->config->{'Authentication methods'}->{$_}->{Command} = 'INTERNAL';
		unless ( __PACKAGE__->can("__AUTH_$_") ) { warn 'Sorry, could not found the function "'. __PACKAGE__ ."::__AUTH_$_\" for INTERNAL authorization method \"$_\"\n"; exit 1 }
		$plugin->auth_command( "__AUTH_$_" );
		print STDOUT 'Authorization method : ', $plugin->auth_method  ," (INTERNAL)\n";
		print STDOUT 'Authorization command: '. __PACKAGE__ ."::__AUTH_$_\n";		
		}

		# External script
		else {
		$plugin->config->{'Authentication methods'}->{$_}->{Command} =~s/^MODULE_INSTALL_DIR/$module_dir/;
		$plugin->auth_command( $plugin->config->{'Authentication methods'}->{$_}->{Command} );
		unless (-f $plugin->auth_command) { warn 'Sorry, could not found the external authorization utility : "'. $plugin->auth_command ."\"\n"; exit 1 }
		unless (-x $plugin->auth_command) { warn 'Sorry, the external authorization utility "'. $plugin->auth_command .'" is not executable from user '.getpwuid($>) ."\n"; exit 1 }
		my $command = $plugin->auth_command;
		$plugin->auth_command( "\Q$command\E" );
		$plugin->auth_command( $plugin->sudo .' '. $plugin->auth_command ) if $plugin->config->{'Authentication methods'}->{$_}->{'Use sudo'} =~/(?i)y/;
		print STDOUT 'Authorization method : ', $plugin->auth_method  ,"\n";
		print STDOUT 'Authorization command: ', $plugin->auth_command ,"\n";
		}	
	last
	}


#print STDERR "\n",  Data::Dumper::Dumper( $plugin->config->{'Authentication methods'} )  ,"\n\n";

# Search for stored sessions
$_ = $plugin->dir_session;
print STDOUT "Session idle time out: ". $plugin->Session_idle_timout ."\n";
print STDOUT "Session storage dir  : $_\n";
opendir __SESSIONDIR, $_ or die "Could not list session directory $_ because $!\n";

	foreach my $session (grep ! /^\.+$/, readdir __SESSIONDIR) {
	if (-f "$_/$session") {unlink "$_/$session"; next}

		if ((-f "$_/$session/__clientip") && (-f "$_/$session/__lastaccess") && (-f "$_/$session/__logintime") && (-f "$_/$session/__user")) {
		my $lastaccess = ${  Storable::retrieve  "$_/$session/__lastaccess" };

			if (time - $lastaccess > $plugin->config->{'Session idle timout'}) {
			print STDOUT "Delete expired session: $session\n";
			system $plugin->rm, '--recursive', '--force', "$_/$session"
			}
			else {
			# Session is not expired update the __lastaccess and read the rest properties
			print STDOUT "Found stored session  : $session\n";
			Storable::lock_store(\ time, "$_/$session/__lastaccess") or die "Could not store at session $session the property __lastaccess because $!\n"
			}
		}
		else {
		print STDERR "Delete corrupt session: $session\n";
		system $plugin->rm, '--recursive', '--force', "$_/$session"
		}
	}

closedir __SESSIONDIR;



	# <after hook> to reset the any posted or user data
	$plugin->app->add_hook( Dancer2::Core::Hook->new(name => 'after', code => sub { $plugin->data_user({}) }) );

	# <before hook>
	$plugin->app->add_hook( Dancer2::Core::Hook->new(name => 'before',code => sub {
	$_ = (values %{ $plugin->app->request->params('route') })[0] // '';
	$plugin->app->request->path =~/^\/*(.+?)\/*$_$/;
	$plugin->route_name($^N);

	$plugin->config->{Routes}->{ $plugin->route_name } = 'public' unless exists $plugin->config->{Routes}->{ $plugin->route_name }; # If a route is not defined at the configuration file we will considered it as public
	$plugin->from($plugin->app->request->query_parameters->{from} // $plugin->config->{'Default format'});
	$plugin->to(  $plugin->app->request->query_parameters->{to}   // $plugin->from);
	if ( $plugin->from !~ $plugin->formats_regex ) { $plugin->error(20); $plugin->errormessage('property from '.$plugin->from.' is not one of the supported : '. join(', ',keys %{$plugin->formats})); $plugin->to('json'); $plugin->app->halt( $plugin->RestReply ) }
	if ( $plugin->to   !~ $plugin->formats_regex ) { $plugin->error(21); $plugin->errormessage('property to '.  $plugin->to.  ' is not one of the supported : '. join(', ',keys %{$plugin->formats})); $plugin->to('json'); $plugin->app->halt( $plugin->RestReply ) }

	$plugin->app->request->header('Content-Type'=> $plugin->formats->{$plugin->to}); # add header
	
		# Parse user's posted/sent data
		if ( $plugin->app->request->body ) { 
		$plugin->data_from( $plugin->app->request->body );
		my $hash = $plugin->__CONVERT_STRING_TO_HASHREF;

			if ( $plugin->error ) {
			$plugin->to('json');
			$plugin->dump_user_properties( { error=>$plugin->error, errormessage=>$plugin->errormessage, description=>'Data conversion error from '.$plugin->from.' to '.$plugin->to } );
			$plugin->data_user( {} );
			die "DataStructure internal error : ". $plugin->errormessage."\n" if $plugin->error;
			$plugin->app->halt( $plugin->data_to )
			}

		$plugin->data_user($hash)
		}

	# Setup the remote IP address, even if the web service is running from a reverse proxy
	$plugin->ClientIP( defined $plugin->app->request->env->{HTTP_X_REAL_IP} ? $plugin->app->request->env->{HTTP_X_REAL_IP} : defined $plugin->app->request->address ? $plugin->app->request->address : '127.0.0.1' );

	return if 'public' eq $plugin->config->{Routes}->{ $plugin->route_name };
	# If the code gets to this line, we are sure, we are dealing with a private protected route

	# Check if the session is valid, or it is expired due to inactivity
	# If the session is not expired update the __lastaccess
	unless (exists $plugin->data_user->{SessionID}) { $plugin->error(2); $plugin->errormessage('You must login for using the private route '.$plugin->route_name); $plugin->data_user({description=>'Get SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }
	$_ = $plugin->dir_session.'/'.$plugin->data_user->{SessionID};
	unless (-d $_) { $plugin->error(3); $plugin->errormessage('invalid or expired SessionID '.$plugin->data_user->{SessionID});   $plugin->data_user({description=>'Get a valid SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }
	my $lastaccess = ${  Storable::retrieve "$_/__lastaccess"  };

		if ( time - $lastaccess > $plugin->config->{'Session idle timout'} ) {
		$plugin->error(4);
		$plugin->errormessage('Session '.$plugin->data_user->{SessionID}.' expired because its idle time '.(time - $lastaccess).' secs is more than the allowed '.$plugin->config->{'Session idle timout'}.' secs');
		system $plugin->rm, '--recursive', '--force', $_;
		$plugin->app->halt( $plugin->RestReply )
		}
		else {
		Storable::lock_store(\ time, "$_/__lastaccess")
		}
	}));




	# Built in route /info
	$plugin->app->add_route( regexp=> '/info', method=> 'get', code=> sub { $_[0]->forward('/info/version') } );

	# Built in route /info/:what
	$plugin->app->add_route(
	method => 'get',
	regexp => '/info/:what',
	code   => sub {
	my $app= shift;

		if ( $app->request->param('what') =~/(?i)v/ ) {

		$plugin->RestReply(
			Name			=> $plugin->app->{name},
			Owner			=> $plugin->{app}->{config}->{plugins}->{WebService}->{Owner},
			Os			=> eval{ local $_ = undef; local $/ = undef; open __F, -f '/etc/redhat-release' ? '/etc/redhat-release' : '/etc/issue'; if (fileno __F) { ($_= <__F>)=~s/\s*$//s; $_ = join ' ', split /\v/, $_ } close __F; $_ // $^O },
			'Service uptime secs'	=> time - $^T,
			'Server date time'	=> scalar localtime time,
			Version			=> {
				Application	=> $plugin->{app}->{config}->{plugins}->{WebService}->{Version},
				Dancer		=> $Dancer2::VERSION,
				Perl		=> $],
				'Linux kernel'	=> eval{$_ = qx/uname -r/; chomp $_; $_},
				'WebService'	=> $VERSION
				}
			)
		}
		elsif ( $app->request->param('what') =~/(?i)cl/ ) {

		$plugin->RestReply(
		'Client address'	=> $plugin->ClientIP,
		'Client port'		=> $plugin->app->request->env->{REMOTE_PORT},
		'Agent'			=> $plugin->app->request->agent,
		'Is secure'		=> $plugin->app->request->secure,
		'Protocol'		=> $plugin->app->request->protocol,
		'Http method'		=> $plugin->app->request->method,
		'Header accept'		=> $plugin->app->request->header('accept'),
		'Parameters url'	=> join(' ', $plugin->app->request->params('query')),
		'Parameters route'	=> join(' ', $plugin->app->request->params('route')),
		'Parameters body'	=> join(' ', $plugin->app->request->params('body')))
		}
		else {
		$plugin->RestReply(error=>5, errormessage=>'Not existing internal route \''.$app->request->param('what').'\' Please choose one of : version, about, client')
		} 
	} );


	# logout and delete the session	
	$plugin->app->add_route(
	method => $_,
	regexp => '/logout',
	code   => sub
		{
		my $app = shift;
		$plugin->error(0);
		$plugin->errormessage('logged out from session '. $plugin->data_user->{SessionID} );
		$plugin->__Delete_session;
		$plugin->RestReply
		}

	) foreach 'get', 'post';




	#  curl -X GET --data '{"user":"Joe", "password":"MySecret" }' 'localhost:3000/login?from=json;to=json'
	#
	#  Authenticate users using external custom scripts or commands
	#  using the appropriate shell script you can easily have your
	#  LDAP, kerberus, Active Directory, SQL, or what ever mechanism you want
	#  Feel free to write your own scripts and define them at config.yml
	#
	#  The external custom shell authorization scripts/commands receives three arguments
	#
	#	1) user (as hex string)
	#	2) password (as hex string)
	#	3) comma delimited groups that the user should belong at least to one of them
	#
	#  we convert the user, pass arguments to hex strings to avoid shell attacks.
	#  Remember at linux the maximum length of a shell command is   getconf ARG_MAX
	#
	#  The result is stored at
	#
	#	$plugin->auth_result     1 for successful login, or 0 fail
	#	$plugin->auth_message    the reason why the login was failed e.g  "user do not exist"
	#	$plugin->auth_member_of  In case of successful login, the groups that the user belongs (from the ones we have specify)
	#
	$plugin->app->add_route(
	method => $_,
	regexp => '/login',
	code   => sub
	{
	my $app = shift;

		# Check client IP address against the access rules
		$plugin->error(13);
		for (my $i=0; $i<@{ $plugin->rules_compiled }; $i++)
		{
			if ( $plugin->ClientIP =~ $plugin->rules_compiled->[$i] ) {
			$plugin->error(0);		
			$plugin->errormessage('ok');
			$plugin->data_user->{'IP access'} = 'Match client IP '. $plugin->ClientIP .' from rule '. $plugin->rules->[$i];
			last
			}
		}

		if ( $plugin->error ) {
		$plugin->errormessage('Client IP address '. $plugin->ClientIP .' is not allowed from any IP access rule');
		$plugin->app->halt( $plugin->RestReply('user') )
		}

	# Check the input parameters
	foreach ('user','password') {unless (exists $plugin->data_user->{$_}) { $plugin->error(6); $plugin->errormessage("Login failed, you did not pass the $_"); $plugin->app->halt( $plugin->RestReply ) }}
	if ( $plugin->data_user->{user} =~ /^\s*$/ ) { $plugin->error(7); $plugin->errormessage("Login failed because the user is blank");     $plugin->app->halt( $plugin->RestReply ) }
	if ( $plugin->data_user->{password} eq ''  ) { $plugin->error(8); $plugin->errormessage("Login failed because the password is blank"); $plugin->app->halt( $plugin->RestReply('user')  ) }
	if ( 0 == @{ $plugin->groups }             ) { $plugin->error(9); $plugin->errormessage("Login failed because the required group list is empty"); $plugin->app->halt( $plugin->RestReply('user') ) }

	$plugin->auth_result(0);
	$plugin->auth_message('Unknown authentication error');
	$plugin->auth_member_of([]);


		# Internal
		if ( 'INTERNAL' eq $plugin->config->{'Authentication methods'}->{ $plugin->auth_method }->{Command} ) {

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

		my ($result, $message, $groups) = __PACKAGE__->can( $plugin->auth_command )->( $plugin->data_user->{user}, $plugin->data_user->{password}, $plugin->groups, $plugin->config->{'Authentication methods'}->{ $plugin->auth_method } );
		$plugin->auth_result($result);
		$plugin->auth_message($message);
		$plugin->auth_member_of($groups) if $plugin->auth_result
		}
		

		# External script
		else {
		my $user	= unpack 'H*', $plugin->data_user->{user};
		my $password	= unpack 'H*', $plugin->data_user->{password};
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
	$plugin->app->halt( $plugin->RestReply('user') ) if $plugin->error;

	# User authenticated successfully, now we must create his permanent session
	# and store there some built in properties
	my $SessionID = ''; $SessionID .= sprintf("%08x", int rand 800_000_000) for 1..4;

		if (-e $plugin->dir_session ."/$SessionID") {
		my $i=1;
		while ( -e $plugin->dir_session ."/$i.$SessionID" ) {$i++}
		$SessionID = "$i.$SessionID"
		}

		unless (mkdir $plugin->dir_session ."/$SessionID") {
		$plugin->error(12);
		$plugin->errormessage("Login failed . Could not create session directory $SessionID because $!");
		$plugin->app->halt( $plugin->RestReply('user') )
		}
	
	$plugin->data_user->{SessionID} = $SessionID;
	$plugin->set_data_session('__clientip'=> $plugin->ClientIP, '__lastaccess'=> time, '__logintime'=> time, '__user'=> $plugin->data_user->{user});

	$plugin->RestReply(
	'IP access'		=> $plugin->data_user->{'IP access'},
	'user'			=> $plugin->data_user->{user},
	'SessionID'		=> $SessionID,
	'Max idle seconds'	=> $plugin->config->{'Session idle timout'},
	'auth_message'		=> $plugin->auth_message,
	'auth_member_of'	=> $plugin->auth_member_of )
	}

	)foreach 'get', 'post';


#print STDERR "\n*". Data::Dumper::Dumper(  $plugin )  ."*\n\n";
#print STDERR "\n*". $plugin->config->{Routes}  ."*\n\n";
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


#  This is my custom Perl Data Structures recursive walker
#  it is usefull when you want to view a Complex data structure at human format
my %Handler;
%Handler =
(
SCALAR => sub { $Handler{WALKER}->(${$_[0]}, $_[1], @{$_[2]} )},
ARRAY  => sub { $Handler{WALKER}->($_, $_[1], @{$_[2]}) for @{$_[0]} },
HASH   => sub { $Handler{WALKER}->($_[0]->{$_}, $_[1], @{$_[2]}, $_) for sort keys %{$_[0]} },
''     => sub { $_[1]->($_[0], @{$_[2]}) },
WALKER => sub { my $data = shift; $Handler{ref $data}->($data, shift, \@_) }
);






#   Convert a string ( data_from ) to a Perl hash reference 
#   as the $obj->{from} defines : json, xml, yaml, perl, human
#
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
	if    ( $obj->{from} eq 'json' ) { $hash = JSON::XS::decode_json   $obj->{data_from} }
	elsif ( $obj->{from} eq 'xml'  ) { $hash = XML::Hash::XS::xml2hash $obj->{data_from} }
	elsif ( $obj->{from} eq 'yaml' ) { $hash = YAML::XS::Load          $obj->{data_from} }
	elsif ( $obj->{from} eq 'perl' ) { $hash = eval                    $obj->{data_from} }
	elsif ( $obj->{from} eq 'human') { my $arrayref;

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



#  Convert hash reference $_[0] to text and store it at $obj->{data_to}
#  format of "data_to" is depended from "to" : json xml yaml perl human
#
#   __CONVERT_HASHREF_TO_STRING( $hash_reference )
#  print $obj->{error} ? "ERROR : $obj->{errormessage}" : $obj->{data_to};
#
sub __CONVERT_HASHREF_TO_STRING
{
my $obj=shift;
@{$obj}{qw/error errormessage/}=(0,'ok');
$obj->{data_to}='';

	eval  {	
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






#    Returns a reply as: json, xml, yaml, perl or human
#    It always include the error and errormessage
#
#    RestReply				error and errormessage
#    RestReply(k1 => 'v1', ...)		specific key/values
#    RestReply('DATA_USER_SEND')	send data
#    RestReply('DATA_USER_ALL')		send data and defined key/value by the user
#   
sub  RestReply
{
my $plugin = shift;

	if (@_) {

		if (1 == @_) {

			if (('DATA_USER_SEND' eq $_[0]) || ('DATA_USER_ALL' eq $_[0])) {			
			$plugin->dump_user_properties($_[0])
			}
			else {
			$plugin->dump_user_properties({ error=> $plugin->error, errormessage=> $plugin->errormessage, $_[0]=> exists $plugin->data_user->{$_[0]} ? $plugin->data_user->{$_[0]} : 'NOT EXISTING USER DATA' })
			}
		}
		else {
		# This the normal operation		
		$plugin->dump_user_properties( {error=> $plugin->error, errormessage=> $plugin->errormessage, @_} )
		}
	}
	else {
	# if no argument passed then we return only error, errormessage and if exists description
	$plugin->dump_user_properties({ error=>$plugin->error, errormessage=>$plugin->errormessage, exists $plugin->data_user->{description} ? ( 'description' , $plugin->data_user->{description} ) : () })
	}

	if ( $plugin->error ) {
	$plugin->to('json');
	$plugin->dump_user_properties( { error=>$plugin->error, errormessage=>$plugin->errormessage, description=>'Data conversion error from '.$plugin->from.' to '.$plugin->to } );
	$plugin->data_user( {} );
	die "DataStructure internal error : ". $plugin->errormessage."\n" if $plugin->error;
	$plugin->app->halt( $plugin->data_to )
	}

$plugin->data_to
}





#  $plugin->dump_user_properties( { k1 => 'v1', ... } );	# specific key/values
#  $plugin->dump_user_properties( 'DATA_USER_SEND'    );	# send data
#  $plugin->dump_user_properties( 'DATA_USER_ALL'     );	# send data and defined key/value by the user
#
#  Answer is a string formatted as    $plugin->to(  json|yaml|xml|perl|human)
#  and stored at  $plugin->data_to
#
sub dump_user_properties
{
my $plugin = shift;
my $hash   = {};
$plugin->data_to('');

	# specific user data
	if ('HASH' eq ref $_[0])
	{
	$plugin->__CONVERT_HASHREF_TO_STRING($_[0])
	}

	# user data (all)
	elsif ('DATA_USER_ALL' eq $_[0])
	{		
	$hash->{error}		= $plugin->error;
	$hash->{errormessage}	= $plugin->errormessage;
 	map { $hash->{$_}	= $plugin->data_user->{$_} } keys %{ $plugin->data_user };
	$plugin->__CONVERT_HASHREF_TO_STRING($hash)
	}

	# only the send data
	elsif ('DATA_USER_SEND' eq $_[0])
	{
		if ($plugin->from eq $plugin->to)
		{
		$_= $plugin->data_from;
		s/^\s*(.*?)\s*$/$1/s;
		$plugin->data_to($_)
		}
		else
		{
		$hash = $plugin->__CONVERT_STRING_TO_HASHREF;	# whatever exists in $plugin->data_from in any format make it hash
		        $plugin->__CONVERT_HASHREF_TO_STRING($hash)
		}
	}

$plugin->data_to
}


#   Create nested directories like the  mdkir -p ...
#
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


#   Delete session directory and property
#
sub __Delete_session {
my $plugin	= shift;
my $dir		= $plugin->dir_session.'/'.$plugin->data_user->{SessionID};

	if (-d $dir) {
	my $exit_code = system $plugin->rm, '--recursive', '--force', $dir;
	if ($exit_code) { $plugin->error(11); $plugin->errormessage('Could not delete session '. $plugin->data_user->{SessionID} ." because $!") }
	}
}



#   Internal authorization code : simple
#   Receive the 4 arguments
#
#   * username
#   * password
#   * groups that user should belong (as an array reference)
#   * configuration properties of the method as defined at the config.xml
#
# And return the 3 items
#
#  * 1 (success) or 0 (fail)
#  * a message usually explain why the login failed
#  * Which groups of the defined the user belongs (reference)
#
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
			($result, $message) = (0, 'correct user but wrong password for global user')
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

$result, $message, $groups
}



#   Returns the posted or sent data 
#
#   my ($var1, $var2) = get_data_user('k1', 'k2');    # returns the selected keys
#   my %hash          = get_data_user();              # returns all data as hash
#
sub get_data_user
{
my $plugin = shift;

	if (@_) {
	map {exists $plugin->data_user->{$_} ?  $plugin->data_user->{$_} : 'NOT EXISTING USER DATA'} @_
	}
	else {
	%{ $plugin->data_user }
	}
}



#   Set new user data as if they were sent or posted
#
#   set_data_user(   new1 => 'foo1', new2 => 'foo2'   );  # or
#   set_data_user( { new1 => 'foo1', new2 => 'foo2' } );
#
sub set_data_user
{
my $plugin = shift;
return unless @_;
if (( 1 == @_ ) && ( 'HASH' eq ref $_[0] )) { @_ = %{ $_[0] } }

	for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2)
	{
	$plugin->data_user->{$_[$i]} = $_[$j]
	}
}


#   Delete user data
#
#     del_data_user( 'k1', 'k2', ... );    # delete only the selected keys
#     del_data_user();                     # delete all keys
#
sub del_data_user
{
my $plugin = shift;

	if (@_) {

		foreach (@_) {
		delete $plugin->data_user->{$_} if exists $plugin->data_user->{$_}
		}
	}
	else {
	$plugin->data_user({})
	}
}



#   Retrieves stored session data
#
#   my %data = get_data_session( 'k1', 'k2', ... );    # return only the selected keys
#   my %data = get_data_session();		       # returs all keys
#
sub get_data_session
{
my $plugin = shift;
unless ( exists $plugin->data_user->{SessionID}	) { $plugin->error(2); $plugin->errormessage('You must login for using persistent session data'); $plugin->data_user({description=>'Get SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }
my $id  = $plugin->data_user->{SessionID};
my $dir	= $plugin->dir_session."/$id";
unless (-d $dir) { $plugin->error(3); $plugin->errormessage("Invalid or expired SessionID $id"); $plugin->data_user({description=>'Get a valid SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }

my %hash;

	if (@_)
	{
		foreach (@_)
		{
		if ( ! -f "$dir/$_" ) { $hash{$_} = "NOT EXISTING SESSION RECORD $_"; next }

			if ( $hash{$_} = Storable::retrieve "$dir/$_" )
			{
			$hash{$_} = ${ $hash{$_} } if 'SCALAR' eq ref $hash{$_}
			}
			else	
			{
			$plugin->error(1);
			$plugin->errormessage("Could not retrieve from session $id the property $_ because $!");
			$plugin->app->halt( $plugin->RestReply('error') )
			}
		}

	map { $hash{$_} } @_
	}
	else
	{
	opendir __SESSIONDIR, $dir;

		foreach (grep ! /^\.+$/, readdir __SESSIONDIR)
		{
		next if -d "$dir/$_";

			if ( $hash{$_} = Storable::retrieve "$dir/$_" )
			{
			$hash{$_} = ${ $hash{$_} } if 'SCALAR' eq ref $hash{$_}
			}
			else	
			{
			$plugin->error(1);
			$plugin->errormessage("Could not retrieve from session $id the property $_ because $!");
			$plugin->app->halt( $plugin->RestReply() )
			}
		}

	closedir __SESSIONDIR;
	%hash
	}
}




#   Set and store session data
#   Session data are not volatile like the user data.
#   They are persistent between requests
#
#   set_data_session(  new1 => 'foo1', new2 => 'foo2'  ); 
#   set_data_session( {new1 => 'foo1', new2 => 'foo2'} );
#
sub set_data_session
{
my $plugin = shift;
unless ( exists $plugin->data_user->{SessionID}	) { $plugin->error(2); $plugin->errormessage('You must login for using persistent session data'); $plugin->data_user({description=>'Get SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }
my $id  = $plugin->data_user->{SessionID};
my $dir	= $plugin->dir_session."/$id";
unless (-d $dir) { $plugin->error(3); $plugin->errormessage("Invalid or expired SessionID $id"); $plugin->data_user({description=>'Get a valid SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }

if (( 1 == @_ ) && ( 'HASH' eq ref $_[0] )) { @_ = %{ $_[0] } }

	for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2)
	{	
	my $data = $_[$j];	
	$data = \ "$data" unless ref $data;

		unless ( Storable::lock_store $data, "$dir/$_[$i]" )
		{
		$plugin->error(1);
		$plugin->errormessage("Could not store at session $id the property $_[$i] because $!");
		$plugin->app->halt( $plugin->RestReply )
		}
	}
}




#   Delete session data (not sessions)
#   It never deletes the built in records : __lastaccess, __logintime, __clientip, __user
#   
#     del_data_session( 'k1', 'k2', ... );    # delete only the selected keys
#     del_data_session();                     # delete all keys
#
sub del_data_session
{
my $plugin = shift;
unless (exists $plugin->data_user->{SessionID}) { $plugin->error(2); $plugin->errormessage('You must login for using persistent session data'); $plugin->data_user({description=>'Get SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }

my $dir	= $plugin->dir_session.'/'.$plugin->data_user->{SessionID};
unless (-d $dir) { $plugin->error(3); $plugin->errormessage('invalid or expired SessionID '.$plugin->data_user->{SessionID});   $plugin->data_user({description=>'Get a valid SessionID via login route'}); $plugin->app->halt( $plugin->RestReply ) }

	if (@_) {

		foreach (@_) {
		next if /^__logintime|__lastaccess|__user|__clientip$/;
		next unless -f "$dir/$_";
		unless (unlink "$dir/$_") { $plugin->error(5); $plugin->errormessage('Could not delete from session '.$plugin->data_user->{SessionID}." the record $_ because $!"); $plugin->app->halt( $plugin->RestReply ) }
		}
	}
	else {
	opendir __SESSIONDIR, $dir;

		foreach (grep ! /^\.+$/, readdir __SESSIONDIR) {
		next if /^__logintime|__lastaccess|__user|__clientip$/;
		next unless -f "$dir/$_";
		unless (unlink "$dir/$_") { $plugin->error(5); $plugin->errormessage('Could not delete from session '.$plugin->data_user->{SessionID}." the record $_ because $!"); $plugin->app->halt( $plugin->RestReply ) }
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

version 3.014

=head1 SYNOPSIS

Using I<curl> ( L<https://curl.haxx.se> ) as client. At your main script you can use all Dancer2 core methods.

All replies have the extra keys B<error> and B<errormessage> . At success B<error> will be 0 . At fail the B<error> will be non 0 while the B<errormessage> will contain a description of the error

  curl localhost:65535/info/version
  curl localhost:65535/info/version?to=yaml
  curl localhost:65535/info/version?to=perl
  curl -X GET localhost:65535/info/version?to=human

  curl localhost:65535/info/client
  curl localhost:65535/info/client?to=json
  curl localhost:65535/info/client?to=xml

  curl --data '{"k1":"v1", "k2":"v2"}'   localhost:65535/test_mirror
  curl --data '{"k1":"v1", "k2":"v2"}'  'localhost:65535/test_mirror?to=xml'
  curl --data '<D><k1>v1</k1></D>'      'localhost:65535/test_mirror?from=xml;to=human'
  curl --data '{"k1":"v1", "k2":"v2"}'   localhost:65535/test_get_one_key
  curl --data '{"k1":"3",  "k2":"5" }'   localhost:65535/test_get_data
  curl --data '{"k1":"v1", "k2":"v2"}'   localhost:65535/test_new_data

  curl --data '{"k1":"v1", "k2":"v2"}'                localhost:65535/test_session
  curl --data '{"user":"joe", "password":"password"}' localhost:65535/login
  curl --data '{"k1":"v1", "k2":"v2", "SessionID":"13d11def280e37ec2d7fbeca096e7d83"}'  localhost:65535/test_session
  curl --data '{"SessionID" : "13d11def280e37ec2d7fbeca096e7d83"}'  localhost:65535/logout

Your script (example)

  package TestService;
  use	  strict;
  use     warnings;
  use     Dancer2;
  use     Dancer2::Plugin::WebService;
  our     $VERSION = setting('plugins')->{WebService}->{Version};


  any '/test_mirror' => sub { RestReply('DATA_USER_SEND') };

  any '/test_get_one_key' => sub { RestReply('k1') };

  any '/test_get_data' => sub {
  my ($var1, $var2) = get_data_user('k1', 'k2');
  RestReply( Total => ($var1 + $var2), Thought => 'Lets add !' )
  };

  any '/test_new_data' => sub { 
  my %data = 
  set_data_user( new1 => 'N1', new2 => 'N2' );
  set_data_user( new3 => 'N3', new4 => 'N4' );
  del_data_user( 'new1' , 'new4' );
  RestReply('DATA_USER_ALL')
  };

  setting('plugins')->{'WebService'}->{'Routes'}->{'test_session'} = 'private';

  any '/test_session' => sub {
  my ($v1, $v2) = get_data_user('k1', 'k2');
	          set_data_session(s1 =>'L1', s2=>'L2', s3=>['L3a', 'L3b']);
	          del_data_session('s7', 's8');
  my @Some      = get_data_session('s1', 's2', 's3', 's7');
  my %All       = get_data_session();
  RestReply(k1=>$v1, k2=>$v2, SesData_A => $Some[2], SesData_b=> [ @Some[0..1] ], SesData_all=> { %All } )
  };

  dance;

=head1 NAME

Dancer2::Plugin::WebService - Rapid creation of RESTful Web Services with sessions and persistent data

=head1 VERSION

version 3.014

=head1 POLYMORPHISM

Dancer2::Plugin::WebService can handle as input or output multiple formats

  json
  xml
  yaml
  perl
  human

Define input/output format using the url parameters "to" and "from".
If missing the default is json. The "to" is the same as "from" if missing. e.g.

  curl localhost:65535/info/client?to=json
  curl localhost:65535/info/client?to=xml
  curl localhost:65535/info/client?to=yaml
  curl localhost:65535/info/client?to=perl
  curl localhost:65535/info/client?to=human

  curl --data '{"k1":"3", "k2":"30"}'               localhost:65535/test_get_data
  curl --data '{"k1":"3", "k2":"30"}'              'localhost:65535/test_get_data?to=xml'
  curl --data '{"k1":"3", "k2":"30"}'              'localhost:65535/test_get_data?to=yaml'
  curl --data '{"k1":"3", "k2":"30"}'              'localhost:65535/test_get_data?to=perl'
  curl --data '{"k1":"3", "k2":"30"}'              'localhost:65535/test_get_data?from=json;to=human'
  curl --data '<Data><k1>3</k1><k2>30</k2></Data>' 'localhost:65535/test_get_data?from=xml'
  curl --data '<Data><k1>3</k1><k2>30</k2></Data>' 'localhost:65535/test_get_data?from=xml;to=human'
  curl --data '<Data><k1>3</k1><k2>30</k2></Data>' 'localhost:65535/test_get_data?from=xml;to=yaml'

=head1 ROUTES

Your routes can be either B<public> or B<private>

B<public> are the routes that anyone can use freely without B<login> , they do not support persistent data, so you if you want to pass some data you must send them. 

B<private> are the routes that they need user to B<login> .
At B<private> routes you can have read/write/delete/update persistent data.
These data are automatic deleted when you B<logout>. Methods I<get_data_session , set_data_session , del_data_session> can be used only at B<private> routes

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

  curl localhost:65535/info/version
  curl localhost:65535/info/version?to=yaml
  curl localhost:65535/info/version?to=xml
  curl localhost:65535/info/version?to=perl
  curl localhost:65535/info/version?to=human

=head2 info/client

Client information (public route)

  curl localhost:65535/info/client

=head2 info

Redirects to /info/version

=head2 login

Login for using private routes and storing persistent data. It is a public route.

  curl -s --data '{"user":"joe","password":"password"}' 'http://localhost:65535/login'

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

  curl -X GET --data '{"SessionID":"0a1ad34505076d930c3f76c52645e54b"}'  localhost:65535/logout
  curl -X GET --data '{"SessionID":"0a8e4f0523dafa980ec35bcf29a5cc8c"}' 'localhost:65535/logout?from=json;to=xml'

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
      Session directory : /usr/local/sessions

=head1 METHODS

=head2 RestReply

send the reply to the client. This should be the last route's statement

  RestReply                           only the error and the errormessage
  RestReply(   k1 => 'v1', ...   )    anything you want
  RestReply( { k1 => 'v1', ... } )    anything you want
  RestReply('DATA_USER_SEND')         data send by the user
  RestReply('DATA_USER_ALL')          data send by the user with any addtions
  RestReply('k1')                     data send by the user only one key

=head2 get_data_user

Retrieves data user send to WebService with his client e.g. curl or wget . We use this to do something usefull with user's data. This is normally the method you will use more often

  my ($var1, $var2) = get_data_user('k1', 'k2');    # return the selected keys
  my %hash          = get_data_user();              # return all data as hash

=head2 set_data_user

You can define extra data. Use this instead of common $variables , @arrays , etc because they are visible to other users of the service !

  set_data_user(   new1 => 'foo1', new2 => 'foo2'   );  # or
  set_data_user( { new1 => 'foo1', new2 => 'foo2' } );

=head2 del_data_user

Deletes data, think it as the opposite of B<set_data_user>

  del_data_user( 'k1', 'k2', ... );    # delete only the selected keys
  del_data_user();                     # delete all keys

=head2 set_data_session

Store persistent session data. Session data are not volatile like the user data between service calls. You have to login prior using this method.

  set_data_session(   new1 => 'foo1', new2 => 'foo2'   );
  set_data_session( { new1 => 'foo1', new2 => 'foo2' } );

=head2 get_data_session

Retrieves session data. You have to login prior using this method.

  my %data = get_data_session( 'k1', 'k2', ... );    # return only the selected keys
  my %data = get_data_session();		     # returs all keys

=head2 del_data_session

Deletes session data. You have to login prior using this method.

  del_data_session( 'k1', 'k2', ... );   # deletes only the selected keys
  del_data_session();                    # deletes all keys

=head1 INSTALLATION

After install I<Dancer2::Plugin::WebService> create your application e.g I<TestService> using the command inside e.g. the I</opt> folder

  cd /opt
  dancer2 gen --application TestService

Assuming that you will start the service as a non privileged user e.g. I<joe>

  mkdir            /var/log/TestService
  mkdir            /usr/local/sessions
  chown -R joe:joe /opt/TestService
  chown -R joe:joe /var/log/TestService
  chown -R joe:joe /usr/local/sessions

If you want compressed replies edit the file I</opt/TestService/bin/app.psgi>

  #!/usr/bin/env perl
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use TestService;
  use Plack::Builder;
  builder { enable 'Deflater'; TestService->to_app }

Or if you have slow CPU use uncompressed replies by editing the file I</opt/TestService/bin/app.psgi>

  #!/usr/bin/env perl
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use TestService;	
  TestService->to_app;

Edit the file
I<.../environments/production.yml>

  show_errors      : 1
  startup_info     : 1
  warnings         : 1 
  no_server_tokens : 0
  log              : "core"
  logger           : "file"
  engines          :
    logger         :
      File         :
        log_dir    : "/var/log/TestService"
        file_name  : "activity.log"

Edit the file I</opt/TestService/config.yml>

  appname                 : TestService
  environment             : production
  plugins                 :
    WebService            :
      Version             : 2.0.1
      Owner               : Joe Lunchbucket, Joe.Lunchbucket@example.com
      Session directory   : /usr/local/sessions
      Session idle timout : 3600
      Default format      : json
      Command sudo        : /usr/bin/sudo
      Command rm          : /usr/bin/rm
      Routes              :
        test_mirror       : public
        test_get_one_key  : public
        test_get_data     : public
        test_new_data     : public
        test_session      : private
  
      Allowed hosts:
  
        - 127.*
        - 10.*
        - 192.168.1.23
        - 172.20.*
        - 32.??.34.4?
        - 4.?.?.??
        - ????:????:????:6d00:20c:29ff:*:ffa3
        - "*"
  
      User must belong to one or more of the groups:
  
        - power
        - storage
        - network

      Authentication methods:
        simple:
          Command  : INTERNAL
          Active   : yes
          Users    :
            <any>  : secret4all
            user1  : <any>
            user2  : pass2
            user2  : pass2
        Linux native users:
          Command  : MODULE_INSTALL_DIR/scripts/LinuxOS/AuthUser.pl
          Active   : no
          Use sudo : yes
        Basic Apache auth for simple users:
          Command  : MODULE_INSTALL_DIR/scripts/HttpBasic/users.pl
          Active   : no
          Use sudo : no
        Basic Apache auth for admins:
          Command  : MODULE_INSTALL_DIR/scripts/HttpBasic/admins.pl
          Active   : no
          Use sudo : no

Write your code at the file  I</opt/TestService/lib/TestService.pm>

e.g.

  package TestService;
  use     strict;
  use     warnings;
  use     Dancer2;
  use     Dancer2::Plugin::WebService;
  our     $VERSION = setting('plugins')->{WebService}->{Version};

  any '/test_mirror'      => sub { RestReply('DATA_USER_SEND') };
  any '/test_get_one_key' => sub { RestReply('k1') };

  any '/test_get_data'    => sub {
  my ($var1, $var2) = get_data_user('k1', 'k2');
  RestReply( Total => ($var1 + $var2), Thought => 'Lets add !' )
  };

  any '/test_new_data'    => sub { 
  my %data = 
  set_data_user( new1 => 'N1', new2 => 'N2' );
  set_data_user( new3 => 'N3', new4 => 'N4' );
  del_data_user( 'new1' , 'new4' );
  RestReply('DATA_USER_ALL')
  };

  setting('plugins')->{'WebService'}->{'Routes'}->{'test_session'} = 'private';

  any '/test_session' => sub {
  my ($v1, $v2) = get_data_user('k1', 'k2');
	          set_data_session(s1 =>'L1', s2=>'L2', s3=>['L3a', 'L3b']);
	          del_data_session('s7', 's8');
  my @Some      = get_data_session('s1', 's2', 's3', 's7');
  my %All       = get_data_session();
  RestReply(k1=>$v1, k2=>$v2, SesData_A => $Some[2], SesData_b=> [ @Some[0..1] ], SesData_all=> { %All } )
  };

  dance;

Start the service as user I<Joe> listening at port e.g I<65535> with the real IP for production and multiple threads

  sudo -u joe /usr/bin/site_perl/plackup --host 172.20.21.20 --port 65535 --server Starman --workers=10 --env production -a /opt/TestService/bin/app.psgi

or during development

  sudo -u joe /usr/bin/site_perl/plackup --port 65535 -a /opt/TestService/bin/app.psgi --Reload /opt/TestService/lib,/opt/TestService/config.yml,/usr/share/perl5/site_perl/Dancer2/Plugin
  sudo -u joe /usr/bin/site_perl/plackup --port 65535 -a /opt/TestService/bin/app.psgi

or without Plack

  sudo -u joe  perl /opt/TestService/bin/app.psgi

if you want to install your WebService application as Linux service please readme the INSTALL

=head1 AUTHENTICATION

For using B<private> methods and persistent session data you have to login. B<login> is handled from external scripts/programs.
The authentication is configured at config.xml
Only one Authentication method can ne active at any time.
The authentication scripts must be executable from the user running the service.

It is very easy to write your own scripts to have any authentication you want. For writing your own scripts please read the AUTHENTICATION_SCRIPTS and review the existing scripts

Some scripts need elevated privileges, so you must to enable sudo for them. You need also to add the the user ( I<joe> ) running the appplication and the coresponded script at the B</etc/sudoers> file e.g.

  # This is needed for the linux user authorization of the WebService
  joe ALL=NOPASSWD: /usr/local/share/perl5/Dancer2/Plugin/scripts/LinuxOS/AuthUser.pl

If you want to use a method you must set  I<Active : yes>

Lets view as an example the native Linux mechanism. We have

    User must belong to one or more of the groups:

      - power
      - storage
      - network

    Authentication methods:

      Linux native users:
        Command  : MODULE_INSTALL_DIR/scripts/LinuxOS/AuthUser.pl
        Active   : yes
        Use sudo : yes

That means that if a user do not belong to any of the groups e.g. I<power , storage , network> the login will fail. Also because this work only with root priviliges we have I<Use sudo : yes>

There are also built in authentication methods that do not need external scripts.

For example the B<simple> method define the users and their passwords directly the B<config.yml> file. It can be configured like 

    Authentication methods:
      simple:
        Command  : INTERNAL
        Active   : yes
          Users  :

            <any> : secret4all
            user1 : <any>
            user2 : pass2
            user2 : pass2

The <any> means ... any ! So if you want to use it for login no matter the username or the password you could have

    Authentication methods:
      simple:
        Command  : INTERNAL
        Active   : yes
          Users  :
            <any>: <any>

=head1 SEE ALSO

B<Plack::Middleware::REST> Route PSGI requests for RESTful web applications

B<Dancer2::Plugin::REST> A plugin for writing RESTful apps with Dancer2

B<RPC::pServer> Perl extension for writing pRPC servers

B<RPC::Any> A simple, unified interface to XML-RPC and JSON-RPC

B<XML::RPC> Pure Perl implementation for an XML-RPC client and server.

B<JSON::RPC> JSON RPC 2.0 Server Implementation 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by George Bouras

It is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

George Bouras <george.mpouras@yandex.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

=head1 AUTHOR

George Bouras <george.mpouras@yandex.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
