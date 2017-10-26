package App::RPi::EnvUI;

use App::RPi::EnvUI::API;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Core::Request;
use Data::Dumper;
use Mock::Sub no_warnings => 1;
use POSIX qw(tzset);

our $VERSION = '0.29';

my $db = App::RPi::EnvUI::DB->new;
my $api = App::RPi::EnvUI::API->new(db => $db);

$ENV{TZ} = $api->_config_core('time_zone');
tzset();

my $log = $api->log->child('webapp');

$api->_config_light;
$api->set_light_times;

#
# fetch routes
#

get '/' => sub {
        my $log = $log->child('/');
        $log->_5("in /home");
        return template 'main';
    };

# fetch graph code

get '/graph_data' => sub {
        return to_json $api->graph_data;
    };

post '/login' => sub {
        my $user = params->{username};
        my $pass = params->{password};

        my ($success, $realm) = authenticate_user($user, $pass);

        if ($success){
            session logged_in_user => $user;
            session logged_in_user_realm => $realm;
            redirect '/';
        }
    };

any '/logout' => sub {
        app->destroy_session;
        redirect '/';
    };

get '/logged_in' => sub {
        if (session 'logged_in_user' || request->address eq '127.0.0.1'){
            return to_json { status => 1 };
        }
        return to_json {status => 0};
    };

get '/time' => sub {
        my ($y, $m, $d, $h, $min) = (localtime)[5, 4, 3, 2, 1];

        $y += 1900;

        for ($m, $d, $h, $min){
            $_ = "0$_" if length $_ < 2;
        }

        return "$y-$m-$d $h:$min";
    };

get '/stats' => sub {
        return template 'stats';
    };

get '/light' => sub {
        my $log = $log->child('/light');
        $log->_6("/light");
        return to_json $api->_config_light;
    };

get '/get_config/:want' => sub {
        my $want = params->{want};
        my $log = $log->child('/get_config');
        my $value = $api->_config_core($want);
        $log->_5("param: $want, value: $value");
        return $value;
    };

get '/get_control/:want' => sub {
        my $want = params->{want};
        my $log = $log->child('/get_control');
        my $value = $api->_config_control($want);
        $log->_5("param: $want, value: $value");
        return $value;
    };
get '/get_aux/:aux' => sub {
        my $aux_id = params->{aux};

        my $log = $log->child('/get_aux');
        $log->_7("fetching aux object for $aux_id");

        $api->switch($aux_id);

        return to_json $api->aux($aux_id);
    };
get '/fetch_env' => sub {
        my $log = $log->child('/fetch_env');

        my $data = $api->env;
         
        $log->_6(
            "temp: $data->{temp}, humidity: $data->{humidity}"
        );

        return to_json {
            temp => $data->{temp},
            humidity => $data->{humidity},
            error => $data->{error}
        };
    };

#
# set routes
#

get '/set_aux_state/:aux/:state' => sub {
        
        if (
            (request->address ne '127.0.0.1' && ! session 'logged_in_user')
            || $ENV{UNIT_TEST}){
            return to_json {
                    error => 'unauthorized request. You must be logged in'
            };
        }

        my $aux_id = params->{aux};
        my $state = $api->_bool(params->{state});

        my $log = $log->child('/set_aux_state');
        $log->_5("aux_id: $aux_id, state: $state");

        $state = $api->aux_state($aux_id, $state);

        $log->_6("$aux_id updated state: $state");

        $api->switch($aux_id);

        return to_json {
            aux => $aux_id,
            state => $state,
        };
    };

get '/set_aux_override/:aux/:override' => sub {

        my $log = $log->child('/set_aux_override');

        if (
            (request->address ne '127.0.0.1' && ! session 'logged_in_user')
            || $ENV{UNIT_TEST}){
            $log->_1("attempted call of a 'set' operation while not logged in");
            return to_json {
                    error => 'unauthorized request. You must be logged in'
            };
        }

        my $aux_id = params->{aux};
        my $override = $api->_bool(params->{override});

        $log->_5("setting override for aux id: $aux_id");

        $override = $api->aux_override($aux_id, $override);

        $log->_5("current override status for aux id $aux_id is $override");

        if ($override == -1){
            $log->_5("override for aux id $aux_id is currently disabled");
        }

        return to_json {
            aux => $aux_id,
            override => $override,
        };
    };

true;

__END__

=head1 NAME

App::RPi::EnvUI - One-page asynchronous grow room environment control web
application

=head1 SYNOPSIS

    cd ~/envui
    sudo plackup bin/app.pl

Now direct your browser at your Pi, on port 3000:

    http://raspberry.pi:3000

=head1 DESCRIPTION

*** This is beta software until v1.00 is released. It's still a constant work
in progress, so the docs are awful, but I am trying to improve them as I learn
the things I need to know to get where I want to be.***

*** Note that my focus hasn't been one about detailed security, so please, if
you desire to test this software, ensure it is not Internet facing, and you have
adequate protection from undesired access ***

A self-contained, one-page web application that runs on a Raspberry Pi and
monitors and manages an indoor grow room environment, with an API that can be
used external to the web app itself.

This distribution reads environmental sensors, turns on/off devices based on
specific thresholds, contains an adjustable grow light timer, and five extra
auxillary channels that you can configure for your own use.

The software connects to Raspberry Pi GPIO pins for each C<"auxillary">, and at
specific times or thresholds, turns on and or off the 120/240v devices that
you've relayed to that voltage (if you choose to use this functionality).

=head1 WHAT IT DOES

Reads temperature and humidity data via a hygrometer sensor through the
L<RPi::DHT11> distribution.

It then allows, through a one-page asynchronous web UI to turn on and off
120/240v devices through buttons, timers and reached threshold limits.

For example. We have a max temperature limit of 80F. We assign an auxillary
(GPIO pin) that is connected to a relay to a 120v exhaust fan. Through the
configuration file, we load the temp limit, and if the temp goes above it, we
enable the fan via the GPIO pin.

To prevent the fan from going on/off repeatedly if the temp hovers at the limit,
a minimum "on time" is also set, so by default, if the fan turns on, it'll stay
on for 30 minutes, no matter if the temp drops back below the limit.

Each auxillary has a manual override switch in the UI, and if overridden in the
UI, it'll remain in the state you set.

We also include a grow light scheduler, so that you can connect your light, set
the schedule, and we'll manage it. The light has an override switch in the UI,
but that can be disabled to prevent any accidents.

=head1 HOW IT WORKS

Upon installation of this module, a new directory C<envui> will be created in
your home directory. All of the necessary pieces of code required for this web
app to run are copied into that directory. You simply change into that
directory, and run C<sudo plackup bin/app.pl>, then point your browser to
C<http://raspberry.pi:3000>. I haven't integrated it into a full-blown web
server as of yet.

There are eight auxillary channels (UI buttons that connect to GPIO pins to turn
devices on or off). Three are dedicated to specific functionality. The first
(aux1) is used for temperature sensor duties. The second, humidity sensor
duties. The third is set up to manage a single grow lamp. The remaining five
auxillaries can be set and connected to whatever you please, but these channels
do not have any logic behind them yet; they're just on or off.

Note that you must be logged in to toggle the connected devices. The default
username is C<admin> and the default password is C<admin>.

=head1 WEB UI

The UI and infrastructure behind it is in its infancy. There are vast changes
that I'll be making. Currently I have:

    - a reasonably nice menu system, with the current time displayed
    - all auxillaries are movable objects within the page
    - if objects are moved, the layout will be preserved across a refresh
    - ability to easily reset page layout to default
    - temp, humidity and light auxillary objects will be in override state if
      the state is changed in the UI (ie. automation routines will skip them)
    - the memory footprint of a long run is very manageable (7-15MB)
    - longest unchanged runtime: 178 hours
    - it's a singleton; all browsers pointed to the UI will see the same state,
      with updates every three seconds maximum
    - design is geared to a 5" LCD touchscreen for attaching to the device
      itself, but renders reasonably well on any device size
    - authentication is required for any routes that set state of any kind
    - everything is stored in a DB backend

Note that you must be logged in to toggle the connected devices. The default
username is C<admin> and the default password is C<admin>.

=head1 HOWTO

I'm not going into detail here yet. Look at the
L<App::RPi::EnvUI::Configuration> documentation to get an idea of the config
file.

Map the C<pin> of each aux in the configuration file to a GPIO pin. Start up the
app per L</HOW IT WORKS>. Go to the webpage in an HTML5-capable browser.

I start the application by doing the following. It'll restart the application
properly after every startup:

    sudo crontab -e
    
    # add a line similar to the following:

    @reboot  cd /home/pi/envui && /home/pi/perl5/perlbrew/perls/perl-5.26.0/bin/plackup bin/app.pl

=head1 ROUTES

=head2 /

Use: Browser

Returns the pre-populated template to the UI. Once the browser loads it, it does
not have to be reloaded again.

Return: L<Template::Toolkit> template in HTML

=head2 /light

Use: Internal

Returns a JSON string containing the configuration for the C<light> section of
the page.

Return: JSON

=head2 /get_config/:want

Use: Internal

Fetches and returns a value from the C<core> section of a configuration file.

Parameters:

    :want

The C<core> configuration directive to retrieve the value for.

Return: String. The value for the specified directive.

=head2 /get_control/:want

Use: Internal

Fetches and returns a value from the C<control> section of a configuration file.

Parameters:

    :want

The C<control> configuration directive to retrieve the value for.

Return: String. The value for the specified directive.

=head2 /get_aux/:aux

Use: Internal

Fetches an auxillary channel's information, and on the way through, makes an
L<App::RPi::EnvUI::API> C<switch()> call, which turns on/off the auxillary
channel if necessary.

Parameters:

    :aux

Mandatory, String. The string name of the auxillary channel to fetch
(eg: C<aux1>).

Return: JSON. The JSON stringified version of an auxillary channel hashref.

=head2 /fetch_env

Use: Internal

Fetches the most recent enviromnent details from the database (temperature and
humidity). Takes no parameters.

Return: JSON. A JSON string in the form C<{"temp": "Int", "humidity": "Int"}>

=head2 /set_aux_state/:aux/:state

Use: Internal

Sets the state of an auxillary channel, when an on-change event occurs to a
button that is associated with an auxillary.

Parameters:

    :aux

Mandatory: String. The string name of the auxillary channel to change state on
(eg: C<aux1>).

    :state

Mandatory: Bool. The state of the auxillary after the button change.

Return: JSON. Returns the current state of the auxillary in the format
C<>{"aux": "aux_name", "state": "bool"}>.

Note: The UI user must be logged in to access this route.

=head2 /set_aux_override/:aux/:state

Use: Internal

Sets the override status of an auxillary channel, when an on-change event occurs
to a button that is associated with an auxillary.

Parameters:

    :aux

Mandatory: String. The string name of the auxillary channel to change state on
(eg: C<aux1>).

    :state

Mandatory: Bool. The override status of the auxillary after the button change.

Return: JSON. Returns the current state of the auxillary in the format
C<>{"aux": "aux_name", "override": "bool"}>.

Note: The UI user must be logged in to access this route.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.org<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

