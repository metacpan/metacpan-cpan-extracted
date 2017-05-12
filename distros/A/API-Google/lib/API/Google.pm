package API::Google;
$API::Google::VERSION = '0.12';
use Data::Dumper;

# ABSTRACT: Perl library for easy access to Google services via their API


use strict;
use warnings;
use Mojo::UserAgent;
use Config::JSON;
use Data::Dumper;


sub new {
  my ($class, $params) = @_;
  my $h = {};
  if ($params->{tokensfile}) {
  	$h->{tokensfile} = Config::JSON->new($params->{tokensfile});
  } else {
  	die 'no json file specified!';
  }
  $h->{ua} = Mojo::UserAgent->new();
  $h->{debug} = $params->{debug};
  $h->{max_refresh_attempts} = $params->{max_refresh_attempts} || 5;
  return bless $h, $class;
}



sub refresh_access_token {
  my ($self, $params) = @_;
  warn "Attempt to refresh access_token with params: ".Dumper $params if $self->{debug};
  $params->{grant_type} = 'refresh_token';
  $self->{ua}->post('https://www.googleapis.com/oauth2/v4/token' => form => $params)->res->json; # tokens
};


sub client_id {
	shift->{tokensfile}->get('gapi/client_id');
}

sub ua {
  shift->{ua};
}


sub client_secret {
	shift->{tokensfile}->get('gapi/client_secret');
}



sub refresh_access_token_silent {
	my ($self, $user) = @_;
	my $tokens = $self->refresh_access_token({
		client_id => $self->client_id,
		client_secret => $self->client_secret,
		refresh_token => $self->get_refresh_token_from_storage($user)
	});
  warn "New tokens got" if $self->{debug};
	my $res = {};
	$res->{old} = $self->get_access_token_from_storage($user);
	warn Dumper $tokens if $self->{debug};
	if ($tokens->{access_token}) {
		$self->set_access_token_to_storage($user, $tokens->{access_token});
	}
	$res->{new} = $self->get_access_token_from_storage($user);
	return $res;
};


sub get_refresh_token_from_storage {
  my ($self, $user) = @_;
  warn "get_refresh_token_from_storage(".$user.")" if $self->{debug};
  return $self->{tokensfile}->get('gapi/tokens/'.$user.'/refresh_token');
};

sub get_access_token_from_storage {
  my ($self, $user) = @_;
  $self->{tokensfile}->get('gapi/tokens/'.$user.'/access_token');
};

sub set_access_token_to_storage {
  my ($self, $user, $token) = @_;
  $self->{tokensfile}->set('gapi/tokens/'.$user.'/access_token', $token);
};



sub build_headers {
  my ($self, $user) = @_;
  my $t = $self->get_access_token_from_storage($user);
  my $headers = {};
  $headers->{'Authorization'} = 'Bearer '.$t;
  return $headers;
}


sub build_http_transaction  {
  my ($self, $params) = @_;

  warn "build_http_transaction() params : ".Dumper $params if $self->{debug};

  my $headers = $self->build_headers($params->{user});
  my $http_method = $params->{method};
  my $tx;

  if ($http_method eq 'get' || $http_method eq 'delete') {
    $tx = $self->{ua}->build_tx(uc $http_method => $params->{route} => $headers);
  } elsif (($http_method eq 'post') && $params->{payload}) {
    $tx = $self->{ua}->build_tx(uc $http_method => $params->{route} => $headers => json => $params->{payload})
  } else {
    die 'wrong http_method on no payload if using POST';
  }
  return $tx;

}




sub api_query {
  my ($self, $params, $payload) = @_;

  warn "api_query() params : ".Dumper $params if $self->{debug};

  $payload = { payload => $payload };
  %$params = (%$params, %$payload);

  my $tx = $self->build_http_transaction($params);
  my $res = $self->{ua}->start($tx)->res->json;
    
  # for future:
  # if ( grep { $_->{message} eq 'Invalid Credentials' && $_->{reason} eq 'authError'} @{$res->{error}{errors}} ) { ... }

  warn "First api_query() result : ".Dumper $res if $self->{debug};

  if (defined $res->{error}) { # token expired error handling

    my $attempt = 1;

    while ($res->{error}{message} eq 'Invalid Credentials')  {
      if ($attempt == $self->{max_refresh_attempts}) {
        last;
      }
      warn "Seems like access_token was expired. Attemptimg update it automatically ..." if $self->{debug};
      $self->refresh_access_token_silent($params->{user});
      $tx = $self->build_http_transaction($params);
      $res = $self->{ua}->start($tx)->res->json;
      $attempt++;
    }

    if ($attempt > 1) {
      warn "access_token was automatically refreshed";
    }

  }

  return $res;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Google - Perl library for easy access to Google services via their API

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use API::Google;
    my $gapi = API::Google->new({ tokensfile => 'config.json' });
    
    $gapi->refresh_access_token_silent('someuser@gmail.com');
    
    $gapi->api_query({ 
      method => 'post', 
      route => 'https://www.googleapis.com/calendar/v3/calendars/'.$calendar_id.'/events',
      user => 'someuser@gmail.com'
    }, $json_payload_if_post);

=head1 CONFIGURATION

config.json must be structured like:

  { "gapi":
    {
      "client_id": "001122334455-abcdefghijklmnopqrstuvwxyz012345.apps.googleusercontent.com",
      "client_secret": "1ayL76NlEKjj85eZOipFZkyM",
      "tokens": {
          "email_1@gmail.com": {
              "refresh_token": "1/cI5jWSVnsUyCbasCQpDmz8uhQyfnWWphxvb1ST3oTHE",
              "access_token": "ya29.Ci-KA8aJYEAyZoxkMsYbbU9H_zj2t9-7u1aKUtrOtak3pDhJvCEPIdkW-xg2lRQdrA"
          },
          "email_2@gmail.com": {
              "access_token": "ya29.Ci-KAzT9JpaPriZ-ugON4FnANBXZexTZOz-E6U4M-hjplbIcMYpTbo0AmGV__tV5FA",
              "refresh_token": "1/_37lsRFSRaUJkAAAuJIRXRUueft5eLWaIsJ0lkJmEMU"
          }
      }
    }
  }

=head1 SUBROUTINES/METHODS

=head2 refresh_access_token_silent

Get new access token for user from Google API server and store it in jsonfile

=head2 build_headers

Keep access_token in headers always actual 

$gapi->build_http_transactio($user);

=head2 build_http_transaction 

$gapi->build_http_transaction({ 
  user => 'someuser@gmail.com',
  method => 'post',
  route => 'https://www.googleapis.com/calendar/users/me/calendarList',
  payload => { key => value }
})

=head2 api_query

Low-level method that can make API query to any Google service

Required params: method, route, user 

Examples of usage:

  $gapi->api_query({ 
      method => 'get', 
      route => 'https://www.googleapis.com/calendar/users/me/calendarList'',
      user => 'someuser@gmail.com'
    });

  $gapi->api_query({ 
      method => 'post', 
      route => 'https://www.googleapis.com/calendar/v3/calendars/'.$calendar_id.'/events',
      user => 'someuser@gmail.com'
  }, $json_payload_if_post);

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
