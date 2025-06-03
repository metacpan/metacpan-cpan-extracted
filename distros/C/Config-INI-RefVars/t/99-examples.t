use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
use File::Spec::Functions;

sub test_data_file { catfile(qw(t 99-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "SYNOPSIS" => sub {
  my $my_ini_file = test_data_file('dummy.ini');

  my $ini_reader = Config::INI::RefVars->new();
  $ini_reader->parse_ini(src => $my_ini_file);
  my $variables = $ini_reader->variables;
  while (my ($section, $section_vars) = each(%$variables)) {
    isa_ok($section_vars, 'HASH');
  }
  is_deeply($variables,
            {
             '__TOCOPY__' => {
                              'section' => '__TOCOPY__'
                             },
             'sec A' => {
                         'bar' => 'Variable foo in section sec A',
                         'foo' => 'Variable foo in section sec A!',
                         'section' => 'sec A'
                        },
             'sec B' => {
                         'baz' => 'from sec B: ref foo from sec A: Variable foo in section sec A!',
                         'section' => 'sec B'
                        }
            },
            'variables()'
           );
};

subtest "COMMENTS" => sub {
  my $obj = Config::INI::RefVars->new();
  my $src = [
             '[section]  ; My fancy section',
             '# This is a comment',
             '; This is also a comment',
             '    ;! a comment, but: avoid ";!" at the very beginning of a line!',
             'var = value ; this is not a comment but part of the value.',
            ];
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             section => {var => 'value ; this is not a comment but part of the value.'}
            },
            'variables()'
           );
};

subtest "HEADERS" => sub {
  my $obj = Config::INI::RefVars->new();
  my $src = [
             '[section]',
             '[]',
            ];

  $obj->parse_ini(src => $src);
  is_deeply($obj->sections, ['section', ''], 'sections()');
};


subtest "VARIABLES AND ASSIGNMENT OPERATORS" => sub {
  subtest "??=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = <<'EOT';
      [sec]
      env_var:=$(=ENV:ENV_VAR)
      env_var??=the default

      wrong1=$(=ENV:ENV_VAR)
      wrong1??=the default

      wrong2:=$(=ENV:ENV_VAR)
      wrong1?=the default
EOT
    subtest "ENV_VAR is undef" => sub {
      local $ENV{ENV_VAR};
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,
                {
                 sec => {
                         env_var => 'the default',
                         wrong1  => '',
                         wrong2  => ''
                        }
                },
                'variables()');
    };
    subtest "ENV_VAR is empty" => sub {
      local $ENV{ENV_VAR} = "";
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,
                {
                 sec => {
                         env_var => 'the default',
                         wrong1  => '',
                         wrong2  => ''
                        }
                },
                'variables()');
    };
    subtest "ENV_VAR is not empty" => sub {
      local $ENV{ENV_VAR} = "blah";
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,
                {
                 sec => {
                         env_var => 'blah',
                         wrong1  => 'blah',
                         wrong2  => 'blah'
                        }
                },
                'variables()');
    };

  };
  subtest ".=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var.=123',
               '[section 2]',
               'var.=123',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => 'abc123'},
               'section 2' => { var => '123'},
              },
              'variables()');
  };

  subtest "+=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var+=123',
               '[section 2]',
               'var+=123',
               '[section 3]',
               'var=abc',
               'var+=',
               '[section 4]',
               'var+=',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => 'abc 123'},
               'section 2' => { var => '123'},
               'section 3' => { var => 'abc '},
               'section 4' => { var => ''},
              },
              'variables()');
  };

  subtest ".>=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var.>=123',
               '[section 2]',
               'var.>=123',
               '[section 3]',
               'var.>=',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => '123abc'},
               'section 2' => { var => '123'},
               'section 3' => { var => ''},
              },
              'variables()');
  };

  subtest "+>=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var+>=123',
               '[section 2]',
               'var+>=123',
               '[section 3]',
               'var=abc',
               'var+>=',
               '[section 4]',
               'var+>=',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => '123 abc'},
               'section 2' => { var => '123'},
               'section 3' => { var => ' abc'},
               'section 4' => { var => ''},
              },
              'variables()');
  };
};


subtest "REFERENCING VARIABLES" => sub {
  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => [
                          '[sec1]',
                          'a=hello',
                          'b=world',
                          'c=$(a) $(b)',

                          '[sec2]',
                          'c=$(a) $(b)',
                          'a=hello',
                          'b=world',

                          '[sec3]',
                          'c:=$(a) $(b)',
                          'a=hello',
                          'b=world',
                         ]);
  is_deeply($obj->variables,
            {
             sec1 => {a => 'hello', b => 'world', c => 'hello world'},
             sec2 => {a => 'hello', b => 'world', c => 'hello world'},
             sec3 => {a => 'hello', b => 'world', c => ' '}
            },
            'variables()');

  my $src = <<'EOT';
  [sec]
   foo=the foo value
   var 1=fo
   var 2=o
   bar=$($(var 1)$(var 2))
EOT

  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             sec => {
                     'foo'   => 'the foo value',
                     'var 1' => 'fo',
                     'var 2' => 'o',
                     'bar'    => 'the foo value',
                    }
            },
            'variables()');

  $src = <<'EOT';
   [section]
   var = $$()(FOO)
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables, { 'section' => { 'var' => '$(FOO)' } }, 'variables()');


  $src = <<'EOT';
   [sec A]
   foo=Referencing a variable from section: $([sec B]bar)

   [sec B]
   bar=Referenced!
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'sec A' => {foo => 'Referencing a variable from section: Referenced!'},
             'sec B' => {bar => 'Referenced!'}
            },
            'variables()');

  $src = <<'EOT';
   [A]
   a var = 1234567

   [B]
   b var = a var
   nested = $([$([C]c var)]$(b var))

   [C]
   c var = A
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'A' => {
                     'a var' => '1234567'
                    },
             'B' => {
                     'b var' => 'a var',
                     'nested' => '1234567'
                    },
             'C' => {
                     'c var' => 'A'
                    }
            },
            'variables()');
};

subtest "PREDEFINED VARIABLES" => sub {
  my $obj = Config::INI::RefVars->new();

  my $src = <<'EOT';
   [A]
   foo=variable $(==) of section $(=)
   ref=Reference to foo of section B: $([B]foo)

   [B]
   foo=variable $(==) of section $(=)
   bar=$(foo)
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'A' => {
                     'foo' => 'variable foo of section A',
                     'ref' => 'Reference to foo of section B: variable foo of section B'
                    },
             'B' => {
                     'bar' => 'variable foo of section B',
                     'foo' => 'variable foo of section B'
                    }
            },
            'variables()');

  $src = <<'EOT';
   [sec]
   foo = abc   $()
   bar = $(   )abc

   var=hello!
   x=$(var)
   y=$$()(var)
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'sec' => {
                       'bar' => '   abc',
                       'foo' => 'abc   ',
                       'var' => 'hello!',
                       'x' => 'hello!',
                       'y' => '$(var)'
                      }
            },
            'variables()');
};


subtest "ACCESSING ENVIRONMENT VARIABLES" => sub {
  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => [
                          '[A]',
                          'path = $(=ENV:PATH)'
                         ]);
  is_deeply($obj->variables, { A => { path => $ENV{PATH} } }, 'variables()');
  local $ENV{FOO} = '$(var)';
  my $src = <<'EOT';
   [sec]
   var=hello!
   x=$(=ENV:FOO)
   y=$(=env:FOO)
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             sec => {
                     var => 'hello!',
                     x   => '$(var)',
                     y   => 'hello!',
                    }
            },
            'variables()');
};

subtest "THE SECTION TOCOPY" => sub {
  my $obj = Config::INI::RefVars->new();

  subtest "tocopy and manual copying" => sub {
    my $src = <<'EOT';
     [__TOCOPY__]
     some var=some value
     section info=$(=)

     [A]

     [B]
EOT
    my $expected = {
                    __TOCOPY__ => { 'some var' => 'some value', 'section info' => '__TOCOPY__'},
                    A => { 'some var' => 'some value', 'section info' => 'A'},
                    B => { 'some var' => 'some value', 'section info' => 'B'},
                   };
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $expected, 'variables()');

    $src = <<'EOT';
     [__TOCOPY__]
     some var=some value
     section info=$(=)

     [A]
     some var=some value
     section info=$(=)

     [B]
     some var=some value
     section info=$(=)
EOT
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $expected, 'variables()');
  };
  subtest "with and without explicite __TOCOPY__" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src1 = <<'EOT';
     [__TOCOPY__]
     a=this
     b=that

     [sec]
      x=y
EOT
    my $expected = {
                    __TOCOPY__ => {a => 'this', b => 'that'},
                    sec        => {a => 'this', b => 'that', x => 'y'},
                   };
    $obj->parse_ini(src => $src1);
    is_deeply($obj->variables, $expected, 'variables()');

    my $src2 = <<'EOT';
     a=this
     b=that

     [sec]
      x=y
EOT
    $obj->parse_ini(src => $src2);
    is_deeply($obj->variables, $expected, 'variables()');

    my $obj_gm = Config::INI::RefVars->new(global_mode => 1);
    $obj_gm->parse_ini(src => $src1);
    is_deeply($obj_gm->variables,
              {
               __TOCOPY__ => {a => 'this', b => 'that'},
               sec        => {x => 'y'},
              },
              'variables(), global mode');
  };
  subtest "global vs default" => sub {
    my $src = <<'EOT';
      section=$(=)
      x=GLOBAL
      x_val=$(x)

      [local-sec]
      var_1 := $(section)
      var_2 = $(section)

      x=LOCAL

      x_1 := $(x_val)
      x_2 = $(x_val)
EOT
    my $obj_dflt = Config::INI::RefVars->new()->parse_ini(src => $src);
    my $obj_gm   = Config::INI::RefVars->new(global_mode => 1)->parse_ini(src => $src);
    is_deeply($obj_dflt->variables,
              {
               '__TOCOPY__' => {
                                'section' => '__TOCOPY__',
                                'x' => 'GLOBAL',
                                'x_val' => 'GLOBAL'
                               },
               'local-sec' => {
                               'section' => 'local-sec',
                               'var_1' => 'local-sec',
                               'var_2' => 'local-sec',
                               'x' => 'LOCAL',
                               'x_1' => 'LOCAL',
                               'x_2' => 'LOCAL',
                               'x_val' => 'LOCAL'
                              }
              },
              'variables(), default mode');
    is_deeply($obj_gm->variables,
              {
               '__TOCOPY__' => {
                                'section' => '__TOCOPY__',
                                'x' => 'GLOBAL',
                                'x_val' => 'GLOBAL'
                               },
               'local-sec' => {
                               'var_1' => 'local-sec',
                               'var_2' => '__TOCOPY__',
                               'x' => 'LOCAL',
                               'x_1' => 'LOCAL',
                               'x_2' => 'GLOBAL'
                         }
              },
              'variables(), global mode; different values for var_2 and ');
  };
};


subtest "PITFALLS" => sub {
  my $obj = Config::INI::RefVars->new();
  my $src = <<'EOT';
    [A]
    a=1

    [B]
    b=2
EOT
  $obj->parse_ini(src => $src, tocopy_vars => {'foo' => 'xyz'});
  is_deeply($obj->variables,
            {
             'A' => {
                     'a' => '1',
                     'foo' => 'xyz'
                    },
             'B' => {
                     'b' => '2',
                     'foo' => 'xyz'
                    },
             '__TOCOPY__' => {
                              'foo' => 'xyz'
                             }
            },
            'variables()');
  is_deeply($obj->sections_h, { A => '0', B => '1' }, 'sections_h())');
  is_deeply($obj->sections,   [qw(A B)],            'sections())');
};

subtest "EXAMPLES" => sub {
  my $obj = Config::INI::RefVars->new(separator      => "\\",
                                      cmnt_vl        => 1,
                                      tocopy_section => 'Settings',
                                      global_mode    => 1);
  # see https://www.dhcpserver.de/cms/ini_file_reference/special/sectionname-syntax-for-ini-file-variables/
  my $src = <<'EOT';
   [Settings]
   BaseDir="d:\dhcpsrv" ; dhcpsrv.exe resides here
   IPBIND_1=192.168.17.2
   IPPOOL_1=$(Settings\IPBIND_1)-50
   AssociateBindsToPools=1
   Trace=1
   TraceFile="$(BaseDir)\dhcptrc.txt" ; trace file

   [DNS-Settings]
   EnableDNS=1

   [General]
   SUBNETMASK=255.255.255.0
   DNS_1=$(IPBIND_1)

   [TFTP-Settings]
   EnableTFTP=1
   Root="$(BaseDir)\wwwroot" ; use wwwroot for http and tftp

   [HTTP-Settings]
   EnableHTTP=1
   Root="$(BaseDir)\wwwroot" ; use wwwroot for http and tftp
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'Settings' => {
                            'AssociateBindsToPools' => '1',
                            'BaseDir' => '"d:\\dhcpsrv"',
                            'IPBIND_1' => '192.168.17.2',
                            'IPPOOL_1' => '192.168.17.2-50',
                            'Trace' => '1',
                            'TraceFile' => '""d:\\dhcpsrv"\\dhcptrc.txt"'
                           },
             'DNS-Settings' => {
                                'EnableDNS' => '1',
                               },
             'General' => {
                           'DNS_1' => '192.168.17.2',
                           'SUBNETMASK' => '255.255.255.0'
                          },
             'TFTP-Settings' => {
                                 'EnableTFTP' => '1',
                                 'Root' => '""d:\\dhcpsrv"\\wwwroot"'
                                },
             'HTTP-Settings' => {
                                 'EnableHTTP' => '1',
                                 'Root' => '""d:\\dhcpsrv"\\wwwroot"'
                                },

            }
           );
};

#==================================================================================================
done_testing();
