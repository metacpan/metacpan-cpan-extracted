use common::sense;
use Test::More;
use AnyEvent::MCP::Workdirs ();
use AnyEvent::MCP::File ();
use File::Temp ();
use JSON::XS ();
use POSIX ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
my $file = "$dir/config/fs-workdir-ids.json";
my $json = JSON::XS->new->utf8;
my $start = time;

sub entries {
   open my $fh, "<", $file or die $!;
   local $/;
   $json->decode (<$fh>)
}

sub save_entries {
   my ($entries) = @_;

   my $lock = AnyEvent::MCP::File::lock $file;
   AnyEvent::MCP::File::replace $file, $json->encode ($entries);
}

my $a = AnyEvent::MCP::Workdirs->new (file => $file, paths => ["/one", "/two"]);
is_deeply $a->{ids}, [1, 2], "allocate small positive IDs";
my $entries = entries;
is $entries->{1}[0], "/one", "registry records path";
ok $entries->{1}[1] >= $start, "registry records last refresh";
is ((stat $file)[2] & 0777, 0600, "registry is private");

open my $fh, "<", $file or die $!;
my $text = do { local $/; <$fh> };
close $fh;
like $text, qr/\n   "1" : \[\n      "\/one"/, "pretty JSON with indentation enabled";

chmod 0644, $file or die $!;
save_entries $entries;
is ((stat $file)[2] & 0777, 0644, "atomic replacement preserves user-selected mode");

my $b = AnyEvent::MCP::Workdirs->new (file => $file, paths => ["/two", "/one", "/three"]);
is_deeply $b->{ids}, [2, 1, 3], "reordering and adding paths retain existing IDs";
$a->refresh;
is entries->{3}[0], "/three", "refresh merges another server's entries";

$entries = entries;
$entries->{1}[0] = "/replacement";
delete $entries->{2};
save_entries $entries;
$a->refresh;
$entries = entries;
is $entries->{1}[0], "/one", "refresh overwrites a reassigned ID with our fixed assignment";
is $entries->{2}[0], "/two", "refresh restores a removed assignment";
is_deeply $a->{ids}, [1, 2], "refresh never reallocates in-memory IDs";

$entries->{2}[1] = time - 8 * 86400;
$entries->{3}[1] = time - 8 * 86400;
save_entries $entries;
$a->refresh;
$entries = entries;
is $entries->{2}[0], "/two", "configured path retains expired ID";
ok $entries->{2}[1] >= $start, "refresh renews configured path";
ok !exists $entries->{3}, "unused expired entry is removed";

my $c = AnyEvent::MCP::Workdirs->new (file => $file, paths => ["/four"]);
is_deeply $c->{ids}, [3], "reuse smallest expired ID";
my $d = AnyEvent::MCP::Workdirs->new (file => $file, paths => ["/one", "/one"]);
is_deeply $d->{ids}, [1, 1], "duplicate resolved paths share an ID";

my @children;
for my $i (1 .. 6) {
   my $pid = fork;
   defined $pid or die "fork: $!";

   unless ($pid) {
      my $ok = eval {
         AnyEvent::MCP::Workdirs->new (file => $file, paths => ["/concurrent/$i"]);
         1
      };
      warn $@ unless $ok;
      POSIX::_exit ($ok ? 0 : 1);
   }

   push @children, $pid;
}

my $failed;
for my $pid (@children) {
   waitpid $pid, 0;
   $failed ||= $?;
}

ok !$failed, "concurrent registry writers succeed";
$entries = entries;
is_deeply [sort map $_->[0], values %$entries],
   [sort "/one", "/two", "/four", map "/concurrent/$_", 1 .. 6],
   "concurrent allocations preserve every path with a separate ID";

my $odd = "/unicode/\x{e4}\n[workdir]=value";
my $unicode = AnyEvent::MCP::Workdirs->new (file => $file, paths => [$odd]);
is entries->{$unicode->{ids}[0]}[0], $odd, "JSON preserves Unicode and multiline paths";
my $again = AnyEvent::MCP::Workdirs->new (file => $file, paths => [$odd]);
is_deeply $again->{ids}, $unicode->{ids}, "unusual path retains its ID on reread";

$entries = entries;
my $valid = $json->encode ($entries);
for my $bad ('[]', '{"0":["/bad",1]}', '{"1":["/bad","invalid"]}', '{"1":["/bad"]}') {
   my $lock = AnyEvent::MCP::File::lock $file;
   AnyEvent::MCP::File::replace $file, $bad;
   undef $lock;
   eval { $a->refresh };
   ok $@, "reject malformed registry without replacing it";
}

{
   my $lock = AnyEvent::MCP::File::lock $file;
   AnyEvent::MCP::File::replace $file, $valid;
}

done_testing;
