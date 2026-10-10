package CPAN::Maker::Bootstrapper::Role::UpdateAvailable;

use strict;
use warnings;

use Carp qw(croak);
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use English qw(-no_match_vars);
use File::ShareDir qw(dist_dir);
use JSON;
use version;

use Role::Tiny;

########################################################################
sub _get_module_version {
########################################################################
  my ( $self, $module ) = @_;

  require HTTP::Tiny;

  my $rsp = HTTP::Tiny->new->get( 'https://fastapi.metacpan.org/v1/download_url/' . $module );

  croak sprintf "ERROR: could not fetch module (%s) version\n%s (%s)\n", $module, @{$rsp}{qw(reason status)}
    if !$rsp->{success};

  my $meta_info = decode_json( $rsp->{content} );

  return $meta_info->{version};
}

########################################################################
sub cmd_update_available {
########################################################################
  my ($self) = @_;

  my ($module) = $self->get_args;
  $module //= 'CPAN::Maker::Bootstrapper';

  my $latest_version = $self->_get_module_version($module);

  my $version = $CPAN::Maker::Bootstrapper::VERSION;

  print {*STDOUT} version->parse($latest_version) > version->parse($version) ? $latest_version : q{};

  return $SUCCESS;
}

1;
