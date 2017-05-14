use strict;
use warnings;
use File::Slurp;
use File::Temp qw(tempfile);
use Test::More 0.88;

use App::GSD;

my ($hosts_fh, $hosts_file) = tempfile();
my $hosts = q(
    # /etc/hosts: static lookup table for host names

    #<ip-address>    <hostname.domain.org>   <hostname>
    #127.0.0.1       localhost.localdomain   localhost mypcname
    #::1             localhost.localdomain   localhost

    # End of file
);
print {$hosts_fh} $hosts;
close $hosts_fh;

my @hosts = qw(reddit.com facebook.com);

# Use a fake hosts file and a dummy DNS flush method
my $config = {
    hosts_file => $hosts_file,
    block => \@hosts,
    network_command => [],
};

my $app = App::GSD->new($config);
isa_ok( $app, 'App::GSD', 'ctor ok' );
is( $app->hosts_file, $hosts_file, 'hosts_file accessor' );

$app->work;

my $new_hosts = read_file($hosts_file);
for my $host (@hosts, map {"www.$_" } @hosts) {
    like($new_hosts, qr/^127\.0\.0\.1\s+\Q$host\E\s*$/m, "$host blocked");
}

$app->play;

is( read_file($hosts_file), $hosts, 'host file matches original' );

done_testing;
