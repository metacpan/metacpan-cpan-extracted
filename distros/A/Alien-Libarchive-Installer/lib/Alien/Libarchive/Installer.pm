package Alien::Libarchive::Installer;

use strict;
use warnings;
use File::ShareDir qw( dist_dir );

# ABSTRACT: Installer for libarchive
our $VERSION = '0.15'; # VERSION


sub versions_available
{
  require HTTP::Tiny;
  my $url = "http://www.libarchive.org/downloads/";
  my $response = HTTP::Tiny->new->get($url);
  
  die sprintf("%s %s %s", $response->{status}, $response->{reason}, $url)
    unless $response->{success};

  my @versions;
  push @versions, [$1,$2,$3] while $response->{content} =~ /libarchive-([1-9][0-9]*)\.([0-9]+)\.([0-9]+)\.tar.gz/g;
  @versions = map { join '.', @$_ } sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] } @versions;
}


sub fetch
{
  my($class, %options) = @_;
  
  my $dir = $options{dir} || eval { require File::Temp; File::Temp::tempdir( CLEANUP => 1 ) };

  require HTTP::Tiny;  
  my $version = $options{version} || do {
    my @versions = $class->versions_available;
    die "unable to determine latest version from listing"
      unless @versions > 0;
    $versions[-1];
  };

  if(defined $ENV{ALIEN_LIBARCHIVE_INSTALL_MIRROR})
  {
    my $fn = File::Spec->catfile($ENV{ALIEN_LIBARCHIVE_INSTALL_MIRROR}, "libarchive-$version.tar.gz");
    return wantarray ? ($fn, $version) : $fn;
  }

  my $url = "http://www.libarchive.org/downloads/libarchive-$version.tar.gz";
  
  my $response = HTTP::Tiny->new->get($url);
  
  die sprintf("%s %s %s", $response->{status}, $response->{reason}, $url)
    unless $response->{success};
  
  require File::Spec;
  
  my $fn = File::Spec->catfile($dir, "libarchive-$version.tar.gz");
  
  open my $fh, '>', $fn;
  binmode $fh;
  print $fh $response->{content};
  close $fh;
  
  wantarray ? ($fn, $version) : $fn;
}


sub build_requires
{
  my %prereqs = (
    'HTTP::Tiny'   => 0,
    'Archive::Tar' => 0,
    'Alien::patch' => '0.08',
  );
  
  if($^O eq 'MSWin32')
  {
    require Config;
    if($Config::Config{cc} =~ /cl(\.exe)?$/i)
    {
      $prereqs{'Alien::CMake'} = '0.05';
    }
    else
    {
      $prereqs{'Alien::MSYS'} = '0.07';
      $prereqs{'PkgConfig'}   = '0.07620';
    }
  }
  
  \%prereqs;
}


sub system_requires
{
  my %prereqs = ();
  \%prereqs;
}


sub system_install
{
  my($class, %options) = @_;

  $options{alien} = 1 unless defined $options{alien};
  $options{test} ||= 'compile';
  die "test must be one of compile, ffi or both"
    unless $options{test} =~ /^(compile|ffi|both)$/;

  if($options{alien} && eval q{ use Alien::Libarchive 0.21; 1 })
  {
    my $alien = Alien::Libarchive->new;
    
    require File::Spec;
    my $dir;
    my(@dlls) = map { 
      my($v,$d,$f) = File::Spec->splitpath($_); 
      $dir = [$v,File::Spec->splitdir($d)]; 
      $f;
    } $alien->dlls;
    
    my $build = bless {
      cflags  => [$alien->cflags],
      libs    => [$alien->libs],
      dll_dir => $dir,
      dlls    => \@dlls,
      prefix  => File::Spec->rootdir,
    }, $class;
    eval {
      $build->test_compile_run || die $build->error if $options{test} =~ /^(compile|both)$/;
      $build->test_ffi || die $build->error if $options{test} =~ /^(ffi|both)$/;
    };
    return $build unless $@;
  }

  my $build = bless {
    cflags => _try_pkg_config(undef, 'cflags', '', ''),
    libs   => _try_pkg_config(undef, 'libs',   '-larchive', ''),
  }, $class;
  
  if($options{test} =~ /^(ffi|both)$/)
  {
    my @dir_search_list;
    
    if($^O eq 'MSWin32')
    {
      # On MSWin32 the entire path is not included in dl_library_path
      # but that is the most likely place that we will find dlls.
      @dir_search_list = grep { -d $_ } split /;/, $ENV{PATH};
    }
    else
    {
      require DynaLoader;
      @dir_search_list = grep { -d $_ } @DynaLoader::dl_library_path
    }
    
    found_dll: foreach my $dir (@dir_search_list)
    {
      my $dh;
      opendir($dh, $dir) || next;
      # sort by filename length so that libarchive.so.12.0.4
      # is preferred over libarchive.so.12 or libarchive.so
      # if only to make diagnostics point to the more specific
      # version.
      foreach my $file (sort { length $b <=> length $a } readdir $dh)
      {
        if($^O eq 'MSWin32')
        {
          next unless $file =~ /^libarchive-[0-9]+\.dll$/i;
        }
        elsif($^O eq 'cygwin')
        {
          next unless $file =~ /^cygarchive-[0-9]+\.dll$/i;
        }
        else
        {
          next unless $file =~ /^libarchive\.(dylib|so(\.[0-9]+)*)$/;
        }
        require File::Spec;
        my($v,$d) = File::Spec->splitpath($dir, 1);
        $build->{dll_dir} = [File::Spec->splitdir($d)];
        $build->{prefix}  = $v;
        $build->{dlls}    = [$file];
        closedir $dh;
        last found_dll;
      }
      closedir $dh;
    }
  }

  $build->test_compile_run || die $build->error if $options{test} =~ /^(compile|both)$/;
  $build->test_ffi || die $build->error if $options{test} =~ /^(ffi|both)$/;
  $build;
}


sub _try_pkg_config
{
  my($dir, $field, $guess, $extra) = @_;
  
  unless(defined $dir)
  {
    require File::Temp;
    $dir = File::Temp::tempdir(CLEANUP => 1);
  }
  
  require Config;
  local $ENV{PKG_CONFIG_PATH} = join $Config::Config{path_sep}, $dir, split /$Config::Config{path_sep}/, ($ENV{PKG_CONFIG_PATH}||'');

  my $value = eval {
    # you probably think I am crazy...
    eval q{ use PkgConfig 0.07620 };
    die $@ if $@;
    my $value = `$^X $INC{'PkgConfig.pm'} --silence-errors libarchive $extra --$field`;
    die if $?;
    $value;
  };

  unless(defined $value) {
    no warnings;
    $value = `pkg-config --silence-errors libarchive $extra --$field`;
    return $guess if $?;
  }
  
  chomp $value;
  require Text::ParseWords;
  [Text::ParseWords::shellwords($value)];
}

sub _msys
{
  my($sub) = @_;
  require Config;
  if($^O eq 'MSWin32')
  {
    if($Config::Config{cc} !~ /cl(\.exe)?$/i)
    {
      require Alien::MSYS;
      return Alien::MSYS::msys(sub{ $sub->('make') });
    }
  }
  $sub->($Config::Config{make});
}

sub build_install
{
  my($class, $prefix, %options) = @_;
  
  $options{test} ||= 'compile';
  die "test must be one of compile, ffi or both"
    unless $options{test} =~ /^(compile|ffi|both)$/;
  die "need an install prefix" unless $prefix;
  
  $prefix =~ s{\\}{/}g;
  
  my $dir = $options{dir} || do { require File::Temp; File::Temp::tempdir( CLEANUP => 1 ) };
  
  require Archive::Tar;
  my $tar = Archive::Tar->new;
  $tar->read($options{tar} || $class->fetch);
  
  require Cwd;
  my $save = Cwd::getcwd();
  
  chdir $dir;  
  my $build = eval {
  
    $tar->extract;

    chdir do {
      opendir my $dh, '.';
      my(@list) = grep !/^\./,readdir $dh;
      close $dh;
      die "unable to find source in build root" if @list == 0;
      die "confused by multiple entries in the build root" if @list > 1;
      $list[0];
    };
    
    do {
      $DB::single = 1;
      my $share_dir = dist_dir('Alien-Libarchive-Installer');
      my($version) = [File::Spec->splitpath(Cwd::getcwd())]->[2] =~ /libarchive-([0-9\.]+)/;
      if($version)
      {
        my $patch = File::Spec->catdir($share_dir, 'patches', "$version.patch");
        if(-r $patch)
        {
          require Alien::patch;
          Alien::patch->import(); # add patch to the path if not already there.
          my $patch_exe = Alien::patch->exe;
          system "$patch_exe -p1 < $patch";
          die "patch failed" if $?;
        }
      }
      else
      {
        warn "unable to determine version number.";
      }
    };
  
    _msys(sub {
      my($make) = @_;
      require Config;
      if($Config::Config{cc} !~ /cl(\.exe)?$/i)
      {
        system 'sh', 'configure', "--prefix=$prefix", '--with-pic';
        die "configure failed" if $?;
      }
      else
      {
        require Alien::CMake;
        my $cmake = Alien::CMake->config('prefix') . '/bin/cmake.exe';
        my $system = $make =~ /nmake(\.exe)?$/ ? 'NMake Makefiles' : 'MinGW Makefiles';
        system $cmake,
          -G => $system,
          "-DCMAKE_MAKE_PROGRAM:PATH=$make",
          "-DCMAKE_INSTALL_PREFIX:PATH=$prefix",
          "-DENABLE_TEST=OFF",
          ".";
        die "cmake failed" if $?;
      }
      system $make, 'all';
      die "make all failed" if $?;
      system $make, 'install';
      die "make install failed" if $?;
    });

    require File::Spec;

    foreach my $name ($^O =~ /^(MSWin32|cygwin)$/ ? ('bin','lib') : ('lib'))
    {
      do {
        my $static_dir = File::Spec->catdir($prefix, $name);
        my $dll_dir    = File::Spec->catdir($prefix, 'dll');
        require File::Path;
        File::Path::mkpath($dll_dir, 0, 0755);
        my $dh;
        opendir $dh, $static_dir;
        my @list = readdir $dh;
        @list = grep { /\.so/ || /\.(dylib|la|dll|dll\.a)$/ } grep !/^\./, @list;
        closedir $dh;
        foreach my $basename (@list)
        {
          my $from = File::Spec->catfile($static_dir, $basename);
          my $to   = File::Spec->catfile($dll_dir,    $basename);
          if(-l $from)
          {
            symlink(readlink $from, $to);
            unlink($from);
          }
          else
          {
            require File::Copy;
            File::Copy::move($from, $to);
          }
        }
      };
    }

    my $pkg_config_dir = File::Spec->catdir($prefix, 'lib', 'pkgconfig');
    
    my $pcfile = File::Spec->catfile($pkg_config_dir, 'libarchive.pc');
    
    do {
      my @content;
      if($Config::Config{cc} !~ /cl(\.exe)?$/i)
      {
        open my $fh, '<', $pcfile;
        @content = map { s{$prefix}{'${pcfiledir}/../..'}eg; $_ } do { <$fh> };
        close $fh;
      }
      else
      {
        # TODO: later when we know the version with more
        # certainty, we can update this file with the
        # Version
        @content = join "\n", "prefix=\${pcfiledir}/../..",
                              "exec_prefix=\${prefix}",
                              "libdir=\${exec_prefix}/lib",
                              "includedir=\${prefix}/include",
                              "Name: libarchive",
                              "Description: library that can create and read several streaming archive formats",
                              "Cflags: -I\${includedir}",
                              "Libs: advapi32.lib \${libdir}/archive_static.lib",
                              "Libs.private: ",
                              "";
        require File::Path;
        File::Path::mkpath($pkg_config_dir, 0, 0755);
      }
      
      my($version) = map { /^Version:\s*(.*)$/; $1 } grep /^Version: /, @content;
      # older versions apparently didn't include the necessary -I and -L flags
      if(defined $version && $version =~ /^[12]\./)
      {
        for(@content)
        {
          s/^Libs: /Libs: -L\${libdir} /;
        }
        push @content, "Cflags: -I\${includedir}\n";
      }
      
      open my $fh, '>', $pcfile;
      print $fh @content;
      close $fh;
    };
    
    my $build = bless {
      cflags  => _try_pkg_config($pkg_config_dir, 'cflags', '-I' . File::Spec->catdir($prefix, 'include'), '--static'),
      libs    => _try_pkg_config($pkg_config_dir, 'libs',   '-L' . File::Spec->catdir($prefix, 'lib'),     '--static'),
      prefix  => $prefix,
      dll_dir => [ 'dll' ],
      dlls    => do {
        opendir(my $dh, File::Spec->catdir($prefix, 'dll'));
        [grep { ! -l File::Spec->catfile($prefix, 'dll', $_) } grep { /\.so/ || /\.(dll|dylib)$/ } grep !/^\./, readdir $dh];
      },
    }, $class;
    
    if($^O eq 'cygwin' || $^O eq 'MSWin32')
    {
      # TODO: should this go in the munged pc file?
      unshift @{ $build->{cflags} }, '-DLIBARCHIVE_STATIC';
    }

    $build->test_compile_run || die $build->error if $options{test} =~ /^(compile|both)$/;
    $build->test_ffi         || die $build->error if $options{test} =~ /^(ffi|both)$/;
    $build;
  };
  
  my $error = $@;
  chdir $save;
  die $error if $error;
  $build;
}


sub cflags  { shift->{cflags}  }
sub libs    { shift->{libs}    }
sub version { shift->{version} }

sub dlls
{
  my($self, $prefix) = @_;
  
  $prefix = $self->{prefix} unless defined $prefix;
  $prefix = '' if $^O eq 'MSWin32' && $prefix eq '\\';
  
  unless(defined $self->{dlls} && defined $self->{dll_dir})
  {
    # Question: is this necessary in light of the better
    # dll detection now done in system_install ?
    if($^O eq 'cygwin')
    {
      # /usr/bin/cygarchive-13.dll
      opendir my $dh, '/usr/bin';
      $self->{dlls} = [grep /^cygarchive-[0-9]+.dll$/i, readdir $dh];
      $self->{dll_dir} = [];
      $prefix = '/usr/bin';
      closedir $dh;
    }
    else
    {
      require DynaLoader;
      $self->{libs} = [] unless defined $self->{libs};
      $self->{libs} = [ $self->{libs} ] unless ref $self->{libs};
      my $path = DynaLoader::dl_findfile(grep /^-l/, @{ $self->libs });
      die "unable to find dynamic library" unless defined $path;
      require File::Spec;
      my($vol, $dirs, $file) = File::Spec->splitpath($path);
      if($^O eq 'openbsd')
      {
        # on openbsd we get the .a file back, so have to scan
        # for .so.#.# as there is no .so symlink
        opendir(my $dh, $dirs);
        $self->{dlls} = [grep /^libarchive.so/, readdir $dh];
        closedir $dh;
      }
      else
      {
        $self->{dlls} = [ $file ];
      }
      $self->{dll_dir} = [];
      $self->{prefix} = $prefix = File::Spec->catpath($vol, $dirs);
    }
  }
  
  if($prefix eq '' && $self->{dll_dir}->[0] eq '')
  {
    shift @{ $self->{dll_dir} };
  }
  
  require File::Spec;
  $^O eq 'MSWin32'
    ? map { File::Spec->catfile(         @{ $self->{dll_dir} }, $_ ) } @{ $self->{dlls} }
    : map { File::Spec->catfile($prefix, @{ $self->{dll_dir} }, $_ ) } @{ $self->{dlls} };
}


sub test_compile_run
{
  my($self, %opt) = @_;
  delete $self->{error};
  $self->{quiet} = 1 unless defined $self->{quiet};
  my $cbuilder = $opt{cbuilder} || do { require ExtUtils::CBuilder; ExtUtils::CBuilder->new(quiet => $self->{quiet}) };
  
  unless($cbuilder->have_compiler)
  {
    $self->{error} = 'no compiler';
    return;
  }
  
  require File::Spec;
  my $dir = $opt{dir} || do { require File::Temp; File::Temp::tempdir( CLEANUP => 1 ) };
  my $fn = File::Spec->catfile($dir, 'test.c');
  do {
    open my $fh, '>', $fn;
    print $fh "#include <archive.h>\n",
              "#include <archive_entry.h>\n",
              "#include <stdio.h>\n",
              "int\n",
              "main(int argc, char *argv[])\n",
              "{\n",
              "  printf(\"version = '%d'\\n\", archive_version_number());\n",
              "  return 0;\n",
              "}\n";
    close $fh;
  };
  
  my $test_object = eval {
    $cbuilder->compile(
      source               => $fn,
      extra_compiler_flags => $self->{cflags} || [],
    );
  };
  
  if(my $error = $@)
  {
    $self->{error} = $error;
    return;
  }
  
  my $test_exe = eval {
    $cbuilder->link_executable(
      objects            => $test_object,
      extra_linker_flags => $self->{libs} || [],
    );
  };
  
  if(my $error = $@)
  {
    $self->{error} = $error;
    return;
  }
  
  if($test_exe =~ /\s/)
  {
    $test_exe = Win32::GetShortPathName($test_exe) if $^O eq 'MSWin32';
    $test_exe = Cygwin::win_to_posix_path(Win32::GetShortPathName(Cygwin::posix_to_win_path($test_exe))) if $^O eq 'cygwin';
  }
  
  my $output = `$test_exe`;
  
  if($? == -1)
  {
    $self->{error} = "failed to execute $!";
    return;
  }
  elsif($? & 127)
  {
    $self->{error} = "child died with siganl " . ($? & 127);
    return;
  }
  elsif($?)
  {
    $self->{error} = "child exited with value " . ($? >> 8);
    return;
  }
  
  if($output =~ /version = '([0-9]+)([0-9]{3})([0-9]{3})'/)
  {
    return $self->{version} = join '.', map { int } $1, $2, $3;
  }
  else
  {
    $self->{error} = "unable to retrieve version from output";
    return;
  }
}


sub test_ffi
{
  my($self) = @_;
  require FFI::Raw;
  delete $self->{error};

  foreach my $dll ($self->dlls)
  {
    my $archive_version_number = eval {
      FFI::Raw->new(
        $dll, 'archive_version_number',
        FFI::Raw::int(),
      );
    };
    next if $@;
    if($archive_version_number->() =~ /^([0-9]+)([0-9]{3})([0-9]{3})/)
    {
      return $self->{version} = join '.', map { int } $1, $2, $3;
    }
  }
  $self->{error} = 'could not find archive_version_number';
  return; 
}


sub error { shift->{error} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Libarchive::Installer - Installer for libarchive

=head1 VERSION

version 0.15

=head1 SYNOPSIS

Build.PL

 # as an optional dep
 use Alien::Libarchive::Installer;
 use Module::Build;
 
 my %build_args;
 
 my $installer = eval { Alien::Libarchive::Installer->system_install };
 if($installer)
 {
   $build_args{extra_compiler_flags} = $installer->cflags,
   $build_args{extra_linker_flags}   = $installer->libs,
 }
 
 my $build = Module::Build->new(%build_args);
 $build->create_build_script;

Build.PL

 # require 3.0
 use Alien::Libarchive::Installer;
 use Module::Build;
 
 my $installer = eval {
   my $system_installer = Alien::Libarchive::Installer->system_install;
   die "we require 3.0.x or better"
     if $system_installer->version !~ /^([0-9]+)\./ && $1 >= 3;
   $system_installer;
      # reasonably assumes that build_install will never download
      # a version older that 3.0
 } || Alien::Libarchive::Installer->build_install("dir");
 
 my $build = Module::Build->new(
   extra_compiler_flags => $installer->cflags,
   extra_linker_flags   => $installer->libs,
 );
 $build->create_build_script;

FFI::Raw

 # as an optional dep
 use Alien::Libarchive::Installer;
 use FFI::Raw;
 
 eval {
   my($dll) = Alien::Libarchive::Installer->system_install->dlls;
   FFI::Raw->new($dll, 'archive_read_new', FFI::Raw::ptr);
 };
 if($@)
 {
   # handle it if libarchive is not available
 }

=head1 DESCRIPTION

This distribution contains the logic for finding existing libarchive
installs, and building new ones.  If you do not care much about the
version of libarchive that you use, and libarchive is not an optional
requirement, then you are probably more interested in using
L<Alien::Libarchive>.

Where L<Alien::Libarchive::Installer> is useful is when you have
specific version requirements (say you require 3.0.x but 2.7.x
will not do), but would still like to use the system libarchive
if it is available.

=head1 CLASS METHODS

Class methods can be executed without creating an instance of
L<Alien::libarchive::Installer>, and generally used to query
status of libarchive availability (either via the system or the
internet).  Methods that discover a system libarchive or build
a one from source code on the Internet will generally return
an instance of L<Alien::Libarchive::Installer> which can be
queried to retrieve the settings needed to interact with 
libarchive via XS or L<FFI::Raw>.

=head2 versions_available

 my @versions = Alien::Libarchive::Installer->versions_available;
 my $latest_version = $versions[-1];

Return the list of versions of libarchive available on the Internet.
Will throw an exception if the libarchive.org website is unreachable.
Versions will be sorted from oldest (smallest) to newest (largest).

=head2 fetch

 my($location, $version) = Alien::Libarchive::Installer->fetch(%options);
 my $location = Alien::Libarchive::Installer->fetch(%options);

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::Libarchive::Installer#build_requires>
method.

Download libarchive source from the internet.  By default it will
download the latest version to a temporary directory which will
be removed when Perl exits.  Will throw an exception on
failure.  Options include:

=over 4

=item dir

Directory to download to

=item version

Version to download

=back

=head2 build_requires

 my $prereqs = Alien::Libarchive::Installer->build_requires;
 while(my($module, $version) = each %$prereqs)
 {
   ...
 }

Returns a hash reference of the build requirements.  The
keys are the module names and the values are the versions.

The requirements may be different depending on your
platform.

=head2 system_requires

This is like L<build_requires|Alien::Libarchive::Installer#build_requires>,
except it is used when using the libarchive that comes with the operating
system.

=head2 system_install

 my $installer = Alien::Libarchive::Installer->system_install(%options);

B<NOTE:> using this method may require modules returned by the
L<system_requires|Alien::Libarchive::Installer> method.

B<NOTE:> This form will also use the libarchive provided by L<Alien::Libarchive>
if version 0.21 or better is installed.  This makes this method ideal for
finding libarchive as an optional dependency.

Options:

=over 4

=item test

Specifies the test type that should be used to verify the integrity
of the system libarchive.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::Libarchive::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::Libarchive::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::Libarchive::Installer#test_compile_run>
and
L<test_ffi|Alien::Libarchive::Installer#test_ffi>
to verify

=back

=item alien

If true (the default) then an existing L<Alien::Libarchive> will be
used if version 0.21 or better is found.  Usually this is what you
want.

=back

=head2 build_install

 my $installer = Alien::Libarchive::Installer->build_install( '/usr/local', %options );

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::Libarchive::Installer>
method.

Build and install libarchive into the given directory.  If there
is an error an exception will be thrown.  On a successful build, an
instance of L<Alien::Libarchive::Installer> will be returned.

These options may be passed into build_install:

=over 4

=item tar

Filename where the libarchive source tar is located.
If not specified the latest version will be downloaded
from the Internet.

=item dir

Empty directory to be used to extract the libarchive
source and to build from.

=item test

Specifies the test type that should be used to verify the integrity
of the build after it has been installed.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::Libarchive::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::Libarchive::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::Libarchive::Installer#test_compile_run>
and
L<test_ffi|Alien::Libarchive::Installer#test_ffi>
to verify

=back

=back

=head1 ATTRIBUTES

Attributes of an L<Alien::Libarchive::Installer> provide the
information needed to use an existing libarchive (which may
either be provided by the system, or have just been built
using L<build_install|Alien::Libarchive::Installer#build_install>.

=head2 cflags

The compiler flags required to use libarchive.

=head2 libs

The linker flags and libraries required to use libarchive.

=head2 dlls

List of DLL or .so (or other dynamic library) files that can
be used by L<FFI::Raw> or similar.

=head2 version

The version of libarchive

=head1 INSTANCE METHODS

=head2 test_compile_run

 if($installer->test_compile_run(%options))
 {
   # You have a working Alien::Libarchive as
   # specified by %options
 }
 else
 {
   die $installer->error;
 }

Tests the compiler to see if you can build and run
a simple libarchive program.  On success it will 
return the libarchive version.  Other options include

=over 4

=item cbuilder

The L<ExtUtils::CBuilder> instance that you want
to use.  If not specified, then a new one will
be created.

=item dir

Directory to use for building the executable.
If not specified, a temporary directory will be
created and removed when Perl terminates.

=item quiet

Passed into L<ExtUtils::CBuilder> if you do not
provide your own instance.  The default is true
(unlike L<ExtUtils::CBuilder> itself).

=back

=head2 test_ffi

 if($installer->test_ffi(%options))
 {
   # You have a working Alien::Libarchive as
   # specified by %options
 }
 else
 {
   die $installer->error;
 }

Test libarchive to see if it can be used with L<FFI::Raw>
(or similar).  On success it will return the libarchive
version.

=head2 error

Returns the error from the previous call to L<test_compile_run|Alien::Libarchive::Installer#test_compile_run>
or L<test_ffi|Alien::Libarchive::Installer#test_ffi>.

=head1 SEE ALSO

=over 4

=item L<Alien::Libarchive>

=item L<Archive::Libarchive::XS>

=item L<Archive::Libarchive::FFI>

=item L<Archive::Libarchive::Any>

=item L<Archive::Ar::Libarchive>

=item L<Archive::Peek::Libarchive>

=item L<Archive::Extract::Libarchive>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
