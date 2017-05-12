package Dancer2::Plugin::ElasticSearch;
$Dancer2::Plugin::ElasticSearch::VERSION = '0.003';
# ABSTRACT: Dancer2 plugin for obtaining Search::Elasticsearch handles

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use Search::Elasticsearch;
use Try::Tiny;
use Dancer2::Plugin;

our $handles = {};

register 'elastic' => sub {
    my ($dsl, $name) = @_;
    $name //= 'default';

    # the classic fork/thread-safety mantra
    my $pid_tid = $$ . ($INC{'threads.pm'} ? '_' . threads->tid : '');

    my $elastic;
    if ($elastic = $handles->{$pid_tid}{$name}) {
        # got one from the cache.  done
    } else {
        # no handle in the cache, create one and stash it
        my $plugin_config = plugin_setting();
        unless (exists $plugin_config->{$name}) {
            die "No config for ElasticSearch client '$name'";
        }
        my $config = $plugin_config->{$name};
        my $params = $config->{params} // {};
        try {
            $elastic = Search::Elasticsearch->new(%{$params});
            # S::E does not actually connect until it needs to, but
            # we're already not creating the S::E object until we need
            # one!
            $elastic->ping;
        } catch {
            my $error = $_;
            die "Could not connect to ElasticSearch: $error";
        };
        $handles->{$pid_tid}{$name} = $elastic;
    }

    return $elastic;
};

register_plugin;

1;


=pod

=head1 NAME

Dancer2::Plugin::ElasticSearch - Dancer2 plugin for obtaining Search::Elasticsearch handles

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Dancer2::Plugin::ElasticSearch;
  get '/count_all_docs' => sub {
    return elastic->search(search_type => 'count',
                           body => { query => { match_all => {} } });
  }

=head1 DESCRIPTION

This Dancer2 plugin handles connection configuration and
fork-and-thread safety for ElasticSearch connectors.

=head1 KEYWORDS

=head2 elastic

  elastic->ping;
  elastic('other')->ping;

Return a L<Search::Elasticsearch::Client> subclass suitable for
running queries against an ElasticSearch instance.  Each thread is
guaranteed to have its own client instances.  If a connection already
exists for a given configuration name, it is returned instead of being
re-created.

If a configuration name is not passed, "default" is assumed.

=head1 CONFIGURATION

  plugins:
    ElasticSearch:
      default:
        params:
          nodes: localhost:9200
      other:
        params: etc

The C<params> hashref must contain a map of parameters that can be
passed directly to the L<Search::Elasticsearch> constructor.  In the
above example, calling C<elastic> (or C<elastic('default')>) will
result in

  Search::Elasticsearch->new(nodes => 'localhost:9200');

=head1 INSTALLATION

You can install this module as you would any Perl module.

During installation, the unit tests will run queries against a local
ElasticSearch instance if there is one (read-only queries, of
course!).  If you have no local ElasticSearch instance, but still wish
to run the unit tests, set the C<D2_PLUGIN_ES> variable to
"$host:$port".  If no instance can be reached, the tests will be
safely skipped.

=head1 SEE ALSO

L<Search::Elasticsearch>, L<Dancer2>

=head1 AUTHOR

Fabrice Gabolde <fgabolde@weborama.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
