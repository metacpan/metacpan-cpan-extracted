package App::RPi::EnvUI::API;

use App::RPi::EnvUI::DB;
use App::RPi::EnvUI::Event;
use Carp qw(confess);
use Crypt::SaltedHash;
use Data::Dumper;
use DateTime;
use JSON::XS;
use Logging::Simple;
use Mock::Sub no_warnings => 1;
use RPi::Const qw(:all);

our $VERSION = '0.29';

# mocked sub handles for when we're in testing mode

our ($temp_sub, $hum_sub, $wp_sub, $pm_sub);

# class variables

my $api;
my $master_log;
my $log;
my $sensor;
my $events;

# public environment methods

sub new {

    # return the stored object if we've already run new()

    if (defined $api){
        $log->_5('returning stored API object');
        return $api if defined $api;
    }

    my $self = bless {}, shift;

    my $caller = (caller)[0];
    $self->_args(@_, caller => $caller);

    $self->_init;

    $api = $self;

    $log->_5("successfully initialized the system");

    if (! $self->testing && ! defined $events){
        $self->events;
        $log->_5('successfully created new async events')
    }
    else {
        $log->_5("async events have already been spawned");
    }

    return $self;
}
sub action_humidity {
    my ($self, $aux_id, $humidity) = @_;

    my $log = $log->child('action_humidity');
    $log->_6("aux: $aux_id, humidity: $humidity");

    my $limit = $self->_config_control('humidity_limit');
    my $min_run = $self->_config_control('humidity_aux_on_time');

    $log->_6("limit: $limit, minimum runtime: $min_run");

    if (! $self->aux_override($aux_id) && $humidity != -1){
        if ($humidity < $limit && $self->aux_time($aux_id) == 0) {
            $log->_5("humidity limit reached turning $aux_id to HIGH");
            $self->aux_state($aux_id, HIGH);
            $self->aux_time($aux_id, time());
        }
        if ($humidity >= $limit && $self->aux_time($aux_id) >= $min_run) {
            $log->_5("humidity above limit setting $aux_id to LOW");

            $self->aux_state($aux_id, LOW);
            $self->aux_time($aux_id, 0);
        }
        $self->switch($aux_id);
    }
}
sub action_temp {
    my ($self, $aux_id, $temp) = @_;

    my $log = $log->child('action_temp');

    my $limit = $self->_config_control('temp_limit');
    my $min_run = $self->_config_control('temp_aux_on_time');

    $log->_6("limit: $limit, minimum runtime: $min_run");

    if (! $self->aux_override($aux_id) && $temp != -1){
        if ($temp > $limit && $self->aux_time($aux_id) == 0){
            $log->_5("temp limit reached turning $aux_id to HIGH");
            $self->aux_state($aux_id, HIGH);
            $self->aux_time($aux_id, time);
        }
        elsif ($temp <= $limit && $self->aux_time($aux_id) >= $min_run){
            $log->_5("temp below limit setting $aux_id to LOW");
            $self->aux_state($aux_id, LOW);
            $self->aux_time($aux_id, 0);
        }
        $self->switch($aux_id);
    }
}
sub action_light {
    my ($self, %test_conf) = @_;

    my $log = $log->child('action_light');

    my $aux      = $self->_config_control('light_aux');
    my $pin      = $self->aux_pin($aux);
    my $override = $self->aux_override($aux);

    return if $override;

    my $on_time  = $self->_config_light('on_time');
    my $off_time = $self->_config_light('off_time');

    my $on_hours = defined $test_conf{on_hours}
        ? $test_conf{on_hours}
        : $self->_config_light('on_hours');

    my $now = defined $test_conf{now} ? $test_conf{now} : time;

    if (($on_hours == 24) || ($now > $on_time && $now < $off_time)){
        if (! $self->aux_state($aux)){
            $self->aux_state($aux, ON);
            pin_mode($pin, OUTPUT);
            write_pin($pin, HIGH);
        }
    }
    elsif ($self->aux_state($aux)){
        $self->aux_state($aux, OFF);
        pin_mode($pin, OUTPUT);
        write_pin($pin, LOW);
        $self->set_light_times;
    }
}
sub aux {
    my ($self, $aux_id) = @_;

    my $log = $log->child('aux');

    $log->_7("getting aux information for $aux_id");

    my $aux = $self->db->aux($aux_id);
    return $aux;
}
sub auxs {
    my $self = shift;

    my $log = $log->child('auxs');
    $log->_7("retrieving all auxs");

    return $self->db->auxs;
}
sub aux_id {
    my ($self, $aux) = @_;

    my $log = $log->child('aux_id');
    $log->_7("aux ID is $aux->{id}");

    return $aux->{id};
}
sub aux_override {
    my $self = shift;
    # sets a manual override flag if an aux is turned on manually (via button)

    my ($aux_id, $override) = @_;

    my $log = $log->child('aux_override');

    if ($aux_id !~ /^aux/){
        confess "aux_override() requires an aux ID as its first param\n";
    }

    if (defined $override){
        $log->_5("attempted override of aux: $aux_id");
        my $toggle = $self->aux($aux_id)->{toggle};

        if ($toggle != 1){
            $log->_5(
                "toggling of aux id $aux_id is disabled in the config file"
            );
            return -1;
        }
    }

    if (defined $override){
        $log->_5("override set operation called for $aux_id");
        $override = $self->aux_override($aux_id) ? 0 : 1;
        $log->_5("override set to $override for aux id: $aux_id");
        $self->db->update('aux', 'override', $override, 'id', $aux_id);
    }
    return $self->aux($aux_id)->{override};
}
sub aux_pin {
    my $self = shift;
    # returns the auxillary's GPIO pin number
    my ($aux_id, $pin) = @_;

    if ($aux_id !~ /^aux/){
        confess "aux_pin() requires an aux ID as its first param\n";
    }

    if (defined $pin){
        $self->db->update('aux', 'pin', $pin, 'id', $aux_id);
    }
    return $self->aux($aux_id)->{pin};
}
sub aux_state {
    my $self = shift;
    # maintains the auxillary state (on/off)

    my ($aux_id, $state) = @_;

    my $log = $log->child('aux_state');

    if ($aux_id !~ /^aux/){
        confess "aux_state() requires an aux ID as its first param\n";
    }

    if (defined $state){
        $log->_5("setting state to $state for $aux_id");
        $self->db->update('aux', 'state', $state, 'id', $aux_id);
    }

    $state = $self->aux($aux_id)->{state};
    $log->_6("$aux_id state = $state");
    return $state;
}
sub aux_time {
    my $self = shift;
    # maintains the auxillary on time

    my ($aux_id, $time) = @_;

    if ($aux_id !~ /^aux/){
        confess "aux_time() requires an aux ID as its first param\n";
    }

    if (defined $time) {
        $self->db->update('aux', 'on_time', $time, 'id', $aux_id);
    }

    my $on_time = $self->aux($aux_id)->{on_time};
    my $on_length = time() - $on_time;
    return $on_time == 0 ? 0 : $on_length;
}
sub env {
    my ($self, $temp, $hum) = @_;

    if (@_ != 1 && @_ != 3){
        confess "env() requires either zero params, or two\n";
    }

    if (defined $temp){
        if ($temp !~ /^\d+$/){
            confess "env() temp param must be an integer\n";
        }
        if ($hum !~ /^\d+$/){
            confess "env() humidity param must be an integer\n";
        }
    }

    if (defined $temp){
        $self->db->insert_env($temp, $hum);
    }

    my $event_error = 0;

    if ($self->{events}{env_to_db}->status == -1){
        $event_error = 1;
        print "event failure!\n";
    }

    my $ret = $self->db->env;

    return {temp => -1, humidity => -1, error => $event_error} if ! defined $ret;

    $ret->{error => $event_error};

    return $ret;
}
sub graph_data {
    my ($self) = @_;

    my $graph_data = $self->db->graph_data;

    my $check = 1;
    my $count = 0;
    my %data;

    my $need = 5760 - @$graph_data; # approx 4 per min, for 24 hours (4*60*24)

    for (@$graph_data) {

        # we need to pad out to get to 24 hours worth of valid data

        if ($need){
            my $last_t = $_->[2];
            my $last_h = $_->[3];
            while($need){
                push @{ $data{temp} }, [ $count, $last_t ];
                push @{ $data{humidity} }, [ $count, $last_h ];
                $need--;
                $count++;
            }
        }
        
        next if $_->[2] > 120;
        last if $count == 300;
        push @{ $data{temp} }, [ $count, $_->[2] ];
        push @{ $data{humidity} }, [ $count, $_->[3] ];

        $count++;
        $check++;
    }

    return \%data;
}
sub humidity {
    my $self = shift;
    return $self->env->{humidity};
}
sub read_sensor {
    my $self = shift;

    my $log = $log->child('read_sensor');

    if (! defined $self->sensor){
        confess "\$self->{sensor} is not defined";
    }
    my $temp = $self->sensor->temp('f');
    my $hum = $self->sensor->humidity;

    $log->_6("temp: $temp, humidity: $hum");

    return ($temp, $hum);
}
sub switch {
    my ($self, $aux_id) = @_;

    my $log = $log->child('switch');

    my $state = $self->aux_state($aux_id);
    my $pin = $self->aux_pin($aux_id);

    if ($pin != -1){
        if ($state){
            $log->_6("set $pin state to HIGH");
            pin_mode($pin, OUTPUT);
            write_pin($pin, HIGH);
        }
        else {
            $log->_6("set $pin state to LOW");
            pin_mode($pin, OUTPUT);
            write_pin($pin, LOW);
        }
    }
}
sub temp {
    my $self = shift;
    return $self->env->{temp};
}

# public core operational methods

sub auth {
    my ($self, $user, $pw) = @_;

    if (! defined $user){
        confess "\n\nauth() requires a username sent in\n\n";
    }

    if (! defined $pw){
        confess "\n\nauth() requires a password sent in\n\n";

    }
    my $csh = Crypt::SaltedHash->new(algorithm => 'SHA1');

    my $crypted = $self->db->user($user)->{pass};

    return $csh->validate($crypted, $pw);
}
sub events {
    my $self = shift;

    my $log = $log->child('events');

    $events = App::RPi::EnvUI::Event->new($self->testing);

    $self->{events}{env_to_db} = $events->env_to_db;
    $self->{events}{env_action} = $events->env_action;

    $self->{events}{env_to_db}->start;
    $self->{events}{env_action}->start;

    $log->_5("events successfully started");
}
sub log {
    my $self = shift;
    $master_log->file($self->log_file) if $self->log_file;
    $master_log->level($self->log_level);
    return $master_log;
}
sub passwd {
    my ($self, $pw) = @_;

    if (! defined $pw){
        confess "\n\nplain text password string required\n\n";
    }

    my $csh = Crypt::SaltedHash->new(
        algorithm => 'SHA1',
    );

    $csh->add($pw);

    my $salted = $csh->generate;

    return $salted;
}
sub user {
    my ($self, $un) = @_;

    if (! defined $un){
        confess "\n\nuser() requires a username to be sent in\n\n";
    }

    return $self->db->user($un);
}

# public configuration getters

sub env_humidity_aux {
    my $self = shift;
    return $self->_config_control('humidity_aux');
}
sub env_temp_aux {
    my $self = shift;
    return $self->_config_control('temp_aux');
}
sub set_light_times {
    my ($self) = @_;

    my $on_at = $self->_config_light('on_at');

    my $time = time;
    $time += 30 until localtime($time) =~ /$on_at:/;

    my $hrs = $self->_config_light('on_hours');

    my $on_time = $time;
    my $off_time = $on_time + $hrs * 3600;

    my $now = time;

    if ($now > ($on_time - 86400) && $now < ($off_time - 86400)){
        $on_time -= 24 * 3600;
        $off_time -= 24 * 3600;
    }

    $self->db->update('light', 'value', $on_time, 'id', 'on_time');
    $self->db->update('light', 'value', $off_time, 'id', 'off_time');

}

# public instance variable methods

sub config {
    $_[0]->{config_file} = $_[1] if defined $_[1];
    return $_[0]->{config_file} || 'config/envui.json';
}
sub db {
    my ($self, $db) = @_;
    $self->{db} = $db if defined $db;
    return $self->{db};
}
sub debug_sensor {
    my ($self, $bool) = @_;

    if (defined $bool){
        $self->{debug_sensor} = $bool;
    }

    return $self->{debug_sensor};
}
sub log_file {
    my ($self, $fn) = @_;

    if (defined $fn){
        $self->{log_file} = $fn;
    }

    return $self->{log_file};
}
sub log_level {
    my ($self, $level) = @_;

    if (defined $level){
        if ($level < -1 || $level > 7){
            warn "log level has to be between 0 and 7... disabling logging\n";
            $level = -1;
        }
        $self->{log_level} = $level;
    }

    return $self->{log_level};
}
sub sensor {
    my ($self, $sensor) = @_;
    $self->{sensor} = $sensor if defined $sensor;
    return $self->{sensor};
}
sub testing {
    my ($self, $bool) = @_;

    if (defined $bool){
        $self->{testing} = $bool;
    }
    return $self->{testing};
}
sub test_mock {
    my ($self, $mock) = @_;

    if (defined $mock){
        $self->{test_mock} = $mock;
    }
    $self->{test_mock} = 1 if ! defined $self->{test_mock};
    return $self->{test_mock};
}

# private

sub _args {
    my ($self, %args) = @_;
    $self->debug_sensor($args{debug_sensor});
    $self->config($args{config_file});
    $self->log_file($args{log_file});
    $self->log_level($args{log_level});
    $self->testing($args{testing});
    $self->test_mock($args{test_mock});
}
sub _bool {
    # translates javascript true/false to 1/0

    my ($self, $bool) = @_;
    confess
      "bool() needs either 'true' or 'false' as param\n" if ! defined $bool;
    return $bool eq 'true' ? 1 : 0;
}
sub _config_control {
    my $self = shift;
    my $want = shift;
    return $self->db->config_control($want);
}
sub _config_core {
    my $self = shift;
    my $want = shift;

    if (! defined $self->db){
        confess "API's DB object is not defined.";
    }

    if (! defined $want){
        confess "_config_core() requires a \$want param\n";
    }
    return $self->db->config_core($want);
}
sub _config_light {
    my $self = shift;
    my $want = shift;

    my %conf;

    my $light = $self->db->config_light;

    for (keys %$light){
        if ($_ eq 'on_hours'){
            my $on_hrs = $light->{on_hours}->{value};
            if ($on_hrs !~ /^\d+$/ || $on_hrs < 0 || $on_hrs > 24){
                confess "\n\non_hours config file directive must be between ".
                        "0 and 24\n\n"
            }
        }
        $conf{$_} = $light->{$_}{value};
    }

    if (defined $want){
        return $conf{$want};
    }

    return \%conf;
}
sub _init {
    my ($self) = @_;

    $self->db(
        App::RPi::EnvUI::DB->new(
            testing => $self->testing
        )
    );

    $self->log_level($self->_config_core('log_level'));
    $self->_log;

    my $log = $log->child('_init()');

    if ($self->_ui_test_mode || $self->testing){
        $log->_5('in test mode');
        $self->_test_mode
    }
    else {
        $log->_5('in prod mode');
        $self->_prod_mode;
    }
}
sub _test_mode {
    my ($self) = @_;

    my $log = $log->child('_test_mode');
    $log->_6("testing mode");

    $self->testing(1);
    $self->db(App::RPi::EnvUI::DB->new(testing => 1));
    $self->config('t/envui.json');
    $self->_parse_config;


    if ($self->test_mock) {
        my $mock = Mock::Sub->new;

        $temp_sub = $mock->mock(
            'RPi::DHT11::temp',
            return_value => 80
        );

        $log->_6( "mocked RPi::DHT11::temp" );

        $hum_sub = $mock->mock(
            'RPi::DHT11::humidity',
            return_value => 20
        );

        $log->_6( "mocked RPi::DHT11::humidity" );

        $pm_sub = $mock->mock(
            'App::RPi::EnvUI::API::pin_mode',
            return_value => 'ok'
        );

        $wp_sub = $mock->mock(
            'App::RPi::EnvUI::API::write_pin',
            return_value => 'ok'
        );
    }

    $log->_5(
        "mocked WiringPi::write_pin as App::RPi::EnvUI::API::write_pin"
    );

    warn "API in test mode\n";

    $self->sensor(bless {}, 'RPi::DHT11');

    $log->_5("blessed a fake sensor");

}
sub _prod_mode {
    my ($self) = @_;

    my $log = $log->child('_prod_mode');

    $self->_parse_config;

    if (! exists $INC{'WiringPi/API.pm'} && ! $self->testing){
        require WiringPi::API;
        WiringPi::API->import(qw(:perl));
    }
    if (! exists $INC{'RPi/DHT11.pm'} && ! $self->testing){
        require RPi::DHT11;
        RPi::DHT11->import;
    }
    $log->_6("required/imported WiringPi::API and RPi::DHT11");

    if (! defined $sensor){
        $sensor =  RPi::DHT11->new(
            $self->_config_core('sensor_pin'), $self->debug_sensor
        );
    }

    $self->sensor($sensor);
    $log->_6("instantiated a new RPi::DHT11 sensor object");
}
sub _log {
    my ($self) = @_;

    # configures the class-level log

    $master_log = Logging::Simple->new(
        name => 'EnvUI',
        print => 1,
        file => $self->log_file,
        level => $self->log_level
    );

    $log = $master_log->child('API');
}
sub _parse_config {
    my ($self, $config) = @_;

    $self->db->begin;

    $self->_reset;

    $config = $self->config if ! defined $config;

    if (! -e $config){
        confess "\n\nconfig file '$config' not found...\n\n";
    }

    my $json;
    {
        local $/;
        open my $fh, '<', $config or confess $!;
        $json = <$fh>;
    }
    my $conf = decode_json $json;

    # auxillary channels

    { # pin numbers

        my $db_struct = [
            'aux',
            'pin',
            'id',
        ];
        my @data;

        for (1 .. 8) {
            my $aux_id = "aux$_";
            my $pin = $conf->{$aux_id}{pin};
            push @data, [$pin, $aux_id];
        }

        $self->db->update_bulk(@$db_struct, \@data);
    }

    { # aux toggle

        my $db_struct = [
            'aux',
            'toggle',
            'id',
        ];
        my @data;

        for (1 .. 8) {
            my $aux_id = "aux$_";
            my $toggle = $conf->{$aux_id}{toggle};
            push @data, [$toggle, $aux_id];
        }

        $self->db->update_bulk(@$db_struct, \@data);
    }

    for my $conf_section (qw(control core light)){
        my $db_struct = [
            $conf_section,
            'value',
            'id'
        ];
        my @data;

        for my $directive (keys %{ $conf->{$conf_section} }){
            push @data, [
                $conf->{$conf_section}{$directive},
                $directive
            ];

            # populate some internal variables from the 'core'
            # config section

            if ($conf_section eq 'core'){
                next if $directive eq 'testing';
                $self->{$directive} = $conf->{$conf_section}{$directive};
            }
        }

        $self->db->update_bulk(@$db_struct, \@data);
    }

    $self->db->commit;
}
sub _reset {
    my $self = shift;
    # reset dynamic db attributes

    my $log = $log->child('_reset');
    $log->_5("reset() called");

    $self->db->update_bulk_all(
        'aux', 'state', [0]
    );
    $self->db->update_bulk_all(
        'aux', 'override', [0]
    );
    $self->db->update_bulk_all(
        'aux', 'on_time', [0]
    );

    # remove all statistics

    $self->db->delete('stats');
}
sub _ui_test_mode {
    return -e 't/testing.lck';
}

true;
__END__

=head1 NAME

App::RPi::EnvUI::API - Core API abstraction class for the
App::RPi::EnvUI web app

=head1 SYNOPSIS

    my $api = App::RPi::EnvUI::API->new;

    ... #FIXME: add a real example

=head1 DESCRIPTION

This class can be used outside of the L<App::RPi::EnvUI> web application to
update settings, read statuses, perform analysis and generate reports.

It's primary purpose is to act as an intermediary between the web app itself,
the asynchronous events that run within their own processes, the environment
sensors, and the application database.

=head1 METHODS

=head2 new(%args)

Instantiates a new core API object. Send any/all parameters in within hash
format (eg: C< testing =\> 1)).

Parameters:

    config

Optional, String. Name of the configuration file to use. Very rarely required.

Default: C<config/envui.json>

    testing

Optional, Bool. Send in C<1> to enable testing, C<0> to disable it.

Default: C<0>

    test_mock

This flag is only useful when C<testing> param is set to true, and should only
be used when writing unit tests for the L<App::RPi::EnvUI::Event> class. Due to
the way the system works, the API has to avoid mocking out items in test mode,
and the mocks have to be set within the test file itself. Do not use this flag
unless you are writing unit tests.

    log_level

Optional, Integer. Send in a level of C<0-7> to enable logging.

Default: C<-1> (logging disabled)

    log_file

Optional, String. Name of file to log to. We log to C<STDOUT> by default. The
C<log_level> parameter must be changed from default for this parameter to have
any effect.

Default: C<undef>

    debug_sensor

Optional, Bool. Enable/disable debug print output from the L<RPi::DHT11> sensor
code. Send in C<1> to enable, and C<0> to disable.

Default: C<0> (off)

=head2 action_humidity($aux_id, $humidity)

Performs the check of the current humidity against the configured set limit, and
enables/disables any devices attached to the humidity auxillary GPIO pin, if
set.

Parameters:

    $aux_id

Mandatory, String. The string name representation of the humidity auxillary. By
default, this will be C<aux2>.

    $humidity

Mandatory: Integer. The integer value of the current humidity (typically
supplied by the C<RPi::DHT11> hygrometer sensor.

=head2 action_light($dt)

Performs the time calculations on the configured light on/off event settings,
and turns the GPIO pin associated with the light auxillary channel on and off as
required.

Parameters (only used for testing):

    %args

Optional (use for testing only!). Pass in a hash with the desired configuration
parameters as found in the configuration file for light configuration.

=head2 action_temp($aux_id, $temperature)

Performs the check of the current temperature against the configured set limit,
and enables/disables any devices attached to the temp auxillary GPIO pin, if
set.

Parameters:

    $aux_id

Mandatory, String. The string name representation of the temperature auxillary.
By default, this will be C<aux1>.

=head2 auth($user, $pw)

Checks whether a user is supplying the correct password.

Parameters:

    $user

Mandatory, String. The user name to validate the password for.

    $pw

Mandatory, String. The plain text password to verify.


Return: True (C<1>) if successful, C<undef> otherwise.

=head2 aux($aux_id)

Retrieves from the database a hash reference that contains the details of a
specific auxillary channel, and returns it.

Parameters:

    $aux_id

Mandatory, String. The string name representation of the auxillary channel to
retrieve (eg: C<aux1>).

Returns: Hash reference with the auxillary channel details.

=head2 auxs

Fetches the details of all the auxillary channels from the database. Takes no
parameters.

Return: A hash reference of hash references, where each auxillary channel name
is a key, and the value is a hash reference containing that auxillary channel's
details.

=head2 aux_id($aux)

Extracts the name/ID of a specific auxillary channel.

Parameters:

    $aux

Mandatory, href. A hash reference as returned from a call to C<aux()>.

Return: String. The name/ID of the specified auxillary channel.

=head2 aux_override($aux_id, $override)

Sets/gets the override status of a specific aux channel.

The override functionality is a flag in the database that informs the system
that automated triggering of an auxillary GPIO pin should be bypassed due to
user override.

Parameters:

    $aux_id

Mandatory, String. The string name of an auxillary channel (eg: C<aux1>).

    $state

Optional, Bool. C<0> to disable an aux pin override, C<1> to enable it.

Return: Bool. Returns the current status of the aux channel's override flag.

=head2 aux_pin($aux_id, $pin)

Associates a GPIO pin to a specific auxillary channel.

Parameters:

    $aux_id

Mandatory, String. The string name of an auxillary channel (eg: C<aux1>).

    $pin

Optional, Integer. The GPIO pin number that you want associated with the
specified auxillary channel.

Return: The GPIO pin number associated with the auxillary channel specified.

=head2 aux_state($aux_id, $state)

Sets/gets the state (ie. on/off) value of a specific auxillary channel's GPIO
pin.

Parameters:

    $aux_id

Mandatory, String. The string name of an auxillary channel (eg: C<aux1>).

    $state

Optional, Bool. C<0> to turn the pin off (C<LOW>), or C<1> to turn it on
(C<HIGH>).

Return: Bool. Returns the current state of the aux pin.

=head2 aux_time($aux_id, $time)

Sets/gets the length of time an auxillary channel's GPIO pin has been C<HIGH>
(on). Mainly used to determine timers.

Parameters:

    $aux_id

Mandatory, String. The string name of an auxillary channel (eg: C<aux1>).

    $time

Optional, output from C<time()>. If sent in, we'll set the start time of a pin
on event to this.

Return, Integer (seconds). Returns the elapsed time in seconds since the last
timestamp was sent in with the C<$time> parameter, after being subtracted with
a current C<time()> call. If C<$time> has not been sent in, or an internal timer
has reset this value, the return will be zero (C<0>).

=head2 config($conf_file)

Sets/gets the currently loaded configuration file.

Parameters:

    $conf_file

Optional, String. The name of a configuration file. This is only useful on
instantiation of a new object.

Default: C<config/envui.json>

Returns the currently loaded configuration file name.

=head2 db($db_object)

Sets/gets the internal L<App::RPi::EnvUI::DB> object. This method allows you to
swap DB objects (and thereby DB handles) within separate processes.

Parameters:

    $db_object

Optional, L<App::RPi::EnvUI::DB> object instance.

Returns: The currently loaded DB object instance.

=head2 debug_sensor($bool)

Enable/disable L<RPi::DHT11> sensor's debug print output.

Parameters:

    $bool

Optional, Bool. C<1> to enable debugging, C<0> to disable.

Return: Bool. The current state of the sensor's debug state.

Default: False (C<0>)

=head2 env($temp, $humidity)

Sets/gets the current temperature and humidity pair.

Parameters:

All parameters are optional, but if one is sent in, both must be sent in.

    $temp

Optional, Integer. The current temperature.

    $humidity

Optional, Integer. The current humidity .

Return: A hash reference in the format C<{temp => Int, humidity => Int}>

=head2 env_humidity_aux

Returns the string name of the humidity auxillary channel (default: C<aux2>).
Takes no parameters.

=head2 env_temp_aux

Returns the string name of the temperature auxillary channel (default: C<aux1>).
Takes no parameters.

=head2 events

Initializes and starts the asynchronous timed events that operate in their own
processes, performing actions outside of the main thread.

Takes no parameters, has no return.

=head2 graph_data

Returns a hash reference with keys C<temp> and C<humidity>, where the values of
each are an array reference of array references with the inner arefs containing
the element number and the temp/humidity value.

It attempts to fetch data for 24 hours, sampling approximately every minute. If
no data is found far enough back, the temp/humidity will be set to C<0>.

=head2 humidity

Returns as an integer, the current humidity level.

=head2 temp

Returns as an integer, the current temperature level.

=head2 set_light_time

Sets in the database the values for lights-on and lights-off time.

Takes no parameters, there is no return.

=head2 log

Returns a pre-configured L<Logging::Simple> object, ready to be cloned with its
C<child()> method.

=head2 log_file($filename)

Sets/gets the log file for the internal logger.

Parameters:

    $filename

Optional, String. The name of the log file to use. Note that this won't have any
effect when used in user space, and is mainly a convenience method. It's used
when instantiating a new object.

Return: The string name of the currently in-use log file, if set.

=head2 log_level($level)

Sets/gets the current logging level.

Parameters:

    $level

Optional, Integer. Sets the logging level between C<0-7>.

Return: Integer, the current level.

Default: C<-1> (logging disabled)

=head2 passwd($pw)

Generates an SHA-1 hashed password.

Parameters:

    $pw

Mandatory, String. A plain text string (the password).

Return: SHA-1 hashed password string.

=head2 read_sensor

Retrieves and returns the current temperature and humidity within an array of
two integers.

=head2 sensor($sensor)

Sets/gets the current hygrometer sensor object. This method is here so that for
testing, we can send in mocked sensor objects.

Parameters:

    $sensor

Optional, L<RPi::DHT11> object instance.

Return: The sensor object.

=head2 set_light_times

Internal method that sets the light on-off times in the database, once on webapp
initial startup, then at the end of the lights-off trigger in C<action_light()>.

=head2 switch($aux_id)

Enables/disables the GPIO pin associated with the specified auxillary channel,
based on what the current state of the pin is. If it's currently off, it'll be
turned on, and vice-versa.

Parameters:

    $aux_id

Mandatory, String. The string name of the auxillary channel to have it's GPIO
pin switched (eg: C<aux1>).

Return: none

=head2 testing($bool)

Used primarily internally, sets/gets whether we're in testing mode or not.

Parameters:

    $bool

Optional, Bool. C<0> for production mode, and C<1> for testing mode.

Return: Bool, whether we're in testing mode or not.

=head2 test_mock($bool)

This is for use internally when testing the L<App::RPi::EnvUI::Event> module.
Normally, the API mocks out items for testing, but in C<Event>'s case, the test
file itself has to do the mocking.

Parameters:

    $bool

Optional, Bool. C<0> to disable, C<1> to enable.

Default: C<1>, enabled (the API will mock in test mode)

=head2 user($user)

Fetches a user's details.

Parameters:

    $user

Mandatory, String. The username of the user to fetch details for.

Return: href, the hash reference containing user details per the 'user' database
table.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.org<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

