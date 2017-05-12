#########################

use Test;
BEGIN { plan tests => 7 };
use Config::Directory;

#########################

# 'Set' testing

# ok(-d "t/t8" && ! -w "t/t8");
ok(-d "t/t10" && -w "t/t10");

# Empty t/t10
opendir DIR, "t/t10" or die "opening t/t10 failed: $!";
while (my $f = readdir(DIR)) {
  next if -d "t/t10/$f";
  unlink "t/t10/$f" or die "unlink of t/t10/$f failed: $!";
}

# Non-writable directory
# my $c = Config::Directory->new([ "t/t10", "t/t8" ]);
# ok(ref $c);
# ok(keys %$c == 7);
# ok(! defined eval { $c->set('APPLE','appular') });

# Normal
$c = Config::Directory->new([ "t/t8", "t/t10" ]);
ok(ref $c);
ok(keys %$c == 7);
ok($c->get('GRAPE') eq 'grape');
ok(! exists $c->{STRAWBERRY});
$c->set('GRAPE','grapple');
$c->set('STRAWBERRY','straggle');

# Check
my $c2 = Config::Directory->new([ "t/t10" ]);
ok($c->{GRAPE} eq 'grapple');
ok($c->get('STRAWBERRY') eq 'straggle');

