package CPAN::Maker::Utils;

use strict;
use warnings;

use CPAN::Maker::Constants qw( :all );
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp_json);
use Data::Dumper;
use Module::CoreList;
use Scalar::Util qw(reftype);
use version;

our $VERSION = '2.0.4';

use parent qw(Exporter);

our @EXPORT = qw(is_core trim is_array is_hash is_scalar get_json_file);

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
sub get_json_file {
########################################################################
  my ($file) = @_;

  return slurp_json($file);
}

########################################################################
sub _is_obj {
########################################################################
  my ( $this, $type ) = @_;

  return ref $this && reftype($this) eq $type;
}

########################################################################
sub is_array {
########################################################################
  my ($this) = @_;

  return _is_obj( $this, 'ARRAY' );
}

########################################################################
sub is_scalar {
########################################################################
  my ($this) = @_;

  return !ref $this;
}

########################################################################
sub is_hash {
########################################################################
  my ($this) = @_;

  return _is_obj( $this, 'HASH' );
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
