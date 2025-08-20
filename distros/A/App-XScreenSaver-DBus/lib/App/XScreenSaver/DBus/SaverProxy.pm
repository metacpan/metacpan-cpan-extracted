package App::XScreenSaver::DBus::SaverProxy;
use v5.20;
use strict;
use warnings;
# this is the interface name
use Net::DBus::Exporter qw(org.freedesktop.ScreenSaver);
use parent 'Net::DBus::ProxyObject';
our $VERSION = '1.0.6'; # VERSION
# ABSTRACT: proxy dbus object

dbus_method('Inhibit',['string','string','caller'],['uint32']);
dbus_method('UnInhibit',['uint32','caller'],[]);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XScreenSaver::DBus::SaverProxy - proxy dbus object

=head1 VERSION

version 1.0.6

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
