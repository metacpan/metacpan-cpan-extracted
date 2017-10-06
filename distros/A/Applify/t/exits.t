use warnings;
use strict;
use Test::More;

my $code = <<"HERE";
package main;
use Applify;
documentation '$0';
version '1';
app { 0 };
HERE

{
  my $exited = 0;
  local *CORE::GLOBAL::exit = sub (;$) { $exited = 1; };
  ## eval bakes in exit as overridden above
  my $app = eval "$code" or die $@;
  is $exited, 0, 'no exit yet';
  local @ARGV = ('-help');
  my $return = $app->_script->app->run;
  is $return, 0, 'returned zero';
  is $exited, 1, 'print_help';

  *CORE::GLOBAL::exit = *CORE::exit;
}

{
  my $exited = 0;
  local *CORE::GLOBAL::exit = sub (;$) { $exited = 1; };
  my $app = eval "$code" or die $@;
  is $exited, 0, 'no exit yet';
  local @ARGV = ('-man');
  my $return = $app->_script->app->run;
  is $return, 0, 'returned zero';
  is $exited, 1, 'man';

  *CORE::GLOBAL::exit = *CORE::exit;
}

{
  my $exited = 0;
  local *CORE::GLOBAL::exit = sub (;$) { $exited = 1; };
  my $app = eval "$code" or die $@;
  is $exited, 0, 'no exit yet';
  local @ARGV = ('-version');
  my $return = $app->_script->app->run;
  is $return, 0, 'returned zero';
  is $exited, 1, 'version';

  *CORE::GLOBAL::exit = *CORE::exit;
}

{
  my $exited = 0;
  local *CORE::GLOBAL::exit = sub (;$) { $exited = 5 * shift; };
  my $app = eval <<'HERE' or die $@;
package main;
use Applify;
app { shift->_script->_exit(5) };
HERE
  is $exited, 0, 'no exit yet';
  local @ARGV = ('-version');
  my $return = $app->_script->app->run;
  is $return, 25, 'returned zero';
  is $exited, 25, 'exited!';

  *CORE::GLOBAL::exit = *CORE::exit;
}

done_testing;

=pod

=head1 dummy pod

=cut
