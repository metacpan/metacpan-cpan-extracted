use strict;
use warnings;

use lib 'inc';

my %platforms =(
  # Unix = default, thus not listing all UNIX like systems
  MSWin32 => 'Windows',
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print STDERR "Gonna use '$package' class ...\n";
eval "require $package" or die "Require '$package' failed: $@\n";

my $builder = $package->new(
  module_name        => 'Alien::Tidyp',
  dist_version_from  => 'lib/Alien/Tidyp.pm',
  dist_author        => 'KMX, kmx@cpan.org',
  license            => 'perl',
  requires => {
    'perl'              => '5.008',
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
  },
  configure_requires => {
    'perl'              => '5.008',
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
  },
  build_requires => {
    'perl'              => '5.008',
    'Test::More'        => 0,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Copy'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'Alien-Tidyp-*', 'build_done' ],
  create_readme      => 1,
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Tidyp',
      repository => 'http://github.com/kmx/alien-tidyp',
    }
  },
  get_options => { srctarball =>  { type  => '=s' } },  # option: Build.PL --srctarball=<url_or_filename>
);

$builder->create_build_script();

if ($builder->check_installed_tidyp()) {
  my $ans = $builder->prompt("Tidyp detected, wanna use tidyp already installed on your system?", 'y');
  $builder->notes('installed_tidyp', undef) unless (lc($ans) eq 'y');
}

# delete build marker (= force rebuild after running Build.PL)
unlink 'build_done';

# set what tidyp tarball we are gonna use
$builder->notes('tidyp_url', [ 
    'http://github.com/downloads/petdance/tidyp/tidyp-1.04.tar.gz',    
    'https://github.com/downloads/petdance/tidyp/tidyp-1.04.tar.gz',
    'http://strawberryperl.com/package/kmx/testing/tidyp-1.04.tar.gz',
  ]); # has to be an array
$builder->notes('tidyp_dir', 'tidyp-1.04'); # dirname inside the tarball
$builder->notes('tidyp_sha1', '5d9050512259c3a67a2f48469555932e3a7b8bd0'); # SHA1 checksum of the tarball
