package CLI::Simple::Helpers;

use strict;
use warnings;

use parent qw(Exporter);

our @EXPORT_OK = qw(
  _class_to_dist
  _class_to_filename
  _cmd_to_role
  _extract_pod
  _find_module_path
  _generate_spec_yaml
  _is_class_name
  _main_module_stub
  _pm_path
  _resolve_spec
  _role_stub
  _spec_filename
  _sub_to_role
  _tarball_filename
);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

########################################################################
sub _class_to_dist {
########################################################################
  my ($class) = @_;

  ( my $dist = $class ) =~ s/::/-/gxsm;

  return $dist;
}

########################################################################
sub _class_to_filename {
########################################################################
  my ($class) = @_;

  return lc _class_to_dist($class);
}

########################################################################
sub _spec_filename {
########################################################################
  my ($class) = @_;

  return _class_to_filename($class) . '.yml';
}

########################################################################
sub _tarball_filename {
########################################################################
  my ($class) = @_;

  return _class_to_filename($class) . '-roles.tar.gz';
}

########################################################################
sub _pm_path {
########################################################################
  my ($package) = @_;

  ( my $path = "lib/$package.pm" ) =~ s|::|/|gxsm;

  return $path;
}

########################################################################
sub _extract_pod {
########################################################################
  my ($content) = @_;

  my @pods = $content =~ /(^=(?:pod|head\d|over|item|begin|for|encoding).+?^=cut)/gxsm;

  return join q{}, @pods;
}

########################################################################
sub _is_class_name {
########################################################################
  my ($value) = @_;

  return $value =~ /::/xsm;
}

########################################################################
sub _cmd_to_role {
########################################################################
  my ( $class, $cmd ) = @_;

  my $suffix = join q{::}, map { ucfirst lc $_ } split /[-_]/xsm, $cmd;

  return "${class}::Role::${suffix}";
}

########################################################################
sub _sub_to_role {
########################################################################
  my ( $class, $sub ) = @_;

  ( my $name = $sub ) =~ s/\Acmd_//xsm;

  return _cmd_to_role( $class, $name );
}

########################################################################
sub _resolve_spec {
########################################################################
  my ( $class, $commands, $option_specs ) = @_;

  # 1. explicit spec file from command line
  my $spec_file = $ARGV[1];

  if ($spec_file) {
    die "ERROR: spec file not found: $spec_file\n"
      if !-e $spec_file;

    require YAML::Tiny;
    return YAML::Tiny::LoadFile($spec_file);
  }

  # 2. conventional spec file in cwd
  my $default_spec = _spec_filename($class);

  if ( -e $default_spec ) {
    require YAML::Tiny;
    return YAML::Tiny::LoadFile($default_spec);
  }

  # 3. introspect from running module
  return {
    options  => $option_specs,
    commands => { map { $_ => $commands->{$_} } grep { !/\A-/xsm } keys %{$commands} },
  };
}

########################################################################
sub _generate_spec_yaml {
########################################################################
  my ( $class, $commands, $option_specs, $use_roles ) = @_;

  require YAML::Tiny;

  my %spec_commands;

  for my $cmd ( sort grep { !/\A-/xsm } keys %{$commands} ) {
    my $val = $commands->{$cmd};

    # resolve coderef to actual sub name regardless of mode
    my $sub_name;
    if ( ref $val ) {
      require B;
      my $cv = B::svref_2object($val);
      $sub_name = $cv->GV->NAME;
    }
    else {
      $sub_name = $val;
    }

    ( my $expected = "cmd_$cmd" ) =~ s/-/_/gxsm;

    if ( $use_roles && $sub_name eq $expected ) {
      # derive role from the actual sub name, not the command key
      # cmd_extract -> extract -> Pod::Extract::Role::Extract
      ( my $name = $sub_name ) =~ s/\Acmd_//xsm;
      $spec_commands{$cmd} = _cmd_to_role( $class, $name );
    }
    else {
      $spec_commands{$cmd} = $sub_name;
    }
  }

  # extra_options live in the class stash
  no strict 'refs'; ## no critic
  my $stash         = \%{ $class . '::' };
  my @extra_options = $stash->{EXTRA_OPTIONS} ? @{ ${ $stash->{EXTRA_OPTIONS} } } : ();

  return YAML::Tiny::Dump(
    { options       => $option_specs,
      extra_options => \@extra_options,
      commands      => \%spec_commands,
    }
  );
}

########################################################################
sub _main_module_stub {
########################################################################
  my ($class) = @_;

  my $stub = <<'END_MODULE';
package $class;

use strict;
use warnings;

use CLI::Simple qw(:roles);
use parent qw(CLI::Simple);

our $VERSION = '%s';

caller or exit __PACKAGE__->main;

1;
END_MODULE
  $stub = sprintf $stub, q{@} . 'PACKAGE' . q{@};  # to avoid replacement of PACKAGE_VERSION

  return _tidy_source($stub);
}

########################################################################
sub _role_stub {
########################################################################
  my ( $role, $method, $class ) = @_;

  my $stub = <<"END_ROLE";
package $role;

use strict;
use warnings;

use English qw(-no_match_vars);
use CLI::Simple::Constants qw(:booleans);
#use CLI::Simple::Utils qw(choose slurp slurp_json);
#use Cwd qw(abs_path getcwd);
#use File::Basename qw(basename dirname);

use Role::Tiny;

########################################################################
sub $method {
########################################################################
  my (\$self) = \@_;

  # TODO: migrated from $class - move implementation here
  die "ERROR: not yet implemented\\n";

  return \$SUCCESS;
}

1;
END_ROLE

  return _tidy_source($stub);
}

########################################################################
sub _find_module_path {
########################################################################
  my ($class) = @_;

  ( my $rel = $class ) =~ s|::|/|gxsm;
  $rel .= '.pm';

  # check %INC first - module is already loaded
  return $INC{$rel} if $INC{$rel};

  # fall back to @INC search
  for my $dir (@INC) {
    my $path = "$dir/$rel";
    return $path if -e $path;
  }

  return;
}

########################################################################
sub _tidy_source {
########################################################################
  my ($source) = @_;

  return $source if !eval { require Perl::Tidy; 1 };

  my $perltidyrc = glob('~/.perltidyrc');

  return $source if !$perltidyrc || !-e $perltidyrc;

  my $tidied = q{};
  my $errors = q{};

  Perl::Tidy::perltidy(
    source      => \$source,
    destination => \$tidied,
    stderr      => \$errors,
    perltidyrc  => $perltidyrc,
    argv        => [],
  );

  return length($tidied) ? $tidied : $source;
}

1;

__END__

