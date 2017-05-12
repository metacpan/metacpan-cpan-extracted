package App::ProcTrends::Config;

use 5.006;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp;

=head1 NAME

App::ProcTrends::Config - The great new App::ProcTrends::Config!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use App::ProcTrends::Config;

    my $cfg = App::ProcTrends::Config->new();
    my $value = $cfg->some_key();

=head1 SUBROUTINES/METHODS

=head2 new

    The constructor.

=cut

sub new {
    my $class = shift;
    my $self = {
        RRD_DIR             => '/tmp',
        CRON_TIMEOUT        => 60,
        CRON_PS_CMD         => find_cron_ps_cmd(),
        CRON_CPU_CORES      => find_cpu_cores(),
        CRON_CPU_THRESHOLD  => 0,
        CRON_RSS_THRESHOLD  => 0,
        CRON_RSS_UNIT       => 'mb',
        CRON_RRD_RRA        => [ qw/
            --step=60
            RRA:AVERAGE:0.5:1:23040
            RRA:AVERAGE:0.5:10:9216
            RRA:AVERAGE:0.5:60:18432
        / ],
        CRON_RRD_DS             => "GAUGE:120:0:U",
        COMMANDLINE_START       => '-1d',
        COMMANDLINE_END         => 'now',
        COMMANDLINE_INTERVAL    => 30,
        COMMANDLINE_PROCS       => undef,
        COMMANDLINE_COMMAND     => 'table',
        RRD_START               => '-1d',
        RRD_END                 => 'now',
        RRD_LINE                => 'AREA',
        RRD_STACK               => 'STACK',
        RRD_IMGFORMAT           => 'PNG',
        RRD_TITLE               => "<%METRIC%> for <%PROCESS%>",
        RRD_WIDTH               => 800,
        RRD_HEIGHT              => 600,
    };
    
    __PACKAGE__->mk_ro_accessors( keys %{ $self } );
    return bless $self, $class;
}

=head2 find_cron_ps_cmd

    Tries to find ps then construct the ps command to use

=cut

sub find_cron_ps_cmd {
    chomp( my $ps = `which ps` );
    if ( $ps && -x $ps ) {
        return "$ps axo pcpu,rss,args";
    }
    croak "ps not found";
}

=head2 find_cpu_cores

    Tries to determine the # of cores on the system.  If it could not detect, it will default to 1.

=cut

sub find_cpu_cores {
    my $file = "/proc/cpuinfo";
    
    if ( -f $file ) {
        open( my $fh, "<", $file ) or die "Couldn't open $file: $!\n";
        my @lines = <$fh>;
        my $count = grep( /core id/, @lines );
        return $count;
    }
    return 1;
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-proctrends-cron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ProcTrends-Cron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ProcTrends::Config


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ProcTrends-Cron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ProcTrends-Cron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ProcTrends-Cron>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ProcTrends-Cron/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Satoshi Yagi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::ProcTrends::Config
