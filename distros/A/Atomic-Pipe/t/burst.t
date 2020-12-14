use Test2::V0;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

my ($rh, $wh);
pipe($rh, $wh);

my $old = select($wh);
$| = 1;
select $old;

my $w = Atomic::Pipe->from_fh('>&=', $wh);

ok($w->write_burst("aaa\n"), "write_burst returned true");

chomp(my $data = <$rh>);
is($data, 'aaa', "Got the short message");

ok(!$w->write_burst(("a" x PIPE_BUF) . 'x'), "Message is too long, not written");
print $wh "\n";
chomp($data = <$rh>);
ok(!$data, "No message received");

ok($w->write_burst(("a" x (PIPE_BUF - 1)) . "\n"), "write_burst max-length returned true");
close($wh);
chomp($data = <$rh>);
is($data, ('a' x (PIPE_BUF - 1)), "Got the short burst");

done_testing;
