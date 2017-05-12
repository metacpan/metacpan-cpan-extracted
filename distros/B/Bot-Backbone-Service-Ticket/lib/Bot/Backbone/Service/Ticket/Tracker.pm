package Bot::Backbone::Service::Ticket::Tracker;
$Bot::Backbone::Service::Ticket::Tracker::VERSION = '0.160490';
use v5.10;
use Moose::Role;

use String::Errf qw( errf );
use Try::Tiny;

# ABSTRACT: role implemented by ticket lookup whatsits


has title => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has link => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_link',
);


has patterns => (
    is          => 'ro',
    isa         => 'ArrayRef[RegexpRef]',
    required    => 1,
);


requires 'lookup_issue';


sub titles_for_string {
    my ($self, $string) = @_;

    my @titles;
    for my $pattern (@{ $self->patterns }) {
        while ($string =~ /$pattern/g) {
            my $issue  = $+{issue};
            my $scheme = $+{scheme};
            my $title  = $self->issue_title($issue, !defined($scheme));
            push @titles, $title if defined $title;
        }
    }

    return @titles;
}


sub issue_title {
    my ($self, $number, $show_url) = @_;

    my $result;
    try {
        my $issue = $self->lookup_issue($number);
        $result = errf($self->title, $issue);

        $result .= $self->issue_link($issue)
            if $show_url and $self->has_link;
    }
    catch {
        warn "Ticket $number not found: " . $_;
    };

    return $result;
}


sub issue_link {
    my ($self, $issue) = @_;
    return ' <' . errf($self->link, $issue) . '>';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Ticket::Tracker - role implemented by ticket lookup whatsits

=head1 VERSION

version 0.160490

=head1 SYNOPSIS

    # To make a new ticket tracker lookup whatsit...
    package Bot::Backbone::Service::Ticket::Tracker::MyTicketSystem;
    use Moose;

    with qw( Bot::Backboen::Service::Ticket::Tracker );

    use WebService::MyTicketSystem;

    has uri        => ( is => 'ro', isa => 'Str', required => 1 );
    has auth_token => (is => 'ro', isa => 'Str', required => 1 );

    sub lookup_issue {
        my ($self, $number) = @_;

        my $tracker = WebService::MyTicketSystem->new(
            uri   => $self->uri,
            token => $self->auth_token,
        );

        my $issue = $tracker->lookup($number);

        return {
            summary => $issue->title,
            issue   => $issue->id,
            details => $issue->description,
        };
    }

    __PACKAGE__->meta->make_immutable;

    # And then in your bot configuration:
    service my_tickets => (
        service  => 'Ticket',
        trackers => [{
            type       => 'MyTicketSystem',
            uri        => 'http://api.example.com/mytickets',
            auth_token => 'gobbledygooksecretstuff',
            title      => 'Ticket #%{issue}s: %{summary}s',
            link       => 'http://example.com/mytickets/issue/%{issue}s',
            patterns   => [
                qr{\bmy:(?<issue>\d+)\b},
                qr{{(?<issue>\d+)}},
                qr{(?<![\[])\b(?<scheme>http:)//example\.com/mytickets/issue/(?<issue>\d+)\b},
            ]
        }],
    );

=head1 DESCRIPTION

This is the role implemented by a ticket tracking system to perform lookups.

=head1 ATTRIBUTES

=head2 title

I<Required.> This is a L<String::Errf> format pattern used to create the title
of the issue to return to chat. it will be passed the hash returned by
L</lookup_issue> to fill.

=head2 link

I<Optional.> This is a L<String::Errf> format pattern used to create a link when
needed. It will be passed the hash returned by L</lookup_issue> to fill.

If not given, links will never be shown.

=head2 patterns

I<Required.> This is an array of regular expressions that match issues in some
text. Each one must use named pattern groups and must include at least an
"issue" group. It may also contain a "scheme" group. The "issue" is the issue
number and the "scheme" is used to identify whether or not the matched pattern
contains a link. The actual content of "scheme" is ignored, but is usually
"http:" or "https:".

Since every company and workgroup has its own nomenclature, the patterns are
almost always context-specific, so there are generally no default patterns.
There is nothing stopping some ticket tracker from implementing such default,
though.

=head1 REQUIRED METHODS

=head2 lookup_issue

  my %info = %{ $service->lookup_issue($number) };

Given an issue identifier found using one of the L</patterns>, this should
return a hash of information to be used with L</title> and L</link> to render
that information back to the end-user.

=head1 METHODS

=head2 titles_for_string

  my @titles = $service->titles_for_string($string);

Given a string to evaluate, return all the titles of all the issues found in it.

=head2 issue_title

  my $title = $service->issue_title($number, $show_url);

This method is passed the result of a matching pattern from L</patterns>. The
first argument is "issue" match and the second is based on the presence of a
"scheme" in the match. If a "scheme" is found then C<$show_url> will be false
(i.e., they already have the link, we don't need to send it again).

This method calls L</lookup_issue> to get information about the issue and uses
that to generate the title.

The result is built using the L</title> and L</link> attribute values.

=head2 issue_link

  my $link = $service->issue_link(\%issue);

Returns the link text to use. Passed the issue hash returned by
L</lookup_issue>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
