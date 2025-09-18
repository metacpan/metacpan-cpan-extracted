package App::SecretsManager;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->mk_accessors(qw(profile region));

########################################################################
sub find_secret_arn {
########################################################################
  my ( $self, $secret_name ) = @_;

  my $result = $self->command(
    'list-secrets' => [
      '--filters' => 'Key=name,Values=' . $secret_name,
      '--query'   => 'SecretList[].{ARN:ARN}',
      '--output'  => 'text'
    ]
  );

  return $result;
}

1;
