# ABSTRACT: Define what data is to be uploaded to elasticsearch, and handle it's uploading
# PODNAME: App::Prove::Elasticsearch::Indexer

package App::Prove::Elasticsearch::Indexer;
$App::Prove::Elasticsearch::Indexer::VERSION = '0.001';
use strict;
use warnings;

use App::Prove::Elasticsearch::Utils();

use Search::Elasticsearch();
use List::Util 1.33;

our $index = 'testsuite';

sub index {
    return $index;
}

our $max_query_size = 1000;
our $e;
our $bulk_helper;
our $idx;

sub check_index {
    my $conf = shift;

    my $port = $conf->{'server.port'} ? ':' . $conf->{'server.port'} : '';
    die "server must be specified" unless $conf->{'server.host'};
    die("port must be specified")  unless $port;
    my $serveraddress = "$conf->{'server.host'}$port";
    $e //= Search::Elasticsearch->new(
        nodes => $serveraddress,
    );

    #XXX for debugging
    #$e->indices->delete( index => $index );

    if (!$e->indices->exists(index => $index)) {
        $e->indices->create(
            index => $index,
            body  => {
                index => {
                    number_of_shards   => "3",
                    number_of_replicas => "2",
                    similarity         => {default => {type => "classic"}}
                },
                analysis => {
                    analyzer => {
                        default => {
                            type      => "custom",
                            tokenizer => "whitespace",
                            filter    => [
                                'lowercase', 'std_english_stop', 'custom_stop'
                            ]
                        }
                    },
                    filter => {
                        std_english_stop => {
                            type      => "stop",
                            stopwords => "_english_"
                        },
                        custom_stop => {
                            type      => "stop",
                            stopwords => [ "test", "ok", "not" ]
                        }
                    }
                },
                mappings => {
                    testsuite => {
                        properties => {
                            id       => {type => "integer"},
                            elapsed  => {type => "integer"},
                            occurred => {
                                type   => "date",
                                format => "yyyy-MM-dd HH:mm:ss"
                            },
                            executor => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            status => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            version => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            test_version => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            platform => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            path => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            defect => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            steps_planned => {type => "integer"},
                            body          => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                            },
                            name => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            steps => {
                                properties => {
                                    number  => {type => "integer"},
                                    text    => {type => "text"},
                                    status  => {type => "text"},
                                    elapsed => {type => "integer"},
                                }
                            },
                        }
                    }
                }
            }
        );
        return 1;
    }
    return 0;
}

sub index_results {
    my ($result) = @_;

    die("check_index must be run first") unless $e;

    $idx //= App::Prove::Elasticsearch::Utils::get_last_index($e, $index);
    $idx++;

    $e->index(
        index => $index,
        id    => $idx,
        type  => $index,
        body  => $result,
    );

    my $doc_exists =
      $e->exists(index => $index, type => 'testsuite', id => $idx);
    if (!defined($doc_exists) || !int($doc_exists)) {
        die
          "Failed to Index $result->{'name'}, could find no record with ID $idx\n";
    } else {
        print
          "Successfully Indexed test: $result->{'name'} with result ID $idx\n";
    }
}

sub bulk_index_results {
    my @results = @_;
    $bulk_helper //= $e->bulk_helper(
        index => $index,
        type  => $index,
    );

    $idx //= App::Prove::Elasticsearch::Utils::get_last_index($e, $index);

    $bulk_helper->index(map { $idx++; {id => $idx, source => $_} } @results);
    $bulk_helper->flush();
}

sub associate_case_with_result {
    my %opts = @_;

    die("check_index must be run first") unless $e;

    my %q = (
        index => $index,
        body  => {
            query => {
                bool => {
                    must => [
                        {
                            match => {
                                name => $opts{case},
                            }
                        },
                    ],
                },
            },
        },
    );

    #It's normal to have multiple platforms in a document.
    foreach my $plat (@{$opts{platforms}}) {
        push(@{$q{body}{query}{bool}{must}}, {match => {platform => $plat}});
    }

    #It's NOT normal to have multiple versions in a document.
    foreach my $version (@{$opts{versions}}) {
        push(
            @{$q{body}{query}{bool}{should}},
            {match => {version => $version}}
        );
    }

    #Paginate the query, TODO short-circuit when we stop getting results?
    my $hits = App::Prove::Elasticsearch::Utils::do_paginated_query(
        $e, $max_query_size,
        %q
    );
    return 0 unless scalar(@$hits);

    #Now, update w/ the defect.
    my $failures = 0;
    my $attempts = 0;
    foreach my $hit (@$hits) {
        $hit->{_source}->{platform} = [ $hit->{_source}->{platform} ]
          if ref($hit->{_source}->{platform}) ne 'ARRAY';
        next if (scalar(@{$opts{versions}}) && !$hit->{_source}->{version});
        next
          unless List::Util::any { $hit->{_source}->{version} eq $_ }
        @{$opts{versions}};
        next if (scalar(@{$opts{platforms}}) && !$hit->{_source}->{platform});
        next unless List::Util::all {
            my $p = $_;
            grep { $_ eq $p } @{$hit->{_source}->{platform}}
        }
        @{$opts{platforms}};
        next unless $hit->{_source}->{name} eq $opts{case};

        $attempts++;

        #Merge the existing defects with the ones we are adding in
        $hit->{defect} //= [];
        my @df_merged =
          List::Util::uniq((@{$hit->{defect}}, @{$opts{defects}}));

        my %update = (
            index => $index,
            id    => $hit->{_id},
            type  => 'result',
            body  => {
                doc => {
                    defect => \@df_merged,
                },
            }
        );
        $update{body}{doc}{status} = $opts{status} if $opts{status};

        my $res = $e->update(%update);

        print "Associated cases to document $hit->{_id}\n"
          if $res->{result} eq 'updated';
        if (!grep { $res->{result} eq $_ } qw{updated noop}) {
            print
              "Something went wrong associating cases to document $hit->{_id}!\n$res->{result}\n";
            $failures++;
        }
    }

    print "No cases matching your query could be found.  No action was taken.\n"
      unless $attempts;

    return $failures;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Indexer - Define what data is to be uploaded to elasticsearch, and handle it's uploading

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 9600 });

=head1 VARIABLES

=head2 index (STRING)

The name of the elasticsearch index used.
If you are subclassing this, be aware that the Searcher plugin will rely on this.

=head2 max_query_size

Number of items returned by queries.
Defaults to 1000.

=head1 SUBROUTINES

=head2 check_index

Returns 1 if the index needed to be created, 0 if it's already OK.
Dies if the server cannot be reached, or the index creation fails.

=head2 index_results

Index a test result (see L<App::Prove::Elasticsearch::Parser> for the input).

=head2 bulk_index_results(@results)

Helper method for migration scripts.
Uploads an array of results in bulk such as would be fed to index_results.

It is up to the caller to chunk inputs as is appropriate for your installation.

=head2 associate_case_with_result(%config)

Associate an indexed result with a tracked defect.

Requires configuration to be inside of ENV vars already.

Arguments Hash:

=over 4

=item B<case STRING>     - case to associate defect to

=item B<defects ARRAY>   - defects to associate with case

=item B<platforms ARRAY> - filter out any results not having these platforms

=item B<versions ARRAY>  - filter out any results not having these versions

=back

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

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
