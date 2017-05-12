use Test::More;
use Test::Deep;

plan skip_all => "Optional modules (MIME::Base64) not installed"
  unless eval {
               require MIME::Base64;
              };

plan tests => 3;

my $package = 'Apache::Session::Serialize::Base64';
use_ok $package;
can_ok $package, qw[serialize unserialize];

my $serialize   = \&{"$package\::serialize"};
my $unserialize = \&{"$package\::unserialize"};

my $session = {
               serialized => undef,
               data       => undef,
              };
my $simple  = {
               foo  => 1,
               bar  => 2,
               baz  => 'quux',
               quux => ['foo', 'bar'],
              };

$session->{data} = $simple;

$serialize->($session);

$session->{data} = undef;

$unserialize->($session);

cmp_deeply $session->{data}, $simple, "Session was deserialized correctly";
