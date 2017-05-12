#
#    Apache::SessionManager.pm - mod_perl module to manage HTTP sessions
#
#    The Apache::SessionManager module is free software; you can redistribute it
#    and/or modify it under the same terms as Perl itself. 
#
#    See 'perldoc Apache::SessionManager' for documentation
#

package Apache::SessionManager;

require 5.005;
use strict;

use vars qw($VERSION);
$VERSION = '1.03';

use mod_perl;
use Apache::Session::Flex;
use constant MP2 => ($mod_perl::VERSION >= 1.99);

if (MP2) {
	@Apache::SessionManager::ISA = qw(Apache::RequestRec);
}
else {
	@Apache::SessionManager::ISA = qw(Apache);
}

# Test libapreq modules
my $libapreq;
BEGIN {
	# Tests mod_perl version and uses the appropriate components
	if (MP2) {
		require Apache::Const;
		Apache::Const->import(-compile => qw(DECLINED REDIRECT));
		require Apache::RequestRec;
		require Apache::SubRequest;
		require Apache::RequestUtil;
		require APR::Pool;           # for cleanup_register
		require APR::URI;
		require Apache::URI;
		#require Apache::Connection;  # for remote_ip
	}
	else {
		require Apache::Constants;
		Apache::Constants->import(qw(DECLINED REDIRECT));
		require Apache::URI;
	}
	# Test libapreq modules
	eval { require Apache::Cookie; Apache::Cookie->can('bake'); Apache::Cookie->can('fetch') };
	if ($@) {
		require CGI::Cookie;
		$libapreq = 0;
	}
	else {
		$libapreq = 1;
	}
}

sub handler {
	my $r = shift;
	my (%session_config,%session,$session_id,%cookie_options);

	return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED) unless $r->is_initial_req;

	my $debug_prefix = '[' . $r->connection->remote_ip . "] SessionManager ($$): ";
	$session_config{'SessionManagerDebug'} = $r->dir_config('SessionManagerDebug') || 0;
	foreach ( qw/SessionManagerURITracking SessionManagerTracking SessionManagerEnableModBackhand 
		          SessionManagerStoreArgs SessionManagerCookieArgs SessionManagerSetEnv SessionManagerExpire 
		          SessionManagerHeaderExclude SessionManagerIPExclude/ ) {
		$session_config{$_} = $r->dir_config($_);
	}

	$r->log_error($debug_prefix . '---START REQUEST: ' .  $r->uri . ' ---') if $session_config{'SessionManagerDebug'} > 0;
	#print STDERR "$debug_prefix ---START REQUEST: " .  $r->uri . " ---\n" if $session_config{'SessionManagerDebug'} > 0;

	# Get and remove session ID from URI
	if ( $session_config{'SessionManagerURITracking'} eq 'On' ) {
		$r->log_error($debug_prefix . 'start URI ' . $r->uri) if $session_config{'SessionManagerDebug'} > 0;
		#print STDERR "$debug_prefix start URI " . $r->uri . "\n" if $session_config{'SessionManagerDebug'} > 0;
	
		# retrieve session ID from URL (or HTTP 'Referer:' header)
		my (undef, $uri_session_id, $rest) = split /\/+/, $r->uri, 3;

		if ( $uri_session_id =~ /^[0-9a-h]+$/ ) {
			$session_id = $uri_session_id;
			# Remove the session from the URI
			$r->uri("/$rest");
			$r->log_error($debug_prefix . 'end URI ' . $r->uri) if $session_config{'SessionManagerDebug'} > 0;
			#print STDERR "$debug_prefix end URI " . $r->uri . "\n" if $session_config{'SessionManagerDebug'} > 0;
		}
	}
	
	# declines each request if session manager is off
	return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED) unless ( $session_config{'SessionManagerTracking'} eq 'On' );

	# declines requests matching IP exclusion list
	if ( $session_config{'SessionManagerIPExclude'} ) {
		require Socket;
		foreach ( split(/\s+/,$session_config{'SessionManagerIPExclude'}) ) {
			$r->log_error($debug_prefix . '_isInRange(' . $r->connection->remote_ip . ",$_)") if $session_config{'SessionManagerDebug'} >= 5;
			#print STDERR "$debug_prefix _isInRange(" . $r->connection->remote_ip . ",$_)\n" if $session_config{'SessionManagerDebug'} >= 5;
			return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED) if _isInRange($r->connection->remote_ip,$_); 
		}
	}

	# declines requests matching any of exclusions headers
	foreach my $header ( $r->dir_config->get('SessionManagerHeaderExclude') ) {
		my ($key,$value) = split(/\s*=\s*>\s*/,$header,2);
		# Header and its value must exists in order to check it
		next unless ($r->headers_in->{$key} && $value);
		if ( $r->headers_in->{$key} =~ /$value/i ) {
			return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED)
		}
	}

	# Set exclusion extension(s)
	$session_config{'SessionManagerItemExclude'} = $r->dir_config('SessionManagerItemExclude') || '(\.gif|\.jpe?g|\.png|\.mpe?g|\.css|\.js|\.txt|\.mp3|\.wav|\.swf|\.avi|\.au|\.ra?m)$';

	# declines requests if resource type is to exlcude
	return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED) if ( $r->uri =~ /$session_config{'SessionManagerItemExclude'}/i );

	$session_config{'SessionManagerStore'} = $r->dir_config('SessionManagerStore') || 'File';
	$session_config{'SessionManagerLock'} = $r->dir_config('SessionManagerLock') || 'Null';
	$session_config{'SessionManagerGenerate'} = $r->dir_config('SessionManagerGenerate') || 'MD5';
	$session_config{'SessionManagerSerialize'} = $r->dir_config('SessionManagerSerialize') || 'Storable';
	$session_config{'SessionManagerExpire'} = 
		$session_config{'SessionManagerExpire'} =~ /^(none|no|disabed)$/i ? 0 
		: $session_config{'SessionManagerExpire'} !~ /^\d+$/ ? 3600
		: $session_config{'SessionManagerExpire'};
	$session_config{'SessionManagerInactivity'} = ( $r->dir_config('SessionManagerInactivity') =~ /^\d+$/ ) ? $r->dir_config('SessionManagerInactivity') : undef;
	$session_config{'SessionManagerName'} = $r->dir_config('SessionManagerName') || 'PERLSESSIONID';

	# Print SesssionManager configs to error_log
	if ( $session_config{'SessionManagerDebug'} >= 3 ) {
		$r->log_error($debug_prefix . 'configuration settings:');
		#print STDERR "$debug_prefix configuration settings\n";
		foreach (sort keys %session_config)	{
			$r->log_error($debug_prefix . ' ' x 8 . "$_ = $session_config{$_}");
			#print STDERR "\t$_ = $session_config{$_}\n";
		}
	}

	# Get session ID from cookie
	unless ( $session_config{'SessionManagerURITracking'} eq 'On' ) {

		if ( $libapreq ) {
			# Test libapreq 1 or 2 version to use correct 'fetch' API
			my %cookies = $Apache::Request::VERSION >= 2 ? Apache::Cookie->fetch($r) : Apache::Cookie->fetch;
			$session_id = $cookies{$session_config{'SessionManagerName'}}->value if defined $cookies{$session_config{'SessionManagerName'}};
			$r->log_error($debug_prefix . 'Apache::Cookie fetch') if $session_config{'SessionManagerDebug'} >= 5;
			#print STDERR "$debug_prefix Apache::Cookie fetch\n" if $session_config{'SessionManagerDebug'} >= 5;
		}
		# Fetch cookies with CGI::Cookie				
		else {
			# At this phase (HeaderParser | Translation), no $ENV{'COOKIE'} var is set, so we use CGI::Cookie parse method by passing 'Cookie' HTTP header
			my %cookies = CGI::Cookie->parse($r->headers_in->{'Cookie'});
			$session_id = $cookies{$session_config{'SessionManagerName'}}->value if defined $cookies{$session_config{'SessionManagerName'}};
			$r->log_error($debug_prefix . 'CGI::Cookie fetch') if $session_config{'SessionManagerDebug'} >= 5;
			#print STDERR "$debug_prefix CGI::Cookie fetch\n" if $session_config{'SessionManagerDebug'} >= 5;
		}
	}

	# Prepare Apache::Session::Flex options parameters call
	my %apache_session_flex_options = (
		Store     => $session_config{'SessionManagerStore'},
		Lock      => $session_config{'SessionManagerLock'},
		Generate  => $session_config{'SessionManagerGenerate'},
		Serialize => $session_config{'SessionManagerSerialize'}
	); 

	# Load session data store specific parameters
	foreach my $arg ( split(/\s*,\s*/,$session_config{'SessionManagerStoreArgs'}) ) {
		my ($key,$value) = split(/\s*=\s*>\s*/,$arg);
		$apache_session_flex_options{$key} = $value;
	}

	if ( $session_config{'SessionManagerDebug'} >= 5 ) {
		$r->log_error($debug_prefix . 'Apache::Session::Flex options:');
		#print STDERR "$debug_prefix Apache::Session::Flex options\n";
		foreach (sort keys %apache_session_flex_options)	{
			$r->log_error($debug_prefix . ' ' x 8 . "$_ = $apache_session_flex_options{$_}");
			# print STDERR "\t$_ = $apache_session_flex_options{$_}\n";
		}
	}

	# Support for mod_backhand sticky sessions
	$session_id = substr($session_id,8) if ( $session_config{'SessionManagerEnableModBackhand'} eq 'On' );
	 
	# Try to retrieve session object from session ID
	my $res = _tieSession($r,\%session, $session_id, \%apache_session_flex_options,$session_config{'SessionManagerDebug'},$debug_prefix);

	# Session ID not found or invalid session: a new object session will be create
	if ($res) {
		my $res = _tieSession($r,\%session, undef, \%apache_session_flex_options,$session_config{'SessionManagerDebug'},$debug_prefix);
		$session_id = undef;
	}

	# for new or invalid session's ID put session start time in special session key '_session_start'
	$session{'_session_start'} = time if ! defined $session{'_session_start'};

	# session's expiration date check only for existing sessions
	if ( $session_id ) {
		$r->log_error($debug_prefix . "checking TTL session, ID = $session_id ($session{'_session_timestamp'})") if $session_config{'SessionManagerDebug'} > 0;
		#print STDERR "$debug_prefix  checking TTL session, ID = $session_id ($session{'_session_timestamp'})\n" if $session_config{'SessionManagerDebug'} > 0;

		# Session TTL expired: a new object session is create
		if ( ( $session_config{'SessionManagerInactivity'} && 
		       (time - $session{'_session_timestamp'}) > $session_config{'SessionManagerInactivity'} ) 
			  || 
			  ( $session_config{'SessionManagerExpire'} && 
			    (time - $session{'_session_start'}) > $session_config{'SessionManagerExpire'} ) ) {
			$r->log_error($debug_prefix . 'session to delete') if $session_config{'SessionManagerDebug'} > 0;
			#print STDERR "$debug_prefix session to delete\n" if $session_config{'SessionManagerDebug'} > 0;
			tied(%session)->delete;
			
			my $res = _tieSession($r,\%session, undef, \%apache_session_flex_options,$session_config{'SessionManagerDebug'},$debug_prefix);

			$session_id = undef;
			$session{'_session_start'} = time;
		}
	}

	# Update '_session_timpestamp' session value only if required
	$session{'_session_timestamp'} = time if $session_config{'SessionManagerInactivity'};
	
	# store object session reference in pnotes to share it over other handlers
	$r->pnotes('SESSION_MANAGER_HANDLE' => \%session );

	# set 'SESSION_MANAGER_SID' env variable to session ID to make it available to CGI/SSI scripts
	$r->subprocess_env(SESSION_MANAGER_SID => $session{_session_id}) if ($session_config{'SessionManagerSetEnv'} eq 'On');

	MP2 ? $r->pool->cleanup_register(\&cleanup,$r) : $r->register_cleanup(\&cleanup);

	# Foreach new session we:
	unless ( $session_id ) {
		my $session_id = $session{_session_id};
		
		# Adjusts session id for mod_backhand
		if ( $session_config{'SessionManagerEnableModBackhand'} eq 'On' ) {
			my $hex_addr = join "", map { sprintf "%lx", $_ } unpack('C4', gethostbyname($r->get_server_name));
			$session_id = $hex_addr . $session_id;
		}

		# redirect to embedded session ID URI...
		if ( $session_config{'SessionManagerURITracking'} eq 'On' ) {
			$r->log_error($debug_prefix . 'URI redirect...') if $session_config{'SessionManagerDebug'} > 0;
			#print STDERR "$debug_prefix URI redirect...\n" if $session_config{'SessionManagerDebug'} > 0;
			_redirect($r,$session_id);
			return MP2 ? Apache::REDIRECT : Apache::Constants::REDIRECT;
		}
		# ...or send cookie to browser
		else {
			$r->log_error($debug_prefix . 'sending cookie...') if $session_config{'SessionManagerDebug'} > 0;
			#print STDERR "$debug_prefix sending cookie...\n" if $session_config{'SessionManagerDebug'} > 0;
			
			# Load cookie specific parameters
			foreach my $arg ( split(/\s*,\s*/,$session_config{'SessionManagerCookieArgs'}) ) {
				my ($key,$value) = split(/\s*=>\s*/,$arg);
				$cookie_options{'-' . lc($key)} = $value if $key =~ /^(expires|domain|path|secure)$/i;
			}
			
			# Set default cookie path
			$cookie_options{'-path'} = '/' unless $cookie_options{'-path'};
			
			if ( $session_config{'SessionManagerDebug'} >= 5 ) {
				$r->log_error($debug_prefix . 'Cookie options:');
				#print STDERR "$debug_prefix Cookie options\n";
				foreach (sort keys %cookie_options)	{
					$r->log_error($debug_prefix . ' ' x 8 . "$_ = $cookie_options{$_}");
					#print STDERR "\t$_ = $cookie_options{$_}\n";
				}
			}

			# Set cookie with Apache::Cookie
			if ( $libapreq ) {
				my $cookie = Apache::Cookie->new($r,
					name => $session_config{'SessionManagerName'},
					value => $session_id,
					%cookie_options
				);
				$cookie->bake;
				
				$r->log_error($debug_prefix . 'Apache::Cookie bake ' . $cookie->as_string) if $session_config{'SessionManagerDebug'} >= 5;
				#print STDERR ("$debug_prefix Apache::Cookie bake " . $cookie->as_string . "\n") if $session_config{'SessionManagerDebug'} >= 5;
			}
			# Set cookie with CGI::Cookie
			else {
				my $cookie = CGI::Cookie->new(
					-name => $session_config{'SessionManagerName'},
					-value => $session_id,
					%cookie_options
				);
				$r->err_headers_out->{'Set-Cookie'} = "$cookie";
				
				$r->log_error($debug_prefix . "CGI::Cookie bake $cookie") if $session_config{'SessionManagerDebug'} >= 5;
				#print STDERR "$debug_prefix CGI::Cookie bake $cookie\n" if $session_config{'SessionManagerDebug'} >= 5;
			}
		}
	}

	$r->log_error($debug_prefix . '---END REQUEST---') if $session_config{'SessionManagerDebug'} > 0;
	#print STDERR "$debug_prefix ---END REQUEST---\n" if $session_config{'SessionManagerDebug'} > 0;
		
	return MP2 ? Apache::DECLINED : Apache::Constants::DECLINED;
}

sub cleanup {
	my $r = shift;
	return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED) unless ( $r->dir_config('SessionManagerTracking') eq 'On' );
	my $session = ref $r->pnotes('SESSION_MANAGER_HANDLE') ? $r->pnotes('SESSION_MANAGER_HANDLE') : {};
	untie %{$session};
	return MP2 ? Apache::DECLINED : Apache::Constants::DECLINED;
}

sub new {
	my ($class, $r) = @_;
	my $session = (ref $r->pnotes('SESSION_MANAGER_HANDLE')) ? $r->pnotes('SESSION_MANAGER_HANDLE') : {};
	return bless { r => $r, session => $session }, $class;
}

sub get_session_param {
	my ($r,@args) = @_;
	if ( ! @args ) {
		@args = keys %{$r->{session}};
	}
	my @ary;
	foreach ( @args ) {
		push @ary, $r->{session}->{$_};
	}
	return wantarray ? @ary: "@ary";
}

sub set_session_param {
	my ($r,%args) = @_;
	foreach ( keys %args ) {
		# to avoid ovverride session special keys
		next if /^_session/;
		$r->{session}->{$_} = $args{$_};
	}
}

sub delete_session_param {
	my ($r,@args) = @_;
	foreach ( @args ) {
		# to avoid ovverride session special keys
		next if /^_session/;
		delete $r->{session}->{$_};
	}
}

sub get_session {
	my $r = shift;
	return ($r->pnotes('SESSION_MANAGER_HANDLE')) ? $r->pnotes('SESSION_MANAGER_HANDLE') : ();
}

sub destroy_session {
	my $r = shift;
	my $session = (ref $r->pnotes('SESSION_MANAGER_HANDLE')) ? $r->pnotes('SESSION_MANAGER_HANDLE') : {};
	tied(%{$session})->delete;
}

sub _tieSession {
	my ($r,$session_ref,$id,$options,$debug,$debug_prefix) = @_;
	eval {
		tie %{$session_ref}, 'Apache::Session::Flex', $id, $options;
	};
	$r->log_error($debug_prefix . "Tied session ID = $$session_ref{_session_id}$@") if $debug >= 3;
	#print STDERR "Tied session ID = $$session_ref{_session_id}\n$@" if $debug >= 3;
	return $@ if $@;
}

# _redirect function adapted from original redirect sub wrote by Greg Cope
sub _redirect {
	my $r = shift;
	my $session_id = shift || '';
	my ($args, $host, $rest, $redirect);
	($host, $rest) = split '/', $r->uri, 2;
	$args = $r->args || '';
	$args = '?' . $args if $args;
	$r->content_type('text/html');
 
	# "suggest by Gerald Richter / Matt Sergeant to add scheme://hostname:port to redirect" (Greg's original note)
	my $uri = MP2 ? APR::URI->parse($r->pool,$r->construct_url) : Apache::URI->parse($r);

 	# hostinfo give port if necessary - otherwise not
	my $hostinfo = $uri->hostinfo;
	my $scheme =  $uri->scheme . '://';
	$session_id .= '/' if $session_id;
	$redirect = $scheme . $hostinfo . '/'. $session_id . $rest . $args;
	# if no slash and it's a dir add a slash
	if ($redirect !~ m#/$# && -d $r->lookup_uri($redirect)->filename) {
		$redirect .= '/';
	}
	$r->headers_out->{'Location'} = $redirect;
}

sub _isInRange {
	my ($addr,$base) = @_;
	my $bits;
	($base, $bits) = split /[\/:]/, $base;
	return ( (4 == grep { $_ < 256 && /^\d+$/ } split(/\./, $base)) 
	         && (4 == grep { $_ < 256 && /^\d+$/ } split(/\./, $addr)) 
	         && ($bits =~ /^\d*$/ && $bits <= 32)
				&& ((unpack("N", Socket::inet_aton($base)) >> (32 - $bits)) == (unpack ("N", Socket::inet_aton($addr)) >> (32 - $bits)))
	       ) ? 1 : 0;
}
	
1;
__END__

=pod 

=head1 NAME

Apache::SessionManager - mod_perl 1.0/2.0 session manager extension to
manage sessions over HTTP requests

=head1 SYNOPSIS

In F<httpd.conf> (mod_perl 1):

   PerlModule Apache::SessionManager
   PerlTransHandler Apache::SessionManager

   <Location /my-app-with-session>
      SetHandler perl-script
      PerlHandler Apache::MyModule
      PerlSetVar SessionManagerTracking On
      PerlSetVar SessionManagerExpire 3600
      PerlSetVar SessionManagerInactivity 900
      PerlSetVar SessionManagerStore File
      PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_sessions"
   </Location>  

   <Location /my-app-without-sessions>
      PerlSetVar SessionManagerTracking Off
   </Location>

In F<httpd.conf> (mod_perl 2):

   PerlModule Apache2
   PerlModule Apache::SessionManager
   PerlTransHandler Apache::SessionManager

   <Location /my-app-with-session>
      SetHandler perl-script
      PerlResponseHandler Apache::MyModule
      PerlSetVar SessionManagerTracking On
      PerlSetVar SessionManagerExpire 3600
      PerlSetVar SessionManagerInactivity 900
      PerlSetVar SessionManagerStore File
      PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_sessions"
   </Location>  

In a mod_perl module handler:

   sub handler {
      my $r = shift;
      my $session = Apache::SessionManager::get_session($r);
      ...
   }

=head1 DESCRIPTION

Apache::SessionManager is a mod_perl (1.0 and 2.0) module that helps session
management of a web application. This module is a wrapper around
L<Apache::Session|Apache::Session> persistence framework for session data. It
creates a session object and makes it available to all other handlers 
transparenlty by putting it in pnotes. In a mod_perl handlers you can retrieve 
the session object directly from pnotes with predefined key 
C<SESSION_MANAGER_HANDLE>:

   my $session = $r->pnotes('SESSION_MANAGER_HANDLE') ? $r->pnotes('SESSION_MANAGER_HANDLE') : ();

then it is possible to set a value in current session with:

   $$session{'key'} = $value;
   # same as
   $session->{'key'} = $value;	

or it is possible to read value session with:

   print "$$session{'key'}";
   # same as
   print $session->{'key'};	

Apache::SessionManager is intended also to use within thirdy part packages.
See L<Apache::SessionManager::cookpod|Apache::SessionManager::cookpod> for more
info.

=head1 MOD_PERL 2 COMPATIBILITY

Since version 1, Apache::SessionManager is fully compatible with both mod_perl
generations 1.0 and 2.0.

If you have mod_perl 1.0 and 2.0 installed on the same system and the two uses
the same per libraries directory, to use mod_perl 2.0 version make sure to load
first C<Apache2> module which will perform the necessary adjustements to
C<@INC>:

   PerlModule Apache2
   PerlModule Apache::SessionManager

Of course, notice that if you use mod_perl 2.0, there is no need to pre-load
the L<Apache::compat|Apache::compat> compatibility layer.

Versions of Apache::SessionManager less than 1.00 are mod_perl 1.0 only, so its 
works fine with mod_perl 2.0 only under L<Apache::compat|Apache::compat>.

=head1 API OVERVIEW

Apache::SessionManager offers two kinds of interfaces: functional and object
oriented. For a detailed description for the last one, see L</METHODS> section.

The following functions are provided (but not exported) by this module:

=over 4

=item C<Apache::SessionManager::get_session(Apache-E<gt>request)>

Return an hash reference to current session object. 

In a mod_perl module handler:

   sub handler {
      my $r = shift;
      my $session = Apache::SessionManager::get_session($r);
      ...
   }

In a CGI L<Apache::Registry|Apache::Registry> script:

   my $session = Apache::SessionManager::get_session(Apache->request);

=item C<Apache::SessionManager::destroy_session(Apache-E<gt>request)>

Destroy the current session object.

In a mod_perl module handler:

   sub handler {
      my $r = shift;
      ...

   Apache::SessionManager::destroy_session($r);

      ...
   }

In a CGI L<Apache::Registry|Apache::Registry> script:

   Apache::SessionManager::destroy_session(Apache->request);

=back

=head1 METHODS

Apache::SessionManager also provides an object oriented interface described in
this section. Apache::SessionManager subclass C<$r> Apache request object by
adding following methods:

=over 4

=item C<my $r = new Apache::SessionManager(Apache-E<gt>request)>

Tipically, in a mod_perl module handler:

   sub handler {
      my $r = new Apache::SessionManager(shift);
      ...
   }

=item C<$r-E<gt>get_session>

Return an hash reference to current session object. 

   my $session = $r->get_session;

It is the equivalent of  C<Apache::SessionManager::get_session> functional
approach.

=item C<$r-E<gt>get_session_param( $session_key,...)>

Returns an array containing session values correspondent
to keys passed as arguments. 

   my @values = $r->get_session_param('foo', 'baz');

Called with no args, return all session values.

In a scalar context return the stringyfied version of array.

=item C<$r-E<gt>set_session_param( %args );>

Set session values:

   $r->set_session_param( foo => $foo, baz => \%baz );

Called with no arguments, has no effects.

=item C<$r-E<gt>delete_session_param( $session_key,...)>

Delete session values:

   $r->delete_session_param('foo', 'baz');

Called with no arguments, has no effects.

=item C<$r-E<gt>destroy_session>

Destroy the current session object. It is the equivalent of 
C<Apache::SessionManager::destroy_session> functional approach.

=back

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
better.

Prerequisites:

=over 4

=item * mod_perl 1.0 or 2.0 is required (of course) with the appropriate
call-back hooks (PERL_TRANS=1 PERL_HEADER_PARSER=1)

=item * Apache::Session >= 0.53 is required

=item * Apache::Cookie >= 0.33 (libapreq) is preferred but not required 
(CGI::Cookie will be used instead)

=item * CGI::Cookie (used only if Apache::Request isn't installed)

=back 

Installation as usual:

   % perl Makefile.PL
   % make
   % make test
   % su
     Password: *******
   % make install

=head1 CONFIGURATION

To enable session tracking with this module you could modify F<httpd.conf> or
F<.htaccess> files.

=head2 Configuring via F<httpd.conf>

To enable session tracking with this module via F<httpd.conf> (or any  files
included by the C<Include> directive) you must add the following  lines:

   PerlModule Apache::SessionManager
   PerlTransHandler Apache::SessionManager
   PerlSetVar SessionManagerTracking On

This will activate the session manager over each request.
It is posibible to activate this module only in certain locations:

   <Location /my-app-dir>
      PerlSetVar SessionManagerTracking On
   </Location>

Also, it is possible to deactivate session management explicitly:

   <Location /my-app-dir-without>
      PerlSetVar SessionManagerTracking Off
   </Location>

B<Note>: If you want to control session management by directory, you cannot use
C<PerlTransHandler>, but you must install the module in a phase where the
mapping of URI->filename has been made.  Generally C<Header parsing> phase is a
good place:

   PerlModule Apache::SessionManager
   <Directory /usr/local/apache/htdocs/perl>
      <FilesMatch "\.perl$">
         SetHandler perl-script
         PerlHandler Apache::Registry
         PerlSendHeader On
         PerlSetupEnv   On
         Options ExecCGI

         PerlHeaderParserHandler Apache::SessionManager
         PerlSetVar SessionManagerTracking On
         PerlSetVar SessionManagerExpire 3600
         PerlSetVar SessionManagerInactivity 900
         PerlSetVar SessionManagerName REGISTRY_SESSIONID
         PerlSetVar SessionManagerStore File
         PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_sessions"
      </FilesMatch>
   </Directory>

=head2 Configuring via F<.htaccess>

In the case you don't have access to F<httpd.conf> or you want work with
F<.htaccess> files only , you can put similar directives directly into  an
F<.htaccess> file:

   <FilesMatch "\.(cgi|pl)$">
      PerlHeaderParserHandler Apache::SessionManager
      PerlSetVar SessionManagerTracking On
      PerlSetVar SessionManagerExpire 3600
      PerlSetVar SessionManagerInactivity 900
      PerlSetVar SessionManagerName PERLSESSIONID
      PerlSetVar SessionManagerStore File
      PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_session"
      PerlSetVar SessionManagerDebug 5
   </FilesMatch> 

The only difference is that you cannot use C<Location> directive (I used
C<FilesMatch>) and you must install Apache::SessionManager in C<Header parsing>
phase of Apache request instead of C<URI translation> phase.

=head2 Notes on using F<.htaccess> instead of F<httpd.conf>

=over 4

=item *

In this cases it is necessary to install Apache::SessionManager in C<Header
parsing>  phase and not into C<URI translation> phase (in this phase,
F<.htaccess> hasn't yet  been processed).

=item *

Using F<.htaccess>, it is possible to use only cookies for the session
tracking.

=back

See L<Apache::SessionManager::cookpod|Apache::SessionManager::cookpod> for more
info  about module configuration and use within thirdy part packages.

=head1 DIRECTIVES

You can control the behaviour of this module by configuring the following
variables with C<PerlSetVar> directive  in the F<httpd.conf> (or F<.htaccess>
files)

=over 4

=item C<SessionManagerTracking> On|Off

This single directive enables session traking

   PerlSetVar SessionManagerTracking On

It can be placed in server config, <VirtualHost>, <Directory>,  <Location>,
<Files> and F<.htaccess> context.
The default value is C<Off>.

=item C<SessionManagerURITracking> On|Off

This single directive enables session URI traking

   PerlSetVar SessionManagerURITracking On

where the session ID is embedded in the URI. This is a possible cookieless
solution to track session ID between browser and server. Please see L</URI
TRACKING NOTES> section below for more details. The default value is C<Off>.

=item C<SessionManagerExpire> number

This single directive defines global sessions expiration time (in seconds).

   PerlSetVar SessionManagerExpire 900

If non set, the default value is C<3600> seconds. A C<0> explicit value means
no expiration time session control, and the session will die when the user will
close the browser. 

Because both mod_perl 1 (to 1.29) and 2 (to 1.99_11, fixed in 1.99_12-dev) has a
bug which with "C<PerlSetVar Foo 0>", C<$-E<gt>dir_config('Foo')> return C<undef>
instead of C<0>, there are the aliases C<none> or C<no> or C<disabled>
which can be used instead of C<0>:

   PerlSetVar SessionManagerExpire none

The module put the user start session time in a special session key 
C<_session_start>.

=item C<SessionManagerInactivity> number

This single directive defines user inactivity sessions expiration time (in
seconds).

   PerlSetVar SessionManagerInactivity 900

If not specified no user inactivity expiration policies are applied. The module
put the user timestamp in a special session key  C<_session_timestamp>.

=item C<SessionManagerName> string

This single directive defines session cookie name

   PerlSetVar SessionManagerName PSESSID

The default value is C<PERLSESSIONID>

=item C<SessionManagerCookieArgs>

With this directive you can provide optional arguments  for cookie attributes
setting. The arguments are passed as comma-separated list of name/value pairs.
The only attributes accepted are:

=over 4

=item * Domain

Set the domain for the cookie.

=item * Path

Set the path for the cookie.

=item * Secure

Set the secure flag for the cookie. 

=item * Expires

Set expire time for the cookie.

=back

For instance:

   PerlSetVar SessionManagerCookieArgs "Path   => /some-path, \
                                        Domain => .yourdomain.com, \
                                        Secure => 1"

Please see the documentation for L<Apache::Cookie|Apache::Cookie> or
L<CGI::Cookie|CGI::Cookie> in order to see more cookie arguments details.

=item C<SessionManagerStore> datastore

This single directive sets the session datastore used by
L<Apache::Session|Apache::Session> framework

   PerlSetVar SessionManagerStore File

The following datastore plugins are available with 
L<Apache::Session|Apache::Session> distribution:

=over 4

=item * File

Sessions are stored in file system

=item * MySQL

Sessions are stored in MySQL database

=item * Postgres

Sessions are stored in Postgres database

=item * Sybase

Sessions are stored in Sybase database

=item * Oracle

Sessions are stored in Oracle database

=item * DB_File

Sessions are stored in DB files

=back

In addition to datastore plugins shipped with
L<Apache::Session|Apache::Session>, you can pass the modules you want to use as
arguments to the store constructor. The Apache::Session::Whatever part is
appended for you: you should not supply it.

If you wish to use a module of your own making, you should  make sure that it
is available under the L<Apache::Session|Apache::Session> package namespace.
For example:

   PerlSetVar SessionManagerStore SharedMem

in order to use L<Apache::Session::SharedMem|Apache::Session::SharedMem> to
store sessions in RAM (but you must install
L<Apache::Session::SharedMem|Apache::Session::SharedMem>  before!)

The default value is C<File>.

=item C<SessionManagerLock> Null|MySQL|Semaphore|File

This single directive set lock manager for
L<Apache::Session::Flex|Apache::Session::Flex>. The default value is C<Null>.

=item C<SessionManagerGenerate> MD5|ModUniqueId|ModUsertrack

This single directive set session ID generator for
L<Apache::Session::Flex|Apache::Session::Flex>. The default value is C<MD5>.

=item C<SessionManagerSerialize> Storable|Base64|UUEncode

This single directive set serializer for
L<Apache::Session::Flex|Apache::Session::Flex>. The default value is
C<Storable>.

=item C<SessionManagerStoreArgs>

With this directive you must provide whatever arguments are expected by the
backing store and lock manager  that you've chosen. The arguments are passed as
comma-separated  list of name/value pairs.

For instance if you use File for your datastore, you need to pass store and
lock directories:

   PerlSetVar SessionManagerStoreArgs "Directory     => /tmp/apache_sessions, \
                                       LockDirectory => /tmp/apache_sessions/lock"

If you use MySQL for your datastore, you need to pass database connection
informations:

   PerlSetVar SessionManagerStoreArgs "DataSource => dbi:mysql:sessions, \
                                       UserName   => user, \
                                       Password   => password" 

Please see the documentation for store/lock modules in order to pass right
arguments.

=item C<SessionManagerItemExclude> string|regex

This single directive defines the exclusion string. For example:

   PerlSetVar SessionManagerItemExclude exclude_string

All the HTTP requests containing the 'exclude_string' string in the URI will be
declined. Also is possible to use regex:

   PerlSetVar SessionManagerItemExclude "\.m.*$"

and all the request (URI) ending by ".mpeg", ".mpg" or ".mp3" will be declined.

If C<SessionManagerItemExclude> isn't defined, the default value is:

C<(\.gif|\.jpe?g|\.png|\.mpe?g|\.css|\.js|\.txt|\.mp3|\.wav|\.swf|\.avi|\.au|\.ra?m)$>

B<Note> If you want process each request, you can set
C<SessionManagerItemExclude> with:

   PerlSetVar SessionManagerItemExclude "^$"

=item C<SessionManagerHeaderExclude>

This directive allows to define HTTP headers contents in order to decline
requests that match them. For example:

   PerlSetVar SessionManagerHeaderExclude "User-Agent => SomeBot"

All the HTTP requests containing the 'SomeBot' string in the HTTP C<User-Agent>
header will be declined. Also is possible to use regex:

   PerlSetVar SessionManagerHeaderExclude "User-Agent => SomeBot\s*/\*\d+\.\d+"

All HTTP headers are available (case sensitive) to use in the exclusion rules.

In order to set more than one rule you must use C<PerlAddVar> directive:

   PerlSetVar SessionManagerHeaderExclude "User-Agent => SomeBot\s*/\*\d+\.\d+"
   PerlAddVar SessionManagerHeaderExclude "User-Agent => GoogleBot"
   PerlAddVar SessionManagerHeaderExclude "Referer => ^http:\/\/some\.host\.com"

Why could be useful to decline request based on HTTP headers check? If you
store session ID in the URI, this prevent bot search engines to index URL with
the session ID.

=item C<SessionManagerIPExclude> IP-list

Matchs client IP addresses against IP list and declines request.
It's possible to set an IP address and optionally a bitmask:

233.76.193.0/24

233.76.193.1/32 (or simply 233.76.193.1)

For example:

   PerlSetVar SessionManagerIPExclude "127.0.0.0/8 192.168.0.0/16 195.31.218.3"

Note that since C<1.03> Apache::SessionManager version, non dotted-quad IP
will be skipped.

=item C<SessionManagerSetEnv> On|Off

Sets the C<SESSION_MANAGER_SID> environment variable with the current (valid)
session ID:

   PerlSetVar SessionManagerSetEnv On

It makes session ID available to CGI scripts for use in absolute links or
redirects. The default value is C<Off>.

To retrieve the C<SESSION_MANAGER_SID> environment variabile you can do, for
instance:

=over 

=item * mod_perl

   print $r->subprocess_env('SESSION_MANAGER_SID');

=item * CGI

   print $ENV{'SESSION_MANAGER_SID'};

=item * Server Side Includes

   <!--#echo var="SESSION_MANAGER_SID" -->

=back

=item C<SessionManagerDebug> level

This single directive set debug level.

   PerlSetVar SessionManagerDebug 3

If greather than zero, debug informations will be print to STDERR. The default
value is C<0> (no debug information will be print).

=item C<SessionManagerEnableModBackhand> On|Off

This single directive enable mod_backhand sticky session load balancing
support.
Someone asked me this feature, so I've added it.

   PerlSetVar SessionManagerEnableModBackhand On

A few words on mod_backhand. mod_backhand is a load balancing Apache module.
mod_backhand can attempt to find a cookie in order to hex decodes the first 8 
bytes of its content into an IPv4 style IP address.
It will attempt to find this IP address in the list of candidates and if it is
found it will make the server in question the only remaining candidate. This
can be used to implement sticky user sessions -- where a  given user will
always be delivered to the same server once a session  has been established.
Simply turning on this directive, you add hex IP address in front to
session_id. See mod_backhand docs for more details 
(L<http://www.backhand.org/mod_backhand|http://www.backhand.org/mod_backhand>).

The default value is C<Off>.

=back

=head1 URI TRACKING NOTES

There are some considerations and issues in order to use the session ID
embedded in the URI. In fact, this is a possible cookieless solution to track
session ID between browser and server.

If you enable session ID URI tracking you must place all the  C<PerlSetVar>
directives you need in server config context (that is  outside of <Directory>
or <Location> sections) otherwise the handler  will not work for these
requests. The reason of this is that the URI will  be rewrite with session ID
on the left and all <Location> that you've defined  will match no longer.

Alternatively it is possible to use <LocationMatch> section. For instance:

   PerlModule Apache::SessionManager
   PerlTransHandler Apache::SessionManager

   <LocationMatch "^/([0-9a-h]+/)?my-app-dir">
      SetHandler perl-script
      PerlHandler MyModule
      PerlSetVar SessionManagerTracking On
      PerlSetVar SessionManagerURITracking On
      PerlSetVar SessionManagerStore File
      PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_sessions"
   </LocationMatch>

to match also URI with embedded session ID.

Another issue is if you use a front-end/middle-end  architecture with a reverse
proxy front-end server in front (for static content) and a mod_perl enabled
server in middle tier to serve dynamic contents.
If you use Apache as reverse proxy it became impossible to set the ProxyPass
directive either because it can be palced only in server config and/or
<VirtualHost> context, either because it isn't support for regex to match
session ID embedded in the URI.

In this case, you can use the proxy support available via the C<mod_rewrite>
Apache module by putting  in front-end server's F<httpd.conf>:

   ProxyPass /my-app-dir http://middle-end.server.com:9000/my-app-dir
   ProxyPassReverse / http://middle-end.server.com:9000/

   RewriteEngine On
   RewriteRule (^/([0-9a-h]+/)?my-app-dir.*) http://middle-end.server.com:9000$1 [P,L]

Take careful to make all links to static content as non relative link (use
"http://myhost.com/images/foo.gif" or "/images/foo.gif") or the rewrite engine
will proxy these requests to mod_perl server.

=head1 EXAMPLES

This is a simple mod_perl handler F<Apache/MyModule.pm>:

   package Apache::MyModule;
   use strict;
   use Apache::Constants qw(:common);

   sub handler {
      my $r = shift;

      # retrieve session
      my $session = Apache::SessionManager::get_session($r);

      # set a value in current session
      $$session{'key'} = "some value";
      # same as
      $session->{'key'} = "some value";

      # read value session
      print $$session{'key'};
      # same as
      print $session->{'key'};

      # destroy session explicitly
      Apache::SessionManager::destroy_session($r);

      ...

      return OK;
   } 

and the correspondent configuration lines in F<httpd.conf>:

   PerlModule Apache::SessionManager
   PerlTransHandler Apache::SessionManager

   <Location /mymodule>
      SetHandler perl-script
      PerlHandler Apache::MyModule
      PerlSetVar SessionManagerTracking On
      PerlSetVar SessionManagerExpire 3600
      PerlSetVar SessionManagerInactivity 900
      PerlSetVar SessionManagerStore File
      PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_sessions"
   </Location>  

See also F<t/lib> directory of this distribution for more examples used in
Apache live tests.

=head1 TODO

=over 4

=item *

Use Apache::Test instead of Apache::testold for testing

=item * 

Add the possibility of auto-switch session ID tracking  from cookie to URI in
cookieless situation.

=item * 

Add the query string param support (other than cookie and URI) to track session
ID between browser and server.

=item * 

Include into the distro the session cleanup script (the scripts I use for 
cleanup actually)

=item * 

Embed the cleanup policies not in a external scripts but in a register_cleanup
method

=item * 

Test, test ,test ;-)

=back

=head1 AUTHORS

Enrico Sorcinelli <enrico at sorcinelli.it>

=head1 THANKS

A particular thanks to Greg Cope <gjjc at rubberplant.freeserve.co.uk> for
freeing Apache::SessionManager namespace from his RFC (October 2000). His
SessionManager project can be found at 
http://sourceforge.net/projects/sessionmanager

=head1 BUGS 

This library has been tested by the author with Perl versions 5.005, 5.6.x and
5.8.x on different platforms: Linux 2.2 and 2.4, Solaris 2.6 and 2.7 and
Windows 98/XP.

Please submit bugs to CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-SessionManager
or by email at bug-apache-sessionmanager@rt.cpan.org

Patches are welcome and I'll update the module if any problems will be found.

=head1 VERSION

Version 1.03

=head1 SEE ALSO

L<Apache::SessionManager::cookpod|Apache::SessionManager::cookpod>,
L<Apache::Session|Apache::Session>, L<Apache::Session::Flex|Apache::Session::Flex>, 
L<Apache::Request|Apache::Request>, L<Apache::Cookie|Apache::Cookie>, 
L<CGI::Cookie|CGI::Cookie>, L<Apache|Apache>, perl(1)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2004 Enrico Sorcinelli. All rights reserved. 
This program is free software; you can redistribute it  and/or modify it under
the same terms as Perl itself. 

=cut
