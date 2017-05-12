# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;

eval {
  require DBD::SQLite;
  plan tests => 2;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);
use t::model::derived;
use t::util;
use Test::Trap;

my $util = t::util->new();

{
  my $der = t::model::derived->new({util=>$util});
  trap {
    $der->hasa('derived_child');
  };
  like($trap->stderr(), qr/deprecated/mix);
}

{
  my $der = t::model::derived->new({util=>$util});
  trap {
    $der->hasmany('derived_child');
  };
  like($trap->stderr(), qr/deprecated/mix);
}
