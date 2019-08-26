package Apache::Defaults;
use strict;
use warnings;
use File::Spec;
use IPC::Open3;
use Shell::GetEnv;
use DateTime::Format::Strptime;
use Text::ParseWords;
use Symbol 'gensym';
use Carp;

our $VERSION = '1.02';

sub new {
    my $class = shift;
    my $self = bless { on_error => 'croak' }, $class;
    local %_ = @_;
    my $v;

    if (my $v = delete $_{on_error}) {
	croak "invalid on_error value"
	    unless grep { $_ eq $v } qw(croak return);
	$self->{on_error} = $v;
    }
    
    my @servlist;
    if ($v = delete $_{server}) {
	if (ref($v) eq 'ARRAY') {
	    @servlist = @$v;
	} else {
	    @servlist = ( $v );
	}
    } else {
	@servlist = qw(/usr/sbin/apachectl /usr/sbin/httpd /usr/sbin/apache2);
    }
    
    if (my @select = grep { -x $_->[0] }
                      map { [ shellwords($_) ] } @servlist) {
	$self->{server} = shift @select;
    } elsif ($self->{on_error} eq 'return') {
	$self->{status} = 127;
	$self->{error} = "No suitable httpd binary found";
    } else {
	croak "No suitable httpd binary found";
    }

    my $envfile = delete $_{environ};
    croak "unrecognized arguments" if keys(%_);

    if ($envfile) {
	unless (-f $envfile) {
	    if ($self->{on_error} eq 'return') {
                $self->{status} = 127;
		$self->{error} = "environment file $envfile does not exist";
		return $self;
	    } else {
		croak "environment file $envfile does not exist";
	    }
	}
	unless (-r $envfile) {
	    if ($self->{on_error} eq 'return') {
                $self->{status} = 127;
		$self->{error} = "environment file $envfile is not readable";
		return $self;
	    } else {
		croak "environment file $envfile is not readable";
	    }
	}

	my $env = eval {
            Shell::GetEnv->new('sh', ". $envfile", { startup => 0 });
        };
        if ($@) {
            if ($self->{on_error} eq 'return') {
                $self->{status} = 127;
                $self->{error} = $@;
		return $self;
            } else {
                croak $@;
            }
        } elsif ($env->status) {
	    if ($self->{on_error} eq 'return') {
		$self->{status} = $env->status;
		$self->{error} = "Failed to inherit environment";
		return $self;
	    } else {
		croak sprintf("Got status %d trying to inherit environment",
			      $env->status);
	    }
	} else {
  	    $self->{environ} = $env->envs;
        }        
     }

    $self->_get_version_info unless $self->status;
    $self->_get_module_info unless $self->status;
    
    return $self;
}	    

sub server { shift->{server}[0] }
sub server_command { @{shift->{server}} }
sub environ { shift->{environ} }

sub probe {
    my ($self, $cb, @opt) = @_;

    open(my $nullin, '<', File::Spec->devnull);

    my $out = gensym;
    my $err = gensym;
    local %ENV = %{$self->{environ}} if $self->{environ};
    if (my $pid = open3($nullin, $out, $err,
			$self->server_command, @opt)) {
	while (<$out>) {
	    chomp;
	    last unless &{$cb}($_);
	}
	waitpid($pid, 0);
	if ($self->{on_error} eq 'croak') {
	    if ($? == -1) {
		croak "failed to execute " .$self->server . ": $!";
	    } elsif ($? & 127) {
		croak sprintf("%s died with signal %d%s",
			      $self->server, $? & 127,
			      ($? & 128) ? ' (core dumped)' : '');
	    } elsif (my $code = $? >> 8) {
		local $/ = undef;
		croak sprintf("%s terminated with status %d; error message: %s",
			      $self->server, $code, <$err>);
	    }
	} elsif ($?) {
	    local $/ = undef;
	    $self->{status} = $?;
	    $self->{error} = <$err>;
	}
    }
    close $nullin;
    close $out;
    close $err;
}    

sub dequote {
    my ($self, $arg) = @_;
    if ($arg =~ s{^"(.*?)"$}{$1}) {
	$arg =~ s{\\([\\"])}{$1}g;
    }
    return $arg;
}

sub _get_version_info {
    my $self = shift;
    $self->probe(sub {
	    local $_ = shift;
	    if (m{^Server version:\s+(.+?)/(\S+)\s+\((.*?)\)}) {
		$self->{name} = $1;
		$self->{version} = $2;
		$self->{platform} = $3;
	    } elsif (/^Server built:\s+(.+)/) {
		$self->{built} =
		    DateTime::Format::Strptime->new(
			pattern => '%b %d %Y %H:%M%S',
			locale => 'en_US',
			time_zone => 'UTC',
			on_error => 'undef'
		    )->parse_datetime($1);
			
	    } elsif (/^Server loaded:\s+(.+)$/) {
		$self->{loaded_with} = $1;
	    } elsif (/^Compiled using:\s+(.+)$/) {
		$self->{compiled_with} = $1;
	    } elsif (/^Architecture:\s+(.+)$/) {
		$self->{architecture} = $1;
	    } elsif (/^Server MPM:\s+(.+)$/) {
		$self->{MPM} = $1;
            } elsif (/^\s+threaded:\s+(?<b>yes|no)/) {
		$self->{MPM_threaded} = $+{b} eq 'yes';
	    } elsif (/^\s+forked:\s+(?<b>yes|no)/) {
		$self->{MPM_forked} = $+{b} eq 'yes';
	    } elsif (/^\s+-D\s+(?<name>.+?)=(?<val>.+)$/) {
		$self->{defines}{$+{name}} = $self->dequote($+{val});
	    } elsif (/^\s+-D\s+(?<name>\S+)(?:\s*(?<com>.+))?$/) {
		$self->{defines}{$+{name}} = 1;
	    }
	    return 1;
        }, '-V');
}

my @ATTRIBUTES = qw(status error
                    name
                    version
                    platform
                    built
                    loaded_with
                    compiled_with
                    architecture
                    MPM
                    MPM_threaded
                    MPM_forked);
{
    no strict 'refs';
    foreach my $attribute (@ATTRIBUTES) {
	*{ __PACKAGE__ . '::' . $attribute } = sub { shift->{$attribute} }
    }
}

sub server_root { shift->defines('HTTPD_ROOT') }

sub server_config {
    my $self = shift;
    my $conf = $self->defines('SERVER_CONFIG_FILE');
    if ($conf && !File::Spec->file_name_is_absolute($conf)) {
	$conf = File::Spec->catfile($self->server_root, $conf);
    }
    return $conf;
}

sub defines {
    my $self = shift;
    if (@_) {
	return @{$self->{defines}}{@_};
    }
    return sort keys %{$self->{defines}};
}

# List of module sources and corresponding identifiers, obtained from the
# httpd-2.4.6 source.
my %modlist = (
    'event.c' => 'mpm_event_module',
    'prefork.c' => 'mpm_prefork_module',
    'worker.c' => 'mpm_worker_module',
    'mod_access_compat.c' => 'access_compat_module',
    'mod_actions.c' => 'actions_module',
    'mod_alias.c' => 'alias_module',
    'mod_allowmethods.c' => 'allowmethods_module',
    'mod_asis.c' => 'asis_module',
    'mod_auth_basic.c' => 'auth_basic_module',
    'mod_auth_digest.c' => 'auth_digest_module',
    'mod_auth_form.c' => 'auth_form_module',
    'mod_authn_anon.c' => 'authn_anon_module',
    'mod_authn_core.c' => 'authn_core_module',
    'mod_authn_dbd.c' => 'authn_dbd_module',
    'mod_authn_dbm.c' => 'authn_dbm_module',
    'mod_authn_file.c' => 'authn_file_module',
    'mod_authn_socache.c' => 'authn_socache_module',
    'mod_authnz_ldap.c' => 'authnz_ldap_module',
    'mod_authz_core.c' => 'authz_core_module',
    'mod_authz_dbd.c' => 'authz_dbd_module',
    'mod_authz_dbm.c' => 'authz_dbm_module',
    'mod_authz_groupfile.c' => 'authz_groupfile_module',
    'mod_authz_host.c' => 'authz_host_module',
    'mod_authz_owner.c' => 'authz_owner_module',
    'mod_authz_user.c' => 'authz_user_module',
    'mod_autoindex.c' => 'autoindex_module',
    'mod_buffer.c' => 'buffer_module',
    'mod_cache.c' => 'cache_module',
    'mod_cache_disk.c' => 'cache_disk_module',
    'mod_cache_socache.c' => 'cache_socache_module',
    'mod_cern_meta.c' => 'cern_meta_module',
    'mod_cgi.c' => 'cgi_module',
    'mod_cgid.c' => 'cgid_module',
    'mod_charset_lite.c' => 'charset_lite_module',
    'mod_data.c' => 'data_module',
    'mod_dav.c' => 'dav_module',
    'mod_dav_fs.c' => 'dav_fs_module',
    'mod_dav_lock.c' => 'dav_lock_module',
    'mod_dbd.c' => 'dbd_module',
    'mod_deflate.c' => 'deflate_module',
    'mod_dialup.c' => 'dialup_module',
    'mod_dir.c' => 'dir_module',
    'mod_dumpio.c' => 'dumpio_module',
    'mod_echo.c' => 'echo_module',
    'mod_env.c' => 'env_module',
    'mod_example.c' => 'example_module',
    'mod_expires.c' => 'expires_module',
    'mod_ext_filter.c' => 'ext_filter_module',
    'mod_file_cache.c' => 'file_cache_module',
    'mod_filter.c' => 'filter_module',
    'mod_headers.c' => 'headers_module',
    'mod_heartbeat' => 'heartbeat_module',
    'mod_heartmonitor.c' => 'heartmonitor_module',
    'mod_ident.c' => 'ident_module',
    'mod_imagemap.c' => 'imagemap_module',
    'mod_include.c' => 'include_module',
    'mod_info.c' => 'info_module',
    'mod_isapi.c' => 'isapi_module',
    'mod_lbmethod_bybusyness.c' => 'lbmethod_bybusyness_module',
    'mod_lbmethod_byrequests.c' => 'lbmethod_byrequests_module',
    'mod_lbmethod_bytraffic.c' => 'lbmethod_bytraffic_module',
    'mod_lbmethod_heartbeat.c' => 'lbmethod_heartbeat_module',
    'util_ldap.c' => 'ldap_module',
    'mod_log_config.c' => 'log_config_module',
    'mod_log_debug.c' => 'log_debug_module',
    'mod_log_forensic.c' => 'log_forensic_module',
    'mod_logio.c' => 'logio_module',
    'mod_lua.c' => 'lua_module',
    'mod_macro.c' => 'macro_module',
    'mod_mime.c' => 'mime_module',
    'mod_mime_magic.c' => 'mime_magic_module',
    'mod_negotiation.c' => 'negotiation_module',
    'mod_nw_ssl.c' => 'nwssl_module',
    'mod_privileges.c' => 'privileges_module',
    'mod_proxy.c' => 'proxy_module',
    'mod_proxy_ajp.c' => 'proxy_ajp_module',
    'mod_proxy_balancer.c' => 'proxy_balancer_module',
    'mod_proxy_connect.c' => 'proxy_connect_module',
    'mod_proxy_express.c' => 'proxy_express_module',
    'mod_proxy_fcgi.c' => 'proxy_fcgi_module',
    'mod_proxy_fdpass.c' => 'proxy_fdpass_module',
    'mod_proxy_ftp.c' => 'proxy_ftp_module',
    'mod_proxy_html.c' => 'proxy_html_module',
    'mod_proxy_http.c' => 'proxy_http_module',
    'mod_proxy_scgi.c' => 'proxy_scgi_module',
    'mod_proxy_wstunnel.c' => 'proxy_wstunnel_module',
    'mod_ratelimit.c' => 'ratelimit_module',
    'mod_reflector.c' => 'reflector_module',
    'mod_remoteip.c' => 'remoteip_module',
    'mod_reqtimeout.c' => 'reqtimeout_module',
    'mod_request.c' => 'request_module',
    'mod_rewrite.c' => 'rewrite_module',
    'mod_sed.c' => 'sed_module',
    'mod_session.c' => 'session_module',
    'mod_session_cookie.c' => 'session_cookie_module',
    'mod_session_crypto.c' => 'session_crypto_module',
    'mod_session_dbd.c' => 'session_dbd_module',
    'mod_setenvif.c' => 'setenvif_module',
    'mod_slotmem_plain.c' => 'slotmem_plain_module',
    'mod_slotmem_shm.c' => 'slotmem_shm_module',
    'mod_so.c' => 'so_module',
    'mod_socache_dbm.c' => 'socache_dbm_module',
    'mod_socache_dc.c' => 'socache_dc_module',
    'mod_socache_memcache.c' => 'socache_memcache_module',
    'mod_socache_shmcb.c' => 'socache_shmcb_module',
    'mod_speling.c' => 'speling_module',
    'mod_ssl.c' => 'ssl_module',
    'mod_status.c' => 'status_module',
    'mod_substitute.c' => 'substitute_module',
    'mod_suexec.c' => 'suexec_module',
    'mod_unique_id.c' => 'unique_id_module',
    'mod_unixd.c' => 'unixd_module',
    'mod_userdir.c' => 'userdir_module',
    'mod_usertrack.c' => 'usertrack_module',
    'mod_version.c' => 'version_module',
    'mod_vhost_alias.c' => 'vhost_alias_module',
    'mod_watchdog.c' => 'watchdog_module',
    'mod_xml2enc.c' => 'xml2enc_module'
);

sub preloaded {
    my $self = shift;
    if (@_) {
	return @{$self->{preloaded}}{@_};
    }
    return sort keys %{$self->{preloaded}};
}

sub _get_module_info {
    my $self = shift;
    $self->probe(sub {
	                    local $_ = shift;
#			    print "GOT $_\n";
			    if (/^\s*(\S+\.c)$/ && exists($modlist{$1})) {
				$self->{preloaded}{$modlist{$1}} = $1;
			    }
			    return 1;
		     }, '-l');
}

1;
__END__
=head1 NAME

Apache::Defaults - Get default settings for Apache httpd daemon

=head1 SYNOPSIS

    $x = new Apache::Defaults;
    print $x->name;
    print $x->version;
    print $x->server_root;
    print $x->server_config;
    print $x->built;
    print $x->architecture;
    print $x->MPM;
    print $x->defines('DYNAMIC_MODULE_LIMIT');
    print $x->preloaded('cgi_module');

=head1 DESCRIPTION

Detects the default settings of the Apache httpd daemon by invoking
it with appropriate options and analyzing its output.

=head1 METHODS

=head2 new

    $x = new Apache::Defaults(%attrs);

Detects the settings of the apache server and returns the object representing
them. Attributes (I<%attrs>) are:

=over 4

=item C<server>

Full pathname of the B<httpd> binary to inspect. The argument can also be
a reference to the list of possible pathnames. In this case, the first of
them that exists on disk and has executable privileges will be used. Full
command line can also be used, e.g.:

    server => '/usr/sbin/httpd -d /etc/httpd'

The default used in the absense of this attribute is:

    [ '/usr/sbin/apachectl', '/usr/sbin/httpd', '/usr/sbin/apache2' ]

The use of B<apachectl> is preferred over directly invoking B<httpd> daemon,
because the apache configuration file might contain referenmces to environment
variables defined elsewhere, which will cause B<httpd> to fail. B<apachectl>
takes care of this by including the file with variable definitions prior to
calling B<httpd>. See also C<environ>, below.    
    
=item C<environ>

Name of the shell script that sets the environment for B<httpd> invocation.
Usually, this is the same script that is sourced by B<apachectl> prior to
passing control over to B<httpd>. This option provides another solution to
the environment problem mentioned above. E.g.:

    $x = new Apache::Defaults(environ => /etc/apache2/envvars)

=item C<on_error>

Controls error handling. Allowed values are C<croak> and C<return>.
If the value is C<croak> (the default), the method will I<croak> if an
error occurs. If set to C<return>, the constructor will return a valid
object. The B<httpd> exit status and diagnostics emitted to the stderr
will be available via the B<status> and B<error> methods.

=back

=head2 status

    $x = new Apache::Defaults(on_error => 'return');
    if ($x->status) {
        die $x->error;
    }

Returns the status of the last B<httpd> invocation (i.e. the value of
the B<$?> perl variable after B<waitpid>). The caller should inspect
this value, after constructing an B<Apache::Defaults> object with
the C<on_error> attribute set to C<return>.

=head2 error

Returns additional diagnostics if B<$x-E<gt>status != 0>. Normally, these are
diagnostic messages that B<httpd> printed to standard error before
termination.    
    
=head2 server

    $s = $x->server;
    
Returns the pathname of the B<httpd> binary.

=head2 server_command

    @cmd = $x->server_command;

Returns the full command line of the B<httpd> binary.

=head2 server_config

    $s = $x->server_config;

Returns the full pathname of the server configuration file.
    
=head2 environ

    $hashref = $x->environ;

Returns a reference to the environment used when invoking the server.

=head2 name

    $s = $x->name;

Returns server implementation name (normally C<Apache>).

=head2 version

    $v = $x->version;

Returns server version (as string).

=head2 platform

    $s = $x->platform;

Platform (distribution) on which the binary is compiled.

=head2 architecture

Architecture for which the server is built.
    
=head2 built

    $d = $x->built;

Returns a B<DateTime> object, representing the time when the server
was built.

=head2 loaded_with

APR tools with which the server is loaded.
    
=head2 compiled_with

APR tools with which the server is compiled.
    
=head2 MPM

MPM module loaded in the configuration.

=head2 MPM_threaded

True if the MPM is threaded.

=head2 MPM_forked

True if the MPM is forked.

=head2 defines

    @names = $x->defines;

Returns the list of symbolic names defined during the compilation. The
names are in lexical order.

    @values = $x->defines(@names);

Returns values of the named defines.

=head2 server_root

    $s = $x->server_root;
    
Returns default server root directory. This is equivalent to

    $x->defines('HTTPD_ROOT');

=head2 preloaded

    @ids = $x->preloaded;

Returns the list of the preloaded module identifiers, in lexical order.

    @sources = $x->preloaded(@ids);

Returns the list of module source names for the given source identifiers.
For non-existing identifiers, B<undef> is returned.

=head1 LICENSE

GPLv3+: GNU GPL version 3 or later, see
L<http://gnu.org/licenses/gpl.html>.
    
This  is  free  software:  you  are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.    
    
=head1 AUTHORS

Sergey Poznyakoff <gray@gnu.org>        
    
=cut
    
