# ABSTRACT: Find out whether results exist for cases
# PODNAME: App::Prove::Elasticsearch::Searcher::ByName

package App::Prove::Elasticsearch::Searcher::ByName;
$App::Prove::Elasticsearch::Searcher::ByName::VERSION = '0.001';
use strict;
use warnings;

use Search::Elasticsearch();
use File::Basename();
use Cwd();
use List::Util 1.45 qw{uniq};
use App::Prove::Elasticsearch::Utils();

sub new {
    my ($class, $conf, $indexer) = @_;

    my $v = App::Prove::Elasticsearch::Utils::require_versioner($conf);
    my $p = App::Prove::Elasticsearch::Utils::require_platformer($conf);

    return bless(
        {
            handle => Search::Elasticsearch->new(
                nodes => "$conf->{'server.host'}:$conf->{'server.port'}",
                request_timeout => 30
            ),
            index      => $indexer->index,
            versioner  => $v,
            platformer => $p,
        },
        $class
    );

}

sub filter {
    my ($self, @tests) = @_;

    return @tests unless $self->_has_results();

    my $platz = &{\&{$self->{platformer} . "::get_platforms"}}();

    my @tests_filtered;
    foreach my $test (@tests) {
        $test = Cwd::abs_path($test);
        my $tname    = File::Basename::basename($test);
        my $tversion = &{\&{$self->{versioner} . "::get_version"}}($test);
        my %q        = (
            index => $self->{index},
            body  => {
                query => {
                    bool => {
                        must => [
                            {
                                match => {
                                    name => $tname,
                                }
                            },
                            {
                                match => {
                                    version => $tversion,
                                }
                            },
                        ],
                    },
                },
                size => 1
            },
        );

        foreach my $plat (@$platz) {
            push(
                @{$q{body}{query}{bool}{must}},
                {match => {platform => $plat}}
            );
        }

        my $docs = $self->{handle}->search(%q);

        #OK, check if this document we got back *actually* matched
        if (!scalar(@{$docs->{hits}->{hits}})) {
            push(@tests_filtered, $test);
            next;
        }
        my $match = $docs->{hits}->{hits}->[0]->{_source};

        my @plats_match = (
            (ref($match->{platform}) eq 'ARRAY')
            ? @{$match->{platform}}
            : ($match->{platform})
        );

        my $name_correct    = $match->{name} eq $tname;
        my $version_correct = $match->{version} eq $tversion;
        my $plats_size_ok   = scalar(@plats_match) == scalar(@$platz);
        my $plats_are_same =
          scalar(@plats_match) ==
          scalar(uniq((@plats_match, @$platz)))
          ;    #XXX THIS IS WRONG, WHAT IF WE HAVE NO PLATZ
        my $plats_correct = $plats_size_ok && $plats_are_same;

        if ($name_correct && $version_correct && $plats_correct) {
            print
              "# Not going to execute $test, it already has results in elasticsearch for this version and platform\n";
            next;
        }

        push(@tests_filtered, $test);
    }
    return @tests_filtered;
}

sub get_test_replay {
    my ($self, $tversion, $platz, @tests) = @_;

    return @tests unless $self->_has_results();

    my @tests_filtered;
    foreach my $test (@tests) {
        my %q = (
            index => $self->{index},
            body  => {
                query => {
                    query_string => {
                        query => qq{name: "$test" AND version: "$tversion"},
                    },
                },
                size => 1
            },
        );

        foreach my $plat (@$platz) {
            $q{body}{query}{query_string}{query} .= qq{ AND platform: "$plat"};
        }

        my $docs = $self->{handle}->search(%q);

        #OK, check if this document we got back *actually* matched
        if (!scalar(@{$docs->{hits}->{hits}})) {
            push(
                @tests_filtered,
                {name => $test, status => 'UNTESTED', body => ''}
            );
            next;
        }
        push(@tests_filtered, $docs->{hits}->{hits}->[0]->{_source});
    }
    return @tests_filtered;
}

sub _has_results {
    my ($self) = @_;

    my $res = $self->{handle}->search(
        index => $self->{index},
        body  => {
            query => {match_all => {}},
            sort  => {id        => {order => "desc"}},
            size => 1
        }
    );

    my $hits = $res->{hits}->{hits};
    return 0 unless scalar(@$hits);

    return $res->{hits}->{total};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Searcher::ByName - Find out whether results exist for cases

=head1 VERSION

version 0.001

=head1 CONSTRUCTOR

=head2 new($server,$port,$index,[$versioner,$platformer])

Connect to the ES instance at $server:$port and check the provided index.
That should be defined by your indexer.

filter() requires knowledge of the versioner and platformer, so those must be passed as well.
They default to 'Default'.

=head1 METHODS

=head2 filter(@tests)

Filter out tests in your elasticsearch index matching the filename, platform and SUT version of the test result.
Designed to work with L<App::Prove::Elasticsearch::Indexer>.

=head2 get_test_replay($sut_version,$platforms,@tests)

Returns a hash describing the test result body and the global status of each test provided.

Must be filtered by the provided sut version and platforms (arrayref).

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://https://github.com/teodesian/App-Prove-Elasticsearch>
and may be cloned from L<git://https://github.com/teodesian/App-Prove-Elasticsearch.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
