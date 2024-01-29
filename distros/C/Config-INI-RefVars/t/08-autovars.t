use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use Config;
use File::Spec::Functions qw(catdir catfile rel2abs splitpath);

sub test_data_file { catfile(qw(t 08-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

my $Dir_Sep = catdir("", "");
my $VERSION = $Config::INI::RefVars::VERSION;
my %Global = ('=:'        => $Dir_Sep,
              '=::'       => $Config{path_sep},
              '=VERSION'  => $VERSION,
             );

sub exp_sec_1 {
  my ($src, $ini_file, $ini_dir) = @_;
  return {
          '1a' => $src,
          '1b' => $ini_file,
          '1c' => $ini_dir,
          '1d' => $Dir_Sep,
          '1e' => 'section 1',
          '1f' => '',
          '1g' => '  ',
          '1h' => $Config{path_sep},
          '1i' => $VERSION,
          '2a' => $src,
          '2b' => $ini_file,
          '2c' => $ini_dir,
          '2d' => $Dir_Sep,
          '2e' => 'section 2',
          '2f' => '',
          '2g' => '  ',
          '2h' => $Config{path_sep},
          '2i' => $VERSION,
          '3a' => '',
          '3b' => '',
          '3c' => '',
          '3d' => '',
          '3e' => '',
          '3f' => '',
          '3g' => '',
          '3h' => '',
          '3i' => '',
         };
}

subtest "not from file" => sub {
  my $expected = {
                  'section 1' => exp_sec_1('INI data', '', ''),
                  'section 2' => {}
                 };
    subtest "default section ref" => sub {
      my $obj = Config::INI::RefVars->new();
      my $src = [
                 '[section 1]',
                 '1a=$(=srcname)',
                 '1b=$(=INIfile)',
                 '1c=$(=INIdir)',
                 '1d=$(=:)',
                 '1e=$(=)',
                 '1f=$()',
                 '1g=$(  )',
                 '1h=$(=::)',
                 '1i=$(=VERSION)',

                 '2a=$([section 2]=srcname)',
                 '2b=$([section 2]=INIfile)',
                 '2c=$([section 2]=INIdir)',
                 '2d=$([section 2]=:)',
                 '2e=$([section 2]=)',
                 '2f=$([section 2]x)',
                 '2g=$([section 2]  )',
                 '2h=$([section 2]=::)',
                 '2i=$([section 2]=VERSION)',

                 '3a=$([section 3]=srcname)',
                 '3b=$([section 3]=INIfile)',
                 '3c=$([section 3]=INIdir)',
                 '3d=$([section 3]=:)',
                 '3e=$([section 3]=)',
                 '3f=$([section 3])',
                 '3g=$([section 3]  )',
                 '3h=$([section 3]=::)',
                 '3i=$([section 3]=VERSION)',

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

      #
      # Keep this in sync with file mix.ini!!!
      #
      my $src = [
                 '[section 1]',
                 '1a=$(=srcname)',
                 '1b=$(=INIfile)',
                 '1c=$(=INIdir)',
                 '1d=$(=:)',
                 '1e=$(=)',
                 '1f=$()',
                 '1g=$(  )',
                 '1h=$(=::)',
                 '1i=$(=VERSION)',

                 '2a=$(section 2~=srcname)',
                 '2b=$(section 2~=INIfile)',
                 '2c=$(section 2~=INIdir)',
                 '2d=$(section 2~=:)',
                 '2e=$(section 2~=)',
                 '2f=$(section 2~x)',
                 '2g=$(section 2~  )',
                 '2h=$(section 2~=::)',
                 '2i=$(section 2~=VERSION)',

                 '3a=$(section 3~=srcname)',
                 '3b=$(section 3~=INIfile)',
                 '3c=$(section 3~=INIdir)',
                 '3d=$(section 3~=:)',
                 '3e=$(section 3~=)',
                 '3f=$(section 3~)',
                 '3g=$(section 3~  )',
                 '3h=$(section 3~=::)',
                 '3i=$(section 3~=VERSION)',

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
               'section 1' => exp_sec_1($src, $ini_file, $ini_dir),
               'section 2' => {}
              },
              'variables()');
  };

  subtest "turned off cleanup via cleanup argument" => sub {
    $obj->parse_ini(src => $src, cleanup => 0);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                '='   => '__TOCOPY__',
                                %Global,
                                '=INIdir'  => $ini_dir,
                                '=INIfile' => $ini_file,
                                '=srcname' => $src
                               },
               'section 1' => {
                               '='   => 'section 1',
                               %{exp_sec_1($src, $ini_file, $ini_dir)},
                               %Global,
                               '=INIdir'  => $ini_dir,
                               '=INIfile' => $ini_file,
                               '=srcname' => $src
                              },
               'section 2' => {
                               '='   => 'section 2',
                               %Global,
                               '=INIdir'  => $ini_dir,
                               '=INIfile' => $ini_file,
                               '=srcname' => $src
                              }
              },
              'variables()');

    $obj->parse_ini(src => $src, cleanup => undef);
    is_deeply($obj->variables,
              {
               '__TOCOPY__' => {
                                '='   => '__TOCOPY__',
                                %Global,
                                '=INIdir'  => $ini_dir,
                                '=INIfile' => $ini_file,
                                '=srcname' => $src
                               },
               'section 1' => {
                               '='   => 'section 1',
                               %{exp_sec_1($src, $ini_file, $ini_dir)},
                               %Global,
                               '=INIdir'  => $ini_dir,
                               '=INIfile' => $ini_file,
                               '=srcname' => $src
                              },
               'section 2' => {
                               '='   => 'section 2',
                               %Global,
                               '=INIdir'  => $ini_dir,
                               '=INIfile' => $ini_file,
                               '=srcname' => $src
                              }
              },
              'variables(): same result for cleanup => undef');
  };
};

#==================================================================================================
done_testing();
