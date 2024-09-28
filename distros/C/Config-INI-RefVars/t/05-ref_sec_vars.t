use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

#use File::Spec::Functions;
#
#sub test_data_file { catfile(qw(t 05-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#


my $obj = Config::INI::RefVars->new;


subtest "basic sec refs" => sub {
  subtest "very simple, using = and ==" => sub {
    my $src = <<'EOT';
[sec A]
X = Reference from other section: $([sec B]str)
Y = From variable $(==) in section $(=)
Z = >$([BLAH]blubb)<

[sec B]
X = Reference: $([sec A]Y)
str = huhu --->$(=)
EOT
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'sec A' => {
                           # Note the value of Y: "... ---> sec B"!
                           X => 'Reference from other section: huhu --->sec B',
                           Y => 'From variable Y in section sec A',
                           Z => '><'
                          },
               'sec B' => {
                           str => 'huhu --->sec B',
                           X   => 'Reference: From variable Y in section sec A'
                          }
              },
              'variables()');
  };
  subtest "section in variable" => sub {
    my $src = [
               '[A]',
               'the A variable = Variable in section $(=)',
               'section = $(=)',
               '[B]',
               'sec A = [A]',
               'ref A 1 = $($(sec A)the A variable)',
               'ref A 2 = $([$([A]section)]the A variable)',
               'ref A 3 = $([$($(sec A)section)]the A variable)',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
          'A' => {
                   'section' => 'A',
                   'the A variable' => 'Variable in section A'
                 },
          'B' => {
                   'ref A 1' => 'Variable in section A',
                   'ref A 2' => 'Variable in section A',
                   'ref A 3' => 'Variable in section A',
                   'sec A' => '[A]'
                 }
              },
              'variables()');
  };
};

subtest "chains" => sub {
  subtest "[section 1] ... [section 7]" => sub {
    my $src = [
               '[section 1]',
               'a= Variable $(==) in section $(=)',
               'b=$([section 1]a)',
               # ---
               '[section 2]',
               'a=$([section 1]a)',
               'b=$([section 1]a)',
               # ---
               '[section 3]',
               'a=$([section 1]a)',
               'b=$([section 2]a)',
               # ---
               '[section 4]',
               'a=$([section 1]a)',
               'b=$([section 3]a)',
               # ---
               '[section 5]',
               'a=$([section 1]a)',
               'b=$([section 4]a)',
               # ---
               '[section 6]',
               'a=$([section 1]a)',
               'b=$([section 5]a)',
               # ---
               '[section 7]',
               'a=$([section 1]a)',
               'b=$([section 6]a)',
              ];
    $obj->parse_ini(src => $src);
    my $vars = $obj->variables;
    while (my ($sec, $val) = each(%$vars)) {
      is_deeply($val, {
                       'a' => 'Variable a in section section 1',
                       'b' => 'Variable a in section section 1'
                      },
                "section '$sec'");
    }
    is_deeply($obj->sections_h, {
                                 'section 1' => 0,
                                 'section 2' => 1,
                                 'section 3' => 2,
                                 'section 4' => 3,
                                 'section 5' => 4,
                                 'section 6' => 5,
                                 'section 7' => 6,
                                },
              "sections_h"
              );
  };

  subtest "[section 1] ... [section 7] with := and .=" => sub {
    my $src = [
               '[section 1]',
               'a= Variable $(==) in section $(=)',
               'b:=$([section 1]a)',
               '',
               '[section 2]',
               'a:=$([section 1]a)',
               'b=$([section 1]a)',
               '',
               '[section 3]',
               'a:=$([section 1]a)',
               'b=$([section 2]a)',
               '',
               '[section 4]',
               'a=$([section 1]a)',
               'b:=$([section 3]a)',
               '',
               '[section 5]',
               'a:=$([section 1]a)',
               'b=$([section 4]a)',
               '',
               '[section 6]',
               'a=$([section 1]a)',
               'b:=$([section 5]a)',
               '',
               '[section 7]',
               'a.=$([section 1]a)',
               'b.=$([section 6]a)',
              ];
    $obj->parse_ini(src => $src);
    my $vars = $obj->variables;
    while (my ($sec, $val) = each(%$vars)) {
      is_deeply($val, {
                       'a' => 'Variable a in section section 1',
                       'b' => 'Variable a in section section 1'
                      },
                "section '$sec'");
    }
  };

  subtest "[section 1] ... [section 7] with := and .= and 'foreward ref'" => sub {
    my $src = [
               '[section 1]',
               'a= $([section 5]a)',
               'b:=$([section 5]a)',
               '',
               '[section 2]',
               'a:=$([section 1]a)',
               'b=$([section 1]a)',
               '',
               '[section 3]',
               'a:=$([section 1]a)',
               'b=$([section 2]a)',
               '',
               '[section 4]',
               'a=$([section 1]a)',
               'b:=$([section 3]a)',
               '',
               '[section 5]',
               'a:=Variable $(==) in section $(=)',
               'b=$([section 4]a)',
               '',
               '[section 6]',
               'a=$([section 1]a)',
               'b:=$([section 5]a)',
               '',
               '[section 7]',
               'a.=$([section 1]a)',
               'b.=$([section 6]a)',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => {
                               'a' => 'Variable a in section section 5',
                               'b' => ''
                              },
               'section 2' => {
                               'a' => '',
                               'b' => 'Variable a in section section 5'
                              },
               'section 3' => {
                               'a' => '',
                               'b' => ''
                              },
               'section 4' => {
                               'a' => 'Variable a in section section 5',
                               'b' => ''
                              },
               'section 5' => {
                               'a' => 'Variable a in section section 5',
                               'b' => 'Variable a in section section 5'
                              },
               'section 6' => {
                               'a' => 'Variable a in section section 5',
                               'b' => 'Variable a in section section 5'
                              },
               'section 7' => {
                               'a' => 'Variable a in section section 5',
                               'b' => 'Variable a in section section 5'
                              }
              },
              "variables()");
  };
};

subtest "mix" => sub {
  subtest "simple mix 1" => sub {
    my $src = [
               '[sec 1]',
               'sec2 = sec 2',
               '',
               '[sec 2]',
               'foo = Var $(==) in section $(=)',
               'bar := $([sec 3]var3)',
               'baz = $([sec 3]var3)',
               '',
               '[sec 3]',
               'var3 = $([$([sec 1]sec2)]foo)',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'sec 1' => {
                           'sec2' => 'sec 2'
                          },
               'sec 2' => {
                           'bar' => '',
                           'baz' => 'Var foo in section sec 2',
                           'foo' => 'Var foo in section sec 2'
                          },
               'sec 3' => {
                           'var3' => 'Var foo in section sec 2'
                          }
              },
              "variables()");
  };

  subtest "simple mix 2" => sub {
    my $src =
      [
       '[sec A]',
       'secname = sec C',
       'a=$([$(secname)]c)',
       '',
       '[sec B]',
       'section = [sec A]',
       'A=$($(section)a)',
       'weird=-$([sec A]=)-$([sec B]=)-$([sec C]=)--$([sec A]==)-$([sec B]==)-$([sec C]==)',
       '',
       '[sec C]',
       'c=A variable from section $(=)!',
       'd= $([Sec FOO]=)'       # Ref to non existing section!
      ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'sec A' => {
                           'a' => 'A variable from section sec C!',
                           'secname' => 'sec C'
                          },
               'sec B' => {
                           'A' => 'A variable from section sec C!',
                           'section' => '[sec A]',
                           'weird' => '-sec A-sec B-sec C----'
                          },
               'sec C' => {
                           'c' => 'A variable from section sec C!',
                           'd' => ''
                          }
              },
              "variables()");
  };
};

#==================================================================================================
done_testing();

