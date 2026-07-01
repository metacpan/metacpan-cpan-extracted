use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;


subtest '#= definitions are stored separately from variables' => sub {

  my $ini = <<'INI';
global_var = hello
global_func #= $(1)

[sec]
var1 = abc
func1 #= $(1):$(2)

var2 = def
INI

  my $obj = Config::INI::RefVars->new();
  my $vars  = $obj->parse_ini(src => $ini)->variables();

  is($vars->{__TOCOPY__}{global_var}, 'hello', 'global variable stored normally');

  ok(!exists $vars->{__TOCOPY__}{global_func}, 'global function not stored as variable');
  is($vars->{sec}{var1}, 'abc', 'section variable stored normally');
  is($vars->{sec}{var2}, 'def', 'second section variable stored normally');

  ok(!exists $vars->{sec}{func1}, 'section function not stored as variable');

  my $funcs = $obj->{+Config::INI::RefVars::FUNCTIONS};
  is($funcs->{__TOCOPY__}{global_func}, '$(1)', 'global function stored');
  is($funcs->{sec}{func1}, '$(1):$(2)', 'section function stored');
};


#==================================================================================================
done_testing();
