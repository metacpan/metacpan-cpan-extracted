package Cocoa::Growl;
use strict;
use warnings;
use parent 'Exporter';

use XSLoader;
use URI;

our $VERSION = '0.05';

our @EXPORT_OK   = qw(growl_installed growl_running growl_register growl_notify);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use File::ShareDir ();
use File::Spec;

our $FRAMEWORK_DIR = do {
    (my $dist = __PACKAGE__) =~ s/::/-/g;
    File::Spec->catfile(File::ShareDir::dist_dir($dist), 'Growl.framework');
};

XSLoader::load __PACKAGE__, $VERSION;

sub growl_notify {
    my %info = @_;

    my $title       = $info{title} || '';
    my $description = $info{description} || '';
    my $notifName   = $info{name} || '';
    my $icon        = $info{icon};
    my $sticky      = $info{sticky};
    my $priority    = $info{priority} || 0;

    my $on_click   = $info{on_click};
    my $on_timeout = $info{on_timeout};

    if ($icon) {
        my $uri = URI->new($icon);
        $uri->scheme or do { $uri->scheme('file'); $uri->host('') };
        $icon = $uri->as_string;
    }

    _growl_notify($title, $description, $notifName, $icon, $on_click, $on_timeout, $sticky, $priority);
}

sub growl_register {
    my %info = @_;

    my $appName  = $info{app} || __PACKAGE__;
    my $appIcon  = $info{icon};
    my $all      = $info{notifications};
    my $defaults = $info{defaults} || $all;

    if ($appIcon) {
        my $uri = URI->new($appIcon);
        $uri->scheme or do { $uri->scheme('file'); $uri->host('') };
        $appIcon = $uri->as_string;
    }

    _growl_register($appName, $all, $defaults, $appIcon);
}

1;

__END__

=for stopwords NSRunLoop Str AnyEvent

=head1 NAME

Cocoa::Growl - Yet another growl module using Growl.framework

=head1 SYNOPSIS

    use Cocoa::Growl ':all';
    
    my $installed = growl_installed(); # true if Growl is installed.
    my $running   = growl_running();   # true if Growl is running.
    
    # register application
    growl_register(
        app           => 'My growl script',
        icon          => '/path/to/icon.png', # or 'http://url/to/icon'
        notifications => [qw(Notification1 Notification2)],
    );
    
    # show growl notification
    growl_notify(
        name        => 'Notification1',
        title       => 'Hello!',
        description => 'Growl world!',
    );

=head1 DESCRIPTION


=head1 FUNCTIONS

No function is exported by default, but all functions is exportable.
And ':all' tag export all functions.

=head2 growl_installed

    my $installed = growl_installed();

Return true value if growl is installed.

=head2 growl_running

    my $running = growl_running();

Return true value if growl is running.

=head2 growl_register(%parameters)

Register application to growl.

    growl_register(
        app           => 'My growl script',
        icon          => '/path/to/icon.png', # or 'http://url/to/icon'
        notifications => [qw(Notification1 Notification2)],
    );

Available parameters are:

=over 4

=item * app => 'Str' (Required)

The name of the application. 
This is listed in Growl preference panel.

=item * icon => 'Str'

Application icon image path or URL. This image is showed in Growl preference panel, and used notification default image.

=item * notifications => 'ArrayRef' (Required)

List of notification names.
These names will be displayed in Growl preference pane to let users customize options for each notification.

=item * defaults => 'ArrayRef'

List of notification names to enable by default.
If this parameter is not set, all notifications is to become default.

=back

=head2 growl_notify(%parameters)

Show growl notify.

    growl_notify(
        name        => 'Notification1',
        title       => 'Hello!',
        description => 'Growl world!',
    );

Available options are:

=over 4

=item * name => 'Str' (Required)

The internal name of the notification. Should be human-readable, as it will be displayed in the Growl preference pane.
And this value is required to be registered by C<growl_register> before calling this function.

=item * title => 'Str'

The title of the notification displayed to the user.

=item * description => 'Str'

The full description of the notification displayed to the user.

=item * icon => 'Str'

Image file path or URL to show with the notification as its icon. If this value is not set, the application's icon will be used instead.

=item * sticky => 'Bool'

If true value is set, the notification will remain on screen until clicked.
Not all Growl displays support sticky notifications.

=item * priority => 'Int'

The priority of the notification. The default value is 0; positive values are higher priority and negative values are lower priority.
Not all Growl displays support priority.

=item * on_click => 'CodeRef',

This callback is called when notification is clicked.
See also CALLBACK NOTICE below.

=item * on_timeout => 'CodeRef',

This callback is called when notification is timeout. (also called notification closed by close button)

=back

=head3 CALLBACK NOTICE

You should run Cocoa's event loop NSRunLoop to be enable callbacks.
Simplest way to do that is use this module with L<Cocoa::EventLoop>.

    use Cocoa::EventLoop;
    use Cocoa::Growl ':all';
    
    growl_register(
        name          => 'test script',
        notifications => ['test notification'],
    );
    
    my $wait = 1;
    growl_notify(
        name        => 'test notification',
        title       => 'Hello',
        description => 'Growl World!',
        on_click => sub {
            warn 'click';
            $wait = 0;
        },
        on_timeout => sub {
            warn 'timeout';
            $want = 0;
        },
    );
    
    Cocoa::EventLoop->run_while(0.1) while unless $wait;

If you want to write more complicated script, use L<AnyEvent>.
AnyEvent 5.3 or higher is support L<Cocoa::EventLoop> internally, so you can use cocoa's event loop transparently in your AnyEvent application.
See L<AnyEvent::Impl::Cocoa> for more detail.

=head1 USE YOUR OWN Growl.framework

Although this module bundle Growl.framework and load it by default, you can load your own Growl.framework.
To do that, save your Growl.framework to C</Library/Frameworks/Growl.framework/>, and add C<USE_LOCAL_GROWL_FRAMEWORK=1> option when run Makefile.PL

    perl Makefile.PL USE_LOCAL_GROWL_FRAMEWORK=1


=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
