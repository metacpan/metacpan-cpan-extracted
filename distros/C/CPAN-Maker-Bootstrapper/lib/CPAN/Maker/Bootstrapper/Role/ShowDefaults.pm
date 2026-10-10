package CPAN::Maker::Bootstrapper::Role::ShowDefaults;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(choose);
use Cwd qw(abs_path);

use Data::Dumper;
use English qw(-no_match_vars);
use File::HomeDir;
use Role::Tiny;

########################################################################
sub cmd_show_defaults {
########################################################################
  my ($self) = @_;

  my $defaults = $self->_resolve_defaults;

  foreach my $default ( sort { $a->[0] cmp $b->[0] } @{$defaults} ) {
    my ( $name, $value ) = @{$default};

    if ( !defined $value || $value eq q{} ) {
      $value = '<not set>';
    }

    printf "%-20s %s\n", $name, $value;
  }

  return $SUCCESS;
}

########################################################################
sub _resolve_defaults {
########################################################################
  my ($self) = @_;

  my $installdir = $self->get_installdir;

  if ( !$installdir ) {
    $installdir = sprintf '%s/{module-name}', $self->get_basedir;
  }

  my $reader = $self->get_reader;

  my @config = (
    [ config_source      => $self->get_config ],
    [ basedir            => $self->get_basedir ],
    [ installdir         => $installdir ],
    [ username           => $self->get_username ],
    [ email              => $self->get_email ],
    [ github_user        => $self->get_github_user ],
    [ resources          => $self->get_resources ],
    [ color              => $self->get_color ? 'on' : 'off' ],
    [ llm_api_key_helper => $self->get_llm_api_key_helper ],
    [ max_tokens         => $self->get_max_tokens ],
    [ max_diff_files     => $self->get_max_diff_files ],
  );

  my $syntax_checking = choose {
    return $ENV{SYNTAX_CHECKING}
      if exists $ENV{SYNTAX_CHECKING};

    return $reader->cpan_maker_syntax_checking
      if $reader && defined $reader->cpan_maker_syntax_checking;

    return;
  };

  push @config, [ syntax_checking => $syntax_checking ];

  my $home = File::HomeDir->my_home;

  my $perltidyrc = choose {
    return abs_path( $ENV{PERLTIDYRC} )
      if $ENV{PERLTIDYRC} && -e abs_path( $ENV{PERLTIDYRC} );

    return $reader->cpan_maker_perltidyrc
      if $reader && defined $reader->cpan_maker_perltidyrc;

    return abs_path('.perltidyrc')
      if -e '.perltidyrc';

    return abs_path('perltidyrc')
      if -e 'perltidyrc';

    return "$home/.perltidyrc"
      if -e "$home/.perltidyrc";

    return;
  };

  push @config, [ perltidyrc => $perltidyrc ];

  my $perlcriticrc = choose {
    return abs_path( $ENV{PERLCRITICRC} )
      if $ENV{PERLCRITICRC} && -e abs_path( $ENV{PERLCRITICRC} );

    return $reader->cpan_maker_perlcriticrc
      if $reader && defined $reader->cpan_maker_perlcriticrc;

    return abs_path('.perlcriticrc')
      if -e '.perlcriticrc';

    return abs_path('perlcriticrc')
      if -e 'perlcriticrc';

    return "$home/.perlcriticrc"
      if -e "$home/.perlcriticrc";

    return;
  };

  push @config, [ perlcriticrc => $perlcriticrc ];

  return \@config;
}

1;
