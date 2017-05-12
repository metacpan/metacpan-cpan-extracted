# -*- Mode: Perl; -*-

=head1 NAME

6_die_00_base.t - Very basic testing of the Die module.

=cut

use Test::More tests => 2;

use_ok('CGI::Ex::Die');

ok(eval {
  import CGI::Ex::Die register => 1;
  $SIG{__DIE__} eq \&CGI::Ex::Die::die_handler;
});
