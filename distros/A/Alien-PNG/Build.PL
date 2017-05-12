use strict;
use warnings;

use lib "inc";
use File::Spec::Functions qw(catdir catfile);
use My::Utility qw(check_config_script check_prebuilt_binaries check_src_build);

#### we need the platform-specific module
my %platforms =(
       # Unix = default, thus not listing all UNIX like systems
       MSWin32 => 'Windows',       
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print "Gonna use '$package' class ...\n";
eval "require $package" or die "Require '$package' failed: $@\n";

#### Stadard Module::Builder stuff
my $build = $package->new(
  module_name          => 'Alien::PNG',
  all_from             => 'lib/Alien/PNG.pm',
  dist_abstract        => 'Get, Build and Use PNG libraries',
  dist_author	       => 'Tobias Leich <FROGGS@cpan.org>',
  license              => 'perl',
  requires             => {
    'File::Spec'       => '0',
    'File::Temp'       => '0',
    'File::ShareDir'   => '0',
    'ExtUtils::CBuilder' => '0',
  },
  build_requires       => {  #need to have for running: ./Build (install|test)
    'File::Spec'       => '0',
    'File::Temp'       => '0',
    'File::ShareDir'   => '0',
    'ExtUtils::CBuilder' => '0',
    'File::Path'       => '2.07',
    'File::Fetch'      => '0',
    'File::Find'       => '0',
    'Digest::SHA'      => '0',
    'Archive::Extract' => '0',
    'Archive::Tar'     => '0',
    'Archive::Zip'     => '0',
    'Module::Build'    => '0.36',
  },
  configure_requires   => {  #need to have for running: perl Buil.PL
    'File::Spec'       => '0',
    'File::Path'       => '2.07',
    'File::Fetch'      => '0',
    'File::Find'       => '0',
    'Digest::SHA'      => '0',
    'Archive::Extract' => '0',
    'Module::Build'    => '0.36',
  },
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-PNG',
      repository => 'http://github.com/FROGGS/Alien_PNG'
    }
  },
  create_readme => 1,
  share_dir => 'sharedir',
  # sharedir is used for storing compiled/prebuilt binaries of PNG lib + related libraries
  # avoid using 'share' name as M::B doe not handle well paths like /xx/yy/share/zz/ww/share/xx
);
$build->create_build_script();

#### clean build_done stamp; force rebuild when running 'Build'
$build->clean_build_done_marker;

print "\nWelcome to Alien::PNG module installation";
print "\n-----------------------------------------\n\n";

#### check what options we have for our platform
my $rv; my @candidates = ();

if(defined($ENV{PNG_INST_DIR})) {
  print "Gonna use PNG_INST_DIR environment variable...\n";
  print "(PNG_INST_DIR=$ENV{PNG_INST_DIR})\n";
  if (-d $ENV{PNG_INST_DIR}) {
    my @pnginst = File::Spec->splitdir($ENV{PNG_INST_DIR});
    if($rv=check_config_script(File::Spec->catdir(@pnginst, 'bin', 'libpng-config'))) {
      push @candidates, $rv;
    }
    elsif($rv=check_config_script(File::Spec->catdir(@pnginst, 'libpng-config'))) {
      push @candidates, $rv;
    }
  }
  else {
    warn "###WARN### Non-existing directory '$ENV{PNG_INST_DIR}' - skipping";
  }
}

if($rv=check_config_script("libpng-config")) {
  push @candidates, $rv;
};

if($rv=check_prebuilt_binaries($build->os_type)) {
  push @candidates, @{$rv};
};

if(($rv=check_src_build($build->os_type)) && $build->can_build_binaries_from_sources()) {
  push @candidates, @{$rv};
};

push @candidates, { title => 'Quit installation' };

#### ask user what way to go
my $i = 1;
my $prompt_string = "\nYou have the following options:\n";
foreach my $c (@candidates) {
  $prompt_string .= "[" . $i++ . "] " . $c->{title} . "\n"
}
$prompt_string .= "\nWhat way do you wanna go?";
my $ans = $build->prompt($prompt_string, 1);

#### store build params into 'notes'
if(($ans>0) && ($ans<scalar(@candidates))) {
  $build->notes('build_params', $candidates[$ans-1]);
}
else {
  $build->notes('build_params', undef); # just to be sure
}
