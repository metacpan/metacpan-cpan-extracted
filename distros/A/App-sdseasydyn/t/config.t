use strict;
use warnings;

use Test2::V0;

use File::Temp qw/tempdir/;
use File::Spec ();

use EasyDNS::DDNS::Config;

my $tdir = tempdir(CLEANUP => 1);
my $cfgd = File::Spec->catdir($tdir, 'sdseasydyn');
mkdir $cfgd or die "mkdir: $!" if !-d $cfgd;

my $cfg = File::Spec->catfile($cfgd, 'config.ini');

_write_file($cfg, <<'INI');
[easydns]
username = cfg_user
token    = cfg_token

[update]
hosts = a.example.com, b.example.com
ip_url = https://example.test/ip
timeout = 20

[state]
path = /tmp/sdseasydyn.last_ip
INI

my %env = (
    EASYDNS_USER      => 'env_user',
    EASYDNS_TOKEN     => 'env_token',
    SDS_EASYDYN_STATE => '/env/state/last_ip',
);

# ENV beats config for creds; secrets returned separately
{
    my $r = EasyDNS::DDNS::Config->load(
        config_path => $cfg,
        env         => \%env,
        cli         => {
            hosts      => [],
            state_path => '',
            ip         => '',
            ip_url     => '',
            timeout    => 0,
        },
    );

    ok($r->{ok}, 'config load ok');
    is($r->{resolved}{username}, 'env_user', 'ENV username wins');
    is($r->{resolved}{token_set}, 1, 'token_set true');
    is($r->{secrets}{token}, 'env_token', 'token returned as secret');
    is($r->{resolved}{ip_url}, 'https://example.test/ip', 'config ip_url');
    is($r->{resolved}{timeout}, 20, 'config timeout');
    is($r->{resolved}{hosts}, [qw/a.example.com b.example.com/], 'hosts from config');
    is($r->{resolved}{state_path}, '/env/state/last_ip', 'ENV state_path wins');
}

done_testing;

sub _write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open($path): $!";
    print {$fh} $content or die "write($path): $!";
    close $fh or die "close($path): $!";
}

