package App::RPi::EnvUI::Event;

use Async::Event::Interval;

our $VERSION = '0.30';

sub new {
    my ($class, %args) = @_;
    return bless {%args}, $class;
}
sub env_to_db {
    my ($self) = @_;

    my $db = App::RPi::EnvUI::DB->new(testing => $self->{testing});
    my $api = App::RPi::EnvUI::API->new(
        testing => $self->{testing},
        test_mock => 0
    );

    $api->{db} = $db;
    $self->{db} = $db;
    $self->{timeout} = $api->_config_control('event_timeout');

    my $event = Async::Event::Interval->new(
        $api->_config_core('event_fetch_timer'),
        sub {
            local $SIG{ALRM} = sub { kill 9, $$; };
            alarm $self->{timeout};
            my ($temp, $hum) = $api->read_sensor;
            alarm 0;
            $api->env($temp, $hum);
        },
    );

    return $event;
}
sub env_action {
    my ($self) = @_;

    my $db = App::RPi::EnvUI::DB->new(testing => $self->{testing});
    my $api = App::RPi::EnvUI::API->new(
        testing => $self->{testing},
        test_mock => 0
    );

    $api->{db} = $db;
    $self->{db} = $db;

    my $event = Async::Event::Interval->new(
        $api->_config_core('event_action_timer'),
        sub {
            my $t_aux = $api->env_temp_aux;
            my $h_aux = $api->env_humidity_aux;

            $api->action_temp($t_aux, $api->temp);
            $api->action_humidity($h_aux, $api->humidity);

            $api->action_light
              if $api->_config_light('enable');
        }
    );

    return $event;
}
1;
__END__

=head1 NAME

App::RPi::EnvUI::Event - Asynchronous events for the Perl portion of
L<App::RPi::EnvUI>

=head1 SYNOPSIS

    use App::RPi::EnvUI::API;
    use App::RPi::EnvUI::Event;

    my $api = App::RPi::EnvUI::API->new;
    my $events = App::RPi::EnvUI::Event->new;

    my $env_to_db_event  = $events->env_to_db;
    my $env_action_event = $events->env_action;

    $env_to_db_event->start;
    $env_action_event->start;

=head1 DESCRIPTION

This is a helper module for L<App::RPi::EnvUI>, which contains the scheduled
asynchronous Perl events on the server side of the webapp.

These events are objects of the L<Async::Event::Interval> class, and run in a
separate process than the rest of the application.

=head1 METHODS

=head2 new(%args)

Returns a new C<App::RPi::EnvUI::Event> object. The parameters are passed in
within a hash format.

Parameters:

    testing

Optional, Bool: C<0> disables testing mode, C<1> enables it.

=head2 env_to_db

Returns the event that polls the environment sensors, and updates the C<stats>
environment database table.

=head2 env_action

Returns the event that enables/disables the GPIO pins associated with the
environment.

=head1 SEE ALSO

L<Async::Event::Interval>

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.org<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

