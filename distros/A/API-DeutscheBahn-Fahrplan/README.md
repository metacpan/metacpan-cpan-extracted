# NAME

API::DeutscheBahn::Fahrplan - Deutsche Bahn Fahrplan API Client

# SYNOPSIS

    my $fahrplan_free = API::DeutscheBahn::Fahrplan->new;
    my $fahrplan_plus = API::DeutscheBahn::Fahrplan->new( access_token => $access_token );

    $data = $fahrplan->location( name => 'Berlin' );
    $data = $fahrplan->arrival_board( id => 8503000, date => '2018-09-24T11:00:00' );
    $data = $fahrplan->departure_board( id => 8503000, date => '2018-09-24T11:00:00' );
    $data = $fahrplan->journey_details( id => '87510%2F49419%2F965692%2F453678%2F80%3fstation_evaId%3D850300' );

# DESCRIPTION

API::DeutscheBahn::Fahrplan provides a simple interface to the Deutsche Bahn Fahrplan
API. See [https://developer.deutschebahn.com/](https://developer.deutschebahn.com/) for further information.

# ATTRIBUTES

- fahrplan\_free\_url

    URL endpoint for DB Fahrplan free version. Defaults to _https://api.deutschebahn.com/freeplan/v1_.

- fahrplan\_plus\_url

    URL endpoint for DB Fahrplan subscribed version. Defaults to _https://api.deutschebahn.com/fahrplan-plus/v1_.

- access\_token

    Access token to sign requests. If provided the client will use the `fahrplan_plus_url` endpoint.

# METHODS

## location

    $fahrplan->location( name => 'Berlin' );

Fetch information about locations matching the given name or name fragment.

## arrival\_board

    $fahrplan->arrival_board( id => 8503000, date => '2018-09-24T11:00:00' );

Fetch the arrival board at a given location at a given date and time. The date
parameter should be in the ISO-8601 format.

## departure\_board

    $fahrplan->departure_board( id => 8503000, date => '2018-09-24T11:00:00' );

Fetch the departure board at a given location at a given date and time. The date
parameter should be in the ISO-8601 format.

## journey\_details

    $fahrplan->journey_details( id => '87510%2F49419%2F965692%2F453678%2F80%3fstation_evaId%3D850300' );

Retrieve details of a journey for a given id.

# LICENSE

Copyright (C) Edward Francis.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Edward Francis <edwardafrancis@gmail.com>
