package Cocoa::BatteryInfo;
use strict;
use warnings;
use XSLoader;

our $VERSION = '0.02';

use constant +{
    LowBatteryWarningNone  => 1,
    LowBatteryWarningEarly => 2,
    LowBatteryWarningFinal => 3,
};

XSLoader::load __PACKAGE__, $VERSION;

1;

__END__

=head1 NAME

Cocoa::BatteryInfo - Getting battery informations on your Mac

=head1 SYNOPSIS

Get battery informations

    use Cocoa::BatteryInfo;
    
    # get information for first battery source
    my $info = Cocoa::BatteryInfo->current_info;
    
    # get information for all battery sources
    my @sources = Cocoa::BatteryInfo->sources;
    for my $source (@sources) {
        my $info = Cocoa::BatteryInfo->current_info($source);
        ...
    }
    
    # get estimated time remaining until all power sources are empty
    my $sec = Cocoa::BatteryInfo->time_remaining_estimate;


Get battery related notifications with Cocoa::EventLoop

    use Cocoa::BatteryInfo;
    use Cocoa::EventLoop;
    
    Cocoa::BatteryInfo::low_battery_handler {
        # called when the battery time remaining drops into a warnable level.
        my $warning_level = Cocoa::BatteryInfo->battery_warning_level;
        ...
    };
    
    Cocoa::BatteryInfo::time_remaining_handler {
        # called when the power source(s) time remaining changes.
        my $remaining_sec = Cocoa::BatteryInfo->time_remaining_estimate;
        ...
    };
    
    # run event loop
    Cocoa::EventLoop->run;

=head1 DESCRIPTION

This module provides several functions to get battery information about your Mac computers.
Optionally this module also supports some notifications (low battery notifications, time remaining change notifications) with L<Cocoa::EventLoop>.

This module requires Mac OS X 10.7 or later because it depends new IOKit APIs.

=head1 CLASS METHODS

=head2 info($source_name : Str)

    my $info = Cocoa::BatteryInfo->info;
    # or
    my $info = Cocoa::BatteryInfo->info($source_name);

Returns readable information about the specific power source.

If C<$source_name> is not set, returns first source information.
If system doesn't have any battery, returns nothing.

=head2 sources()

    my @sources = Cocoa::BatteryInfo->sources;

Returns list of power sources that connected to current machine.

=head2 time_remaining_estimate()

    my $sec = Cocoa::BatteryInfo->time_remaining_estimate;

Returns 'unknown' if the OS cannot determine the time remaining.
Returns 'unlimited' if the system has an unlimited power source.

Otherwise returns estimated time remaining until all power sources are empty (in seconds).

=head2 battery_warning_level()

    my $level = Cocoa::BatteryInfo->battery_warning_level;

Indicates whether the system is at a low battery warning level.

C<$level> is one of following levels:

=over 4

=item * Cocoa::BatteryInfo::LowBatteryWarningNone (== 1) (No battery warnings)

=item * Cocoa::BatteryInfo::LowBatteryWarningEarly (== 2) (Early battery warnings)

=item * Cocoa::BatteryInfo::LowBatteryWarningFinal (== 3) (Final battery warnings)

=back

=head1 CALLBACKS

=head2 low_battery_handler($callback :CodeRef)

Register low battery event handler called when the battery time remaining drops into a warnable level.

=head2 time_remaining_handler($callback :CodeRef)

Register time remaining event handler called when the power source(s) time remaining changes.

=head1 NOTICE

Callbacks listed above do nothing without under the Cocoa's event loop.

To work those callbacks correctly, you have to use this module with L<Cocoa::EventLoop>:

    use Cocoa::EventLoop;
    use Cocoa::BatteryInfo;
    
    Cocoa::BatteryInfo::low_battery_handler {
        # do something;
    };
    
    Cocoa::EventLoop->run;

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 Daisuke Murase. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
