use strict;
use warnings;
use Test::More;
use CSS::LESS::Filter;

{ # simple property value
  my $filter = CSS::LESS::Filter->new;
  $filter->add('@import' => '"baz.less"');
  my $got = $filter->process(<<'LESS');
@import "foo.less";
LESS

  my $expected = <<'LESS';
@import "baz.less";
LESS

  is $got => $expected;
}

{ # property value callback
  my $filter = CSS::LESS::Filter->new;
  $filter->add('@import' => sub {
    my $value = shift;
    $value =~ s/foo/bar/;
    $value;
  });
  my $got = $filter->process(<<'LESS');
@import "foo.less";
LESS

  my $expected = <<'LESS';
@import "bar.less";
LESS

  is $got => $expected;
}

{ # remove at_rule
  my $filter = CSS::LESS::Filter->new;
  $filter->add('@import' => undef);
  my $got = $filter->process(<<'LESS');
@import "foo.less";
@import "bar.less";
LESS

  my $expected = <<'LESS';
LESS

  is $got => $expected;
}

done_testing;
