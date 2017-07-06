package Alien::make::Module::Build;

use strict;
use warnings;
use 5.010;  # //

use base qw( Module::Build );

use File::Basename qw( dirname );
use File::Spec;
use File::Path 2.07 qw( make_path );

use constant SRCDIR => "src";

BEGIN {
   # GNU make is called 'gmake' on most non-Linux platforms, gnumake on Dariwn.
   # Rather than hardcode it we'll try to identify a suitable command by inspection
   foreach my $make (qw( make gmake gnumake )) {
      no warnings 'exec';
      my $output = `$make --version`;
      next if $?;
      next unless $output =~ m/^GNU Make /;

      constant->import( MAKE => $make );
      last;
   }

   # GNU libtool is called 'glibtool' on Darwin
   foreach my $libtool (qw( libtool glibtool )) {
      no warnings 'exec';
      my $output = `$libtool --version`;
      next if $?;
      next unless $output =~ m/^.*\(GNU libtool\)/;

      constant->import( LIBTOOL => $libtool );
      last;
   }
}

sub MAKEARGS { "LIBTOOL=".LIBTOOL() }

__PACKAGE__->add_property( 'tarball' );
__PACKAGE__->add_property( 'pkgconfig_module' );
__PACKAGE__->add_property( 'pkgconfig_version' );
__PACKAGE__->add_property( 'alien_requires' );

# Modules that this code itself requires
my %more_configure_requires = (
   'File::Basename' => 0,
   'File::Spec'     => 0,
   'File::Path'     => '2.07',
   'Module::Build'  => 0,
);

sub new
{
   my $class = shift;
   my %args = @_;

   my $use_bundled = 0;

   $args{get_options}{bundled} = {
      store => \$use_bundled,
      type  => "+",
   };


   my $self = $class->SUPER::new( %args );

   foreach my $req ( @{ $self->alien_requires || [] } ) {
      my $missing = $self->do_requires( @$req );
      die "OS unsupported - missing $missing\n" if defined $missing;
   }

   my @reqs = @{ $self->alien_requires || [] };
   while( @reqs ) {
      my ( $name, @args ) = @{ shift @reqs };

      push( @reqs, @args ), next if $name eq "any";

      $self->configure_requires->{"ExtUtils::CChecker"} //= 0 if $name eq "header";
   }

   $self->configure_requires->{$_} ||= $more_configure_requires{$_} for keys %more_configure_requires;

   my $module = $self->pkgconfig_module;
   my $version = $self->pkgconfig_version;

   $use_bundled = 1 if
      !$use_bundled and system( "pkg-config", $module, "--atleast-version", $version ) != 0;

   if( $use_bundled ) {
      die "OS unsupported - unable to find GNU make\n" unless defined &MAKE;
      die "OS unsupported - unable to find GNU libtool\n" unless defined &LIBTOOL;
      print "Building bundled source\n";
   }
   else {
      print "Detected $module version >= $version from pkg-config\n";
   }

   $self->notes( use_bundled => $use_bundled );

   return $self;
}

{
   my $eucc;

   sub cchecker
   {
      my $self = shift;
      return $eucc ||= do {
         require ExtUtils::CChecker;
         return ExtUtils::CChecker->new;
      };
   }
}

sub do_requires
{
   my $self = shift;
   my ( $name, @args ) = @_;

   my $code = $self->can( "do_requires_$name" ) or
      die "Unrecognised 'alien_requires' requirement type '$name'\n";

   return $self->$code( @args );
}

sub do_requires_any
{
   my $self = shift;
   my @alts = @_;

   my @missing;
   foreach my $alt ( @alts ) {
      my $ret = $self->do_requires( @$alt );
      return if !$ret;

      push @missing, $ret;
   }

   return $missing[0] if @missing < 2;
   return "either $missing[0] or $missing[1]" if @missing == 2;
   return "any of " . join( ", ", @missing[0 .. $#missing-1] ) . " or " . $missing[-1];
}

sub do_requires_pkgconfig
{
   my $self = shift;
   my ( $module, %args ) = @_;

   print "Looking for pkg-config $module... ";

   my @cmdline;
   push @cmdline, "--atleast-version=$args{atleast_version}" if defined $args{atleast_version};

   if( system( "pkg-config", $module, @cmdline ) == 0 ) {
      print "found\n";
      return;
   }

   print "not found\n";
   return "$module";
}

sub do_requires_header
{
   my $self = shift;
   my ( $header ) = @_;

   print "Looking for <$header>... ";

   my $success = $self->cchecker->try_compile_run(
      source => <<"EOC"
#include <$header>
int main(int argc, char *argv[]) {return 0;}
EOC
   );

   if( $success ) {
      print "found\n";
      return;
   }

   print "not found\n";
   return "<$header>";
}

sub _srcdir
{
   my $self = shift;
   return File::Spec->catdir( $self->base_dir, SRCDIR );
}

sub _stampfile
{
   my $self = shift;
   my ( $name ) = @_;

   return File::Spec->catfile( $self->base_dir, ".$name-stamp" );
}

sub in_srcdir
{
   my $self = shift;

   chdir( $self->_srcdir ) or
      die "Unable to chdir to srcdir - $!";

   shift->();
}

sub make_in_srcdir
{
   my $self = shift;
   my @args = @_;

   $self->in_srcdir( sub {
      system( MAKE(), MAKEARGS(), @args ) == 0 or
         die "Unable to make - $!";
   } );
}

sub ACTION_src
{
   my $self = shift;

   return unless $self->notes( 'use_bundled' );

   -d $self->_srcdir and return;

   my $tarball = $self->tarball;

   system( "tar", "xzf", $tarball ) == 0 or
      die "Unable to untar $tarball - $!";

   ( my $untardir = $tarball ) =~ s{\.tar\.[a-z]+$}{};

   -d $untardir or
      die "Expected to find a directory called $untardir\n";

   rename( $untardir, $self->_srcdir ) or
      die "Unable to rename src dir - $!";
}

sub ACTION_code
{
   my $self = shift;

   my $blib = File::Spec->catdir( $self->base_dir, "blib" );

   my $libdir = File::Spec->catdir( $blib, "arch" );
   my $incdir = File::Spec->catdir( $libdir, "include" );
   my $mandir = File::Spec->catdir( $blib, "libdoc" );

   # All these at least must exist
   -d $_ or mkdir $_ for $blib, $libdir;

   my $pkgconfig_module = $self->pkgconfig_module;

   my $buildstamp = $self->_stampfile( "build" );

   if( $self->notes( 'use_bundled' ) and !-f $buildstamp ) {
      $self->depends_on( 'src' );

      $self->make_in_srcdir( () );

      $self->make_in_srcdir( "install",
         "LIBDIR=$libdir",
         "INCDIR=$incdir",
         "MAN3DIR=$mandir",
         "MAN7DIR=$mandir",
      );

      open( my $stamp, ">", $buildstamp ) or die "Unable to touch .build-stamp file - $!";

      # Now hack the .pc file to put ${libdir}-relative paths in it
      my $pcfile = "$libdir/pkgconfig/$pkgconfig_module.pc";
      if( -f $pcfile ) {
         open my $in, "<", $pcfile or die "Cannot open $pcfile for reading - $!";
         open my $out, ">", "$pcfile.new" or die "Cannot open $pcfile.new for writing - $!";

         while( <$in> ) {
            s{\Q$libdir\E}{\${libdir}}g;
            print { $out } $_;
         }

         # Cygwin/Windows doesn't like it when you rename open files
         close $in;
         close $out;

         rename "$pcfile.new", $pcfile or die "Cannot rename $pcfile.new to $pcfile - $!";
      }
   }

   my @module_file = split m/::/, $self->module_name . ".pm";
   my $srcfile = File::Spec->catfile( $self->base_dir, "lib", @module_file );
   my $dstfile = File::Spec->catfile( $blib, "lib", @module_file );

   unless( $self->up_to_date( $srcfile, $dstfile ) ) {
      my %replace = (
         USE_BUNDLED      => $self->notes( 'use_bundled' ),
         PKGCONFIG_MODULE => $pkgconfig_module,
      );

      # Turn ' into \' in replacements
      s/'/\\'/g for values %replace;

      $self->cp_file_with_replacement(
         srcfile => $srcfile,
         dstfile => $dstfile,
         replace => \%replace,
      );
   }
}

sub cp_file_with_replacement
{
   my $self = shift;
   my %args = @_;

   my $srcfile = $args{srcfile};
   my $dstfile = $args{dstfile};
   my $replace = $args{replace};

   make_path( dirname( $dstfile ), { mode => 0777 } );

   open( my $inh,  "<", $srcfile ) or die "Cannot read $srcfile - $!";
   open( my $outh, ">", $dstfile ) or die "Cannot write $dstfile - $!";

   while( my $line = <$inh> ) {
      $line =~ s/\@$_\@/$replace->{$_}/g for keys %$replace;
      print $outh $line;
   }
}

sub ACTION_test
{
   my $self = shift;

   return unless $self->notes( 'use_bundled' );

   $self->depends_on( "code" );

   $self->make_in_srcdir( "test" );
}

sub ACTION_clean
{
   my $self = shift;

   if( $self->notes( 'use_bundled' ) ) {
      if( -d $self->_srcdir ) {
         $self->make_in_srcdir( "clean" );
      }

      unlink( $self->_stampfile( "build" ) );
   }

   $self->SUPER::ACTION_clean;
}

sub ACTION_realclean
{
   my $self = shift;

   if( -d $self->_srcdir ) {
      system( "rm", "-rf", $self->_srcdir ); # best effort; ignore failure
   }

   $self->SUPER::ACTION_realclean;
}

0x55AA;
