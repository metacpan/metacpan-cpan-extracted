use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Inliner::Parser');

my $css = <<END;
.foo {
  color: red;
}
.bar {
  color: blue;
  font-weight: bold;
}
.biz {
  color: green;
  font-size: 10px;
}
.foo {
  color: red;
}
.bar {
  color: blue;
  font-weight: bold;
}
END

my $simple = CSS::Inliner::Parser->new();

$simple->read({ css => $css });

my $ordered = $simple->write();

# check to make sure that our shuffled hashes matched up...
ok($css eq $ordered);
