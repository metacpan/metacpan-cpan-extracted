package CPAN::Maker::Bootstrapper::Role::CreateBuildConfig;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(choose);
use Cwd qw(abs_path);
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Which;

use Role::Tiny;

########################################################################
sub cmd_create_build_config {
########################################################################
  my ($self) = @_;

  my $config = $self->_build_config;

  foreach my $name ( sort keys %{$config} ) {
    my $value = $config->{$name} // q{};
    print {*STDOUT} sprintf "%s := %s\n", $name, $value;
  }

  return $SUCCESS;
}

########################################################################
sub _build_config {
########################################################################
  my ($self) = @_;

  my $module_name = choose {
    return $ENV{MODULE_NAME}
      if $ENV{MODULE_NAME};

    my $module_name = basename abs_path q{.};
    $module_name =~ s{-}{::}gxsm;

    return $module_name;
  };

  my $module_path = File::Spec->catfile( 'lib', split( /::/xsm, $module_name ), ) . '.pm';

  my $project_name = $module_name;
  $project_name =~ s{::}{-}gxsm;

  my $unit_test_name = File::Spec->catfile( 't', sprintf q{00-%s.t}, lc $project_name, );

  my %defaults = map { $_->[0] => $_->[1] } @{ $self->_resolve_defaults };

  my %config = (
    MODULE_NAME           => $module_name,
    MODULE_PATH           => $module_path,
    PROJECT_NAME          => $project_name,
    UNIT_TEST_NAME        => $unit_test_name,
    BASEDIR               => $defaults{basedir},
    PERLTIDYRC            => $defaults{perltidyrc},
    PERLCRITICRC          => $defaults{perlcriticrc},
    SYNTAX_CHECKING       => $defaults{syntax_checking},
    BOOTSTRAPPER_DIST_DIR => dist_dir('CPAN-Maker-Bootstrapper'),
  );

  my %helpers = (
    PERL           => [ perl            => 'perl' ],
    PERLTIDY       => [ perltidy        => 'perltidy' ],
    PERLCRITIC     => [ perlcritic      => 'perlcritic' ],
    PODCHECKER     => [ podchecker      => 'podchecker' ],
    CPM            => [ cpm             => 'cpm' ],
    CARTON         => [ carton          => 'carton' ],
    BOOTSTRAPPER   => [ cmb             => 'cmb' ],
    DOCKER         => [ docker          => 'docker' ],
    GIT            => [ git             => 'git' ],
    CPAN_MAKER     => [ cpan_maker      => 'cpan-maker' ],
    MD_UTILS       => [ markdown_render => 'markdown-render' ],
    POD2MARKDOWN   => [ pod2markdown    => 'pod2markdown' ],
    PODEXTRACT     => [ podextract      => 'podextract' ],
    SCANDEPS       => [ scandeps_static => 'scandeps-static' ],
    GITHUB_ACTIONS => [ gha_aws         => 'gha-aws' ],
  );

  my $reader = $self->get_reader;

  for my $name ( sort keys %helpers ) {
    my ( $key, $command ) = @{ $helpers{$name} };

    $config{$name} = $self->_resolve_helper( $reader, $key, $command, );
  }

  if ( !$defaults{perltidyrc} ) {
    $config{PERLTIDY} = q{};
  }

  if ( !$defaults{perlcriticrc} ) {
    $config{PERLCRITIC} = q{};
  }

  return \%config;
}

########################################################################
sub _resolve_helper {
########################################################################
  my ( $self, $reader, $key, $command ) = @_;

  if ($reader) {
    # present in config, including empty string
    return $reader->get_config->{helpers}{$key}
      if exists $reader->get_config->{helpers} && exists $reader->get_config->{helpers}{$key};
  }

  # otherwise discover
  return which($command);
}

1;
