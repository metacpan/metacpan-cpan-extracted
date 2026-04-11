package Chandra::Notify;
use strict;
use warnings;

# Load XS functions from Chandra bootstrap
use Chandra ();

our $VERSION = '0.21';

=head1 NAME

Chandra::Notify - Native OS desktop notifications

=head1 SYNOPSIS

    use Chandra::Notify;

    # Simple notification
    Chandra::Notify->send(
        title => 'Download Complete',
        body  => 'report.pdf has finished downloading',
    );

    # With options
    Chandra::Notify->send(
        title   => 'New Message',
        body    => 'Alice: Hey, are you there?',
        icon    => '/path/to/icon.png',
        sound   => 1,
        timeout => 5000,
    );

    # Check if supported
    if (Chandra::Notify->is_supported) {
        Chandra::Notify->send(title => 'Hello', body => 'World');
    }

=head1 DESCRIPTION

Chandra::Notify provides native desktop notifications across platforms:

=over 4

=item * macOS: Uses UNUserNotificationCenter (10.15+) or NSUserNotification

=item * Linux: Uses libnotify if available, falls back to notify-send

=item * Windows: Uses toast notifications (MessageBox as fallback)

=back

=head1 METHODS

=head2 send(%args)

Send a notification. Returns true on success.

Arguments:

=over 4

=item title - Notification title (required)

=item body - Notification body text

=item icon - Path to icon file

=item sound - Play default notification sound (1 = yes)

=item timeout - Auto-dismiss timeout in milliseconds (Linux/Windows)

=back

=head2 is_supported()

Returns true if notifications are supported on this platform.

=cut

# XS functions: is_supported(), _xs_send()
# These are loaded automatically via Chandra bootstrap

sub is_supported {
    return _xs_is_supported();
}
sub send {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    
    # Validate title
    unless (defined $args{title} && length $args{title}) {
        warn "Chandra::Notify: title is required";
        return 0;
    }
    
    return _xs_send(\%args);
}

# Convenience method for OO interface
sub new {
    my $class = shift;
    my %defaults = @_;
    return bless \%defaults, $class;
}

sub notify {
    my $self = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    
    # Merge with defaults
    %args = (%$self, %args);
    
    return Chandra::Notify->send(%args);
}

1;

__END__

=head1 EXAMPLES

    use Chandra::App;
    
    my $app = Chandra::App->new(title => 'My App');
    
    # Via app integration
    $app->notify(
        title => 'Task Complete',
        body  => 'Build finished successfully',
    );

=head1 PLATFORM NOTES

=head2 macOS

Requires macOS 10.8+ for NSUserNotification, 10.15+ for UNUserNotificationCenter.
The app must be properly signed to display notifications in some cases.

=head2 Linux

Requires a notification daemon (most desktop environments have one).
libnotify.so.4 is preferred; falls back to notify-send CLI.

=head2 Windows

Currently uses MessageBox as a fallback. Full toast notification support
is planned for a future release.

=head1 SEE ALSO

L<Chandra>, L<Chandra::App>

=cut
