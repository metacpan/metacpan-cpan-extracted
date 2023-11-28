# ABSTRACT:RESTful Web Services with login, persistent data, multiple in/out formats, IP security, role based access
# Multiple input/output formats : json , xml , yaml, perl , human
#
# George Bouras , george.mpouras@yandex.com
# Joan Ntzougani, ✞

package Dancer2::Plugin::WebService;
our	$VERSION = '4.4.7';
use	strict;
use	warnings;
use Encode;
use	Dancer2::Plugin;
use	Storable;
use Cpanel::JSON::XS;
use	XML::Hash::XS; $XML::Hash::XS::canonical=0;    $XML::Hash::XS::utf8=1;  $XML::Hash::XS::doc=0;  $XML::Hash::XS::root='root'; $XML::Hash::XS::encoding='utf-8'; $XML::Hash::XS::indent=2; $XML::Hash::XS::xml_decl=0;
use YAML::XS;      # user posted yaml text -> hash
use YAML::Syck;    $YAML::Syck::ImplicitUnicode=1;  # hash -> reply yaml text
use	Data::Dumper;  $Data::Dumper::Trailingcomma=0; $Data::Dumper::Indent=2; $Data::Dumper::Terse=1; $Data::Dumper::Deepcopy=1; $Data::Dumper::Purity=1; $Data::Dumper::Sortkeys=0;

if ($^O=~/(?i)MSWin/) {warn "Operating system is not supported\n"; exit 1}

my $JSON = Cpanel::JSON::XS->new;
$JSON->space_before(0);
$JSON->canonical(0);
$JSON->allow_tags(1);
$JSON->allow_unknown(0);
$JSON->pretty(0);
$JSON->indent(0);
$JSON->space_after(1);
$JSON->max_size(0);
$JSON->relaxed(0);
$JSON->shrink(0);
$JSON->allow_nonref(0);
$JSON->allow_blessed(1);
$JSON->convert_blessed(1);
$JSON->max_depth(1024);

my $dir;
my %Handler;
my %TokenDB = ();
my %Formats = (json=>'application/json', xml=>'application/xml', yaml=>'application/yaml', perl=>'text/plain', human=>'text/plain');
my $fmt_rgx = eval 'qr/^('. join('|', sort keys %Formats) .')$/';

has error           => (is=>'rw', lazy=>1, default     => 0);
has sort            => (is=>'rw', lazy=>1, default     => 0);
has pretty          => (is=>'rw', lazy=>1, default     => 1);
has route_name      => (is=>'rw', lazy=>1, default     => '');
has ClientIP        => (is=>'rw', lazy=>1, default     => '');
has reply_text      => (is=>'rw', lazy=>1, default     => '');
has auth_method     => (is=>'rw', lazy=>1, default     => '');
has auth_command    => (is=>'rw', lazy=>1, default     => '');
has auth_config     => (is=>'rw', lazy=>1, default     => sub{ {} });
has data            => (is=>'rw', lazy=>1, default     => sub{ {} }); # user posted data as hash
has Format          => (is=>'rw', lazy=>1, default     => sub{ {from => undef, to => undef} });
has Session_timeout => (is=>'ro', lazy=>0, from_config => 'Session idle timeout',default=> sub{ 3600 }, isa => sub {unless ( $_[0]=~/^\d+$/ ) {warn "Session idle timeout \"$_[0]\" It is not a number\n"; exit 1}} );
has rules           => (is=>'ro', lazy=>0, from_config => 'Allowed hosts',       default=> sub{ ['127.*', '192.168.*', '172.16.*'] });
has rules_compiled  => (is=>'ro', lazy=>0, default     => sub {my $array = [@{$_[0]->rules}]; for (@{$array}) { s/([^?*]+)/\Q$1\E/g; s|\?|.|g; s|\*+|.*?|g; $_ = qr/^$_$/i } $array});
has dir_session     => (is=>'ro', lazy=>0, default     => sub {my $D = exists $_[0]->config->{'Session directory'} ? $_[0]->config->{'Session directory'}."/$_[0]->{app}->{name}" : "$_[0]->{app}->{config}->{appdir}/session"; $D=~s|/+|/|g; my @MD = split /(?:\\|\/)+/, $D; my $i; for ($i=$#MD; $i>=0; $i--) { last if -d join '/', @MD[0..$i] } for (my $j=$i+1; $j<=$#MD; $j++) { unless (mkdir join '/', @MD[0 .. $j]) {warn "Could not create the session directory \"$D\" because $!\n"; exit 1} } $D} );
has rm              => (is=>'ro', lazy=>0, default     => sub{foreach (qw[/usr/bin /bin /usr/sbin /sbin]) {return "$_/rm" if -f "$_/rm" && -x "$_/rm" } warn "Could not found utility rm\n"; exit 1});

# Recursive walker of complex Perl Data Structures
%Handler=(
SCALAR => sub { $Handler{WALKER}->(${$_[0]}, $_[1], @{$_[2]} )},
ARRAY  => sub { $Handler{WALKER}->($_, $_[1], @{$_[2]}) for @{$_[0]} },
HASH   => sub { $Handler{WALKER}->($_[0]->{$_}, $_[1], @{$_[2]}, $_) for sort keys %{$_[0]} },
''     => sub { $_[1]->($_[0], @{$_[2]}) },
WALKER => sub { my $data = shift; $Handler{ref $data}->($data, shift, \@_) }
);


sub BUILD
{
my $plg = shift;
my $app = $plg->app;

# Module directory
(my $module_dir =__FILE__) =~s|/[^/]+$||;
unless (-d $module_dir) {CORE::warn "Could not find the Dancer2::Plugin::WebService installation directory\n"; exit 1}

# Security of the built-in routes and default settings
$plg->config->{Routes}->{WebService} = {Protected=>0};
$plg->config->{Routes}->{login}      = {Protected=>0};
$plg->config->{Routes}->{logout}     = {Protected=>1, Groups=>[]};
$app->config->{charset}            //= 'UTF-8';
$app->config->{encoding}           //= 'UTF-8';
$app->config->{show_errors}        //= 0;
$plg->config->{'Default format'}     = 'json' if ((! exists $plg->config->{'Default format'}) || ($plg->config->{'Default format'} !~ $fmt_rgx));
$app->config->{content_type}         = $Formats{ $plg->config->{'Default format'} };

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
      foreach (qw[/usr/bin /bin /usr/sbin /sbin]) { if ((-f "$_/sudo") && -x ("$_/sudo")) { $sudo="$_/sudo"; last } }
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

  # Check the active auth method if there are protected routes
  foreach (keys %{$plg->config->{Routes}}) {

    if ((exists $plg->config->{Routes}->{$_}->{Protected}) && ($plg->config->{Routes}->{$_}->{Protected}=~/(?i)[y1t]/)) {
    delete $plg->config->{Routes}->{$_}->{Protected};
           $plg->config->{Routes}->{$_}->{Protected}=1;

      if ($plg->auth_method eq '') {
      warn "While there is at least one protected route ( $_ ) there is not any active authorization method\n"; exit 1
      }
      else {

        if (exists $plg->config->{Routes}->{$_}->{Groups}) {
        $plg->config->{Routes}->{$_}->{Groups} = [ $plg->config->{Routes}->{$_}->{Groups} ] unless 'ARRAY' eq ref $plg->config->{Routes}->{$_}->{Groups}
        }
        else {
        $plg->config->{Routes}->{$_}->{Groups} = []
        }
      }
    }
    else {
    delete $plg->config->{Routes}->{$_}->{Protected};
           $plg->config->{Routes}->{$_}->{Protected}=0
    }
  }

print 'Start time              : ', scalar localtime $^T ,"\n";
print "Main PID                : $$\n";
print 'Run as user             : ', (getpwuid($>))[0] ,"\n";
print 'Authorization method    : ', $plg->auth_method ,"\n";
print 'Session directory       : ', $plg->dir_session ,"\n";
print 'Session idle timeout    : ', $plg->Session_timeout ," sec\n";
print "Module auth dir scripts : $module_dir\n";
print "version Perl            : $^V\n";
print "version Dancer2         : $Dancer2::VERSION\n";
print "version WebService      : $VERSION\n";

# Restore the valid sessions, and delete the expired ones
opendir DIR, $plg->dir_session or die "Could not list session directory $plg->{dir_session} because $!\n";

  foreach my $token (grep ! /^\.+$/, readdir DIR) {

    if ((-f "$plg->{dir_session}/$token/control/lastaccess") && (-f "$plg->{dir_session}/$token/control/username") && (-f "$plg->{dir_session}/$token/control/groups")) {
    my $lastaccess = ${ Storable::retrieve "$plg->{dir_session}/$token/control/lastaccess" };

      if (time - $lastaccess > $plg->Session_timeout) {
      print "Delete expired session: $token\n";
      system $plg->rm, '-rf', "$plg->{dir_session}/$token"
      }
      else {
        $TokenDB{$token}->{data} = {};
      @{$TokenDB{$token}->{control}}{qw/lastaccess username groups/} = ($lastaccess, ${Storable::retrieve "$plg->{dir_session}/$token/control/username"}, ${Storable::retrieve "$plg->{dir_session}/$token/control/groups"});
      opendir __TOKEN, "$plg->{dir_session}/$token/data" or die "Could not read session directory $plg->{dir_session}/$token/data because $!\n";

				foreach my $record (grep ! /^\.+$/, readdir __TOKEN) {
				$TokenDB{$token}->{data}->{$record} = Storable::retrieve "$plg->{dir_session}/$token/data/$record";
				$TokenDB{$token}->{data}->{$record} = ${ $TokenDB{$token}->{data}->{$record} } if 'SCALAR' eq ref $TokenDB{$token}->{data}->{$record}
				}

			close __TOKEN;
			print "Restore session : $token (". scalar(keys %{$TokenDB{$token}->{data}}) ." records)\n"
			}
		}
		else {
		print "Delete corrupt session: $token\n";
		system $plg->rm,'-rf',"$plg->{dir_session}/$token"
		}
	}

closedir DIR;

#print Dumper( $app ) ;exit;
#print Dumper( $plg->config->{Routes} ) ;exit;
#print Dumper( $plg->auth_config )      ;exit;
#print Dumper  \%TokenDB; exit;
#print "---------\n*".  $plg->dir_session  ."*\n---------\n";


# Hook, BEFORE the main app process the request

  $app->add_hook(Dancer2::Core::Hook->new(name=>'before_request', code=>sub{
  $plg->error(0);
  $plg->sort(   exists $app->request->query_parameters->{sort}   ? $app->request->query_parameters->{sort}  =~/(?i)1|t|y/ ? 1:0:0);  # sort   default is 0
  $plg->pretty( exists $app->request->query_parameters->{pretty} ? $app->request->query_parameters->{pretty}=~/(?i)1|t|y/ ? 1:0:1);  # pretty default is 1
  $plg->ClientIP($app->request->env->{HTTP_X_REAL_IP} // $app->request->address // '127.0.0.1'); # Client IP address, even if running from a reverse proxy

    # format
    foreach (qw/from to/) {

      if (exists $app->request->query_parameters->{$_}) {

        if ( $app->request->query_parameters->{$_} =~ $fmt_rgx ) {
        $plg->Format->{$_} = $app->request->query_parameters->{$_}
        }
        else {
        $plg->Format->{to} = $plg->config->{'Default format'};
        $app->halt($plg->reply('error'=>"Format parameter $_ ( ".$app->request->query_parameters->{$_}.' ) is not one of the :'. join(', ',keys %Formats)))
        }
      }
      else {
      $plg->Format->{$_} = $plg->config->{'Default format'}
      }
    }

  # Header Content-Type
  $app->request->header('Content-Type'=> $Formats{$plg->Format->{to}});

  # route name
  if    ( $app->request->{route}->{regexp} =~/^\^[\/\\]+(.*?)[\/\\]+\(\?#token.*/ ) { $plg->route_name($1) }
  elsif ( $app->request->{route}->{regexp} =~/^\^[\/\\]+(.*?)\$/ )                  { $plg->route_name($1) }
  else  { $app->halt($plg->reply('error'=>'Could not recognize the route')) }

  # Convert the posted data string, to hash $plg->data
  $plg->data({});

    if ($app->request->body) {

      eval  {

      if    ($plg->Format->{from} eq 'json')  { $JSON->utf8(1); $plg->data( $JSON->decode($app->request->body)         ) }
      elsif ($plg->Format->{from} eq 'xml')   {                 $plg->data( XML::Hash::XS::xml2hash $app->request->body) }
      elsif ($plg->Format->{from} eq 'yaml')  {                 $plg->data( YAML::XS::Load          $app->request->body) }
      elsif ($plg->Format->{from} eq 'perl')  {                 $plg->data( eval                    $app->request->body) }
      elsif ($plg->Format->{from} eq 'human') { my $ref={};

          foreach (split /\v+/, $app->request->body) {
          my @array = split /\s*(?:=|\:|-->|->|\|)+\s*/, $_;
          next unless @array;

            if ($#array==0) {
            $ref->{data}->{default} = $array[0]
            }
            else {
            $ref->{data}->{$array[0]} = join ',', @array[1 .. $#array]
            }
          }

        $plg->data( $ref )
        }
      };

			if ($@) {
			$@ =~s/[\s\v\h]+/ /g;
			$app->halt($plg->reply('error'=>'Data parsing as '.$plg->Format->{from}." failed because $@"))
			}
		}

    # Do not proceed if the posted data are not hash
    if ('HASH' ne ref $plg->{data}) {

      if ('ARRAY' eq ref $plg->{data}) {
      $plg->{data} = { data => $plg->{data} }
      }
      else {
      $app->halt($plg->reply('error'=>'Posted data are not keys or list'))
      }
    }

    # Delete not needed control url parameters
    foreach (qw/from to sort pretty message/) {
    delete $app->request->query_parameters->{$_}
    }

    # Use as data any url parameter
    foreach (keys %{$app->request->query_parameters}) {
    $plg->data->{$_} = $app->request->query_parameters->{$_}
    }

  }));


# Hook ONLY for the protected routes, before the main app do anything
# halt if the session is expired, otherelse update the lastaccess

  $app->add_hook(Dancer2::Core::Hook->new(name=>'before', code=>sub{
  return unless (exists $plg->config->{Routes}->{$plg->route_name}) && $plg->config->{Routes}->{$plg->route_name}->{Protected};

  $app->halt($plg->reply('error' => "You must provide a token to use the protected route $plg->{route_name}")) unless exists $plg->data->{token};
  $app->halt($plg->reply('error' => 'Invalid token')) unless exists $TokenDB{$plg->data->{token}};
  $dir = $plg->dir_session.'/'.$plg->data->{token};

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

	# Check if the user is member to all the Groups of the route

    foreach (@{$plg->config->{Routes}->{$plg->route_name}->{Groups}}) {

      unless (exists $TokenDB{$plg->data->{token}}->{control}->{groups}->{$_} ) {
      $app->halt($plg->reply('error'=>'Required route groups are '. join(',',@{$plg->config->{Routes}->{$plg->route_name}->{Groups}}) .' your groups are '. join(',', sort keys %{$TokenDB{$plg->data->{token}}->{control}->{groups}})))
      }
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
			Routes=>{
				'Built in'		=> [ map {$_} qw(WebService WebService/version WebService/client WebService/about login logout) ],
				'Application'	=> {
					'Protected' => [ map {$_} grep   $Routes->{$_}->{Protected}, sort keys %{$Routes} ],
					'Public'    => [ map {$_} grep ! $Routes->{$_}->{Protected}, sort keys %{$Routes} ]
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
      $plg->reply(Perl=> $], WebService=> $VERSION, Dancer2=> $Dancer2::VERSION)
      }
      elsif ( $app->request->param('what') =~/(?i)a/ ) {

        $plg->reply(
        Application         => $app->{name},
        Os                  => eval{ local $_ = undef; local $/ = undef; open __F, -f '/etc/redhat-release' ? '/etc/redhat-release' : '/etc/issue'; if (fileno __F) { ($_= <__F>)=~s/\s*$//s; $_ = join ' ', split /v/, $_ } close __F; $_ // $^O },
        'Server bind'       => $app->request->env->{SERVER_NAME},
        'Server port'       => $app->request->env->{SERVER_PORT},
        'Service uptime'    => time - $^T,
        'Login idle timeout'=> $plg->Session_timeout,
        'Auth method'       => $plg->auth_method
        )
      }
      elsif ( $app->request->param('what') =~/(?i)c/ ) {

        $plg->reply(
        Address           => $plg->ClientIP,
        Port              => $app->request->env->{REMOTE_PORT},
        Agent             => $app->request->agent,
        Protocol          => $app->request->protocol,
        'Is secure'       => $app->request->secure,
        'Http method'     => $app->request->method,
        'Header accept'   => $app->request->header('accept'),
        'Parameters url'  => join(' ', $app->request->params('query')),
        'Parameters route'=> join(' ', $app->request->params('route')),
        'Parameters body' => join(' ', $app->request->params('body'))
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
  $plg->reply()
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
			$plg->error(0);
			last
			}
		}

	$app->halt($plg->reply) if $plg->error;


	# Check the input parameters
	foreach ('username','password') {unless (exists $plg->data->{$_}) { $plg->error("Login failed, you did not pass the mandatory key $_"); $app->halt($plg->reply) }}
	if ($plg->data->{username} =~/^\s*$/) { $plg->error('Login failed because the username is blank'); $app->halt($plg->reply) }
	if ($plg->data->{password} eq '')     { $plg->error('Login failed because the password is blank'); $app->halt($plg->reply) }

	$plg->error('authorization error');
	my $groups={};

		# Internal
		if ('INTERNAL' eq $plg->auth_method) {
		my $user = $plg->data->{username};
		my $conf = $plg->auth_config;

			if (exists $conf->{Accounts}->{$user}) {
			if    ($conf->{Accounts}->{$user} eq '<any>') {$plg->error(0)} # global password
			elsif ($conf->{Accounts}->{$user} eq $plg->data->{password}) {$plg->error(0)} # normal
			}

			if ($plg->error && exists $conf->{Accounts}->{'<any>'}) {
			if    ($conf->{Accounts}->{'<any>'} eq '<any>')					{$plg->error(0)} # global user and global password
			elsif ($conf->{Accounts}->{'<any>'} eq $plg->data->{password})	{$plg->error(0)} # global user and normal password
			}
		}

		# The external auth scripts expect at least the two arguments
		#
		#	1) username as hex string (for avoiding shell attacks)
		#	2) password as hex string
		#
		# Script output must be the two lines
		#
		#	1) 0 for successful login , or the error message at fail
		#	2) All the groups that the user belongs

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
		map { $groups->{$_} = 1 } split /,/,$output[1]
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
	@{$TokenDB{$plg->data->{token}}->{control}}{qw/lastaccess groups username/} = (time,$groups,$plg->data->{username});

		while (my ($k,$v) = each %{ $TokenDB{$plg->data->{token}}->{control} }) {

			unless ( Storable::lock_store \$v, "$plg->{dir_session}/$plg->{data}->{token}/control/$k" ) {
			$plg->error("Could not store session data $_[$i] because $!");
			$plg->dsl->halt(plg->reply)
			}
		}

	$plg->reply('token'=>$plg->data->{token}, 'groups'=>[sort keys %{$groups}])
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

		if ($plg->Format->{to} eq 'json') {
		$JSON->canonical($plg->sort);

			if ($plg->pretty) {
      $JSON->pretty(1); $JSON->space_after(1) } else {
			$JSON->pretty(0); $JSON->space_after(0)
			}

    $JSON->utf8(0);
    $plg->{reply_text} = Encode::decode_utf8 $JSON->encode($_[0])
		}
		elsif ($plg->Format->{to} eq 'xml') {
		$XML::Hash::XS::canonical=$plg->sort;
		$XML::Hash::XS::indent=$plg->pretty;
		$plg->{reply_text} = XML::Hash::XS::hash2xml $_[0]
		}
		elsif ($plg->Format->{to} eq 'yaml') {
		$YAML::Syck::SortKey=$plg->sort;
    $plg->{reply_text} = YAML::Syck::Dump $_[0]
		}
		elsif ($plg->Format->{to} eq 'perl') {
		$Data::Dumper::Indent=$plg->pretty;
		$Data::Dumper::Sortkeys=$plg->sort;
		$plg->{reply_text} = Encode::decode_utf8 Data::Dumper::Dumper $_[0]
		}
		elsif ($plg->Format->{to} eq 'human') {
		$Handler{WALKER}->($_[0], sub {my $val=shift; $val =~s/^\s*(.*?)\s*$/$1/; $plg->{reply_text} .= join('.', @_) ." = $val\n"});
		$plg->{reply_text} = Encode::decode_utf8 $plg->{reply_text}
		}
	};

	if ($@) {
	$@=~s/[\v\h]+/ /g;
	$plg->error("hash to string convertion failed because $@");
	$plg->reply_text('')
	}
}



#	Returns a string formated as : json, xml, yaml, perl or human
#	Always includes the error
#
#	reply						            only the error
#	reply(   k1=>'v1', ... )    specific keys , values
#	reply( { k1=>'v1', ... } )  specific keys , values
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
		$plg->__HASH_TO_STRING({error=> $plg->error, @_} ) # This the normal
		}
	}
	else {
	$plg->__HASH_TO_STRING({error=> $plg->error}) # if no argument return only the error
	}

	if ($plg->error) {
	$plg->__HASH_TO_STRING({error=> $plg->error})
	}

$plg->dsl->halt( $plg->reply_text )
}



#  Return all or the selected posted keys/values
#
#	 PostData();              # all                posted keys/values
#	 PostData('k1', 'k2');    # hash with selected posted keys/values
#
sub PostData :PluginKeyword
{
my $plg=shift;

	if (@_) {

		if ('HASH' eq ref $plg->data) {
		%{$plg->data}{grep exists $plg->data->{$_}, @_}
		}
		elsif ('ARRAY' eq ref $plg->data) {
		my %hash;
		@hash{@_} = 1;
		grep exists $hash{$_}, @{$plg->data}
		}
		elsif ('SCALAR' eq ref $plg->data) {

			foreach (@_) {
			return $_ if $_ eq ${$plg->data}
			}
		}
		else {

			foreach (@_) {
			return $_ if $_ eq $plg->data
			}
		}
	}
	else {
		if    ('HASH'   eq ref $plg->data) { %{$plg->data} }
		elsif ('ARRAY'  eq ref $plg->data) { @{$plg->data} }
		elsif ('SCALAR' eq ref $plg->data) { ${$plg->data} }
		else  { $plg->data }
	}
}



#	Retrieves stored session data
#
#	my %data = SessionGet( 'k1', 'k2', ...);	# return a hash of the selected keys
#	my %data = SessionGet();					# return a hash of all keys

sub SessionGet :PluginKeyword
{
my $plg	= shift;

	unless ((exists $plg->data->{token}) && (exists $TokenDB{$plg->data->{token}})) {
	$plg->error('You need a valid token via login for using session data');
	$plg->dsl->halt($plg->reply)
	}

	if (0 == scalar @_) {
	%{$TokenDB{$plg->data->{token}}->{data}} # all
	}
	elsif ((1 == scalar @_)) {

		if ('ARRAY' eq ref $_[0]) {
		# At new Perl versions hash slice  %{$TokenDB{$plg->data->{token}}->{data}}{@{$_[0]}}
		map {$_ , $TokenDB{$plg->data->{token}}->{data}->{$_}} @{$_[0]}
		}
		else {
		$_[0] , $TokenDB{$plg->data->{token}}->{data}->{$_[0]}	# one record
		}
	}
	else {	
	map {$_ , $TokenDB{$plg->data->{token}}->{data}->{$_}} @_
	}
}


#   Set session data
#   Session data are not volatile like the user data.
#   They are persistent between requests
#
#   SessionSet(  new1 => 'foo1', new2 => 'foo2'  ); 
#   SessionSet( {new1 => 'foo1', new2 => 'foo2'} );

sub SessionSet :PluginKeyword
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
#		SessionDel( 'k1', 'k2', ... );    # delete only the selected keys
#		SessionDel();                     # delete all keys
#
sub SessionDel :PluginKeyword
{
my $plg	= shift;

	unless ((exists $plg->data->{token}) && (exists $TokenDB{$plg->data->{token}})) {
	$plg->error('You need a vaild token via login for using session data');
	$plg->dsl->halt($plg->reply)
	}

$dir = $plg->dir_session.'/'.$plg->data->{token};
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

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebService - RESTful Web Services with login, persistent data, multiple in/out formats, IP security, role based access

=head1 VERSION

version 4.4.7

=head2 SYNOPSIS

The replies have the extra key B<error> . At success B<error> is 0 , while at fail is the error message

The posted keys can be placed as url parameters if wanted

=head2 Route examples

  POST login           {"username":"joe", "password":"souvlaki"}
  POST login?username=joe&password=souvlaki
  POST ViewKeysAll
  POST ViewKeysSome    {"k1":"v1"}
  POST ProtectStore    {"token":"2d85b82b158e", "k1":"v1", "k2":"v2"}
  POST ProtectDelete   {"token":"2d85b82b158e"}
  POST ProtectRead     {"token":"2d85b82b158e"}
  POST logout          {"token":"2d85b82b158e"}

=head2 Code

  package MyApi;
  use     Dancer2;
  use     Dancer2::Plugin::WebService;

  post '/ViewKeysAll'    => sub { reply   PostData };
  post '/ViewKeysSome'   => sub { reply   PostData('k1','k2') };
  any  '/r3'             => sub { my %H = PostData('k1'); reply 'foo'=> $H{k1} };
  get  '/r1'             => sub { reply  'k1'=>'v1','k2'=>'v2' };
  get  '/r2'             => sub { reply {'k1'=>'v1','k2'=>'v2'}};
  get  '/error'          => sub { reply  'k1', 'v1', 'error', 'oups' };
  any  '/ProtectStore'   => sub { reply SessionSet('s1'=>'sv1', 's2'=>'v1') };
  post '/ProtectdDelete' => sub { reply SessionDel('s1', 's2') };
  any  '/ProtectRead'    => sub { reply SessionGet('s1', 's2') };
  dance;

=head2 Control output : sort, pretty, to, from

You can use the B<to>, B<from>, B<sort>, B<pretty>  parameters to change the input/output format

I<sort> if true the keys are returned sorted. The default is false because it is faster. Valid values are true, 1, yes, false, 0, no

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

=head3 Examples

  GET  /SomeRoute?to=human&sort=true&pretty=true
  GET  /SomeRoute?to=perl&sort=true&pretty=false
  POST /SomeRoute?to=xml&sort=true'      {"k1":"v1"}
  POST /SomeRoute?to=yaml'               {"k1":"v1"}
  POST /SomeRoute?to=perl'               {"k1":"v1"}
  POST /SomeRoute?from=json;to=human'    {"k1":"v1"}
  POST /SomeRoute?from=xml;to=human'     <Data><k1>v1</k1></Data>
  POST /SomeRoute?from=xml;to=yaml'      <Data><k1>v1</k1></Data>

=head2 Built in routes

I<Built in routes>

  GET  /WebService            list routes
  GET  /WebService/about      about
  GET  /WebService/version    version
  GET  /WebService/client     client information
  POST /login                 get a I<token> for using I<protected> routes and storing I<persistent> data
  POST /logout                If you logout your session and all your persistent data are deleted

  POST /login    {"username":"SomeUser","password":"SomePass"}
  POST /logout   {"token":"SomeToken"}

=head2 Routes

Your routes can be either B<public> or B<protected>

B<public> are the routes that anyone can use without B<login> , Τhey do not support sessions / persistent data. You can access the posted data using the method B<PostData>

B<protected> are the routes that you must provide a token, returned by the login route.
At B<protected> routes you can  I<read>, I<write>, I<delete> persistent data using the  methods B<SessionGet> , B<SessionSet> , B<SessionDel>

Persistent session data are auto deleted when you B<logout> or if your session expired.

You can define a route as B<protected> at the I<config.yml>

  plugins:
    WebService:
      Routes:
        Route1: { Protected: false }
        Route2: { Protected: true }
        Route3: { Protected: true, Groups: [ ftp , storage ] }

or at your application code

  setting('plugins')->{'WebService'}->{'Routes'}->{'SomeRoute'} = { Protected: 'true' };

=head2 IP access

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

=head2 Sessions

Upon successful login, client is in session until logout or get expired due to inactivity. In session you can use the session methods by providing the token you received.

=head2 Session persistent storage

You can change persistent data storage directory at the I<config.yml>

  plugins:
    WebService:
      Session directory : /var/lib/WebService

or at your main script

  setting('plugins')->{'WebService'}->{'Session directory'} = '/var/lib/WebService';

Be careful this directory must be writable from the user that is running the service

=head3 Session expiration

Sessions expired after some seconds of inactivity. You can change the amount of seconds either at the I<config.yml>

  plugins:
    WebService:     
      Session idle timeout : 3600

or at your main script

  setting('plugins')->{'WebService'}->{'Session idle timeout'} = 3600;

=head2 Methods

WebService methods for your main Dancer2 code

The posted data can be anything; hashes, lists, scalars

  curl -X POST 0:/   -d  '{ "k1":"v1", "k2":"v2", "k3":"v3" }'
  curl -X POST 0:/   -d  '[ "k1", "k2", "k3", "k4" ]'

=head3 PostData

Get the posted data

             PostData               Everything posted
  my %hash = PostData('k2','k4');   Only some keys  of a hash
  my @list = PostData('k2','k4');   Only some items of a list

=head3 reply

Send the reply to the client; it applies any necessary format convertions.
This should be the last route's statement

  reply                        only the error
  reply    k1 => 'v1', ...     anything you want
  reply( { k1 => 'v1', ... } ) anything you want
  reply   'k1'                 The specific key and its value of the posted data 

=head3 SessionGet

Read session persistent data. I<login is required>

  my %data = SessionGet;                     returns a hash of all keys 
  my %data = SessionGet( 'k1', 'k2', ...  ); returns a hash of the selected keys
  my %data = SessionGet(['k1', 'k2', ... ]); returns a hash of the selected keys

=head3 SessionSet

Store non volatile session persistent data. I<login is required>

You must pass your data as key / value pairs

  SessionSet(   'rec1' => 'v1', 'rec2' => 'v2', ...   );
  SessionSet( { 'rec1' => 'v1', 'rec2' => 'v2', ... } );

It returns a document of the stored keys, your can use the url  to=... modifier e.g.

  {
  "error" : 0,
  "stored keys" : [ "rec1", "rec2" ]
  }

=head3 SessionDel

Deletes session persistent data. I<login is required>

  SessionDel;                              delete all keys
  SessionDel(   'rec1', 'rec2', ...   );   delete selected keys
  SessionDel( [ 'rec1', 'rec2', ... ] );   delete selected keys

It returns a document of the deleted keys, your can use the url  to=... modifier e.g.

  {
  "error" : 0,
  "deleted keys" : [ "rec1", "rec2" ]
  }

=head2 Authentication andd role based access control

For using protected routes, you must provide a valid token received from the B<login> route.
The B<login> route is using the the first active authentication method of the I<config.yml>
Authentication method can be INTERNAL or external executable Command.

At INTERNAL you define the usernames / passwords directly at the I<config.yml> . The <any> means any username or password, 
so if you want to allow all users to login no matter the username or the password use

  <any> : <any>

This make sense if you just want to give anyone the ability for persistent data

At production enviroments, probably you want to use an external auth script e.g for the native "Linux native" authentication

  MODULE_INSTALL_DIR/AuthScripts/linux.sh

The protected routes, at  config.yml  have   Protected:true and their required groups e.g.  Groups:[grp1,grp2 ...]

The user must be member to all the route Groups

If the route's Groups list is empty or missing, the route will run with any valid token ignoring the group

This is usefull because you can have role based access control at your routes.
Every user with its token will be able to access only the routes is assigned to.

A sample route definition. Plese mention the \/ path separator

    Routes:      
      Route1      :
        Protected : false
      Route\/foo1 :
        Protected : true
        Groups    : [ group1 , group2 ... ]
      Route\/foo2 :
        Protected : true
        Groups    : [ ]

It is easy to write your own scripts for Active Directory, LDAP, facebook integration or whatever.

If the Command needs sudo, you must add the user running the WebService to sudoers

Please read the AUTHENTICATION_SCRIPTS for the details

A sample I<config.yml> is the following. 

  environment             : development
  plugins                 :
    WebService            :
      Default format      : json
      Session directory   : /var/lib/WebService
      Session idle timeout: 86400
      Routes              :
        mirror            : { Protected: false }
        somekeys          : { Protected: false }
        data\/m1          : { Protected: false }
        data\/m1          : { Protected: false }
        INeedLogin_store  : { Protected: true, Groups: [ ftp , storage ] }
        INeedLogin_delete : { Protected: true, Groups: log }
        INeedLogin_read   : { Protected: true }

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

      - Name      : Linux native
        Active    : false
        Command   : MODULE_INSTALL_DIR/AuthScripts/linux.sh
        Arguments : [ ]
        Use sudo  : true

      - Name      : Basic Apache auth for simple users
        Active    : false
        Command   : MODULE_INSTALL_DIR/AuthScripts/HttpBasic.sh
        Arguments : [ "/etc/htpasswd" ]
        Use sudo  : false

=head2 Installation

You should run your service a non privileged user e.g. I<dancer>

Create your application ( I<TestService> ) e.g. at I</opt/TestService/>

  dancer2 gen --application TestService --directory TestService --path /opt --overwrite
  chown -R dancer:dancer /opt/TestService

Write your code at the file  I</opt/TestService/lib/TestService.pm>

=head3 Configure your environment file

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

  plackup --host 0.0.0.0 --port 3000 -a /opt/TestService/bin/app.psgi --env production  --server Starman --workers=5 
  plackup --host 0.0.0.0 --port 3000 -a /opt/TestService/bin/app.psgi --env development --server HTTP::Server::PSGI --Reload /opt/TestService/lib/TestService.pm,/opt/TestService/config.yml
  plackup --host 0.0.0.0 --port 3000 -a /opt/TestService/bin/app.psgi

  # without Plack
  perl /opt/TestService/bin/app.psgi

view the INSTALL document for details

=head2 See also

B<Plack::Middleware::REST> Route PSGI requests for RESTful web applications

B<Dancer2::Plugin::REST> A plugin for writing RESTful apps with Dancer2

B<RPC::pServer> Perl extension for writing pRPC servers

B<RPC::Any> A simple, unified interface to XML-RPC and JSON-RPC

B<XML::RPC> Pure Perl implementation for an XML-RPC client and server.

B<JSON::RPC> JSON RPC Server Implementation

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
