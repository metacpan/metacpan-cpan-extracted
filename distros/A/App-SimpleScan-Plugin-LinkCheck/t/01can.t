use Test::More tests=>2;

BEGIN {
  use_ok(qw(App::SimpleScan::Plugin::LinkCheck));
}

can_ok('App::SimpleScan::Plugin::LinkCheck', qw(pragmas _do_has_link _do_no_link));
