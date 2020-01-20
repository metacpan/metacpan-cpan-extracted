package Apache::Config::Preproc::ifmodule;
use parent 'Apache::Config::Preproc::Expand';
use strict;
use warnings;
use Carp;
use IPC::Open3;

our $VERSION = '1.03';

sub new {
    my $class = shift;
    my $conf = shift;
    my $self = bless $class->SUPER::new($conf), $class;
    local %_ = @_;
    my $v;
    if ($v = delete $_{preloaded}) {
	croak "preloaded must be an arrayref" unless ref($v) eq 'ARRAY';
	@{$self->{preloaded}}{@$v} = @$v;
    }
    if ($v = delete $_{probe}) {
	if (ref($v) eq 'ARRAY') {
	    $self->probe(@$v);
	} else {
	    $self->probe;
	}
    }
    return $self;
}

sub preloaded {
    my $self = shift;
    my $id = shift;
    if (my $v = shift) {
	$self->{preloaded}{$id} = $v;
    }
    return $self->{preloaded}{$id};
}

sub expand {
    my ($self, $d, $repl) = @_;
    if ($d->type eq 'section' && lc($d->name) eq 'ifmodule') {
	my $id = $d->value;
	my $negate = $id =~ s/^!//;
	my $res = $self->module_loaded($id);
	if ($negate) {
	    $res = !$res;
	}
	if ($res) {
	    push @$repl, $d->select;
	}
	return 1;
    }
    return 0;
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

sub module_loaded {
    my ($self, $id) = @_;
    if (exists($modlist{$id})) {
	$id = $modlist{$id};
    }
    return 1 if $self->preloaded($id);
    return grep {
	(split /\s+/, $_->value)[0] eq $id
    } $self->conf->directive('loadmodule');
}

sub probe {
    my ($self, @servlist) = @_;
    unless (@servlist) {
	@servlist = qw(/usr/sbin/httpd /usr/sbin/apache2);
    }

    open(my $nullout, '>', File::Spec->devnull);
    open(my $nullin, '<', File::Spec->devnull);
    foreach my $serv (@servlist) {
        use Symbol 'gensym';
        my $fd = gensym;
        eval {
        	if (my $pid = open3($nullin, $fd, $nullout, $serv, '-l')) {
			while (<$fd>) {
			    chomp;
			    if (/^\s*(\S+\.c)$/ && exists($modlist{$1})) {
				$self->preloaded($modlist{$1}, $1);
			    }
			}
		}
	};
	close $fd;
	last unless ($@)
    }
    close $nullin;
    close $nullout;
}

1;
__END__

=head1 NAME    

Apache::Config::Preproc::ifmodule - expand IfModule statements

=head1 SYNOPSIS

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
               -expand => [ qw(ifmodule) ];

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
               -expand => [
                   { ifmodule => { probe => [ '/usr/sbin/httpd' ] } }
               ]; 

=head1 DESCRIPTION

Expands the B<E<lt>IfModuleE<gt>> statements in the Apache configuration parse
tree. If the statement's argument evaluates to true, it is replaced by the
statements inside it. Otherwise, it is removed. Nested statements are allowed.
The B<LoadModule> statements are examined in order to evaluate the argument.   

The following constructor arguments are understood:

=over 4

=item B<preloaded =E<gt>> I<LISTREF>

Supplies a list of preloaded module names. You can use this argument to
pass a list of modules linked statically in your version of B<httpd>.

=item B<probe =E<gt>> I<LISTREF> | B<1>

Provides an alternative way of handling statically linked Apache modules.
If I<LISTREF> is given, each its element is treated as the pathname of
the Apache B<httpd> binary. The first of them that is found is run with
the B<-l> option to list the statically linked modules, and its output
is parsed.

The argument

    probe => 1

is a shorthand for

    probe => [qw(/usr/sbin/httpd /usr/sbin/apache2)]
        
=back

=head1 SEE ALSO

L<Apache::Config::Preproc>

=cut

