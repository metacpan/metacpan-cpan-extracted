use strict;
use warnings;
use Test::More;
use CSS::LESS::Filter;

{
  # property
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo { .bar { baz:' => '#color');
  my $got = $filter->process('', {mode => 'append'});
  my $expected = <<'LESS';
.foo { .bar { baz: #color; }}
LESS

  is $got => $expected;
}

{
  # ruleset
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo {' => sub {
    my $value = shift;
    return "// Added by CSS::LESS::Filter\n$value";
  });
  my $got = $filter->process(<<'LESS', {mode => 'append'});
.bar {
  baz: 'test';
}
LESS

  my $expected = <<'LESS';
.bar {
  baz: 'test';
}
.foo {
// Added by CSS::LESS::Filter
}
LESS

  is $got => $expected;
}

{
  # at rule
  my $filter = CSS::LESS::Filter->new;
  $filter->add('@import' => '"foo.less"');
  my $got = $filter->process('', {mode => 'append'});
  my $expected = <<'LESS';
@import "foo.less";
LESS

  is $got => $expected;
}

{
  # special case
  my $filter = CSS::LESS::Filter->new;
  $filter->add('' => '@import "foo.less";');
  my $got = $filter->process(<<'LESS', {mode => 'append'});
@import "bar.less";
LESS
  my $expected = <<'LESS';
@import "bar.less";
@import "foo.less";
LESS

  is $got => $expected;
}

done_testing;
