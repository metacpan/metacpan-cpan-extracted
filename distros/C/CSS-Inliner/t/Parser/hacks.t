use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Inliner::Parser');

my $css = <<END;
.foo {
  *color: red;
}
.bar {
  _font-weight: bold;
}
.biz {
  -font-size: 10px;
}
.foo2 {
  w\\idth: 500px;
  width: 130px;
}
END

my $correct = <<END;
.foo {
}
.bar {
}
.biz {
}
.foo2 {
  width: 130px;
}
END

my $simple = CSS::Inliner::Parser->new();

$simple->read({ css => $css });

my $ordered = $simple->write();

ok($correct eq $ordered);
