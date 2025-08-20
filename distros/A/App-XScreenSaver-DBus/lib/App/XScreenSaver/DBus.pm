package App::XScreenSaver::DBus;
use v5.20;
use Moo;
use experimental qw(signatures postderef);
use Net::DBus::Reactor;
use Log::Any;
use App::XScreenSaver::DBus::Logind;
use App::XScreenSaver::DBus::Saver;
our $VERSION = '1.0.6'; # VERSION
# ABSTRACT: tie xscreensaver into dbus


has reactor => (
    is => 'lazy',
    builder => sub { Net::DBus::Reactor->main() },
);


has logind => (
    is => 'lazy',
    builder => sub { App::XScreenSaver::DBus::Logind->new() },
);


has saver => (
    is => 'lazy',
    builder => sub($self) {
        App::XScreenSaver::DBus::Saver->new(reactor => $self->reactor);
    },
);


has log => ( is => 'lazy', builder => sub { Log::Any->get_logger } );


sub run($self) {
    $self->logind->start();
    $self->saver->start();
    $self->reactor->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XScreenSaver::DBus - tie xscreensaver into dbus

=head1 VERSION

version 1.0.6

=head1 SYNOPSIS

    use App::XScreenSaver::DBus;
    App::XScreenSaver::DBus->new->run;

=head1 ATTRIBUTES

=head2 C<reactor>

the event loop

=head2 C<logind>

instance of L<< C<App::XScreenSaver::DBus::Logind> >>.

=head2 C<saver>

instance of L<< C<App::XScreenSaver::DBus::Saver> >>.

=head2 C<log>

a logger

=head1 METHODS

=head2 C<run>

registers the DBus services and runs the event loop; this method does
not return

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
