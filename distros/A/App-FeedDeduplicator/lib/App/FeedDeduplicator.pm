=head1 NAME

App::FeedDeduplicator - A simple feed deduplicator

=head1 SYNOPSIS

    use App::FeedDeduplicator;

    my $deduplicator = App::FeedDeduplicator->new();
    $deduplicator->run();

=head1 DESCRIPTION

App::FeedDeduplicator is a simple Perl application that aggregates, deduplicates, and publishes feeds.
It uses the XML::Feed module to parse feeds and LWP::UserAgent to fetch them. The deduplication process is based on the entry's unique identifier.
The application can output the deduplicated feed in either Atom or JSON format.
It is designed to be run from the command line, and it can be configured using a JSON configuration file.
The configuration file should specify the feeds to be aggregated, the output format, and the maximum number of entries to include in the output.
The application is designed to be extensible, allowing for additional features and functionality to be added in the future.

=head1 CONFIGURATION

The configuration file is a JSON file that specifies the feeds to be aggregated, the output format, and the maximum number of entries to include in the output.
The configuration file should be located at ~/.feed-deduplicator/config.json by default, but this can be overridden by setting the FEED_DEDUP_CONFIG environment variable.
The configuration file should have the following structure:

    {
        "feeds": [
            {
                "name": "Feed Name",
                "feed": "http://example.com/feed",
                "web": "http://example.com"
            }
        ],
        "output_format": "Atom",
        "max_entries": 10
    }

=head1 METHODS

=head2 new

Creates a new instance of App::FeedDeduplicator. The constructor accepts a configuration file path as an optional parameter.
If the configuration file is not provided, it defaults to ~/.feed-deduplicator/config.json or the path specified by the FEED_DEDUP_CONFIG environment variable.

=head2 run

The main method that runs the application. It aggregates feeds, deduplicates entries, and publishes the output.
It creates instances of the Aggregator, Deduplicator, and Publisher classes and calls their respective methods to perform the operations.

=cut

package App::FeedDeduplicator;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

our $VERSION = '0.3.1';

class App::FeedDeduplicator {
    use App::FeedDeduplicator::Aggregator;
    use App::FeedDeduplicator::Deduplicator;
    use App::FeedDeduplicator::Publisher;
    use JSON::MaybeXS;
    use File::Spec;
    use File::HomeDir;

    field $config_file :param //= $ENV{FEED_DEDUP_CONFIG}
        // File::Spec->catfile(File::HomeDir->my_home, '.feed-deduplicator', 'config.json');

    field $config = do { 
        unless (-e $config_file) {
            die "Configuration file not found: $config_file\n";
        }

        open my $fh, '<', $config_file or die "Can't read config file: $config_file\n";
        decode_json(do { local $/; <$fh> });
    };

    field $ua = LWP::UserAgent->new(
      timeout => 5,
      agent => 'App::FeedDeduplicator',
    );

    method run () {
        my $aggregator =
            App::FeedDeduplicator::Aggregator->new(
                feeds => $config->{feeds},
                ua    => $ua,
            );
        $aggregator->aggregate;

        my $deduplicator =
            App::FeedDeduplicator::Deduplicator->new(
                entries => $aggregator->entries,
                ua      => $ua,
            );
        $deduplicator->deduplicate;

        my $publisher =
            App::FeedDeduplicator::Publisher->new(
                entries     => $deduplicator->deduplicated,
                format      => $config->{output_format} // 'Atom',
                max_entries => $config->{max_entries} // 10,
            );
        $publisher->publish;
    }
}

=head1 AUTHOR

Dave Cross, <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 Magnum Solutions Ltd.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/artistic.html> for more details.

=cut

