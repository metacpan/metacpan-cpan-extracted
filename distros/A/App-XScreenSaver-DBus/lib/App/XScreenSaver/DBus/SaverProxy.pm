package App::XScreenSaver::DBus::SaverProxy;
use v5.20;
use strict;
use warnings;
use experimental qw(signatures postderef);
# this is the interface name
use Net::DBus::Exporter qw(org.freedesktop.ScreenSaver);
use parent 'Net::DBus::Object';
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: proxy dbus object


dbus_method('Inhibit',['string','string'],['uint32']);
dbus_method('UnInhibit',['uint32'],[]);

sub new($class,$service,$path,$inhibit_cb,$uninhibit_cb) {
    my $self = $class->SUPER::new($service, $path);
    bless $self, $class;
    $self->{__inhibit_cb} = $inhibit_cb;
    $self->{__uninhibit_cb} = $uninhibit_cb;
    return $self;
}

our $_message;
sub _dispatch_object($self,$connection,$message,@etc) {
    local $_message = $message;
    return $self->SUPER::_dispatch_object($connection,$message,@etc);
}

sub Inhibit($self,$name,$reason) {
    return $self->{__inhibit_cb}->($name,$reason,$_message);
}

sub UnInhibit($self,$cookie) {
    return $self->{__uninhibit_cb}->($cookie,$_message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XScreenSaver::DBus::SaverProxy - proxy dbus object

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This is functionally the same as L<< C<Net::DBus::ObjectProxy> >>, but
specialised for this application, and with a hack to allow L<<
C<App::XScreenSaver::DBus::Saver> >> to access the sender of the
message.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
