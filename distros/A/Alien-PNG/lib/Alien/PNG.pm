package Alien::PNG;
use strict;
use warnings;
use Alien::PNG::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Find;
use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Temp;
use ExtUtils::CBuilder;

=head1 NAME

Alien::PNG - building, finding and using PNG binaries

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Alien::PNG tries (in given order) during its installation:

=over

=item * Locate an already installed PNG via 'libpng-config' script.

=item * Check for PNG libs in directory specified by PNG_INST_DIR variable.
In this case the module performs PNG library detection via
'$PNG_INST_DIR/bin/libpng-config' script.

=item * Download prebuilt PNG binaries (if available for your platform).

=item * Build PNG binaries from source codes (if possible on your system).

=back

Later you can use Alien::PNG in your module that needs to link agains PNG
and/or related libraries like this:

    # Sample Makefile.pl
    use ExtUtils::MakeMaker;
    use Alien::PNG;

    WriteMakefile(
      NAME         => 'Any::PNG::Module',
      VERSION_FROM => 'lib/Any/PNG/Module.pm',
      LIBS         => Alien::PNG->config('libs', [-lAdd_Lib]),
      INC          => Alien::PNG->config('cflags'),
      # + additional params
    );

=head1 DESCRIPTION

Please see L<Alien> for the manifest of the Alien namespace.

In short C<Alien::PNG> can be used to detect and get
configuration settings from an installed PNG and related libraries.
Based on your platform it offers the possibility to download and
install prebuilt binaries or to build PNG & co. from source codes.

The important facts:

=over

=item * The module does not modify in any way the already existing PNG
installation on your system.

=item * If you reinstall PNG libs on your system you do not need to
reinstall Alien::PNG (providing that you use the same directory for
the new installation).

=item * The prebuild binaries and/or binaries built from sources are always
installed into perl module's 'share' directory.

=item * If you use prebuild binaries and/or binaries built from sources
it happens that some of the dynamic libraries (*.so, *.dll) will not
automaticly loadable as they will be stored somewhere under perl module's
'share' directory. To handle this scenario Alien::PNG offers some special
functionality (see below).

=back

=head1 METHODS

=head2 config()

This function is the main public interface to this module. Basic
functionality works in a very similar maner to 'libpng-config' script:

    Alien::PNG->config('prefix');   # gives the same string as 'libpng-config --prefix'
    Alien::PNG->config('version');  # gives the same string as 'libpng-config --version'
    Alien::PNG->config('libs');     # gives the same string as 'libpng-config --libs'
    Alien::PNG->config('cflags');   # gives the same string as 'libpng-config --cflags'

On top of that this function supports special parameters:

    Alien::PNG->config('ld_shared_libs');

Returns a list of full paths to shared libraries (*.so, *.dll) that will be
required for running the resulting binaries you have linked with PNG libs.

    Alien::PNG->config('ld_paths');

Returns a list of full paths to directories with shared libraries (*.so, *.dll)
that will be required for running the resulting binaries you have linked with
PNG libs.

    Alien::PNG->config('ld_shlib_map');

Returns a reference to hash of value pairs '<libnick>' => '<full_path_to_shlib'>,
where '<libnick>' is shortname for PNG related library like: PNG.

NOTE: config('ld_<something>') return an empty list/hash if you have decided to
use PNG libraries already installed on your system. This concerns 'libpng-config' 
detection and detection via '$PNG_INST_DIR/bin/libpng-config'.

=head2 check_header()

This function checks the availability of given header(s) when using compiler
options provided by "Alien::PNG->config('cflags')".

    Alien::PNG->check_header('png.h');
    Alien::PNG->check_header('png.h', 'pngconf.h');

Returns 1 if all given headers are available, 0 otherwise.

=head2 get_header_version()

Tries to find a header file specified as a param in PNG prefix direcotry and
based on "#define" macros inside this header file tries to get a version triplet.

    Alien::PNG->get_header_version('png.h');

Returns string like '1.2.3' or undef if not able to find and parse version info.

=head1 BUGS

Please post issues and bugs at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-PNG>

=head1 AUTHOR

    Tobias Leich
    CPAN ID: FROGGS
    FROGGS@cpan.org

=head1 ACKNOWLEDGEMENTS

    This module is based on Alien::SDL, so in fact the credits has to be given to these guys.
    kmx - complete redesign between versions 0.7.x and 0.8.x

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

### get config params
sub config
{
  my $package = shift;
  my @params  = @_;
  return _png_config_via_script(@params)      if(Alien::PNG::ConfigData->config('script'));
  return _png_config_via_config_data(@params) if(Alien::PNG::ConfigData->config('config'));
}

### get version info from given header file
sub get_header_version {
  my ($package, $header) = @_;
  return unless $header;

  # try to find header
  my $root = Alien::PNG->config('prefix');
  #warn 'Finding in '.$root.'/include';
  my $include = File::Spec->catfile($root, 'include');
  my @files;
  find({ wanted => sub { push @files, rel2abs($_) if /\Q$header\E$/ }, follow => 1, no_chdir => 1, follow_skip => 2 }, $include);
  return unless @files;

  # get version info
  open(DAT, $files[0]) || return;
  my @raw=<DAT>;
  close(DAT);

  # generic magic how to get version major/minor/patchlevel
  my ($v_maj) = grep(/^#define[ \t]+[A-Z_]+?MAJOR[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_maj =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_min) = grep(/^#define[ \t]+[A-Z_]+MINOR[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_min =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_pat) = grep(/^#define[ \t]+[A-Z_]+(PATCHLEVEL|MICRO|RELEASE)[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_pat =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  return if (($v_maj eq '')||($v_min eq '')||($v_pat eq ''));
  return "$v_maj.$v_min.$v_pat";
}

### check presence of header(s) specified as params
sub check_header {
  my ($package, @header) = @_;
  print STDERR "[$package] Testing header(s): " . join(', ', @header) . "\n";
  my $cb = ExtUtils::CBuilder->new(quiet => 1);
  my ($fs, $src) = File::Temp->tempfile('XXXXaa', SUFFIX => '.c', UNLINK => 1);
  my $inc = '';
  $inc .= "#include <$_>\n" for @header;  
  syswrite($fs, <<MARKER); # write test source code
#include <stdio.h>
#if defined(_WIN32) && !defined(__CYGWIN__)
/* GL/gl.h on Win32 requires windows.h being included before */
#include <windows.h>
#endif
$inc
int demofunc(void) { return 0; }

MARKER
  close($fs);
  #open OLDERR, ">&STDERR";
  #open STDERR, ">", File::Spec->devnull();  
  my $obj = eval { $cb->compile( source => $src, extra_compiler_flags => Alien::PNG->config('cflags')); };
  #open(STDERR, ">&OLDERR");
  if($obj) {
    unlink $obj;
    return 1;
  }
  else {
    print STDERR "###TEST FAILED### for: " . join(', ', @header) . "\n";
    return 0;
  }
}

### internal functions
sub _png_config_via_script
{
  my $param    = shift;
  my @add_libs = @_;
  my $devnull = File::Spec->devnull();
  my $script = Alien::PNG::ConfigData->config('script');
  return unless ($script && ($param =~ /[a-z0-9_]*/i));
  my $val = `$script --$param 2>$devnull`;
  $val =~ s/[\r\n]*$//;
  if($param eq 'cflags') {
    $val .= ' ' . Alien::PNG::ConfigData->config('additional_cflags');
  }
  elsif($param eq 'libs') {
    $val .= ' ' . join(' ', @add_libs) if scalar @add_libs;
    $val .= ' ' . Alien::PNG::ConfigData->config('additional_libs');
  }
  return $val;
}

sub _png_config_via_config_data
{
  my $param    = shift;
  my @add_libs = @_;
  my $share_dir = dist_dir('Alien-PNG');
  my $subdir = Alien::PNG::ConfigData->config('share_subdir');
  return unless $subdir;
  my $real_prefix = catdir($share_dir, $subdir);
  return unless ($param =~ /[a-z0-9_]*/i);
  my $val = Alien::PNG::ConfigData->config('config')->{$param};
  return unless $val;
  # handle additional flags
  if($param eq 'cflags') {
    $val .= ' ' . Alien::PNG::ConfigData->config('additional_cflags');
  }
  elsif($param eq 'libs') {
    $val .= ' ' . join(' ', @add_libs) if scalar @add_libs;
    $val .= ' ' . Alien::PNG::ConfigData->config('additional_libs');
  }  
  # handle @PrEfIx@ replacement
  if ($param =~ /^(ld_shared_libs|ld_paths)$/) {
    s/\@PrEfIx\@/$real_prefix/g foreach (@{$val});
  }
  elsif ($param =~ /^(ld_shlib_map)$/) {
    while (my ($k, $v) = each %$val ) {
      $val->{$k} =~ s/\@PrEfIx\@/$real_prefix/g;
    }
  }
  else {
    $val =~ s/\@PrEfIx\@/$real_prefix/g;
  }
  return $val;
}

1;
