use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

#use File::Spec::Functions;
#
#sub test_data_file { catfile(qw(t 07-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "separator => '::'" => sub {
  my $obj = Config::INI::RefVars->new(separator => '::');
  is($obj->separator, '::', 'separator()');
  my $src = [
             '[A]',
             'x=$(=)',
             'y=27',
             '',
             '[B]',
             'a var=$(A::y)',
             'empty1=$([A]y)',
             'empty2=$(A/y)',
            ];
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'A' => {
                     'x' => 'A',
                     'y' => '27'
                    },
             'B' => {
                     'a var' => '27',
                     'empty1' => '',
                     'empty2' => ''
                    }
            },
            'variables()');
};


subtest "separator => '/'" => sub {
  my $obj = Config::INI::RefVars->new(separator => '/');
  my $src = [
             '[A]',
             'x=$(=)',
             'y=27',
             '',
             '[B]',
             'a var=$(A/y)',
             'empty1=$([A]y)',
             'empty2=$(A::y)',
            ];
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'A' => {
                     'x' => 'A',
                     'y' => '27'
                    },
             'B' => {
                     'a var' => '27',
                     'empty1' => '',
                     'empty2' => ''
                    }
            },
            'variables()');
};


subtest 'separator in variable name' => sub {
  my $ini = <<'INI';
[FOO]
var = abcde

[BAR]
FOO/var = my var in section BAR
a = $(FOO/var)
b = $(BAR/FOO/var)
INI

  my $vars = Config::INI::RefVars->new(separator => '/') ->parse_ini(src => $ini)->variables;

  is($vars->{BAR}{'FOO/var'}, 'my var in section BAR',
     'separator remains part of a variable name in a definition');

  is($vars->{BAR}{a}, 'abcde',
     'single qualified reference uses FOO as section');

  is($vars->{BAR}{b}, 'my var in section BAR',
     'qualified reference may address a variable containing the separator');
};


#==================================================================================================
done_testing();
