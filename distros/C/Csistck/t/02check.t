use Test::More;
use Test::Exception;
use Csistck;

plan tests => 5;

$Csistck::Oper::Options->{repair} = 1;

my $tc;

# I'll assume this hostname cannot be set on *NIX
dies_ok(sub { check('#UNDEF#.example.com'); }, "Expect fail on missing hostname");

# Passing various objects
$tc = noop(0);
lives_ok(sub { check($tc); }, "Pass on failing test");
$tc = noop(1);
lives_ok(sub { check($tc); }, "Pass on passing test");

my @tcs;
push(@tcs, [noop(1), noop(1)]);
lives_ok(sub { check(@tcs); }, "Passing array");

# Finally, test hostnames again
host '#UNDEF#.example.com' => noop(1);
lives_ok(sub { check('#UNDEF#.example.com'); }, "Pass on hostname");

1;
