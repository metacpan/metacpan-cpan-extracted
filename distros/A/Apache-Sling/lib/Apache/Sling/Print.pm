#!/usr/bin/perl -w

package Apache::Sling::Print;

use 5.008001;
use strict;
use warnings;
use Carp;
use Fcntl ':flock';
use File::Temp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub print_with_lock

sub print_with_lock {
    my ( $message, $file ) = @_;
    if ( defined $file ) {
        return print_file_lock( "$message", $file );
    }
    else {
        return print_lock("$message");
    }
}

#}}}

#{{{sub print_file_lock

sub print_file_lock {
    my ( $message, $file ) = @_;
    if ( open my $out, '>>', $file ) {
        flock $out, LOCK_EX or croak q{Unable to obtain exclusive lock};
        print {$out} $message . "\n" or croak q{Problem printing!};
        flock $out, LOCK_UN or croak q{Problem releasing exclusive lock};
        close $out or croak q{Problem closing!};
    }
    else {
        croak "Could not open file: $file";
    }
    return 1;
}

#}}}

#{{{sub print_lock

sub print_lock {
    my ($message) = @_;
    my ( $tmp_print_file_handle, $tmp_print_file_name ) =
      File::Temp::tempfile();
    if ( open my $lock, '>>', $tmp_print_file_name ) {
        flock $lock, LOCK_EX or croak q{Unable to obtain exclusive lock};
        print $message . "\n" or croak q{Problem printing!};
        flock $lock, LOCK_UN or croak q{Problem releasing exclusive lock};
        close $lock or croak q{Problem closing!};
        unlink($tmp_print_file_name);
    }
    else {
        croak q(Could not open lock on temporary file!);
    }
    return 1;
}

#}}}

#{{{sub print_result

sub print_result {
    my ($object) = @_;
    my $message = $object->{'Message'};
    if ( $object->{'Verbose'} >= 1 ) {
        $message .= "\n**** Status line was: ";
        $message .= ${ $object->{'Response'} }->status_line;
        if ( $object->{'Verbose'} >= 3 ) {
            $message .= "\n**** Full Content of Response was: \n";
            $message .= ${ $object->{'Response'} }->content;
        }
    }
    print_with_lock( $message, $object->{'Log'} );
    return 1;
}

#}}}

#{{{sub date_string

sub date_string {
    my ( $day_of_week, $month, $year_offset, $day_of_month, $hour, $minute,
        $sec )
      = @_;
    my @months    = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @week_days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    if ( $sec    =~ /^[0-9]$/msx ) { $sec    = "0$sec"; }
    if ( $minute =~ /^[0-9]$/msx ) { $minute = "0$minute"; }
    my $year = 1900 + $year_offset;
    return
"$week_days[$day_of_week] $months[$month] $day_of_month $hour:$minute:$sec";
}

#}}}

#{{{sub date_time

sub date_time {
    (
        my $sec,
        my $minute,
        my $hour,
        my $day_of_month,
        my $month,
        my $year_offset,
        my $day_of_week,
        my $day_of_year,
        my $daylight_savings
    ) = localtime;
    return date_string( $day_of_week, $month, $year_offset, $day_of_month,
        $hour, $minute, $sec );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::Print - functions used for printing by the Apache::Sling library.

=head1 ABSTRACT

useful utility functions for general print to screeen and print to file
functionality.

=head1 METHODS

=head2 print_with_lock

Selects printing to standard out or to log with locking based on whether a suitable log file is defined.

=head2 print_file_lock

Prints out a specified message to a specified file with locking in an attempt
to prevent competing threads or forks from stepping on each others toes when
writing to the file.

=head2 print_lock

Prints out a specified message with locking in an attempt to prevent competing
threads or forks from stepping on each others toes when printing to stdout.

=head2 print_result

Takes an object (user, group, site, etc) and prints out it's Message value,
appending a new line. Also looks at the verbosity level and if greater than or
equal to 1 will print extra information extracted from the object's Response
object. At the moment, won't print if log is defined, as the prints to log
happen elsewhere. TODO tidy that up.

=head2 date_time

Returns a current date time string, which is useful for log timestamps.

=head1 USAGE

use Apache::Sling::Print;

=head1 DESCRIPTION

Utility library providing useful utility functions for general Print
functionality.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
