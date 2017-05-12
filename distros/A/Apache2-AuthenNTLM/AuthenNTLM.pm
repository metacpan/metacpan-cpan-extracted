###################################################################################
#
#   Apache2::AuthenNTLM - Copyright (c) 2002 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: AuthenNTLM.pm,v 1.28 2002/11/12 05:31:50 richter Exp $
#
###################################################################################


package Apache2::AuthenNTLM ;

use strict ;
use vars qw{$cache $VERSION %msgflags1 %msgflags2 %msgflags3 %invflags1 %invflags2 %invflags3 $addr $port $debug} ;

$VERSION = 0.02 ;

$debug = 0 ;

$cache = undef ;

use MIME::Base64 () ;
use Authen::Smb 0.95 ;
use Socket ;

%msgflags1 = ( 0x01 => "NEGOTIATE_UNICODE",
	       0x02 => "NEGOTIATE_OEM",
	       0x04 => "REQUEST_TARGET",
	       0x10 => "NEGOTIATE_SIGN",
	       0x20 => "NEGOTIATE_SEAL",
	       0x80 => "NEGOTAITE_LM_KEY",
	       );

%msgflags2 = ( 0x02 => "NEGOTIATE_NTLM",
	       0x40 => "NEGOTIATE_LOCAL_CALL",
	       0x80 => "NEGOTIATE_ALWAYS_SIGN",
	       );

%msgflags3 = ( 0x01 => "TARGET_TYPE_DOMAIN",
	       0x02 => "TARGET_TYPE_SERVER",
	       );

%invflags1 = ( "NEGOTIATE_UNICODE" => 0x01,
	       "NEGOTIATE_OEM"     => 0x02,
	       "REQUEST_TARGET"    => 0x04,
	       "NEGOTIATE_SIGN"    => 0x10,
	       "NEGOTIATE_SEAL"    => 0x20,
	       "NEGOTIATE_LM_KEY"  => 0x80,
	       );

%invflags2 = ( "NEGOTIATE_NTLM"        => 0x02,
	       "NEGOTIATE_LOCAL_CALL"  => 0x40,
	       "NEGOTIATE_ALWAYS_SIGN" => 0x80,
	       );

%invflags3 = ( "TARGET_TYPE_DOMAIN" => 0x01,
	       "TARGET_TYPE_SERVER" => 0x02,
	       );
     
############################################
# here is where we start the new code....
############################################
use mod_perl2 ;

use Apache2::Access ;
use Apache2::Connection ;
use Apache2::Log ;
use Apache2::RequestRec ;
use Apache2::RequestUtil ;
use Apache2::RequestIO ;
use APR::Table ;
use APR::SockAddr ;
use Apache2::Const -compile => qw(HTTP_UNAUTHORIZED HTTP_INTERNAL_SERVER_ERROR DECLINED HTTP_FORBIDDEN OK) ;

##################### end modperl code ######################

sub get_config
{
    my ($self, $r) = @_ ;

    return if ($self -> {smbpdc}) ; # config already setup

    $debug = $r -> dir_config ('ntlmdebug') || 0 ;
    $debug = $self -> {debug} = lc($debug) eq 'on'?1:($debug+0) ;

    my @config = $r -> dir_config -> get ('ntdomain') ;

    foreach (@config)
    {
        my ($domain, $pdc, $bdc) = split /\s+/ ;
        $domain = lc ($domain) ;
        $self -> {smbpdc}{$domain} = $pdc ;
        $self -> {smbbdc}{$domain} = $bdc ;
        print STDERR "[$$] AuthenNTLM: Config Domain = $domain  pdc = $pdc  bdc = $bdc\n" if ($debug) ; 
    }

    $self -> {defaultdomain} = $r -> dir_config ('defaultdomain') || '' ;
    $self -> {fallbackdomain} = $r -> dir_config ('fallbackdomain') || '' ;
    $self -> {cacheuser} = $r -> dir_config ('cacheuser') || '0' ;
    $self -> {authtype} = $r -> auth_type || 'ntlm,basic' ;
    $self -> {authname} = $r -> auth_name || ''  ;
    my $autho = $r -> dir_config ('ntlmauthoritative') || 'on' ;
    $self -> {ntlmauthoritative} = lc($autho) eq 'on' || $autho == 1?1:0 ;
    $autho = $r -> dir_config ('basicauthoritative') || 'on' ;
    $self -> {basicauthoritative} = lc($autho) eq 'on' || $autho == 1?1:0 ;
	
    $self -> {authntlm} = 0 ;
    $self -> {authbasic} = 0 ;

    $self -> {authntlm} = 1 if ($self -> {authtype} =~ /(^|,)ntlm($|,)/i) ;
    $self -> {authbasic} = 1 if ($self -> {authtype} =~ /(^|,)basic($|,)/i) ;

    $self -> {semkey} = $r -> dir_config ('ntlmsemkey') ;
    $self -> {semkey} = 23754 if (!defined ($self -> {semkey})) ;
    $self -> {semtimeout} = $r -> dir_config ('ntlmsemtimeout') ;
    $self -> {semtimeout} = 2 if (!defined ($self -> {semtimeout})) ;
    $self -> {splitdomainprefix} = $r -> dir_config ('splitdomainprefix') || '' ;

    if ($debug)
    {
	print STDERR "[$$] AuthenNTLM: Config Default Domain = $self->{defaultdomain}\n"  ; 
	print STDERR "[$$] AuthenNTLM: Config Fallback Domain = $self->{fallbackdomain}\n"  ; 
	print STDERR "[$$] AuthenNTLM: Config AuthType = $self->{authtype} AuthName = $self->{authname}\n"  ; 
	print STDERR "[$$] AuthenNTLM: Config Auth NTLM = $self->{authntlm} Auth Basic = $self->{authbasic}\n"  ; 
	print STDERR "[$$] AuthenNTLM: Config NTLMAuthoritative = " .  ($self -> {ntlmauthoritative}?'on':'off') . "  BasicAuthoritative = " . ($self -> {basicauthoritative}?'on':'off') . "\n"  ; 
	print STDERR "[$$] AuthenNTLM: Config Semaphore key = $self->{semkey} timeout = $self->{semtimeout}\n"  ; 
	print STDERR "[$$] AuthenNTLM: Config SplitDomainPrefix = $self->{splitdomainprefix}\n"  ; 
    }
}


sub get_nonce
{
    my ($self, $r) = @_ ;

    # reuse connection if possible
    if ($self -> {nonce} && $self -> {ok})
    {
        print STDERR "[$$] AuthenNTLM: Returning cached nonce\n" if ($debug) ;
        return $self -> {nonce}
    }

    # this is not the real nonce!
    # we just need to preallocate some space (8 bytes) where Authen::Smb::Valid_User_Connect
    # puts the real nonce
    my $nonce = '12345678' ;
    $self -> {domain} = $self -> {fallbackdomain}
    if ($self -> {fallbackdomain} && !($self -> {smbpdc}{lc ($self -> {domain})}));
    my $domain  = lc ($self -> {domain}) ;
    my $pdc     = $self -> {smbpdc}{$domain} ;
    my $bdc     = $self -> {smbbdc}{$domain} ;

    if (!$pdc)
    {
	$r->log_error("No PDC and no fallbackdomain given for domain $domain") ;
	return '' ;
    }

    $self -> {nonce} = undef ;

    print STDERR "[$$] AuthenNTLM: Connect to pdc = $pdc bdc = $bdc domain = $domain\n" if ($debug) ;

    # smb aborts any connection that where no user is logged on as soon as somebody
    # tries to open another one. So we have to make sure two request, do not start
    # two auth cycles at the same time. To avoid a hang of the whole server we wrap it with
    # a small timeout
    if ($self->{semkey})
    {
        eval
	{
            local $SIG{ALRM} = sub { print STDERR "[$$] AuthenNTLM: timed out" 
					 . "while waiting for lock (key = $self->{semkey})\n";  die ; };

            alarm $self -> {semtimeout} ;
            $self -> {lock} = Apache2::AuthenNTLM::Lock -> lock ($self->{semkey}, $debug) ;
            alarm 0;
	};
    }

    $self -> {smbhandle} = Authen::Smb::Valid_User_Connect ($pdc, $bdc, $domain, $nonce) ;
    
    print STDERR "[$$] AuthenNTLM: verify handle $self->{username} smbhandle == $self->{smbhandle} \n" if ($debug) ;
    
    if (!$self -> {smbhandle})
    {
	$r->log_error("Connect to SMB Server failed (pdc = $pdc bdc = $bdc domain = $domain error = "
		      . Authen::Smb::SMBlib_errno . '/' . Authen::Smb::SMBlib_SMB_Error . ") for " . 
		      $r -> uri) ;
	return undef ;
    }

    return $self -> {nonce} = $nonce ;
}



sub verify_user
{
    my ($self, $r) = @_ ;

    if (!$self -> {smbhandle})
    {
	$self -> {lock} = undef ; # reset lock in case anything has gone wrong
	$r->log_error("SMB Server connection not open in state 3 for " . $r -> uri) ;
	return ;
    }

    my $rc ;

    print STDERR "[$$] AuthenNTLM: Verify user $self->{username} via smb server\n" if ($debug) ;

    if ($self -> {basic})
    {
	$rc = Authen::Smb::Valid_User_Auth ($self -> {smbhandle}, $self->{username}, $self -> {password}) ;
    }
    else
    {
	$rc = Authen::Smb::Valid_User_Auth ($self -> {smbhandle}, $self->{username}, $self -> {usernthash}, 1, $self->{userdomain}) ;
    }
    my $errno  = Authen::Smb::SMBlib_errno ;
    my $smberr = Authen::Smb::SMBlib_SMB_Error ;
    Authen::Smb::Valid_User_Disconnect ($self -> {smbhandle}) if ($self -> {smbhandle}) ;
    $self -> {smbhandle} = undef ;
    $self -> {lock}      = undef ;

    if ($rc == &Authen::Smb::NTV_LOGON_ERROR)
    {
	$r->log_error("Wrong password/user (rc=$rc/$errno/$smberr): $self->{userdomain}\\$self->{username} for " . $r -> uri) ;
	print STDERR "[$$] AuthenNTLM: rc = $rc  ntlmhash = $self->{usernthash}\n" if ($debug) ; 
	return ;
    }

    if ($rc)
    {
	$r->log_reason("SMB Server error $rc/$errno/$smberr for " . $r -> uri) ;
	return ;
    }

    return 1 ;
}


sub map_user
{
    my ($self, $r) = @_ ;

    if ($self -> {splitdomainprefix} == 1) 
    {
	return lc("$self->{username}") ;
    }
    else 
    {
	return lc("$self->{userdomain}\\$self->{username}") ;
    }
}



sub substr_unicode 
{
    my ($data, $off,  $len) = @_ ;
    
    my $i = 0 ; 
    my $end = $off + $len ;
    my $result = '' ;
    for ($i = $off ; $i < $end ; $i += 2)
    {# for now we simply ignore high order byte
	 $result .=  substr ($data, $i,  1) ;
    }

    return $result ;
}


sub get_msg_data
{
    my ($self, $r) = @_ ;

    my $auth_line =  $r->headers_in->{$r->proxyreq ? 'Proxy-Authorization' : 'Authorization'} ;
                    
    $self -> {ntlm}  = 0 ;
    $self -> {basic} = 0 ;
    if ($debug)
    {
        $auth_line =~ /^(.*?)\s+/ ;
        my $type = $1 ;
        print STDERR "[$$] AuthenNTLM: Authorization Header " 
	    . (defined($auth_line)?($debug > 1?$auth_line:$type):'<not given>') . "\n" if ($debug) ;
    }
    if ($self -> {authntlm} && ($auth_line =~ /^NTLM\s+(.*?)$/i))
    {
	$self -> {ntlm} = 1 ;
    }
    elsif ($self -> {authbasic} && ($auth_line =~ /^Basic\s+(.*?)$/i))
    {
	$self -> {basic}  = 1 ;
    }
    else
    {
	return undef ;
    }

    my $data = MIME::Base64::decode($1) ;

    if ($debug > 1)
    {
        my @out ;
        for (my $i = 0; $i < length($data); $i++)
	{
            push @out, unpack('C', substr($data, $i, 1)) ;
	}
        print STDERR "[$$] AuthenNTLM: Got: " . join (' ', @out). "\n" ;
    }

    return $data ;
}



sub get_msg
{
    my ($self, $r) = @_ ;

    my $data = $self -> get_msg_data ($r) ;
    return undef if (!$data) ;

    if ($self -> {ntlm})
    {
        my ($protocol, $type) = unpack ('Z8C', $data) ;
        return $self -> get_msg1 ($r, $data) if ($type == 1) ;
        return $self -> get_msg3 ($r, $data) if ($type == 3) ;
        return $type ;
    }
    elsif ($self -> {basic})
    {
        return $self -> get_basic ($r, $data) ;
    }
    return undef ;
}



sub get_msg1
{
    my ($self, $r, $data) = @_ ;
    
    my ($protocol, $type, $zero, $flags1, $flags2, $zero2, $dom_len, $x1, $dom_off, $x2, $host_len, $x3, $host_off, $x4) = unpack ('Z8Ca3CCa2vvvvvvvv', $data) ;
    my $host   = $host_off?substr ($data, $host_off, $host_len):'' ;
    my $domain = $dom_off?substr ($data, $dom_off,  $dom_len):'' ;

    $self -> {domain} = $dom_len?$domain:$self -> {defaultdomain} ;
    $self -> {host}   = $host_len?$host:'' ;

    $self -> {accept_unicode} = $flags1 & 0x01;

    if ($debug)
    {
        my @flag1str;
        foreach my $i ( sort keys %msgflags1 ) 
	{
            push @flag1str, $msgflags1{ $i } if $flags1 & $i;
	}
        my $flag1str = join( ",", @flag1str );

        my @flag2str;
        foreach my $i ( sort keys %msgflags2 ) 
	{
            push @flag2str, $msgflags2{ $i } if $flags2 & $i;
	}
	my $flag2str = join( ",", @flag2str );
    
        print STDERR "[$$] AuthenNTLM: protocol=$protocol, type=$type, flags1=$flags1($flag1str), " 
	    . "flags2=$flags2($flag2str), domain length=$dom_len, domain offset=$dom_off, "
	    . "host length=$host_len, host offset=$host_off, host=$host, domain=$domain\n" ;
    }


    return $type ;
}


sub set_msg2
{
    my ($self, $r, $nonce) = @_ ;

    my $charencoding = $self->{ accept_unicode } ? $invflags1{ NEGOTIATE_UNICODE } : $invflags1{ NEGOTIATE_OEM };

    my $flags2 = $invflags2{ NEGOTIATE_ALWAYS_SIGN } | $invflags2{ NEGOTIATE_NTLM };

    my $data = pack ('Z8Ca7vvCCa2a8a8', 'NTLMSSP', 2, '', 40, 0, $charencoding,  $flags2, '', $nonce, '') ;

    my $header = 'NTLM '. MIME::Base64::encode($data, '') ;

    if ($debug)
    {
	if ($debug > 1)
	{
            my @out ;
            for (my $i = 0; $i < length($data); $i++)
	    {
                push @out, unpack('C', substr($data, $i, 1)) ;
	    }
            print STDERR "[$$] AuthenNTLM: Send: " . join (' ', @out). "\n" ;
	}
        print STDERR "[$$] AuthenNTLM: charencoding = $charencoding\n";
        print STDERR "[$$] AuthenNTLM: flags2 = $flags2\n";
        print STDERR "[$$] AuthenNTLM: nonce=$nonce\n" if ($debug > 1);
        print STDERR "[$$] AuthenNTLM: Send header: " . ($debug > 1?$header:'NTLM ...') . "\n" ;
    }

    return $header;
}


sub get_msg3
{
    my ($self, $r, $data) = @_ ;

    my ($protocol, $type, $zero, 
        $lm_len,  $l1, $lm_off,
        $nt_len,   $l3, $nt_off,
        $dom_len, $x1, $dom_off,
        $user_len, $x3, $user_off,
        $host_len, $x5, $host_off,
        $msg_len
        ) = unpack ('Z8Ca3vvVvvVvvVvvVvvVv', $data) ;
    
    my $lm     = $lm_off  ? substr ($data, $lm_off,   $lm_len):'' ;
    my $nt     = $nt_off  ? substr ($data, $nt_off,   $nt_len):'' ;
    my $user   = $user_off ? ($self->{accept_unicode} ? substr_unicode ($data, $user_off, $user_len) : substr( $data, $user_off, $user_len ) ) :'' ;
    my $host   = $host_off ? ($self->{accept_unicode} ? substr_unicode ($data, $host_off, $host_len) : substr( $data, $host_off, $host_len ) ) :'' ;
    my $domain = $dom_off ? ($self->{accept_unicode} ? substr_unicode ($data, $dom_off,  $dom_len) : substr( $data, $dom_off, $dom_len ) ) :'' ;

    $self -> {userdomain} = $dom_len?$domain:$self -> {defaultdomain} ;
    $self -> {username}   = $user ;
    $self -> {usernthash} = $nt_len ? $nt : $lm;

    if ($debug)
    {
        print STDERR "[$$] AuthenNTLM: protocol=$protocol, type=$type, user=$user, "
	    . "host=$host, domain=$domain, msg_len=$msg_len\n" ;
    }


    return $type ;
}


sub get_basic
{
    my ($self, $r, $data) = @_ ;

    ($self -> {username}, $self -> {password}) = split (/:/, $data)  ;

    my ($domain, $username) = split (/\\|\//, $self -> {username}) ;
    if ($username)
    {
	$self -> {domain} = $domain ;
	$self -> {username} = $username ;
    }
    else
    {
	$self -> {domain} = $self -> {defaultdomain} ;
    }

    $self -> {userdomain} = $self -> {domain} ; 

    if ($debug)
    {
        print STDERR "[$$] AuthenNTLM: basic auth username = $self->{domain}\\$self->{username}\n" ;
    }

    return -1 ;
}


sub DESTROY
{
    my ($self) = @_ ;

    Authen::Smb::Valid_User_Disconnect ($self -> {smbhandle}) if ($self -> {smbhandle}) ;
}


sub handler : method
{
    my ($class, $r) = @_ ;
    my $type ;
    my $nonce = '' ;
    my $self ;
    my $conn = $r -> connection ;
    my $connhdr = $r -> headers_in -> {'Connection'} ;

    my $fh = select (STDERR) ;
    $| = 1 ;
    select ($fh) ;

    my $addr = $conn -> remote_addr -> ip_get ;
    my $port = $conn -> remote_addr -> port ;
    
    print STDERR "[$$] AuthenNTLM: Start NTLM Authen handler pid = $$, connection = " 
	. "$$conn conn_http_hdr = $connhdr  main = " . ($r -> main) 
	. " cuser = " . $r -> user . ' remote_ip = ' . $conn -> remote_ip 
	. " remote_port = " . unpack('n', $port) . ' remote_host = <' 
	. $conn -> remote_host . "> version = $VERSION "
	. "smbhandle = " . $self -> {smbhandle} . "\n" if ($debug) ;

    # we cannot attach our object to the connection record. Since in
    # Apache 1.3 there is only one connection at a time per process
    # we can cache our object and check if the connection has changed.
    # The check is done by slightly changing the remote_host member, which
    # persists as long as the connection does
    # This has to be reworked to work with Apache 2.0
    my $table;
    $table = $conn->notes();
    if (ref ($cache) ne $class || $$conn != $cache->{connectionid} || ($table->get('status') ne "AUTHSTARTED"))
    {
	$table->add('status','AUTHSTARTED');
	$conn->notes($table);
	$self = {connectionid => $$conn } ;
	bless $self, $class ;
	$cache = $self ;
	print STDERR "[$$] AuthenNTLM: Setup new object\n" if ($debug) ;
    }
    else
    {
	$self = $cache ;
	print STDERR "[$$] AuthenNTLM: Object exists user = $self->{userdomain}\\$self->{username}\n" if ($debug) ;
	
	if ($self -> {ok})
	{
	    $r -> user($self->{mappedusername}) ;
	    
	    # we accept the user because we are on the same connection
	    $type = $self -> get_msg ($r);
	    my $content_len = $r->headers_in->{'content-length'} ;
	    my $method      = $r -> method ;
	    print STDERR "[$$] AuthenNTLM: Same connection pid = $$, connection = $$conn cuser = " .
		$r -> user . ' ip = ' . $conn -> remote_ip . ' method = ' . 
		$method . ' Content-Length = ' .
		$content_len . ' type = ' . $type . "\n" if ($debug) ;
	     
	    # IE (5.5, 6.0, probably others) can send a type 1 message 
	    # after authenticating on the same connection.  This is a
	    # problem for POST messages, because IE also sends a
	    # "Content-length: 0" with no POST data.
	    if ($method eq 'GET' || $method eq 'HEAD' || $method eq 'OPTION' || $method eq 'DELETE' ||
		$content_len > 0 || $type == 3)
	    {
		print STDERR "[$$] AuthenNTLM: OK because same connection\n" if ($debug) ;
		return Apache2::Const::OK ;
	    }
	}
    }
    # end of if statement

    $self -> get_config ($r) ;
    $type = $self -> get_msg ($r) if (!$type) ;
    
    if (!$type)
    {
        $self -> {lock} = undef ; # reset lock in case anything has gone wrong
        if (!$self->{ntlmauthoritative})
	{ # see if we have any header
            my $auth_line = $r -> headers_in->{$r->proxyreq ? 'Proxy-Authorization' : 'Authorization'} ;
            if ($auth_line)
	    {
		$r->log_error('Bad/Missing NTLM Authorization Header for ' . $r->uri 
			      . '; DECLINEing because we are not authoritative' ) ;
		return Apache2::Const::DECLINED ;
	    }
	}

	$r->log_error('Bad/Missing NTLM/Basic Authorization Header for ' . $r->uri) ;

	my $hdr = $r -> err_headers_out ;
        $hdr -> add ($r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate', 'NTLM') if ($self -> {authntlm}) ;
        $hdr -> add ($r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate', 'Basic realm="' 
		     . $self -> {authname} . '"') if ($self -> {authbasic}) ;
	# $r->discard_request_body ;
        return Apache2::Const::HTTP_UNAUTHORIZED ;
    }

    if ($type == 1)
    {
	print STDERR "[$$] handler type == 1 \n" if ($debug) ;
        my $nonce = $self -> get_nonce ($r) ;
        if (!$nonce)
	{
            $self -> {lock} = undef ; # reset lock in case anything has gone wrong
            $r->log_error("Cannot get nonce") ;
            # $r->discard_request_body ;
	    return $self->{ntlmauthoritative} ? (defined($nonce)) 
		? Apache2::Const::HTTP_FORBIDDEN 
		: Apache2::Const::HTTP_INTERNAL_SERVER_ERROR
		: Apache2::Const::DECLINED ;
	}

        my $header1 = $self -> set_msg2 ($r, $nonce) ;
	my $hdr = $r -> err_headers_out ;
        $hdr -> add ($r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate', $header1) if ($self -> {authntlm}) ;
        # $r->discard_request_body ;
        print STDERR "[$$] AuthenNTLM: verify handle = 1 smbhandle == $self->{smbhandle} \n" if ($debug) ;
	return Apache2::Const::HTTP_UNAUTHORIZED ;
    }
    elsif ($type == 3)
    {
	print STDERR "[$$] handler type == 3 \n" if ($debug) ;
        print STDERR "[$$] AuthenNTLM: verify handle = 3 smbhandle == $self->{smbhandle} \n" if ($debug) ;
        if ( !$self->verify_user( $r ) )
	{
            if ( $self->{ntlmauthoritative} )
	    {
                my $hdr = $r -> err_headers_out ;
                $hdr -> add ($r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate', 'NTLM') if ($self -> {authntlm}) ;
                $hdr -> add ($r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate', 'Basic realm="' 
			     . $self -> {authname} . '"') if ($self -> {authbasic}) ;
		# $r->discard_request_body ;
		return Apache2::Const::HTTP_UNAUTHORIZED ;
	    }
            else
	    {
                return Apache2::Const::DECLINED ;
	    }
	}
    }
    elsif ($type == -1)
    {
        my $nonce = $self -> get_nonce ($r) ;
        if (!$nonce) 
	{
            $self -> {lock} = undef ; # reset lock in case anything has gone wrong
            $r->log_error("Cannot get nonce for " . $r->uri) ;
            return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR ;
	}

        if (!$self -> verify_user ($r))
	{
            if ($self -> {basicauthoritative})
	    {
                my $hdr = $r -> err_headers_out ;
                $hdr -> add ($r->proxyreq ? 'Proxy-Authenticate' :'WWW-Authenticate', 'Basic realm="' 
			     . $self -> {authname} . '"') if ($self -> {authbasic}) ;
		# $r->discard_request_body ;
		return Apache2::Const::HTTP_UNAUTHORIZED ;
	    }
            else
	    {
                return Apache2::Const::DECLINED ;
	    }
	}
    }
    else
    {
        $self -> {lock} = undef ; # reset lock in case anything has gone wrong
        $r->log_error("Bad NTLM Authorization Header type $type for " . $r->uri) ;
	# $r->discard_request_body ;
	return Apache2::Const::HTTP_UNAUTHORIZED ;
    }

    $self -> {lock} = undef ; # reset lock in case anything has gone wrong
    $r -> user($self -> {mappedusername} = $self -> map_user ($r)) ;

    $self->{ok} = 1 ;

    print STDERR "[$$] AuthenNTLM: OK pid = $$, connection = $$conn cuser = " . $r -> user
	. ' ip = ' . $conn -> remote_ip . "\n" if ($debug) ;

    return Apache2::Const::OK ;
}


package Apache2::AuthenNTLM::Lock ;

use IPC::SysV qw(IPC_CREAT S_IRWXU SEM_UNDO);
use IPC::Semaphore;


sub lock
{
    my $class = shift ;
    my $key   = shift ;
    my $debug   = shift ;

    my $self = bless {debug => $debug}, $class ;
    $self->{sem} = new IPC::Semaphore($key, 1,
				      IPC_CREAT | S_IRWXU) or die "Cannot create semaphore with key $key ($!)" ;

    $self->{sem}->op(0, 0, SEM_UNDO,
                     0, 1, SEM_UNDO);
    print STDERR "[$$] AuthenNTLM: enter lock\n" if ($self -> {debug}) ;
    
    return $self ;
}

sub DESTROY
{
    my $self    = shift;

    $self->{sem}->op(0, -1, SEM_UNDO);
    print STDERR "[$$] AuthenNTLM: leave lock\n" if ($self -> {debug}) ;
}

1 ;

__END__

=head1 NAME

Apache2::AuthenNTLM - Perform Microsoft NTLM and Basic User Authentication

=head1 SYNOPSIS

	<Location />
	PerlAuthenHandler Apache2::AuthenNTLM 
	AuthType ntlm,basic
	AuthName test
	require valid-user

	#                    domain             pdc                bdc
	PerlAddVar ntdomain "name_domain1   name_of_pdc1"
	PerlAddVar ntdomain "other_domain   pdc_for_domain    bdc_for_domain"

	PerlSetVar defaultdomain wingr1
        PerlSetVar splitdomainprefix 1
	PerlSetVar ntlmdebug 1
	</Location>

=head1 DESCRIPTION

The purpose of this module is to perform a user authentication via Microsoft's
NTLM protocol. This protocol is supported by all versions of the Internet
Explorer and is mainly useful for intranets. Depending on your preferences
setting IE will supply your windows logon credentials to the web server
when the server asks for NTLM authentication. This saves the user to type in
his/her password again.

The NTLM protocol performs a challenge/response to exchange a random number
(nonce) and get back a md4 hash, which is built from the user's password
and the nonce. This makes sure that no password goes over the wire in plain text.

The main advantage of the Perl implementation is, that it can be easily extended
to verify the user/password against other sources than a windows domain controller.
The defaultf implementation is to go to the domain controller for the given domain 
and verify the user. If you want to verify the user against another source, you
can inherit from Apache2::AuthenNTLM and override it's methods.

To support users that aren't using Internet Explorer, Apache2::AuthenNTLM can
also perform basic authentication depending on its configuration.

B<IMPORTANT:> NTLM authentification works only when KeepAlive is on. (If you have set ntlmdebug 2, and see that there is no return message (type 3), check your httpd.conf file for "KeepAlive Off".  If KeepAlive Off, then change it to KeepAlive On, restart Apache, and test again).   


=head1 CONFIGURATION


=head2 AuthType 

Set the type of authentication. Can be either "basic", "ntlm"
or "ntlm,basic" for doing both.
 
=head2 AuthName

Set the realm for basic authentication

=head2 require valid-user

Necessary to tell Apache to require user authentication at all. Can also 
used to allow only some users, e.g.

  require user foo bar

Note that Apache2::AuthenNTLM does not perform any authorization, if
the require xxx is executed by Apache itself. Alternatively you can
use another (Perl-)module to perform authorization.


=head2 PerlAddVar ntdomain "domain pdc bdc"

This is used to create a mapping between a domain and both a pdc and bdc for
that domain. Domain, pdc and bdc must be separated by a space. You can
specify mappings for more than one domain.

NOTE FOR WINDOWS ACTIVE DIRECTORY USERS: You must specify the DOMAIN for 
the pdc and/or bdc.  Windows smb servers will not accept ip address in dotted
quad form.  For example, the SPEEVES domain pdc has an ip address of 192.168.0.2.
If you enter the ntdomain as:

PerlAddVar ntdomain 192.168.0.2

Then you will never be able be able to authenticate to the remote server correctly,
and you will receive a "Can not get NONCE" error in the error_log.  You must 
specify it as:

PerlAddVar ntdomain SPEEVES

This means that you will need to resolve the DOMAIN locally on the web server
machine.  I put it into the /etc/hosts file.

For the complete run-down on this issue, check out:

http://www.gossamer-threads.com/archive/mod_perl_C1/modperl_F7/%5BFwd:_Re:_Apache::AuthenNTLM-2.04_Problems..%5D_P104237/

=head2 PerlSetVar defaultdomain 

Set the default domain. This is used when the client does not provide
any information about the domain.

=head2 PerlSetVar fallbackdomain 

fallbackdomain is used in cases where the domain that the user supplied
isn't configured. This is useful in environments where you have a lot of
domains, which trust each other, allowing you to always authenticate against
a single domain, (removing the need to configure all domains available in
your network).

=head2 PerlSetVar ntlmauthoritative

Setting the ntlmauthoritative directive explicitly to 'off' allows authentication
to be passed on to lower level modules if AuthenNTLM cannot authenticate the user
and the NTLM authentication scheme is used.
If set to 'on', which is the default, AuthenNTLM will try to verify the user and,
if it fails, will give an Authorization Required reply. 

=head2 PerlSetVar basicauthoritative

Setting the ntlmauthoritative directive explicitly to 'off' allows authentication
to be passed on to lower level modules if AuthenNTLM cannot authenticate the user
and the Basic authentication scheme is used.
If set to 'on', which is the default, AuthenNTLM will try to verify the user and
if it fails will give an Authorization Required reply. 

=head2 PerlSetVar ntlmsemkey 

There are troubles when two authentication requests take place at the same 
time. If the second request starts, before the first request has successfully 
verified the user to the smb (windows) server, the smb server will terminate the first 
request. To avoid this Apache2::AuthenNTLM serializes all requests. It uses a semaphore
for this purpose. The semkey directive set the key which is used (default: 23754).
Set it to zero to turn serialization off.

=head2 PerlSetVar ntlmsemtimeout

This set the timeout value used to wait for the semaphore. The default is two seconds.
It is very small because during the time Apache waits for the semaphore, no other
authentication request can be sent to the windows server. Also Apache2::AuthenNTLM
only asks the windows server once per keep-alive connection, this timeout value
should be as small as possible.

=head2 PerlSetVar splitdomainprefix

If set to 1, $self -> map_user ($r) will return "username" 
else $self -> map_user ($r) will return "domain\username"
 
Default is "domain\username" 

=head2 PerlSetVar ntlmdebug 

Set this to 1 if you want extra debugging information in the error log.
Set it to 2 to also see the binary data of the NTLM headers.


=head1 OVERRIDEABLE METHODS

Each of the following methods takes the Apache object as argument. Information
about the current authentication can be found inside the object Apache2::AuthenNTLM 
itself. To override the methods, create our own class which inherits from
Apache2::AuthenNTLM and use it in httpd.conf e.g. 	

	PerlAuthenHandler Apache2::MyAuthenNTLM 


=head2 $self -> get_config ($r)

Will be called after the object is setup to read in configuration informations.
The $r -> dir_config can be used for that purpose.

=head2 $self -> get_nonce ($r)

Will be called to setup the connection to the windows domain controller 
for $self -> {domain} and retrieve the nonce.
In case you do not authenticate against a windows machine, you simply need 
to set $self -> {nonce} to a 8 byte random string. Returns undef on error.

=head2 $self -> verify_user ($r)

Should verify that the given user supplied the right credentials. Input:

=over

=item $self -> {basic}

Set when we are doing basic authentication

=item $self -> {ntlm}

Set when we are doing ntlm authentication

=item $self -> {username}

The username

=item $self -> {password}

The password when doing basic authentication

=item $self -> {usernthash}

The md4 hash when doing ntlm authentication

=item $self -> {userdomain}

The domain

=back

returns true if this is a valid user.

=head2 $self -> map_user ($r)

Is called before to get the user name which should be available as REMOTE_USER
to the request. Default is to return DOMAIN\USERNAME.

=head2 Example for overriding

The following code shows the a basic example for creating a module which
overrides the map_user method and calls AuthenNTLM's handler only if a
precondition is met. Note: The functions preconditon_met and lookup_user
do the real work and are not shown here.


    package Apache2::MyAuthenNTLM ;

    use Apache2::AuthenNTLM ;

    @ISA = ('Apache2::AuthenNTLM') ;


    sub handler ($$)
        {
        my ($self, $r) = @_ ;

        return Apache2::AuthenNTLM::handler ($self, $r) if (precondition_met()) ;
        return DECLINED ;
        }

    sub map_user

        {
        my ($self, $r) = @_ ;

        return lookup_user ($self->{userdomain}, $self->{username}) ;
        }

=head1 SUPPORT

Speeves: Thanks to everyone that is helping to find bugs, etc. in this module.  Please, feel free to contact me and let me know of any strange things are going on with this module.  Also, please copy the modperl@perl.apache.org mailing list, as there are probably many others that are experiencing the same problems as you, and they may be able to return an answer faster than I can by myself.  Thanks :)

=head1 SEE ALSO

An implementation of this module which uses cookies to cache the session.

Apache-AuthCookieNTLM - Leo Lapworth
http://search.cpan.org/~llap/Apache-AuthCookieNTLM/

=head1 AUTHOR

G. Richter (richter@dev.ecos.de)
Ported by Shannon Eric Peevey (speeves@unt.edu)

Development of this package, versions 0.01-0.13 was sponsored by:
Siemens: http://www.siemens.com

