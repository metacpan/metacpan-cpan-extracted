# NAME

API::Google - Perl library for easy access to Google services via their API

# VERSION

version 0.12

# SYNOPSIS

    use API::Google;
    my $gapi = API::Google->new({ tokensfile => 'config.json' });
    
    $gapi->refresh_access_token_silent('someuser@gmail.com');
    
    $gapi->api_query({ 
      method => 'post', 
      route => 'https://www.googleapis.com/calendar/v3/calendars/'.$calendar_id.'/events',
      user => 'someuser@gmail.com'
    }, $json_payload_if_post);

# CONFIGURATION

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

# SUBROUTINES/METHODS

## refresh\_access\_token\_silent

Get new access token for user from Google API server and store it in jsonfile

## build\_headers

Keep access\_token in headers always actual 

$gapi->build\_http\_transactio($user);

## build\_http\_transaction 

$gapi->build\_http\_transaction({ 
  user => 'someuser@gmail.com',
  method => 'post',
  route => 'https://www.googleapis.com/calendar/users/me/calendarList',
  payload => { key => value }
})

## api\_query

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

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
