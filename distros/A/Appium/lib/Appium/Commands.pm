package Appium::Commands;
$Appium::Commands::VERSION = '0.0804';
# ABSTRACT: Appium specific extensions to the Webdriver JSON protocol
use Moo;
extends 'Selenium::Remote::Commands';


has 'get_cmds' => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;
        my $commands = $self->SUPER::get_cmds;

        my $appium_commands = {
            contexts => {
                method => 'GET',
                url => 'session/:sessionId/contexts',
                no_content_success => 0
            },
            get_current_context => {
                method => 'GET',
                url => 'session/:sessionId/context',
                no_content_success => 0
            },
            switch_to_context => {
                method => 'POST',
                url => 'session/:sessionId/context',
                no_content_success => 1
            },
            # touch_action => {
            #         method => 'POST',
            #         url => 'session/:sessionId/touch/perform',
            #         no_content_success => 1
            #     },
            #     multi_action => {
            #         method => 'POST',
            #         url => 'session/:sessionId/touch/multi/perform',
            #         no_content_success => 1
            #     },
            app_strings => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/strings',
                no_content_success => 0
            },
            press_keycode => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/press_keycode',
                no_content_success => 1
            },
            long_press_keycode => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/long_press_keycode',
                no_content_success => 1
            },
            current_activity => {
                method => 'GET',
                url => 'session/:sessionId/appium/device/current_activity',
                no_content_success => 0
            },
            set_value => {
                method => 'POST',
                url => 'session/:sessionId/appium/element/$elementId/value',
                no_content_success => 1
            },
            pull_file => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/pull_file',
                no_content_success => 0
            },
            pull_folder => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/pull_folder',
                no_content_success => 0
            },
            push_file => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/push_file',
                no_content_success => 1
            },
            complex_find => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/complex_find',
                no_content_success => 1
            },
            background_app => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/background',
                no_content_success => 1
            },
            is_app_installed => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/app_installed',
                no_content_success => 1
            },
            install_app => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/install_app',
                no_content_success => 1
            },
            remove_app => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/remove_app',
                no_content_success => 1
            },
            launch_app => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/launch',
                no_content_success => 1
            },
            close_app => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/close',
                no_content_success => 1
            },
            end_test_coverage => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/end_test_coverage',
                no_content_success => 1
            },
            lock => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/lock',
                no_content_success => 1
            },
            is_locked => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/is_locked',
                no_content_success => 0
            },
            shake => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/shake',
                no_content_success => 1
            },
            reset => {
                method => 'POST',
                url => 'session/:sessionId/appium/app/reset',
                no_content_success => 1
            },
            hide_keyboard => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/hide_keyboard',
                no_content_success => 1
            },
            open_notifications => {
                method => 'POST',
                url => 'session/:sessionId/appium/device/open_notifications',
                no_content_success => 1
            },
            network_connection => {
                method => 'GET',
                url => 'session/:sessionId/network_connection',
                no_content_success => 0
            },
            set_network_connection => {
                method => 'POST',
                url => 'session/:sessionId/network_connection',
                no_content_success => 1
            },
            #     get_available_ime_engines => {
            #         method => 'GET',
            #         url => 'session/:sessionId/ime/available_engines',
            #         no_content_success => 0
            #     },
            #     is_ime_active => {
            #         method => 'GET',
            #         url => 'session/:sessionId/ime/activated',
            #         no_content_success => 0
            #     },
            #     activate_ime_engine => {
            #         method => 'POST',
            #         url => 'session/:sessionId/ime/activate',
            #         no_content_success => 1
            #     },
            #     deactivate_ime_engine => {
            #         method => 'POST',
            #         url => 'session/:sessionId/ime/deactivate',
            #         no_content_success => 1
            #     },
            #     get_active_ime_engine => {
            #         method => 'GET',
            #         url => 'session/:sessionId/ime/active_engine',
            #         no_content_success => 0
            #     }
        };

        foreach (keys %$appium_commands) {
            $commands->{$_} = $appium_commands->{$_};
        }

        return $commands;
    }
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium::Commands - Appium specific extensions to the Webdriver JSON protocol

=head1 VERSION

version 0.0804

=head1 DESCRIPTION

There's not much to see here. View the source if you'd like to see the
Appium specific endpoints. Otherwise, you might be looking for
L<Appium> or L<Selenium::Remote::Commands>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Appium|Appium>

=item *

L<Selenium::Remote::Commands|Selenium::Remote::Commands>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/appium/perl-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
