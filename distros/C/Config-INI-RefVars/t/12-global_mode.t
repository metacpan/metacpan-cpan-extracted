use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use File::Spec::Functions;
use Config;

#
#sub test_data_file { catfile(qw(t 07-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

my $VERSION = $Config::INI::RefVars::VERSION;
my $Dir_Sep = catdir("", "");
my ($True, $False) = (!!1, !!0);

subtest "accessor global_mode()" => sub {
  subtest "default" => sub {
    my $obj = Config::INI::RefVars->new;
    is($obj->global_mode, $False, 'global_mode() false');
  };
  subtest "global_mode false" => sub {
    my $obj = Config::INI::RefVars->new(global_mode => 0);
    is($obj->global_mode, $False, 'global_mode() false');
    $obj = Config::INI::RefVars->new(global_mode => $False);
    is($obj->global_mode, $False, 'global_mode() false');
  };
  subtest "global_mode true" => sub {
    my $obj = Config::INI::RefVars->new(global_mode => 1234);
    is($obj->global_mode, $True, 'global_mode() true');
  };
};


subtest "simple examples" => sub {
  my $obj = Config::INI::RefVars->new(global_mode => 1);
  subtest "No TOCOPY section" => sub {
    my $src = [ '[A]',
                'foo = 123',
                '[B]'
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'A' => {
                       'foo' => '123'
                      },
               'B' => {}
              },
              'variables(), with cleanup');
    is($obj->global_mode, $True, 'global_mode() true');
    $obj->parse_ini(src => $src, cleanup => 0);
    is_deeply($obj->variables,
              {
               'A' => {
                       '='   => 'A',
                       'foo' => '123'
                      },
               'B' => {
                       '=' => 'B'
                      },
               '__TOCOPY__' => {
                                '=' => '__TOCOPY__',
                                '=:' => $Dir_Sep,
                                '=::' => $Config{path_sep},
                                '=VERSION' => $VERSION,
                                '=srcname' => 'INI data'
                               }
              },
              'variables(), no cleanup');
    is($obj->global_mode, $True, 'global_mode() true');
  };

  subtest "With TOCOPY section" => sub {
    my $src = [
               '[__TOCOPY__]',
               'global=i am global',
               'not common= i am NOT global',
               '[A]',
               'foo = 123',
               'bar=global: $(global)',
               'baz=global: $([__TOCOPY__]global)',
               '[B]',
               'bar=not common: $(not common)',
               'baz=not common: $([__TOCOPY__]not common)',
               'global:=$(global) (but local)',
               'x=$([A]=srcname)',
               'y=$(=srcname)'
              ];
    $obj->parse_ini(src => $src, not_tocopy => ['not common']);
    is_deeply($obj->variables,
              {
               'A' => {
                       'bar' => 'global: i am global',
                       'baz' => 'global: i am global',
                       'foo' => '123'
                      },
               'B' => {
                       'bar'    => 'not common: ',
                       'baz'    => 'not common: i am NOT global',
                       'global' => 'i am global (but local)',
                       'x'      => 'INI data',
                       'y'      => 'INI data'
                      },
               '__TOCOPY__' => {
                                'global' => 'i am global',
                                'not common' => 'i am NOT global'
                               }
              },
              'variables(), with cleanup');
    is($obj->global_mode, $True, 'global_mode() true');
    $obj->parse_ini(src => $src, not_tocopy => ['not common'], cleanup => 0);
    is_deeply($obj->variables,
              {
               'A' => {
                       '=' => 'A',
                       'bar' => 'global: i am global',
                       'baz' => 'global: i am global',
                       'foo' => '123'
                      },
               'B' => {
                       '=' => 'B',
                       'bar' => 'not common: ',
                       'baz' => 'not common: i am NOT global',
                       'global' => 'i am global (but local)',
                       'x' => 'INI data',
                       'y' => 'INI data'
                      },
               '__TOCOPY__' => {
                                '=' => '__TOCOPY__',
                                '=:' => $Dir_Sep,
                                '=::' => $Config{path_sep},
                                '=VERSION' => $VERSION,
                                '=srcname' => 'INI data',
                                'global' => 'i am global',
                                'not common' => 'i am NOT global'
                               }
              },
              'variables(), no cleanup');
    is($obj->global_mode, $True, 'global_mode() true');
  };
};

#==================================================================================================
done_testing();

