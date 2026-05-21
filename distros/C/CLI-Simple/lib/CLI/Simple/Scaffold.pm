package CLI::Simple::Scaffold;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Helpers qw(:all);
use English qw(-no_match_vars);

use parent qw(Exporter);

our @EXPORT_OK = qw(_cmd_scaffold);

########################################################################
sub _cmd_scaffold {
########################################################################
  my ( $class, $commands, $option_specs ) = @_;

  require Archive::Tar;
  require YAML::Tiny;

  my $spec_file = $ARGV[1];

  my ( $spec, $effective_class );

  if ( $spec_file && -e $spec_file ) {
    $spec = YAML::Tiny::LoadFile($spec_file);

    # derive class from spec filename: cpan-maker-bootstrapper.yml -> Cpan::Maker::Bootstrapper
    ( my $stem = $spec_file ) =~ s/[.]ya?ml\z//xsm;
    $effective_class = join '::', map { ucfirst $_ } split /-/xsm, $stem;
  }
  else {
    my $yaml = _generate_spec_yaml( $class, $commands, $option_specs, $TRUE );
    $spec            = YAML::Tiny::Load($yaml);
    $effective_class = $class;
  }

  # use effective_class for all naming
  my $tarball = _tarball_filename($effective_class);
  my $dist    = _class_to_filename($effective_class);

  my $tar = Archive::Tar->new;

  my $main_stub = _main_module_stub($effective_class);

  my $source_path = _find_module_path($effective_class);

  if ( $source_path && -e $source_path ) {
    local $RS = undef;

    open my $fh, '<', $source_path or die "ERROR: $OS_ERROR\n";
    my $pod = _extract_pod(<$fh>);
    close $fh;
    if ($pod) {
      $main_stub .= "\n$pod";
    }
    $main_stub .= "\n" if $main_stub !~ /\n\z/xsm;
  }

  $tar->add_data( _pm_path($effective_class), $main_stub );

  my %seen_roles;

  for my $cmd ( sort keys %{ $spec->{commands} } ) {
    my $value = $spec->{commands}{$cmd};
    my $role  = _is_class_name($value) ? $value : _sub_to_role( $effective_class, $value );

    next if $seen_roles{$role}++;

    # derive method name from role class, not command key
    # Pod::Extract::Role::Extract -> Extract -> cmd_extract
    ( my $method_suffix = $role ) =~ s/\A.*::Role:://xsm;
    $method_suffix =~ s/::/_/gxsm;
    my $method = 'cmd_' . lc $method_suffix;

    $tar->add_data( _pm_path($role), _role_stub( $role, $method, $effective_class ) );
  }

  # spec yaml into share/
  $tar->add_data( "$dist.yml", YAML::Tiny::Dump($spec), );

  # help out the bootstrapper...
  my @role_paths = map { _pm_path($_); } keys %seen_roles;

  my $main_pm = _pm_path($effective_class);

  ( my $role_dir = $effective_class ) =~ s|::|/|gxsm;
  $role_dir = "lib/$role_dir/Role";

  my $project_mk = <<"END_MK";
# inter-module dependencies
\$(eval \$(call find-files,ROLES,$role_dir,*.pm.in))

$main_pm: \\
  \$(ROLES)
END_MK

  $tar->add_data( 'project.mk', $project_mk );
  $tar->write( $tarball, Archive::Tar::COMPRESS_GZIP() );

  printf {*STDOUT} "created %s\n", $tarball;

  return $SUCCESS;
}

1;

__END__
