use strict;
use warnings;

use lib "inc";

#### we need the platform-specific module
my %platforms =(
    # Unix = default, thus not listing all UNIX like systems
    MSWin32 => 'Windows',
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print "Gonna use '$package' class ...\n";
eval "require $package" or die "Require '$package' failed: $@\n";

my $builder = $package->new(
  module_name        => 'Alien::AntTweakBar',
  dist_version_from  => 'lib/Alien/AntTweakBar.pm',
  dist_author        => 'DMOL, dmol@cpan.org',
  license            => 'perl',
  configure_requires => {
    'perl'               => '5.008',
    'Archive::Extract'   => 0,
    'Devel::CheckLib'    => '1.01',
    'Digest::SHA'        => 0,
    'File::chdir'        => 0.1008,
    'File::Basename'     => 0,
    'File::Copy'         => 0,
    'File::Fetch'        => 0,
    'File::Path'         => 0,
    'File::ShareDir'     => 0,
    'ExtUtils::Command'  => 0,
    'ExtUtils::CBuilder' => 0,
    'ExtUtils::Liblist'  => 0,
    'Module::Build'      => 0,
	'Text::Patch'        => 0,
  },
  requires => {
      'perl'             => 5.008,
      'Carp'             => 0,
      'File::ShareDir'   => 0,
      'File::Spec'       => 0,
      'Text::ParseWords' => 0,
  },
  test_requires => {
      'Test::More' => 0,
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'Alien-AntTweakBar-*', 'build_done' ],
  meta_merge => {
    resources  => {
      bugtracker => 'https://github.com/PerlGameDev/Alien-AntTweakBar/issues',
      repository => 'https://github.com/PerlGameDev/Alien-AntTweakBar',
    }
  },
  # option: Build.PL --srctarball=<url_or_filename>
  get_options => { srctarball =>  { type  => '=s' } },

);

$builder->create_build_script;
unlink 'build_done';

$builder->notes(src_url =>
    'http://downloads.sourceforge.net/project/anttweakbar/AntTweakBar_116.zip'
);
$builder->notes('sha1', '5743321df3b074f9a82b5ef3e6b54830a715b938');
