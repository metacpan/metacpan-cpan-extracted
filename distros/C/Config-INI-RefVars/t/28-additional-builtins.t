use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest "add new builtins" => sub {
  my $cfg = Config::INI::RefVars->new(
                                      builtins => {
                                                   _uc      => sub { return uc($_[0] // ""); },
                                                   _repeat  => sub { my ($str, $n) = @_;
                                                                     return $str x $n;
                                                                   },
                                                   _sprintf => sub {
                                                     my $fmt = shift // return "";
                                                     my $result;
                                                     eval { $result = sprintf($fmt, @_); 1; } or
                                                       die("_sprintf: $@\n");
                                                     return $result;
                                                   },
                                                  },
                                     );
  $cfg->parse_ini(
                  src => <<'INI'
[sec]
a = $(=& _uc,hello)
b = $(=& _repeat,ab,3)
c = $(=& _sprintf, <%s:%d>, a string, 27)
INI
                 );
  my $vars = $cfg->variables()->{sec};

  is($vars->{a}, 'HELLO',         'custom builtin _uc');
  is($vars->{b}, 'ababab',        'custom builtin _repeat');
  is($vars->{c}, '<a string:27>', 'custom builtin _sprintf');
};


subtest "overwrite buildin" => sub {
  my $cfg = Config::INI::RefVars->new(builtins => { concat => sub { return join(':', @_); },
                                                  },
                                     );
  $cfg->parse_ini(src => <<'INI'
[sec]
x = $(=& concat,a,b,c)
INI
                 );
  my $vars = $cfg->variables()->{sec};
  is($vars->{x}, 'a:b:c', 'custom builtin uc');
};


#==================================================================================================
done_testing();
