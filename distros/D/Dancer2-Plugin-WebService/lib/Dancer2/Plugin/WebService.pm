# ABSTRACT:RESTful Web Services with login, sessions, persistent data, multiple input/output formats, and IP access
# Multiple input/output formats : JSON , XML , YAML, PERL , HUMAN
#
# George Bouras, george.mpouras@yandex.com

package Dancer2::Plugin::WebService;
our	$VERSION = '4.1.8';
use	strict;
use	warnings;
use	Dancer2::Plugin;
use	Storable;
use	Data::Dumper;	$Data::Dumper::Sortkeys=0; $Data::Dumper::Indent=2; $Data::Dumper::Purity=1; $Data::Dumper::Terse=1; $Data::Dumper::Deepcopy=1; $Data::Dumper::Trailingcomma=0;
use	YAML::XS;		$YAML::XS::QuoteNumericStrings=1;
use	XML::Hash::XS;	$XML::Hash::XS::root='Data'; $XML::Hash::XS::canonical=0; $XML::Hash::XS::indent=2; $XML::Hash::XS::utf8=1; $XML::Hash::XS::encoding='utf8'; $XML::Hash::XS::xml_decl=0; $XML::Hash::XS::doc=0;
use JSON::XS;		my $JSON=JSON::XS->new; $JSON->canonical(0); $JSON->pretty(1); $JSON->indent(1); $JSON->space_before(0); $JSON->space_after(0); $JSON->max_size(0); $JSON->relaxed(0); $JSON->shrink(0); $JSON->allow_tags(1); $JSON->allow_nonref(0); $JSON->allow_unknown(0); $JSON->allow_blessed(1); $JSON->convert_blessed(1); $JSON->utf8(1); $JSON->max_depth(1024);


if ($^O=~/(?i)MSWin/) {warn "Operating system is not supported\n"; exit 1}

has error			=> (is=>'rw', lazy=>1, default=> 0);
has formats			=> (is=>'ro', lazy=>0, default=> sub{ {json=> 'application/json', xml=> 'text/xml', yaml=> 'text/x-yaml', perl=> 'text/html', human=> 'text/html'} });
has formats_regex	=> (is=>'ro', lazy=>0, default=> sub{ $_ = join '|', sort keys %{ $_[0]->formats }; $_ = qr/^($_)$/; $_ });
has Format			=> (is=>'rw', lazy=>1, default=> sub{ {from=>undef, to=>undef}} );
has sort			=> (is=>'rw', lazy=>1, default=> 0);
has pretty			=> (is=>'rw', lazy=>1, default=> 2);
has route_name		=> (is=>'rw', lazy=>1, default=> '');
has ClientIP		=> (is=>'rw', lazy=>1, default=> '');
has reply_text		=> (is=>'rw', lazy=>1, default=> '');
has auth_method		=> (is=>'rw', lazy=>1, default=> '');
has auth_command	=> (is=>'rw', lazy=>1, default=> '');
has auth_config		=> (is=>'rw', lazy=>1, default=> sub{ {} });
has data			=> (is=>'rw', lazy=>1, default=> sub{ {} });	# posted data as hash
has Session_timeout	=> (is=>'ro', lazy=>0, from_config=>'Session idle timeout',default=> sub{ 3600 }, isa => sub {unless ( $_[0]=~/^\d+$/ ) {warn "Session idle timeout \"$_[0]\" It is not a number\n"; exit 1}} );
has rules			=> (is=>'ro', lazy=>0, from_config=>'Allowed hosts',       default=> sub{ ['127.0.*', '192.168.*', '10.*', '172.16.*'] });
has rules_compiled	=> (is=>'ro', lazy=>0, default=> sub {my $array = [@{$_[0]->rules}]; for (@{$array}) { s/([^?*]+)/\Q$1\E/g; s|\?|.|g; s|\*+|.*?|g; $_ = qr/^$_$/i } $array});
has dir_session		=> (is=>'ro', lazy=>0, default=> sub {my $dir = exists $_[0]->config->{'Session directory'} ? $_[0]->config->{'Session directory'}."/$_[0]->{app}->{name}" : "$_[0]->{app}->{config}->{appdir}/session"; $dir=~s|/+|/|g; my @MD = split /(?:\\|\/)+/, $dir; my $i; for ($i=$#MD; $i>=0; $i--) { last if -d join '/', @MD[0..$i] } for (my $j=$i+1; $j<=$#MD; $j++) { unless (mkdir join '/', @MD[0 .. $j]) {warn "Could not create the session directory \"$dir\" because $!\n"; exit 1} } $dir} );
has rm				=> (is=>'ro', lazy=>0, default=> sub{for (split /:/,$ENV{PATH}) {return "$_/rm" if -f "$_/rm" && -x "$_/rm" } warn "Could not found utility rm\n"; exit 1});


# Recursive walker of custom Perl Data Structures
my %Handler; %Handler=(
SCALAR => sub { $Handler{WALKER}->(${$_[0]}, $_[1], @{$_[2]} )},
ARRAY  => sub { $Handler{WALKER}->($_, $_[1], @{$_[2]}) for @{$_[0]} },
HASH   => sub { $Handler{WALKER}->($_[0]->{$_}, $_[1], @{$_[2]}, $_) for sort keys %{$_[0]} },
''     => sub { $_[1]->($_[0], @{$_[2]}) },
WALKER => sub { my $data = shift; $Handler{ref $data}->($data, shift, \@_) }
);


my %TokenDB;


sub BUILD
{
my $plg = shift;
my $app = $plg->app;

# Security of the built-in routes
@{$plg->config->{Routes}}{qw/logout login WebService/} = qw/protected public public/;

# Default settings
$plg->config->{'Default format'}=	'json' if ((! exists $plg->config->{'Default format'}) || ($plg->config->{'Default format'} !~ $plg->formats_regex));
$app->config->{content_type}	=	$plg->formats->{ $plg->config->{'Default format'} };
$app->config->{charset}			//=	'UTF-8';
$app->config->{encoding}		//=	'UTF-8';
$app->config->{show_errors}		//=	0;

# Module directory
(my $module_dir =__FILE__) =~s|/[^/]+$||;
unless (-d $module_dir) {warn "Sorry could not find the Dancer2::Plugin::WebService installation directory\n"; exit 1}

# Use the first active authentication method

	foreach my $method (@{$plg->config->{'Authentication methods'}}) {
	next unless ((exists $method->{Active}) && ($method->{Active}=~/(?i)[y1t]/));
	$plg->auth_method( $method->{Name} );

		# If the Authorization method is an external script
		if ($plg->auth_method ne 'INTERNAL') {
		unless (exists $method->{Command}) {warn "The active Authentication method \"".$plg->auth_method."\" does not know what to do\n"; exit 1}
		$method->{Command} =~s/^MODULE_INSTALL_DIR/$module_dir/;
		unless (-f $method->{Command}) {warn "Sorry, could not found the external authorization utility $method->{Command}\n"; exit 1}
		unless (-x $method->{Command}) {warn "Sorry, the external authorization utility $method->{Command} is not executable from user ". getpwuid($>) ."\n"; exit 1}

			if ((exists $method->{'Use sudo'}) && ($method->{'Use sudo'}=~/(?i)[y1t]/)) {
			my $sudo = undef;
			for (split /:/,$ENV{PATH}) { if ((-f "$_/sudo") && -x ("$_/sudo")) { $sudo="$_/sudo"; last } }
			unless (defined $sudo) {warn "Could not found sudo command\n"; exit 1}
			$plg->auth_command( "$sudo \Q$method->{Command}\E" )
			}
			else {
			$plg->auth_command( "\Q$method->{Command}\E" )
			}
		}

	delete @{$method}{'Name','Active','Command','Use sudo'};
	$method->{Arguments} //= [];
	$plg->auth_config($method);
	last
	}

delete $plg->config->{'Authentication methods'};

# Check for an active auth method if there are protected routes

	foreach (keys %{$plg->config->{Routes}}) {
	next if $plg->config->{Routes}->{$_} =~/(?i)pub/;
	if ($plg->auth_method eq '') {warn "While there is at least one protected route ( $_ ) there is not any active authorization method\n"; exit 1}
	last
	}

print "\nApplication              : $app->{name}\n";
print "Application version      : ",(exists $app->{config}->{version} ? $app->{config}->{version} : '1.0.0')."\n";
print "WebService  version      : $Dancer2::Plugin::WebService::VERSION\n";
print "Dancer2     version      : $Dancer2::VERSION\n";
print 'Max session idle timeout : ', $plg->Session_timeout ," sec\n";
print 'Run as user              : ', (getpwuid($>))[0]     ,"\n";
print 'Session directory        : ', $plg->dir_session     ,"\n";
print 'Start time               : ', scalar localtime $^T  ,"\n";
print 'Authorization method     : ', $plg->auth_method     ,"\n";
print "Module dir               : $module_dir\n";
print "Main PID                 : $$\n\n";


# Restore the sessions, and delete the expired
opendir __SESSIONDIR, $plg->dir_session or die "Could not list session directory $plg->{dir_session} because $!\n";

	foreach my $token (grep ! /^\.+$/, readdir __SESSIONDIR) {

		if ((-f "$plg->{dir_session}/$token/control/lastaccess") && (-f "$plg->{dir_session}/$token/control/username")) {
		my $lastaccess = ${ Storable::retrieve "$plg->{dir_session}/$token/control/lastaccess" };

			if (time - $lastaccess > $plg->Session_timeout) {
			print "Delete expired session: $token\n";
			system $plg->rm, '-rf', "$plg->{dir_session}/$token"
			}
			else {
			  $TokenDB{$token}->{data} = {};
			@{$TokenDB{$token}->{control}}{qw/lastaccess username/} = ($lastaccess, ${ Storable::retrieve "$plg->{dir_session}/$token/control/username" } );
			opendir __TOKEN, "$plg->{dir_session}/$token/data" or die "Could not read session directory $plg->{dir_session}/$token/data because $!\n";

				foreach my $record (grep ! /^\.+$/, readdir __TOKEN) {
				$TokenDB{$token}->{data}->{$record} = Storable::retrieve "$plg->{dir_session}/$token/data/$record";
				$TokenDB{$token}->{data}->{$record} = ${ $TokenDB{$token}->{data}->{$record} } if 'SCALAR' eq ref $TokenDB{$token}->{data}->{$record}
				}

			close __TOKEN;
			print "Restore session : $token , having ". scalar(keys %{$TokenDB{$token}->{data}}) ." records\n";
			}
		}
		else {
		print "Delete corrupt session: $token\n";
		system $plg->rm,'-rf',"$plg->{dir_session}/$token"
		}
	}

closedir __SESSIONDIR;
#print 'debug : '. Dumper( $app )                   ;exit;
#print 'debug : '. Dumper( $plg->config->{Routes} ) ;exit;
#print 'debug : '. Dumper  \%TokenDB; exit;


# Hook, BEFORE the main app process the request

	$app->add_hook(Dancer2::Core::Hook->new(name=>'before_request', code=>sub{
	$plg->error(0);
	$plg->data({});

	# Route name
	if    ( $app->request->{route}->{regexp} =~/^\^[\/\\]+(.*?)[\/\\]+\(\?#token.*/ )	{ $plg->route_name($1) }
	elsif ( $app->request->{route}->{regexp} =~/^\^[\/\\]+(.*?)\$/ )					{ $plg->route_name($1) }
	else  { $plg->error("Could not recognize route $_"); $app->halt($plg->reply) }

	# Define the client IP address, even if the web service is running from a reverse proxy
	$plg->ClientIP( $app->request->env->{HTTP_X_REAL_IP} // $app->request->address // '127.0.0.1' );

	# format input/output

		foreach (qw/from to/) {

			if (exists $app->request->query_parameters->{$_}) {

				if ( $app->request->query_parameters->{$_} =~ $plg->formats_regex ) {
				$plg->Format->{$_} = $app->request->query_parameters->{$_}
				}
				else {
				$plg->error("Format $_ ".$app->request->query_parameters->{$_}.' is not one of the supported : '. join(', ',keys %{$plg->formats}));
				$plg->Format->{to}='json';
				$app->halt($plg->reply)
				}
			}
			else {
			$plg->Format->{$_} = $plg->config->{'Default format'}
			}
		}

	# if the output should be sorted, sort([0|1])
	$plg->{sort} = ((exists $app->request->query_parameters->{sort}) && ($app->request->query_parameters->{sort} =~/(?i)1|t|y/)) ? 1:0;

	# if the output should be human readable : pretty([0|2])
	if (exists $app->request->query_parameters->{pretty}) {

		if ($app->request->query_parameters->{pretty} =~/(?i)1|t|y/) {
		$plg->pretty(1)
		}
		else {
		$plg->pretty(0)
		}
	}
	else {
	$plg->pretty(2)
	}

	# add header
	$app->request->header('Content-Type'=> $plg->formats->{$plg->Format->{to}});

	# Convert the received data string, to hash $plg->data

		if ( $app->request->body ) { 

			eval  {
			if    ($plg->Format->{from} eq 'json')	{ $plg->data( JSON::XS::decode_json   $app->request->body ) }
			elsif ($plg->Format->{from} eq 'xml')	{ $plg->data( XML::Hash::XS::xml2hash $app->request->body ) }
			elsif ($plg->Format->{from} eq 'yaml')	{ $plg->data( YAML::XS::Load          $app->request->body ) }
			elsif ($plg->Format->{from} eq 'perl')	{ $plg->data( eval                    $app->request->body ) }
			elsif ($plg->Format->{from} eq 'human')	{

				my $arrayref;

					while ( $app->request->body =~/(.*)$/gm ) {
					my @array = split /\s*(?:\,| |\t|-->|==>|=>|->|=|;|\|)+\s*/, $1;
					next unless @array;

						if (@array % 2 == 0) {
						push @{$arrayref}, { @array }
						}
						else {
						push @{$arrayref}, { shift @array => [ @array ] }
						}
					}

				$plg->data( 1==scalar @{$arrayref} ? $arrayref->[0] : { 'Data' => $arrayref } )
				}
			};

			if ($@) {
			$@ =~s/[\s\v\h]+/ /g;
			$plg->error('Data parsing as '.$plg->Format->{from}." failed because : $@");
			$app->halt($plg->reply)
			}
		}
	}));



# Hook ONLY for the protected routes, before the main app do anything

	$app->add_hook(Dancer2::Core::Hook->new(name=>'before', code=>sub{
	return if (! exists $plg->config->{Routes}->{$plg->route_name}) || ('public' eq $plg->config->{Routes}->{$plg->route_name});

	# Halt if the session is expired, otherelse update the lastaccess

		if (exists $plg->data->{token}) {

			if (exists $TokenDB{$plg->data->{token}}) {
			my $dir	= $plg->dir_session.'/'.$plg->data->{token};

				if (time - $TokenDB{$plg->data->{token}}->{control}->{lastaccess} > $plg->Session_timeout) {
				$plg->error('Session expired because its idle time '.(time - $TokenDB{$plg->data->{token}}->{control}->{lastaccess}).' secs is more than the allowed '.$plg->Session_timeout.' secs');
				system $plg->rm,'-rf',$dir;
				delete $TokenDB{$plg->data->{token}};
				$plg->data({});	# clear user data
				$app->halt($plg->reply)
				}
				else {
				# update the lastaccess
				$TokenDB{$plg->data->{token}}->{control}->{lastaccess} = time;
				Storable::lock_store \$TokenDB{$plg->data->{token}}->{control}->{lastaccess}, "$dir/control/lastaccess"
				}
			}
			else {
			$app->halt($plg->reply('error'=>'invalid or expired token'))
			}
		}
		else {
		$app->halt($plg->reply('error' => "You must provide a token for using the protected route $plg->{route_name}"))
		}
	}));

	# Built in route /WebService list the routes
	$app->add_route(
	regexp => '/WebService',
	method => 'get',
	code   => sub {
		my $Routes = $plg->config->{Routes};
		delete @{$Routes}{qw/WebService login logout/};

			$plg->reply(
			Application	=> $_[0]->{name},
			Routes		=> {
				'Info'			=> [ qw(version client about) ],
				'WebService'	=> [ qw(login logout) ],
				'Application'	=> {
					'protected' => [ grep $Routes->{$_} eq 'protected', keys %{$Routes} ],
					'public'    => [ grep $Routes->{$_} eq 'public',    keys %{$Routes} ]
					}
				}
			)
		}
	);

	# Built in route /WebService/:what
	$app->add_route(
	regexp => '/WebService/:what?',
	method => 'get',
	code   => sub {
		my $app= shift;

			if ( $app->request->param('what') =~/(?i)v/ ) {
			$plg->reply(Perl=> $], WebService=> $VERSION, Dancer2=> $Dancer2::VERSION, Application=> (exists $app->config->{version} ? $app->config->{version} : '1.0.0')    )
			}
			elsif ( $app->request->param('what') =~/(?i)a/ ) {

				$plg->reply(
				Application			=> $app->{name},
				Os					=> eval{ local $_ = undef; local $/ = undef; open __F, -f '/etc/redhat-release' ? '/etc/redhat-release' : '/etc/issue'; if (fileno __F) { ($_= <__F>)=~s/\s*$//s; $_ = join ' ', split /v/, $_ } close __F; $_ // $^O },				
				'Service uptime'	=> time - $^T,
				Epoch				=> time,
				Server				=> { address => $app->request->env->{SERVER_NAME}, ip => $app->request->env->{SERVER_PORT} },
				'Login idle timeout'=> $plg->Session_timeout,
				'Auth method'       => $plg->auth_method
				)
			}
			elsif ( $app->request->param('what') =~/(?i)c/ ) {

				$plg->reply(
				Address				=> $plg->ClientIP,
				Port				=> $app->request->env->{REMOTE_PORT},
				Agent				=> $app->request->agent,
				Protocol			=> $app->request->protocol,
				'Is secure'			=> $app->request->secure,
				'Http method'		=> $app->request->method,
				'Header accept'		=> $app->request->header('accept'),
				'Parameters url'	=> join(' ', $app->request->params('query')),
				'Parameters route'	=> join(' ', $app->request->params('route')),
				'Parameters body'	=> join(' ', $app->request->params('body'))
				)
			}
			else {
			$plg->reply(error=>'Not existing internal route /WebService/'. $app->request->param('what') )
			}
		}
	);

	# logout and delete the session
	$app->add_route(
	regexp => '/logout',
	method => $_,
	code   => sub {

		if (exists $TokenDB{$plg->data->{token}}) {
		delete $TokenDB{$plg->data->{token}};
		system $plg->rm,'-rf',$plg->dir_session.'/'.$plg->data->{token}
		}

	$plg->data({});
	$plg->reply(error => 'You have been successfully logged out')
	}) foreach 'post','put';


	# Authentication
	$app->add_route(
	regexp => '/login',
	method => $_,
	code   => sub {
	my $app = shift;

	# Check client IP address against the access rules
	$plg->error('Client IP address '.$plg->ClientIP.' is not allowed');

		for (my $i=0; $i<@{$plg->rules_compiled}; $i++) {

			if ( $plg->ClientIP =~ $plg->rules_compiled->[$i] ) {
			#print '*Rule '.$plg->rules->[$i].' matched client IP '.$plg->ClientIP."*\n";
			$plg->error(0);
			last
			}
		}

	$app->halt($plg->reply) if $plg->error;


	# Check the input parameters
	foreach ('username','password') {unless (exists $plg->data->{$_}) { $plg->error("Login failed, you did not pass the mandatory key $_"); $app->halt($plg->reply) }}
	if ($plg->data->{username} =~/^\s*$/)	{ $plg->error('Login failed because the username is blank'); $app->halt($plg->reply) }
	if ($plg->data->{password} eq '')		{ $plg->error('Login failed because the password is blank'); $app->halt($plg->reply) }

	$plg->error('authorization error');
	my $groups=[];

		# Internal
		if ('INTERNAL' eq $plg->auth_method) {
		my $user = $plg->data->{username};
		my $conf = $plg->auth_config;

			if (exists $conf->{Accounts}->{$user}) {
			if    ($conf->{Accounts}->{$user} eq '<any>')				{$plg->error(0)} # global password
			elsif ($conf->{Accounts}->{$user} eq $plg->data->{password}){$plg->error(0)} # normal
			}

			if ($plg->error && exists $conf->{Accounts}->{'<any>'}) {
			if    ($conf->{Accounts}->{'<any>'} eq '<any>')					{$plg->error(0)} # global user and global password
			elsif ($conf->{Accounts}->{'<any>'} eq $plg->data->{password})	{$plg->error(0)} # global user and normal password
			}
		}

		# The external auth scripts expects two arguments
		#
		#	1) username as hex string (for avoiding shell attacks)
		#	2) password as hex string
		#
		# Script output must be the two lines
		#
		#	1) The error. 0 for successful login , or at fail, a descriptive short message usually for the fail reason
		#	2) In case of successful login, the groups that the user belongs (from the ones we have specify)

		else {
		my @output;
		my $command	= $plg->auth_command.' '.unpack('H*', $plg->data->{username}).' '.unpack('H*', $plg->data->{password});
		if (@{$plg->auth_config->{Arguments}}) { $command .=' '.join ' ', map { "\"$_\"" } @{$plg->auth_config->{Arguments}} }

		# Execute the external authorization utility and capture its 3 lines output at @output array
		open   SHELL, '-|', "$command 2> /dev/null" or die "Could run AuthScript \"$command\" because \"$?\"\n";
		while(<SHELL>) {s/^\s*(.*?)\s*$/$1/; push @output,$_}
		close  SHELL;

		unless (2 == scalar @output) { $plg->error('Expected 2 lines output instead of '.scalar(@output).' at auth method '.$plg->auth_method ); $app->halt($plg->reply) }
		$plg->error($output[0]);
		$app->halt($plg->reply) if $plg->error;

			if (@{$plg->auth_config->{Groups}}) {

			# There are demanded groups
			my %hash; @hash{ @{$plg->auth_config->{Groups}} }=1;
			foreach (split /,/,$output[1]) { push @{$groups}, $_ if exists $hash{$_} }

				unless (@{$groups}) {
				$plg->error('User did not belong to any of the demanded groups: '.join ',',@{$plg->auth_config->{Groups}})
				}
			}
			else {
			$groups = [split /,/,$output[1]]
			}
		}

	$app->halt($plg->reply) if $plg->error;

	# Create the token and session dir
	open  URANDOM__, '<', '/dev/urandom' or die "\nCould not read device /dev/urandom\n";
	read  URANDOM__, my $j, 10;
	close URANDOM__;
	$plg->data->{token} = time.'-'.unpack 'h*',$j;
	my $i=0;
	do { $j = sprintf $plg->data->{token}.'-%02d', $i++ } while ( -e $plg->dir_session ."/$j" );
	$plg->data->{token}=$j;

		foreach ("$plg->{dir_session}/$plg->{data}->{token}", "$plg->{dir_session}/$plg->{data}->{token}/control", "$plg->{dir_session}/$plg->{data}->{token}/data") {

			unless (mkdir $_) {
			$plg->error("Could not create session directory $_ because $!");
			$app->halt($plg->reply)
			}
		}

	  $TokenDB{$plg->data->{token}}->{data} = {};
	@{$TokenDB{$plg->data->{token}}->{control}}{qw/lastaccess username/} = (time,$plg->data->{username});

		while ( my ($k,$v) = each %{ $TokenDB{$plg->data->{token}}->{control} } ){

			unless ( Storable::lock_store \$v, "$plg->{dir_session}/$plg->{data}->{token}/control/$k" ) {
			$plg->error("Could not store session data $_[$i] because $!");
			$plg->dsl->halt(plg->reply)
			}
		}

	$plg->reply('token'=>$plg->data->{token}, 'groups'=>$groups)
	}) foreach 'post', 'put'
}



#	Convert $_[0] hash ref to sting as $plg->reply_text
#	format of "reply_text" is depended from "to" : json xml yaml perl human
#
#	$plg->__HASH_TO_STRING( $hash_reference )
#	print $plg->{error} ? $plg->{error} : $plg->{reply_text};

sub __HASH_TO_STRING
{
my $plg=shift;
$plg->reply_text('');

	eval {
	if    ($plg->Format->{to} eq 'json') {
	$JSON->pretty($plg->pretty);
	$JSON->canonical($plg->sort);
	$plg->{reply_text} = $JSON->encode($_[0])
	}
	elsif ($plg->Format->{to} eq 'xml') {
	$XML::Hash::XS::canonical=$plg->sort;
	$XML::Hash::XS::indent=$plg->pretty;
	$plg->{reply_text} = XML::Hash::XS::hash2xml $_[0]
	}
	elsif ($plg->Format->{to} eq 'perl') {
	$Data::Dumper::Indent=$plg->pretty;
	$Data::Dumper::Sortkeys=$plg->sort;
	$plg->{reply_text} = Data::Dumper::Dumper $_[0]
	}
	elsif ($plg->Format->{to} eq 'yaml')  { $plg->{reply_text} = YAML::XS::Dump $_[0] }
	elsif ($plg->Format->{to} eq 'human') { $Handler{WALKER}->($_[0], sub {my $val=shift; $val =~s/^\s*(.*?)\s*$/$1/; $plg->{reply_text} .= join('.', @_) ." = $val\n"}); $plg->{reply_text} = Encode::encode('utf8', $plg->{reply_text}) }
	};

	if ($@) {
	$@=~s/[\v\h]+/ /g;
	$plg->error("hash to string convertion failed because : $@");
	''
	}
	else {
	$plg->reply_text
	}
}



#	Returns a reply as: json, xml, yaml, perl or human
#	It always include the error
#
#	reply							error
#	reply(   k1=>'v1', ... )		specific keys , values
#	reply( { k1=>'v1', ... } )		specific keys , values
#
sub reply :PluginKeyword
{
my $plg = shift;

	if (@_) {

		if (1 == @_) {

			if ('HASH' eq ref $_[0]) {
			$plg->__HASH_TO_STRING({error=> $plg->error, %{$_[0]}} )
			}
			else {
			$plg->__HASH_TO_STRING({error=> $plg->error, $_[0]=> $plg->data->{$_[0]}})
			}
		}
		else {
		# This the normal operation		
		$plg->__HASH_TO_STRING({error=> $plg->error, @_} )
		}
	}
	else {
	# if no argument passed then we return only the error
	$plg->__HASH_TO_STRING({error=> $plg->error})
	}

	if ($plg->error) {
	$plg->__HASH_TO_STRING({error=> $plg->error});
	$plg->dsl->halt( $plg->reply_text )
	}

$plg->reply_text
}



#	posted_data();              # returns a hash with all      posted keys/values
#	posted_data('k1', 'k2');    # returns a hash with selected posted keys/values
#
sub posted_data :PluginKeyword
{
my $plg=shift;

	if (@_) {
	%{$plg->data}{@_}  # %hash{'k1','k2'} k1 v1 k2 v2 Hash Slice
	}
	else {
	%{$plg->data}
	}
}


#	Retrieves stored session data
#
#	my %data = session_get( 'k1', 'k2', ...);	# returns a hash of the selected keys
#	my %data = session_get();					# returss a hash of all the all keys

sub session_get :PluginKeyword
{
my $plg	= shift;

	unless ((exists $plg->data->{token}) && (exists $TokenDB{$plg->data->{token}})) {
	$plg->error('You need a valid token via login for using session data');
	$plg->dsl->halt($plg->reply)
	}

	if (0 == @_) {
	%{$TokenDB{$plg->data->{token}}->{data}} # all
	}
	elsif ((1 == @_)) {

		if ('ARRAY' eq ref $_[0]) {
		%{$TokenDB{$plg->data->{token}}->{data}}{@{$_[0]}} # some @{$_[0]} , hash slice as new hash
		}
		else {
		$TokenDB{$plg->data->{token}}->{data}->{$_[0]}	# one record
		}
	}
	else {
	%{$TokenDB{$plg->data->{token}}->{data}}{@_} # some @_, hash slice as new hash
	}
}


#   Set session data
#   Session data are not volatile like the user data.
#   They are persistent between requests
#
#   session_set(  new1 => 'foo1', new2 => 'foo2'  ); 
#   session_set( {new1 => 'foo1', new2 => 'foo2'} );

sub session_set :PluginKeyword
{
my $plg = shift;

	unless ((exists $plg->data->{token}) && (exists $TokenDB{$plg->data->{token}})) {
	$plg->error('You need a vaild token via login for using session data');
	$plg->dsl->halt($plg->reply)
	}

my @keys;
@_ = %{$_[0]} if (1 == @_) && ('HASH' eq ref $_[0]);

	for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {
	push @keys, $_[$i];

	$TokenDB{$plg->data->{token}}->{data}->{$_[$i]} = $_[$j];
	my $data = ref $_[$j] ? $_[$j] : \$_[$j];

		unless ( Storable::lock_store $data, "$plg->{dir_session}/$plg->{data}->{token}/data/$_[$i]" ) {
		$plg->error("Could not store session data $_[$i] because $!");
		$plg->dsl->halt(plg->reply)
		}
	}

'stored keys', \@keys
}



#	Delete session data (not sessions)
#	It never deletes the built in records : lastaccess, username`
#
#		session_del( 'k1', 'k2', ... );    # delete only the selected keys
#		session_del();                     # delete all keys
#
sub session_del :PluginKeyword
{
my $plg	= shift;

	unless ((exists $plg->data->{token}) && (exists $TokenDB{$plg->data->{token}})) {
	$plg->error('You need a vaild token via login for using session data');
	$plg->dsl->halt($plg->reply)
	}

my $dir = $plg->dir_session.'/'.$plg->data->{token};
my @keys;

	if (@_) {
	@_ = @{$_[0]} if (1 == @_) && ('ARRAY' eq ref $_[0]);

		foreach (@_) {

			if (exists $TokenDB{$plg->data->{token}}->{data}->{$_}) {
			push @keys,$_;
			delete $TokenDB{$plg->data->{token}}->{data}->{$_};
			unlink "$dir/data/$_"
			}
		}
	}
	else {
		foreach (keys %{$TokenDB{$plg->data->{token}}->{data}}) {
		push @keys,$_;
		delete $TokenDB{$plg->data->{token}}->{data}->{$_};
		unlink "$dir/data/$_"
		}
	}

'deleted keys', \@keys
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebService - RESTful Web Services with login, sessions, persistent data, multiple input/output formats, and IP access

=head1 VERSION

version 4.1.8

=head1 SYNOPSIS

The replies through this module have the extra key B<error> . At success B<error> is 0 , while at fail is the error description

=head2 Built in routes

  GET  WebService
  GET  WebService/client
  GET  WebService/about
  GET  WebService/version

=head2 Your routes

  POST AllKeys?to=yaml    posted data  {"k1":"v1"}
  POST SomeKeys?to=xml    posted data  {"k1":"v1"}
  POST login              posted data  {"username":"joe", "password":"souvlaki"}
  POST LoginNeeded_store  posted data  {"token":"2d85b82b158e", "k1":"v1", "k2":"v2"}
  POST LoginNeeded_delete posted data  {"token":"2d85b82b158e"}
  POST LoginNeeded_read   posted data  {"token":"2d85b82b158e"}
  POST logout             posted data  {"token":"2d85b82b158e"}

=head2 Code example

  package MyService;
  use     Dancer2;
  use     Dancer2::Plugin::WebService;

  post '/AllKeys'  => sub { reply   posted_data            };
  post '/SomeKeys' => sub { reply   posted_data('k1','k2') };
  get  '/data1'    => sub { reply  'k1'=>'v1', 'k2'=>'v2'  };
  get  '/data2'    => sub { reply {'k1'=>'v1', 'k2'=>'v2'} };
  any  '/data3'    => sub { my %H = posted_data('k1', 'k2');
                      reply 'foo'=> $H{k1}, 'boo'=>$H{k2}
                      };
  get  '/error'             => sub { reply 'k1', 'v1', 'error', 'oups' };
  any  '/LoginNeeded_store' => sub { reply session_set('s1'=>'sv1', 's2'=>'v1') };
  post '/LoginNeeded_delete'=> sub { reply session_del('s1', 's2') };
  any  '/LoginNeeded_read'  => sub { reply session_get('s1', 's2') };

  dance;

=head1 Control output : sort, pretty, to, from

url parameters to control the reply

I<sort> if true, the keys are returned sorted. The default is false because it is faster. Valid values are true, 1, yes, false, 0, no

I<pretty> if false, the data are returned as one line compacted. The default is true, for human readable output. Valid values are true, 1, yes, false, 0, no

I<from> , I<to> define the input/output format. You can mix input/output formats independently. Supported formats are 

  json
  xml
  yaml
  perl
  human

I<from> default is the I<config.yml> property

  plugins :
    WebService :
      Default format : json

=head2 Examples

  GET   SomeRoute?to=human&sort=true&pretty=true
  GET   SomeRoute?to=perl&sort=true&pretty=false

  POST  SomeRoute?to=xml&sort=true'    posted data  {"k1":"v1"}
  POST  SomeRoute?to=yaml'             posted data  {"k1":"v1"}
  POST  SomeRoute?to=perl'             posted data  {"k1":"v1"}
  POST  SomeRoute?from=json;to=human'  posted data  {"k1":"v1"}
  POST  SomeRoute?from=xml;to=human'   posted data  <Data><k1>v1</k1></Data>
  POST  SomeRoute?from=xml;to=yaml'    posted data  <Data><k1>v1</k1></Data>

=head1 ROUTES

Your routes can be either B<public> or B<protected>

B<public> are the routes that anyone can use without B<login> , Τhey do not support sessions / persistent data, but you can post and access data using the method B<posted_data>

B<protected> are the routes that you must provide a token, returned by the login route.
At B<protected> routes you can  I<read>, I<write>, I<delete> persistent data using the  methods B<session_get> , B<session_set> , B<session_del>

Persistent session data are auto deleted when you B<logout> or if your session expired.

You can define a route as B<protected> at the I<config.yml>

  plugins:
    WebService:
      Routes:
        SomeRoute: protected

or at your application code

  setting('plugins')->{'WebService'}->{'Routes'}->{'SomeRoute'} = 'protected';

=head1 BUILT-IN ROUTES

I<public informational routes>

You can use "to" format modifiers if you want

  GET  WebService            The available routes
  GET  WebService/about      About
  GET  WebService/version    Perl, Dancer2, WebService, apllication version
  GET  WebService/client     Your client information

=head1 LOGIN

I<public route>

Login to get a I<token> for using I<protected> routes and storing I<persistent> data

  POST login   posted data {"username":"SomeUser","password":"SomePass"}  e.g.
  curl -X POST 0/login -d '{"username":"jonathan","password":"__1453__"}'

=head1 LOGOUT

I<protected route>

If you logout your session and all your persistent data are deleted

  POST logout      posted data  {"token":"SomeToken"}  e.g
  curl -X POST 0/logout --data '{"token":"a105076d9"}'

=head1 IP ACCESS

You can control which clients IP addresses are allowed to login by editing the file I<config.yml>

The rules are checked from up to bottom until there is a match. If no rule match then the client can not login. At rules your can use the wildcard characters * ? 

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

=head1 SESSIONS

Upon successful login, client is in session until logout or get expired due to inactivity. In session you can use the session methods by providing the token you received.

=head2 Session persistent storage

You can change persistent data storage directory at the I<config.yml>

  plugins:
    WebService:
      Session directory : /var/lib/WebService

or at your main script

  setting('plugins')->{'WebService'}->{'Session directory'} = '/var/lib/WebService';

Be careful this directory must be writable from the user that is running the service

=head2 Session expiration

Sessions expired after some seconds of inactivity. You can change the amount of seconds either at the I<config.yml>

  plugins:
    WebService:     
      Session idle timeout : 3600

or at your main script

  setting('plugins')->{'WebService'}->{'Session idle timeout'} = 3600;

=head1 METHODS

WebService methods for your main Dancer2 code

=head2 reply

I<public method>

Send the reply to the client; it applies any necessary format convertions.
This should be the last route's statement

  reply                        only the error
  reply    k1 => 'v1', ...     anything you want
  reply( { k1 => 'v1', ... } ) anything you want
  reply   'k1'                 The specific key and its value of the posted data 

=head2 posted_data

I<public method>

Get the data posted by the user

  posted_data                  hash of all the posted data
  posted_data('k1', 'k2');     hash of the selected posted keys and their values

=head2 session_get

I<session method>

Read session persistent data

  my %data = session_get;                     returns a hash of all keys 
  my %data = session_get( 'k1', 'k2', ...  ); returns a hash of the selected keys
  my %data = session_get(['k1', 'k2', ... ]); returns a hash of the selected keys

=head2 session_set I<session method>

Store non volatile session persistent data;

You must pass your data as key / value pairs

  session_set(   'rec1' => 'v1', 'rec2' => 'v2', ...   );
  session_set( { 'rec1' => 'v1', 'rec2' => 'v2', ... } );

It returns a document of the stored keys, your can use the url  to=... modifier e.g.

  {
  "error" : 0,
  "stored keys" : [ "rec1", "rec2" ]
  }

=head2 session_del

I<session method>

Deletes session persistent data

  session_del;                              delete all keys
  session_del(   'rec1', 'rec2', ...   );   delete selected keys
  session_del( [ 'rec1', 'rec2', ... ] );   delete selected keys

It returns a document of the deleted keys, your can use the url  to=... modifier e.g.

  {
  "error" : 0,
  "deleted keys" : [ "rec1", "rec2" ]
  }

=head1 AUTHENTICATION

For using protected routes, you must provide a valid token received from the B<login> route.
The B<login> route is using the the first active authentication method of the I<config.yml>
Authentication method can be INTERNAL or external executable Command.

At INTERNAL you define the usernames / passwords directly at the I<config.yml> . The <any> means any username or password, 
so if you want to allow all users to login no matter the username or the password use

  <any> : <any>

This make sense if you just want to give anyone the ability for persistent data

At production enviroments, for native Linux authentication mechanism, use the Command

  MODULE_INSTALL_DIR/AuthScripts/LinuxNative.pl

If the user do not belong to any of the defined groups then the login will fail, even if the username and password are correct.

It is easy to write your own scripts for Active Directory, LDAP, facebook integration or whatever.

If the Command needs sudo, you must add the user running the WebService to sudoers

Please read the AUTHENTICATION_SCRIPTS for the details

A sample I<config.yml> is the following. 

  version                 : 2.0.0
  environment             : development
  plugins                 :
    WebService            :
      Default format      : json
      Session directory   : /var/lib/WebService
      Session idle timeout: 86400
      Routes              :
        INeedLogin_store  : protected
        INeedLogin_read   : protected
        route1            : public
        route2            : public
        mirror            : public

      Allowed hosts:
      - 127.*
      - 10.*
      - 172.16.?.*
      - 192.168.1.23
      - "????:????:????:6d00:20c:29ff:*:ffa3"
      - "*"

      Authentication methods:
      - Name      : INTERNAL
        Active    : true
        Accounts  :
          user1   : pass1
          user2   : <any>
          <any>   : Secret4All

      - Name      : Linux native users
        Active    : false
        Command   : MODULE_INSTALL_DIR/AuthScripts/LinuxNative.pl
        Arguments : [ ]
        Groups    : [root, glusterfs, ceph]
        Use sudo  : true

      - Name      : Basic Apache auth for simple users
        Active    : false
        Command   : MODULE_INSTALL_DIR/AuthScripts/HttpBasic.sh
        Arguments : [ "/etc/htpasswd" ]
        Groups    : [ ]
        Use sudo  : false

=head1 INSTALLATION

You should run your service a non privileged user e.g. I<dancer>

Create your application ( I<TestService> ) e.g. at I</opt/TestService/>

  dancer2 gen --application TestService --directory TestService --path /opt --overwrite
  chown -R dancer:dancer /opt/TestService

Write your code at the file  I</opt/TestService/lib/TestService.pm>

=head2 Configure your environment file

I</opt/TestService/environments/development.yml>

  # logger    : file, console
  # log level : core, debug, info, warning, error

  startup_info     : 1
  show_errors      : 1
  warnings         : 1
  no_server_tokens : 0
  log              : 'core'
  logger           : 'console'

  engines:
    logger:
      file:
        log_format : '{"ts":"%{%Y-%m-%d %H:%M:%S}t","host":"%h","level":"%L","message":"%m"}'
        log_dir    : '/var/log/WebService'
        file_name  : 'TestService.log'
      console:
        log_format : '{"ts":"%{%Y-%m-%d %H:%M:%S}t","host":"%h","level":"%L","message":"%m"}'

Start the service as user I<dancer>

=head2 production

  plackup --host 0.0.0.0 --port 3000 --server Starman --workers=5 --env production -a /opt/TestService/bin/app.psgi

=head2 development

  plackup --host 0.0.0.0 --port 3000 --server HTTP::Server::PSGI --env development --Reload /opt/TestService/lib/TestService.pm,/opt/TestService/config.yml -a /opt/TestService/bin/app.psgi
  plackup --host 0.0.0.0 --port 3000 -a /opt/TestService/bin/app.psgi

=head2 without Plack

  perl /opt/TestService/bin/app.psgi

view the INSTALL document for details

=head1 SEE ALSO

B<Plack::Middleware::REST> Route PSGI requests for RESTful web applications

B<Dancer2::Plugin::REST> A plugin for writing RESTful apps with Dancer2

B<RPC::pServer> Perl extension for writing pRPC servers

B<RPC::Any> A simple, unified interface to XML-RPC and JSON-RPC

B<XML::RPC> Pure Perl implementation for an XML-RPC client and server.

B<JSON::RPC> JSON RPC 2.0 Server Implementation 

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
