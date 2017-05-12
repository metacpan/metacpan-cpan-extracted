package Confman::API;

use strict;
use IO::File;
use JSON;
use REST::Client;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);


sub new {
  my $class = shift;
  my $self = bless({}, ref($class) || $class);

  $self->{config_dir} ||= "/etc/confman";
  $self->{json} = JSON->new->allow_nonref;
  $self;
}

sub config_path {
  my $self = shift;
  return $self->{config_dir} . "/config.json"
}

sub api_key {
  my $self = shift;
  $self->{api_key} = shift if scalar(@_) > 0;
  return $self->{api_key};
}

sub secret {
  my $self = shift;
  $self->{secret} = shift if scalar(@_) > 0;
  return $self->{secret};
}

sub endpoint_url {
  my $self = shift;
  $self->{endpoint_url} = shift if scalar(@_) > 0;
  return $self->{endpoint_url};
}

sub load_config {
  my $self = shift;
  my $config_path = shift || $self->config_path;
  if(-e $config_path) {
    my $fh = IO::File->new($config_path);
    local $/ = undef;
    my $config = $self->json->decode(<$fh>);
    $fh->close();

    while(my ($key, $value) = each(%$config)) {
      $self->{$key} = $value;
    }
  }
  return $self;
}

sub find_by_name {
  my $self = shift;
  my $name = shift;

  my $results = $self->search(name => $name);
  return undef if($results->{count} == 0);
  my $conf_set_data = $results->{results}[0];
  return Confman::ConfSet->new(
    $self,
    %$conf_set_data
  );
}

sub search {
  my $self = shift;
  my %query = @_;

  my ($results, $response) = $self->request('GET', "confman/sets/search", \%query);
  return $results;
}


sub json { my $self = shift; $self->{json}; }

sub request {
  my $self = shift;
  my $method = shift;
  my $path = shift;
  my $object = shift;

  my $client = REST::Client->new();
  $client->getUseragent()->ssl_opts(verify_hostname => 0);

  my $timestamp = time();
  my $secret_hash = md5_hex($self->secret.":".$timestamp);

  my $body;
  if($method eq 'GET') {
    $path = $path.$client->buildQuery($object);
  }
  else {
    $body = $self->json->encode($object);
  }
  my $cloud_meta = encode_base64($self->json->encode($self->cloud_metadata));
  $cloud_meta =~ s/\s+//ism;
  my $headers = {
    Accept => 'application/json',
    'Content-type' => 'application/json',
    Authorization => 'Basic ' . encode_base64($self->api_key . ':' . "$secret_hash:$timestamp"),
    HTTP_CLOUD_META => $cloud_meta
  };

  $client->setHost($self->endpoint_url);
  $client->request($method, $path, $body, $headers);

  my $response;
  if($client->responseCode eq '200') {
    $response = $self->json->decode($client->responseContent());
  }
  return $response, $client;
}

sub cloud_metadata {
  my $self = shift;
  return if $self->{no_cloud};
  $self->{cloud_metadata} ||= $self->aws_metadata;
  $self->{cloud_metadata};
}

sub aws_metadata {
  my $self = shift;
  return $self->{aws_metadata} if $self->{aws_metadata};

  my @fields = qw(
      instance-id ami-id availability-zone
      instance-type
      kernel-id local-hostname
      mac public-hostname
  );

  $self->{aws_metadata} = {};

  my $client = REST::Client->new();
  $client->setHost("http://169.254.169.254/latest/meta-data");
  $client->setTimeout(1);

  foreach my $field (@fields) {
    $client->GET($field);
    if($client->responseCode() =~ /2\d\d/) {
      $self->{aws_metadata}{$field} = $client->responseContent();
      $self->{aws_metadata}{type} = 'aws';
    }
    elsif(scalar(keys %{$self->{aws_metadata}}) == 0) {
      last;
    }
  }

  return $self->{aws_metadata};
}


package Confman::ConfSet;

sub new {
  my $class = shift;
  my $api = shift;
  my %conf = @_;
  my $self = bless(\%conf, ref($class) || $class);
  $self->{api} = $api;

  {
    no strict 'refs';
    foreach my $key (keys %{$self->pairs}) {
      *{$class.'::'.$key} = sub {
        my $self = shift;
        $self->{pairs}{$key};
      } unless($self->can($key));
    }
  }

  $self;
}

sub update_pairs {
  my $self = shift;
  my %pairs = @_;
  my ($results, $response) = $self->api->request('PUT', "confman/sets/$self->{id}/update_pairs", {
      conf_pairs => \%pairs
  });
}

sub api {
  my $self = shift;
  return $self->{api};
}

sub pairs {
  my $self = shift;
  unless($self->{pairs}) {
    $self->{pairs} = {};
    foreach my $pair (@{$self->{conf_pairs}}) {
      $self->{pairs}{$pair->{name}} = $pair->{value};
    }
  }
  return $self->{pairs};
}

1;
