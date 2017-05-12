package Alien::bz2::Installer;

use strict;
use warnings;

# ABSTRACT: Installer for bz2
our $VERSION = '0.05'; # VERSION

sub _catfile {
  my $path = File::Spec->catfile(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}

sub _catdir {
  my $path = File::Spec->catdir(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}


sub versions_available
{
  ($^O eq 'MSWin32' ? '1.0.5' : '1.0.6');
}


sub fetch
{
  my($class, %options) = @_;
  
  my $dir = $options{dir} || eval { require File::Temp; File::Temp::tempdir( CLEANUP => 1 ) };
  
  # actually we ignore the version argument.

  require File::Spec;
  
  my $url      = 'http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz';
  my $fn       = _catfile($dir, 'bzip2-1.0.6.tar.gz');
  my($version) = $class->versions_available;
  if($^O eq 'MSWin32')
  {
    $url = 'http://gnuwin32.sourceforge.net/downlinks/bzip2-src-zip.php';
    $fn  = _catfile($dir, 'bzip2-1.0.5-src.zip');
  }
  
  require HTTP::Tiny;
  my $response = HTTP::Tiny->new->get($url);
  
  die sprintf("%s %s %s", $response->{status}, $response->{reason}, $url)
    unless $response->{success};

  open my $fh, '>', $fn;
  binmode $fh;
  print $fh $response->{content};
  close $fh;
  
  wantarray ? ($fn, $version) : $fn;
}


sub build_requires
{
  my %prereqs = (
    'HTTP::Tiny' => 0,
  );
  
  if($^O eq 'MSWin32')
  {
    $prereqs{'Archive::Zip'} = 0;
    $prereqs{'Alien::o2dll'} = 0;
    $prereqs{'Alien::MSYS'}  = 0;
  }
  else
  {
    $prereqs{'Archive::Tar'} = 0;
  }
  
  \%prereqs;
}


sub system_requires
{
  my %prereqs;
  \%prereqs;
}


sub system_install
{
  my($class, %options) = @_;
  
  $options{alien} = 1 unless defined $options{alien};
  $options{test} ||= 'compile';
  die "test must be one of compile, ffi or both"
    unless $options{test} =~ /^(compile|ffi|both)$/;
   
  my $build = bless {
    cflags => [],
    libs   => ['-lbz2'],
  }, $class;
  
  $build->test_compile_run || die $build->error if $options{test} =~ /^(compile|both)$/;
  $build->test_ffi || die $build->error if $options{test} =~ /^(ffi|both)$/;
  $build;
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
  
  require Cwd;
  require File::Spec;
  my $save = Cwd::getcwd();
  
  my $build = eval {
    if($^O eq 'MSWin32')
    {
      require Archive::Zip;
      my $zip = Archive::Zip->new;
      $zip->read(scalar $options{tar} || $class->fetch);
      chdir $dir;
      mkdir 'bzip2-1.0.5';
      chdir 'bzip2-1.0.5';
      $zip->extractTree;
      chdir(_catdir(qw( src bzip2 1.0.5 bzip2-1.0.5 )));
    }
    else
    {
      require Archive::Tar;
      my $tar = Archive::Tar->new;
      $tar->read($options{tar} || $class->fetch);
      chdir $dir;
      $tar->extract;
      chdir do {
      opendir my $dh, '.';
        my(@list) = grep !/^\./,readdir $dh;
        close $dh;
        die "unable to find source in build root" if @list == 0;
        die "confused by multiple entries in the build root" if @list > 1;
        $list[0];
      };
    }
      
    if($^O eq 'MSWin32')
    {
      open my $fh, '<', 'Makefile';
      my $makefile = do { local $/; <$fh> }; 
      close $fh;
      
      $makefile =~ s/\to2dll/\t$^X -MAlien::o2dll=o2dll o2dll.pl/g;
      
      open $fh, '>', 'Makefile';
      print $fh $makefile;
      close $fh;
      
      open $fh, '>', 'o2dll.pl';
      print $fh "use Alien::o2dll qw( o2dll );\n";
      print $fh "o2dll(\@ARGV)\n";
      close $fh;
      
      _msys(sub {
        system 'make', 'all';
        die "make all failed" if $?;
        system 'make', 'install', "PREFIX=$prefix";
        die "make install failed" if $?;
      });
      mkdir(_catdir($prefix, 'dll'));
      File::Copy::copy('bzip2.dll', _catfile($prefix, 'dll', 'bzip2.dll'));
      File::Copy::copy('libbz2.dll.a', _catfile($prefix, 'dll', 'libbz2.dll.a'));
    }
    else
    {
      require Config;
      require File::Copy;
      my $make = $Config::Config{make};
      system $make, -f => 'Makefile-libbz2_so';
      die "make -f Makefile-libbz2_so failed" if $?;
      system $make, 'all';
      die "make all failed" if $?;
      system $make, 'install', "PREFIX=$prefix";
      die "make install failed" if $?;
      mkdir(_catdir($prefix, 'dll'));
      File::Copy::copy('libbz2.so.1.0.6', _catfile($prefix, 'dll', 'libbz2.so.1.0.6'));
      eval { chmod 0755, _catfile($prefix, 'dll', 'libbz2.so.1.0.6') };
    }
    
    my $build = bless {
      cflags  => [ "-I" . _catdir($prefix, 'include') ],
      libs    => [ "-L" . _catdir($prefix, 'lib'), '-lbz2' ],
      prefix  => $prefix,
      dll_dir => [ 'dll' ],
      dlls    => do {
        opendir(my $dh, File::Spec->catdir($prefix, 'dll'));
        [grep { ! -l File::Spec->catfile($prefix, 'dll', $_) } grep { /\.so/ || /\.(dll|dylib)$/ } grep !/^\./, readdir $dh];
      },
    }, $class;
    
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
  
  require File::Spec;
  
  unless(defined $self->{dlls} && defined $self->{dll_dir})
  {
    if($^O eq 'cygwin')
    {
      opendir my $dh, '/usr/bin';
      $self->{dlls}    = [grep /^cygbz2-[0-9]+\.dll$/i, readdir $dh];
      $self->{dll_dir} = [];
      $prefix = '/usr/bin';
      closedir $dh;
    }
    else
    {
      require DynaLoader;
      my $path = DynaLoader::dl_findfile(grep /^-l/, @{ $self->libs});
      die "unable to find dynamic library" unless defined $path;
      my($vol, $dirs, $file) = File::Spec->splitpath($path);
      if($^O eq 'openbsd')
      {
        # on openbsd we get the .a file back, so have to scan
        # for .so.#.# as there is no .so symlink
        opendir(my $dh, $dirs);
        $self->{dlls} = [grep /^libbz2.so/, readdir $dh];
        closedir $dh;
      }
      else
      {
        $self->{dlls} = [ $file ];
      }
      $self->{dll_dir} = [];
      $prefix = File::Spec->catpath($vol, $dirs);
      $prefix =~ s{\\}{/}g;
    }
  }
  
  map { _catfile($prefix, @{ $self->{dll_dir} }, $_) } @{ $self->{dlls} };
}


sub test_compile_run
{
  my($self, %opt) = @_;
  
  delete $self->{error};
  $opt{quiet} = 1 unless defined $opt{quiet};
  my $cbuilder = $opt{cbuilder} || do { require ExtUtils::CBuilder; ExtUtils::CBuilder->new(quiet => $opt{quiet}) };
  
  unless($cbuilder->have_compiler)
  {
    $self->{error} = 'no compiler';
    return;
  }
  
  my $dir = $opt{dir} || do { require File::Temp; File::Temp::tempdir(CLEANUP => 1) };
  require File::Spec;
  my $fn = _catfile($dir, 'test.c');
  do {
    open my $fh, '>', $fn;
    print $fh "#include <bzlib.h>\n",
              "#include <stdio.h>\n",
              "int\n",
              "main(int argc, char *argv[])\n",
              "{\n",
              "  printf(\"version = '%s'\\n\", BZ2_bzlibVersion());\n",
              "  return 0;\n",
              "}\n";
    close $fh;
  };
  
  my $test_exe = eval {
    my $test_object = $cbuilder->compile(
      source               => $fn,
      extra_compiler_flags => $self->cflags,
    );
    $cbuilder->link_executable(
      objects            => $test_object,
      extra_linker_flags => $self->libs,
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

  if($?)
  {
    if($? == -1)
    {
      $self->{error} = "failed to execute $!";
    }
    elsif($? & 127)
    {
      $self->{error} = "child died with signal" . ($? & 127);
    }
    else
    {
      $self->{error} = "child exited with value " . ($? >> 8);
    }
    return;
  }
  
  if($output =~ /version = '(.*?),/)
  {
    return $self->{version} = $1;
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
  
  foreach my $dll ($self->dlls)
  {
    my $get_version = eval {
      FFI::Raw->new(
        $dll, 'BZ2_bzlibVersion', FFI::Raw::str(),
      );
    };
    next if $@;
    if($get_version->() =~ /^(.*?),/)
    {
      return $self->{version} = $1;
    }
  }
  $self->{error} = 'BZ2_bzlibVersion not found (ffi)';
  return;
}


sub error { $_[0]->{error} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::bz2::Installer - Installer for bz2

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Build.PL

 # as an optional dep
 use Alien::bz2::Installer;
 use Module::Build;
 
 my %build_args;
 
 my $installer = eval { Alien::bz2::Installer->system_install };
 if($installer)
 {
   $build_args{extra_compiler_flags} = $installer->cflags,
   $build_args{extra_linker_flags}   = $installer->libs,
 }
 
 my $build = Module::Build->new(%build_args);
 $build->create_build_script;

Build.PL

 # require 3.0
 use Alien::bz2::Installer;
 use Module::Build;
 
 my $installer = eval {
   my $system_installer = Alien::bz2::Installer->system_install;
   die "we require 1.0.6 or better"
     if $system->version !~ /^([0-9]+)\.([0-9]+)\.([0-9]+)/ && $1 >= 1 && ($3 >= 6 || $1 > 1);
   $system_installer;
      # reasonably assumes that build_install will never download
      # a version older that 1.0.6
 } || Alien::bz2::Installer->build_install("dir");
 
 my $build = Module::Build->new(
   extra_compiler_flags => $installer->cflags,
   extra_linker_flags   => $installer->libs,
 );
 $build->create_build_script;

FFI::Raw

 # as an optional dep
 use Alien::bz2::Installer;
 use FFI::Raw;
 
 eval {
   my($dll) = Alien::bz2::Installer->system_install->dlls;
   FFI::Raw->new($dll, 'BZ2_bzlibVersion', FFI::Raw::str);
 };
 if($@)
 {
   # handle it if bz2 is not available
 }

=head1 DESCRIPTION

If you just want to compress or decompress bzip2 data in Perl you
probably want one of L<Compress::Bzip2>, L<Compress::Raw::Bzip2>
or L<IO::Compress::Bzip2>.

This distribution contains the logic for finding existing bz2
installs, and building new ones.  If you do not care much about the
version of bz2 that you use, and bz2 is not an optional
requirement, then you are probably more interested in using
L<Alien::bz2>.

Where L<Alien::bz2::Installer> is useful is when you have
specific version requirements (say you require 3.0.x but 2.7.x
will not do), but would still like to use the system bz2
if it is available.

=head1 CLASS METHODS

Class methods can be executed without creating an instance of
L<Alien::bz2::Installer>, and generally used to query
status of bz2 availability (either via the system or the
internet).  Methods that discover a system bz2 or build
a one from source code on the Internet will generally return
an instance of L<Alien::bz2::Installer> which can be
queried to retrieve the settings needed to interact with 
bz2 via XS or L<FFI::Raw>.

=head2 versions_available

 my @versions = Alien::bz2::Installer->versions_available;
 my $latest_version = $version[-1];

Returns the list of versions of bzip2 available on the Internet.
Will throw an exception if available versions cannot be determined.

=head2 fetch

 my($location, $version) = Alien::bz2::Installer->fetch(%options);
 my $location = Alien::bz2::Installer->fetch(%options);

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::bz2::Installer#build_requires>
method.

Download the bz2 source from the internet.  By default it will
download the latest version t a temporary directory, which will
be removed when Perl exits.  Will throw an exception on failure.
Options include:

=over 4

=item dir

Directory to download to

=item version

Version to download

=back

=head2 build_requires

 my $prereqs = Alien::bz2::Installer->build_requires;
 while(my($module, $version) = each %$prereqs)
 {
   ...
 }

Returns a hash reference of the build requirements.  The
keys are the module names and the values are the versions.

The requirements may be different depending on your platform.

=head2 system_requires

This is like L<build_requires|Alien::bz2::Installer#build_requires>,
except it is used when using the bz2 that comes with the operating
system.

=head2 system_install

 my $installer = Alien::bz2::Installer->system_install(%options);

B<NOTE:> using this method may require modules returned by the
L<system_requires|Alien::bz2::Installer> method.

Options:

=over 4

=item test

Specifies the test type that should be used to verify the integrity
of the system bz2.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::bz2::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::bz2::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::bz2::Installer#test_compile_run>
and
L<test_ffi|Alien::bz2::Installer#test_ffi>
to verify

=back

=item alien

If true (The default) then an existing L<Alien::bz2> will
be used if found.  Usually this is what you want.

=back

=head2 build_install

 my $installer = Alien::bz2::Installer->build_install( '/usr/local', %options );

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::bz2::Installer>
method.

Build and install bz2 into the given directory.  If there
is an error an exception will be thrown.  On a successful build, an
instance of L<Alien::bz2::Installer> will be returned.

These options may be passed into build_install:

=over 4

=item tar

Filename where the bz2 source tar is located.
If not specified the latest version will be downloaded
from the Internet.

=item dir

Empty directory to be used to extract the bz2
source and to build from.

=item test

Specifies the test type that should be used to verify the integrity
of the build after it has been installed.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::bz2::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::bz2::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::bz2::Installer#test_compile_run>
and
L<test_ffi|Alien::bz2::Installer#test_ffi>
to verify

=back

=back

=head1 ATTRIBUTES

Attributes of an L<Alien::bz2::Installer> provide the
information needed to use an existing bz2 (which may
either be provided by the system, or have just been built
using L<build_install|Alien::bz2::Installer#build_install>.

=head2 cflags

The compiler flags required to use bz2.

=head2 libs

The linker flags and libraries required to use bz2.

=head2 dlls

List of DLL or .so (or other dynamic library) files that can
be used by L<FFI::Raw> or similar.

=head2 version

The version of bz2

=head1 INSTANCE METHODS

=head2 test_compile_run

 if($installer->test_compile_run(%options))
 {
   # You hae a working bz2
 }
 else
 {
   die $installer->error;
 }

Tests the compiler to see if you can build and run
a simple bz2 program.  On success it will 
return the bz2 version.  Other options include

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
   # You have a working bz2
 }
 else
 {
   die $installer->error;
 }

Test bz2 to see if it can be used with L<FFI::Raw> (or similar).
On success, it will return the bz2 version.

=head2 error

Returns the error from the previous call to L<test_compile_run|Alien::bz2::Installer#test_compile_run>
or L<test_ffi|Alien::bz2::Installer#test_ffi>.

=head1 SEE ALSO

=over 4

=item L<Alien::bz2>

=item L<Compress::Bzip2>

=item L<Compress::Raw::Bzip2>

=item L<IO::Compress::Bzip2>

=back

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
