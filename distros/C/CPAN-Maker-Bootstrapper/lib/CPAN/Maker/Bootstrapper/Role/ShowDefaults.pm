package CPAN::Maker::Bootstrapper::Role::ShowDefaults;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use English;
use Role::Tiny;

########################################################################
sub cmd_show_defaults {
########################################################################
  my ($self) = @_;

  my $installdir = $self->get_installdir;

  if ( !$installdir ) {
    $installdir = sprintf '%s/{module-name}', $self->get_basedir;
  }

  my @defaults = (
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

  foreach my $default ( sort { $a->[0] cmp $b->[0] } @defaults ) {
    my ( $name, $value ) = @{$default};

    if ( !defined $value || $value eq q{} ) {
      $value = '<not set>';
    }

    printf "%-20s %s\n", $name, $value;
  }

  return $SUCCESS;
}

1;
