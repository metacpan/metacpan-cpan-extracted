use strict;
use warnings;
use Test::More;
use CSS::LESS::Filter;

{ # simple property value
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo { bar:' => '@ok');
  my $got = $filter->process(<<'LESS');
.foo {
  bar: 'fail';
}
LESS

  my $expected = <<'LESS';
.foo {
  bar: @ok;
}
LESS

  is $got => $expected;
}

{ # property value callback
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo { bar:' => sub {
    my $value = shift;
    $value =~ s/fail/pass/;
    $value;
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

{ # remove property
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo { bar:' => undef);
  my $got = $filter->process(<<'LESS');
.foo {
  bar: 'fail';
}
LESS

  my $expected = <<'LESS';
.foo {
  }
LESS

  is $got => $expected;
}

{ # root variable
  my $filter = CSS::LESS::Filter->new;
  $filter->add('@a:' => '"pass"');
  my $got = $filter->process(<<'LESS');
@a: 'fail';
LESS

  my $expected = <<'LESS';
@a: "pass";
LESS

  is $got => $expected;
}

done_testing;
