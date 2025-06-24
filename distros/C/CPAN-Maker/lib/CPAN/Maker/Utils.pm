package CPAN::Maker::Utils;

use strict;
use warnings;

use parent qw( Exporter );

our @EXPORT_OK   = qw( trim make_path_from_module get_module_version is_core );
our %EXPORT_TAGS = ( 'all' => [@EXPORT_OK], );

our $VERSION = '1.5.46';  ## no critic (RequireInterpolationOfMetachars)

use CPAN::Maker::Constants qw( :all );

use Data::Dumper;
use ExtUtils::MM;
use Module::CoreList;
use version;

########################################################################
sub make_path_from_module {
########################################################################
  my ($module) = @_;

  my $file = join $SLASH, split /$DOUBLE_COLON/xsm, $module;

  return "$file.pm";
}

########################################################################
sub get_module_version {
########################################################################
  my ( $module_w_version, @include_path ) = @_;

  if ( !@include_path ) {
    @include_path = $DOT;
  }

  my ( $module, $version ) = split /\s+/xsm, $module_w_version;

  my %module_version = (
    module  => $module,
    version => $version,
    path    => undef,
  );

  return \%module_version
    if $version;

  $module_version{'file'} = make_path_from_module($module);

  foreach my $prefix (@include_path) {
    my $path = $prefix . $SLASH . $module_version{'file'};

    next if !-e $path;

    $module_version{'path'} = $path;

    $module_version{'version'}
      = eval { return ExtUtils::MM->parse_version($path) // 0; };

    last;
  }

  return \%module_version;
}

########################################################################
sub is_core {
########################################################################
  my ( $module_w_version, $perl_version ) = @_;

  my ( $module, $version ) = split /\s/xsm, $module_w_version;

  if ($perl_version) {
    $perl_version = version->parse($perl_version);
  }

  my @ms = Module::CoreList->find_modules( qr/\A$module\z/xsm, $perl_version );

  return $FALSE
    if !@ms;

  # is core and we don't care about version
  return $TRUE
    if @ms && ( !$perl_version || !$version );

  my $modules = Module::CoreList->find_version($perl_version);

  # return false if the version we want is > then provided by CORE
  if ( version->parse($version) > version->parse( $modules->{$module} ) ) {
    return $FALSE;
  }

  return $TRUE;
}

########################################################################
sub trim {
########################################################################
  my ($s) = @_;

  chomp $s;

  $s =~ s/^\s*(.*?)$/$1/xsm;

  return $s;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CPAN/Maker/Utils - utilities to support CPAN::Maker

=head1 SYNOPSIS

 use CPAN::Maker::Utils qw(is_core);

=head1 DESCRIPTION

Set of utilities to support `make-cpan-dist` project.

=head1 METHODS AND SUBROUTINES

=head2 get_module_version

 get_module_version(module, [include-paths])

If you pass a list
of include paths, the function will look for the module in those
paths. Returns a hash with information about the module.

=over 5

=item version

The module version. The version is found using
C<ExtUtils::MM::parse_version> (this may be an undocumented function
not for public consumption).

=item module

The module name.

=item path

The fully qualifed path where the module was found.

=back

=head2 is_core

 is_core(module, [perl-version])

Returns a boolean true value if the module is core. If C<perl-version>
is provided it returns true if the module was included in that version
of Perl.

A module is determined to be core using C<Module::CoreList>.

=head2 make_path_from_module

 make_path_from_module(module)

Returns the pathname for module by replacing the double-colon with '/'
and adding '.pm' to the end of the string.

=head2 trim

 trim(str)

Strip leading whitespace from string.

=head1 SEE ALSO

L<CPAN::Maker>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
