use strict;
use warnings;
use Test::More;

use Test::TCP qw/empty_port wait_port/;
use Test::Skip::UnlessExistsExecutable;
use File::Which qw(which);
use Proc::Guard;
use Cache::Memcached::Fast::Safe;
use POSIX qw//;
#use Log::Minimal;
#$Log::Minimal::AUTODUMP =1;

skip_all_unless_exists 'memcached';

my @memcached;
my @user = ();
if ( $> == 0 ) {
    @user = ('-u','nobody');
}

for ( 1..5 ) {
    my $port = empty_port();
    my $proc = proc_guard( scalar which('memcached'), '-p', $port, '-U', 0, '-l', '127.0.0.1', @user );
    wait_port($port);
    push @memcached, { proc => $proc, port => $port };
}

my $cache = Cache::Memcached::Fast::Safe->new({
    servers => [map { "localhost:" . $_->{port} } @memcached],
});
my $version = $cache->server_versions;

my $pid = fork;
if ( $pid == 0 ) {
    my $after_fork = $cache->server_versions; 
    is_deeply($after_fork, $version);
    POSIX::_exit(0);
}

waitpid($pid,0);
is_deeply($cache->server_versions, $version);

done_testing();


