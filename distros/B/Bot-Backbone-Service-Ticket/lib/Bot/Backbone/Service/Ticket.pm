package Bot::Backbone::Service::Ticket;
$Bot::Backbone::Service::Ticket::VERSION = '0.160490';
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
);

# ABSTRACT: a service for doing ticket lookups and summarizing


service_dispatcher as {
    also not_command respond_by_method 'name_that_issue';
};

no Bot::Backbone::Service; # <-- remove my as
use Class::Load qw( load_first_existing_class );
use Moose::Util::TypeConstraints; # <-- bring in their as
use Scalar::Util qw( blessed );
use List::MoreUtils qw( all );
use Try::Tiny;

subtype 'Bot::Backbone::Service::Ticket::TrackerList'
    => as 'ArrayRef'
    => where { all { blessed($_) && $_->does('Bot::Backbone::Service::Ticket::Tracker') } @$_ };

coerce 'Bot::Backbone::Service::Ticket::TrackerList'
    => from 'ArrayRef[HashRef]',
    => via { [ map {
            my $class = try {
                load_first_existing_class
                    "Bot::Backbone::Service::Ticket::Tracker::$_->{type}",
                    "Bot::Backbone::Service::Ticket::Tracker::" . ucfirst $_->{type},
                    "Bot::Backbone::Service::Ticket::Tracker::" . uc $_->{type},
                    $_->{type};
            }
            catch {
                if (/^Can't locate\b/) {
                    die "Unknown ticket tracker type $_->{type}. Is it installed?";
                }
                else {
                    die $_;
                }
            };

            $class->new($_);
       } @$_ ] };

no Moose::Util::TypeConstraints; # <-- remove their as
use Bot::Backbone::Service; # <-- bring in my as


has trackers => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Service::Ticket::TrackerList',
    required    => 1,
    coerce      => 1,
    traits      => [ 'Array' ],
    handles     => {
        'all_trackers' => 'elements',
    },
);


sub name_that_issue {
    my ($self, $message) = @_;

    my @titles;
    for my $tracker ($self->all_trackers) {
        push @titles, grep { defined } $tracker->titles_for_string($message->text);
    }

    return @titles;
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Ticket - a service for doing ticket lookups and summarizing

=head1 VERSION

version 0.160490

=head1 SYNOPSIS

    # And then in your bot configuration:
    service my_tickets => (
        service  => 'Ticket',
        trackers => [{
            type       => 'JIRA',
            uri        => 'http://company.atlassian.net/',
            username   => 'botuser',
            password   => 'secret',
            title      => 'Issue %{issue}s: %{summary}s',
            link       => 'https://company.atlassian.net/browse/%{issue}s',
            patterns   => [
                qr{(?<!/)\b(?<issue>[A-Za-z]+-\d+)\b},
                qr{(?<![\[])\b(?<schema>https:)//company\.atlassian\.net/browse/(?<issue>[A-Za-z]+-\d+)\b},
            ],
        }, {
            type     => 'FogBugz',
            base_url => 'https://company.fogbugz.com/api.asp',
            token    => 'gobbledygooksecretstuff',
            title    => 'Case #%{issue}s: %{summary}s',
            link     => 'http://example.com/mytickets/issue/%{issue}s',
            patterns => [
                qr{\bbugzid:(?<issue>\d+)\b},
                qr{(?<![\[])\b(?<scheme>https:)//company\.fogbugz\.com/f/cases/(?<issue>\d+)\b},
            ]
        }],
        send_policy => 'dont_repeat_too_often',
    );

=head1 DESCRIPTION

This module is the main reason most (maybe all, actually) of my work bots began their existence: to spew out the title and link to a ticket in the ticket/issue/case tracker application used by the company. When a ticket gets mentioned, the bot looks up the ticket, grabs the title and shares it with a link to the ticket with the group. That way it's easy for someone to say, "while working on #123, I ran into X problem" and everyone can be clued into the context without having to remember the ticket numbers, but the original poster can still be precise and let others look into the ticket details easily.

To use this module, you must install one of the ticket tracking systems or build your own. As of this writing, the following trackers are implemented:

=over

=item *

B<JIRA.> Install L<Bot::Backbone::Service::Ticket::Tracker::JIRA>

=item *

B<FogBugz.> Install L<Bot::Backbone::Service::Ticket::Tracker::FogBugz>

=back

To build your own, see L<Bot::Backbone::Service::Ticket::Tracker>. It is pretty simple.

Multiple ticket trackers can be defined in a single service configuration for simplicity. This is useful as most organizations have more than one or transition from one to another from time to time.

=head1 DISPATCHER

=head2 <mention ticket>

When one of the C<patterns> defined in the tracker configuration matches a message received, the L</name_that_method> method is called to respond.

This will trigger the L<Bot::Backbone::Service::Ticket::Tracker/lookup_issue> method on the tracker which is responsible for finding the named issue in the tracking system and returning the metadata describing it. If a matching ticket is actually found, the details will be announced as a reply. If nothing is returned, the bot is silent.

=head1 ATTRIBUTES

=head2 trackers

This is a list of trackers configured for this service. At least one tracker must be defined. The C<type> key is used to lookup the class implementing the C<lookup_issue> method for your tracking system. It can be the full name of the class or just the last part of the name if the class name is prefixed with "Bot::Backbone::Service::Ticket::Tracker::".

=head1 METHODS

=head2 name_that_issue

Implements the issue lookup and response.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
