use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

#use File::Spec::Functions;
#
#sub test_data_file { catfile(qw(t 06-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#


my $obj = Config::INI::RefVars->new;

subtest "basic" => sub {
  subtest "first examples, with and without arg 'tocopy_section'" => sub {
    subtest 'no explicite [__TOCOPY__]' => sub {
      my $src = [
                 '[A]',
                 'a=b'
                ];
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,  {A => {a => 'b'}}, 'variables()');
      is_deeply($obj->sections_h, {A => 0}, 'sections_h()');
      is_deeply($obj->sections,   ['A'], 'sections()');

      $obj->parse_ini(src => $src, tocopy_vars => {'a=b' => 1});
      is_deeply($obj->variables,  {A => {a => 'b'}}, 'variables()');
      is_deeply($obj->sections_h, {A => 0}, 'sections_h()');
      is_deeply($obj->sections,   ['A'], 'sections()');

      $obj->parse_ini(src => $src, tocopy_vars => {'ab' => 1});
      is_deeply($obj->variables,
                {
                 '__TOCOPY__' => {
                                  'ab' => '1'
                                 },
                 A => {a  => 'b',
                       ab => '1'
                      }
                },
                'variables()');
      is_deeply($obj->sections_h, {A => 0}, 'sections_h()');
      is_deeply($obj->sections,   ['A'], 'sections()');
    };

    subtest 'with explicite [__TOCOPY__]' => sub {
      my $src = [
                 '[__TOCOPY__]',  # explicite tocopy section (but empty)
                 '[A]',
                 'a=b'
                ];
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,  {__TOCOPY__ => {}, A => {a => 'b'}}, 'variables()');
      is_deeply($obj->sections_h, {__TOCOPY__ => 0, A => 1}, 'sections_h()');
      is_deeply($obj->sections,   [qw(__TOCOPY__ A)], 'sections()');
    };

    my $src = [
               'a=1',
               '',
               '[sec A]',
               '',
               '[sec B]',
               'a += huhu',
               '',
               '[sec C]',
               'a=27'
              ];

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                'a' => '1'
                               },
               'sec A' => {
                           'a' => '1'
                          },
               'sec B' => {
                           'a' => '1 huhu'
                          },
               'sec C' => {
                           'a' => '27'
                          }
              },
              'variables()');

    is($obj->current_tocopy_section, Config::INI::RefVars::DFLT_TOCOPY_SECTION,
       "current_tocopy_section() eq default");

    $obj->parse_ini(src => $src, tocopy_section => 'COM_SEC');
    is($obj->current_tocopy_section, 'COM_SEC', "current_tocopy_section() eq 'COM_SEC'");
    is($obj->tocopy_section, Config::INI::RefVars::DFLT_TOCOPY_SECTION,
       "tocopy_section() eq default");
    is_deeply($obj->variables,
              {
               'COM_SEC' => {
                             'a' => '1'
                            },
               'sec A' => {
                           'a' => '1'
                          },
               'sec B' => {
                           'a' => '1 huhu'
                          },
               'sec C' => {
                           'a' => '27'
                          }
              },
              'variables()');

    $obj->parse_ini(src => $src, tocopy_section => '');
    is_deeply($obj->variables,
              {
               ''      => {
                           'a' => '1'
                          },
               'sec A' => {
                           'a' => '1'
                          },
               'sec B' => {
                           'a' => '1 huhu'
                          },
               'sec C' => {
                           'a' => '27'
                          }
              },
              'variables()');
  };

  subtest 'with $(=) and explicite [__TOCOPY__]' => sub {
    my $src = [
               '[__TOCOPY__]',
               'theVar = Section: $(=)',
               '',
               '[A]',
               '',
               '[B]',
               'a var=$([A]theVar), not $([C]sec)',
               '[C]',
               'sec=$(=)'
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'A' => {
                       'theVar' => 'Section: A'
                      },
               'B' => {
                       'a var' => 'Section: A, not C',
                       'theVar' => 'Section: B'
                      },
               'C' => {
                       'theVar' => 'Section: C',
                       'sec'    => 'C'
                      },
               '__TOCOPY__' => {
                                'theVar' => 'Section: __TOCOPY__'
                               }
              },
              'variables()');
  };
};

subtest "Environment variables" => sub {
  subtest 'env and ENV and $( )' => sub {
    my $src = [
               '[sec Z]',
               'x=$([sec A]=ENV:FOO)',
               'y = $([sec XYY]=ENV:FOO)',
               'z = $(=env:FOO)',
               '',
               '[sec A]',
               'a=$(=ENV:NO_SUCH_VAR)$(=env:NO_SUCH_VAR)',
              ];
    local $ENV{FOO} = 'The FOO env variable$( )!';
    local $ENV{NO_SUCH_VAR};
    delete $ENV{NO_SUCH_VAR};
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'sec A' => {
                           'a' => ''
                          },
               'sec Z' => {
                           'x' => 'The FOO env variable$( )!',
                           'y' => '',
                           'z' => 'The FOO env variable !'
                          }
              },
              'variables()');
  };
  subtest "ENV and env" => sub {
    my $src = [
               '[sec Z]',
               'x= $(=ENV:FOO)',
               'y =$(=env:FOO)',
               '',
               '[sec A]',
               'AVar=Variable \'$(==)\' of section \'$(=)\'!',
              ];
    local $ENV{FOO} = '$([sec A]AVar)';
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'sec A' => {
                           'AVar' => 'Variable \'AVar\' of section \'sec A\'!'
                          },
               'sec Z' => {
                           'x' => '$([sec A]AVar)',
                           'y' => 'Variable \'AVar\' of section \'sec A\'!'
                          }
              },
              'variables()');
  };
};

subtest "tocopy, not tocopy" => sub {
  subtest "tocopy" => sub {
    my $expected = {
                    '__TOCOPY__' => {
                                     'a' => 'xyz',
                                     'foo' => 'abcde'
                                    },
                    'sec A' => {
                                'a' => 'xyz',
                                'foo' => 'abcde'
                               },
                    'sec B' => {
                                'a' => 'xyz',
                                'foo' => 'abcde'
                     }
                   };
    subtest "tocopy section" => sub {
      my $src = [
                 'a=xyz',
                 'foo=abcde',
                 '',
                 '[sec A]',
                 '',
                 '[sec B]',
                ];
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables, $expected, 'variables()');
    };
    subtest "tocopy: 'tocopy_vars' arg" => sub {
      my $src = [
                 '[sec A]',
                 '',
                 '[sec B]',
                ];
      $obj->parse_ini(src => $src, tocopy_vars => {a => 'xyz', foo => 'abcde'});
      is_deeply($obj->variables, $expected, 'variables()');
    };
  };
  subtest 'with $(=)' => sub {
    my $src = [
               'foo=$([sec A]=)',
               'bar=$(=)',
               '',
               '[sec A]',
               '',
               '[sec B]',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                'bar' => '__TOCOPY__',
                                'foo' => 'sec A'
                               },
               'sec A' => {
                           'bar' => 'sec A',
                           'foo' => 'sec A'
                          },
               'sec B' => {
                           'bar' => 'sec B',
                           'foo' => 'sec A'
                          }
              },
              'variables()');
  };
  subtest "'tocopy_section', section in input" => sub {
    my $src = [
               '[XY]',
               'a=1',
               '',
               '[sec A]',
              ];
    $obj->parse_ini(src => $src, tocopy_section => 'XY');
    is_deeply($obj->variables,
              {
               'XY' => {
                         'a' => '1'
                        },
               'sec A' => {
                           'a' => '1'
                          }
              },
              'variables()');
  };
  subtest "simple mix, with 'tocopy_section'" => sub {
    my $src = [
               'a.=xyz',     # tocopy section
               '',
               'foo=abcde',  # tocopy section
               '',
               '[sec A]',
               '',
               '[sec B]',
              ];
    $obj->parse_ini(src => $src,
                    tocopy_vars => {a => 27,
                                    c => 42,
                                    d => '$(x=y)!!!',
                                    'x=y' => 'hello'},
                    tocopy_section => '_C_',
                    not_tocopy => [qw(c foo)]);
    is_deeply($obj->variables,
              {
               '_C_' => {
                         'a' => '27xyz',
                         'c' => '42',
                         'd' => 'hello!!!',
                         'foo' => 'abcde'
                        },
               'sec A' => {
                           'a' => '27xyz',
                           'd' => 'hello!!!'
                          },
               'sec B' => {
                           'a' => '27xyz',
                           'd' => 'hello!!!'
                          }
              },
              'variables()');
  };
};

#==================================================================================================
done_testing();

