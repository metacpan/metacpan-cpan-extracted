package App::XScreenSaver::DBus::InhibitSleep;
use v5.20;
use Moo;
use experimental qw(signatures postderef);
use curry;
use Net::DBus;
use IPC::Run;
use Log::Any;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: implements the logind "inhibitor locks" protocol


has bus => ( is => 'lazy', builder => sub { Net::DBus->system() } );


has logind_srv => (
    is => 'lazy',
    builder => sub { shift->bus->get_service('org.freedesktop.login1') },
);


has logind_obj => (
    is => 'lazy',
    builder => sub { shift->logind_srv->get_object('/org/freedesktop/login1') },
);


has inhibit_fd => ( is => 'rwp' );


has log => ( is => 'lazy', builder => sub { Log::Any->get_logger } );


sub start($self) {
    $self->logind_obj->connect_to_signal(
        'PrepareForSleep',
        $self->curry::weak::_going_to_sleep,
    );
    $self->_inhibit();
    return;
}

sub _inhibit($self) {
    return if $self->inhibit_fd;
    $self->_set_inhibit_fd(
        $self->logind_obj->Inhibit(
            'sleep',
            'xscreensaver','locking before sleep',
            'delay',
        )
    );
    $self->log->debugf('got logind inhibit fd %d',$self->inhibit_fd);
    return;
}

sub _going_to_sleep($self,$before) {
    if ($before) {
        $self->log->debug('locking');
        $self->_xscreensaver_command('-suspend');
        $self->log->debug('locked');
        $self->_set_inhibit_fd(undef);
    }
    else {
        $self->log->debug('woken up');
        $self->_xscreensaver_command('-deactivate');
        $self->_inhibit();
    }
    return;
}

sub _xscreensaver_command($self,$command) {
    my ($out, $err);
    IPC::Run::run(
        ['xscreensaver-command',$command],
        \undef, \$out, \$err,
    );
    $self->log->tracef('xscreensaver-command %s said <%s>',$command,$out);
    $self->log->warnf('xscreensaver-command %s errored <%s>',$command,$err)
        if $err;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XScreenSaver::DBus::InhibitSleep - implements the logind "inhibitor locks" protocol

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

    use Net::DBus::Reactor;
    use App::XScreenSaver::DBus::InhibitSleep;
    my $is = App::XScreenSaver::DBus::InhibitSleep->new;
    $is->start;

    Net::DBus::Reactor->new->run;

=head1 ATTRIBUTES

=head2 C<bus>

the DBus system bus

=head2 C<logind_srv>

the (e)logind DBus service

=head2 C<logind_obj>

the (e)logind DBus object

=head2 C<inhibit_fd>

the file descriptor that logind gives us when we ask for a lock; we
close it to release the lock

=head2 C<log>

a logger

=head1 METHODS

=head2 C<start>

starts listening to the C<PrepareForSleep> signal from (e)logind, and
takes the lock

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
