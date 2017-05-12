
use lib qw(t/lib);
use IO::Capture qw(open_s close_s);

use Test::More tests => 8;

BEGIN { use_ok('Business::BR::Ids::Common', '_dot') };

my @a = (1,1,1,1);
my @b = (1,1,1,1);

is(_dot(\@a, \@b), 4, "_dot works");

my @c = (1,undef,1,1);
is(_dot(\@a, \@c), 3, "untrue's are discarded");

# the following tests are expected to emit warnings.
# To test this, the STDERR is captured and checked to be non-empty

my @d = (1,1,1,1,1);
{
  local *STDERR;
  open_s *STDERR;

  is(_dot(\@a, \@d), 4, "_dot works for \@a < \@b");

  my $stderr = close_s *STDERR;
  ok($stderr, "but it does complain");
}


my @e = (1,1,1);
{ 
  local *STDERR; 
  open_s(*STDERR);

  is(_dot(\@a, \@e), 3, "_dot works for \@a > \@b");

  my $stderr = close_s *STDERR;
  ok($stderr, "but it does complain");
}

{
  my @a = (1,2,3,3);
  my @b = (2,5,2,6);

  is( _dot( \@a, \@b ), 36, "the synopsis example works");
}
