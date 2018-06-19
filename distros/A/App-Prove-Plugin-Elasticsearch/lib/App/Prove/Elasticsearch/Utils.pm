# PODNAME: App::Prove::Elasticsearch::Utils
# ABSTRACT: common functions used by multiple modules in the distribution.

package App::Prove::Elasticsearch::Utils;
$App::Prove::Elasticsearch::Utils::VERSION = '0.001';
use strict;
use warnings;

use Config::Simple();
use File::HomeDir();

sub process_configuration {
    my $args = shift;
    my $conf = {};

    my $homedir = File::HomeDir::my_home() || '.';
    if (-e $homedir) {
        unless (Config::Simple->import_from("$homedir/elastest.conf", $conf)) {
            warn Config::Simple->error() if -e "$homedir/elastest.conf";
        }
    }

    my @kvp = ();
    my ($key, $value);
    foreach my $arg (@$args) {
        @kvp = split(/=/, $arg);
        if (scalar(@kvp) < 2) {
            print
              "Unrecognized Argument '$arg' to App::Prove::Plugin::Elasticsearch, ignoring\n";
            next;
        }
        $key          = shift @kvp;
        $value        = join('', @kvp);
        $conf->{$key} = $value;
    }

    #Set ENV for use by harness
    foreach my $key (keys(%$conf)) {
        my $km = uc($key);
        $km =~ s/\./_/g;
        $ENV{$km} = $conf->{$key};
    }

    return $conf;
}

sub require_indexer {
    my $conf = shift;
    my $index_suffix =
      $conf->{'client.indexer'} ? "::" . $conf->{'client.indexer'} : '';
    my $indexer = "App::Prove::Elasticsearch::Indexer$index_suffix";

    eval "require $indexer";
    die $@ if $@;

    #Set ENV for use by harness
    $ENV{CLIENT_INDEXER} = $indexer;
    return $indexer;
}

sub require_searcher {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Searcher',
        'client.autodiscover',
        'CLIENT_AUTODISCOVER'
    );
}

sub require_blamer {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Blamer',
        'client.blamer',
        'CLIENT_BLAMER'
    );
}

sub require_planner {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Planner',
        'client.planner',
        'CLIENT_PLANNER'
    );
}

sub require_platformer {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Platformer',
        'client.platformer',
        'CLIENT_PLATFORMER'
    );
}

sub require_queue {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Queue',
        'client.queue',
        'CLIENT_QUEUE'
    );
}

sub require_versioner {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Versioner',
        'client.versioner',
        'CLIENT_VERSIONER'
    );
}

sub require_runner {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Runner',
        'client.runner',
        'CLIENT_RUNNER'
    );
}

sub require_provisioner {
    my $module = shift;
    $module //= 'Default';
    my $module_full = "App::Prove::Elasticsearch::Provisioner::$module";
    eval "require $module_full";
    die $@ if $@;

    #Set ENV for use by harness
    if ($ENV{CLIENT_PROVISIONERS}) {
        $ENV{CLIENT_PROVISIONERS} .= ":$module_full";
    } else {
        $ENV{CLIENT_PROVISIONERS} = "$module_full";
    }
    return $module_full;
}

sub _require_generic {
    my ($conf, $prefix, $suffix_key, $envvar) = @_;
    my $suffix = $conf->{$suffix_key} // 'Default';
    my $module = "${prefix}::$suffix";

    eval "require $module";
    die $@ if $@;

    #Set ENV for use by harness
    $ENV{$envvar} = $suffix;
    return $module;
}

sub get_last_index {
    my ($e, $index) = @_;

    my $res = $e->search(
        index => $index,
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

sub do_paginated_query {
    my ($e, $max_query_size, %q) = @_;
    my $offset     = 0;
    my $hits       = [];
    my $hitcounter = $max_query_size;
    while ($hitcounter == $max_query_size) {
        $q{size} = $max_query_size;
        $q{from} = ($max_query_size * $offset);
        my $res = $e->search(%q);
        push(@$hits, @{$res->{hits}->{hits}});
        $hitcounter = scalar(@{$res->{hits}->{hits}});
        $offset++;
    }
    return $hits;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Utils - common functions used by multiple modules in the distribution.

=head1 VERSION

version 0.001

=head1 FUNCTIONS

=head2 process_configuration

Read the configuration & any CLI args (key=value,key=value...), and set their values in ENV.

=head2 require_indexer($conf)

Require the needed indexer implied by the configuration passed.
Set the ENV var CLIENT_INDEXER for use by parser, etc.

=head2 require_searcher($conf)

Require the needed searcher implied by the configuration passed.
Set the ENV var CLIENT_AUTODISCOVER for use by parser, etc.

Will die unless you have autodiscover= set in your configuration, as there is no default searcher.

=head2 require_blamer($conf)

Require the needed searcher implied by the configuration passed.
Set the ENV var CLIENT_BLAMER for use by parser, etc.

=head2 require_planner($conf)

Require the needed planner implied by the configuration passed.
Set the ENV var CLIENT_PLANNER for use by parser, etc.

=head2 require_platformer($conf)

Require the needed platformer implied by the configuration passed.
Set the ENV var CLIENT_PLATFORMER for use by parser, etc.

=head2 require_queue($conf)

Require the needed queue module implied by the configuration passed
Sets the ENV var CLIENT_QUEUE for use by testd & testplan, etc

=head2 require_versioner($conf)

Require the needed versioner module implied by the configuration passed
Sets the ENV var CLIENT_VERSIONER for use by parser, etc

=head2 require_runner($conf)

Require the needed runner module implied by the configuration passed
Sets the ENV var CLIENT_RUNNER for use by testd, etc

=head2 require_provisioner($module)

Require the needed runner module provided.
Sets the ENV var CLIENT_PROVISIONERS for use by testd, etc

=head2 ES convenience methods

These are used directly in some indexer & planner subs.
Thankfully, those are required dynamically, so reliance on these shouldn't break plugin compatibility.

=head2 get_last_index

Ask ES for the last index it has on hand, so we can then add some new records.

Arguments are ES handle and index name.

=head2 do_paginated_query

Do an elasticsearch paginated query.

Arguments are ES handle, max query results and the query to paginate (HASH).

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
