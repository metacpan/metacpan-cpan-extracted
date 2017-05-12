use strict;
use warnings FATAL => 'all';

use Test;
use Apache::TestUtil;
use Apache::TestRequest ();

my @test_strings = qw(hello world);

plan tests => 1 + @test_strings;

my $module = 'TestDebugFilter::bb_dump';
my $socket = Apache::TestRequest::vhost_socket($module);

ok $socket;

for (@test_strings) {
    print $socket "$_\n";
    chomp(my $reply = <$socket> || '');
    ok t_cmp($reply, "HEAP => $_");
}
