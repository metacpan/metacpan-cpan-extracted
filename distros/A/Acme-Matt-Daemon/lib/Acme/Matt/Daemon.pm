package Acme::Matt::Daemon;

use warnings;
use strict;

=head1 MATT DAEMON

=head1 NAME

Acme::Matt::Daemon - MATT DAEMON

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use vars qw/@ISA @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/MATT DAEMON DAMON MATTDAMON MATTDAEMON/;

use Log::Syslog::Abstract qw/openlog syslog closelog/;
use Proc::Daemon;

sub MATT {
}

my @interval = map { $_ * 60 } qw/15 60/;
$interval[1] -= $interval[0];

sub DAEMON {

    print "MATT DAEMON\n";

    Proc::Daemon::Init;

    while (1) {
        openlog( 'matt-daemon', '', 'local0' );

        syslog( 'info', '%s', 'MATT DAEMON' );

        closelog;

        sleep($interval[0] + int rand $interval[1]);
    }
}

*DAMON = \&DAEMON;
*MATTDAMON = \&DAEMON;
*MATTDAEMON = \&DAEMON;

=head1 SYNOPSIS

MATT DAEMON

    perl -MAcme::Matt::Daemon -e 'MATT DAEMON'

=head1 DESCRIPTION

MATT DAEMON

L<http://www.youtube.com/watch?v=ZWTzyU5MFgM>

L<Acme::Matt::Daemon> will daemonize and output MATT DAEMON to your syslog at every 15 to 60 minutes (randomly). Enjoy!

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-matt-daemon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Matt-Daemon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Matt::Daemon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Matt-Daemon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Matt-Daemon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Matt-Daemon>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Matt-Daemon/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 MATT DAEMON

=cut

'MATT DAEMON'; # End of Acme::Matt::Daemon
