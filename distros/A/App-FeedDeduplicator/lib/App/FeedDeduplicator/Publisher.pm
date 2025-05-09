=head1 NAME

App::FeedDeduplicator::Publisher - Publisher class for App::FeedDeduplicator

=head1 DESCRIPTION

This module is part of the App::FeedDeduplicator application. It is responsible for publishing the deduplicated entries to a specified format (Atom or JSON).

=head1 SYNOPSIS

    use App::FeedDeduplicator::Publisher;

    my $publisher = App::FeedDeduplicator::Publisher->new(
        entries => $deduplicated_entries,
        format  => 'Atom',
        max_entries => 10,
    );

    $publisher->publish();

=head1 METHODS

=head2 new

Creates a new instance of App::FeedDeduplicator::Publisher. The constructor accepts a list of entries, a format (Atom or JSON), and a maximum number of entries as parameters.
The entries should be an array reference containing hash references with the keys 'entry' and 'feed'.
The 'entry' key should contain an XML::Feed::Entry object, and the 'feed' key should contain a hash reference with the feed information.
The format should be either 'Atom' or 'JSON', and the maximum number of entries specifies how many entries to include in the output.

=head2 publish

The main method that publishes the deduplicated entries to the specified format (Atom or JSON).
It sorts the entries based on their issued, modified, updated, or date attributes and limits the output to the specified maximum number of entries.
It generates the output in the specified format and prints it to STDOUT.

=cut

use v5.38;
use feature 'class';
no warnings 'experimental::class';

class App::FeedDeduplicator::Publisher {
    use XML::Feed;
    use JSON::MaybeXS;

    field $entries     :param;
    field $format      :param //= 'Atom';
    field $max_entries :param //= 10;

    method publish {
        my @sorted = sort {
            ($b->{entry}->issued || $b->{entry}->modified || $b->{entry}->updated || $b->{entry}->date || 0)
                <=>
            ($a->{entry}->issued || $a->{entry}->modified || $a->{entry}->updated || $a->{entry}->date || 0)
        } @$entries;

        if (@sorted > $max_entries) {
          $#sorted = $max_entries - 1;
        }

        if ($format eq 'json') {
            say encode_json([ map { {
                title => $_->{entry}->title,
                link  => $_->{entry}->link,
                summary => $_->{entry}->summary->body,
                issued => $_->{entry}->issued && $_->{entry}->issued->iso8601,
                source_name => $_->{feed}{name},
                source_url  => $_->{feed}{web},
            } } @sorted ]);
        } else {
            my $feed = XML::Feed->new($format);
            $feed->title("Deduplicated Feed");
            $feed->add_entry($_) for @sorted;
            say $feed->as_xml;
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