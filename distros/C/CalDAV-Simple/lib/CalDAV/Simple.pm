package CalDAV::Simple;

use 5.006;
use strict;
use warnings;
use Moo 1.006;
use Carp            qw/ croak /;
use CalDAV::Simple::Task;

our $VERSION = '0.01';

has ua => (
    is      => 'ro',
    default => sub {
                   require HTTP::Tiny;
                   require IO::Socket::SSL;
                   return HTTP::Tiny->new(agent => __PACKAGE__.'/'.$VERSION);
               },
);

has calendar         => (is => 'ro');
has username         => (is => 'ro'); 
has password         => (is => 'ro'); 
has croak_on_failure => (is => 'ro', default => sub { 1 });
has _url             => (is => 'lazy');

sub _build__url
{
    my $self = shift;
    
    # This is a hack for doing basic auth
    if ($self->calendar =~ m!^(https?://)(.*)$!) {
        return $1.$self->username.':'.$self->password.'@'.$2;
    }
    else {
        # This is probably my fault :-)
        croak sprintf("unexpected format calendar '%s'\n",
                      $self->calendar);
    }
}

my $request = sub {
    my $self  = shift;
    my $param = shift;

    return $self->ua->request($param->{verb}, $param->{url},
                              {
                               headers => $param->{headers},
                               content => $param->{content},
                              });
};

sub tasks
{
    my $self = shift;
    my $body = '<?xml version="1.0" encoding="utf-8"?><c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><d:getetag/><c:calendar-data/></d:prop><c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VTODO"/></c:comp-filter></c:filter></c:calendar-query>';
    my $response = $self->$request({
        verb    => 'REPORT',
        url     => $self->_url,
        content => $body,
        headers => {
                    'Depth'        => 1,
                    'Prefer'       => 'return-minimal',
                    'Content-Type' => 'application/xml; charset=utf-8',
                   },
    });
    if ($response->{success}) {
        my @tasks;
        while ($response->{content} =~ m!<d:response>(.*?)</d:response>!msg) {
            push(@tasks, CalDAV::Simple::Task->new(vcal_string => $1));
        }
        return @tasks;
    }
    else {
        return undef unless $self->croak_on_failure;

        # TODO: make some effort to determine what kind of failure :-)
        croak "failed to get tasks\n";
    }
}

sub delete_task
{
    my ($self, $task) = @_;
    my $response = $self->$request({
        verb    => 'DELETE',
        url     => $self->_url.'/'.$task->uid.'.ics',
        headers => {
                    'If-Match'     => $task->etag,
                    'Content-Type' => 'application/xml; charset=utf-8',
                   },
    });
}


1;

=head1 NAME

CalDAV::Simple - a simple interface to calendar services via a subset of CalDAV

=head1 SYNOPSIS

 use CalDAV::Simple;

 my $cal = CalDAV::Simple->new(
               username => $username,
               password => $password,
               calendar => $url,
           );

 my @tasks = $cal->tasks;

 foreach my $task (@tasks) {
   printf "task '%s' is due '%s'\n", $task->summary, $task->due;
 }

=head1 DESCRIPTION

This is a ALPHA quality module for talking to a CalDAV server.
Currently it just provides an interface for getting tasks
and deleting individual tasks.

This distribution is currently a lash-up: I hacked together something to
solve a problem. It does things the quick dirty way, and the interface
is likely to change from release to release. So far I've only tested it
against L<fruux.com|http://fruux.com>'s CalDAV server: I've no idea if
it will work with other servers yet. Please let me know either way.

=head1 METHODS

=head2 new

This expects three attributes: username, password, and calendar.
The latter is the URL for your calendar.

=head2 tasks

Returns a list of all tasks in the calendar.
Each entry in the list is an instance of L<CalDAV::Simple::Task>.
Look at the document for that module to see what attributes are provided.

=head2 delete_task

Takes a task (instance of L<CalDAV::Simple::Task>) and deletes it
from the calendar.

=head1 LIMITATIONS

This is very much alpha quality and has only been tested against one CalDAV server.
The XML returned by the server is currently handled with regular expressions,
and I haven't read any specs to find out what range of results I can expect.

In short: your mileage may vary :-)

=head1 SEE ALSO

L<CalDAV::Simple::Task> - instances of this are returned by the C<tasks()> method,
and expected as the argument to the C<delete_task()> method.

L<Building a CalDAV client|http://sabre.io/dav/building-a-caldav-client/> -
documentation about CalDAV, which I've been using as a guide when hacking this up.

L<Wikipedia page|http://en.wikipedia.org/wiki/CalDAV> - about CalDAV.

=head1 REPOSITORY

L<https://github.com/neilbowers/CalDAV-Simple>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

