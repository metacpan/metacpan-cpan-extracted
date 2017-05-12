#########################

use Test;
BEGIN { plan tests => 3 };
use Config::Directory;

#########################

# Null directory testing

ok(-d "t/t1");
my $c = Config::Directory->new("t/t1");
ok(ref $c);
ok(! keys %$c);
