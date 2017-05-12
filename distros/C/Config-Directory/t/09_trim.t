#########################

use Test;
BEGIN { plan tests => 21 };
use Config::Directory;

#########################

# Trim and chomp testing

ok(-d "t/t9");

# trim => 0, chomp => 0
my $c = Config::Directory->new("t/t9", { trim => 0, chomp => 0 });
ok(ref $c);
ok(keys %$c == 1);
my $apple = $c->get('APPLE');
my @apple = split /\n/, $apple;
ok($apple[0] =~ m/^\s+/);
ok($apple[0] =~ m/\s+$/);
ok(substr($apple,-1) eq "\n");

# trim => 1, chomp => 1
$c = Config::Directory->new("t/t9", { trim => 1, chomp => 1 });
ok(ref $c);
ok(keys %$c == 1);
$apple = $c->get('APPLE');
@apple = split /\n/, $apple;
ok($apple[0] !~ m/^\s+/);
ok($apple[0] !~ m/\s+$/);
ok(substr($apple,-1) ne "\n");

# trim => 1, chomp => 0
$c = Config::Directory->new("t/t9", { trim => 1, chomp => 0 });
ok(ref $c);
ok(keys %$c == 1);
$apple = $c->get('APPLE');
@apple = split /\n/, $apple;
ok($apple[0] !~ m/^\s+/);
ok($apple[0] !~ m/\s+$/);
ok(substr($apple,-1) eq "\n");

# trim => 0, chomp => 1
$c = Config::Directory->new("t/t9", { trim => 0, chomp => 1 });
ok(ref $c);
ok(keys %$c == 1);
$apple = $c->get('APPLE');
@apple = split /\n/, $apple;
ok($apple[0] =~ m/^\s+/);
ok($apple[0] =~ m/\s+$/);
ok(substr($apple,-1) ne "\n");

