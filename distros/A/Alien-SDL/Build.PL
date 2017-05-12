use strict;
use warnings;

use lib "inc";
use File::Spec::Functions qw(catdir catfile);
use Config;
use My::Utility qw(check_config_script check_prebuilt_binaries check_prereqs_libs check_prereqs_tools $source_packs
                   check_perl_buildlibs);

use Getopt::Long;
my ( $ans, $travis ) = 0;
GetOptions( "travis" => \$travis );

print "Welcome to Alien::SDL module installation\n";
print "-----------------------------------------\n";
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

my $sdl_config;

#### Stadard Module::Builder stuff
my $build = $package->new(
  module_name          => 'Alien::SDL',
  all_from             => 'lib/Alien/SDL.pm',
  dist_abstract        => 'Get, Build and Use SDL libraries',
  dist_author          => 'Kartik Thakore <KTHAKORE@cpan.org>',
  license              => 'perl',
  requires             => {
    'File::Spec'       => '0',
    'File::Temp'       => '0',
    'File::ShareDir'   => '0',
    'File::Which'      => '0',
    'ExtUtils::CBuilder' => '0',
    'Capture::Tiny'    => '0',
    'perl'             => '5.008000',
  },
  build_requires       => {  #need to have for running: ./Build (install|test)
    'File::Spec'       => '0',
    'File::Temp'       => '0',
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
    'Capture::Tiny'    => '0',
  },
  meta_merge => {
    resources  => {
      bugtracker => 'http://github.com/PerlGameDev/SDL/issues?labels=Alien-SDL',
      repository => 'http://github.com/PerlGameDev/Alien-SDL'
    }
  },
  get_options => { 'with-sdl-config' => { qw(type :s  store) => \$sdl_config } },
  dynamic_config => 1,
  create_readme => 1,
  share_dir => 'sharedir',
  # sharedir is used for storing compiled/prebuilt binaries of SDL lib + related libraries
  # avoid using 'share' name as M::B doe not handle well paths like /xx/yy/share/zz/ww/share/xx
);

my $choice;
my %have_libs = ();
my %perl_libs = ();

if (defined $sdl_config) {
  # handle --with-sdl-config (without params)
  $sdl_config = 'sdl-config' if $sdl_config eq '';
  # Don't prompt; just use specified location:
  $choice = check_config_script($sdl_config)
      or warn "###ERROR### Unable to use config script $sdl_config\n";
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

  print "checking SDL_INST_DIR env var... ";
  if(defined($ENV{SDL_INST_DIR})) {
    if (-d $ENV{SDL_INST_DIR}) {
      print "yes, $ENV{SDL_INST_DIR}\n";
      my @sdlinst = File::Spec->splitdir($ENV{SDL_INST_DIR});
      if($rv = check_config_script(File::Spec->catdir(@sdlinst, 'bin', 'sdl-config'))) {
        push @candidates, $rv;
      }
      elsif($rv = check_config_script(File::Spec->catdir(@sdlinst, 'sdl-config'))) {
        push @candidates, $rv;
      }
    }
    else {
      print "directory '$ENV{SDL_INST_DIR}' does not exist";
    }
  }
  print "no\n";

  # sdl-config script
  push @candidates, $rv if $rv = check_config_script("sdl-config");

  if( $build->can_build_binaries_from_sources || scalar(@candidates) ) {
    for(qw(pthread SDL
           z jpeg tiff png SDL_image
           ogg vorbis vorbisfile SDL_mixer
           freetype SDL_ttf
           SDL_gfx
           pangoft2 pango gobject gmodule glib fontconfig expat SDL_Pango)) {
      $have_libs{$_} = check_prereqs_libs($_);
    }
  }

  $perl_libs{pthread} = check_perl_buildlibs('pthread') if $have_libs{pthread} && $^O eq 'openbsd';

  # prebuilt binaries (windows only)
  push @candidates, @{$rv} if $rv = check_prebuilt_binaries($build->os_type);

  if($build->can_build_binaries_from_sources) {
    for my $p ( @$source_packs ) {
      $rv = { title => $p->{title}, members => [], buildtype => 'build_from_sources' };
      for my $m (@{ $p->{members} }) {
        next if $m->{pack} !~ /^SDL/ && $have_libs{ $m->{pack} }[0];
        my $good = 1;
        $good   &= $have_libs{$_} && $have_libs{$_}[0] ? 1 : 0 for @{ $m->{prereqs}->{libs} };
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
      for(qw(SDL SDL_image SDL_mixer SDL_ttf SDL_gfx SDL_Pango)) {
        $c->{title} .= "$_(v$have_libs{$_}->[0]) " if $have_libs{$_}[0];
      }
    }

    $prompt_string .= "[" . $i++ . "] " . $c->{title} . "\n";
  }

  # select option '1' for travis
  if ( defined $travis and $travis == 1 ) {
    $ans = 1;
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
  $build->notes('perl_libs',   \%perl_libs);
  $build->create_build_script();

  #### clean build_done stamp; force rebuild when running 'Build'
  $build->clean_build_done_marker;
}
else {
  $build->notes('build_params', undef); # just to be sure
  exit(0); # we want no reports from CPAN Testers in this case
}
