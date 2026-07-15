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

  my $vars = Config::INI::RefVars->new(separator => '/')->parse_ini(src => $ini)->variables;

  is($vars->{BAR}{'FOO/var'}, 'my var in section BAR',
     'separator remains part of a variable name in a definition');

  is($vars->{BAR}{a}, 'abcde',
     'single qualified reference uses FOO as section');

  is($vars->{BAR}{b}, 'my var in section BAR',
     'qualified reference may address a variable containing the separator');
};


subtest 'separator in tocopy_vars variable name' => sub {
  subtest 'default' => sub {
    my $ini =<<'INI';
[FOO]
var=abcde

[BAR]
FOO/var=my var in section BAR
a=$(FOO/var)
b=$(BAR/FOO/var)
c=$(FOO/FOO/var)
x=$([FOO]var)
y=$([BAR][FOO]var)
z=$([FOO][FOO]var)
INI
    my $obj = Config::INI::RefVars->new(tocopy_vars => {'[FOO]var' => "tocopy_vars: [FOO]var",
                                                        'FOO/var'  => "tocopy_vars: FOO/var"});
    is_deeply($obj->parse_ini(src => $ini)->variables,
              {
               'BAR' => {
                         'FOO/var' => 'my var in section BAR',
                         '[FOO]var' => 'tocopy_vars: [FOO]var',
                         'a' => 'my var in section BAR',
                         'b' => '',
                         'c' => '',
                         'x' => 'abcde',
                         'y' => 'tocopy_vars: [FOO]var',
                         'z' => 'tocopy_vars: [FOO]var'
                        },
               'FOO' => {
                         'FOO/var' => 'tocopy_vars: FOO/var',
                         '[FOO]var' => 'tocopy_vars: [FOO]var',
                         'var' => 'abcde'
                        },
               '__TOCOPY__' => {
                                'FOO/var' => 'tocopy_vars: FOO/var',
                                '[FOO]var' => 'tocopy_vars: [FOO]var'
                               }
              },
              'variables() returns expected data');
  };

  subtest '' => sub {
    my $ini =<<'INI';
[FOO]
var=abcde

[BAR]
FOO/var=my var in section BAR
a=$(FOO/var)
b=$(BAR/FOO/var)
c=$(FOO/FOO/var)
x=$([FOO]var)
y=$([BAR][FOO]var)
z=$([FOO][FOO]var)
INI
    my $obj = Config::INI::RefVars->new(separator   => "/",
                                        tocopy_vars => {'[FOO]var' => "tocopy_vars: [FOO]var",
                                                        'FOO/var'  => "tocopy_vars: FOO/var"});
    is_deeply($obj->parse_ini(src => $ini)->variables,
              {
               'BAR' => {
                         'FOO/var' => 'my var in section BAR',
                         '[FOO]var' => 'tocopy_vars: [FOO]var',
                         'a' => 'abcde',
                         'b' => 'my var in section BAR',
                         'c' => 'tocopy_vars: FOO/var',
                         'x' => 'tocopy_vars: [FOO]var',
                         'y' => '',
                         'z' => ''
                        },
               'FOO' => {
                         'FOO/var' => 'tocopy_vars: FOO/var',
                         '[FOO]var' => 'tocopy_vars: [FOO]var',
                         'var' => 'abcde'
                        },
               '__TOCOPY__' => {
                                'FOO/var' => 'tocopy_vars: FOO/var',
                                '[FOO]var' => 'tocopy_vars: [FOO]var'
                               }
              },
              'variables() returns expected data');
  };
};

#==================================================================================================
done_testing();
