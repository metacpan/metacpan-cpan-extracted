# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 8;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);

#diag(q[Expect ClearPress::driver / SQLite warnings about failure to create tables]);

trap {
  my $util1 = t::util->new();
  my $util2 = t::util->new();
  is($util1, $util2, 'same singleton util instance');

  is($util1->dbh(), $util2->dbh(), 'same dbh from different utils');
};

trap {
  my $util1 = t::util::test1->new();
  my $util2 = t::util::test2->new();
  isnt($util1, $util2, 'different singleton util subclass instance');

  isnt($util1->dbh(), $util2->dbh(), 'different dbh from different utils');
};

trap {
  my $util1 = t::util::test1->new();
  my $util2 = t::util::test1->new();
  is($util1, $util2, 'same singleton util subclass instance');

  is($util1->dbh(), $util2->dbh(), 'same dbh from different util subclass instances');
};

trap {
  my $util1 = ClearPress::util->new({
				     cgi => {},
				    });
  my $cgi1 = $util1->cgi();

  my $util2 = ClearPress::util->new({
				     cgi => {},
				    });
  my $cgi2 = $util2->cgi();

  isnt($cgi1, $cgi2, 'CGI values differ');
};

trap {
  my $util1 = ClearPress::util->new();
  $util1->cleanup();
  my $util2 = ClearPress::util->new();
  isnt($util1, $util2, 'utils differ after cleanup');
};

package t::util::test1;
use base qw(t::util);

1;

package t::util::test2;
use base qw(t::util);

1;
