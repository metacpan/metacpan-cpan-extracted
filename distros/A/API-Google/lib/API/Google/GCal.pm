package API::Google::GCal;
$API::Google::GCal::VERSION = '0.12';

use parent 'API::Google';
# use base 'API::Google';

# ABSTRACT: Google Calendar API client




sub new {
    my ($class, $params) = @_;
    my $self = API::Google->new($params);
    $self->{api_base} = 'https://www.googleapis.com/calendar/v3';
    bless $self, $class;
    return $self; # just for clearance
}


sub get_calendars {
  my ($self, $user, $fields) = @_;
  my $res = $self->api_query({ 
  	method => 'get', 
  	route => $self->{api_base}.'/users/me/calendarList',
  	user => $user
  });

  if ($fields) {
    my @a;
    for my $item (@{$res->{items}}) {
        push @a, { map { $_ => $item->{$_} } grep { exists $item->{$_} } @$fields }; 
    }
    return \@a;
  } else {
    return $res;
  }
}


sub get_calendar_id_by_name {
    my ($self, $user, $name) = @_;
    my $all = $self->get_calendars($user, ['id', 'summary']);   # arr ref
    my @n = grep { $_->{'summary'} eq $name } @$all;
    my $full_id = $n[0]->{id};
    return $full_id;
}



sub add_event {
    my ($self, $user, $calendar_id, $event_data) = @_;
    $self->api_query({ 
      method => 'post', 
      route => $self->{api_base}.'/calendars/'.$calendar_id.'/events',
      user => $user
    }, $event_data);
}



sub busy_time_ranges {
   my ($self, $params) = @_;
    $self->api_query({ 
      method => 'post', 
      route => $self->{api_base}.'/freeBusy',
      user => $params->{user}
    }, {
      timeMin => $params->{dt_start},
      timeMax => $params->{dt_end},
      timeZone => $params->{timeZone},
      items => [{ 'id' => $params->{calendarId} }]
    });
};




sub events_list {
   my ($self, $params) = @_;

   if (!defined $params->{calendarId}) { die "No calendarId provided as parameter"}
   if (!defined $params->{user}) { die "No user  provided as parameter"}
   
   my $res = $self->api_query({ 
      method => 'get', 
      route => $self->{api_base}.'/calendars/'.$params->{calendarId}.'/events',
      user => $params->{user}
    });

   if (defined $res->{items}) { return $res->{items} };
   if (defined $res->{error}) { return $res };
};




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Google::GCal - Google Calendar API client

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use API::Google::GCal;
    my $gapi = API::Google::GCal->new({ tokensfile => 'config.json' });
      
    my $user = 'someuser@gmail.com';
    my $calendar_id = 'ooqfhagr1a91u1510ffdf7vfpk@group.calendar.google.com';
    my $timeZone = 'Europe/Moscow';
    my $event_start = DateTime->now->set_time_zone($timeZone);
    my $event_end = DateTime->now->add_duration( DateTime::Duration->new( hours => 2) );

    $gapi->refresh_access_token_silent($user); # inherits from API::Google

    $gapi->get_calendars($user);
    $gapi->get_calendars($user, ['id', 'summary']);  # return only specified fields

    $gapi->get_calendar_id_by_name($user, 'Contacts');

    my $event_data = {};
    $event_data->{summary} = 'Exibition';
    $event_data->{description} = 'Amazing cats exibition';
    $event_data->{location} = 'Angels av. 13';
    $event_data->{start}{dateTime} = DateTime::Format::RFC3339->format_datetime($event_start);  # '2016-11-11T09:00:00+03:00' format
    $event_data->{end}{dateTime} = DateTime::Format::RFC3339->format_datetime($event_end);
    $event_data->{start}{timeZone} = $event_data->{end}{timeZone} = $timeZone; # not obligatory

    $gapi->add_event($user, $calendar_id, $event_data);

    my $freebusy_data = {
      user => $user,
      calendarId => $calendar_id,
      dt_start => DateTime::Format::RFC3339->format_datetime($event_start),
      dt_end => DateTime::Format::RFC3339->format_datetime($event_end),
      timeZone => 'Europe/Moscow'
    };

    $gapi->busy_time_ranges($freebusy_data);

    $gapi->events_list($freebusy_data);

=head2 get_calendars

Get all calendars of particular Google account

=head2 get_calendar_id_by_name

$gapi->get_calendar_id_by_name($user, $name)

Get calendar id by its name. Name = "summary" parameter

=head2 add_event

$gapi->add_event($user, $calendar_id, $event_data)

# https://developers.google.com/google-apps/calendar/v3/reference/events/insert

=head2 busy_time_ranges

Return List of time ranges during which this calendar should be regarded as busy. 

=head2 events_list

Return list of events in particular calendar

L<https://developers.google.com/google-apps/calendar/v3/reference/events/list>

Usage:

$gapi->events_list({
  calendarId => 'ooqfhagr1a91u1510ffdf7vfpk@group.calendar.google.com',
  user => 'someuser@gmail.com'
});

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
