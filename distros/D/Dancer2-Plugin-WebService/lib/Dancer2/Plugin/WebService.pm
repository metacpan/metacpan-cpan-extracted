# ABSTRACT: REST apis with login, persistent data, multiple in/out formats, IP security, role based access
# Multiple input/output formats : json , xml , yaml, perl , human
# Provide extra routes and functions to your main application.
# 
# George Bouras , george.mpouras@yandex.com
# Joan Ntzougani, ✞

package Dancer2::Plugin::WebService;
our $VERSION = '4.7.2';
if ( $^O =~/(?i)MSWin/ ) { CORE::warn "\nOperating system is not supported\n"; CORE::exit 1 }

use strict;
use warnings;
use Encode;
use Dancer2::Plugin;
use Storable;
use Cpanel::JSON::XS;
use XML::Hash::XS; $XML::Hash::XS::canonical=0;    $XML::Hash::XS::utf8=0; $XML::Hash::XS::doc=0; $XML::Hash::XS::root='root'; $XML::Hash::XS::encoding='utf-8'; $XML::Hash::XS::indent=2; $XML::Hash::XS::xml_decl=0;
use YAML::Syck;    $YAML::Syck::ImplicitTyping=0;  $YAML::Syck::ImplicitTyping=0;
use Data::Dumper;  $Data::Dumper::Trailingcomma=0; $Data::Dumper::Indent=2; $Data::Dumper::Terse=1; $Data::Dumper::Deepcopy=1; $Data::Dumper::Purity=1; $Data::Dumper::Sortkeys=0;

my $JSON = Cpanel::JSON::XS->new;
$JSON->utf8(0); $JSON->pretty(0); $JSON->indent(0); $JSON->max_size(0); $JSON->space_before(0); $JSON->space_after(1); $JSON->relaxed(0); $JSON->canonical(0); $JSON->allow_tags(1); $JSON->allow_unknown(0); $JSON->shrink(0); $JSON->allow_nonref(0); $JSON->allow_blessed(0); $JSON->convert_blessed(0); $JSON->max_depth(1024);

my %Formats = (json=>'application/json', xml=>'application/xml', yaml=>'application/yaml', perl=>'text/plain', human=>'text/plain');
my $fmt_rgx = eval 'qr/^('. join('|', sort keys %Formats) .')$/';
my $dir;
my $tmp;
my %Handler;
my %TokenDB;
my @keys;

has token           => (is=>'rw', lazy=>1, default    => undef);
has error           => (is=>'rw', lazy=>1, default    => 0);
has sort            => (is=>'rw', lazy=>1, default    => 0);
has pretty          => (is=>'rw', lazy=>1, default    => 1);
has route_name      => (is=>'rw', lazy=>1, default    => '');
has ClientIP        => (is=>'rw', lazy=>1, default    => '');
has reply_text      => (is=>'rw', lazy=>1, default    => '');
has auth_method     => (is=>'rw', lazy=>1, default    => '');
has auth_command    => (is=>'rw', lazy=>1, default    => '');
has data            => (is=>'rw', lazy=>1, default    => ''); # user posted data
has auth_config     => (is=>'rw', lazy=>1, default    => sub{ {} });
has Format          => (is=>'rw', lazy=>1, default    => sub{ {from => undef, to => undef} });
has Session_timeout => (is=>'ro', lazy=>0, from_config=> 'Session idle timeout',default=> sub{ 3600 }, isa => sub {unless ( $_[0]=~/^\d+$/ ) {warn "Session idle timeout \"$_[0]\" It is not a number\n"; exit 1}} );
has rules           => (is=>'ro', lazy=>0, from_config=> 'Allowed hosts',       default=> sub{ ['127.*', '192.168.*', '172.16.*'] });
has rules_compiled  => (is=>'ro', lazy=>0, default    => sub {my $array = [@{$_[0]->rules}]; for (@{$array}) { s/([^?*]+)/\Q$1\E/g; s|\?|.|g; s|\*+|.*?|g; $_ = qr/^$_$/i } $array});
has dir_session     => (is=>'ro', lazy=>0, default    => sub {my $D = exists $_[0]->config->{'Session directory'} ? $_[0]->config->{'Session directory'}."/$_[0]->{app}->{name}" : "$_[0]->{app}->{config}->{appdir}/session"; $D=~s|/+|/|g; my @MD = split /(?:\\|\/)+/, $D; my $i; for ($i=$#MD; $i>=0; $i--) { last if -d join '/', @MD[0..$i] } for (my $j=$i+1; $j<=$#MD; $j++) { unless (mkdir join '/', @MD[0 .. $j]) {warn "Could not create the session directory \"$D\" because $!\n"; exit 1} } $D} );
has OS              => (is=>'ro', lazy=>0, default    => sub {my $D = undef; foreach (qw[/usr/bin /bin /usr/sbin /sbin]) {if (-f "$_/uname") {$D="$_/uname"; last}; unless (defined $D) {warn "Could not found utility uname\n"; exit 1} } sub{-f $_[0] ? sub{open __F, $_[0]; $_=readline __F; close __F; ($_) = $_=~ /\A(\S+\s+\S+\s+\S+).*/ ; $_}->($_[0])  : sub { $_=qx[$D -sr] ; chomp ; $_ }->() }->('/proc/version') });
has rm              => (is=>'ro', lazy=>0, default    => sub {foreach (qw[/usr/bin /bin /usr/sbin /sbin]) {return "$_/rm" if -f "$_/rm" && -x "$_/rm" } warn "Could not found utility rm\n"; exit 1});
has session_enable  => (is=>'ro', lazy=>0, default    => sub {exists $_[0]->config->{'Session enable'} ? $_[0]->config->{'Session enable'}=~/(?i)[y1t]/ ? 1:0 : 1});

# Recursive walker of complex and custon Data Structures
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

(my $module_dir =__FILE__) =~s|/[^/]+$||; # Module's directory
unless (-d $module_dir) { CORE::warn "Could not find the Dancer2::Plugin::WebService installation directory\n"; CORE::exit 1 }

# Built-in routes and their security
$plg->config->{Routes}->{logout}              = { Protected => 1, 'Built in' => 1, Groups=>[] }; # we should be logged in to logout
$plg->config->{Routes}->{login}               = { Protected => 0, 'Built in' => 1 };
$plg->config->{Routes}->{WebService}          = { Protected => 0, 'Built in' => 1 };
$plg->config->{Routes}->{'WebService/client'} = { Protected => 0, 'Built in' => 1 };
$plg->config->{Routes}->{'WebService/routes'} = { Protected => 0, 'Built in' => 1 };
$plg->config->{Routes}->{''}                  = { Protected => 2, 'Built in' => 1 };

# Default settings
$plg->config->{'Default format'}= 'json' if ((! exists $plg->config->{'Default format'}) || ($plg->config->{'Default format'} !~ $fmt_rgx));
$app->config->{content_type}    = $Formats{ $plg->config->{'Default format'} };
$app->config->{show_errors}   //= 0;
$app->config->{charset}       //= 'UTF-8';
$app->config->{encoding}      //= 'UTF-8';

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

delete $plg->config->{'Session enable'};
delete $plg->config->{'Authentication methods'};

  if (($plg->session_enable) && ($plg->auth_method eq '')) {
  warn "\nWhile the sessions are enabled there is not any active authorization method at your config.yml\n";
  CORE::exit 1
  }

  # Check if there are protected routes
  foreach (keys %{$plg->config->{Routes}}) {
  next if exists  $plg->config->{Routes}->{$_}->{'Built in'};
  $plg->config->{Routes}->{$_}->{'Built in'}=0;

    if ((exists $plg->config->{Routes}->{$_}->{Protected}) && ($plg->config->{Routes}->{$_}->{Protected}=~/(?i)[y1t]/)) {

    delete $plg->config->{Routes}->{$_}->{Protected};
           $plg->config->{Routes}->{$_}->{Protected}=1;

      if ($plg->auth_method eq '') {
      warn "\nWhile there is at least one protected route ( $_ ) there is not any active authorization method at your config.yaml\n";
      CORE::exit 1
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

print STDOUT "\n";
print STDOUT "Application name      : ", $plg->dsl->config->{appname}  ,"\n";
print STDOUT 'Start time            : ', scalar localtime $^T ,"\n";
print STDOUT 'Run as user           : ', (getpwuid($>))[0] ,"\n";
print STDOUT "Command               : $0\n";
print STDOUT "PID parent            : ", getppid() ,"\n";
print STDOUT "PID Main              : $$\n";
print STDOUT 'Authorization method  : ', ( $plg->auth_method ? $plg->auth_method :'UNDEFINED' ) ,"\n";
print STDOUT "Authorization scripts : $module_dir/\n";
print STDOUT 'Environment           : ', $plg->dsl->config->{environment} ,"\n";
print STDOUT 'Logging               : ', $plg->dsl->config->{log} ,"\n";
print STDOUT 'Session enable        : ', ( $plg->session_enable ? 'Yes' : 'No') ,"\n";
print STDOUT 'Session directory     : ', $plg->dir_session ,"\n";
print STDOUT 'Session idle timeout  : ', $plg->Session_timeout ," sec\n";
print STDOUT "Version application   : ", ( exists $plg->dsl->config->{appversion} ? $plg->dsl->config->{appversion} : '0.0.0' ) ,"\n";
print STDOUT "Version Perl          : $^V\n";
print STDOUT "Version Dancer2       : $Dancer2::VERSION\n";
print STDOUT "Version WebService    : $VERSION\n";
print STDOUT "Operating system      : ", $plg->OS ,"\n\n";

# Restore the valid sessions, and delete the expired ones
opendir DIR, $plg->dir_session or die "Could not list session directory $plg->{dir_session} because $!\n";

  foreach my $token (grep ! /^\.+$/, readdir DIR) {

    if ((-f "$plg->{dir_session}/$token/control/lastaccess") && (-f "$plg->{dir_session}/$token/control/username") && (-f "$plg->{dir_session}/$token/control/groups")) {
    my $lastaccess = ${ Storable::retrieve "$plg->{dir_session}/$token/control/lastaccess" };

      if (time - $lastaccess > $plg->Session_timeout) {
      print "Delete expired session    : $token\n";
      system $plg->rm, '-rf', "$plg->{dir_session}/$token"
      }
      else {
        $TokenDB{$token}->{data} = {};
      @{$TokenDB{$token}->{control}}{qw/lastaccess username groups/} = ($lastaccess, ${Storable::retrieve "$plg->{dir_session}/$token/control/username"}, ${Storable::retrieve "$plg->{dir_session}/$token/control/groups"});

      opendir __TOKEN, "$plg->{dir_session}/$token/data" or die "Could not read session directory $plg->{dir_session}/$token/data because $!\n";

        foreach my $record (grep ! /^\.{1,2}$/, readdir __TOKEN) {
        next unless -f "$plg->{dir_session}/$token/data/$record";
        $record = Encode::decode('utf8', $record);
        $TokenDB{$token}->{data}->{$record} = Storable::retrieve "$plg->{dir_session}/$token/data/$record";
        $TokenDB{$token}->{data}->{$record} = ${ $TokenDB{$token}->{data}->{$record} } if 'SCALAR' eq ref $TokenDB{$token}->{data}->{$record}
        }

      close __TOKEN;
      print "Restore session           : $token (". scalar(keys %{$TokenDB{$token}->{data}}) ." records)\n"
      }
    }
    else {
    print "Delete corrupt session    : $token\n";
    system $plg->rm,'-rf',"$plg->{dir_session}/$token"
    }
  }

closedir DIR;


#print Dumper( $app ) ;exit;
#print Dumper( $plg->config->{Routes} ) ;exit;
#print Dumper( $plg->auth_config )      ;exit;
#print Dumper  \%TokenDB; exit;
#print "---------\n*".  $plg->dir_session  ."*\n---------\n";

## Catch hard errors 
#  $app->add_hook(
#    Dancer2::Core::Hook->new( name => 'init_error', code => sub
#      {
#      print STDERR "\n---------\n";
#      print STDERR "debug  : ". Dumper( $_[0] ); 
#      print STDERR "\n---------\n";
#
#      $plg->error( 'Unknown route '. $plg->dsl->request->env->{REQUEST_URI} );
#      $_[0]->{content} = "{ \"error\" : \"". $plg->error . "\", \"reply\" : {} }"
#      }
#    )
#  );


# Hook, BEFORE the main app process the request

  $app->add_hook( Dancer2::Core::Hook->new( name => 'before', code => sub
  {
  $plg->error(0);
  $plg->token(undef);
  $plg->data({});
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

          if    ( $app->request->query_parameters->{$_} eq 'jsn' ) { $plg->Format->{$_} = 'json' }
          elsif ( $app->request->query_parameters->{$_} eq 'yml' ) { $plg->Format->{$_} = 'yaml' }
          elsif ( $app->request->query_parameters->{$_} eq 'txt' ) { $plg->Format->{$_} = 'human'}
          elsif ( $app->request->query_parameters->{$_} eq 'text') { $plg->Format->{$_} = 'human'}
          else  {
          $plg->Format->{to} = $plg->config->{'Default format'};
          $plg->error("Format parameter $_ ( ".$app->request->query_parameters->{$_}.' ) is not one of the : '. join(', ',keys %Formats));
          $plg->reply
          }
        }
      }
      else {
      $plg->Format->{$_} = $plg->config->{'Default format'}
      }
    }

  # Header Content-Type
  $app->request->header('Content-Type'=> $Formats{$plg->Format->{to}});


  # Check client IP address against the access rules
  $plg->error('Client IP address '.$plg->ClientIP.' is not allowed');
    for (my $i=0; $i<@{$plg->rules_compiled}; $i++) {
      if ( $plg->ClientIP =~ $plg->rules_compiled->[$i] ) {
      $plg->error(0);
      last
      }
    }
  $plg->reply if $plg->error;


  # route name
  if    ( $app->request->{route}->{regexp} =~/^\^[\/\\]+(.*?)[\/\\]+\(\?#token.*/ ) { $plg->route_name($1) }
  elsif ( $app->request->{route}->{regexp} =~/^\^[\/\\]+(.*?)\$/ )                  { $plg->route_name($1) }
  else  { $plg->error('Could not recognize the route'); $plg->reply }

  unless (exists $plg->config->{Routes}->{$1}) {
  $_=$1; s/\\//g;
  $plg->error("Unknown route $_ you have to add it at your config.yml under the Routes");
  $plg->reply
  }

  # Convert the posted data text, to hash/array at $plg->data

      if ($app->request->body) {

        eval {

          if    ('json'  eq $plg->Format->{from}) { $plg->data(           $JSON->decode($app->request->body) ) }
          elsif ('xml'   eq $plg->Format->{from}) { $plg->data( XML::Hash::XS::xml2hash $app->request->body  ) }
          elsif ('yaml'  eq $plg->Format->{from}) { $plg->data( YAML::Syck::Load        $app->request->body  ) }
          elsif ('perl'  eq $plg->Format->{from}) { $plg->data( eval                    $app->request->body  ) }
          elsif ('human' eq $plg->Format->{from}) { my $ref={};

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

          $plg->data($ref)
          }
        };

			if ($@) {
			$@ =~s/[\s\v\h]+/ /g;
			$plg->error('Data parsing as '.$plg->Format->{from}." failed because $@");
      $plg->reply
      }
    }


    # Define the token if sent as a query parameter
    if (exists  $app->request->query_parameters->{token}) {
    $plg->token($app->request->query_parameters->{token});
    delete      $app->request->query_parameters->{token}
    }

    # Delete not needed control url parameters
    foreach (qw/from to sort pretty message/) {
    delete $app->request->query_parameters->{$_}
    }

    if ('HASH' eq ref $plg->data) {

      # Use data token as ... token !
      if ((exists $plg->data->{token}) && (! defined $plg->token))  {
      $plg->token($plg->data->{token});
      delete      $plg->data->{token}
      }

      # Use the url parameters as data
      foreach (keys %{$app->request->query_parameters}) {
      $plg->data->{$_} = $app->request->query_parameters->{$_}
      }
    }
    elsif ('ARRAY' eq ref $plg->data) {
    # probably we will should push the query parameters to data list or something else fancy
    # so far yada yada
    }
    else {
    $plg->error('Posted data are not keys or list'); $plg->reply
    }

  }));


# Hook ONLY for the protected routes, before the main app do anything
# halt if the session is expired, otherelse update the lastaccess

  $app->add_hook( Dancer2::Core::Hook->new(name=>'before', code=>sub{
  return unless (exists $plg->config->{Routes}->{$plg->route_name}) && ($plg->config->{Routes}->{$plg->route_name}->{Protected} == 1);

  if (! defined $plg->token )            { $plg->error("You must provide a token to use the protected route $plg->{route_name}"); $plg->reply }
  if (! exists $TokenDB{ $plg->token } ) { $plg->error('Invalid token'); $plg->reply }
  $dir = $plg->dir_session.'/'.$plg->token;

    if (time - $TokenDB{ $plg->token }->{control}->{lastaccess} > $plg->Session_timeout) {
    $plg->error('Session expired because its idle time '.(time - $TokenDB{ $plg->token }->{control}->{lastaccess}).' secs is more than the allowed '.$plg->Session_timeout.' secs');
    system $plg->rm,'-rf',$dir;
    delete $TokenDB{ $plg->token };
    $plg->data({});	# clear user data
    $plg->reply
    }
    else {
    # update the lastaccess
    $TokenDB{ $plg->token }->{control}->{lastaccess} = time;
    Storable::lock_store \$TokenDB{ $plg->token }->{control}->{lastaccess}, "$dir/control/lastaccess"
    }

	# Check if the user is member to all the Groups of the route

    foreach (@{$plg->config->{Routes}->{$plg->route_name}->{Groups}}) {

      unless (exists $TokenDB{ $plg->token }->{control}->{groups}->{$_} ) {
      $plg->error('Required route groups are '. join(',',@{$plg->config->{Routes}->{$plg->route_name}->{Groups}}) .' your groups are '. join(',', sort keys %{$TokenDB{ $plg->token }->{control}->{groups}})); $plg->reply
      }
    }

  }));


  # Built-in route /WebService list the routes
  $app->add_route(
  regexp => '/WebService',
  method => 'get',
  code   => sub {

      $plg->reply(
        {
        Application          => $app->{name},
        Server               => { bind => $app->request->env->{SERVER_NAME} , port => $app->request->env->{SERVER_PORT} , uptime => time - $^T },
        'Login idle timeout' => $plg->Session_timeout,
        'Auth method'        => ( $plg->auth_method ? $plg->auth_method :'UNDEFINED' ),
        Version              => {
          $app->{name}       => ( exists $plg->dsl->config->{appversion} ? $plg->dsl->config->{appversion} : '0.0.0' ),
          Dancer2            => $Dancer2::VERSION,
          Os                 => $plg->OS,
          Perl               => $],
          WebService         => $VERSION
          }
        }
      )
    }
  );

  # Built-in route /WebService/:what
  $app->add_route(
  regexp => '/WebService/:what?',
  method => 'get',
  code   => sub { $plg->error(0);

      if ( $app->request->param('what') =~/(?i)\Ar/ ) {

        $plg->reply(
          {
          'Built in'		=> {
            'Protected' => [ map { $_ }          grep   $plg->config->{Routes}->{$_}->{'Built in'} && $plg->config->{Routes}->{$_}->{Protected}==1, sort keys %{$plg->config->{Routes}} ],            
            'Public'    => [ map { $_ }          grep   $plg->config->{Routes}->{$_}->{'Built in'} && $plg->config->{Routes}->{$_}->{Protected}==0, sort keys %{$plg->config->{Routes}} ]
            },
          $plg->dsl->config->{appname} => {
            'Protected' => [ map { s/\\//g; $_ } grep ! $plg->config->{Routes}->{$_}->{'Built in'} && $plg->config->{Routes}->{$_}->{Protected}==1, sort keys %{$plg->config->{Routes}} ],
            'Public'    => [ map { s/\\//g; $_ } grep ! $plg->config->{Routes}->{$_}->{'Built in'} && $plg->config->{Routes}->{$_}->{Protected}==0, sort keys %{$plg->config->{Routes}} ]
            }
          }
        )
      }
      elsif ( $app->request->param('what') =~/(?i)\Ac/ ) {

        $plg->reply(
          {
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
          }
        )
      }
      else {
      $plg->error('Not existing internal route /WebService/'.$app->request->param('what')); $plg->reply
      }
    }
  );

  # logout and delete the session
  $app->add_route(
  regexp => '/logout',
  method => $_,
  code   => sub {
    $plg->error(0);
    delete $TokenDB{ $plg->token };
    system $plg->rm,'-rf', $plg->dir_session.'/'.$plg->token if -d $plg->dir_session.'/'.$plg->token;
    $plg->data({});
    $plg->reply( { token => $plg->token } )
    }
  ) foreach 'get','post','put';


	# Authentication
	$app->add_route(
	regexp => '/login',
	method => $_,
	code   => sub {
  if ($plg->auth_method eq '') { $plg->error('There is not any enabled authentication method at the config.yml'); $plg->reply }

  # Check the input parameters
  foreach ('username','password') {unless (exists $plg->data->{$_}) { $plg->error("Missing mandatory key $_"); $plg->reply }}
  if ( $plg->data->{username} =~/^\s*$/ ) { $plg->error('username can not be blank'); $plg->reply }
  if ( $plg->data->{password} eq ''     ) { $plg->error('password can not be blank'); $plg->reply }

  my $app    = shift;
  my $groups = {};
  $plg->error('authorization error');
  
    # Internal
    if ($plg->auth_method eq 'INTERNAL') {

      if (exists $plg->auth_config->{Accounts}->{ $plg->data->{username} }) {
        if      ($plg->auth_config->{Accounts}->{ $plg->data->{username} } eq '<any>')                {$plg->error(0)} # global password
        elsif   ($plg->auth_config->{Accounts}->{ $plg->data->{username} } eq $plg->data->{password}) {$plg->error(0)} # normal
      }

      if ($plg->error && exists $plg->auth_config->{Accounts}->{'<any>'}) {
        if    ($plg->auth_config->{Accounts}->{'<any>'} eq '<any>')                {$plg->error(0)} # global user and global password
        elsif ($plg->auth_config->{Accounts}->{'<any>'} eq $plg->data->{password}) {$plg->error(0)} # global user and normal password
      }
    }

    # The external authorization scripts expect at least the two arguments
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

    unless (2 == scalar @output) { $plg->error('Expected 2 lines output instead of '.scalar(@output).' at auth method '.$plg->auth_method ); $plg->reply }
    $plg->error($output[0]);
    map { $groups->{$_} = 1 } split /,/,$output[1]
    }

  $plg->reply if $plg->error;

  # Create the token and session dir
  open  URANDOM__, '<', '/dev/urandom' or die "\nCould not read device /dev/urandom\n";
  read  URANDOM__, my $i, 12;
  close URANDOM__;
  $tmp = time.'-'.unpack 'h*',$i;
  $i=0;
  while ( -e $plg->dir_session .'/'. $tmp .'-'. $i++ ) {}
  $tmp .= '-'. (--$i);

    foreach ("$plg->{dir_session}/$tmp", "$plg->{dir_session}/$tmp/control", "$plg->{dir_session}/$tmp/data") {
    unless (mkdir $_) { $plg->error("Could not create session directory $_ because $!"); $plg->reply }
    }

    $TokenDB{$tmp}->{data} = {};
  @{$TokenDB{$tmp}->{control}}{qw/lastaccess groups username/} = (time,$groups,$plg->data->{username});

    while (my ($k,$v) = each %{ $TokenDB{$tmp}->{control} }) {

      unless ( Storable::lock_store \$v, "$plg->{dir_session}/$tmp/control/$k" ) {
      $plg->error("Could not store session data $_[$i] because $!"); $plg->reply
      }
    }

  $plg->reply( { token=>$tmp, groups=>[sort keys %{$groups}] } )
  }) foreach 'post', 'put'
}



#	Accepts a Perl data structure, and under the key "reply" returns a string formated as : json, xml, yaml, perl or human
# It also returns any error defined from the Error(...)  
# A typical response is 
#
# {
# "reply" : { "k1" : "B", "k2" : "v2" },
# "error" : "oh no"
# }
#
#	reply
#	reply(   'hello world'        )
#	reply( [ 'a', 'b' , 'c' ]     )
#	reply( { k1=>'v1', k1=>'v1' } )
#	reply(   'a', 'b' , 'c'       )
#	reply(  \&SomeFunction        )

sub reply :PluginKeyword
{
my $plg=shift;

  if ($#_ == -1) {
  $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => {} } ) # if no argument return only the error
  }
  elsif ($#_ == 0) {
    if (ref $_[0]) {
      if    ('HASH'   eq ref $_[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => $_[0]    } ) }
      elsif ('ARRAY'  eq ref $_[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => $_[0]    } ) }
      elsif ('SCALAR' eq ref $_[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => ${$_[0]} } ) }
      elsif ('GLOB'   eq ref $_[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => 'GLOB'   } ) }
      elsif ('CODE'   eq ref $_[0]) {
      @keys = &{$_[0]}();

        if (0 == $#keys) {
          if (ref $keys[0]) {
            if    ('HASH'   eq ref $keys[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => $keys[0]    } ) }
            elsif ('ARRAY'  eq ref $keys[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => $keys[0]    } ) }
            elsif ('SCALAR' eq ref $keys[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => ${$keys[0]} } ) }
            elsif ('GLOB'   eq ref $keys[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => 'GLOB'      } ) }
            elsif ('CODE'   eq ref $keys[0]) { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => 'CODE'      } ) }
            else                             { $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => ${$keys[0]} } ) }
          }
          else {
          $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => $keys[0] } )
          }
        }
        else {
        $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => [ @keys ] } )
        }
      }
    }
    else {
    $plg->__STRUCTURE_TO_STRING( { error=> $plg->error, reply => $_[0] } )
    }
  }
  else {
  $plg->__STRUCTURE_TO_STRING( { error => $plg->error, reply => [ @_ ] } )
  }

$plg->dsl->halt( $plg->reply_text )
}


#	Convert a hash, array, scalar to sting as $plg->reply_text
#	format of "reply_text" is depended from "to" : json xml yaml perl human
#
#	$plg->__STRUCTURE_TO_STRING( Some Data )

sub __STRUCTURE_TO_STRING
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

    $plg->{reply_text} = Encode::decode 'utf8', $JSON->encode($_[0])
		}
		elsif ($plg->Format->{to} eq 'xml') {
		$XML::Hash::XS::canonical = $plg->sort;
    $XML::Hash::XS::indent    = $plg->pretty ? 2 : 0;
		$plg->{reply_text} = Encode::decode 'utf8', XML::Hash::XS::hash2xml $_[0]
		}
		elsif ($plg->Format->{to} eq 'yaml') {
    $YAML::Syck::SortKey=$plg->sort;
    $plg->{reply_text} = Encode::decode 'utf8', YAML::Syck::Dump $_[0]
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
	$plg->dsl->halt("{\"error\" : \"FATAL, Internal structure to string convertion failed\"}")
	}
}


#  Returns all or some of the posted data
#  Retruns a  hash  referense if the data are posted as hash
#  Retruns an array referense if the data are posted as list
#
#	 UserData();              # all               posted data of $plg->data
#	 UserData( 'k1', 'k2' );  # only the selected posted data of $plg->data
#
sub UserData :PluginKeyword
{
my $plg=shift;

  if (@_) {

    if ('HASH' eq ref $plg->data) {
    $tmp={}; @{$tmp}{@_}=();

      foreach (keys %{$plg->data}) {
      delete $plg->data->{$_} unless exists $tmp->{$_}
      }
    }

    elsif ('ARRAY' eq ref $plg->data) {
    $tmp={}; @{$tmp}{@_}=();
    $plg->data( [ grep exists $tmp->{$_}, @{$plg->data} ] ) # Redefine the $plg->data from any valid values of the $plg->data
    }

    elsif ('SCALAR' eq ref $plg->data) { foreach (@_) { $plg->data($_) if $_ eq ${$plg->data} } }
    else                               { foreach (@_) { $plg->data($_) if $_ eq   $plg->data  } }
  }

$plg->data
}


#   Set session data
#   Session data are not volatile like the posted by user
#   They are persistent between requests until the user logout or its session get expired
#   Returns a list of the stored keys
#
#   SessionSet(  k1 => 'v1', k2 => 'v2'  ); 
#   SessionSet( {k1 => 'v1', k2 => 'v2'} );

sub SessionSet :PluginKeyword
{
my $plg=shift;

  if ($plg->session_enable) {

    if (defined $plg->token) {
  
      if ( ! exists $TokenDB{ $plg->token } ) {
      $plg->error('Invalid token'); $plg->reply
      }
    }
    else {
    $plg->error('You need a token via login route for saving session data'); $plg->reply
    }
  }
  else {
  $plg->error('Sessions are disabled at application config.yml'); $plg->reply
  }

@_ = %{$_[0]} if (1 == @_) && ('HASH' eq ref $_[0]);
@keys=();

  for (my ($k,$v)=(0,1); $k<$#_-(@_ % 2); $k+=2,$v+=2) {
  next if 'token' eq $_[$k];
  push @keys, $_[$k];
  $tmp = Encode::decode 'utf8', $_[$k];

  $TokenDB{$plg->token}->{data}->{$tmp} = $_[$v];

    unless ( Storable::lock_store ref $_[$v] ? $_[$v] : \$_[$v],  "$plg->{dir_session}/". $plg->token  ."/data/$tmp" ) {
    $plg->error("Could not store session key $tmp because $!"); $plg->reply
    }
	}

@keys
}


#	Retrieves session data
#
#	my %data = SessionGet();                 # return a hash of all keys
#	my %data = SessionGet('k1', 'k2', ...);  # return a hash of the selected keys

sub SessionGet :PluginKeyword
{
my $plg	= shift;

  if ($plg->session_enable) {

    if (defined $plg->token) {

      if (! exists $TokenDB{$plg->token}) {
      $plg->error('Invalid token'); $plg->reply
      }
    }
    else {
    $plg->error('You need a token via login route for reading session data'); $plg->reply
    }
  }
  else {
  $plg->error('Sessions are disabled at application config.yml'); $plg->reply
  }

	if (0 == scalar @_) {
  # all records
	map { Encode::encode('utf8',$_) , $TokenDB{$plg->token}->{data}->{$_}} keys %{$TokenDB{$plg->token}->{data}}
	}
	elsif ((1 == scalar @_)) {
  # one record

		if ('ARRAY' eq ref $_[0]) {
		# At new Perl versions hash slice  %{$TokenDB{ $plg->token }->{data}}{@{$_[0]}}
    map { exists $TokenDB{$plg->token}->{data}->{$_} ? ( Encode::encode('utf8',$_) , $TokenDB{$plg->token}->{data}->{$_} ) : () } @{$_[0]}
		}
		else {
         exists $TokenDB{$plg->token}->{data}->{$_[0]} ? ( Encode::encode('utf8',$_[0]) , $TokenDB{$plg->token}->{data}->{$_[0]} ) : ()
		}
	}
	else {
  # Some records, normal, not array reference
  map { ( Encode::encode('utf8',$_) , $TokenDB{$plg->token}->{data}->{$_} ) }  grep exists $TokenDB{$plg->token}->{data}->{$_} , @_
	}
}


#	Delete session data
# Retun a list of the deleted keys
#
#		SessionDel()                  # delete all  records
#		SessionDel(   'k1', 'k2'   )  # delete some records
#   SessionDel( [ 'k1', 'k2' ] )  # delete some records

#
sub SessionDel :PluginKeyword
{
my $plg	= shift;

  if ($plg->session_enable) {

    if (defined $plg->token) {

      if ( ! exists $TokenDB{$plg->token} ) {
      $plg->error('Invalid token'); $plg->reply
      }
    }
    else {
    $plg->error('You need a token via login route for deleting session data'); $plg->reply
    }
  }
  else {
  $plg->error('Sessions are disabled at application config.yml'); $plg->reply
  }

$dir = $plg->dir_session.'/'.$plg->token;
@keys=();

  if (@_) {
  @_ = @{$_[0]} if (1 == @_) && ('ARRAY' eq ref $_[0]);

    foreach (@_) {
    $_ = Encode::decode 'utf8', $_;

      if (exists $TokenDB{$plg->token}->{data}->{$_}) {
      delete     $TokenDB{$plg->token}->{data}->{$_};
      $_ = Encode::encode 'utf8', $_;
      push @keys, $_;
      unlink "$dir/data/$_" if -f "$dir/data/$_"
      }
    }
  }
  else {

		foreach (keys %{$TokenDB{$plg->token}->{data}}) {
    delete          $TokenDB{$plg->token}->{data}->{$_};
    $_ = Encode::encode 'utf8', $_;
    push @keys, $_;
    unlink "$dir/data/$_" if -f "$dir/data/$_"
		}
  }

@keys
}


#	Set the error
#
#   Error('oh no') --> { "error" : "oh no" }
#   Error()        --> { "error" : "Something went wrong" }
#
# any['get','post','put'] => '/error1' => sub {       Error('oh no !'); reply UserData };
# any['get','post','put'] => '/error2' => sub {       Error('oh no !'); reply          };
# any['get','post','put'] => '/error3' => sub { reply Error('oh no !')                 };

sub Error :PluginKeyword { $_[0]->error( exists $_[1] ? Encode::encode('utf8', $_[1]) : 'Something went wrong' ) }

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebService - REST apis with login, persistent data, multiple in/out formats, IP security, role based access

=head1 VERSION

version 4.7.2

=head1 SYNOPSIS

  get '/my_keys' => sub { reply { 'k1'=>'v1' , 'k2'=>'v2' } };

  curl $url/my_keys

=head1 DESCRIPTION

Create REST APIs with login, logout, persistent session data, IP security, role based access.
Multiple input/output supported formats : json , xml , yaml, perl , human
Post your data and keys as url parameters or content body text

  curl -X GET  "$url?k1=v1&k2=v2&k3=v3"
  curl -X POST  $url -d  '{ "k1":"v1", "k2":"v2", "k3":"v3" }'
  curl -X POST  $url -d  '[ "k1", "k2", "k3", "k4" ]'

=head1 NAME

Convert your functions to REST api with minimal effort

=head1 URL parameters to format the reply

You can use the  B<from>, B<to>, B<sort>, B<pretty>  parameters to define the input/output format

=over 2

=item I<from> , I<to>

Define the input/output format. You can mix input/output formats independently.
I<from> default is the I<config.yml> property plugins.TestService.Default format = json
Supported formats are

  json or jsn
  yaml or yml
  xml
  perl
  human or text or txt

=item I<sort>

If true the keys are returned sorted. The default is false because it is faster. Valid values are true, 1, yes, false, 0, no

=item I<pretty>

If false, the data are returned as one line compacted. The default is true, for human readable output. Valid values are true, 1, yes, false, 0, no

=back

=head1 METHODS

Plugin methods available for your main Dancer2 code

=head2 UserData

Get all or some of the posted data
Retruns a hash referense if the data are posted as hash
Retruns an array referense if the data are posted as list

  UserData               Everything
  UserData('k1','k2');   Only some keys of the posted hash, list

  get '/foo' => sub { reply UserData };

=head2 Error

It sets the error. Normally at success B<error> is 0.
It does not stop the route execution

  any['get','post'] => '/error1' => sub {       Error('oh no'); reply UserData };
  any['get','post'] => '/error2' => sub {       Error('oh no'); reply          };
  any['get','post'] => '/error3' => sub { reply Error('oh no')                 };

=head2 reply

Accepts a Perl data structure, and under the key "reply" returns a string formated as : json, xml, yaml, perl or human

It also returns any error defined from the Error(...)  

Aply any necessary format convertions.

This should be the last route's statement

  reply
  reply(   'hello world'        )
  reply(   'a', 'b' , 'c'       )
  reply( [ 'a', 'b' , 'c' ]     )
  reply( { k1=>'v1', k1=>'v1' } )
  reply(  \&SomeFunction        )

A typical response is

  {
  "reply" : { "T" : "42", "wind" : "12" },
  "error" : "Cartridge out of ink"
  }

=head2 SessionSet

Store session persistent data. It is a protected method, I<login is required>

Session data are not volatile like posted data.

They are persistent between requests until they deleted, the user logout or their session get expired.

Returns a list of the stored keys.

You must pass your data as hash or hash reference.

  any['get','post'] => '/session_save'  => sub {
  @arr = SessionSet(   k1=>'v1' , k2=>'v2'    );
  @arr = SessionSet( { k3=>'v3' , k3=>'v4' }  );
  reply { 'saved keys' => \@arr }
  };

Store from a POST passing the login token as url parameter

  curl $url/session_save?token=17398-5c8a71b -H "$H" -X POST -d '{"k1":"v1", "k2":"v2", "k3":"v3"}'

=head2 SessionGet

Read session persistent data. It is a protected method, I<login is required>

Returns a hash

  any['post','put'] => '/session_read' => sub {
  my %has1 = SessionGet(   'k1','k2'   );  # some records
  my %has2 = SessionGet( [ 'k1','k2' ] );  # some records
  my %hash = SessionGet();                 # all  reocords
  reply { %hash }
  };

  curl $url/session_read?token=17398-5c8a71b

=head2 SessionDel

Deletes session persistent data. It is a protected method, I<login is required>

Returns a list of the deleted keys

  SessionDel;                              delete all keys
  SessionDel(   'rec1', 'rec2', ...   );   delete selected keys
  SessionDel( [ 'rec1', 'rec2', ... ] );   delete selected keys

  any['delete'] => '/session_delete' => sub {
  my $arg = UserData();
  my @arr = SessionDel( $arg );
  reply { 'Deleted keys' => \@arr }
  };

  curl -X DELETE $url/session_delete?token=17398-5c8a71b -H "$H" -d '["k1","k2","k9"]'

  {
    "error" : 0,
    "reply" : {
        "Deleted keys" : [ "k1" , "k2" ]
    }
  }

=head1 Authentication and role based access control

The routes can be either B<public> or B<protected>

=over 2

=item B<protected>

  routes that you must provide a token, returned by the login route.
  Afer login you can save, read persistent session data, which they  auto deleted when you B<logout> or if your session expired.

=item B<public>

  routes that anyone can use without B<login> , they do not support sessions / persistent data.

=back

Example of route definitions and authentication mechanisms at the I<config.yml>

    ...

    Routes:
      mirror         : { Protected: false }
      text           : { Protected: true, Groups: [] }
      dev\/commits   : { Protected: true, Groups: [ git , ansible ] }

    Authentication methods:

    - Name      : INTERNAL
      Active    : true
      Accounts  :
        user1   : s3cr3T+PA55sW0rD
        user2   : <any>
        <any>   : S3cREt-F0R-aLl
        #<any>  : <any>

    - Name      : Linux native users
      Active    : false
      Command   : MODULE_INSTALL_DIR/AuthScripts/Linux_native_authentication.sh
      Arguments : [ ]
      Use sudo  : true

    - Name      : Basic Apache auth for simple users
      Active    : false
      Command   : MODULE_INSTALL_DIR/AuthScripts/HttpBasic.sh
      Arguments : [ "/etc/htpasswd" ]
      Use sudo  : false

    ...

For using protected routes, user must provide a valid token received from the B<login> route.
The B<login> route is using the the first active authentication method of the I<config.yml>
Authentication method can be INTERNAL or external executable Command.

At INTERNAL you define the usernames / passwords directly at the I<config.yml> . The <any> means any username or password,
so if you want to allow all users to login no matter the username or the password use

  <any> : <any>

This make sense if you just want to give anyone the ability for persistent data

At production enviroments, probably you want to use an external auth script e.g for the native "Linux native" authentication

  MODULE_INSTALL_DIR/AuthScripts/Linux_native_authentication.sh

The protected routes, at  config.yml  have   Protected:true and their required groups e.g.  Groups:[grp1,grp2 ...]

The user must be member to all the route Groups

If the route's Groups list is empty or missing, the route will run with any valid token ignoring the group

This way you can have group based access at your routes.
Every user is be able to access only the routes is assigned to.

It is easy to write your own scripts for LDAP, Active Directory, OAuth 2.0, etc

If the Command needs sudo, you must add the user running the application to sudoers e.g

  dendrodb ALL=(ALL:ALL) NOPASSWD: /usr/share/perl5/site_perl/Dancer2/Plugin/AuthScripts/Linux_native_authentication.sh

Please read the file  AUTHENTICATION_SCRIPTS  for the details

=head1 IP access

You can control which clients are allowed to use your application at the file I<config.yml>

The rules are checked from up to bottom until there is a match. If no rule match then the client can not login. At rules your can use the wildcard characters * ? 

  ...
  plugins:
    WebService:
      Allowed hosts:
      - 127.*
      - 10.*
      - 172.20.*
      - 32.??.34.4?
      - 4.?.?.??
      - ????:????:????:6d00:20c:29ff:*:ffa3
      - 192.168.0.153
      - "*"

=head1 Sessions

Upon successful login, the client is in session until logout or its session get expired due to inactivity.

While in session you can access protected routes and save, read, delete session persistent data.

at the I<config.yml> You can change persistent data storage directory and session expiration

=over 2

=item B<Storage directory>

  Be careful this directory must be writable from the user that is running the service
  To set the sessions directory

  plugins:
    WebService:
      Session directory : /var/lib/WebService

  or at your application
  setting('plugins')->{'WebService'}->{'Session directory'} = '/var/lib/WebService';

=item B<Session expiration>

  Sessions expired after some seconds of inactivity. You can change the amount of seconds either at the I<config.yml>

  plugins:
    WebService:     
      Session idle timeout : 3600

  or at your main script

  setting('plugins')->{'WebService'}->{'Session idle timeout'} = 3600;

=back

=head1 Built in plugin routes

These are plugin built in routes 

  WebService            version
  WebService/routes     list the built-in and application routes
  WebService/client     client propertis
  login                 login
  logout                logout

Usage examples

  export url=http://127.0.0.1:3000
  export H='Content-Type: application/json'

  curl  $url
  curl  $url/WebService/routes?sort=true
  curl  $url/WebService/client?sort=true
  curl  $url/WebService
  curl "$url/WebService?to=json&pretty=true&sort=true"
  curl  $url/WebService?to=yaml
  curl "$url/WebService?to=xml&pretty=false"
  curl "$url/WebService?to=xml&pretty=true"
  curl  $url/WebService?to=perl
  curl  $url/WebService?to=human

=head1 Application routes

Based on the code of our TestService ( lib/TestService.pm ) some examples of how to login, logout, and route usage

  curl  $url/mirror -X POST -H "$H"        -d '[ "a", "b", "c" ]'
  curl  $url/mirror -X GET                 -d '[ "a", { "k1" : "v1" } ]'
  curl "$url/mirror?from=xml&to=yaml"      -d '<root><k1>v1</k1><k2>v2</k2><k3></k3></root>'
  curl  $url/mirror?sort=true              -d '{ "k1":"v1", "k2":"v2", "k3":{} }'
  curl "$url/mirror?k3=v3&k4=v4&sort=true" -d '{ "k1":"v1", "k2":"v2" }'
  curl  $url/mirror?to=human               -d '{ "k1":"v1", "k2":"v2" }'
  curl "$url/mirror?to=json&pretty=true"   -d '{ "k1":[ "a","b","c" ] }'
  curl "$url/mirror?to=xml&pretty=false"   -d '{ "k1":"v1", "k2":"v2" }'
  curl  $url/mirror?to=yaml                -d '{ "k1":[ "a","b","c" ] }'
  curl  $url/mirror?to=FOO                 -d '{ "k1":"v1" }'

Login. A successful login returns a token e.g. 17393926-5c8-0

  curl -X POST $url/login -H "$H" -d '{"username": "user1", "password": "s3cr3T+PA55sW0rD"}'

Unprotected application routes

  curl  $url/text -H "$H" -d '{"token":"17393926-5c8-0"}' -X POST
  curl  $url/text_ref
  curl  $url/list?pretty=false
  curl  $url/list_ref?to=yaml
  curl  $url/list_ref
  curl  $url/hash
  curl  $url/function/text
  curl  $url/function/list
  curl  $url/function/hash
  curl  $url/function/text_ref
  curl  $url/function/list_ref
  curl  $url/keys_selected?to=yaml -d '{ "k1":"v1", "k2":"v2", "k3":"v3" }'
  curl  $url/keys_selected?to=yaml -d '[ "k1", "k2", "k3", "k4" ]'
  curl "$url/error?to=json&pretty=true" -H "$H" -d '{"k1":"B",  "k2":"v2"}'

Protected application routes

  curl  $url/text
  curl  $url/text?token=17393926-5c8-0
  curl  $url/session_save?token=17393926-5c8-0 -H "$H" -X POST -d '{"k1":"v1", "k2":"v2", "k3":"v3"}'
  curl  $url/session_read?token=17393926-5c8-0
  curl  $url/session_delete?token=17393926-5c8-0 -H "$H" -X DELETE -d '["k3","k8","k9"]'
  curl  $url/session_read?token=17393926-5c8-0

Logout

  curl  $url/logout?token=17393926-5c8-0
  curl  $url/logout -d '{"token":"17393926-5c8-0"}' -H "$H" -X POST

=head1 Plugin Installation

You should your run your APIs as a non privileged user e.g. the "dancer"

  getent group  dancer >/dev/null || groupadd dancer
  getent passwd dancer >/dev/null || useradd -g dancer -l -m -c "Dancer2 WebService" -s $(which nologin) dancer
  i=/var/lib/WebService; [ -d $i ] || { mkdir $i; chown -R dancer:dancer $i; }
  i=/var/log/WebService; [ -d $i ] || { mkdir $i; chown -R dancer:dancer $i; }
  cpanm Dancer2
  cpanm Dancer2::Plugin::WebService

=head1 Create a sample application e.g. the "TestService"

As best practise we create our applications inside the dancer's home directory

  /usr/bin/site_perl/dancer2 version
  dancer2 gen --application TestService --directory TestService --path /home/dancer --overwrite  
  vi /home/dancer/TestService/bin/app.psgi

    #!/usr/bin/perl
    use strict;
    use warnings;
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use TestService;
    use Plack::Builder;
    builder {
    enable 'Deflater';
    # you can have multiple applications on different http paths
    mount '/' => TestService->to_app
    }

  chown -R dancer:dancer /home/dancer/TestService

=head1 TestService

For better comprehension of the functionality, review the TestService code

  package TestService;

  use strict;
  use warnings;
  use Dancer2;
  use Dancer2::Plugin::WebService;
  set no_default_middleware => true;
  our $VERSION = exists config->{appversion} ? config->{appversion} : '0.0.0.0';

  get '/' => sub{send_as html => template 'index' => {'title' => 'TestService'}, {layout=>'main'}};

  any['get','post']=> '/mirror'=> sub { reply UserData };
  any['get','post']=> '/text'  => sub { reply  'hello world'                  };
  get '/text_ref'              => sub { reply \'hello world'                  };
  get '/list'                  => sub { reply   'a', 'b', 'c'                 };
  get '/list_ref'              => sub { reply [ 'a', 'b', 'c' ]               };
  get '/hash'                  => sub { reply { 'k1'=>'v1' , 'k2'=>'v2' }     };
  get '/function/text'         => sub { reply sub {  'hello world'          } };
  get '/function/list'         => sub { reply sub {   'a', 'b', 'c', 'd'    } };
  get '/function/hash'         => sub { reply sub { {'k1'=>'v1','k2'=>'v2'} } };
  get '/function/text_ref'     => sub { reply sub { \'hello world'          } };
  get '/function/list_ref'     => sub { reply sub { [ 'a', 'b', 'c', 'd' ]  } };

  any['get','post','put'] => '/error'         => sub { Error('oh no'); reply UserData  };
  any['get','post','put'] => '/keys_selected' => sub { reply UserData('k1','k2')       };
  any['get','post','put'] => '/session_save'  => sub { reply { 'saved keys' => \@arr } };
  any['post','put','get'] => '/session_read'  => sub { reply { %hash } };
  any['delete'] => '/session_delete' => sub { my $arg = UserData(); reply { 'Deleted keys' => \@arr } };

  dance

=head1 Configuration config.yml

At the configuration file define the application name, version, routes, their security, and the authorization methods

vi /home/dancer/TestService/config.yml

  appname                 : TestService
  appversion              : 1.0.1
  environment             : development
  layout                  : main
  charset                 : UTF-8
  template                : template_toolkit
  engines:
    template:
      template_toolkit:
        EVAL_PERL         : 0
        start_tag         : '<%'
        end_tag           : '%>'

  plugins:
    WebService:
      Session enable      : true
      Session directory   : /var/lib/WebService
      Session idle timeout: 86400
      Default format      : json

      Allowed hosts:
      - 172.20.20.*
      - "????:????:????:6d00:20c:29ff:*:ffa3"
      - 127.*
      - 10.*.?.*
      - *

      Routes:
        mirror            : { Protected: false }
        text              : { Protected: true, Groups: [] }
        text_ref          : { Protected: false }
        list              : { Protected: false }
        list_ref          : { Protected: false }
        hash              : { Protected: false }
        function\/text    : { Protected: false }
        function\/list    : { Protected: false }
        function\/hash    : { Protected: false }
        function\/text_ref: { Protected: false }
        function\/list_ref: { Protected: false }
        keys_selected     : { Protected: false }
        error             : { Protected: false }
        session_save      : { Protected: true, Groups: [] }
        session_read      : { Protected: true, Groups: [] }
        session_delete    : { Protected: true, Groups: [] }
        dev\/commits      : { Protected: true, Groups: [ git , ansibleremote ] }

      Authentication methods:

      - Name      : INTERNAL
        Active    : true
        Accounts  :
          user1   : s3cr3T+PA55sW0rD
          user2   : <any>
          <any>   : S3cREt-4-aLl
          #<any>  : <any>

      - Name      : Linux native users
        Active    : false
        Command   : MODULE_INSTALL_DIR/AuthScripts/Linux_native_authentication.sh
        Arguments : [ ]
        Use sudo  : true

      - Name      : Basic Apache auth for simple users
        Active    : false
        Command   : MODULE_INSTALL_DIR/AuthScripts/HttpBasic.sh
        Arguments : [ "/etc/htpasswd" ]
        Use sudo  : false

=head1 Start the application

To start it manual as user I<dancer> from the command line

=over 2

=item Production

  sudo -u dancer plackup --host 0.0.0.0 --port 3000 --server Starman --workers=5 --env development -a /home/dancer/TestService/bin/app.psgi

=item While developing

  sudo -u dancer plackup --host 0.0.0.0 --port 3000 --env development --app /home/dancer/TestService/bin/app.psgi --server HTTP::Server::PSGI

=back

view also the INSTALL document for details

=head1 Configure the loggger at the environment file

I</home/dancer/TestService/environments/[development|production].yml>

  log              : 'core'   # core, debug, info, warning, error
  startup_info     : 1        # print the banner
  show_errors      : 1        # if true shows a detailed debug error page
  show_stacktrace  : 0
  warnings         : 1        # should Dancer2 consider warnings as critical errors?
  no_server_tokens : 1        # disable server tokens in production environments
  logger           : 'file'   # console : to STDOUT , file : to file
  engines:
    logger:
      file:
        log_format : '{"ts":"%{%Y-%m-%d %H:%M:%S}t","host":"%h","pid":"%P","level":"%L","message":"%m"}'
        log_dir    : '/var/log/WebService'
        file_name  : 'TestService.log'
      console:
        log_format : '%T , %h, %m'

=head1 See also

B<Plack::Middleware::REST> Route PSGI requests for RESTful web applications

B<Dancer2::Plugin::REST> A plugin for writing RESTful apps with Dancer2

B<RPC::pServer> Perl extension for writing pRPC servers

B<RPC::Any> A simple, unified interface to XML-RPC and JSON-RPC

B<XML::RPC> Pure Perl implementation for an XML-RPC client and server.

B<JSON::RPC> JSON RPC Server Implementation

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
