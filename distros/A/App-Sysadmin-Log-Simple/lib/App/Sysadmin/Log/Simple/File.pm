package App::Sysadmin::Log::Simple::File;
use strict;
use warnings;
# ABSTRACT: a file-logger for App::Sysadmin::Log::Simple
our $VERSION = '0.009'; # VERSION

use Carp;
use Try::Tiny;
use autodie qw(:file :filesys);
use Path::Tiny;


sub new {
    my $class = shift;
    my %opts  = @_;
    my $app   = $opts{app};

    return bless {
        logdir          => path( $app->{logdir} || $opts{logdir} || qw(/ var log sysadmin) ),
        index_preamble  => $app->{index_preamble},
        view_preamble   => $app->{view_preamble},
        date            => $app->{date},
        user            => $app->{user},
        do_file         => $app->{do_file},
    }, $class;
}


sub view {
    my $self  = shift;
    my $year  = $self->{date}->year;
    my $month = $self->{date}->month;
    my $day   = $self->{date}->day;
    require IO::Pager;

    my $logfile = path($self->{logdir}, $year, $month, "$day.log");
    die "No log for $year/$month/$day\n" unless $logfile->is_file;

    my $logfh = $logfile->openr_utf8;
    local $STDOUT = IO::Pager->new(*STDOUT)
        unless $ENV{__PACKAGE__.' under test'};
    say($self->{view_preamble}) if $self->{view_preamble};
    print while (<$logfh>);
    close $logfh;

    return;
}


sub log {
    my $self = shift;
    my $line = shift;

    return unless $self->{do_file};

    $self->{logdir}->mkpath unless $self->{logdir}->is_dir;

    my $year  = $self->{date}->year;
    my $month = $self->{date}->month;
    my $day   = $self->{date}->day;

    my $dir = path($self->{logdir}, $year, $month);
    $dir->mkpath unless $dir->is_dir;
    my $logfile = path($self->{logdir}, $year, $month, "$day.log");

    # Start a new log file if one doesn't exist already
    unless ($logfile->is_file) {
        open my $logfh, '>>', $logfile;
        my $line = $self->{date}->day_name . ' ' . $self->{date}->month_name . " $day, $year";
        say $logfh $line;
        say $logfh '=' x length($line), "\n";
        close $logfh; # Explicitly close before calling generate_index() so the file is found
        $self->_generate_index();
    }

    open my $logfh, '>>', $logfile;
    my $timestamp = $self->{date}->hms;
    my $user = $ENV{SUDO_USER} || $ENV{USER}; # We need to know who wrote this
    say $logfh "    $timestamp $user:\t$line";

    # This might be run as root, so fix up ownership and
    # permissions so mortals can log to files root started
    my ($uid, $gid) = (getpwnam($self->{user}))[2,3];
    chown $uid, $gid, $logfile;
    chmod 0644, $logfile;

    return "Logged to $logfile";
}

sub _generate_index {
    my $self = shift;
    require File::Find::Rule;

    my $indexfh = path($self->{logdir}, 'index.log')->openw_utf8; # clobbers the file
    say $indexfh $self->{index_preamble} if defined $self->{index_preamble};

    # Find relevant log files
    my @files = File::Find::Rule->mindepth(3)->in($self->{logdir});
    my @dates;
    foreach (@files) {
        if (m{
            (?<year>\d{4})
            /
            (?<month>\d{1,2})
            /
            (?<day>\d{1,2})
        }x) { # Extract the date
            push @dates, [$+{year}, $+{month}, $+{day}];
        }
        else {
            warn "WTF: $_";
        }
    }
    # Sort by year, then by month, then by day
    @dates =    map  { $_->[0] }
                sort { $b->[1] <=> $a->[1] }
                map  { [ $_, $_->[0]*1000 + $_->[1]*10 + $_->[2] ] }
                @dates;

    # Keep track of
    my $lastyear  = 0;
    my $lastmonth = 0;
    for my $date (@dates) {
        my $year  = $date->[0];
        my $month = $date->[1];
        my $day   = $date->[2];

        if ($year != $lastyear) {
            say $indexfh "\n$year";
            say $indexfh "-" x length($year);
            $lastyear  = $year;
            $lastmonth = 0;
        }
        if ($month != $lastmonth) {
            say $indexfh "\n### $month ###\n";
            $lastmonth = $month;
        }
        if ($year == $lastyear and $month == $lastmonth) {
            say $indexfh "[$day]($year/$month/$day)"
        }
    }
    close $indexfh;
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Sysadmin::Log::Simple::File - a file-logger for App::Sysadmin::Log::Simple

=head1 VERSION

version 0.009

=head1 DESCRIPTION

This provides methods to App::Sysadmin::Log::Simple for logging to a file, and
viewing those log files.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::File object. It takes a hash of
options with keys:

=over 4

=item logdir

This specifies the top of the tree of log files. Default is F</var/log/sysadmin>.
Please note that unprivileged users are typically not permitted to create the
default log directory.

=item index_preamble

This is a string to place at the top of the index page.

=item view_preamble

This is a string to prepend when viewing the log files.

=item date

This is a DateTime object for when the log entry was made I<or> for specifying
which date's log file to view, depending on the mode of operation.

=back

=head2 view

This allows users to view a log file in a pager provided by L<IO::Pager>,
typically L<less(1)>.

=head2 log

This creates a new log file if needed, adds the log entry to it, and re-generates
the index file as necessary.

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
