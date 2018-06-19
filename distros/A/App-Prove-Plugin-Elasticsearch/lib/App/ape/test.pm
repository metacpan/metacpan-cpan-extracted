package App::ape::test;
$App::ape::test::VERSION = '0.001';

# ABSTRACT: Run a test manually and upload the results to Elasticsearch
# PODNAME: App::Ape::test

use strict;
use warnings;

use Getopt::Long qw{GetOptionsFromArray};
use App::Prove::Elasticsearch::Utils;
use Pod::Usage;
use File::Temp;
use POSIX qw{strftime};
use File::Basename qw{basename dirname};

sub new {
    my ($class, @args) = @_;

    my (%options, @conf, $help);
    GetOptionsFromArray(
        \@args,
        'defect=s@'    => \$options{defects},
        'configure=s@' => \@conf,
        'status=s'     => \$options{status},
        'elapsed=s'    => \$options{elapsed},
        'body=s'       => \$options{body},
        'help'         => \$help
    );

    #Deliberately exiting here, as I "unit" test this as the binary
    pod2usage(0) if $help;

    if (!$options{status}) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg     => "Insufficient arguments.  You must pass a status.",
        );
        return 1;
    }

    if (!scalar(@args)) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg => "Insufficient arguments.  You must pass at least one test.",
        );
        return 2;
    }

    my $conf = App::Prove::Elasticsearch::Utils::process_configuration(@conf);

    if (
        scalar(
            grep {
                my $subj = $_;
                grep { $subj eq $_ } qw{server.host server.port}
            } keys(%$conf)
        ) != 2
      ) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg =>
              "Insufficient information provided to associate defect with test results to elasticsearch",
        );
        return 3;
    }

    $0 = "ape test: starting up";

    my $self = {options => \%options};

    $self->{indexer} = App::Prove::Elasticsearch::Utils::require_indexer($conf);
    &{\&{$self->{indexer} . "::check_index"}}($conf);

    my $searcher = App::Prove::Elasticsearch::Utils::require_searcher($conf);
    $self->{searcher} = $searcher->new($conf, $self->{indexer});

    $self->{versioner} =
      App::Prove::Elasticsearch::Utils::require_versioner($conf);
    $self->{version} = &{\&{$self->{versioner} . "::get_version"}}();
    my @cases = map {
        {
            name    => $_,
            version => &{\&{$self->{versioner} . "::get_file_version"}}($_)
        }
    } @args;
    $self->{cases} = \@cases;

    $self->{blamer} = App::Prove::Elasticsearch::Utils::require_blamer($conf);

    $self->{platformer} =
      App::Prove::Elasticsearch::Utils::require_platformer($conf);
    $self->{platforms} = &{\&{$self->{platformer} . "::get_platforms"}}();

    return bless($self, $class);
}

sub run {
    my ($self) = @_;

    foreach my $case (@{$self->{cases}}) {
        $0 = "ape test : $case->{name}";

        if (!-f $case->{name}) {
            print "No such case $case->{name} on filesystem, skipping.\n";
            next;
        }
        my $executor =
          &{\&{$self->{blamer} . "::get_responsible_party"}}($case->{name});

        my $occurred = time();
        my $output   = $self->get_test_commentary();
        my $elapsed  = time() - $occurred;

        my $upload = {
            body         => $output,
            elapsed      => $elapsed,
            occurred     => strftime("%Y-%m-%d %H:%M:%S", localtime($occurred)),
            status       => $self->{options}{status},
            platform     => $self->{platforms},
            executor     => $executor,
            version      => $self->{version},
            test_version => $case->{version},
            name         => basename($case->{name}),
            path         => dirname($case->{name}),
        };

        eval { &{\&{$self->{indexer} . "::index_results"}}($upload) };
        print "$@\n" if $@;
    }
    $0 = "ape test: shutting down";
    return 0;
}

sub get_test_commentary {
    my $self = shift;

    my ($fh, $filename);
    if ($self->{options}->{body}) {
        $filename = $self->{options}->{body};
    } else {
        my $editor = $ENV{EDITOR} || $ENV{VISUAL};
        die
          "Either pass --body or have EDITOR or VISUAL set to edit your test result body."
          unless $editor;

        (undef, $filename) = File::Temp::tempfile();
        my $pid = fork();
        if (!$pid) {
            exec($editor, $filename);
        }
        waitpid($pid, 0);
    }

    die "No such file $filename!" unless -f $filename;
    my $out;
    open($fh, '<', $filename);
    while (<$fh>) { $out .= $_ }
    close $fh;
    die "Empty test update inside of $filename!" unless $out;

    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Ape::test - Run a test manually and upload the results to Elasticsearch

=head1 VERSION

version 0.001

=head1 USAGE

Adding new results:

    ape test -s OK [ -e 55 -d defect1 ] test1 ... testN

When adding results, your $EDITOR will be opened unless -b is passed.

=head2 OPTIONS

=over 4

=item B<-s [STATUS]> : This will be set for all the relevant test results indexed.  Mandatory.

=item B<-d [DEFECT]> : this will be associated with all the relevant test results indexed.  May be passed multiple times.

=item B<-c [CONFIGURATION]> : override configuration value, e.g. server.host=some.es.host.  Can be passed multiple times.

=item B<-e [SECONDS]> : Override the 'elapsed' field.  Normally the amount of time used to edit your test comment in $EDITOR is used.

=item B<-b [FILE]> : Provide the body of the test result in the passed file.

=back

=head1 CONSTRUCTOR

=head2 new(@ARGV)

Process arguments and include all relevant plugins to add a test result.

=head1 METHODS

=head2 run()

Executes the upload of results to Elasticsearch.

=head2 get_test_commentary

If the user has passed a --body, we will read it.
Otherwise, open up an EDITOR/VISUAL session to allow them to write to a temp file their test body.

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
