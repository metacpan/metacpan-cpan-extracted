#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

start_stop_camel_pki.pl - Apache server for App::CamelPKI.

=head1 SYNOPSIS

    start_stop_camel_pki.pl < start | stop | restart | gdbstart >

=head1 DESCRIPTION

System V script to start/stop the Camel-PKI web server.

=over

=item B<start_stop_camel_pki.pl start>

=item B<start_stop_camel_pki.pl stop>

=item B<start_stop_camel_pki.pl restart>

Your usual System-V style daemon management subcommands.

=item B<start_stop_camel_pki.pl gdbstart>

Like C<start>, but runs Apache in gdb in the current terminal and does
not return until the debugger terminates.  As an additional bonus,
this script works around Emacs' braindamage and can therefore be
invoked from M-x gdb.

=cut

use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../blib/lib";

sub usage {
    require Pod::Usage;
    Pod::Usage::pod2usage( { -exitval => 1, -verbose => 1 } );
}

use App::CamelPKI; # FIXME: possible to load only one model, or, at least
              # to deactivate the Debug plugin?
use App::CamelPKI::Error;

my $apache = App::CamelPKI->model("WebServer")->apache;

die <<"MESSAGE" if (! $apache->is_operational);

The Key Ceremony has not been performed yet, and so it is not possible
to start Apache. Please, run the camel_pki_keyceremony.pl script first.

MESSAGE

if (@ARGV > 1 && $ARGV[$#ARGV - 1] eq "-fullname") {
    # Emacs braindamage fixup
    @ARGV = ($ARGV[$#ARGV]);
}
usage unless @ARGV == 1;

if ($ARGV[0] eq "start") {
    try {
        $apache->start;
    } catch App::CamelPKI::Error::OtherProcess with {
       die <<"MESSAGE" if $apache->is_wedged;

Apache is in an incorrect status, please stop it manually to solve
the issue by yourself.

MESSAGE
       die "Could not start Apache: " .
           $apache->tail_error_logfile();
   };
} elsif ($ARGV[0] eq "stop") {
    $apache->stop;
} elsif ($ARGV[0] eq "restart") {
    $apache->stop;
    $apache->start;
} elsif ($ARGV[0] eq "gdbstart") {
    $apache->start(-gdb => 1, -X => 1, -exec => 1);
} else {
    usage;
}

exit(0);
