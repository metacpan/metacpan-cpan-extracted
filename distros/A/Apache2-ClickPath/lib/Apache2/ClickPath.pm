package Apache2::ClickPath;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use APR::Table ();
use APR::SockAddr ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::Connection ();
use Apache2::Filter ();
use Apache2::RequestRec ();
use Apache2::Module ();
use Apache2::CmdParms ();
use Apache2::Directive ();
use Apache2::Log ();
use Apache2::URI ();
use Apache2::Const -compile => qw(DECLINED OK
				  OR_ALL RSRC_CONF
				  TAKE1 RAW_ARGS NO_ARGS);

use MIME::Base64 ();
use Crypt::CBC ();
use Crypt::Blowfish ();
use Digest::MD5 ();
use Digest::CRC ();

use Apache2::ClickPath::_parse ();

our $VERSION = '1.901';
our $rcounter=int rand 0x10000;

my @directives=
  (
   {
    name         => 'ClickPathSessionPrefix',
    func         => __PACKAGE__ . '::ClickPathSessionPrefix',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathSessionPrefix string',
   },
   {
    name         => 'ClickPathMaxSessionAge',
    func         => __PACKAGE__ . '::ClickPathMaxSessionAge',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathMaxSessionAge time_in_seconds',
   },
   {
    name         => 'ClickPathUAExceptionsFile',
    func         => __PACKAGE__ . '::ClickPathUAExceptionsFile',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathUAExceptionsFile filename',
   },
   {
    name         => '<ClickPathUAExceptions',
    func         => __PACKAGE__ . '::ClickPathUAExceptions',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => '<ClickPathUAExceptions>
name1 regexp1
name2 regexp2
...
</ClickPathUAExceptions>',
   },
   {
    name         => '</ClickPathUAExceptions>',
    func         => __PACKAGE__ . '::ClickPathUAExceptionsEND',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::NO_ARGS,
    errmsg       => '</ClickPathUAExceptions> without <ClickPathUAExceptions>',
   },
   {
    name         => 'ClickPathFriendlySessionsFile',
    func         => __PACKAGE__ . '::ClickPathFriendlySessionsFile',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathFriendlySessionsFile filename',
   },
   {
    name         => '<ClickPathFriendlySessions',
    func         => __PACKAGE__ . '::ClickPathFriendlySessions',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => '<ClickPathFriendlySessions>
name1 regexp1
name2 regexp2
...
</ClickPathFriendlySessions>',
   },
   {
    name         => '</ClickPathFriendlySessions>',
    func         => __PACKAGE__ . '::ClickPathFriendlySessionsEND',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::NO_ARGS,
    errmsg       => '</ClickPathFriendlySessions> without <ClickPathFriendlySessions>',
   },
   {
    name         => 'ClickPathMachine',
    func         => __PACKAGE__ . '::ClickPathMachine',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => 'ClickPathMachine string',
   },
   {
    name         => '<ClickPathMachineTable',
    func         => __PACKAGE__ . '::ClickPathMachineTable',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => '<ClickPathMachineTable>
ip_ext1|name_ext1 [name1 [ip_int1|name_int1]]
ip_ext2|name_ext2 [name2 [ip_int1|name_int1]]
...
</ClickPathMachineTable>',
   },
   {
    name         => '</ClickPathMachineTable>',
    func         => __PACKAGE__ . '::ClickPathMachineTableEND',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::NO_ARGS,
    errmsg       => '</ClickPathMachineTable> without <ClickPathMachineTable>',
   },
   {
    name         => 'ClickPathSecret',
    func         => __PACKAGE__ . '::ClickPathSecret',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => 'ClickPathSecret string',
   },
   {
    name         => 'ClickPathSecretIV',
    func         => __PACKAGE__ . '::ClickPathSecretIV',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => 'ClickPathSecretIV string',
   },
  );
Apache2::Module::add(__PACKAGE__, \@directives);

sub ClickPathSessionPrefix {
  my($I, $parms, $arg)=@_;
  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathSessionPrefix"}=$arg;
}

sub ClickPathMaxSessionAge {
  my($I, $parms, $arg)=@_;
  die "ERROR: Argument to ClickPathMaxSessionAge must be a number\n"
    unless( $arg=~/^\d+$/ );
  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathMaxSessionAge"}=$arg;
}

sub ClickPathUAExceptionsFile {
  my($I, $parms, $arg)=@_;
  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathUAExceptionsFile"}=$arg;
}

sub ClickPathUAExceptions {
  my($I, $parms, @args)=@_;

  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathUAExceptions"}
    =Apache2::ClickPath::_parse::UAExceptions( $parms->directive->as_string );
}

sub ClickPathUAExceptionsEND {
  my($I, $parms, $arg)=@_;
  die "ERROR: </ClickPathUAExceptions> without <ClickPathUAExceptions>\n";
}

sub ClickPathFriendlySessionsFile {
  my($I, $parms, $arg)=@_;
  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathFriendlySessionsFile"}=$arg;
}

sub ClickPathFriendlySessions {
  my($I, $parms, @args)=@_;

  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  @{$I}{"ClickPathFriendlySessionsTable",
	"ClickPathFriendlySessionsReverse"}
    =Apache2::ClickPath::_parse::FriendlySessions( $parms->directive->as_string );
}

sub ClickPathFriendlySessionsEND {
  my($I, $parms, $arg)=@_;
  die "ERROR: </ClickPathFriendlySessions> without <ClickPathFriendlySessions>\n";
}

sub ClickPathMachine {
  my($I, $parms, $arg)=@_;
  die "ClickPathMachine [name] -- name consist of letters, digits or _\n"
    unless( $arg=~/^\w*$/ );

  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathMachine"}=$arg;
}

sub ClickPathMachineTable {
  my($I, $parms, @args)=@_;

  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  @{$I}{"ClickPathMachineTable", "ClickPathMachineReverse"}
    =Apache2::ClickPath::_parse::MachineTable( $parms->directive->as_string );
}

sub ClickPathMachineTableEND {
  my($I, $parms, $arg)=@_;
  die "ERROR: </ClickPathMachineTable> without <ClickPathMachineTable>\n";
}

sub postconfig {
  my($conf_pool, $log_pool, $temp_pool, $s) = @_;

  for( $s=Apache2::ServerUtil->server; $s; $s=$s->next ) {
    my $cfg=Apache2::Module::get_config( __PACKAGE__, $s );
    if( $cfg ) {
      if( exists $cfg->{ClickPathSecret} ) {
	$cfg->{ClickPathSecretIV}="abcd1234"
	  unless( length $cfg->{ClickPathSecretIV} );
      }
    }
  }

  return Apache2::Const::OK;
}

sub setPostConfigHandler {
  my $h=Apache2::ServerUtil->server->get_handlers('PerlPostConfigHandler')||[];
  unless( grep $_==\&postconfig, @{$h} ) {
    Apache2::ServerUtil->server->push_handlers
	('PerlPostConfigHandler'=>\&postconfig);
  }
}

sub ClickPathSecret {
  my($I, $parms, $arg)=@_;

  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathSecret"}=Apache2::ClickPath::_parse::Secret( $arg );
  setPostConfigHandler;
}

sub ClickPathSecretIV {
  my($I, $parms, $arg)=@_;

  $I=Apache2::Module::get_config( __PACKAGE__, $parms->server );
  $I->{"ClickPathSecretIV"}=substr( Digest::MD5::md5( $arg ), 0, 8 );
  setPostConfigHandler;
}

sub _get_ua_exc {
  my $cf=shift;

  ########### checking for UA Exceptions #################################
  # a ClickPathUAExceptionsFile directive overrides ClickPathUAExceptions
  # a ClickPathUAExceptionsFile is read every time it has been changed
  ########################################################################

  my ($fh, @stat);
  if( length $cf->{"ClickPathUAExceptionsFile"} and
      @stat=stat $cf->{"ClickPathUAExceptionsFile"} and
      $stat[9]>$cf->{"ClickPathUAExceptionsFile_read_time"} and
      open $fh, $cf->{"ClickPathUAExceptionsFile"} ) {
    $cf->{"ClickPathUAExceptionsFile_read_time"}=$stat[9];

    local $/;
    $cf->{"ClickPathUAExceptions_list"}
      =Apache2::ClickPath::_parse::UAExceptions( scalar( <$fh> ) );
    close $fh;
    return $cf->{"ClickPathUAExceptions_list"};
  } elsif( @stat and
	   $stat[9]<=$cf->{"ClickPathUAExceptionsFile_read_time"} ) {
    return $cf->{"ClickPathUAExceptions_list"};
  } else {
    return $cf->{"ClickPathUAExceptions"} || [];
  }
}

sub _get_friendly_session {
  my $cf=shift;

  ########### checking for Friendly Sessions #############################
  # a ClickPathFriendlySessionsFile directive overrides
  # ClickPathFriendlySessions
  # a ClickPathFriendlySessionsFile is read every time it has been changed
  ########################################################################

  my ($fh, @stat);
  if( length $cf->{"ClickPathFriendlySessionsFile"} and
      @stat=stat $cf->{"ClickPathFriendlySessionsFile"} and
      $stat[9]>$cf->{"ClickPathFriendlySessionsFile_read_time"} and
      open $fh, $cf->{"ClickPathFriendlySessionsFile"} ) {
    $cf->{"ClickPathFriendlySessionsFile_read_time"}=$stat[9];

    local $/;
    @{$cf}{"ClickPathFriendlySessionsFileTable",
	   "ClickPathFriendlySessionsFileReverse"}
      =Apache2::ClickPath::_parse::FriendlySessions( scalar( <$fh> ) );
    close $fh;
    return @{$cf}{"ClickPathFriendlySessionsFileTable",
		  "ClickPathFriendlySessionsFileReverse"};
  } elsif( @stat and
	   $stat[9]<=$cf->{"ClickPathFriendlySessionsFile_read_time"} ) {
    return @{$cf}{"ClickPathFriendlySessionsFileTable",
		  "ClickPathFriendlySessionsFileReverse"};
  } else {
    return @{$cf}{"ClickPathFriendlySessionsTable",
		  "ClickPathFriendlySessionsReverse"};
  }
}

sub handler {
  my $r=shift;

  my $cf=Apache2::Module::get_config(__PACKAGE__, $r->server);
  my $tag=$cf->{"ClickPathSessionPrefix"}
    or return Apache2::Const::DECLINED;
  $r->pnotes( __PACKAGE__.'::tag'=>$tag );

  #print STDERR "\n\n$$: request: ".$r->the_request, "\n";
  #print STDERR "$$: uri: ".$r->uri, "\n";

  my $file=$r->uri;

  # if an old session is used this will be reset
  # if an old session timed out (goto NEWSESSION) this will be incremented
  # giving in 2.
  # if simply a new session is created this is 1
  # then a pnote is set indicating this state. Thus the filter can
  # examin it.
  my $newsession=1;

  my $pr=$r->main || $r->prev;
  my $ref=$r->headers_in->{Referer} || "";

  if( $pr ) {
    my $session=$pr->subprocess_env( 'SESSION' );
    if( length $session ) {
      $r->subprocess_env( REMOTE_SESSION=>
			  $pr->subprocess_env( 'REMOTE_SESSION' ) );
      $r->subprocess_env( REMOTE_SESSION_HOST=>
			  $pr->subprocess_env( 'REMOTE_SESSION_HOST' ) );
      $r->subprocess_env( CGI_SESSION=>
			  $pr->subprocess_env( 'CGI_SESSION' ) );
      $r->subprocess_env( SESSION_START=>
			  $pr->subprocess_env( 'SESSION_START' ) );
      $r->subprocess_env( SESSION_AGE=>
			  $pr->subprocess_env( 'SESSION_AGE' ) );
      $r->subprocess_env('ClickPathMachineName'=>
			  $pr->subprocess_env( 'ClickPathMachineName' ) );
      my $store=$pr->subprocess_env( 'ClickPathMachineStore' );
      $r->subprocess_env('ClickPathMachineStore'=>$store) if( length $store );
      $r->subprocess_env( SESSION=>$session );
      $newsession=$pr->pnotes( __PACKAGE__.'::newsession' );
      $r->pnotes( __PACKAGE__.'::newsession'=>$newsession )
	if( $newsession );
      #print STDERR "$$: ReUsing session $session\n";
    }
  } elsif( $file=~s!^/+\Q$tag\E ( [^/]+ ) /!/!x ) {
    my $session=$1;

    #print STDERR "$$: Using old session $session\n";

    $ref=~s!^(\w+://[^/]+)/+\Q$tag\E[^/]+!$1!;
    $r->headers_in->{Referer}=$ref;

    $r->parse_uri( 'http://localhost'.$file.(length $r->args ? '?'.$r->args : '') );
    $r->subprocess_env( SESSION=>$session );
    $r->subprocess_env( CGI_SESSION=>'/'.$tag.$session );

    # decode session
    $session=~tr[N-Za-z0-9@\-,A-M][A-Za-z0-9@\-,];
    my @l=split /,/, $session, 3;
    # extract remote session
    my $rtab;
    (undef, $rtab)=_get_friendly_session( $cf );
    $rtab={} unless( $rtab );
    if( @l==3 and exists $rtab->{$l[1]} ) {
      my %h=('**'=>'*', '*!'=>'!', '*.'=>'=', '!'=>"\n", '*x'=>'/', '*y'=>'#');
      $l[2]=~s/(\*[*!.xy]|!)/$h{$1}/ge;
      $r->subprocess_env( REMOTE_SESSION=>$l[2] );
      $r->subprocess_env( REMOTE_SESSION_HOST=>$rtab->{$l[1]} );
    } else {
      $r->subprocess_env->unset( 'REMOTE_SESSION' );
      $r->subprocess_env->unset( 'REMOTE_SESSION_HOST' );
    }
    # extract session start time
    $l[0]=~tr[@\-][+/];
    @l=split /:/, $l[0], 2;	# $l[0]: IP Addr, $l[1]: session
    if( exists $cf->{ClickPathMachineReverse} ) {
      if( exists $cf->{ClickPathMachineReverse}->{$l[0]} ) {
	$r->subprocess_env('ClickPathMachineName'=>$l[0]);
	$r->subprocess_env('ClickPathMachineStore'=>
			   $cf->{"ClickPathMachineReverse"}->{$l[0]}->[1])
	  if( length $cf->{"ClickPathMachineReverse"}->{$l[0]}->[1] );
      } else {
	$r->log->notice( "Caught invalid session: Unknown Machine name '$l[0]'" );
	$r->subprocess_env( INVALID_SESSION=>$r->subprocess_env( 'SESSION' ) );
	$r->subprocess_env->unset( 'SESSION' );
	$r->subprocess_env->unset( 'CGI_SESSION' );
	$r->subprocess_env->unset( 'REMOTE_SESSION' );
	$r->subprocess_env->unset( 'REMOTE_SESSION_HOST' );
	$newsession++;
	goto NEWSESSION;
      }
    }

    my $len4=do {use integer; (length( $l[1] )+3)/4;};
    $len4*=4;
    $l[1]=MIME::Base64::decode_base64( $l[1].('='x($len4-length( $l[1] ))) );

    if( exists $cf->{ClickPathSecret} ) {
      my $crypt=Crypt::CBC->new(
				-key=>$cf->{ClickPathSecret},
				-keysize=>length($cf->{ClickPathSecret}),
				-cipher=>'Crypt::Blowfish',
				-literal_key=>1,
				-header=>'none',
				-iv=>$cf->{ClickPathSecretIV},
			       );
      $l[1]=$crypt->decrypt( $l[1] );
    }

    my $crc;
    if( length( $l[1] ) ) {
      $crc=Digest::CRC::crc8( substr( $l[1], 1 ) );
    } else {
      $crc=-1;			# invalid value
    }

    @l=unpack "CNNnN", $l[1];

    my $maxage=$cf->{"ClickPathMaxSessionAge"};
    my $age=$r->request_time-$l[1];
    if( $crc!=$l[0] or ($maxage>0 and $age>$maxage) or $age<0 ) {
      if( $crc!=$l[0] ) {
	$r->log->notice( "Caught invalid session: CRC checksum failed" );
      } else {
	$r->subprocess_env( EXPIRED_SESSION=>$r->subprocess_env( 'SESSION' ) );
      }
      $r->subprocess_env->unset( 'SESSION' );
      $r->subprocess_env->unset( 'CGI_SESSION' );
      $r->subprocess_env->unset( 'REMOTE_SESSION' );
      $r->subprocess_env->unset( 'REMOTE_SESSION_HOST' );
      $r->subprocess_env->unset( 'ClickPathMachineName' );
      $r->subprocess_env->unset( 'ClickPathMachineStore' );
      $newsession++;
      goto NEWSESSION;
    } else {
      $r->subprocess_env( SESSION_START=>$l[1] );
      $r->subprocess_env( SESSION_AGE=>$r->request_time-$l[1] );
    }
    $newsession=0;
  } else {
    $ref=~s!^(\w+://[^/]+)/\Q$tag\E[^/]+!$1!;
    $r->headers_in->{Referer}=$ref;

  NEWSESSION:
    my $ua=$r->headers_in->{'User-Agent'};
    my $disable='';

    foreach my $el (@{_get_ua_exc( $cf )}) {
      if( $ua=~/$el->[1]/ ) {
	$disable=$el->[0];
	last;
      }
    }

    if( length $disable ) {
      $r->subprocess_env( SESSION=>$disable );
      $r->subprocess_env( SESSION_START=>$r->request_time );
      $r->subprocess_env( SESSION_AGE=>0 );
      $r->subprocess_env->unset( 'CGI_SESSION' );
      $r->subprocess_env->unset( 'REMOTE_SESSION' );
      $r->subprocess_env->unset( 'REMOTE_SESSION_HOST' );
    } else {
      if( $ref=~s!^\w+://([^/]+)/+!/! ) {
	my $host=$1;
	my ($tab)=_get_friendly_session( $cf );
	my $el=($tab || {})->{$host};

	if( $el ) {
	  local $_;
	  my $args;
	  ($ref, $args)=split /\?/, $ref, 2;
	  my @uri=split m!/+!, $ref;
	  my %args=map {
	    my ($k, $v)=split /=/;
	    length( $k ) ? ($k=>$v) : ();
	  } split /[;&]/, $args;

	  my @remote_session=map {
	    $_->[0] eq 'uri' ? $uri[$_->[1]] : $_->[1].'='.$args{$_->[1]};
	  } @{$el->[0]};

	  my $remote_session=join( "\n", @remote_session );
	  $r->subprocess_env( REMOTE_SESSION=>$remote_session );
	  $r->subprocess_env( REMOTE_SESSION_HOST=>$host );

	  my %h=('*'=>'**', '!'=>'*!', '='=>'*.', "\n"=>'!',
		 '/'=>'*x', '#'=>'*y');
	  $remote_session=~s^([*!=\n/#])^$h{$1}^ge;

	  $ref=$el->[1].','.$remote_session;
	} else {
	  $r->subprocess_env->unset( 'REMOTE_SESSION' );
	  $r->subprocess_env->unset( 'REMOTE_SESSION_HOST' );
	  $ref='';
	}
      } else {
	$r->subprocess_env->unset( 'REMOTE_SESSION' );
	$r->subprocess_env->unset( 'REMOTE_SESSION_HOST' );
	$ref='';
      }

      my $session_ip=undef;
      if( exists $cf->{"ClickPathMachine"} ) {
	$session_ip=$cf->{"ClickPathMachine"};
      } else {
	my $serverip=$r->connection->local_addr->ip_get;

	if( exists $cf->{"ClickPathMachineTable"} and
	    exists $cf->{"ClickPathMachineTable"}->{$serverip} ) {
	  $session_ip=$cf->{"ClickPathMachineTable"}->{$serverip}->[0];
	  $r->subprocess_env('ClickPathMachineName'=>
			     $cf->{"ClickPathMachineTable"}->{$serverip}->[0]);
	  $r->subprocess_env('ClickPathMachineStore'=>
			     $cf->{"ClickPathMachineTable"}->{$serverip}->[1])
	    if( length $cf->{"ClickPathMachineTable"}->{$serverip}->[1] );
	} else {
	  $r->server->log->error( "Cannot find myself ($serverip) in ClickPathMachineTable" )
	    if( exists $cf->{"ClickPathMachineTable"} );
	  $session_ip=MIME::Base64::encode_base64
	    ( pack( 'C*', split /\./, $serverip, 4 ), '' );
	  $session_ip=~s/={0,2}$//;
	}
      }
      my $session=pack( 'NNnN',
			$r->request_time, $$, $rcounter++,
			$r->connection->id );
      $rcounter%=2**16;

      $session=pack( 'C', Digest::CRC::crc8( $session ) ).$session;

      if( exists $cf->{ClickPathSecret} ) {
	my $crypt=Crypt::CBC->new(
				  -key=>$cf->{ClickPathSecret},
				  -keysize=>length($cf->{ClickPathSecret}),
				  -cipher=>'Crypt::Blowfish',
				  -literal_key=>1,
				  -header=>'none',
				  -iv=>$cf->{ClickPathSecretIV},
				 );
	$session=$crypt->encrypt( $session );
      }
      $session=MIME::Base64::encode_base64( $session, '' );
      $session=~s/={0,2}$//;

      $session=$session_ip.':'.$session;
      $session=~tr[+/][@\-];
      $session.=','.$ref;

      $session=~tr[A-Za-z0-9@\-,][N-Za-z0-9@\-,A-M];
      $r->subprocess_env( SESSION=>$session );
      $r->subprocess_env( SESSION_START=>$r->request_time );
      $r->subprocess_env( SESSION_AGE=>0 );
      $r->subprocess_env( CGI_SESSION=>'/'.$tag.$session );
      $r->pnotes( __PACKAGE__.'::newsession'=>$newsession );
      #print STDERR "$$: Using new session $session\n";
    }
  }

  return Apache2::Const::DECLINED
}

sub OutputFilter {
  my $f=shift;
  my $sess;
  my $host;
  my $sprefix;
  my $context;
  my ($re0, $re1, $re2, $re3, $re4, $the_request);


  unless ($f->ctx) {
    my $r=$f->r;

    if( $r->main ) {
      # skip filtering for subrequests
      $f->remove;
      return Apache2::Const::DECLINED;
    }

    $sess=$r->subprocess_env('CGI_SESSION');
    unless( defined $sess and length $sess ) {
      $f->remove;
      return Apache2::Const::DECLINED;
    }

    $sprefix=$r->pnotes( __PACKAGE__.'::tag' );
    unless( defined $sprefix and length $sprefix ) {
      $f->remove;
      return Apache2::Const::DECLINED;
    }

    $host=$r->headers_in->{Host};

    my $newsession=$r->pnotes( __PACKAGE__.'::newsession' );
    if( $newsession ) {
      $the_request=$r->the_request;
      $the_request=~s/^\s*\w+\s+//;
      $the_request=~s![^/]*[\s?].*$!!;
      #print STDERR "the_request=$the_request\n";
      if( $newsession==2 ) {
	# cut off an timed out old session if given
	$the_request=~s!^/+\Q$sprefix\E[^/]+!!;
	#print STDERR "the_request(2)=$the_request\n";
      }

      my $re=qr,^(https?://\Q$host\E)?(?!\w+:)(?:/\Q$sprefix\E[^/]+)*(.),i;
      $r->headers_out->{Location}=~s!$re!$2 eq '/'
                                         ? $1.$sess.$2
                                         : $1.$sess.$the_request.$2
                                        !e
	if( exists $r->headers_out->{Location} );
      $r->err_headers_out->{Location}=~s!$re!$2 eq '/'
	                                     ? $1.$sess.$2
                                             : $1.$sess.$the_request.$2
                                            !e
	if( exists $r->err_headers_out->{Location} );

      $re=qr,^(\s*\d+\s*;\s*url\s*=\s*(?:https?://\Q$host\E)?)(?!\w+:)(?:/\Q$sprefix\E[^/]+)*(.),i;
      $r->headers_out->{Refresh}=~s!$re!$2 eq '/'
                                        ? $1.$sess.$2
                                        : $1.$sess.$the_request.$2
                                       !e
	if( exists $r->headers_out->{Refresh} );
      $r->err_headers_out->{Refresh}=~s!$re!$2 eq '/'
                                            ? $1.$sess.$2
                                            : $1.$sess.$the_request.$2
                                           !e
	if( exists $r->err_headers_out->{Refresh} );
    } else {
      $the_request="";

      my $re=qr!^(https?://\Q$host\E)?(?:/\Q$sprefix\E[^/]+)*/!i;
      $r->headers_out->{Location}=~s!$re!$1$sess/!
	if( exists $r->headers_out->{Location} );
      $r->err_headers_out->{Location}=~s!$re!$1$sess/!
	if( exists $r->err_headers_out->{Location} );

      $re=qr!^(\s*\d+\s*;\s*url\s*=\s*(?:https?://\Q$host\E)?)(?:/\Q$sprefix\E[^/]+)*/!i;
      $r->headers_out->{Refresh}=~s!$re!$1$sess/!
	if( exists $r->headers_out->{Refresh} );
      $r->err_headers_out->{Refresh}=~s!$re!$1$sess/!
	if( exists $r->err_headers_out->{Refresh} );
    }

    # we only process HTML documents but Location: and Refresh: headers
    # are processed anyway
    unless( $r->content_type =~ m!text/html!i ) {
      $f->remove;
      return Apache2::Const::DECLINED;
    }

    if( $r->pnotes( __PACKAGE__.'::newsession' ) ) {
      # Wenn die Session neu ist, dann muessen auch relative Links
      # reaendert werden
      $re1=qr,(			# $1 start
	       <\s*a(?:rea)?\s+	# <a> start
	       .*?		# evtl. target=...
               \bhref\s*=\s*	# href=
	       (["'])		# " oder ': Das ist $2 oder \2 (siehe unten)
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# Das alles ist in $1
	      (?:/+\Q$sprefix\E[^/]+)?
	      (			# $3 start
	       (?!(?:\w+:|\043)).*? # ein beliebiger nicht mit http:// o.ae.
				#   beginnender String (moeglichst kurz)
	       \2		# das schließende Quote: $2
	      )			# $3 ende
	     ,xi;

    # nach dieser regexp enthält entweder $2 oder $7 "http-equiv=refresh"
    # $sess darf nur eingefügt werden, wenn eins von beiden nicht leer ist.
      $re2=qr,(			# $1 start         "<meta ..."
	       <\s*meta\s+	# <meta> start
	       [^>]*?		# evtl. anderes Zeug
	      )			# $1 ende

	      (			# $2 start         optional "http-equiv=..."
	       \bhttp-equiv\s*=\s*(["']?)refresh\3
	       [^>]*?		# evtl. anderes Zeug
	      )?		# $2 ende

	      (			# $4 start         "content=" + opening quote
               \bcontent\s*=\s*
	       (["'])		# " oder ': Das ist \5 (siehe unten)
               \s*\d+\s*;\s*url\s*=\s*
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# $4 ende

	      (?:/+\Q$sprefix\E[^/]+)?

	      (			# $6 start         URL + closing quote
	       (?!\w+:).*?	# ein beliebiger nicht mit http:// o.ae.
				#   beginnender String (so kurz wie möglich)
	       \5		# das schließende Quote: $5
	      )			# $6 ende

	      (			# $7 start         optional "http-equiv=..."
	       [^>]*?		# evtl. anderes Zeug
	       \bhttp-equiv\s*=\s*(["']?)refresh\8
	      )?		# $7 ende
	     ,ix;

      $re3=qr,(			# $1 start
	       <\s*form\s+	# <a> start
	       [^>]*?		# evtl. target=...
               \baction\s*=\s*	# href=
	       (["'])		# " oder ': Das ist $2 oder \2 (siehe unten)
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# Das alles ist in $1
	      (?:/+\Q$sprefix\E[^/]+)?
	      (			# $3 start
	       (?!\w+:).*?	# ein beliebiger nicht mit http:// o.ae.
				#   beginnender String (moeglichst kurz)
	       \2		# das schließende Quote: $2
	      )			# $3 ende
	     ,xi;

      $re4=qr,(			# $1 start
	       <\s*i?frame\s+	# <a> start
	       [^>]*?		# evtl. target=...
               \bsrc\s*=\s*	# href=
	       (["'])		# " oder ': Das ist $2 oder \2 (siehe unten)
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# Das alles ist in $1
	      (?:/+\Q$sprefix\E[^/]+)?
	      (			# $3 start
	       (?!\w+:).*?	# ein beliebiger nicht mit http:// o.ae.
				#   beginnender String (moeglichst kurz)
	       \2		# das schließende Quote: $2
	      )			# $3 ende
	     ,xi;
    } else {
      $re1=qr,(			# $1 start
	       <\s*a(?:rea)?\s+	# <a> start
	       .*?		# evtl. target=...
               \bhref\s*=\s*	# href=
	       (["'])		# " oder ': Das ist $2 oder \2 (siehe unten)
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# Das alles ist in $1
	      (?:/+\Q$sprefix\E[^/]+)?
	      (			# $3 start
	       /.*?		# ein beliebiger mit /
				#   beginnender String (moeglichst kurz)
	       \2		# das schließende Quote: $2
	      )			# $3 ende
	     ,xi;

    # nach dieser regexp enthält entweder $2 oder $7 "http-equiv=refresh"
    # $sess darf nur eingefügt werden, wenn eins von beiden nicht leer ist.
      $re2=qr,(			# $1 start         "<meta ..."
	       <\s*meta\s+	# <meta> start
	       [^>]*?		# evtl. anderes Zeug
	      )			# $1 ende

	      (			# $2 start         optional "http-equiv=..."
	       \bhttp-equiv\s*=\s*(["']?)refresh\3
	       [^>]*?		# evtl. anderes Zeug
	      )?		# $2 ende

	      (			# $4 start         "content=" + opening quote
               \bcontent\s*=\s*
	       (["'])		# " oder ': Das ist \5 (siehe unten)
               \s*\d+\s*;\s*url\s*=\s*
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# $4 ende

	      (?:/+\Q$sprefix\E[^/]+)?

	      (			# $6 start         URL + closing quote
	       /.*?		# ein beliebiger mit /
				#   beginnender String (so kurz wie möglich)
	       \5		# das schließende Quote: $5
	      )			# $6 ende

	      (			# $7 start         optional "http-equiv=..."
	       [^>]*?		# evtl. anderes Zeug
	       \bhttp-equiv\s*=\s*(["']?)refresh\8
	      )?		# $7 ende
	     ,ix;

      $re3=qr,(			# $1 start
	       <\s*form\s+	# <a> start
	       [^>]*?		# evtl. target=...
               \baction\s*=\s*	# href=
	       (["'])		# " oder ': Das ist $2 oder \2 (siehe unten)
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# Das alles ist in $1
	      (?:/+\Q$sprefix\E[^/]+)?
	      (			# $3 start
	       /.*?		# ein beliebiger /
				#   beginnender String (moeglichst kurz)
	       \2		# das schließende Quote: $2
	      )			# $3 ende
	     ,xi;

      $re4=qr,(			# $1 start
	       <\s*i?frame\s+	# <a> start
	       [^>]*?		# evtl. target=...
               \bsrc\s*=\s*	# href=
	       (["'])		# " oder ': Das ist $2 oder \2 (siehe unten)
	       (?:https?://\Q$host\E)?	# evtl. Host
	      )			# Das alles ist in $1
	      (?:/+\Q$sprefix\E[^/]+)?
	      (			# $3 start
	       /.*?		# ein beliebiger /
				#   beginnender String (moeglichst kurz)
	       \2		# das schließende Quote: $2
	      )			# $3 ende
	     ,xi;
    }

    # store the configuration
    $f->ctx( +{
	        extra => '',
		sess  => $sess,
		req   => $the_request,
		re    => qr/(<[^>]*)$/,
		re1   => $re1,
		re2   => $re2,
		re3   => $re3,
		re4   => $re4,
	      } );

    # output filters that alter content are responsible for removing
    # the Content-Length header, but we only need to do this once.
    $r->headers_out->unset('Content-Length');
  }

  # retrieve the filter context, which was set up on the first invocation
  $context=$f->ctx;

  $sess=$context->{sess};
  $re1=$context->{re1};
  $re2=$context->{re2};
  $re3=$context->{re3};
  $re4=$context->{re4};
  $re0=$context->{re};
  $the_request=$context->{req};

  # now, filter the content
  while( $f->read(my $buffer, 1024) ) {
    # prepend any tags leftover from the last buffer or invocation
    $buffer = $context->{extra} . $buffer if( length $context->{extra} );

    # if our buffer ends in a split tag ('<strong' for example)
    # save processing the tag for later
    if (($context->{extra}) = $buffer =~ m/$re0/) {
      $buffer = substr($buffer, 0, -length($context->{extra}));
    }

    if( length $the_request ) {
      $buffer=~s!$re1!(substr($3, 0, 1) eq '/')
                      ? $1.$sess.$3
                      : $1.$sess.$the_request.$3
                     !ge;
      $buffer=~s!$re2!(length($2) or length($7))
                      ? ((substr($6, 0, 1) eq '/')
			 ? $1.$2.$4.$sess.$6.$7
                         : $1.$2.$4.$sess.$the_request.$6.$7
                        )
		      : $1.$2.$4.$6.$7
                     !ge;
      $buffer=~s!$re3!(substr($3, 0, 1) eq '/')
                      ? $1.$sess.$3
                      : $1.$sess.$the_request.$3
                     !ge;
      $buffer=~s!$re4!(substr($3, 0, 1) eq '/')
                      ? $1.$sess.$3
                      : $1.$sess.$the_request.$3
                     !ge;
    } else {
      $buffer=~s!$re1!$1$sess$3!g;
      $buffer=~s!$re2!(length($2) or length($7))
                      ? $1.$2.$4.$sess.$6.$7
		      : $1.$2.$4.$6.$7
                     !ge;
      $buffer=~s!$re3!$1$sess$3!g;
      $buffer=~s!$re4!$1$sess$3!g;
    }

    $f->print($buffer);
  }

  if ($f->seen_eos) {
    # we've seen the end of the data stream

    # Hier muss keine Ersetzung durchgeführt werden, da $context->{extra}
    # für richtige HTML Dokumente leer sein muss.

    # print any leftover data
    $f->print($context->{extra}) if( length $context->{extra} );
  }

  return Apache2::Const::OK;
}

1;

__END__

=head1 NAME

Apache2::ClickPath - Apache WEB Server User Tracking

=head1 SYNOPSIS

 LoadModule perl_module ".../mod_perl.so"
 PerlLoadModule Apache2::ClickPath
 <ClickPathUAExceptions>
   Google     Googlebot
   MSN        msnbot
   Mirago     HeinrichderMiragoRobot
   Yahoo      Yahoo-MMCrawler
   Seekbot    Seekbot
   Picsearch  psbot
   Globalspec Ocelli
   Naver      NaverBot
   Turnitin   TurnitinBot
   dir.com    Pompos
   search.ch  search\.ch
   IBM        http://www\.almaden\.ibm\.com/cs/crawler/
 </ClickPathUAExceptions>
 ClickPathSessionPrefix "-S:"
 ClickPathMaxSessionAge 18000
 PerlTransHandler Apache2::ClickPath
 PerlOutputFilterHandler Apache2::ClickPath::OutputFilter
 LogFormat "%h %l %u %t \"%m %U%q %H\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" \"%{SESSION}e\""

=head1 ABSTRACT

C<Apache2::ClickPath> can be used to track user activity on your web server
and gather click streams. Unlike mod_usertrack it does not use a cookie.
Instead the session identifier is transferred as the first part on an URI.

Furthermore, in conjunction with a load balancer it can be used to direct
all requests belonging to a session to the same server.

=head1 DESCRIPTION

C<Apache2::ClickPath> adds a PerlTransHandler and an output filter to
Apache's request cycle. The transhandler inspects the requested URI to
decide if an existing session is used or a new one has to be created.

=head2 The Translation Handler

If the requested URI starts with a slash followed by the session prefix
(see L</"B<ClickPathSessionPrefix>"> below) the rest of the URI up to the next
slash is treated as session identifier. If for example the requested URI
is C</-S:s9NNNd:doBAYNNNiaNQOtNNNNNM/index.html> then assuming
C<ClickPathSessionPrefix> is set to C<-S:> the session identifier would be
C<s9NNNd:doBAYNNNiaNQOtNNNNNM>.

Starting with version 1.8 a checksum is included in the session ID. Further,
some parts of the information contained in the session including the checksum
can be encrypted. This both makes a valid session ID hard to guess. If an
invalid session ID is detected an error message is printed to the ErrorLog.
So, a log watching agent can be set up to catch frequent abuses.

If no session identifier is found a new one is created.

Then the session prefix and identifier are stripped from the current URI.
Also a potentially existing session is stripped from the incoming C<Referer>
header.

There are several exceptions to this scheme. Even if the incoming URI
contains a session a new one is created if it is too old. This is done
to prevent link collections, bookmarks or search engines generating
endless click streams.

If the incoming C<UserAgent> header matches a configurable regular
expression neither session identifier is generated nor output filtering
is done. That way search engine crawlers will not create sessions and
links to your site remain readable (without the session stuff).

The translation handler sets the following environment variables that
can be used in CGI programms or template systems (eg. SSI):

=over 4

=item B<SESSION>

the session identifier itself. In the example above
C<s9NNNd:doBAYNNNiaNQOtNNNNNM> is assigned. If the C<UserAgent> prevents
session generation the name of the matching regular expression is
assigned, (see L</"B<ClickPathUAExceptions>">).

=item B<CGI_SESSION>

the session prefix + the session identifier. In the example above
C</-S:s9NNNd:doBAYNNNiaNQOtNNNNNM> is assigned. If the C<UserAgent> prevents
session generation C<CGI_SESSION> is empty.

=item B<SESSION_START>

the request time of the request starting a session in seconds since 1/1/1970.

=item B<CGI_SESSION_AGE>

the session age in seconds, i.e. CURRENT_TIME - SESSION_START.

=item B<REMOTE_SESSION>

in case a friendly session was caught this variable contains it, see below.

=item B<REMOTE_SESSION_HOST>

in case a friendly session was caught this variable contains the host it
belongs to, see below.

=item B<EXPIRED_SESSION>

if a session has expired and a new one has been created the old session is
stored here.

=item B<INVALID_SESSION>

when a C<ClickPathMachineTable> is used a check is accomplished to ensure the
session was created by on of the machines of the cluster. If it was not
a message is written to the C<ErrorLog>, a new one is created and the invalid
session is written to this environment variable.

=item B<ClickPathMachineName>

when a C<ClickPathMachineTable> is used this variable contains the name of
the machine where the session has been created.

=item B<ClickPathMachineStore>

when a C<ClickPathMachineTable> is used this variable contains the address of
the session store in terms of C<Apache2::ClickPath::Store>.

=back

=head2 The Output Filter

The output filter is entirely skipped if the translation handler had not
set the C<CGI_SESSION> environment variable.

It prepends the session prefix and identifier to any C<Location> an
C<Refresh> output headers.

If the output C<Content-Type> is C<text/html> the body part is modified.
In this case the filter patches the following HTML tags:

=over 4

=item B<E<lt>a ... href="LINK" ...E<gt>>

=item B<E<lt>area ... href="LINK" ...E<gt>>

=item B<E<lt>form ... action="LINK" ...E<gt>>

=item B<E<lt>frame ... src="LINK" ...E<gt>>

=item B<E<lt>iframe ... src="LINK" ...E<gt>>

=item B<E<lt>meta ... http-equiv="refresh" ... content="N; URL=LINK" ...E<gt>>

In all cases if C<LINK> starts with a slash the current value of
C<CGI_SESSION> is prepended. If C<LINK> starts with
C<http://HOST/> (or https:) where C<HOST> matches the incoming C<Host>
header C<CGI_SESSION> is inserted right after C<HOST>. If C<LINK> is
relative and the incoming request URI had contained a session then C<LINK>
is left unmodified. Otherwize it is converted to a link starting with a slash
and C<CGI_SESSION> is prepended.

=back

=head2 Configuration Directives

All directives are valid only in I<server config> or I<virtual host> contexts.

=over 4

=item B<ClickPathSessionPrefix>

specifies the session prefix without the leading slash.

=item B<ClickPathMaxSessionAge>

if a session gets older than this value (in seconds) a new one is created
instead of continuing the old. Values of about a few hours should be good,
eg. 18000 = 5 h.

=item B<ClickPathMachine>

set this machine's name. The name is used with load balancers. Each
machine of a farm is assigned a unique name. That makes session identifiers
unique across the farm.

If this directive is omitted a compressed form (6 Bytes) of the server's
IP address is used. Thus the session is unique across the Internet.

In environments with only one server this directive can be given without
an argument. Then an empty name is used and the session is unique on
the server.

If possible use short or empty names. It saves bandwidth.

A name consists of letters, digits and underscores (_).

The generated session identifier contains the name in a slightly scrambled
form to slightly hide your infrastructure.

=item B<ClickPathMachineTable>

this is a container directive like C<< <Location> >> or C<< <Directory> >>.
It defines a 3-column table specifying the layout of your WEB-server cluster.
Each line consists of max. 3 fields. The 1st one is the IP address or name
the server is listening on. Second comes an optional machine name in in terms
of the C<ClickPathMachine> directive. If it is omitted each machine is
assigned it's line number within the table as name. This means that each
machine in a cluster must run with exactly the same table regarding the
line order. The optional 3rd field specifies the address where the session
store is accessible (see L<Apache2::ClickPath::Store> for more information.

=item B<ClickPathUAExceptions>

this is a container directive like C<< <Location> >> or C<< <Directory> >>.
The container content lines consist of a name and a regular expression.
For example

 1   <ClickPathUAExceptions>
 2     Google     Googlebot
 3     MSN        (?i:msnbot)
 4   </ClickPathUAExceptions>

Line 2 maps each C<UserAgent> containing the word C<Googlebot> to the name
C<Google>. Now if a request comes in with an C<UserAgent> header containing
C<Googlebot> no session is generated. Instead the environment variable
C<SESSION> is set to C<Google> and C<CGI_SESSION> is emtpy.

=item B<ClickPathUAExceptionsFile>

this directive takes a filename as argument. The file's syntax and semantic
are the same as for C<ClickPathUAExceptions>. The file is reread every time
is has been changed avoiding server restarts after configuration changes at
the prize of memory consumption.

=item B<ClickPathFriendlySessions>

this is also a container directive. It describes friendly sessions. What is
a friendly session? Well, suppose you have a WEB shop running on
C<shop.tld.org> and your company site running on C<www.tld.org>. The shop
does it's own URL based session management but there are links from the
shop to the company site and back. Wouldn't it be nice if a customer once
he has stepped into the shop could click links to the company without loosing
the shopping session? This is where friendly sessions come in.

Since your shop's session management is URL based the C<Referer> seen
by C<www.tld.org> will be something like

 https://shop.tld.org/cgi-bin/shop.pl?session=sdafsgr;clusterid=25

(if session and clusterid are passed as CGI parameters) or

 https://shop.tld.org/C:25/S:sdafsgr/cgi-bin/shop.pl

(if session and clusterid are passed as URL parts) or something mixed.

Assuming that C<clusterid> and C<session> both identify the session on
C<shop.tld.org> C<Apache2::ClickPath> can extract them, encode them in it's
own session and place them in environment variables.

Each line in the C<ClickPathFriendlySessions> section decribes one friendly
site. The line consists of the friendly hostname, a list of URL parts or
CGI parameters identifying the friendly session and an optional short name
for this friend, eg:

 shop.tld.org uri(1) param(session) shop

This means sessions at C<shop.tld.org> are identified by the combination
of 1st URL part after the leading slash (/) and a CGI parameter named
C<session>.

If now a request comes in with a C<Referer> of
C<http://shop.tld.org/25/bin/shop.pl?action=showbasket;session=213>
the C<REMOTE_SESSION> environment variable will contain 2 lines:

 25
 session=213

Their order is determined by the order of C<uri()> and C<param()> statements
in the configuration section between the hostname and the short name. The
C<REMOTE_SESSION_HOST> environment variable will contain the host name the
session belongs to.

Now a CGI script or a modperl handler or something similar can fetch the
environment and build links back to C<shop.tld.org>. Instead of directly
linking back to the shop your links then point to that script. The script
then puts out an appropriate redirect.

=item B<ClickPathFriendlySessionsFile>

this directive takes a filename as argument. The file's syntax and semantic
are the same as for C<ClickPathFriendlySessions>. The file is reread every time
is has been changed avoiding server restarts after configuration changes at
the prize of memory consumption.

=item B<ClickPathSecret>

=item B<ClickPathSecretIV>

if you want to run something like a shop with our session identifiers they
must be unguessable. That means knowing a valid session ID it must be
difficult to guess another one. With these directives a significant part
of the session ID is encrypted with Blowfish in the cipher block chaining
mode thus making the session ID unguessable. C<ClickPathSecret> specifies
the key, C<ClickPathSecretIV> the initialization vector.

C<ClickPathSecretIV> is a simple string of arbitrary length. The first 8
bytes of its MD5 digest are used as initialization vector. If omitted the
string C<abcd1234> is the IV.

C<ClickPathSecret> is given as C<http:>, C<https:>, C<file:> or C<data:> URL.
Thus the secret can be stored directly as data-URL in the httpd.conf or in a
separate file on the local disk or on a possibly secured server. To enable
all modes of accessing the WEB the http(s)-URL syntax is a bit extented.
Maybe you have already used C<http://user:password@server.tld/...>. Many
browsers allow this syntax to specify a username and password for HTTP
authentication. But how about proxies, SSL-authentication etc? Well, add
another colon (:) after the password and append a semicolon (;) delimited
list of C<key=value> pairs. The special characters (@:;\) can be quoted
with a backslash (\). In fact, all characters can be quoted. Thus, C<\a> and
C<a> produce the same string C<a>.

The following keys are defined:

=over 2

=item B<https_proxy>

=item B<https_proxy_username>

=item B<https_proxy_password>

=item B<https_version>

=item B<https_cert_file>

=item B<https_key_file>

=item B<https_ca_file>

=item B<https_ca_dir>

=item B<https_pkcs12_file>

=item B<https_pkcs12_password>

their meaning is defined in L<Crypt::SSLeay>.

=item B<http_proxy>

=item B<http_proxy_username>

=item B<http_proxy_password>

these are passed to L<LWP::UserAgent>.

Remember a HTTP-proxy is accessed with the GET or POST, ... methods whereas
a HTTPS-proxy is accessed with CONNECT. Don't mix them, see L<Crypt::SSLeay>.

=back

B<Examples>

 ClickPathSecret https://john:a\@b\;c\::https_ca_file=/my/ca.pem@secrethost.tld/bin/secret.pl?host=me

fetches the secret from C<https://secrethost.tdl/bin/secret.pl?host=me>
using C<john> as username and C<a@b;c:> as password. The server certificate
of secrethost.tld is verified against the CA certificate found in
C</my/ca.pem>.

 ClickPathSecret https://::https_pkcs12_file=/my/john.p12;https_pkcs12_password=a\@b\;c\:;https_ca_file=/my/ca.pem@secrethost.tld/bin/secret.pl?host=me

fetches the secret again from C<https://secrethost.tdl/bin/secret.pl?host=me>
using C</my/john.p12> as client certificate with C<a@b;c:> as password.
The server certificate of secrethost.tld is again verified against the CA
certificate found in C</my/ca.pem>.

 ClickPathSecret data:,password:very%20secret%20password

here a data-URL is used that produces the content
C<password:very secret password>.

The URL's content is fetched by L<LWP::UserAgent> once at server startup.

Its content defines the secret either in binary form or as string of
hexadecimal characters or as a password. If it starts with C<binary:> the
rest of the content is taken as is as the key. If it starts with C<hex:>
C<pack( 'H*', $arg )> is used to convert it to binary. If it starts with
C<password:> or with neither of them the MD5 digest of the rest of the
content is used as secret.

The Blowfish algorithm allows up to 56 bytes as secret. In hex and binary
mode the starting 56 bytes are used. You can specify more bytes but they
won't be regarded. In password mode the MD5 algorithm produces
16 bytes long secret.

=back

=head2 Working with a load balancer

Most load balancers are able to map a request to a particular machine
based on a part of the request URI. They look for a prefix followed
by a given number of characters or until a suffix is found. The string
between identifies the machine to route the request to.

The name set with C<ClickPathMachine> can be used by a load balancer.
It is immediately following the session prefix and finished by a single
colon. The default name is always 6 bytes long.

=head2 Logging

The most important part of user tracking and clickstreams is logging.
With C<Apache2::ClickPath> many request URIs contain an initial session part.
Thus, for logfile analyzers most requests are unique which leads to
useless results. Normally Apache's common logfile format starts with

 %h %l %u %t \"%r\"

C<%r> stands for I<the request>. It is the first line a browser sends to
a server. For use with C<Apache2::ClickPath> C<%r> is better changed to
C<%m %U%q %H>. Since C<Apache2::ClickPath> strips the session part from
the current URI C<%U> appears without the session. With this modification
logfile analyzers will produce meaningful results again.

The session can be logged as C<%{SESSION}e> at end of a logfile line.

=head2 A word about proxies

Depending on your content and your users community HTTP proxies can
serve a significant part of your traffic. With C<Apache2::ClickPath>
almost all request have to be served by your server.

=head2 Debugging

Sometimes it is useful to know the information encoded in a session
identifier. This is why L<Apache2::ClickPath::Decode> exists.

=head1 SEE ALSO

L<Apache2::ClickPath::Store>
L<Apache2::ClickPath::StoreClient>
L<Apache2::ClickPath::Decode>
L<http://perl.apache.org>,
L<http://httpd.apache.org>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
