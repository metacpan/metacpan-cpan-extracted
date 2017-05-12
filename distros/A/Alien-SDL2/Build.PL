use strict;
use warnings;

use lib "inc";
use File::Spec::Functions qw(catdir catfile);
use Config;
use My::Utility qw(check_config_script check_prebuilt_binaries check_prereqs_libs check_prereqs_tools $source_packs);

use Getopt::Long;
my ($ans, $travis)   = '';
GetOptions (  "travis"  => \$travis)  ;

print "Welcome to Alien::SDL2 module installation\n";
print "------------------------------------------\n";
print "checking operating system... $^O\n";
$| = 1;
print "checking for $My::Utility::cc... ";
if( !check_prereqs_tools($My::Utility::cc) ) {
  print "no\n";
  for(qw(gcc cc lc)) {
    next if $_ eq \$My::Utility::cc;
    print "checking for $_... ";
    if( check_prereqs_tools($_) ) {
      $My::Utility::cc = $_;
      print "yes\n";
      last;
    }
    else {
      print "no\n";
    }
  }
}
else {
  print "yes\n";
}
print "checking build system type... $Config{archname}\n";

#### we need the platform-specific module
my %platforms =(
       # Unix = default, thus not listing all UNIX like systems
       MSWin32 => 'Windows',
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print "checking platform specific module... using '$package'\n";
eval "require $package" or die "Require '$package' failed: $@\n";

my $sdl2_config;

#### Stadard Module::Builder stuff
my $build = $package->new(
  module_name          => 'Alien::SDL2',
  all_from             => 'lib/Alien/SDL2.pm',
  dist_abstract        => 'Get, Build and Use SDL2 libraries',
  dist_author          => 'Kartik Thakore <KTHAKORE@cpan.org>',
  license              => 'perl',
  requires             => {
    'File::Spec'       => '0',
    'File::Temp'       => '0.23',
    'File::ShareDir'   => '0',
    'File::Which'      => '0',
    'ExtUtils::CBuilder' => '0',
    'Capture::Tiny'    => '0',
    'perl'             => '5.008000',
  },
  build_requires       => {  #need to have for running: ./Build (install|test)
    'File::Spec'       => '0',
    'File::Temp'       => '0.23',
    'File::ShareDir'   => '0',
    'ExtUtils::CBuilder' => '0',
    'File::Path'       => '2.08',
    'File::Fetch'      => '0.24',
    'File::Find'       => '0',
    'File::Which'      => '0',
    'Digest::SHA'      => '0',
    'Archive::Extract' => '0',
    'Archive::Tar'     => '0',
    'Archive::Zip'     => '0',
    'Module::Build'    => '0.36',
    'Text::Patch'      => '1.4',
  },
  configure_requires   => {  #need to have for running: perl Build.PL
    'File::Spec'       => '0',
    'File::Path'       => '2.08',
    'File::Fetch'      => '0.24',
    'File::Find'       => '0',
    'File::Which'      => '0',
    'Digest::SHA'      => '0',
    'Archive::Extract' => '0',
    'Module::Build'    => '0.36',
    'Text::Patch'      => '1.4',
    'File::ShareDir'   => '0',
    'IPC::Run3'        => '0',
  },
  meta_merge => {
    resources  => {
      bugtracker => 'http://github.com/PerlGameDev/SDL2/issues?labels=Alien-SDL2',
      repository => 'http://github.com/PerlGameDev/Alien-SDL2'
    }
  },
  get_options => { 'with-sdl2-config' => { qw(type :s  store) => \$sdl2_config } },
  dynamic_config => 1,
  create_readme => 1,
  share_dir => 'sharedir',
);

my $choice;
my %have_libs = ();

if (defined $sdl2_config) {
  # handle --with-sdl2-config (without params)
  $sdl2_config = 'sdl2-config' if $sdl2_config eq '';
  # Don't prompt; just use specified location:
  $choice = check_config_script($sdl2_config)
      or warn "###ERROR### Unable to use config script $sdl2_config\n";
}
else {
  $| = 1;

  if( $My::Utility::cc eq 'cl' && $^O eq 'MSWin32' ) {
    print "checking INCLUDE and LIB... ";
    if( !$ENV{INCLUDE} || !$ENV{LIB} ) {
      my @set = `\@vcvars32 & set`;
      chomp @set;
      my %set  = map /(\w+)=(.+)/, @set;
      for( keys %set ) {
        if( /^INCLUDE|LIB$/ ) {
          $ENV{$_} = $set{$_};
        }
      }
      print(($ENV{INCLUDE} && $ENV{LIB})
        ? "yes, via vcvars32\n"
        : "no\n");
    }
    else {
      print "yes\n";
    }
  }
  #### check what options we have for our platform
  my $rv;
  my @candidates = ();

  # sdl2-config script
  push @candidates, $rv if $rv = check_config_script("sdl2-config");

  if( $build->can_build_binaries_from_sources || scalar(@candidates) ) {
    for(qw(pthread SDL2
           z jpeg tiff png SDL2_image
           ogg vorbis vorbisfile SDL2_mixer
           freetype SDL2_ttf
           SDL2_gfx)) {
      $have_libs{$_} = check_prereqs_libs($_);
    }
  }

  # prebuilt binaries (windows only)
  push @candidates, @{$rv} if $rv = check_prebuilt_binaries($build->os_type);

  if($build->can_build_binaries_from_sources) {
    for my $p ( @$source_packs ) {
      $rv = { title => $p->{title}, members => [], buildtype => 'build_from_sources' };
      for my $m (@{ $p->{members} }) {
        next if $m->{pack} !~ /^SDL2/ && $have_libs{ $m->{pack} }[0];
        my $good = 1;
        $good   &= $have_libs{$_} && $have_libs{$_}[0] ? 1 : 0 for @{ $m->{prereq_libs} };
        if( $good ) {
          $have_libs{ $m->{pack} }[0] ||= 1;
          push @{ $rv->{members} }, $m;
          $rv->{title} .= "$m->{pack}(v$m->{version}) ";
        }
      }
      push @candidates, $rv if scalar( @{ $rv->{members} } );
    }
  };

  push @candidates, { title => 'Quit installation', buildtype => '' };

  #### ask user what way to go
  my $i                     = 1;
  my $prompt_string         = "\nYou have the following options:\n";
  my $recommended_candidate = 1;
  foreach my $c (@candidates) {
    $recommended_candidate = $i if $c->{buildtype} eq 'build_from_sources';

    if( $c->{buildtype} eq 'use_config_script' ) {
      $c->{title} .= "\n    ";
      for(qw(SDL2 SDL2_image SDL2_mixer SDL2_ttf SDL2_gfx)) {
        $c->{title} .= "$_(v$have_libs{$_}->[0]) " if $have_libs{$_}[0];
      }
    }

    $prompt_string .= "[" . $i++ . "] " . $c->{title} . "\n";
  }

  # select option '1' for travis
  if ($travis == 1) {
      $ans = 1;
      #set 'travis' var for inc/My/Builder.pm
      $build->notes( 'travis', '1' );
  }

  # or prompt user for build option
  else {
      $prompt_string .= "\nWhat way do you wanna go?";
      $ans = $build->prompt( $prompt_string, $recommended_candidate );
  }

  if($ans > 0 && $ans < scalar(@candidates)) {
      $choice = $candidates[$ans - 1];
  }

  $| = 0;
} # end else search and prompt for build method

#### store build params into 'notes'
if($choice) {
  print "Using \l$choice->{title}\n";
  $build->notes('build_params', $choice);
  $build->notes('env_include', $ENV{INCLUDE}) if $ENV{INCLUDE};
  $build->notes('env_lib',     $ENV{LIB})     if $ENV{LIB};
  $build->notes('have_libs',   \%have_libs);
  $build->create_build_script();

  #### clean build_done stamp; force rebuild when running 'Build'
  $build->clean_build_done_marker;
}
else {
  $build->notes('build_params', undef); # just to be sure
  exit(0); # we want no reports from CPAN Testers in this case
}
