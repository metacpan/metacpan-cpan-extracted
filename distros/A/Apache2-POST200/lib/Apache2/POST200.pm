package Apache2::POST200;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::RequestIO;
use Apache2::ServerUtil;
use Apache2::Connection;
use Apache2::CmdParms;
use Apache2::Module;
use Apache2::Filter;
use APR::Brigade;
use APR::Bucket;
use APR::Table;
use Apache2::Const -compile=>qw{OK DECLINED
				TAKE1 TAKE12 TAKE123 TAKE3 FLAG OR_ALL
				M_POST M_GET
				HTTP_OK REDIRECT NOT_FOUND};

use MIME::Base64 ();
use Crypt::CBC ();
use Crypt::Blowfish ();
use Digest::MD5 ();
use Digest::CRC ();
use DBI;

our $VERSION = '0.05';
my $rcounter=0;

# these 2 values were once read from /dev/random on my box
my $default_key=("tFS\343x\314\357uh\212W\177+#\332\0q\317S\231\321\316\270H".
		 "\252\205\313\264\357LT\16h\362\36\354cK\317\362\e\253`[8".
		 "\211\365\347\217:\f1\224\321L*");
my $default_iv="P\363\32\310\24\340\265\373";

my $msg302=<<'EOF';
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>302 Found</title>
</head><body>
<h1>Found</h1>
<p>The document has moved <a href="%{location}">here</a>.</p>
</body></html>
EOF

my @directives=
  (
   {
    name         => 'Post200Storage',
    func         => __PACKAGE__ . '::config123',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::TAKE123,
    errmsg       => 'Post200Storage DBI-DSN [USER] [PASSWORD]',
    cmd_data     => 'storage',
   },
   {
    name         => 'Post200Table',
    func         => __PACKAGE__ . '::config123',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::TAKE3,
    errmsg       => 'Post200Table TABLENAME KEY-COLUMN VALUE-COLUMN',
    cmd_data     => 'table',
   },
   {
    name         => 'Post200Label',
    func         => __PACKAGE__ . '::config123',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'Post200Label marker (default: "-redirect-")',
    cmd_data     => 'location',
   },
   {
    name         => 'Post200Secret',
    func         => __PACKAGE__ . '::config123',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::TAKE12,
    errmsg       => 'Post200Secret SECRET [INITVECTOR]',
    cmd_data     => 'secret',
   },
   {
    name         => 'Post200IpCheck',
    func         => __PACKAGE__ . '::config123',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::FLAG,
    errmsg       => 'Post200IpCheck On|Off (default: On)',
    cmd_data     => 'checkip',
   },
   {
    name         => 'Post200DataBlockSize',
    func         => __PACKAGE__ . '::config123',
    req_override => Apache2::Const::OR_ALL,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'Post200DataBlockSize bytes',
    cmd_data     => 'blocksize',
   },
  );
Apache2::Module::add(__PACKAGE__, \@directives);

my %extra_config=
  (
   secret=>sub {
     unless( length $_[0]->[1] ) {
       $_[0]->[1]='hex:'.unpack( 'H*', $default_iv );
     }
     map {
       if( /^hex:(.+)/ ) {
	 $_=pack( 'H*', $_ );
       } elsif( /^b64:(.+)/ ) {
	 $_=MIME::Base64::decode_base64( $_ );
       } else {
	 $_=Digest::MD5::md5( $_ );
       }
       $_.=$_ while( length($_)<56 );
       $_=substr( $_, 0, 56 ) if( length($_)>56 );
     } @{$_[0]};
     $_[1]=substr( $_[1], 0, 8 );
     @{$_[0]};
   },
  );

sub config123 {
  my($I, $parms, @args)=@_;
  $I->{$parms->info}=[@args[0..2]];
  $extra_config{$parms->info}->( $I->{$parms->info} )
    if( exists $extra_config{$parms->info} );
}

sub DIR_CREATE {
  my ($class, $parms)=@_;
  return bless {
		secret=>[$default_key, $default_iv],
		location=>['-redirect-'],
		checkip=>['1'],
	       } => $class;
}

sub DIR_MERGE {
  my ($base, $add) = @_;

  my %new=(%$base, %$add);

  return bless \%new, ref($base);
}

sub Response {
  my $r=shift;

  my $cf=Apache2::Module::get_config(__PACKAGE__, $r->server,
				     $r->per_dir_config);

  return Apache2::Const::NOT_FOUND
    unless( $r->method_number==Apache2::Const::M_GET and
	    length( $r->args )==32+length($cf->{location}->[0]) );

  my $crypt=Crypt::CBC->new(
			    -key=>$cf->{secret}->[0],
			    -keysize=>length($cf->{secret}->[0]),
			    -cipher=>'Crypt::Blowfish',
			    -literal_key=>1,
			    -header=>'none',
			    -iv=>$cf->{secret}->[1],
			   );

  my $session=$r->args;
  $session=~s/^\Q$cf->{location}->[0]\E//;
  my $db_key=$session;
  $session=~tr[@\-][+/];
  $session=$crypt->decrypt( MIME::Base64::decode_base64( $session ) );

  my $crc=Digest::CRC::crc8( substr( $session, 1 ) );

  my ($crc2, undef, undef, undef, undef, @ip)=unpack 'CNNnNC8', $session;

  unless( $crc==$crc2 ) {
    $r->warn( __PACKAGE__.": CRC checksum error" );
    return Apache2::Const::NOT_FOUND;
  }

  if( $cf->{checkip}->[0] and join('.', @ip[0..3]) ne $r->connection->remote_ip ) {
    $r->warn( __PACKAGE__.": IP check failed" );
    return Apache2::Const::NOT_FOUND;
  }

  my $dbh=DBI->connect( @{$cf->{storage}}[0..2],
			{
			 AutoCommit=>1,
			 PrintError=>0,
			 RaiseError=>0,
			} )
    or do {
      $r->warn( "Cannot connect to $cf->{storage}->[0]: $DBI::errstr" );
      return Apache2::Const::NOT_FOUND;
    };

  my $stmt=$dbh->prepare("SELECT $cf->{table}->[1], $cf->{table}->[2] ".
			 "FROM $cf->{table}->[0] ".
			 "WHERE $cf->{table}->[1] LIKE ? ".
			 "ORDER BY $cf->{table}->[1] ASC")
    or do {
      $r->warn( "Cannot prepare SELECT statement: ".$dbh->errstr );
      $dbh->disconnect;
      return Apache2::Const::NOT_FOUND;
    };

  $session=$db_key;
  $stmt->execute( $session.':%' )
    or do {
      $r->warn( "Cannot execute SELECT statement: ".$dbh->errstr );
      $dbh->disconnect;
      return Apache2::Const::NOT_FOUND;
    };

  my $i=1;
  while( my $l=$stmt->fetchrow_arrayref ) {
    if( $l->[0] eq sprintf( '%s:%08d', $session, $i ) ) {
      if( $i==1 ) {		# headers_out
	$r->headers_out->clear;
	foreach my $line (split /\n/, $l->[1]) {
	  $r->headers_out->add(split /: /, $line, 2)
	    if( length $line );
	}
      } elsif( $i==2 ) {	# err_headers_out
	$r->err_headers_out->clear;
	foreach my $line (split /\n/, $l->[1]) {
	  $r->err_headers_out->add(split /: /, $line, 2)
	    if( length $line );
	}
      } elsif( $i==3 ) {	# content-type
	$r->content_type($l->[1]);
      } else {			# data
	$r->print( $l->[1] );
      }
    } else {
      $r->warn( "Read incomplete data from database" );
    }
    $i++;
  }

  return Apache2::Const::OK;
}

sub Filter {
  my ($f, $bb) = @_;

  unless( $f->ctx ) {
    my $r=$f->r;

    my $cf=Apache2::Module::get_config(__PACKAGE__, $r->server,
				       $r->per_dir_config);

    if( $r->main or		# skip filtering for subrequests
	$r->method_number!=Apache2::Const::M_POST or
	!(do{no warnings 'numeric';$r->status_line==Apache2::Const::HTTP_OK} or
	  !length( $r->status_line ) && $r->status==Apache2::Const::HTTP_OK) or
	!exists($cf->{storage}) or
	lc $cf->{storage}->[0] eq 'none' or
	!exists($cf->{table}) or
	lc $cf->{table}->[0] eq 'none') {
      $f->remove;
      return Apache2::Const::DECLINED;
    }

    my $session=pack( 'NNnNC8',
		      $r->request_time, $$, $rcounter++,
		      $r->connection->id,
		      split( /\./, $r->connection->remote_ip, 4 ),
		      split( /\./, $r->connection->local_ip, 4 ),
		    );
    $rcounter%=2**16;

    $session=pack( 'C', Digest::CRC::crc8( $session ) ).$session;

    my $crypt=Crypt::CBC->new(
			      -key=>$cf->{secret}->[0],
			      -keysize=>length($cf->{secret}->[0]),
			      -cipher=>'Crypt::Blowfish',
			      -literal_key=>1,
			      -header=>'none',
			      -iv=>$cf->{secret}->[1],
			     );

    $session=MIME::Base64::encode_base64( $crypt->encrypt( $session ), '' );

    # The Base64 Alphabet consists of [A-Za-z0-9+/] where each character
    # represents 6 bits (0-64) plus the equal sign (=) as padding character
    # To get a valid URI part [+/] must be avoided since they have special
    # meaning in URIs. We change them to [@-].
    # Thus, the resulting alphabet contains neither [/#?+] nor [_%]. The
    # former are dangerous in URIs the latter in SQL LIKE statements.
    $session=~tr[+/][@\-];

    my $dbh=DBI->connect( @{$cf->{storage}}[0..2],
			  {
			   AutoCommit=>1,
			   PrintError=>0,
			   RaiseError=>0,
			  } )
      or do {
	$r->warn( "Cannot connect to $cf->{storage}->[0]: $DBI::errstr" );
	$f->remove;
	return Apache2::Const::DECLINED;
      };

    $dbh->begin_work;

    my $headers='';
    $r->headers_out->do(sub{$headers.="$_[0]: $_[1]\n";1;});
    my $err_headers='';
    $r->err_headers_out->do(sub{$err_headers.="$_[0]: $_[1]\n";1;});

    # check if the table exists and can be written
    my $stmt=$dbh->prepare("INSERT INTO $cf->{table}->[0] ".
			   "($cf->{table}->[1], $cf->{table}->[2]) ".
			   "VALUES (?, ?)")
      or do {
	$r->warn( "Cannot prepare INSERT statement: ".$dbh->errstr );
	$dbh->disconnect;
	$f->remove;
	return Apache2::Const::DECLINED;
      };

    $stmt->execute( $session.':00000001', $headers) &&
    $stmt->execute( $session.':00000002', $err_headers) &&
    $stmt->execute( $session.':00000003', $r->content_type)
      or do {
	$r->warn( "Cannot insert into $cf->{table}->[0]: ".$dbh->errstr );
	$dbh->disconnect;
	$f->remove;
	return Apache2::Const::DECLINED;
      };

    my $loc=$r->the_request;	# don't count on $r->uri or $r->unparsed_uri
				# they may have been changed
    $loc=~s/^\w+\s//;		# strip "POST " at head
    $loc=~s/[?#\s].*//;		# strip any parameters, anchor and "HTTP/1.1"
    unless( $loc=~m!^https?://! ) { # can already be for proxy requests
      my $proto=(($r->can('is_https') && $r->is_https or # using Apache::SSLLookup
		  $r->connection->can('is_https') && $r->connection->is_https or # Apache2::ModSSL
		  $r->subprocess_env('HTTPS'))
		 ? 'https'
		 : 'http');
      my $port=':'.$r->get_server_port;
      $port='' if( $port eq ':80' && $proto eq 'http' or
		   $port eq ':443' && $proto eq 'https' );
      $loc=$proto.'://'.$r->get_server_name.$port.$loc;
    }
    $loc.='?'.$cf->{location}->[0].$session;

    my $msg=$msg302;
    $msg=~s/%{location}/$loc/g;

    $r->status( Apache2::Const::REDIRECT );
    $r->status_line( Apache2::RequestUtil::get_status_line(Apache2::Const::REDIRECT) );
    $r->headers_out->clear;
    $r->err_headers_out->clear;
    $r->content_type( 'text/html; charset=iso-8859-1' );
    $r->headers_out->{'Content-Length'}=length $msg;
    $r->headers_out->{'Location'}=$loc;

    $f->ctx( {
	      dbh=>$dbh,
	      stmt=>$stmt,
	      session=>$session,
	      nr=>4,
	      msg=>$msg,
	      bs=>$cf->{blocksize}->[0],
	     } );
  }

  my $ctx=$f->ctx;
  while (my $e = $bb->first) {
    if( $e->is_eos ) {
      $ctx->{dbh}->commit;
      $e->remove;
      my $bbnew=APR::Brigade->new( $f->c->pool, $f->c->bucket_alloc );
      $bbnew->insert_tail(APR::Bucket->new( $bbnew->bucket_alloc, $ctx->{msg} ));
      $bbnew->insert_tail($e);
      $f->next->pass_brigade( $bbnew );
    } else {
      $e->read(my $buf);
      if( length $buf ) {
	if( $ctx->{bs}>0 ) {
	  my ($i, $len, $bs)=(0, length( $buf ), $ctx->{bs});
	  while( $i<$len ) {
	    $ctx->{stmt}->execute
	      ( sprintf( '%s:%08d', $ctx->{session}, $ctx->{nr}++ ),
		substr( $buf, $i, $bs ) );
	    $i+=$bs;
	  }
	} else {
	  $ctx->{stmt}->execute
	    ( sprintf( '%s:%08d', $ctx->{session}, $ctx->{nr}++ ), $buf );
	}
      }
      $e->delete;
    }
  }

  return Apache2::Const::OK;
}

1;
