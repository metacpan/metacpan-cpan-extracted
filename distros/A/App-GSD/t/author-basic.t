
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;
use English qw($EUID);
use File::Slurp qw(read_file write_file);
use Socket qw(inet_ntoa);
use Test::More 0.88;

use App::GSD;

if (not $ENV{'TEST_AUTHOR'}) {
    plan skip_all => 'This test modifies live network configuration. Set $ENV{TEST_AUTHOR}=1 and run as root.';
}

if ($EUID != 0) {
    plan skip_all => 'This test must be run as root.';
}

my @hosts = qw(reddit.com facebook.com);
my $app = App::GSD->new({ block => \@hosts });
isa_ok( $app, 'App::GSD', 'ctor ok' );

my $hosts_file = $app->hosts_file;
my $previous_hosts = read_file($hosts_file);

$app->work;

for my $host (@hosts, map { "www.$_" } @hosts) {
    is( resolve($host), '127.0.0.1', "$host blocked" );
}

$app->play;
sleep 20;  # Give network time to restart

for my $host (@hosts, map { "www.$_" } @hosts) {
    isnt( resolve($host), '127.0.0.1', "$host no longer blocked" );
}

is( scalar read_file($hosts_file), $previous_hosts, 'host file matches original' ) or do {
    diag("Restoring old hostfile...");
    write_file($hosts_file, $previous_hosts);
};

done_testing;

# Resolve a hostname to an IP address
sub resolve {
    my $hostname = shift;
    my $ip = gethostbyname($hostname);
    return defined $ip ? inet_ntoa($ip) : undef;
}
