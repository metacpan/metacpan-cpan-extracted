package Apache2::LogNotify;

use strict;
use Apache2::Const -compile => qw(OK HTTP_UNAUTHORIZED SERVER_ERROR);
use Apache2::Const qw(:common :log :cmd_how :http HTTP_BAD_REQUEST);
use Apache2::Connection qw(get_remote_host);
use Apache2::RequestUtil qw(dir_config);
use Apache2::RequestRec ();
use Apache2::ServerRec;
use Apache2::ServerUtil qw(server get_server_version);
use Apache2::Log;
use Apache2::Process;
use APR::Table;
use APR::Finfo ();
use Mail::Mailer;
use IPC::Cache;
use Data::Dumper;

our $VERSION = 0.10;
my $cache = new IPC::Cache( { namespace  => 'LogNotify',
			      expires_in => 86400 } );
$cache->purge();

sub handler {
    my $r = shift;
    my $s = $r->server();
    my $args = $r->args;
    my $user = $r->user;
    my $debug = undef;
    my $dir_cfg = getConfig($r->server , $r->per_dir_config);

    $debug = 1 if ( $dir_cfg->{Debug} eq "On" );
    $r->log_error(__PACKAGE__.": ", ' Debug: ['. $dir_cfg->{Debug} . ']');
    foreach my $key ( keys %{$dir_cfg} ) {
	my $value = $dir_cfg->{$key};
	if ( $debug ) {
	    if ( ref($value ) eq "SCALAR" ){
		$r->log_error(__PACKAGE__.": ", $key, ': ['. $value .']');
	    }
	    if ( ref($value ) eq "ARRAY" ){
		$r->log_error(__PACKAGE__.": ", $key, ': ['. join(", ", @{$value} ) .']');
	    }
	}
    }
    # LogError On
    $r->log_error(__PACKAGE__.':  LogError CODE: ['. $dir_cfg->{LogError}->[0]  .']') if ( $debug );
    return Apache2::Const::OK unless ( $dir_cfg->{LogError} !~ /^[Oo][Nn]$/ );

    #ErrorType 300 400 500
    #my @errorType = split( /\s+,\s+/, join(' ',@{$dir_cfg->{ErrorType}}) );
    my @errorType = split( /\s+/, join(' ',@{$dir_cfg->{ErrorType}}) );
    $r->log_error(__PACKAGE__. "==========: ErrorType:  ".  Dumper ($dir_cfg->{ErrorType}) ) if ( $debug );
    $r->log_error(__PACKAGE__.'==========:  ERROR TYPE: ['. @{$dir_cfg->{ErrorType}}  .']') if ( $debug );
    $r->log_error(__PACKAGE__.'==========:  ERROR TYPE 2: ['. join(", ", @errorType )  .']') if ( $debug );
#    $r->log_error(__PACKAGE__.'==========:  HOSTNAME: ['. $s->server_hostname() .']') if ( $debug );

    foreach my $errorTest ( @errorType ) {
	#$r->log_error(__PACKAGE__.'==========: errorType: Test: ['. $errorTest  .']') if ( $debug );
	if ( $r->status() == $errorTest ) {
	    $r->log_error(__PACKAGE__.'==========: PURGE CACHE: ') if ( $debug );
	    $cache->purge();
	    my $seen = $cache->get( $r->uri() );
	    my $seenCount = $cache->get("SeenCount");
	    $r->log_error(__PACKAGE__.'==========: SEEN: <' . $seenCount . '>') if ( $debug );
	    if ( ! $seen || $seenCount % 10 == 0 ) {
		$cache->set($r->uri(), 1, 30 );
		$cache->set("SeenCount", 1, 30 );
		$r->log_error(__PACKAGE__.'==========: SENDING MAIL ON: <'. $r->uri().'>' ) if ( $debug );
		&sendMail($r);
	    }
	    else {
		$r->log_error(__PACKAGE__.'==========: NO MAIL MAIL <' . $seen . '> <'. $r->uri().'>') if ( $debug );
		$cache->set("SeenCount", $seenCount + 1, 30 );
	    }
	}
    }

    $r->log_error(__PACKAGE__.'==========:  RESPONSE CODE: ['. $r->status()  .']') if ( $debug );
    $r->log_error(__PACKAGE__.'==========:  NotifyMode CODE: ['. $dir_cfg->{NotifyMode}->[0]  .']') if ( $debug );
    
    return Apache2::Const::HTTP_UNAUTHORIZED; 
}

sub sendMail {
    my $r = shift @_;
    my $s = $r->server();

    my $dir_cfg = getConfig($r->server , $r->per_dir_config);
    my $debug = undef;
    $debug = 1 if ( $dir_cfg->{Debug} eq "On" );

    my $email = {};
    $email->{From} = $s->server_admin();
    $email->{To} = shift( @{ $dir_cfg->{Admins} } );
    my @message = ();
    my %mailList;
    if ( $dir_cfg->{NotifyMode}->[0] eq "All" || $dir_cfg->{NotifyMode}->[0] eq "Admins" ) {
	$r->log_error(__PACKAGE__.':  NotifyMode CODE OPTION: [ADMIN]') if ( $debug );
	foreach my $mail ( @{$dir_cfg->{Admins}} ) {
	    $mailList{$mail} = 1;
	}
    }
    
    if ( $dir_cfg->{NotifyMode}->[0] eq "All" || $dir_cfg->{NotifyMode}->[0] eq "AppOwners" ) {
	$r->log_error(__PACKAGE__.':  NotifyMode CODE OPTION: [APPOWNERS]') if ( $debug );
	foreach my $mail ( @{$dir_cfg->{AppOwners}} ) {
	    $mailList{$mail} = 1;
	}
    }
    
    $r->log_error(__PACKAGE__.':  EMAILS: [' . join(', ', keys %mailList )  . ']');
    $email->{Subject} = "Apache: ERROR: " . $s->server_hostname(). ": " . $r->status_line();
    $email->{Cc} = join(",",  (keys %mailList) );

    my $c = $r->connection;
    my $httpURL = "http://". $s->server_hostname()."". $r->unparsed_uri();
    push( @message, "USER Request: " . $httpURL );
    push( @message, "STATUS LINE: " . $r->status_line() );
    push( @message, "STATUS: " . $r->status() );
    push( @message, "REQUEST: " . $r->the_request());
    push( @message, "UNPARSED URI: " . $r->unparsed_uri() );
    push( @message, "URI: " . $r->uri() );
    push( @message, "USER: " . $r->user() );

    push( @message, "PORT: " . $s->port() );
    push( @message, "SHORT_NAME: " . $s->process()->short_name() );
    push( @message, "SERVER HOSTNAME: " . $s->server_hostname() );
    push( @message, "BASE SERVER: " . $c->base_server()->server_hostname() );
	  
    push( @message, "AUTH TYPE: " . $r->ap_auth_type() );
    push( @message, "QUERY STRING: " . $r->args() );

    push( @message, "BYTES SENT: " . $r->bytes_sent() ) ;
    push( @message, "REMOTE HOST IP: " . $r->connection()->get_remote_host() );
    push( @message, "REMOTE HOST NAME: " . $r->connection()->remote_host() );
    push( @message, "FILE NAME: " . $r->filename() );
    my $finfo = $r->finfo();
 
    push( @message, "INODE: " . $finfo->inode );
    
    push( @message, "PROTECTION: " . $finfo->protection );
    push( @message, "NLINK: " . $finfo->nlink );
    push( @message, "GROUP: " . $finfo->group );
    push( @message, "USER: " . $finfo->user );
    push( @message, "SIZE: " . $finfo->size );
    push( @message, "ATIME: " . scalar localtime($finfo->atime) );
    push( @message, "MTIME: " . scalar localtime($finfo->mtime) );
    push( @message, "CTIME: " . scalar localtime($finfo->ctime) );
    
    my $headersIn = $r->headers_in() ;
    foreach my $key (keys %{$headersIn}) {
	push( @message, $key.": " . $headersIn->{$key} );
    }

    my $headersOut = $r->headers_out() ;
    foreach my $key (keys %{$headersOut}) {
	push( @message, $key.": " . $headersOut->{$key} );
    }

    push( @message, "HOST NAME: " . $r->hostname() );  
    
    push( @message, "METHOD: " . $r->method() );
    push( @message, "MTIME: " . $r->mtime() );
    push( @message, "PROTOCOL: " . $r->protocol());
    push( @message, "REQUEST TIME: " . $r->request_time());
    push( @message, "OBJECT SERVER NAME: " . $r->server() );
    push( @message, "RESPONSE STATUS: " . $r->status() );

    my $env = $r->subprocess_env() ;
    foreach my $key (keys %{$env}) {
	push( @message, $key.": " . $env->{$key} );
    }

    push( @message, "STATUS LINE: " . $r->status_line() );
    push( @message, "STATUS: " . $r->status() );
    push( @message, "REQUEST: " . $r->the_request());
    push( @message, "UNPARSED URI: " . $r->unparsed_uri() );
    push( @message, "URI: " . $r->uri() );
    push( @message, "USER: " . $r->user() );

    foreach my $key (keys %{$email}) {
	push( @message, "EMAIL: ". $key.": " . $email->{$key} );
    }

    my $sendmail=Mail::Mailer->new("sendmail");
    $sendmail->open( $email );
    print $sendmail join("\n", @message);
    $sendmail->close;
    $r->log_error(__PACKAGE__.':  MESSAGE: [' . join(', ', @message )  . ']') if ( $debug );
    
}

sub getConfig {
    Apache2::Module::get_config(__PACKAGE__.'::Parameters', @_);
}

1;
__END__
=head1 Apache2::LogNotify - Authrization Module

=head2 Summary

This module will notify a set of specified users when errors occur.  The error and e-mail for notification can be specified on a specific directory or location. If you use CGI::Carp qw(fatalsToBrowser) on perl cgi scripts the Server Error 500 will be trapped by the pperl modules nd the http apache server will display the error on the client browser and  the apach status code will be 200.

=head2 Configuration

You must add the following directives in order for the module to
properly work.  Before the Authz phase must be an Access or Authen
phase.  For most part you want to configure httpd.conf as below.

PerlLoadModule Apache2::LogNotify::Parameters
<Directory />
    Options FollowSymLinks
    AllowOverride None
    Order deny,allow
    Deny from all
    PerlLogHandler Apache2::LogNotify
    LogError On
    ErrorType 403 400 500
    NotifyMode All
    ErrorThrottle 1800
    Admins joe.smith@somehost.com joey.smith@somehost.com
    AppOwners james.smith@somehost.com
    NotifyOptions Email
    Debug Off
</Directory>

Add the directive, "PerlLogHandler Apache2::LogNotify" inside a Directory or Location section
to enable Error Notification .

LogErrors: 
    This is use to manualy turn on/off the error notification.
    On  - Turns logging on.
    Off - Turns logging off

ErrorType:
    A list of errors to notify about.  All other apache error codes will be ignored.
    Specify which errors to log.  This are the http response codes.

NotifyMode:
    Admin - Send email to Admins only
    Users - Send email to Users only
    All - Send email to Admins and Users.

ErrorThrottle:
    It uses an integer which will represent the number of seconds between multiple e-mails for the
    same url.  If the Directory or Location (URL) gets multiple hits the system will send one e-mail
    and ignores errors on this url instances that occur within the specified number of seconds 
    on ErrorThrottle.  This prevents sending multiple e-mails for the same error on the same url.  Each
    URL will have its own Throttle.

Admins:
    Specify the Administrator's email.  One or more can be used. Defaults to the web site admin.

AppOwners:
    Specify the application or web page owner(s).  One or more can be used. It can be left blank.

NotifyOptions:
    Use "Email" to send email to Admin and/or AppOwner.  This is the only option at this moment.

Debug
    Debugging messages go to the log file.
    On - Turn debugging on
    Off - Turn debugging off

=head2 AUTHOR

Carlos B. Rios <carlos.rios@bms.com>

=cut
