use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warn;


use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
#sub test_data_file { catfile(qw(t 10-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

my $Dummy_Src = [
                 '[The Section]',
                 'The Variable=007'
                ];

subtest "tocopy_vars" => sub {
  subtest 'new()' => sub {
    like(exception { Config::INI::RefVars->new(tocopy_vars => 72) },
         qr/'tocopy_vars': expected HASH ref/,
         "tocopy_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(tocopy_vars => []) },
         qr/'tocopy_vars': expected HASH ref/,
         "tocopy_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(tocopy_vars => {
                                                               x => 'huhu',
                                                               y => {},
                                                               z => 23
                                                              }) },
         qr/'tocopy_vars': value of 'y' is a ref, expected scalar/,
         "tocopy_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(tocopy_vars => {
                                                               x      => 'huhu',
                                                               '=foo' => '',
                                                               z      => 23
                                                              }) },
         qr/'tocopy_vars': variable '=foo': name is not permitted/,
         "tocopy_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(tocopy_vars => {
                                                               x      => 'huhu',
                                                               ';foo' => '',
                                                               z      => 23
                                                              }) },
         qr/'tocopy_vars': variable ';foo': name is not permitted/,
         "tocopy_vars: the code died as expected");
  };

  subtest 'parse_ini()' => sub {
    my $obj = Config::INI::RefVars->new();

    like(exception { $obj->parse_ini(src => $Dummy_Src, tocopy_vars => 72) },
         qr/'tocopy_vars': expected HASH ref/,
         "tocopy_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, tocopy_vars => []) },
         qr/'tocopy_vars': expected HASH ref/,
         "tocopy_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, tocopy_vars => {
                                                                        x => 'huhu',
                                                                        y => {},
                                                                        z => 23
                                                                       }) },
         qr/'tocopy_vars': value of 'y' is a ref, expected scalar/,
         "tocopy_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, tocopy_vars => {
                                                                        x      => 'huhu',
                                                                        '=foo' => '',
                                                                        z      => 23
                                                              }) },
         qr/'tocopy_vars': variable '=foo': name is not permitted/,
         "tocopy_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, tocopy_vars => {
                                                                        x      => 'huhu',
                                                                        ';foo' => '',
                                                                        z      => 23
                                                                       }) },
         qr/'tocopy_vars': variable ';foo': name is not permitted/,
         "tocopy_vars: the code died as expected");
  };
};


subtest "not_tocopy" => sub {
  subtest 'new()' => sub {
    like(exception { Config::INI::RefVars->new(not_tocopy => 72) },
         qr/'not_tocopy': unexpected type: must be ARRAY or HASH ref/,
         "not_tocopy: the code died as expected");

    like(exception { Config::INI::RefVars->new(not_tocopy => ['a', undef, 'b']) },
         qr/'not_tocopy': undefined value in array/,
         "not_tocopy: the code died as expected");

    like(exception { Config::INI::RefVars->new(not_tocopy => ['a', [], 'b']) },
         qr/'not_tocopy': unexpected ref value in array/,
         "not_tocopy: the code died as expected");
  };

  subtest 'parse_ini()' => sub {
    my $obj = Config::INI::RefVars->new();

    like(exception { $obj->parse_ini(src => $Dummy_Src, not_tocopy => 72) },
         qr/'not_tocopy': unexpected type: must be ARRAY or HASH ref/,
         "not_tocopy: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, not_tocopy => ['a', undef, 'b']) },
         qr/'not_tocopy': undefined value in array/,
         "not_tocopy: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, not_tocopy => ['a', [], 'b']) },
         qr/'not_tocopy': unexpected ref value in array/,
         "not_tocopy: the code died as expected");
  };
};

subtest "separator (only possible in new())" => sub {
  my $dummy = "";
  like(exception { Config::INI::RefVars->new(separator => \$dummy) },
       qr/'separator': unexpected ref type, must be a scalar/,
       "separator: the code died as expected");

  like(exception { Config::INI::RefVars->new(separator => '=') },
       qr/'separator': invalid value. Allowed chars: [[:punct:]]+/,
       "separator: the code died as expected");
};


subtest "tocopy_section" => sub {
  like(exception { Config::INI::RefVars->new(tocopy_section => []) },
       qr/'tocopy_section': must not be a reference/,
       "separator: the code died as expected");

  my $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => '[sec]', tocopy_section => []) },
       qr/'tocopy_section': must not be a reference/,
       "separator: the code died as expected");
};


subtest "src_name (only possible in parse_ini())" => sub {
  my $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => '[sec]', src_name => []) },
       qr/'src_name': must not be a reference/,
       "separator: the code died as expected");
};


subtest "src (only possible in (parse_ini())" => sub {
  my $dummy = "";
  my $obj = Config::INI::RefVars->new();

  like(exception { $obj->parse_ini() },
       qr/'src': missing mandatory argument/,
       "src: the code died as expected");

  like(exception { $obj->parse_ini(src => {}) },
       qr/'src': HASH: ref type not allowed/,
       "src: the code died as expected");

  like(exception { $obj->parse_ini(src => ['a=1', [], '[sec]']) },
       qr/'src': unexpected ref type in array/,
       "src: the code died as expected");
};


subtest "Unsupported argument" => sub {
  like(exception { Config::INI::RefVars->new(FOO => []) },
       qr/'FOO': unsupported argument/,
       "unsupported argument: the code died as expected");

  my $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => $Dummy_Src, FOO => []) },
       qr/'FOO': unsupported argument/,
       "unsupported argument: the code died as expected");
};


subtest "warning: tocopy_vars" => sub {
  subtest "new()" => sub {
    my $obj;
    warning_like(sub {$obj = Config::INI::RefVars->new(tocopy_vars => {a => 1,
                                                                       b => undef,
                                                                       c => 3})
                    },
                 qr/'tocopy_vars': value 'b' is undef - treated as empty string/,
                 "'tocopy_vars': the code printed the warning as expected");
    $obj->parse_ini(src => [ '[sec]' ]);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                'a' => '1',
                                'b' => '',
                                'c' => '3'
                               },
               'sec' => {
                         'a' => '1',
                         'b' => '',
                         'c' => '3'
                        }
              },
              'variables()');
  };

  subtest "parse_ini()" => sub {
    my $obj = Config::INI::RefVars->new();
    warning_like(sub {$obj->parse_ini(src         => [ '[sec]' ],
                                      tocopy_vars => {a => 1,
                                                      b => undef,
                                                      c => 3})
                    },
                 qr/'tocopy_vars': value 'b' is undef - treated as empty string/,
                 "'tocopy_vars': the code printed the warning as expected");
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                'a' => '1',
                                'b' => '',
                                'c' => '3'
                               },
               'sec' => {
                         'a' => '1',
                         'b' => '',
                         'c' => '3'
                        }
              },
              'variables()');
  };
};


subtest "no error" => sub {
  my $obj;
  warning_is( sub { $obj = Config::INI::RefVars->new(tocopy_section => undef,
                                                     tocopy_vars    => undef,
                                                     not_tocopy     => undef,
                                                     separator      => undef,
                                                );
              },
              "",
              "new() - no ");

  # We do not test cleanup => undef here, as this is done somewhere else.
  warning_is( sub { $obj->parse_ini(src            => [ '[sec]' ],
                                    tocopy_section => undef,
                                    tocopy_vars    => undef,
                                    not_tocopy     => undef,
                                   )
                  },
              "",
              "new() - no ");
  is_deeply($obj->variables, { sec => {} }, 'variables()');
};

#==================================================================================================
done_testing();
