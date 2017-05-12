use strict;
use warnings;
use Test::More;
use CSS::LESS::Filter;

{ # simple ruleset replace
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo {' => 'baz: "pass";');
  my $got = $filter->process(<<'LESS');
.foo {
  bar: 'fail';
}
LESS

  my $expected = <<'LESS';
.foo {
  baz: "pass";}
LESS

  is $got => $expected;
}

{ # ruleset callback
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo {' => sub {
    my $inside = shift;
    $inside =~ s/fail/pass/;
    $inside;
  });
  my $got = $filter->process(<<'LESS');
.foo {
  bar: 'fail';
}
LESS

  my $expected = <<'LESS';
.foo {
  bar: 'pass';
}
LESS

  is $got => $expected;
}

done_testing;
