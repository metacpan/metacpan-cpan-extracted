# PODNAME:  App::Prove::Plugin::Elasticsearch
# ABSTRACT: Prove Plugin to upload test results to elastic search as they are executed

package App::Prove::Plugin::Elasticsearch;
$App::Prove::Plugin::Elasticsearch::VERSION = '0.001';
use strict;
use warnings;

use App::Prove::Elasticsearch::Utils();

sub load {
    my ($class, $prove) = @_;

    my $app  = $prove->{app_prove};
    my $args = $prove->{args};

    my $conf = App::Prove::Elasticsearch::Utils::process_configuration($args);

    if (
        scalar(
            grep {
                my $subj = $_;
                grep { $subj eq $_ } qw{server.host server.port}
            } keys(%$conf)
        ) != 2
      ) {
        print
          "# Insufficient information provided to upload test results to elasticsearch.  Skipping...\n";
        return $class;
    }

    $app->harness('App::Prove::Elasticsearch::Harness');
    $app->merge(1);

    my $indexer = App::Prove::Elasticsearch::Utils::require_indexer($conf);
    &{\&{$indexer . "::check_index"}}($conf);

    return $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::Elasticsearch - Prove Plugin to upload test results to elastic search as they are executed

=head1 VERSION

version 0.001

=head1 SYNOPSIS

`prove -PElasticsearch='server.host=zippy.test,server.port=666,client.blamer=FingerPointer,client.indexer=EvilIndexer,client.versioner=Git,client.autodiscover=ByName`

=head1 DESCRIPTION

This testing plugin itself is highly pluggable to allow for a variety of indexing and searching conditions.

=head2 INDEXER

The default indexer is L<App::Prove::Elasticsearch::Indexer>

Creates an index (if it does not exist)  called 'testsuite' in your specified Elasticsearch instance, which has the following parameters:

=over 4

=item B<body>: the raw text produced by prove -mv from your test.

=item B<elapsed>: the time it took the test to execute

=item B<occurred>: when the test began execution

=item B<executor>: the name of the executor.  This can be passed as executor=.  Defaults to root @ the host executed on.

=item B<version>: the version of the system under test.  See the versioner option as to how this is obtained.

=item B<environment>: the environment of the system under test.  See the platformer option as to how this is obtained.

=item B<name>: the filename of the test run

=item B<path>: the path to the test.  This is to allow tests with the same name at different paths to report correctly.

=item B<status>: whether the test global result was PASS, FAIL, SKIP, etc.  See L<App::Prove::Elasticsearch::Parser> for the rules as to these statuses.

=item B<steps>: detailed information (es object) as to the name, elapsed time, status and step # for each step.

=back

If this index does not exist, it will be created for you.
If an index exists with that name an exception will be thrown.
To override the index name to avoid exceptions, subclass App::Prove::Elasticsearch::Indexer and use your own name.
The name searched for must be a child of the App::Prove::Elasticsearch::Indexer, e.g. App::Prove::Elasticsearch::Indexer::EvilIndexer.

You may have noticed that this pluggable design does not necessarily mean you need to use elasticsearch as your indexer;
so long as the information above is all you need for your test management system, there's no reason you couldn't make a custom indexer for it.

There are also some shipped indexer extensions:

=over 4

=item B<DzilDist>: Names the index based on what your distribution is named in dist.ini

=item B<MMDist>: Names the index based on what your distribution is named in Makefile.PL

=back

=head2 VERSIONER

The version getter is necessarily complicated, as all perl modules do not necessarily provide a reliable method of acquiring this.
As such this behavior can be modified with the versioner= parameter.
This module ships with various versioners:

=over 4

=item B<Default>: used if no versioner is passed, the latest version in Changes is used.  Basically the CPAN module workflow.

=item B<Git>: use the latest SHA for the file.

=item B<Env>: use $ENV{TESTSUITE_VERSION} as the value used.  Handy when testing remote systems.

=back

App::Prove::Elasticsearch::Provisioner is built to be subclassed to discern the version used by your application.
For example, App::Prove::Elasticsearch::Provisioner::Default provides the 'Default' versioner.

=head2 PLATFORMER

Given that tests run on various platforms, we need a flexible way to determine that information.
As such, I've provided (you guessed it) yet another pluggable interface, App::Prove::Elasticsearch::Platformer.
Here are the shipped plugins:

=over 4

=item B<Default>: use Sys::Info::OS to determine the operating system environment, and $^V for the interpreter environment.

=item B<Env>: use $ENV{TESTSUITE_PLATFORM} as the environment.  Accepts comma separated variables.

=back

Unlike the other pluggable interfaces, this is intended to return an array of platforms describing the system under test.

=head2 BLAMER

All test results should be directly attributable to some entity.
As such, you can subclass App::Prove::Elasticsearch::Blamer to blame whatever is convenient for test results.
This module ships with:

=over 4

=item B<Default>: The latest author listed in Changes.

=item B<System>: user executing @ hostname

=item B<Git>: git config's author.email.

=item B<Env>: whatever is set in $ENV{TESTSUITE_EXECUTOR}.

=back

=head2 INDEXER

=head2 AUTODISCOVER

Passing the client.autodiscover option makes the Test Harness eject tests which have results indexed for the relevant configuration.
The value is the class in the App::Prove::Elasticsearch::Searcher::* namespace you wish to use to autodiscover results.
This module ships with:

=over 4

=item B<ByName>: Checks for results with the same name and path as the provided tests.

=back

By default, this option is NOT set, and tests will simply be re-run and indexed.

=head2 QUEUE

By default, when running test plans via -PElasticsearch='plan=SomePlan,...', we run everything in the plan possible based on the local host's configuration.
In some situations though, you might have more work than your local host can satisfy, and need to distribute your testing load.

To facilitate that, App::Prove::Elasticsearch::Queue::* modules have been provided to assist you in going about that:

=over 4

=item B<Default>: Runs everything in the plan possible based on localhost's configuration, as defined by your platformer/versioner.

=item B<Rabbit>:  Use RabbitMQ to run a portion of the queue relevant to the host's configuration, as defined by your platformer/versioner.

A tool (bin/testd) has also been provided to leverage these queues by watching and waiting for work.

=back

=head2 CONFIGURATION

All parameters passed to the plugin may be set in ~/elastest.conf, which read by Config::Simple.
Set the host and port values in the [Server] section.
Set the autodiscover, blamer, indexer and versioner values in the [Client] section.
If your Indexer & Versioner subclasses require additional configuration you may put them in arbitrary sections, as the entire configuration is passed to both parent classes.

If no configuration is passed either by file or argument, the plugin chooses to do nothing, and notifies you of this fact.

=head1 CONSTRUCTOR

=head2 load

Like App::Prove::Plugin's example load() method, but that loads our configuration file, parses args and injects everything into $ENV to be read by the harness.
Also initializes the Elasticsearch index.

=head2 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 CONTRIBUTOR

=for stopwords George S. Baugh

George S. Baugh <george@troglodyne.net>

=head1 SOURCE

The development version is on github at L<http://https://github.com/teodesian/App-Prove-Elasticsearch>
and may be cloned from L<git://https://github.com/teodesian/App-Prove-Elasticsearch.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
