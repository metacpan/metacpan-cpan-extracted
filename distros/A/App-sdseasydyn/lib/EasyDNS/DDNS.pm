package EasyDNS::DDNS;

use strict;
use warnings;

our $VERSION = '0.1.0';

use URI::Escape qw(uri_escape);

use EasyDNS::DDNS::Config ();
use EasyDNS::DDNS::HTTP ();
use EasyDNS::DDNS::State ();
use EasyDNS::DDNS::Util ();

sub new {
    my ($class, %args) = @_;
    return bless {
        verbose => $args{verbose} // 0,
        http    => $args{http},   # optional injection for tests
    }, $class;
}

sub cmd_update {
    my ($self, %args) = @_;

    my $cfg = EasyDNS::DDNS::Config->load(
        config_path => $args{config_path},
        env         => \%ENV,
        cli         => {
            hosts      => $args{hosts},
            state_path => $args{state_path},
            ip         => $args{ip},
            ip_url     => $args{ip_url},
            timeout    => $args{timeout},
        },
    );
    return $cfg if !$cfg->{ok};

    my $r       = $cfg->{resolved};
    my $token   = $cfg->{secrets}{token} // '';
    my $dry_run = $args{dry_run} ? 1 : 0;

    my $hosts = $r->{hosts} || [];
    return _err(2, "No hostnames provided. Use --host or set [update] hosts in config.")
      if !@$hosts;

    if (!$dry_run) {
        return _err(2, "Missing EasyDNS username. Set EASYDNS_USER or [easydns] username.")
          if !$r->{username};
        return _err(2, "Missing EasyDNS token. Set EASYDNS_TOKEN or [easydns] token.")
          if !$token;
    }

    my $http = $self->{http} || EasyDNS::DDNS::HTTP->new(
        timeout => $r->{timeout},
        verbose => $self->{verbose},
    );

    my $state = EasyDNS::DDNS::State->new(
        path    => $r->{state_path},
        verbose => $self->{verbose},
    );

    my $current_ip = $r->{ip};
    if (!$current_ip) {
        $current_ip = _fetch_public_ip($http, $r->{ip_url});
        return _err(4, "Could not determine public IPv4 address") if !$current_ip;
    } else {
        return _err(2, "Invalid IPv4 address supplied via --ip")
          if $current_ip !~ /^(\d{1,3}\.){3}\d{1,3}$/;
    }

    my $last_ip = $state->getLastIp;
    if ($last_ip && $last_ip eq $current_ip) {
        return {
            ok         => 1,
            exit_code  => 0,
            message    => "No change (IP unchanged)",
            current_ip => $current_ip,
            resolved   => $r,
        };
    }

    if ($dry_run) {
        return {
            ok         => 1,
            exit_code  => 0,
            message    => "Dry-run: would update",
            current_ip => $current_ip,
            resolved   => $r,
        };
    }

    for my $host (@$hosts) {
        my $u = _easydns_update_url($host, $current_ip);

        my $auth = $http->basicAuthHeader($r->{username}, $token);

        my $resp = $http->get($u, headers => { Authorization => $auth }, desc => "EasyDNS update $host");
        my $body = EasyDNS::DDNS::Util::trim($resp->{content} // '');

        my $parsed = _parse_easydns_response($body);
        if (!$parsed->{ok}) {
            return _err($parsed->{exit_code}, "EasyDNS update failed for $host: $parsed->{code}");
        }
    }

    $state->setLastIp($current_ip);

    return {
        ok         => 1,
        exit_code  => 0,
        message    => "Updated",
        current_ip => $current_ip,
        resolved   => $r,
    };
}

sub _fetch_public_ip {
    my ($http, $url) = @_;
    my $resp = $http->get($url, desc => "IP discovery");
    my $body = EasyDNS::DDNS::Util::trim($resp->{content} // '');
    return '' if $body !~ /^(\d{1,3}\.){3}\d{1,3}$/;
    return $body;
}

sub _easydns_update_url {
    my ($host, $ip) = @_;
    my $h = uri_escape($host);
    my $i = uri_escape($ip);
    return "https://api.cp.easydns.com/dyn/generic.php?hostname=$h&myip=$i";
}

sub _parse_easydns_response {
    my ($body) = @_;
    $body = EasyDNS::DDNS::Util::trim($body);
    my $u = uc $body;

    return { ok => 1, code => 'OK', exit_code => 0 } if $u =~ /\bOK\b/;
    return { ok => 1, code => 'NOERROR', exit_code => 0 } if $u =~ /\bNOERROR\b/;

    return { ok => 0, code => 'NOACCESS',  exit_code => 3 } if $u =~ /\bNOACCESS\b/;
    return { ok => 0, code => 'NO_AUTH',   exit_code => 3 } if $u =~ /\bNO_AUTH\b/ || $u =~ /\bNOAUTH\b/;

    return { ok => 0, code => 'TOOSOON',   exit_code => 5 } if $u =~ /\bTOOSOON\b/;
    return { ok => 0, code => 'NOSERVICE', exit_code => 5 } if $u =~ /\bNOSERVICE\b/;
    return { ok => 0, code => 'ILLEGAL',   exit_code => 5 } if $u =~ /\bILLEGAL\b/;

    return { ok => 0, code => 'UNKNOWN',   exit_code => 5 };
}

sub _err {
    my ($exit_code, $msg) = @_;
    return { ok => 0, exit_code => $exit_code, error => $msg };
}

1;

