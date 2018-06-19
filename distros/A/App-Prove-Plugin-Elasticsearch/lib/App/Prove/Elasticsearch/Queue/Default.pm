package App::Prove::Elasticsearch::Queue::Default;
$App::Prove::Elasticsearch::Queue::Default::VERSION = '0.001';

# PODNAME: App::Prove::Elasticsearch::Queue::Default;
# ABSTRACT: Coordinate the running of test plans across multiple forks.

use strict;
use warnings;

use List::Util 1.45 qw{shuffle uniq};
use App::Prove::Elasticsearch::Utils;

sub new {
    my ($class, $input) = @_;
    my $conf = App::Prove::Elasticsearch::Utils::process_configuration($input);

    my $planner = App::Prove::Elasticsearch::Utils::require_planner($conf);
    &{\&{$planner . "::check_index"}}($conf);

    return bless({config => $conf, planner => $planner}, $class);
}

sub get_jobs {
    my ($self, $jobspec) = @_;

    $self->_get_searcher();

    $jobspec->{searcher} = $self->{searcher};
    my $plans = &{\&{$self->{planner} . "::get_plans_needing_work"}}(%$jobspec);
    return () unless scalar(@$plans);

    my @tests;
    foreach my $plan (@$plans) {
        my @tmp_tests =
          ref $plan->{tests} eq 'ARRAY' ? @{$plan->{tests}} : ($plan->{tests});
        push(@tests, @tmp_tests);
    }
    @tests = shuffle($self->{searcher}->filter(uniq @tests));
    return @tests unless $self->{config}->{'queue.granularity'};
    @tests = splice(@tests, 0, $self->{config}->{'queue.granularity'});
    return @tests;
}

sub _get_indexer {
    my $self = shift;
    $self->{indexer} //=
      App::Prove::Elasticsearch::Utils::require_indexer($self->{config});
    return $self->{indexer};
}

sub _get_searcher {
    my $self = shift;
    return $self->{searcher} if $self->{searcher};
    my $searcher =
      App::Prove::Elasticsearch::Utils::require_searcher($self->{config});

    $self->{searcher} = &{\&{$searcher . "::new"}}
      ($searcher, $self->{config}, $self->_get_indexer());
    return $self->{searcher};
}

sub list_queues {
    my ($self, %matrix) = @_;
    my $pf = [];
    @$pf = grep { defined $_ } values(%{$matrix{cur_platforms}});
    push(@$pf, @{$matrix{unsatisfiable_platforms}});
    my %jobspec = (
        version   => $matrix{cur_version},
        platforms => $pf,
        searcher  => $self->_get_searcher(),
    );
    my $plans = &{\&{$self->{planner} . "::get_plans_needing_work"}}(%jobspec);
    return @$plans if @$plans;

    #construct iterator
    my @pigeonholes =
      map  { $matrix{platforms}{$_} }
      grep { scalar(@{$matrix{platforms}{$_}}) } keys(%{$matrix{platforms}});

    my @plots;
    my @iterator = @{$pigeonholes[0]};
    while (scalar(@iterator)) {
        my $subj = shift @iterator;

        #Handle initial elements
        $subj = [$subj] if ref $subj ne 'ARRAY';

        #Break out of the loop if we have no more possibilities to exploit
        if (scalar(@$subj) == scalar(@pigeonholes)) {
            push(@plots, $subj);
            next;
        }

        #Keep pushing partials on to the end of the iterator, until we run out of categories to add
        foreach my $element (@{$pigeonholes[ scalar(@$subj) ]}) {
            my @partial = @$subj;
            push(@partial,  $element);
            push(@iterator, \@partial);
        }
    }
    @plots = map { [ @$_, @{$matrix{'unsatisfiable_platforms'}} ] } @plots;

    #OK, now I have a list of potential platforms I can ask whether they exist
    foreach my $gambit (@plots) {
        $jobspec{platforms} = $gambit;
        $plans = &{\&{$self->{planner} . "::get_plans_needing_work"}}(%jobspec);
        return @$plans if (ref($plans) eq 'ARRAY') && @$plans;
    }
    return ();
}

sub queue_jobs {
    print "Queued local job.\n";
    return 0;
}

sub build_queue_name {
    my ($self, $jobspec) = @_;
    my $name = $jobspec->{version};
    $name .= join('', @{$jobspec->{platforms}});
    return $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Queue::Default; - Coordinate the running of test plans across multiple forks.

=head1 VERSION

version 0.001

=head1 SUMMARY

Grabs a random selection of tests from a provided test plan, and executes them.

=head1 CONFIGURATION

Accepts a granularity option in the [Queue] section of elastest.conf controlling how many tests you want to grab at a time.
If the value is not set, we default to running everything available for our configuration.
You can use this to (minimize) duplicate work done when using multiple workers of the same configuration.

=head1 CONSTRUCTOR

=head2 new(%config_options)

Thin wrapper around App::Prove::Elasticsearch::Utils::process_configuration.
Subclasses likely will do more with this, such as advertise their availability to a queue.

=head1 METHODS

=head2 get_jobs

Gets the runner a selection of jobs that the queue thinks appropriate to our current configuration (if possible),
and that should keep it busy for a reasonable amount of time (see the granularity option).

The idea here is that clients will run get_jobs in a loop (likely using several workers) and run them until exhausted.

=head2 list_queues(%provision_options)

List the existing queues of jobs available.

=head2 queue_jobs

Stub method.  Does nothing except in 'real' queue modules like Rabbit, etc.

Called in bin/testplan to add jobs to our queue at plan creation.
Should return the number of jobs that failed to queue.

=head2 build_queue_name

Builds a queue_name inside a passed job specification hashref containing version and platforms information.

Here mostly in case you need to override this for your queueing solution.

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
