=head1 NAME

App::FeedDeduplicator::Deduplicator - Deduplicator class for
App::FeedDeduplicator

=head1 DESCRIPTION

This module is part of the App::FeedDeduplicator application. It is
responsible for deduplicating entries from aggregated feeds.

It uses the LWP::UserAgent to fetch the feeds and HTML::TreeBuilder::XPath
to parse the HTML content for canonical links.

The deduplication process is based on the entry's, id canonical link or title.
The deduplicated entries are stored in an array for further processing. It is
designed to be used in conjunction with the Aggregator and Publisher classes
to provide a complete feed deduplication and publishing solution.

=head1 SYNOPSIS

    use App::FeedDeduplicator::Deduplicator;

    my $deduplicator = App::FeedDeduplicator::Deduplicator->new(
      entries => $aggregated_entries,
      ua      => LWP::UserAgent->new(),
    );

    $deduplicator->deduplicate();

=head1 METHODS

=head2 new

Creates a new instance of App::FeedDeduplicator::Deduplicator. The constructor
accepts a list of entries and a user agent as parameters.

The entries should be an array reference containing hash references with the
keys 'entry' and 'feed'.

The 'entry' key should contain an XML::Feed::Entry object, and the 'feed' key
should contain a hash reference with the feed information.

The user agent should be an instance of LWP::UserAgent.

=head2 deduplicate

The main method that deduplicates entries from the aggregated feeds. It
iterates through the entries and checks for duplicates based on the id,
canonical link or title.

It uses a hash to keep track of seen entries and filters out duplicates. The
deduplicated entries are stored in the $deduplicated attribute.

It is designed to be used in conjunction with the Aggregator and Publisher
classes to provide a complete feed deduplication and publishing solution.

=head2 find_canonical

Finds the canonical link for a given entry. It fetches the entry's link using
LWP::UserAgent and parses the HTML content using HTML::TreeBuilder::XPath.

It looks for the <link rel="canonical"> tag in the HTML content and returns
the canonical URL if found. If the canonical link is not found, it returns
undef.

It is used during the deduplication process to determine the unique
identifier for each entry.

=cut

package App::FeedDeduplicator::Deduplicator; # For MetaCPAN

use v5.40;
use feature 'class';
no warnings 'experimental::class';

class App::FeedDeduplicator::Deduplicator {
  use HTML::TreeBuilder::XPath;
  use LWP::UserAgent;
  use URI;

  field $entries :param;
  field $deduplicated :reader;
  field $ua :param;

  method deduplicate {
    my %seen;
    my @result;

    for my $entry (@$entries) {
      # warn ref($entry) . "\n" . ref($entry->{entry}) . "\n";
      my $canonical = $self->find_canonical($entry->{entry}) // '';
      my $title = $entry->{entry}->title // '';

      push @result, $entry
        unless ($canonical and $seen{$canonical})
            or ($title     and $seen{$title});

      ++$seen{$canonical} if $canonical;
      ++$seen{$title}     if $title;
    }

    $deduplicated = \@result;
  }

  method find_canonical ($entry) {
    my $link = $entry->link;
    return unless $link;

    my $response = $ua->get($link);
    return unless $response->is_success;

    my $tree = HTML::TreeBuilder::XPath->new_from_content(
      $response->decoded_content
    );
    my $node = $tree->findnodes('//link[@rel="canonical"]')->[0];

    return unless $node;
    return URI->new($node->attr('href'))->as_string;
  }
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 Magnum Solutions Ltd.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html> for more details.

=cut

1;
