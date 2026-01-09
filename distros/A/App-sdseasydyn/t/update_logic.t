use strict;
use warnings;

use Test2::V0;

use File::Temp qw/tempdir/;
use File::Spec ();

use EasyDNS::DDNS;

{
    package Local::HTTPMock;
    use strict;
    use warnings;

    sub new {
        my ($class, %args) = @_;
        return bless { calls => 0, seq => $args{seq} || [] }, $class;
    }

    sub calls { $_[0]{calls} }

    sub basicAuthHeader { return 'Basic xxx' }

    sub get {
        my ($self, $url, %opt) = @_;
        $self->{calls}++;
        my $i = $self->{calls} - 1;
        return $self->{seq}[$i] if defined $self->{seq}[$i];
        return { success => 1, status => 200, content => "OK\n" };
    }
}

my $tdir = tempdir(CLEANUP => 1);
my $state_path = File::Spec->catfile($tdir, 'last_ip');
my $cfg = File::Spec->catfile($tdir, 'config.ini');

_write_file($cfg, <<"INI");
[easydns]
username = u
token = t

[update]
hosts = h.example.com
ip_url = https://ip.test/
timeout = 5

[state]
path = $state_path
INI

# 1) First run: last_ip missing, ip provided, should call update once and store
{
    my $http = Local::HTTPMock->new(seq => [
        { success => 1, status => 200, content => "OK\n" }, # update
    ]);

    my $ddns = EasyDNS::DDNS->new(http => $http);

    my $res = $ddns->cmd_update(
        config_path => $cfg,
        hosts       => [],
        ip          => '203.0.113.10',
        dry_run     => 0,
    );

    ok($res->{ok}, 'first run ok');
    is($res->{exit_code}, 0, 'exit 0');
    is($http->calls, 1, 'did update');
    ok(-f $state_path, 'state file written');
}

# 2) Second run: same ip, should do zero updates
{
    my $http = Local::HTTPMock->new();

    my $ddns = EasyDNS::DDNS->new(http => $http);

    my $res = $ddns->cmd_update(
        config_path => $cfg,
        hosts       => [],
        ip          => '203.0.113.10',
        dry_run     => 0,
    );

    ok($res->{ok}, 'second run ok');
    is($res->{exit_code}, 0, 'exit 0');
    is($http->calls, 0, 'no update call when unchanged');
    like($res->{message}, qr/unchanged/i, 'message indicates no change');
}

done_testing;

sub _write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open($path): $!";
    print {$fh} $content or die "write($path): $!";
    close $fh or die "close($path): $!";
}

