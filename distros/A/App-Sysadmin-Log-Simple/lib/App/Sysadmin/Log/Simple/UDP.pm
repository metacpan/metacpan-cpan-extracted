package App::Sysadmin::Log::Simple::UDP;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;
use autodie qw(:socket);

# ABSTRACT: a UDP-logger for App::Sysadmin::Log::Simple
our $VERSION = '0.009'; # VERSION


sub new {
    my $class = shift;
    my %opts  = @_;
    my $app   = $opts{app};

    $app->{udp}->{host} ||= 'localhost';
    $app->{udp}->{port} ||= 9002;

    return bless {
        do_udp  => $app->{do_udp},
        udp     => $app->{udp},
        user    => $app->{user},
    }, $class;
}


sub log {
    my $self     = shift;
    my $logentry = shift;

    return unless $self->{do_udp};

    my $sock = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => $self->{udp}->{host},
        PeerPort    => $self->{udp}->{port},
    );
    carp "Couldn't get a socket: $!" unless $sock;

    if ($self->{udp}->{irc}) {
        my %irc = (
            normal      => "\x0F",
            bold        => "\x02",
            underline   => "\x1F",
            white       => "\x0300",
            black       => "\x0301",
            blue        => "\x0302",
            green       => "\x0303",
            lightred    => "\x0304",
            red         => "\x0305",
            purple      => "\x0306",
            orange      => "\x0307",
            yellow      => "\x0308",
            lightgreen  => "\x0309",
            cyan        => "\x0310",
            lightcyan   => "\x0311",
            lightblue   => "\x0312",
            lightpurple => "\x0313",
            grey        => "\x0314",
            lightgrey   => "\x0315",
        );

        my $ircline = $irc{bold} . $irc{green} . '(LOG)' . $irc{normal}
            . ' ' . $irc{underline} . $irc{lightblue} . $self->{user} . $irc{normal}
            . ': ' . $logentry . "\r\n";
        print $sock $ircline;
    }
    else {
        print $sock "(LOG) $self->{user}: $logentry\r\n";
    }
    $sock->shutdown(2);

    return "Logged to $self->{udp}->{host}:$self->{udp}->{port}";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Sysadmin::Log::Simple::UDP - a UDP-logger for App::Sysadmin::Log::Simple

=head1 VERSION

version 0.009

=head1 DESCRIPTION

This provides a log method that sends text over a UDP socket, optionally
with IRC colour codes applied. This can be used to centralize logging on
a single machine, or echo log entries to an IRC channel.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::UDP object. It takes a hash
of options:

=head3 udp

A hashref containing keys:

=over 4

=item host - default: localhost

=item port - default: 9002

=back

=head3 user

The user to attribute the log entry to

=head3 irc

Whether to apply IRC colour codes or not.

=head2 log

This creates a socket, and sends the log entry out, optionally applying IRC
colour codes to it.

=head1 AVAILABILITY

The project homepage is L<http://p3rl.org/App::Sysadmin::Log::Simple>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/App::Sysadmin::Log::Simple/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/App-Sysadmin-Log-Simple>
and may be cloned from L<git://github.com/doherty/App-Sysadmin-Log-Simple.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/App-Sysadmin-Log-Simple/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
