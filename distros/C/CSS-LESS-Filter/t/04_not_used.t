use strict;
use warnings;
use Test::More;
use CSS::LESS::Filter;

{ # property
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo { bar:', 'baz');
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $filter->process('');
  ok @warnings, "received warnings";
}

{ # ruleset
  my $filter = CSS::LESS::Filter->new;
  $filter->add('.foo {', 'bar: @baz;');
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $filter->process('');
  ok @warnings, "received warnings";
}

{ # at rule
  my $filter = CSS::LESS::Filter->new;
  $filter->add('@import', '"foo"');
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $filter->process('');
  ok @warnings, "received warnings";
}

done_testing;
