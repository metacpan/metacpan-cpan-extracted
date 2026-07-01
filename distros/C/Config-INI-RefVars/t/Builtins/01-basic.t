use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catdir catfile);

use Config::INI::RefVars::Builtins ();

my $Dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();

my %Names = map {$_ => undef } qw(and
                                  basename
                                  catdir
                                  catfile
                                  concat
                                  dirname
                                  eq
                                  if
                                  ignore
                                  join
                                  m
                                  not
                                  or
                                  s
                                  substr
                                  tr
                                  x
                                );

isa_ok($Dispatch, 'HASH', 'dispatch table');

while (my ($name, $value) = each %$Dispatch) {
  is(ref($Dispatch->{$name}), 'CODE', "$name is code ref");
  ok(index($name, '_') < 0, "'$name' contains no underscore");
  ok(exists($Names{$name}), "'$name': expected");
  delete $Names{$name};
}

ok(!%Names, "all names found") or diag("Missing: " . join(', ', keys(%Names)));

is($Dispatch->{catdir}->('foo', 'bar'), catdir('foo', 'bar'), 'catdir');
is($Dispatch->{catfile}->('foo', 'bar.txt'), catfile('foo', 'bar.txt'), 'catfile');
is($Dispatch->{ignore}->('a', 'b', 'c'), '', 'ignore');
is($Dispatch->{concat}->('a', 'b', 'c'), 'abc', 'concat');
is($Dispatch->{join}->(':', 'a', 'b', 'c'), 'a:b:c', 'join');
is($Dispatch->{x}->('ab', 3), 'ababab', 'x');


#==================================================================================================
done_testing();
