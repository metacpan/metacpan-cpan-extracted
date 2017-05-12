package Appium;
$Appium::VERSION = '0.0803';
# ABSTRACT: Perl bindings to the Appium mobile automation framework (WIP)
use Carp qw/croak/;
use feature qw/state/;
use Moo;
use MooX::Aliases 0.001005;

use Appium::Commands;
use Appium::Element;
use Appium::ErrorHandler;
use Appium::SwitchTo;
use Appium::TouchActions;

use Selenium::Remote::Driver 0.2202;
use Selenium::Remote::RemoteConnection;
extends 'Selenium::Remote::Driver';



use constant FINDERS => {
    %{ Selenium::Remote::Driver->FINDERS },
    ios                 => '-ios uiautomation',
    ios_uiautomation    => '-ios uiautomation',
    android             => '-android uiautomator',
    android_uiautomator => '-android uiautomator',
    accessibility_id    => 'accessibility id'
};

has '+desired_capabilities' => (
    is => 'rw',
    required => 1,
    alias => 'caps',
);

has '_type' => (
    is => 'rw',
    lazy => 1,
    coerce => sub {
        my $device = shift || 'iOS';

        croak 'platformName must be Android or iOS'
          unless grep { $_ eq $device } qw/Android iOS/;

        return $device;
    }
);

has '+remote_server_addr' => (
    is => 'ro',
    default => sub { 'localhost' }
);

has '+port' => (
    is => 'ro',
    default => sub { 4723 }
);

has '+commands' => (
    is => 'ro',
    default => sub { Appium::Commands->new }
);

has '+remote_conn' => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Selenium::Remote::RemoteConnection->new(
            remote_server_addr => $self->remote_server_addr,
            port               => $self->port,
            ua                 => $self->ua,
            error_handler      => Appium::ErrorHandler->new
        );
    }
);

has 'touch_actions' => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
    handles => [ qw/tap/ ],
    default => sub { Appium::TouchActions->new( driver => shift ); }
);


has 'webelement_class' => (
    is => 'rw',
    default => sub { 'Appium::Element' }
);

sub BUILD {
    my ($self) = @_;

    $self->_type($self->desired_capabilities->{platformName});
}


sub contexts {
    my ($self) = @_;

    my $res = { command => 'contexts' };
    return $self->_execute_command( $res );
}


sub current_context {
    my ($self) = @_;

    my $res = { command => 'get_current_context' };
    my $params = {};

    return $self->_execute_command( $res, $params );
}


has 'switch_to' => (
    is => 'lazy',
    init_arg => undef,
    default => sub { Appium::SwitchTo->new( driver => shift );  }
);


sub hide_keyboard {
    my ($self, %args) = @_;

    my $res = { command => 'hide_keyboard' };
    my $params = {};

    if (exists $args{key_name}) {
        $params->{keyName} = $args{key_name}
    }
    elsif (exists $args{key}) {
        $params->{key} = $args{key}
    }

    # default strategy is tapOutside
    my $strategy = 'tapOutside';
    $params->{strategy} = $args{strategy} || $strategy;

    return $self->_execute_command( $res, $params );
}


sub app_strings {
    my ($self, $language) = @_;

    my $res = { command => 'app_strings' };
    my $params;
    if (defined $language ) {
        $params = { language => $language }
    }
    else {
        $params = {};
    }

    return $self->_execute_command( $res, $params );
}


sub reset {
    my ($self) = @_;

    my $res = { command => 'reset' };

    return $self->_execute_command( $res );
}


sub press_keycode {
    my ($self, $keycode, $metastate) = @_;

    my $res = { command => 'press_keycode' };
    my $params = {
        keycode => $keycode,
    };

    $params->{metastate} = $metastate if $metastate;

    return $self->_execute_command( $res, $params );
}


sub long_press_keycode {
    my ($self, $keycode, $metastate) = @_;

    my $res = { command => 'long_press_keycode' };
    my $params = {
        keycode => $keycode,
    };

    $params->{metastate} = $metastate if $metastate;

    return $self->_execute_command( $res, $params );
}


sub current_activity {
    my ($self) = @_;

    my $res = { command => 'current_activity' };

    return $self->_execute_command( $res );
}


sub pull_file {
    my ($self, $path) = @_;
    croak "Please specify a path to pull from the device"
      unless defined $path;

    my $res = { command => 'pull_file' };
    my $params = { path => $path };

    return $self->_execute_command( $res, $params );
}


sub pull_folder {
    my ($self, $path) = @_;
    croak 'Please specify a folder path to pull'
      unless defined $path;

    my $res = { command => 'pull_folder' };
    my $params = { path => $path };

    return $self->_execute_command( $res, $params );
}


sub push_file {
    my ($self, $path, $data) = @_;

    my $res = { command => 'push_file' };
    my $params = {
        path => $path,
        data => $data
    };

    return $self->_execute_command( $res, $params );
}


# todo: add better examples of complex find

sub complex_find {
    my ($self, @selector) = @_;
    croak 'Please specify selection criteria'
      unless scalar @selector;

    my $res = { command => 'complex_find' };
    my $params = { selector => \@selector };

    return $self->_execute_command( $res, $params );
}


sub background_app {
    my ($self, $seconds) = @_;

    my $res = { command => 'background_app' };
    my $params = { seconds => $seconds};

    return $self->_execute_command( $res, $params );
}


sub is_app_installed {
    my ($self, $bundle_id) = @_;

    my $res = { command => 'is_app_installed' };
    my $params = { bundleId => $bundle_id };

    return $self->_execute_command( $res, $params );
}


sub install_app {
    my ($self, $app_path) = @_;

    my $res = { command => 'install_app' };
    my $params = { appPath => $app_path };

    return $self->_execute_command( $res, $params );
}


sub remove_app {
    my ($self, $app_id) = @_;

    my $res = { command => 'remove_app' };
    my $params = { appId => $app_id };

    return $self->_execute_command( $res, $params );
}


sub launch_app {
    my ($self) = @_;

    my $res = { command => 'launch_app' };
    return $self->_execute_command( $res );
}


sub close_app {
    my ($self) = @_;

    my $res = { command => 'close_app' };
    return $self->_execute_command( $res );
}


sub end_test_coverage {
    my ($self, $intent, $path) = @_;

    my $res = { command => 'end_test_coverage' };
    my $params = {
        intent => $intent,
        path => $path
    };

    return $self->_execute_command( $res, $params );
}


sub lock {
    my ($self, $seconds) = @_;

    my $res = { command => 'lock' };
    my $params = { seconds => $seconds };

    return $self->_execute_command( $res, $params );
}


sub is_locked {
    my($self) = @_;

    my $res = { command => 'is_locked' };
    return $self->_execute_command( $res );
}


sub shake {
    my ($self) = @_;

    my $res = { command => 'shake' };
    return $self->_execute_command( $res );
}


sub open_notifications {
    my ($self) = @_;

    my $res = { command => 'open_notifications' };
    return $self->_execute_command( $res );
}


sub network_connection {
    my ($self) = @_;

    my $res = { command => 'network_connection' };
    return $self->_execute_command( $res );
}


sub set_network_connection {
    my ($self, $connection_bitmask) = @_;

    my $res = { command => 'set_network_connection' };
    my $params = {
        parameters => {
            type => $connection_bitmask
        }
    };

    return $self->_execute_command( $res, $params );
}



sub page {
    my ($self) = @_;

    $self->_get_page;
}

sub _get_page {
    my ($self, $element, $level) = @_;
    return 'TODO: implement page on android' if $self->is_android;

    $element //= $self->_source_window_with_children;
    $level //= 0;
    my $indent = '  ' x $level;

    # App strings are found in an actual file in the app package
    # somewhere, so I'm assuming we don't have to worry about them
    # changing in the middle of our app execution. This may very well
    # turn out to be a false assumption.
    state $strings = $self->app_strings;

    my @details = qw/name label value hint/;
    if ($element->{visible}) {
        print $indent .  $element->{type} . "\n";
        foreach (@details) {
            my $detail = $element->{$_};
            if ($detail) {
                print $indent .  '  ' . $_ . "\t: " . $detail  . "\n" ;

                foreach my $key (keys %{ $strings }) {
                    my $val = $strings->{$key};
                    if ($val =~ /$detail/) {
                        print $indent .  '  id  ' . "\t: " . $key . ' => ' . $val . "\n";
                    }
                }
            }
        }
    }

    $level++;
    my @children = @{ $element->{children} };
    foreach (@children) {
        $self->_get_page($_, $level);
    }
}

sub _source_window_with_children {
    my ($self, $index) = @_;
    $index //= 0;

    my $window = $self->execute_script('UIATarget.localTarget().frontMostApp().windows()[' . $index . '].getTree()');
    if (scalar @{ $window->{children} }) {
        return $window;
    }
    else {
        return $self->_source_window_with_children(++$index);
    }
}

sub is_android {
    return shift->_type eq 'Android'
}

sub is_ios {
    return shift->_type eq 'iOS'
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium - Perl bindings to the Appium mobile automation framework (WIP)

=for markdown [![Build Status](https://travis-ci.org/appium/perl-client.svg?branch=master)](https://travis-ci.org/appium/perl-client)

=head1 VERSION

version 0.0803

=head1 SYNOPSIS

    my $appium = Appium->new(caps => {
        app => '/url/or/path/to/mobile/app.zip'
    });

    $appium->page;
    $appium->find_element('TextField1', 'name')->send_keys('5');
    $appium->quit;

=head1 DESCRIPTION

Appium is an open source test automation framework for use with native
and hybrid mobile apps.  It drives iOS and Android apps using the
WebDriver JSON wire protocol. This module is a thin extension of
L<Selenium::Remote::Driver> that adds Appium specific API endpoints
and Appium-specific constructor defaults. It's woefully incomplete at
the moment, so feel free to pitch in at the L<Github
repo|https://github.com/appium/perl-client>! For details on how Appium
extends the Webdriver spec, see the Selenium project's L<spec-draft
document|https://code.google.com/p/selenium/source/browse/spec-draft.md?repo=mobile>.

Note that like L<Selenium::Remote::Driver>, you shouldn't have to
instantiate L<Appium::Element> on your own; this module will create
them when necessary so that all you need to know is what methods are
appropriate on an element vs the driver.

    my $appium = Appium->new( caps => { app => '/path/to/app.zip' } );

    # automatically instantiates Appium::Element for you
    my $elem = $appium->find_element('test', 'id');
    $elem->click;

=head1 NEW OR UPDATED FUNCTIONALITY

=head2 Contexts

Instead of using windows to manage switching between native
applications and webviews, use the analogous context methods:

    my $current = $appium->current_context;
    my @contexts = $appium->contexts;

    my $context = 'WEBVIEW_1'
    $appium->switch_to->context( $context );

=head2 Finding Elements

There are different strategies available for finding elements in
Appium. The options for strategies in a native application are:

    id
    name
    xpath
    class|class_name
    accessibility_id
    ios|ios_uiautomation
    android|android_uiautomator

If you're testing a mobile browser like Chrome or Safari, you'll have
access to the same set of finders as in Webdriver:

    class
    class_name
    css
    id
    link
    link_text
    name
    partial_link_text
    tag_name
    xpath

Here are some examples of using the Appium specific strategies:

    # iOS UIAutomation
    $driver->find_element( $locator , 'ios' );

    # Android UIAutomator
    $driver->find_element( $locator , 'android' );

    # iOS accessibility identifier
    $driver->find_element( $locator , 'accessibility_id' );

Note that using C<id> as your finding strategy also seems to find
elements by accessibility_id.

=head1 METHODS

=head2 contexts ()

Returns the contexts within the current session

    $appium->contexts;

=head2 current_context ()

Return the current active context for the current session

    $appium->current_context;

=head2 switch_to->context ( $context_name )

Switch to the desired context for the current session

    $appium->switch_to->context( 'WEBVIEW_1' );

=head2 hide_keyboard( [key_name|key|strategy => $key_or_strategy] )

Hides the software keyboard on the device. In iOS, you have the option
of using C<key_name> to close the keyboard by pressing a specific
key. Or, you can specify a particular strategy; the default strategy
is C<tapOutside>. In Android, no parameters are used.

    $appium->hide_keyboard;
    $appium->hide_keyboard( key_name => 'Done');
    $appium->hide_keyboard( strategy => 'pressKey', key => 'Done');

=head2 app_strings ( [language] )

Get the application strings from the device for the specified
language; it will return English strings by default if the language
argument is omitted.

    $appium->app_strings
    $appium->app_strings( 'en' );

=head2 reset ()

Reset the current application

    $appium->reset;

=head2 press_keycode ( keycode, [metastate])

Android only: send a keycode to the device. Valid keycodes can be
found in the L<Android
docs|http://developer.android.com/reference/android/view/KeyEvent.html>.
C<metastate> describes the pressed state of key modifiers such as
META_SHIFT_ON or META_ALT_ON; more information is available in the
Android KeyEvent documentation.

    $appium->press_keycode(176);

=head2 long_press_keycode ( keycode, [metastate])

Android only: send a long press keycode to the device. Valid keycodes
can be found in the L<Android
docs|http://developer.android.com/reference/android/view/KeyEvent.html>.
C<metastate> describes the pressed state of key modifiers such as
META_SHIFT_ON or META_ALT_ON; more information is available in the
Android KeyEvent documentation.

    $appium->long_press_keycode(176);

=head2 current_activity ()

Get the current activity on the device.

    $appium->current_activity;

=head2 pull_file ( $file )

Pull a file from the device, returning it Base64 encoded.

    $appium->pull_file( '/tmp/file/to.pull' );

=head2 pull_folder ( $path )

Retrieve a folder at path, returning the folder's contents in a zip
file.

    $appium->pull_folder( 'folder' );

=head2 push_file ( $path, $encoded_data )

Puts the data in the file specified by C<path> on the device. The data
must be base64 encoded.

    $appium->push_file( '/file/path', $base64_data );

=head2 complex_find ( $selector )

Search for elements in the current application, given an array of
selection criteria.

    $appium->complex_find( $selector );

=head2 background_app ( $time_in_seconds )

Defer the application to the background on the device for the
interval, given in seconds.

    $appium->background_app( 5 );

=head2 is_app_installed ( $bundle_id )

Check whether the application with the specified C<bundle_id> is
installed on the device.

    $appium->is_app_installed( $bundle_id );

=head2 install_app ( $app_path )

Install the desired app on to the device

    $appium->install_app( '/path/to/local.app' );

=head2 remove_app( $app_id )

Remove the specified application from the device by app ID.

    $appium->remove_app( 'app_id' );

=head2 launch_app ()

Start the application specified in the desired capabilities on the
device.

    $appium->launch_app;

=head2 close_app ()

Stop the running application, as specified in the desired
capabilities.

    $appium->close_app;

=head2 end_test_coverage ( $intent, $path )

Android only: end the coverage collection and download the specified
C<coverage.ec> file from the device. The file will be returned base 64
encoded.

    $appium->end_test_coverage( 'intent', '/path/to/coverage.ec' );

=head2 lock ( $seconds )

Lock the device for a specified number of seconds.

    $appium->lock( 5 ); # lock for 5 seconds

=head2 is_locked

Query the device for its locked/unlocked state.

    $locked = $appium->is_locked

=head2 shake ()

Shake the device.

    $appium->shake;

=head2 open_notifications ()

Android only, API level 18 and above: open the notification shade on
Android.

    $appium->open_notifications;

=head2 network_connection ()

Android only: retrieve an integer bitmask that describes the current
network connection configuration. Possible values are listed in
L</set_network_connection>.

    $appium->network_connection;

=head2 set_network_connection ( $connection_type_bitmask )

Android only: set the network connection type according to the
following bitmask:

    # Value (Alias)      | Data | Wifi | Airplane Mode
    # -------------------------------------------------
    # 0 (None)           | 0    | 0    | 0
    # 1 (Airplane Mode)  | 0    | 0    | 1
    # 2 (Wifi only)      | 0    | 1    | 0
    # 4 (Data only)      | 1    | 0    | 0
    # 6 (All network on) | 1    | 1    | 0

    $appium->set_network_connection(6);

=head2 tap ( $x, $y )

Perform a precise tap. See L<Appium::TouchActions/tap> for more
information.

    $appium->tap( 0.5, 0.5 );

=head2 page

A shadow of L<arc|https://github.com/appium/ruby_console>'s page
command, this will print to STDOUT a list of all the visible elements
on the page along with whatever details are available (name, label,
value, etc). It's currently only compatible with iOS, and it doesn't
take filtering arguments like arc's version of page does.

    $appium->page;
    # UIAWindow
    #   UIATextField
    #     name          : IntegerA
    #     label         : TextField1
    #     value         : 5
    #     UIATextField
    #       name        : TextField1
    #       label       : TextField1
    #       value       : 5
    #   UIATextField
    #     name          : IntegerB
    #     label         : TextField2
    #     UIATextField
    #       name        : TextField2
    #       label       : TextField2
    # ...

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Appium::Element|Appium::Element>

=item *

L<Selenium::Remote::Driver|Selenium::Remote::Driver>

=item *

L<http://appium.io|http://appium.io>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/appium/perl-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 CONTRIBUTOR

=for stopwords Freddy Vega

Freddy Vega <freddy@vgp-miami.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
