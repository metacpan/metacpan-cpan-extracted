use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use File::Spec::Functions qw(catdir catfile rel2abs splitpath);

sub test_data_file { catfile(qw(t 08-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

my $Path_Sep = catdir("", "");

subtest "not from file" => sub {
  my $expected = {
                  'section 1' => {
                                  '1a' => 'INI data',
                                  '1b' => '',
                                  '1c' => '',
                                  '1d' => $Path_Sep,
                                  '1e' => 'section 1',
                                  '1f' => '',
                                  '1g' => '  ',
                                  '2a' => 'INI data',
                                  '2b' => '',
                                  '2c' => '',
                                  '2d' => $Path_Sep,
                                  '2e' => 'section 2',
                                  '2f' => '',
                                  '2g' => '  ',
                                  '3a' => '',
                                  '3b' => '',
                                  '3c' => '',
                                  '3d' => '',
                                  '3e' => '',
                                  '3f' => '',
                                  '3g' => ''
                                 },
                  'section 2' => {}
                 };
    subtest "default section ref" => sub {
      my $obj = Config::INI::RefVars->new();
      my $src = [
                 '[section 1]',
                 '1a=$(=srcname)',
                 '1b=$(=srcfile)',
                 '1c=$(=srcdir)',
                 '1d=$(=:)',
                 '1e=$(=)',
                 '1f=$()',
                 '1g=$(  )',

                 '2a=$([section 2]=srcname)',
                 '2b=$([section 2]=srcfile)',
                 '2c=$([section 2]=srcdir)',
                 '2d=$([section 2]=:)',
                 '2e=$([section 2]=)',
                 '2f=$([section 2]x)',
                 '2g=$([section 2]  )',

                 '3a=$([section 3]=srcname)',
                 '3b=$([section 3]=srcfile)',
                 '3c=$([section 3]=srcdir)',
                 '3d=$([section 3]=:)',
                 '3e=$([section 3]=)',
                 '3f=$([section 3])',
                 '3g=$([section 3]  )',

                 '[section 2]',
                ];
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables, $expected, 'variables()');

      subtest 'src_name' => sub {
        my $vars_old = $obj->variables;
        $obj->parse_ini(src => $src, src_name => "Some name");
        is_deeply($vars_old, $expected, 'prev variable hash is not changed');
        my $vars = $obj->variables;
        is($vars->{'section 1'}{'1a'}, "Some name", "1a");
        is($vars->{'section 1'}{'2a'}, "Some name", "2a");
        $vars->{'section 1'}{'1a'} = $vars->{'section 1'}{'2a'} = 'INI data';
        is_deeply($vars, $expected, 'after changing 1a and 2a');
      };

    };
    subtest "separator" => sub {
      my $obj = Config::INI::RefVars->new(separator => '~');
      my $src = [
                 '[section 1]',
                 '1a=$(=srcname)',
                 '1b=$(=srcfile)',
                 '1c=$(=srcdir)',
                 '1d=$(=:)',
                 '1e=$(=)',
                 '1f=$()',
                 '1g=$(  )',

                 '2a=$(section 2~=srcname)',
                 '2b=$(section 2~=srcfile)',
                 '2c=$(section 2~=srcdir)',
                 '2d=$(section 2~=:)',
                 '2e=$(section 2~=)',
                 '2f=$(section 2~x)',
                 '2g=$(section 2~  )',

                 '3a=$(section 3~=srcname)',
                 '3b=$(section 3~=srcfile)',
                 '3c=$(section 3~=srcdir)',
                 '3d=$(section 3~=:)',
                 '3e=$(section 3~=)',
                 '3f=$(section 3~)',
                 '3g=$(section 3~  )',

                 '[section 2]',
                ];
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables, $expected, 'variables()');
    };
};

subtest "from file / with and without cleanup" => sub {
  my $src = test_data_file('mix.ini');
  my ($vol, $dirs, $file) = splitpath(rel2abs($src));
  my ($ini_file, $ini_dir) = ($file, catdir(length($vol // "") ? $vol : (), $dirs));
  my $obj = Config::INI::RefVars->new();

  subtest "default, e.i., no cleanup argument" => sub {
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
               {
                  'section 1' => {
                                  '1a' => $src,
                                  '1b' => $ini_file,
                                  '1c' => $ini_dir,
                                  '1d' => $Path_Sep,
                                  '1e' => 'section 1',
                                  '1f' => '',
                                  '1g' => '  ',
                                  '2a' => $src,
                                  '2b' => $ini_file,
                                  '2c' => $ini_dir,
                                  '2d' => $Path_Sep,
                                  '2e' => 'section 2',
                                  '2f' => '',
                                  '2g' => '  ',
                                  '3a' => '',
                                  '3b' => '',
                                  '3c' => '',
                                  '3d' => '',
                                  '3e' => '',
                                  '3f' => '',
                                  '3g' => ''
                                 },
                  'section 2' => {}
               },
              'variables()');
  };

  subtest "turned off cleanup via cleanup argument" => sub {
    $obj->parse_ini(src => $src, cleanup => 0);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                '='  => '__TOCOPY__',
                                '=:' => $Path_Sep,
                                '=srcdir'  => $ini_dir,
                                '=srcfile' => $ini_file,
                                '=srcname' => $src
                               },
               'section 1' => {
                                  '1a' => $src,
                                  '1b' => $ini_file,
                                  '1c' => $ini_dir,
                                  '1d' => $Path_Sep,
                                  '1e' => 'section 1',
                                  '1f' => '',
                                  '1g' => '  ',
                                  '2a' => $src,
                                  '2b' => $ini_file,
                                  '2c' => $ini_dir,
                                  '2d' => $Path_Sep,
                                  '2e' => 'section 2',
                                  '2f' => '',
                                  '2g' => '  ',
                                  '3a' => '',
                                  '3b' => '',
                                  '3c' => '',
                                  '3d' => '',
                                  '3e' => '',
                                  '3f' => '',
                                  '3g' => '',
                                  '='  => 'section 1',
                                  '=:' => $Path_Sep,
                                  '=srcdir'  => $ini_dir,
                                  '=srcfile' => $ini_file,
                                  '=srcname' => $src

                                 },
                'section 2' => {
                                '='  => 'section 2',
                                '=:' => $Path_Sep,
                                '=srcdir'  => $ini_dir,
                                '=srcfile' => $ini_file,
                                '=srcname' => $src
                               }
               },
              'variables()');

    $obj->parse_ini(src => $src, cleanup => undef);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                '='  => '__TOCOPY__',
                                '=:' => $Path_Sep,
                                '=srcdir'  => $ini_dir,
                                '=srcfile' => $ini_file,
                                '=srcname' => $src
                               },
               'section 1' => {
                                  '1a' => $src,
                                  '1b' => $ini_file,
                                  '1c' => $ini_dir,
                                  '1d' => $Path_Sep,
                                  '1e' => 'section 1',
                                  '1f' => '',
                                  '1g' => '  ',
                                  '2a' => $src,
                                  '2b' => $ini_file,
                                  '2c' => $ini_dir,
                                  '2d' => $Path_Sep,
                                  '2e' => 'section 2',
                                  '2f' => '',
                                  '2g' => '  ',
                                  '3a' => '',
                                  '3b' => '',
                                  '3c' => '',
                                  '3d' => '',
                                  '3e' => '',
                                  '3f' => '',
                                  '3g' => '',
                                  '='  => 'section 1',
                                  '=:' => $Path_Sep,
                                  '=srcdir'  => $ini_dir,
                                  '=srcfile' => $ini_file,
                                  '=srcname' => $src

                                 },
                'section 2' => {
                                '='  => 'section 2',
                                '=:' => $Path_Sep,
                                '=srcdir'  => $ini_dir,
                                '=srcfile' => $ini_file,
                                '=srcname' => $src
                               }
               },
              'variables(): same result for cleanup => undef');
    };
};

#==================================================================================================
done_testing();
