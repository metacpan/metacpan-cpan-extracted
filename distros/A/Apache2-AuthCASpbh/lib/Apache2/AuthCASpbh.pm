package Apache2::AuthCASpbh;

use strict;
use warnings;

use parent qw(Exporter);

our @EXPORT_OK = qw(cfg_value open_session);

use Apache2::CmdParms qw();
use Apache2::Const -compile => qw(OR_ALL TAKE1 FLAG ITERATE);
use Apache2::Directive qw();
use Apache2::Module qw();
use Apache2::ServerUtil qw();
use Apache::Session::Browseable::SQLite qw();
use Storable qw();

our $VERSION = '0.20';

my %session_dbh;

my @directives = (
	{ name         => 'DebugLevel',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^(alert|crit|debug|emerg|error|info|notice|warn)$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<apache log level>',
	  default      => 'debug'
	},
	{ name         => 'LoginPath',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^/([^?#]+)(\?([^#]*))?(#(.*))?$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL path>',
	  default      => '/login'
	},
	{ name         => 'PGTCallback',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^((([^:/?#]+):)(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?|/([^?#]+)(\?([^#]*))?(#(.*))?)$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL|URL path>',
	  default      => '/cas_pgt'
	},
	{ name         => 'PGTIOU_TTL',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^[1-9]\d*$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<time in seconds>',
	  default      => '10'
	},
	{ name         => 'ProxyAllow',
	  func         => __PACKAGE__ . '::StoreConfigArray',
	  cmd_data     => '^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::ITERATE,
	  errmsg       => '<URL>[ <URL>]...',
	},
	{ name         => 'ProxyAllowRE',
	  func         => __PACKAGE__ . '::StoreConfigRegexArray',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::ITERATE,
	  errmsg       => '<regex>[ <regex>]...',
	},
	{ name         => 'ProxyPath',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^/([^?#]+)(\?([^#]*))?(#(.*))?$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL path>',
	  default      => '/proxy'
	},
	{ name         => 'ProxyRequire',
	  func         => __PACKAGE__ . '::StoreConfigFlag',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::FLAG,
	  default      => '0'
	},
	{ name         => 'ProxyValidatePath',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^/([^?#]+)(\?([^#]*))?(#(.*))?$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL path>',
	  default      => '/proxyValidate'
	},
	{ name         => 'RemoveServiceTicket',
	  func         => __PACKAGE__ . '::StoreConfigFlag',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::FLAG,
	  default      => '0'
	},
	{ name         => 'RequestPGT',
	  func         => __PACKAGE__ . '::StoreConfigFlag',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::FLAG,
	  default      => '0'
	},
	{ name         => 'ServerURL',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^(([^:/?#]+):)(//([^/?#]*))?([^?#]*)$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL>',
	  default      => 'http://localhost/cas'
	},
	{ name         => 'ServiceOverride',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^(([^:/?#]+):)(//([^/?#]*))?([^?#]*)$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL>',
	},
	{ name         => 'ServiceValidatePath',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^/([^?#]+)(\?([^#]*))?(#(.*))?$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL path>',
	  default      => '/serviceValidate'
	},
	{ name         => 'SessionCleanupInterval',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^[1-9]\d*$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<seconds>',
	  default      => '3600'
	},
	{ name         => 'SessionCookieName',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^[a-zA-z0-9_-]+$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<[a-zA-z0-9_-]+>',
	  default      => 'AuthCAS_Session'
	},
	{ name         => 'SessionCookiePath',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^/([^?#]+)$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<URL path>',
	},
	{ name         => 'SessionCookieSecure',
	  func         => __PACKAGE__ . '::StoreConfigFlag',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::FLAG,
	  default      => '1'
	},
	{ name         => 'SessionDBName',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^[^/\x00]+$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<filename>',
	  default      => 'authcas_sessions.db'
	},
	{ name         => 'SessionDBPath',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^/[^\x00]+$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<path>',
	  default      => '/tmp'
	},
	{ name         => 'SessionStateName',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^[a-fA-F0-9]{1,64}$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<[a-fA-F0-9]{1,64}>',
	  default      => 'ABC123'
	},
	{ name         => 'SessionTTL',
	  func         => __PACKAGE__ . '::StoreConfig',
	  cmd_data     => '^[1-9]\d*$',
	  req_override => Apache2::Const::OR_ALL,
	  args_how     => Apache2::Const::TAKE1,
	  errmsg       => '<seconds>',
	  default      => '3600'
	},
);

my %default_config;

foreach my $directive (@directives) {

	if (exists($directive->{errmsg})) {
		$directive->{errmsg} =~ s/^/AuthCAS_$directive->{name} /;
	}

	if (exists($directive->{default})) {
		$default_config{$directive->{name}} = $directive->{default};
		delete($directive->{default});
	}

	$directive->{name} =~ s/^/AuthCAS_/;
}

Apache2::Module::add(__PACKAGE__, \@directives);

sub StoreConfig {
	my ($self, $parms, $arg) = @_;
	
	my $directive = $parms->directive;
	my $name = $directive->directive;

	my $regex = $parms->info;
	if ($arg !~ /$regex/) {
		die sprintf "error: %s at %s:%d parameter $arg does not match $regex\n",
			    $name, $directive->filename, $directive->line_num;
	}

	$self->{$name} = $arg;
}

sub StoreConfigArray {
	my ($self, $parms, $arg) = @_;
	
	my $directive = $parms->directive;
	my $name = $directive->directive;

	my $regex = $parms->info;
	if ($arg !~ /$regex/) {
		die sprintf "error: %s at %s:%d parameter $arg does not match $regex\n",
			    $name, $directive->filename, $directive->line_num;
	}

	push(@{$self->{$name}}, $arg);
}

sub StoreConfigFlag {
	my ($self, $parms, $arg) = @_;
	
	my $directive = $parms->directive;
	my $name = $directive->directive;

	$self->{$name} = $arg;
}

sub StoreConfigRegexArray {
	my ($self, $parms, $arg) = @_;
	
	my $directive = $parms->directive;
	my $name = $directive->directive;

	eval { $arg = qr/$arg/; };
	if ($@) {
		die sprintf "error: %s at %s:%d paramter $arg is not a valid regex\n",
			    $name, $directive->filename, $directive->line_num;
	}

	push(@{$self->{$name}}, $arg);
}

sub DIR_CREATE {
	my ($class, $parms) = @_;

	my $self = {};

	return bless($self, $class);
}

sub DIR_MERGE {
	my ($base, $add) = @_;

	my $mrg = Storable::dclone($base);

	foreach (keys %{$add}) {
		$mrg->{$_} = $add->{$_};
	}

	return bless($mrg, ref($base));
}

sub cfg_value {
	my ($dir_cfg, $directive) = @_;

	return $dir_cfg->{"AuthCAS_$directive"} if exists($dir_cfg->{"AuthCAS_$directive"});

	return $default_config{$directive} if exists($default_config{$directive});

	return undef;
}

sub open_session {
	my ($db, $session_id) = @_;

	if (!exists($session_dbh{$db})) {
		$session_dbh{$db} = DBI->connect("dbi:SQLite:$db",'','', { AutoCommit => 1 }) or
			return "DBI connection failed - $DBI::errstr";
	}

	my %session;
	eval { tie(%session, 'Apache::Session::Browseable::SQLite', $session_id,
		    { Handle => $session_dbh{$db}, Commit => 0 }); };

	return $@ ? $@ : \%session;
}

=head1 NAME

AuthCASpbh - CAS SSO integration for Apache/mod_perl

=head1 SYNOPSIS

Load the module in your Apache mod_perl configuration:

	PerlLoadModule Apache2::AuthCASpbh
	AuthCAS_ServerURL https://my.cas.server/cas

and include additional configuration from the ancillary modules as necessary:

L<Apache2::AuthCASpbh::Authn>

L<Apache2::AuthCASpbh::Authz>

L<Apache2::AuthCASpbh::ProxyCB>

L<Apache2::AuthCASpbh::UserAgent>

=head1 DESCRIPTION

AuthCASpbh is a framework for integrating CAS SSO support into the Apache web
server using mod_perl. It can authenticate Apache resources via CAS, perform
authorization via CAS attributes, acquire proxy granting tickets, and provides
a client allowing transparent access to other CAS applications via proxy
authentication. It automatically manages sessions using Apache::Session
(currently via sqlite, but other mechanisms could be used) and provides
mod_perl based applications access to session state and attributes.

=head2 Configuration options

=over

=item C<AuthCAS_DebugLevel>

Use a different logging level for debugging messages generated by AuthCASpbh
rather than the default "debug", allowing visibility into internal operation
without being overwhelmed by debugging output from unrelated components.
Messages can be logged at any supported Apache level, for example:

	AuthCAS_DebugLevel warn

=item C<AuthCAS_LoginPath>

The URL component added after the AuthCAS_ServerURL value to access the CAS
login service; by default "/login".

=item C<AuthCAS_PGTCallback>

The location of the callback used by the configured CAS server when the request
of a proxy granting ticket is enabled. By default, it is the relative URL
"/cas_pgt" on the server running AuthCASpbh; however, it could also be a fully
qualified URL to point it to an arbitrary location:

	AuthCAS_PGTCallback https://some.other.server/cas_pgt

The URL must be served by L<Apache2::AuthCASpbh::ProxyCB> or a compatible
mechanism that will store the proxy ticket information into the global
AuthCASpbh session.

=item C<AuthCAS_PGTIOU_TTL>

The amount of time in seconds that a proxy granting ticket IOU to proxy
granting ticket value mapping will be maintained in the AuthCASpbh global
session. By default it is 10 seconds, and it is unlikely that value would need
to be overridden in normal circumstances.


=item C<AuthCAS_ProxyAllow>

A list of proxy servers to allow access to the AuthCASpbh protected application
if proxied authentication is desired. Proxied authentication is only enabled
if at least one of AuthCAS_ProxyAllow or AuthCAS_ProxyAllowRE is configured for
the location being accessed. For example:

	AuthCAS_ProxyAllow https://my.frontend.server/cas

=item C<AuthCAS_ProxyAllowRE>

A list of regular expressions to be compared to connecting proxy server to
determine whether or not to allow access to the AuthCASpbh protected
application. Proxied authentication is only enabled if at least one of
AuthCAS_ProxyAllow or AuthCAS_ProxyAllowRE is configured for the location being
accessed. For example:

        AuthCAS_ProxyAllow ^https://[^/]+\.my\.domain/

=item C<AuthCAS_ProxyPath>

The URL component added after the AuthCAS_ServerURL value to access the CAS
proxy ticket issuing service; by default "/proxy".

=item C<AuthCAS_ProxyRequire>

If proxied authentication is enabled, only allow access via proxy credentials,
not direct access by a user; by default disabled.

=item C<AuthCAS_ProxyValidatePath>

The URL component added after the AuthCAS_ServerURL value to access the CAS
proxy ticket validation service; by default "/proxyValidate".
=item C<AuthCAS_RemoveServiceTicket>

Whether or not to remove the ticket parameter from the request arguments (eg,
query string) after it is processed; by default disabled. Note that the value
is only removed from the Apache args variable, not from the unparsed URI; if an
application directly accesses the unparsed URI it will still see the value.

=item C<AuthCAS_RequestPGT>

Whether or not to request a proxy granting ticket when a client service ticket
is validated; by default disabled.

=item C<AuthCAS_ServerURL>

The URL value to access the CAS authentication server; by default
"http://localhost/cas". For example:

	AuthCAS_ServerURL https://idp.my.domain/idp/profile/cas


=item C<AuthCAS_ServiceOverride>

A URL with which to override the computed service URL used when redirecting to
the CAS login page or validating a supplied service ticket. For example:

	AuthCAS_ServiceOverride https://my.service/cas-login


=item C<AuthCAS_ServiceValidatePath>

The URL component added after the AuthCAS_ServerURL value to access the CAS
ticket validation service; by default "/serviceValidate".


=item C<AuthCAS_SessionCleanupInterval>

How frequently (in seconds) to remove expired authentication sessions and
examine the global session to remove orphaned expired proxy ticket mappings; by
default 3600 seconds.

=item C<AuthCAS_SessionCookieName>

The name of the cookie sent to the client to store the AuthCASpbh session
identifier; by default "AuthCAS_Session".

=item C<AuthCAS_SessionCookiePath>

An optional path to include in the session cookie.

=item C<AuthCAS_SessionCookieSecure>

Whether or not to set the secure flag on the session cookie; by default
enabled.

=item C<AuthCAS_SessionDBName>

The filename of the sqlite database used to store session information; by
default "authcas_sessions.db". Prior to use of AuthCASpbh, the database must be
created and the schema created using the following command within sqlite:

	CREATE TABLE sessions (
		id char(32) not null primary key,
		a_session text
	);

In addition, the global state session must be created.  If using the default
SessionStateName value of "ABC123" this can be accomplished by:

	insert into sessions (id, a_session) values ('ABC123', '{"_session_id":"ABC123"}');

Finally, the service account used by the Apache web server must be granted
access to this file by whatever mechanism is appropriate for your deployment.

=item C<AuthCAS_SessionDBPath>

The path to the sqlite database used to store session information; by default
"/tmp".

=item C<AuthCAS_SessionStateName>

The name of the session used to maintain AuthCASpbh global state; by default
"ABC123".

=item C<AuthCAS_SessionTTL>

How long in seconds an AuthCASpbh authentication session should be valid; by
default 3600 seconds. Note that if you are utilizing client proxy
authentication with the session that this value should not exceed the lifetime
of the proxy granting ticket provided by your CAS server or failures to acquire
proxy tickets might occur.

=back

=head1 AVAILABILITY

AuthCASpbh is available via CPAN as well as on GitHub at

https://github.com/pbhenson/Apache2-AuthCASpbh

=head1 AUTHOR

Copyright (c) 2018, Paul B. Henson <henson@acm.org>

This file is part of AuthCASpbh.

AuthCASpbh is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

AuthCASpbh is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
AuthCASpbh.  If not, see <http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<Apache2::AuthCASpbh::Authn> - Authentication functionality

L<Apache2::AuthCASpbh::Authz> - Authorization functionality

L<Apache2::AuthCASpbh::ProxyCB> - Proxy granting ticket callback module

L<Apache2::AuthCASpbh::UserAgent> - Proxy authentication client

=cut

1;
