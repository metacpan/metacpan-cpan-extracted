# ABSTRACT: Index, create and retrieve test plans for use later
# PODNAME: App::Prove::Elasticsearch::Planner::Default

package App::Prove::Elasticsearch::Planner::Default;
$App::Prove::Elasticsearch::Planner::Default::VERSION = '0.001';
use strict;
use warnings;

use App::Prove::Elasticsearch::Utils();

use Search::Elasticsearch();
use File::Basename();
use Cwd();
use List::Util 1.45 qw{uniq};

our $index = 'testplans';
our $e;    # for caching
our $last_id;

our $max_query_size = 1000;

sub check_index {
    my ($conf) = @_;

    my $port = $conf->{'server.port'} ? ':' . $conf->{'server.port'} : '';
    die "server must be specified" unless $conf->{'server.host'};
    die("port must be specified")  unless $port;
    my $serveraddress = "$conf->{'server.host'}$port";

    $e //= Search::Elasticsearch->new(
        nodes           => $serveraddress,
        request_timeout => 30
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
                    testplan => {
                        properties => {
                            id      => {type => "integer"},
                            created => {
                                type   => "date",
                                format => "yyyy-MM-dd HH:mm:ss"
                            },
                            creator => {
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
                            platforms => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            tests => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
                            },
                            pairwise => {type => "boolean"},
                            name     => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {keyword => {type => "keyword"}}
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

sub find_test_paths {
    my (@tests) = @_;
    return map { "t/$_" } @tests;
}

sub get_plan {
    my (%options) = @_;

    die "A version must be passed." unless $options{version};

    my %q = (
        index => $index,
        body  => {
            query => {
                bool => {
                    must => [
                        {
                            match => {
                                version => $options{version},
                            }
                        },
                    ],
                },
            },
            size => 1,
        },
    );

    push(@{$q{body}{query}{bool}{must}}, {match => {name => $options{name}}})
      if $options{name};

    foreach my $plat (@{$options{platforms}}) {
        push(@{$q{body}{query}{bool}{must}}, {match => {platforms => $plat}});
    }

    my $docs = $e->search(%q);

    return 0
      unless ref $docs eq 'HASH'
      && ref $docs->{hits} eq 'HASH'
      && ref $docs->{hits}->{hits} eq 'ARRAY';
    return 0 unless scalar(@{$docs->{hits}->{hits}});
    my $match = $docs->{hits}->{hits}->[0]->{_source};

    my @plats_match = (
        (ref($match->{platforms}) eq 'ARRAY')
        ? @{$match->{platforms}}
        : ($match->{platforms})
    );

    my $name_correct =
      !$options{name} || ($match->{name} // '') eq ($options{name} // '');
    my $version_correct = $match->{version} eq $options{version};
    my $plats_size_ok = scalar(@plats_match) == scalar(@{$options{platforms}});
    my $plats_are_same =
      scalar(@plats_match) ==
      scalar(uniq((@plats_match, @{$options{platforms}})));
    my $plats_correct =
      !scalar(@{$options{platforms}}) || ($plats_size_ok && $plats_are_same);

    $match->{id} = $docs->{hits}->{hits}->[0]->{_id};
    return $match if ($name_correct && $version_correct && $plats_correct);

    return 0;
}

sub get_plans {
    my (%options) = @_;

    die "A version must be passed." unless $options{version};

    my %q = (
        index => $index,
        body  => {
            query => {
                query_string => {
                    query => qq{version: "$options{version}"},
                },
            },
        },
    );

    $q{body}{query}{query_string}{query} .= qq{ AND name: "$options{name}" }
      if $options{name};

    foreach my $plat (@{$options{platforms}}) {
        $q{body}{query}{query_string}{query} .= qq{ AND platforms: "$plat" };
    }
    return App::Prove::Elasticsearch::Utils::do_paginated_query(
        $e,
        $max_query_size, %q
    );
}

sub get_plans_needing_work {
    my (%options) = @_;

    die "Can't find plans needing work without case autodiscover configured!"
      unless $options{searcher};

    my @plans;
    my $docs = get_plans(%options);
    return () unless ref $docs eq 'ARRAY' && scalar(@$docs);

    foreach my $doc (@$docs) {
        next
          unless ref $doc->{_source}->{tests} eq 'ARRAY'
          && scalar(@{$doc->{_source}->{tests}});
        my @tests = $options{searcher}
          ->filter(find_test_paths(@{$doc->{_source}->{tests}}));
        $doc->{_source}->{tests} = \@tests;
        push(@plans, $doc->{_source}) if @tests;
    }
    return \@plans;
}

sub get_plan_status {
    my ($plan, $searcher) = @_;

    die "Can't discover plan status without case autodiscover configured!"
      unless $searcher;
    return $searcher->get_test_replay(
        $plan->{version}, $plan->{platforms},
        @{$plan->{tests}}
    );
}

sub add_plan_to_index {
    my ($plan) = @_;

    if ($plan->{noop}) {
        print "Nothing to do!\n";
        return 0;
    }
    return _update_plan($plan) if $plan->{update};

    die "check_index not run, ES object not defined!" unless $e;

    my $idx = App::Prove::Elasticsearch::Utils::get_last_index($e, $index);
    $idx++;

    $e->index(
        index => $index,
        id    => $idx,
        type  => 'testplan',
        body  => $plan,
    );

    my $doc_exists =
      $e->exists(index => $index, type => 'testplan', id => $idx);
    my $pn = $plan->{'name'} // '';
    if (!defined($doc_exists) || !int($doc_exists)) {
        print "Failed to Index $pn, could find no record with ID $idx\n";
        return 1;
    }

    print "Successfully Indexed plan $pn with result ID $idx\n";
    return 0;

}

sub _update_plan {
    my ($plan) = @_;

    #handle adding new tests, then subtract
    my @tests_merged =
      (@{$plan->{tests}}, @{$plan->{update}->{addition}->{tests}});
    @tests_merged = grep {
        my $subj = $_;
        !grep { $_ eq $subj } @{$plan->{update}->{subtraction}->{tests}}
    } @tests_merged;

    my $res = $e->update(
        index => $index,
        id    => $plan->{id},
        type  => 'testplan',
        body  => {
            doc => {
                tests => \@tests_merged,
            },
        }
    );

    print "Updated tests in plan #$plan->{id}\n" if $res->{result} eq 'updated';
    if (!grep { $res->{result} eq $_ } qw{updated noop}) {
        print
          "Something went wrong associating cases to document $plan->{id}!\n$res->{result}\n";
        return 1;
    }
    print "Successfully Updated plan #$plan->{id}\n";
    return 0;
}

sub make_plan {
    my (%options) = @_;
    die "check_index not run, ES object not defined!" unless $e;

    my %out = %options;
    $out{pairwise} = $out{pairwise} ? "true" : "false";
    delete $out{show};
    delete $out{prompt};
    delete $out{allplatforms};
    delete $out{exts};
    delete $out{recurse};
    delete $out{name} unless $out{name};

    $out{noop} = 1 unless scalar(@{$out{tests}});

    return \%out;
}

sub make_plan_update {
    my ($existing, %out) = @_;
    die "check_index not run, ES object not defined!" unless $e;

    #TODO be sure to do the right thing w pairwise testing (dole out tests appropriately)

    my $adds = {};
    my $subs = {};
    foreach my $okey (@{$out{tests}}) {
        push(@{$adds->{tests}}, $okey)
          if !grep { $_ eq $okey } @{$existing->{tests}};
    }
    foreach my $ekey (@{$existing->{tests}}) {
        push(@{$subs->{tests}}, $ekey) if !grep { $_ eq $ekey } @{$out{tests}};
    }

    if (!scalar(keys(%$adds)) && !scalar(keys(%$subs))) {
        $existing->{noop} = 1;
        return $existing;
    }
    $existing->{update} = {addition => $adds, subtraction => $subs};

    return $existing;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Planner::Default - Index, create and retrieve test plans for use later

=head1 VERSION

version 0.001

=head1 SUBCLASSING

The most useful reason to subclass the planner is to tell the system where to find named tests stored in a plan.
For a variety of good reasons, we do not store paths to tests in plans.
You are expected to alter find_test_paths() to suit your needs if the default behavior (search t/) is insufficient.

=head1 VARIABLES

=head2 index (STRING)

The name of the elasticsearch index used.
If you are subclassing this, be aware that the Searcher plugin will rely on this.

=head2 max_query_size

Number of items returned by queries.
Defaults to 1000.

=head1 CONSTRUCTOR

=head2 check_index($conf)

Constructs a new Search::Elasticsearch object using the provided configuration file data, and stores it for use by other functions.
It then checks the index, and returns false or the object depending on the index status.

Creates the index if it does not exist.

=head1 METHODS

All methods below die if the ES handle hasn't been defined by check_index.

=head2 find_test_paths(@tests)

Resolves the paths to your tests.  By default this is the t/ directory under your current directory.
See SUBCLASSING for more information.

Returns ARRAY

=head2 get_plan

Get the plan most closely matching the description from Elasticsearch.

=head2 get_plans(%options)

Get all the plans matching the version/platforms passed.

Input hash specification:

=over 4

=item B<version> - Required. Version of the software to be tested.

=item B<name> - Optional.  Name of the test plan used (if any).

=item B<platforms> - Optional.  ARRAYREF of platform names to be tested upon.  Must match all provided platforms.

=back

=head2 get_plans_needing_work(%options)

Ask which of the plans in ES fits the provided specification.

Input hash specification:

=over 4

=item B<searcher> - Required. App::Prove::Elasticsearch::Searcher::* object.

=item All other items should be the same as in get_plans.

=back

=head2 get_plan_status(plan)

Gets the status of the tests to be run in the provided plan, regardless of if the plan even exists.

=head2 add_plan_to_index($plan)

Add or update a test plan.
Dies if the plan cannot be added/updated.
Returns 1 in the event of failure.

=head2 make_plan(%plan)

Build a test plan ready to be indexed, and return it.

Takes a hash describing the plan to be created and then mangles it to fit in openstack.

=head2 make_plan_update($existing_plan,%plan)

Build an update statement to modify an indexed plan.  The existing plan and a hash describing the modifications to the plan are required.

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
