use strict;
use warnings;

package App::gcal;
{
  $App::gcal::VERSION = '1.121460';
}

use Class::ReturnValue;
use Data::ICal;
use DateTime::TimeZone;

# ABSTRACT: Command Line Interface interface to Google Calendar.

# cache the timezone lookup
my $localTZ = DateTime::TimeZone->new( name => 'local' );

my $gcal;


# entry point
sub run {
    my ( $args, $username, $password ) = @_;

    # loop over args
    for my $arg (@$args) {

        my $cal;
        if ( ( -e $arg ) && ( -r $arg ) ) {

            # looks like a file
            $cal = _process_file($arg);

        }
        else {

            # give to ICal::QuickAdd
            $cal = _process_text($arg);
        }

        if ($cal) {
            _save_to_gcal( $cal, $username, $password );
        }
        else {
            print STDERR $cal->error_message . "\n";
        }
    }
}

# process an ics file
sub _process_file {
    my ($file) = @_;

    my $calendar = Data::ICal->new( filename => $file );
    unless ($calendar) {
        return _error("error parsing $file");
    }

    return $calendar;
}

# process a text event
sub _process_text {
    my ($text) = @_;

    my $error_msg = 'error parsing text';

    unless ($text) {
        return _error($error_msg);
    }

    require ICal::Format::Natural;
    my $calendar = ICal::Format::Natural::ical_format_natural($text);

    unless ( $calendar->isa('Data::ICal') ) {
        return _error($error_msg);
    }

    return $calendar;
}

# save event to Google Calendar
sub _save_to_gcal {
    my ( $cal, $username, $password ) = @_;

    unless ($gcal) {

        unless ( $username && $password ) {

            # get login and password from .netrc
            require Net::Netrc;
            my $netrc = Net::Netrc->lookup('google.com');

            unless ($netrc) {
                die(
                    'Error. Could not find your credentials in your .netrc file'
                );
            }

            $username = $netrc->login;
            $password = $netrc->password;
        }

        # login
        require Net::Google::Calendar;
        $gcal = Net::Google::Calendar->new;
        $gcal->login( $username, $password );
    }

    for my $entry ( @{ $cal->entries } ) {

        # create gcal event
        my $event = _create_new_gcal_event($entry);

        # save
        my $tmp = $gcal->add_entry($event);
        die "Couldn't add event: $@\n" unless defined $tmp;
    }
}

# converts Data::ICal to Net::Google::Calendar::Entry
sub _create_new_gcal_event {
    my ($entry) = @_;

    require Net::Google::Calendar::Entry;
    require DateTime::Format::ICal;

    my $event = Net::Google::Calendar::Entry->new();

    $event->title( $entry->property('summary')->[0]->value );

    # ensure the times are in the local timezone
    my $dtstart = DateTime::Format::ICal->parse_datetime(
        $entry->property('dtstart')->[0]->value );
    $dtstart->set_time_zone($localTZ);
    my $dtend = DateTime::Format::ICal->parse_datetime(
        $entry->property('dtend')->[0]->value );
    $dtend->set_time_zone($localTZ);
    $event->when( $dtstart, $dtend );

    $event->status('confirmed');

    # optional
    if ( $entry->property('description') ) {
        $event->content( $entry->property('description')->[0]->value );
    }
    if ( $entry->property('location') ) {
        $event->location( $entry->property('location')->[0]->value );
    }

    return $event;
}

# return an error
sub _error {
    my $msg = shift;

    my $ret = Class::ReturnValue->new;
    $ret->as_error( errno => 1, message => $msg );
    return $ret;
}


1;

__END__
=pod

=head1 NAME

App::gcal - Command Line Interface interface to Google Calendar.

=head1 VERSION

version 1.121460

=head1 SYNOPSIS

  gcal --help

  gcal [events.ical, 'tomorrow at noon. Lunch with Bob', ...]

  gcal --username="bill" --password="1234" [events.ical, 'tomorrow at noon. Lunch with Bob', ...]

=head1 DESCRIPTION

The C<gcal> command provides a quick and easy interface to Google Calendar from the command line.

Before using the C<gcal> command, you need to provide your Google credentials. The most convenient way to do this is by using your C<~.netrc> file and supplying credentials for the C<google.com> machine. For example:

  machine google.com
  login bill
  password 1234

NOTE: On Windows, your C<.netrc> file is at C<%HOME%.netrc>.

NOTE 2: On Unix, ensure your C<~.netrc> file has the permissions set to 600.

Alternatively, you can pass the username and password as a parameter to C<gcal>, as follows:

  gcal --username="bill" --password="1234"

You can then pass one or more C<.ics> files to the C<gcal> command and it will be added to your Google Calendar.

You can also pass one or more strings to the C<gcal> command, which will attempt to parse it and create a new event. It uses L<ICal::QuickAdd> to parse, so has the same functionality and limitations.

=head2 Using Google's Two Factor Authentication

If you are using L<Google's two factor authentication|http://googleblog.blogspot.co.uk/2011/02/advanced-sign-in-security-for-your.html> (and you L<really should be|http://www.codinghorror.com/blog/2012/04/make-your-email-hacker-proof.html>), you will need to generate a new application-specific password for C<gcal>. Save that in your C<.netrc> file and use C<gcal> as normal.

=for Pod::Coverage run

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

