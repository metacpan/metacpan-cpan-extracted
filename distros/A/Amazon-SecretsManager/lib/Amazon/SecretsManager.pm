package Amazon::SecretsManager;

use strict;
use warnings;

use parent qw/Amazon::API/;
use Data::UUID;

# https://docs.aws.amazon.com/secretsmanager/latest/apireference/Welcome.html

my @API_METHODS = qw{
  CancelRotateSecret
  CreateSecret
  DeleteResourcePolicy
  DeleteSecret
  DescribeSecret
  GetRandomPassword
  GetResourcePolicy
  GetSecretValue
  ListSecrets
  ListSecretVersionIds
  PutResourcePolicy
  PutSecretValue
  RemoveRegionsFromReplication
  ReplicateSecretToRegions
  RestoreSecret
  RotateSecret
  StopReplicationToReplica
  TagResource
  UntagResource
  UpdateSecret
  UpdateSecretVersionStage
  ValidateResourcePolicy
};

use vars qw/$VERSION @EXPORT/;

$VERSION = '1.0.0'; $VERSION=~s/\-.*$//;

@EXPORT = qw/$VERSION/;

use constant
  { AWS_API              => 'secretsmanager',
    AWS_API_VERSION      => undef,
    AWS_SERVICE_URL_BASE => 'secretsmanager',
    TRUE                 => 1,
    FALSE                => 0
  };

__PACKAGE__->main() if ! caller();

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  
  my %options;
  
  if ( @_ > 1) {
    %options =  @_;
  }
  elsif ( @_ ) {
    %options = %{$_[0]};
  }

  $class->SUPER::new(
    { decode_always    => TRUE,
      service_url_base => AWS_SERVICE_URL_BASE,
      version          => AWS_API_VERSION,
      api              => AWS_API,
      api_methods      => \@API_METHODS,
      content_type     => 'application/x-amz-json-1.1',
      debug            => $ENV{DEBUG} // FALSE,
      %options
    }
  );
}

sub CreateClientRequestToken {
  goto &create_client_request_token;
}

sub create_client_request_token {
  my ($self) = @_;
  
  return Data::UUID->new->create_str;
}

sub main {
  require Data::Dumper;
  require JSON::PP;

  JSON::PP->import(qw{ encode_json });
  
  Data::Dumper->import('Dumper');

  $Data::Dumper::Pair = ':';
  $Data::Dumper::Terse = 1;
  
  my $secrets_mgr = Amazon::SecretsManager->new;
  
  my $secret_list = $secrets_mgr->ListSecrets->{SecretList};
  
  print Dumper($secret_list);
    
  if ($secret_list) {
    my @names = map { $_->{Name} } @{$secret_list};

    if ( !grep {/my-secret/} @names ) {

      $secrets_mgr->CreateSecret(
        { Name               => 'my-secret',
          SecretString       => '$ecur1ty is not a secure!',
          ClientRequestToken => $secrets_mgr->CreateClientRequestToken
        }
      );

    } ## end if ( !grep {/my-secret/...})
    
    my $new_secret = encode_json({ a => 'b', b => 'a'});

    $secrets_mgr->UpdateSecret(
        { SecretId           => 'my-secret',
          SecretString       => $new_secret,
          ClientRequestToken => $secrets_mgr->CreateClientRequestToken
        }
      );
    
   print Dumper($secrets_mgr->GetSecretValue({ SecretId => 'my-secret' })->{SecretString});
  }
}

=pod

=head1 NAME

C<Amazon::SecretsManager>

=head1 SYNOPSIS


  my $secrets_mgr = Amazon::SecretsManager->new;
  
  my $secret_list = $secrets_mgr->ListSecrets->{SecretList};
      
  $secrets_mgr->CreateSecret(
      { Name               => 'my-secret',
        SecretString       => '$ecur1ty is not a secure!',
        ClientRequestToken => $secrets_mgr->CreateClientRequestToken
      }
    );
    
  $secrets_mgr->UpdateSecret(
      { SecretId           => 'my-secret',
        SecretString       => $new_secret,
        ClientRequestToken => $secrets_mgr->CreateClientRequestToken
      }
    );
    
 my $value = $secrets_mgr->GetSecretValue( { SecretId => 'my-secret' } );

=head1 METHODS

See the AWS SecretsManager documentation for a complete reference to the API.

L<AWS SecretsManager|https://docs.aws.amazon.com/secretsmanager/latest/apireference/Welcome.html>

=head1 

=head1 SEE OTHER

L<Amazon::API>, L<Amazon::API::Error>, L<Amazon::Credentials>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 LICENSE

(c) Copyright 2022 Robert C. Lauer. All rights reserved.  This module
is free software. It may be used, redistributed and/or modified under
the same terms as Perl itself.

=cut
  
1;
