package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

sub can_build_binaries_from_sources {
  my $self = shift;
  return 0; # no
}

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  die "###ERROR### Building from sources not supported on MS Windows platform";
}

sub get_path {
  my ( $self, $path ) = @_;
  $path = '"' . $path . '"';
  return $path;
}

sub get_additional_cflags {
  my $self = shift;
  if($My::Utility::cc eq 'cl' && $self->notes('env_include')) {
    my $include = $self->notes('env_include');
    $include    =~ s/"//g;
    my @include = split(/;/, $include);
    my $cflags  = '';
    my $inc = $_;
    for( @include ) {
      my $inc = eval { require Win32; Win32::GetShortPathName($_); };
      $inc ||= $_;
      $cflags    .= "-I\"$inc\" " ;
    }
    return $cflags;
  }
  return '';
}

sub get_additional_libs {
  my $self = shift;
  if($My::Utility::cc eq 'cl' && $self->notes('env_lib')) {
    my $lib  = $self->notes('env_lib');
    $lib     =~ s/"//g;
    my @libs = split(/;/, $lib);
    my $libs = '';
    my $inc  = $_;
    for( @libs ) {
      my $_lib = $self->escape_path( $_ );
      $libs   .= "/LIBPATH:$_lib " ;
    }
    return $libs;
  }
  return '';
}

sub escape_path {
  my( $self, $path ) = @_;
  my $_path          = eval { require Win32; Win32::GetShortPathName($path); };
  $_path           ||= $path;
  $_path             = qq("$_path") if $_path =~ / /;

  return $_path;
}

1;
