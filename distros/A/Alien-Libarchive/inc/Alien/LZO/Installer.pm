package Alien::LZO::Installer;

use strict;
use warnings;

# ABSTRACT: Installer for LZO
# VERSION

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

=head1 SYNOPSIS

Build.PL

 # as an optional dep
 use Alien::LZO::Installer;
 use Module::Build;
 
 my %build_args;
 
 my $installer = eval { Alien::LZO::Installer->system_install };
 if($installer)
 {
   $build_args{extra_compiler_flags} = $installer->cflags,
   $build_args{extra_linker_flags}   = $installer->libs,
 }
 
 my $build = Module::Build->new(%build_args);
 $build->create_build_script;

Build.PL

 # require 2.0
 use Alien::LZO::Installer;
 use Module::Build;
 
 my $installer = eval {
   my $system_installer = Alien::LZO::Installer->system_install;
   die "we require 2.00 or better"
     if $system->version !~ /^([0-9]+)\./ && $1 >= 2;
   $system_installer;
      # reasonably assumes that build_install will never download
      # a version older that 3.0
 } || Alien::LZO::Installer->build_install("dir");
 
 my $build = Module::Build->new(
   extra_compiler_flags => $installer->cflags,
   extra_linker_flags   => $installer->libs,
 );
 $build->create_build_script;

FFI::Raw

 # as an optional dep
 use Alien::LZO::Installer;
 use FFI::Raw;
 
 eval {
   my($dll) = Alien::LZO::Installer->system_install->dlls;
   FFI::Raw->new($dll, 'lzo_version', FFI::Raw::uint);
 };
 if($@)
 {
   # handle it if lzo is not available
 }

=head1 DESCRIPTION

This distribution contains the logic for finding existing lzo
installs, and building new ones.  If you do not care much about the
version of lzo that you use, and lzo is not an optional
requirement, then you are probably more interested in using
L<Alien::LZO>.

Where L<Alien::LZO::Installer> is useful is when you have
specific version requirements (say you require 3.0.x but 2.7.x
will not do), but would still like to use the system lzo
if it is available.

=head1 CLASS METHODS

Class methods can be executed without creating an instance of
L<Alien::LZO::Installer>, and generally used to query
status of lzo availability (either via the system or the
internet).  Methods that discover a system lzo or build
a one from source code on the Internet will generally return
an instance of L<Alien::LZO::Installer> which can be
queried to retrieve the settings needed to interact with 
lzo via XS or L<FFI::Raw>.

=head2 versions_available

 my @versions = Alien::LZO::Installer->versions_available;
 my $latest_version = $versions[-1];

Return the list of versions of lzo available on the Internet.
Will throw an exception if the oberhumer.com website is unreachable.
Versions will be sorted from oldest (smallest) to newest (largest).

=cut

sub versions_available
{
  require HTTP::Tiny;
  my $url = "http://www.oberhumer.com/opensource/lzo/download/";
  my $response = HTTP::Tiny->new->get($url);
  
  die sprintf("%s %s %s", $response->{status}, $response->{reason}, $url)
    unless $response->{success};

  # TODO remove dupes
  my @versions;
  push @versions, [$1,$2] while $response->{content} =~ /lzo-([1-9][0-9]*)\.([0-9]+)\.tar.gz/g;
  @versions = map { join '.', @$_ } sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @versions;
}

=head2 fetch

 my($location, $version) = Alien::LZO::Installer->fetch(%options);
 my $location = Alien::LZO::Installer->fetch(%options);

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::LZO::Installer#build_requires>
method.

Download lzo source from the internet.  By default it will
download the latest version to a temporary directory which will
be removed when Perl exits.  Will throw an exception on
failure.  Options include:

=over 4

=item dir

Directory to download to

=item version

Version to download

=back

=cut

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

  if(defined $ENV{ALIEN_LZO_INSTALL_MIRROR})
  {
    my $fn = _catfile($ENV{ALIEN_LZO_INSTALL_MIRROR}, "lzo-$version.tar.gz");
    return wantarray ? ($fn, $version) : $fn;
  }

  my $url = "http://www.oberhumer.com/opensource/lzo/download/lzo-$version.tar.gz";
  
  my $response = HTTP::Tiny->new->get($url);
  
  die sprintf("%s %s %s", $response->{status}, $response->{reason}, $url)
    unless $response->{success};
  
  require File::Spec;
  
  my $fn = _catfile($dir, "lzo-$version.tar.gz");
  
  open my $fh, '>', $fn;
  binmode $fh;
  print $fh $response->{content};
  close $fh;
  
  wantarray ? ($fn, $version) : $fn;
}

=head2 build_requires

 my $prereqs = Alien::LZO::Installer->build_requires;
 while(my($module, $version) = each %$prereqs)
 {
   ...
 }

Returns a hash reference of the build requirements.  The
keys are the module names and the values are the versions.

The requirements may be different depending on your
platform.

=cut

sub build_requires
{
  my %prereqs = (
    'HTTP::Tiny'   => 0,
    'Archive::Tar' => 0,
  );
  
  if($^O eq 'MSWin32')
  {
    $prereqs{'Alien::MSYS'} = '0.07';
    $prereqs{'Archive::Ar'} = '2.00';
  }
  
  \%prereqs;
}

=head2 system_requires

This is like L<build_requires|Alien::LZO::Installer#build_requires>,
except it is used when using the lzo that comes with the operating
system.

=cut

sub system_requires
{
  my %prereqs = ();
  \%prereqs;
}

=head2 system_install

 my $installer = Alien::LZO::Installer->system_install(%options);

B<NOTE:> using this method may require modules returned by the
L<system_requires|Alien::LZO::Installer> method.

B<NOTE:> This form will also use the lzo provided by L<Alien::LZO>
if it is installed.  This makes this method ideal for finding
lzo as an optional dependency.

Options:

=over 4

=item test

Specifies the test type that should be used to verify the integrity
of the system lzo.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::LZO::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::LZO::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::LZO::Installer#test_compile_run>
and
L<test_ffi|Alien::LZO::Installer#test_ffi>
to verify

=back

=item alien

If true (the default) then an existing L<Alien::LZO> will be
used if version 0.19 or better is found.  Usually this is what you
want.

=back

=cut

sub system_install
{
  my($class, %options) = @_;

  $options{alien} = 1 unless defined $options{alien};
  $options{test} ||= 'compile';
  die "test must be one of compile, ffi or both"
    unless $options{test} =~ /^(compile|ffi|both)$/;

  if($options{alien} && eval q{ use Alien::LZO 0.01; 1 })
  {
    my $alien = Alien::LZO->new;
    my $build = bless {
      cflags => $alien->cflags,
      libs   => $alien->libs,
    }, $class;
    return $build if $options{test} =~ /^(compile|both)$/ && $build->test_compile_run;
    return $build if $options{test} =~ /^(ffi|both)$/ && $build->test_compile_run;
  }

  my $build = bless {
    cflags => [],
    libs   => ['-llzo2'],
  }, $class;
  
  $build->test_compile_run || die $build->error if $options{test} =~ /^(compile|both)$/;
  $build->test_ffi || die $build->error if $options{test} =~ /^(ffi|both)$/;
  $build;
}

=head2 build_install

 my $installer = Alien::LZO::Installer->build_install( '/usr/local', %options );

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::LZO::Installer>
method.

Build and install lzo into the given directory.  If there
is an error an exception will be thrown.  On a successful build, an
instance of L<Alien::LZO::Installer> will be returned.

These options may be passed into build_install:

=over 4

=item tar

Filename where the lzo source tar is located.
If not specified the latest version will be downloaded
from the Internet.

=item dir

Empty directory to be used to extract the lzo
source and to build from.

=item test

Specifies the test type that should be used to verify the integrity
of the build after it has been installed.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::LZO::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::LZO::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::LZO::Installer#test_compile_run>
and
L<test_ffi|Alien::LZO::Installer#test_ffi>
to verify

=back

=back

=cut

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

  require File::Spec;
  
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
  
    _msys(sub {
      # TODO this will only work with gcc
      my($make) = @_;
      system 'sh', 'configure', "--prefix=$prefix", '--with-pic', '--enable-shared';
      die "configure failed" if $?;
      system $make, 'all';
      die "make all failed" if $?;
      system $make, 'install';
      die "make install failed" if $?;
    });

    if($^O eq 'MSWin32')
    {
      # TODO: this will only work with gcc
      require File::Temp;
      my $dir = File::Temp::tempdir( CLEANUP => 1 );
      # TODO: use Archive::Ar when it is a little less broken
      require Archive::Ar;
      my $ar = Archive::Ar->new(_catfile($prefix, 'lib', 'liblzo2.a'));
      my @objects = grep { $_ ne '/' } $ar->list_files;
      foreach my $object (@objects)
      {
        my $fh;
        my $fn = _catfile($dir, $object);
        open($fh, '>', $fn) || die "unable to write $fn $!";
        binmode $fh;
        print $fh $ar->get_content($object)->{data};
        close $fh;
      }      
      system 'dlltool',
        '--export-all-symbols',
        -e => _catfile($dir, 'exports.o'),
        -l => _catfile($prefix, 'lib', 'liblzo2.dll.a'),
        map { _catfile($dir, $_) } @objects;
      die "dlltool failed" if $?;
      system 'gcc',
        '--shared',
        -o => _catfile($prefix, 'lib', 'liblzo2.dll'),
        _catfile($dir, 'exports.o'),
        map { _catfile($dir, $_) } @objects;
      
      do {
        my($in,$out);
        open($in, '<', _catfile($prefix, 'lib', 'liblzo2.la'));
        open($out, '>', _catfile($prefix, 'lib', 'liblzo2.la.tmp'));
        while(<$in>)
        {
          s{^dlname='.*?'}{dlname='../dll/liblzo2.dll'};
          s{^library_names='.*?'}{library_names='../dll/liblzo2.dll.a'};
          print $out $_;
        }
        close $in;
        close $out;
        unlink _catfile($prefix, 'lib', 'liblzo2.la');
        rename _catfile($prefix, 'lib', 'liblzo2.la.tmp'),
               _catfile($prefix, 'lib', 'liblzo2.la');
      };
    }

    foreach my $name ('lib')
    {
      do {
        my $static_dir = _catdir($prefix, $name);
        my $dll_dir    = _catdir($prefix, 'dll');
        require File::Path;
        File::Path::mkpath($dll_dir, 0, 0755);
        my $dh;
        opendir $dh, $static_dir;
        my @list = readdir $dh;
        @list = grep { /\.so/ || /\.(dylib|la|dll|dll\.a)$/} grep !/^\./, @list;
        closedir $dh;
        foreach my $basename (@list)
        {
          my $from = _catfile($static_dir, $basename);
          my $to   = _catfile($dll_dir,    $basename);
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

    my $build = bless {
      cflags  => ['-I' . _catdir($prefix, 'include')],
      libs    => ['-L' . _catdir($prefix, 'lib'), '-llzo2'],
      prefix  => $prefix,
      dll_dir => [ 'dll' ],
      dlls    => do {
        opendir(my $dh, _catdir($prefix, 'dll'));
        [grep { ! -l _catfile($prefix, 'dll', $_) } grep { /\.so/ || /\.(dll|dylib)$/ } grep !/^\./, readdir $dh];
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

=head1 ATTRIBUTES

Attributes of an L<Alien::LZO::Installer> provide the
information needed to use an existing lzo (which may
either be provided by the system, or have just been built
using L<build_install|Alien::LZO::Installer#build_install>.

=head2 cflags

The compiler flags required to use lzo.

=head2 libs

The linker flags and libraries required to use lzo.

=head2 dlls

List of DLL or .so (or other dynamic library) files that can
be used by L<FFI::Raw> or similar.

=head2 version

The version of lzo

=cut

sub cflags  { shift->{cflags}  }
sub libs    { shift->{libs}    }
sub version { shift->{version} }

sub dlls
{
  my($self, $prefix) = @_;
  
  $prefix = $self->{prefix} unless defined $prefix;
  
  unless(defined $self->{dlls} && defined $self->{dll_dir})
  {
    if($^O eq 'cygwin')
    {
      # /usr/bin/cyglzo2-2.dll
      opendir my $dh, '/usr/bin';
      $self->{dlls} = [grep /^lzo2-[0-9]+.dll$/i, readdir $dh];
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
        $self->{dlls} = [grep /^liblzo2.so/, readdir $dh];
        closedir $dh;
      }
      else
      {
        $self->{dlls} = [ $file ];
      }
      $self->{dll_dir} = [];
      $prefix = File::Spec->catpath($vol, $dirs);
    }
  }
  
  require File::Spec;
  map { _catfile($prefix, @{ $self->{dll_dir} }, $_ ) } @{ $self->{dlls} };
}

=head1 INSTANCE METHODS

=head2 test_compile_run

 if($installer->test_compile_run(%options))
 {
   # You have a working Alien::LZO as
   # specified by %options
 }
 else
 {
   die $installer->error;
 }

Tests the compiler to see if you can build and run
a simple lzo program.  On success it will 
return the lzo version.  Other options include

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

=cut

sub test_compile_run
{
  my($self, %opt) = @_;
  delete $self->{error};
  #$self->{quiet} = 1 unless defined $self->{quiet};
  $self->{quiet} = 1;
  my $cbuilder = $opt{cbuilder} || do { require ExtUtils::CBuilder; ExtUtils::CBuilder->new(quiet => $self->{quiet}) };
  
  unless($cbuilder->have_compiler)
  {
    $self->{error} = 'no compiler';
    return;
  }
  
  require File::Spec;
  my $dir = $opt{dir} || do { require File::Temp; File::Temp::tempdir( CLEANUP => 1 ) };
  my $fn = _catfile($dir, 'test.c');
  do {
    open my $fh, '>', $fn;
    print $fh "#include <lzo/lzoconf.h>\n",
              "#include <stdio.h>\n",
              "int\n",
              "main(int argc, char *argv[])\n",
              "{\n",
              "  printf(\"lzo_version = %d\\n\", lzo_version());\n",
              "  printf(\"version = '%s'\\n\", LZO_VERSION_STRING);\n",
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

  if($output =~ /version = '(.*?)'/)
  {
    return $self->{version} = $1;
  }
  else
  {
    $self->{error} = "unable to retrieve version from output";
    return;
  }
}

=head2 test_ffi

 if($installer->test_ffi(%options))
 {
   # You have a working Alien::LZO as
   # specified by %options
 }
 else
 {
   die $installer->error;
 }

Test lzo to see if it can be used with L<FFI::Raw>
(or similar).  On success it will return the lzo
version.

=cut

sub test_ffi
{
  my($self) = @_;
  require FFI::Raw;
  delete $self->{error};

  foreach my $dll ($self->dlls)
  {
    my $lzo_version_number = eval {
      FFI::Raw->new(
        $dll, 'lzo_version_string',
        FFI::Raw::str(),
      );
    };
    next if $@;
    if($lzo_version_number->() =~ /^(.*)$/)
    {
      return $self->{version} = $1;
    }
  }
  $self->{error} = 'could not find lzo_version_string';
  return; 
}

=head2 error

Returns the error from the previous call to L<test_compile_run|Alien::LZO::Installer#test_compile_run>
or L<test_ffi|Alien::LZO::Installer#test_ffi>.

=cut

sub error { shift->{error} }

1;

=head1 SEE ALSO

=over 4

=item L<Alien::LZO>

=back

=cut
