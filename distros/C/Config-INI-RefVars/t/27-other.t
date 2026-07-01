use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;


subtest 'm builtin' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& not,)
b = $(=& eq,foo,foo)
c = $(=& basename,/tmp/file.txt)
d = $(=& dirname,/tmp/file.txt)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, '1',        'not: false');
  is($vars->{b}, '1',        'eq: strings are equal');
  is($vars->{c}, 'file.txt', 'basename');
  is($vars->{d}, '/tmp',     'dirname');
};


#==================================================================================================
done_testing();
