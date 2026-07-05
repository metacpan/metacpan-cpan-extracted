package CPAN::Maker::Role::ModuleUtils;

use CLI::Simple::Constants qw(:chars);
use ExtUtils::MM;

use Role::Tiny;

our $VERSION = '2.0.1';

########################################################################
sub make_path_from_module {
########################################################################
  my ( $self, $module ) = @_;

  my $file = join $SLASH, split /$DOUBLE_COLON/xsm, $module;

  return "$file.pm";
}

########################################################################
sub get_module_version {
########################################################################
  my ( $self, $module_w_version, @include_path ) = @_;

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

  $module_version{file} = $self->make_path_from_module($module);

  foreach my $prefix (@include_path) {
    my $path = $prefix . $SLASH . $module_version{file};

    next if !-e $path;

    my $version = eval { return ExtUtils::MM->parse_version($path); };
    @module_version{qw(path version)} = ( $path, $version // 0 );

    last;
  }

  return \%module_version;
}

1;
