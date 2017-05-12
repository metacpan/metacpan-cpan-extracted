use strict;
use warnings;

use lib "inc";
use My::Builder;

#### Stadard Module::Build stuff
my $build = My::Builder->new(
  module_name          => 'Alien::Box2D',
  all_from             => 'lib/Alien/Box2D.pm',
  dist_author	       => 'FROGGS <froggs@cpan.org>',
  license              => 'perl',
  requires             => {
    'File::Spec'       => '0',
    'File::ShareDir'   => '0',
  },
  build_requires       => {  #need to have for running: ./Build (install|test)
    'File::Spec'       => '0',
    'File::ShareDir'   => '0',
    'File::Path'       => '0',
    'File::Copy'       => '0',
    'File::Fetch'      => '0',
    'File::Find'       => '0',
    'Digest::SHA'      => '0',
    'Archive::Extract' => '0',
    'Archive::Zip'     => '0',
    'Module::Build'    => '0.36',
    'Text::Patch'      => '0',
    'ExtUtils::CppGuess' => '0',
    'ExtUtils::Liblist'  => '0',
  },
  configure_requires   => {  #need to have for running: perl Build.PL
    'File::Spec'       => '0',
    'File::ShareDir'   => '0',
    'File::Path'       => '0',
    'File::Copy'       => '0',
    'File::Fetch'      => '0',
    'File::Find'       => '0',
    'Digest::SHA'      => '0',
    'Archive::Extract' => '0',    
    'Module::Build'    => '0.36',
    'Text::Patch'      => '0',
  },
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Box2D',
      repository => 'http://github.com/PerlGameDev/Alien-Box2D'
    }
  },
  create_readme => 1,
  share_dir => 'sharedir',
  # sharedir is used for storing compiled/prebuilt binaries of Box2D lib
  # avoid using 'share' name as M::B does not handle well paths like /xx/yy/share/zz/ww/share/xx
);
$build->create_build_script();

#### clean build_done stamp; force rebuild when running 'Build'
$build->clean_build_done_marker;

#### check what options we have for our platform
$build->notes('build_params', { dirname => 'Box2D_v2.1.2/Box2D/Box2D',
                                url => 'http://box2d.googlecode.com/files/Box2D_v2.1.2.zip',
                                sha1sum  => 'b1f09f38fc130ae6c17e1767747a3a82bf8e517f',
                                patches => [ 'patches/mingw-minmax.diff' ],
                              } );
