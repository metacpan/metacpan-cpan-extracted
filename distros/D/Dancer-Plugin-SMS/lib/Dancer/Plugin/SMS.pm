package Dancer::Plugin::SMS;

use strict;
use Dancer::Plugin;
use SMS::Send;

our $VERSION = '0.02';

=head1 NAME

Dancer::Plugin::SMS - Easy SMS text message sending from Dancer apps


=head1 SYNOPSIS

In your Dancer app:

    # Positional params ($to, $message)
    sms '+44788....', 'Hello there!';

    # Or named params
    sms to => '+44...', text => 'Hello!';

In your Dancer C<config.yml>, provide the SMS::Send::* driver name, and whatever
params are appropriate for that driver (see the driver documentation for
details) - example configuration for using L<SMS::Send::AQL>:

    plugins:
        SMS:
            driver: 'AQL'
            _login: 'youraqlusername'
            _password: 'youraqlpassword'
            _sender: '+4478....'


=head1 DESCRIPTION

Provides a quick and easy way to send SMS messages using L<SMS::Send> drivers
(of which there are many, so chances are the service you want to use is already
supported; if not, they're easy to write, and if you want to change providers
later, you can simply update a few lines in your config file, and you're done).


=head1 Keywords

=head2 sms

Send an SMS message.  You can pass the destination and message as positional
params:

    sms $to, $message;

Or, you can use named params:

    sms to => $to, text => $message;

The latter form may be clearer, and would allow any additional driver-specific
parameters to be passed too, but the former is terser.  The choice is yours.


=head2 sms_driver

Returns the SMS::Send driver object, in case you need to do things with it
directly.

=cut


my $sms_send;
sub sms_driver {
    return $sms_send if $sms_send;
    
    # OK, get the plugin's settings, and create a new object
    my $config = plugin_setting;
    my $driver = delete $config->{driver};
    return $sms_send = SMS::Send->new($driver, %$config);
}
register sms_driver => \&sms_driver;

register sms => sub {
    my %params;
    if (@_ == 2) {
        @params{qw(to text)} = @_;
    } elsif (@_ > 2 && @_ % 2 == 0) {
        %params = @_;
    } else {
        die "Invalid params passed to sms keyword!";
    }
    sms_driver->send_sms(%params);
};

register_plugin;


=head1 AUTHOR

David Precious, C<< <davidp@preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests, preferably on GitHub, or on
rt.cpan.org:

L<http://github.com/bigpresh/Dancer-Plugin-SMS/issues>

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-SMS>


=head1 FEEDBACK / SUPPORT

The author can usually be found on C<#dancer> on C<irc.perl.org> - see
L<http://www.perldancer.org/irc> for web IRC.


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Dancer>

L<SMS::Send>

L<http://www.aql.com/>

=cut

1; # End of Dancer::Plugin::SMS
