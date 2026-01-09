package EasyDNS::DDNS::Config;

use strict;
use warnings;

use Config::Tiny;
use File::Spec ();
use Cwd ();

use EasyDNS::DDNS::Util ();

sub load {
    my ($class, %args) = @_;

    my $env = $args{env} || {};
    my $cli = $args{cli} || {};

    my $default_cfg_path = _default_config_path();
    my $cfg_path = $args{config_path};
    $cfg_path = $default_cfg_path if !defined($cfg_path) || $cfg_path eq '';
    $cfg_path = _expand_tilde($cfg_path);

    my $ini = {};
    if (-f $cfg_path) {
        my $ct = Config::Tiny->read($cfg_path);
        if (!$ct) {
            return {
                ok        => 0,
                exit_code => 2,
                error     => "Failed to read config '$cfg_path': " . Config::Tiny->errstr,
            };
        }
        $ini = $ct;
    }

    # --- Config values ---
    my $cfg_user   = EasyDNS::DDNS::Util::trim($ini->{easydns}{username} // '');
    my $cfg_token  = EasyDNS::DDNS::Util::trim($ini->{easydns}{token}    // '');

    my $cfg_hosts  = EasyDNS::DDNS::Util::trim($ini->{update}{hosts}     // '');
    my $cfg_ip_url = EasyDNS::DDNS::Util::trim($ini->{update}{ip_url}    // '');
    my $cfg_timeout= EasyDNS::DDNS::Util::trim($ini->{update}{timeout}   // '');

    my $cfg_state_path = EasyDNS::DDNS::Util::trim($ini->{state}{path}   // '');

    # Allow ${ENVVAR} expansion in config values
    $cfg_user       = _expand_env($cfg_user, $env);
    $cfg_token      = _expand_env($cfg_token, $env);
    $cfg_ip_url     = _expand_env($cfg_ip_url, $env);
    $cfg_state_path = _expand_env($cfg_state_path, $env);

    my @hosts_from_cfg = _split_hosts($cfg_hosts);

    # --- ENV values ---
    my $env_user   = EasyDNS::DDNS::Util::trim($env->{EASYDNS_USER}  // '');
    my $env_token  = EasyDNS::DDNS::Util::trim($env->{EASYDNS_TOKEN} // '');
    my $env_state  = EasyDNS::DDNS::Util::trim($env->{SDS_EASYDYN_STATE} // '');

    # --- CLI values ---
    my @hosts_from_cli = ();
    if ($cli->{hosts} && ref($cli->{hosts}) eq 'ARRAY') {
        for my $h (@{ $cli->{hosts} }) {
            if (ref $h eq 'ARRAY') {
                push @hosts_from_cli, @$h;
            } else {
                push @hosts_from_cli, $h;
            }
        }
        @hosts_from_cli = grep { defined($_) && $_ ne '' } @hosts_from_cli;
    }

    my $cli_ip      = EasyDNS::DDNS::Util::trim($cli->{ip}      // '');
    my $cli_ip_url  = EasyDNS::DDNS::Util::trim($cli->{ip_url}  // '');
    my $cli_timeout = $cli->{timeout};
    my $cli_state   = EasyDNS::DDNS::Util::trim($cli->{state_path} // '');

    # --- Defaults ---
    my $def_ip_url     = 'https://api.ipify.org';
    my $def_timeout    = 10;
    my $def_state_path = _default_state_path();

    # Precedence: CLI > ENV > config > defaults
    my $username = $env_user || $cfg_user;

    my @hosts = @hosts_from_cli ? @hosts_from_cli : @hosts_from_cfg;

    my $ip_url  = $cli_ip_url || $cfg_ip_url || $def_ip_url;

    my $timeout = $def_timeout;
    if (defined $cfg_timeout && $cfg_timeout ne '' && $cfg_timeout =~ /^\d+$/) {
        $timeout = int($cfg_timeout);
    }
    if (defined $cli_timeout && $cli_timeout =~ /^\d+$/ && $cli_timeout > 0) {
        $timeout = int($cli_timeout);
    }

    my $state_path = $cli_state || $env_state || $cfg_state_path || $def_state_path;
    $state_path = _expand_tilde($state_path);

    # Secret token (do not expose in resolved)
    my $token = $env_token || $cfg_token;

    my $resolved = {
        config_path => $cfg_path,
        username    => $username,
        token_set   => ($token ? 1 : 0),
        hosts       => \@hosts,
        ip          => $cli_ip,
        ip_url      => $ip_url,
        timeout     => $timeout,
        state_path  => $state_path,
    };

    return {
        ok      => 1,
        resolved => $resolved,
        secrets  => { token => $token },
    };
}

sub _default_config_path {
    my $home = $ENV{HOME} || Cwd::getcwd();
    return File::Spec->catfile($home, '.config', 'sdseasydyn', 'config.ini');
}

sub _default_state_path {
    my $home = $ENV{HOME} || Cwd::getcwd();
    return File::Spec->catfile($home, '.local', 'state', 'sdseasydyn', 'last_ip');
}

sub _expand_tilde {
    my ($path) = @_;
    return $path if !defined $path || $path eq '';
    return $path if $path !~ m{^~(/|$)};
    my $home = $ENV{HOME} || '';
    $path =~ s{^~}{$home};
    return $path;
}

sub _expand_env {
    my ($s, $env) = @_;
    return $s if !defined $s;
    $s =~ s/\$\{([A-Z0-9_]+)\}/exists $env->{$1} ? $env->{$1} : ''/ge;
    return $s;
}

sub _split_hosts {
    my ($s) = @_;
    return () if !defined($s) || $s eq '';
    my @h = split /\s*,\s*/, $s;
    @h = map { EasyDNS::DDNS::Util::trim($_) } @h;
    @h = grep { $_ ne '' } @h;
    return @h;
}

1;

__END__

=pod

=head1 NAME

EasyDNS::DDNS::Config - Configuration handling for sdseasydyn

=head1 DESCRIPTION

Loads configuration from (in precedence order):

  CLI > ENV > config file > defaults

Secrets (token) are returned separately under C<secrets> and are never included
in the resolved hash for logging safety.

=cut

