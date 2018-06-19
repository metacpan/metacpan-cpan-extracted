# ABSTRACT: Associate Test results with a tracked defect
# PODNAME: App::ape::update

package App::ape::update;
$App::ape::update::VERSION = '0.001';
use strict;
use warnings;

use Getopt::Long qw{GetOptionsFromArray};
use App::Prove::Elasticsearch::Utils;
use Pod::Usage;

sub new {
    my ($class, @args) = @_;

    my (%options, @conf, $help);
    GetOptionsFromArray(
        \@args,
        'defect=s@'    => \$options{defects},
        'platform=s@'  => \$options{platforms},
        'version=s@'   => \$options{versions},
        'configure=s@' => \@conf,
        'status=s'     => \$options{status},
        'help'         => \$help
    );

    $options{defects} //= [];

    #Deliberately exiting here, as I "unit" test this as the binary
    pod2usage(0) if $help;

    if (!scalar(@args)) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg => "Insufficient arguments.  You must pass at least one test.",
        );
        return 1;
    }

    if (!scalar(@{$options{defects}})) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg =>
              "Insufficient arguments.  You must pass at least one defect.",
        );
        return 4;
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

    my $self = {options => \%options, cases => \@args};

    $self->{indexer} = App::Prove::Elasticsearch::Utils::require_indexer($conf);
    &{\&{$self->{indexer} . "::check_index"}}($conf);

    return bless($self, $class);
}

sub run {
    my $self          = shift;
    my $global_result = 0;
    foreach my $case (@{$self->{cases}}) {
        $self->{options}{case} = $case;
        $global_result +=
          &{\&{$self->{indexer} . "::associate_case_with_result"}}
          (%{$self->{options}});
    }
    print "$global_result tests failed to be associated, examine above output\n"
      if $global_result;
    return $global_result ? 2 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ape::update - Associate Test results with a tracked defect

=head1 VERSION

version 0.001

=head1 USAGE

ape update [-p ONLY_PLATFORM -v ONLY_VERSION -s STATUS ] -d Defect1 -d Defect2 test1 ... testN

=head2 MANDATORY INPUT

=over 4

=item B<-d [DEFECT]> : at least one must be passed; this will be associated with all the relevant test results indexed.  May be passed multiple times.

=back

=head2 OPTIONS

=over 4

=item B<-p [PLATFORM]> : filter cases to associate by the provided platform(s).

=item B<-v [VERSION]> : filter cases to associate by the provided version(s).

=item B<-c [CONFIGURATION]> : override configuration value, e.g. server.host=some.es.host.  Can be passed multiple times.

=item B<-s [STATUS]> : override the current status of the relevant test results.

=back

After applying the options, the defect will be applied to all the tests you have provided as arguments.

If a result is updated or fails to update, you will be notified the IDs of the documents which failed/succeeded to update, and a reason.

=head1 CONSTRUCTOR

=head2 new(@ARGV)

Process arguments and require the relevant plugins required to update a result in elasticsearch.

=head1 METHODS

=head2 run()

Upload the case result modification to Elasticsearch per the passed arguments.

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
