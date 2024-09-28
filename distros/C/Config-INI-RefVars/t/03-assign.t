use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use File::Spec::Functions;

sub test_data_file { catfile(qw(t 03-data), $_[0]) }


note("Testing assignments with and without auto vars, simple variable referencing");

#
# For heredocs containing INI data always use the single quote variant!
#

use constant DFLT_TOCOPY_SECTION => Config::INI::RefVars::DFLT_TOCOPY_SECTION;

subtest 'basic assignments' => sub {
  my $obj = Config::INI::RefVars->new;
  subtest 'basic.ini' => sub {
    foreach my $file (test_data_file('basic.ini'), test_data_file('basic_spaces.ini')) {
      subtest $file => sub {
        $obj->parse_ini(src => $file);
        is($obj->tocopy_section, DFLT_TOCOPY_SECTION, 'tocopy_section()');
        is($obj->current_tocopy_section, DFLT_TOCOPY_SECTION, 'current_tocopy_section()');
        is($obj->src_name, $file, 'src_name()');
        is_deeply($obj->sections,
                  [+DFLT_TOCOPY_SECTION, "this section"],
                  "sections()");
        is_deeply($obj->sections_h, { (DFLT_TOCOPY_SECTION) => 0,
                                      "this section"        => 1 },
                  "sections_h()");
        is_deeply($obj->variables, { (DFLT_TOCOPY_SECTION) => {foo => 'foo_val'},
                                     "this section"        => {foo => 'foo_val',
                                                               str => "hello world"}
                                   },
                  "variables()") or diag(explain($obj->variables));
      };
    }
  };
  subtest "other basic examples" => sub {
    my $src = [
               '[a section]',
               ' 1 = value' ,
               '2 = 1245',
               '2 =$(1)',    # clobber old value
               ' 3 = $(2)',
               'X=xyz',
               ' x_a += $(X)',
               ' y_a .= $(X)',
               ' x_b +>= $(X)',
               ' y_b .>= $(X)',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, { 'a section' => {
                                                 '1'   => 'value',
                                                 '2'   => 'value',
                                                 '3'   => 'value',
                                                 'X'   => 'xyz',
                                                 'x_a' => 'xyz',
                                                 'y_a' => 'xyz',
                                                 'x_b' => 'xyz',
                                                 'y_b' => 'xyz',
                                                }},
              "variables()") or diag(explain($obj->variables));

  };
};


subtest 'empty and one blank string' => sub {
  my $obj = Config::INI::RefVars->new;
  my $src = <<'EOT';
[the section]
empty-1 =
empty-2.=
empty-3 +=
empty-4=$()
empty-5 = $()$()$()$()$()$()
empty-6 = $(empty-4)
empty-6 ?= 1234567
blank-1 = $( )
blank-2 = $() $()
blank-3 +=
blank-3 +=
blank-4 = $(blank-3)
blank-5 := $(blank-3)$()$()$()
blank-5 ?= 98765421
blank-6 .=
blank-6 +=
blank-7 .=
blank-7 +=
blank-7 .=
blank-7 .=
blank-7 .=
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->sections, ["the section"], "sections()");
  my $sec_vars = $obj->variables->{'the section'};
  while (my ($var, $val) = each(%$sec_vars)) {
    my $prefix = substr($var, 0, 5);
    if ($prefix eq 'empty') {
      is($val, '', "$var: epmty value");
    } elsif ($prefix eq 'blank') {
      is($val, ' ', "$var: a blank");
    } else {
      die("$var: unexpected variable");
    }
  }
};

subtest 'more blanks' => sub {
  my $obj = Config::INI::RefVars->new;
  my $src = <<'EOT';
[some section]
blanks +=
blanks +=
blanks +=
blanks +=
blanks +=
blanks +=
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables, { 'some section' => {blanks => ' ' x 5} },
            'variables(), 5 blanks');
};


subtest 'trailing blanks' => sub {
  my $obj = Config::INI::RefVars->new;
  my $src = <<'EOT';
[some section]
4-trailing-blanks_1 = value    $()
4-trailing-blanks_2 = value$(    )
4-trailing-blanks_3 = value$(  )$(  )
4-trailing-blanks_4 = value$()    $()
4-trailing-blanks_5 = value$(    $())
4-trailing-blanks_6 = value$(  $(  ))
4-trailing-blanks_7 = value$($(  )$(  ))
4-trailing-blanks_8 = value
4-trailing-blanks_8+=
4-trailing-blanks_8+=
4-trailing-blanks_8+=
4-trailing-blanks_8+=
EOT
  $obj->parse_ini(src => $src);
  my $sec_vars = $obj->variables->{'some section'};
  while (my ($var, $val) = each(%$sec_vars)) {
    is($val, 'value    ', $var);
  }
};

subtest 'heading blanks' => sub {
  my $obj = Config::INI::RefVars->new;
  my $src = <<'EOT';
[some section]
4-heading-blanks_1 = $()    value
4-heading-blanks_2 = $(    )value
4-heading-blanks_3 = $(  )$(  )value
4-heading-blanks_4 = $()    $()value
4-heading-blanks_5 = $(    $())value
4-heading-blanks_6 = $(  $(  ))value
4-heading-blanks_7 = $($(  )$(  ))value
4-heading-blanks_8 =
4-heading-blanks_8+=
4-heading-blanks_8+=
4-heading-blanks_8+=
4-heading-blanks_8+= value
EOT
  $obj->parse_ini(src => $src);
  my $sec_vars = $obj->variables->{'some section'};
  while (my ($var, $val) = each(%$sec_vars)) {
    is($val, '    value', $var);
  }
};


subtest 'section name, variable name' => sub {
  my $src = <<'EOT';
[Sec-1]
info = This is variable '$(==)' in section $(=).

[Sec-2]
info = This is variable '$(==)' in section $(=).

[Sec-3]
info = This is variable '$(==)' in section $(=).
xyz  = This is variable '$(==)' in section $(=).
EOT
  my $obj = Config::INI::RefVars->new->parse_ini(src => $src);
  isa_ok($obj, 'Config::INI::RefVars');
  is_deeply($obj->variables,
            {'Sec-1' => {
                         info => "This is variable 'info' in section Sec-1."
                        },
             'Sec-2' => {
                         info => "This is variable 'info' in section Sec-2."
                        },
             'Sec-3' => {
                         info => "This is variable 'info' in section Sec-3.",
                         xyz  => "This is variable 'xyz' in section Sec-3."
                        }

            },
            'variables()');
};

subtest "??= and ?=" => sub {
  local $ENV{NO_SUCH_VAR};

  my $src = <<'EOT';
    [sec]
    a1?=A1
    a2??=A2

    b1=
    b2=

    b1 ?= B1
    b2 ??= B2

    c1:=$(=ENV:NO_SUCH_VAR)
    c2:=$(=ENV:NO_SUCH_VAR)
    c1?=C1
    c2??=C2
EOT
  my $obj = Config::INI::RefVars->new->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'sec' => {
                       'a1' => 'A1',
                       'a2' => 'A2',
                       'b1' => '',
                       'b2' => 'B2',
                       'c1' => '',
                       'c2' => 'C2'
                      }
            },
            'variables()');
};

#==================================================================================================
done_testing();

