package CalDAV::Simple::Task;
$CalDAV::Simple::Task::VERSION = '0.01';
use 5.006;
use Moo 1.006;
use Carp qw/ croak /;
use DateTime;

has vcal_string => (is => 'ro');
has due         => (is => 'lazy');

my $extract_field = sub {
    my ($self, $field) = @_;

    if ($self->vcal_string =~ m!^${field}:(.*?)$!ms) {
        return $1;
    }
    else {
        croak "failed to get '$field' field out of CalDAV response (", $self->vcal_string, ")\n";
    }

};

foreach my $attribute (qw/ created summary status uid /) {
    has $attribute => (
                       is      => 'lazy',
                       builder => sub {
                           my $self = shift;
                           return $self->$extract_field(uc($attribute)) },
                      );
}

my $extract_xml_element = sub {
    my ($self, $tag) = @_;

    if ($self->vcal_string =~ m!<$tag>(.*?)</$tag>!ms) {
        return $1;
    }
    else {
        croak "failed to get <$tag> element out of CalDAV response (", $self->vcal_string, ")\n";
    }

};

has etag        => (is => 'lazy',
                    builder => sub {
                        my $self = shift;
                        return $self->$extract_xml_element('d:getetag');
                    });

has href        => (is => 'lazy',
                    builder => sub {
                        my $self = shift;
                        return $self->$extract_xml_element('d:href');
                    });


sub BUILD
{
    my $self = shift;

    # print STDERR $self->vcal_string, "\n";
}

sub _build_due
{
    my $self = shift;

    # The 'DUE' field can take two formats, either zulu time or with a timezone
    #       DUE;TZID=Europe/London:20150519T213000
    #       DUE:20150513T200129Z
    if ($self->vcal_string =~ m!^DUE(;TZID=(.*?))?:(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z?)$!ms) {
        my ($dummy, $tz, $year, $month, $day, $hour, $min, $sec, $zulu) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
        $tz = 'UTC' if !defined($tz) && $zulu eq 'Z';
        return DateTime->new(year => $year, month => $month, day => $day,
                             hour => $hour, minute => $min, second => $sec,
                             time_zone => $tz);
    }
    else {
        croak "failed to get 'DUE' field out of VTODO string\n";
    }
}

1;

=head1 NAME

CalDAV::Simple::Task - a data class representing one task (VTODO) in a CalCAV calendar

=head1 SYNOPSIS

 use CalDAV::Simple::Task;
 my $task = CalDAV::Simple::Task->new(vcal_string => $string);
 printf "task '%s' is due '%s'\n", $task->summary, $task->due;

=head1 DESCRIPTION

This module is used to hold details of a single task from a CalDAV calendar.
It is alpha quality code. I don't really know much about CalDAV, but I've
been hacking around until I could get what I wanted working.

=head1 METHODS

=head2 summary

The short description / title of the task.

=head2 status

The CalDAV STATUS string for the task. I haven't looked into the different
values this can take.

=head2 uid

The CalDAV UID for the task.

=head2 etag

The L<HTTP etag|http://en.wikipedia.org/wiki/HTTP_ETag> for the task.

=head2 href

The relative URL for the task.

=head2 due

A L<DateTime> instance holding the due date for the task.

=head2 created

When the task was created. This will currently be returned as an ISO 8601 date+time
string, I think. In the future I'll make this return a L<DateTime> instance as well.

=head2 vcal_string

This is the string returned from the CalDAV server for a single task.
It's basically the C<d:response> element:

 <d:response>
    ...
    <cal:calendar-data>
      BEGIN:VCALENDAR
      ...
      END:VCALENDAR
    </cal:calendar-data>
    ...
 </d:response>

Hopefully you won't have to deal with this.

=head2 delete_task

Takes a task (instance of L<CalDAV::Simple::Task>) and deletes it
from the calendar.

=head1 SEE ALSO

L<CalDAV::Simple> - the main module of this distribution, the C<tasks()>
method of which returns instances of C<CalDAV::Simple::Task>.

=head1 REPOSITORY

L<https://github.com/neilbowers/CalDAV-Simple>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


