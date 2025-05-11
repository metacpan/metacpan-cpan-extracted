=head1 NAME

App::FeedDeduplicator::Aggregator - Aggregator class for App::FeedDeduplicator

=head1 DESCRIPTION

This module is part of the App::FeedDeduplicator application. It is responsible for aggregating feeds from multiple sources.
It fetches the feeds using LWP::UserAgent and parses them using XML::Feed. The aggregated entries are stored in a list for further processing.
It is designed to be used in conjunction with the Deduplicator and Publisher classes to provide a complete feed deduplication and publishing solution.
It is part of a larger application that aggregates, deduplicates, and publishes feeds.
It is designed to be extensible, allowing for additional features and functionality to be added in the future.

=head1 SYNOPSIS

    use App::FeedDeduplicator::Aggregator;

    my $aggregator = App::FeedDeduplicator::Aggregator->new(
        feeds => [
            { name => 'Feed 1', feed => 'http://example.com/feed1', web => 'http://example.com' },
            { name => 'Feed 2', feed => 'http://example.com/feed2', web => 'http://example.com' },
        ],
        ua => LWP::UserAgent->new(),
    );

    $aggregator->aggregate();

=head1 METHODS

=head2 new

Creates a new instance of App::FeedDeduplicator::Aggregator. The constructor accepts a list of feeds and a user agent as parameters.
The feeds should be an array reference containing hash references with the keys 'name', 'feed', and 'web'.
The user agent should be an instance of LWP::UserAgent.

=head2 aggregate

The main method that aggregates feeds from the specified sources. It fetches each feed using the provided user agent and parses it using XML::Feed.
It stores the aggregated entries in a list for further processing. The entries are stored as hash references containing the entry and the corresponding feed information.
It is designed to be used in conjunction with the Deduplicator and Publisher classes to provide a complete feed deduplication and publishing solution.

=cut 

use v5.40;
use feature 'class';
no warnings 'experimental::class';

class App::FeedDeduplicator::Aggregator {
    use XML::Feed;
    use LWP::UserAgent;

    field $feeds :param;
    field $ua :param;
    field $entries :reader;

    method aggregate {

        for (@$feeds) {
            my $response = $ua->get($_->{feed});
            unless ($response->is_success) {
              warn "$_->{feed}\n";
              warn $response->status_line, "\n";
              next;
            }

            my $feed = XML::Feed->parse(\$response->decoded_content);
            unless ($feed) {
              warn "Unable to parse $_->{feed}\n";
              next;
            }

            for my $entry ($feed->entries) {
                push @$entries, {
                    entry => $entry,
                    feed => $_,
                }
            }
        }
    }
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 Magnum Solutions Ltd.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/artistic.html> for more details.

=cut

1;
