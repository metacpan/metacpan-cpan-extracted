# PODNAME: App::ape::plan
# ABSTRACT: plan testing using elasticsearch

package App::ape::plan;
$App::ape::plan::VERSION = '0.001';
use strict;
use warnings;

use Getopt::Long qw{GetOptionsFromArray};
use App::Prove::Elasticsearch::Utils;
use App::Prove::State;
use Pod::Usage;
use IO::Prompter [ -yesno, -single, -stdio, -style => 'bold' ];
use List::Util qw{shuffle};
use File::Basename qw{basename};
use POSIX qw{strftime};

sub new {
    my ($class, @args) = @_;

    my (%options, @conf, $help);
    GetOptionsFromArray(
        \@args,
        'platform=s@'   => \$options{platforms},
        'version=s'     => \$options{version},
        'show'          => \$options{show},
        'prompt'        => \$options{prompt},
        'pairwise'      => \$options{pairwise},
        'all-platforms' => \$options{allplatforms},
        'recurse'       => \$options{recurse},
        'extension=s@'  => \$options{exts},
        'name'          => \$options{name},
        'requeue'       => \$options{requeue},
        'replay'        => \$options{replay},
        'help'          => \$help,
    );
    $options{platforms} //= [];

    #Deliberately exiting here, as I "unit" test this as the binary
    pod2usage(0) if $help;

    if (!$options{version}) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg     => "Insufficient arguments.  You must pass --version.",
        );
        return 2;
    }

    if ($options{prompt} && $options{show}) {
        pod2usage(
            -exitval => "NOEXIT",
            -msg =>
              "--prompt and --show are mutually exclusive options.  You must pass one or the other.",
        );
        return 3;
    }

    #Store platform groups in the configuration to differentiate further plans
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
        return 4;
    }

    my $self = {};

    #default platforms to whatever platformer can figure out
    if (!scalar(@{$options{platforms}}) && !$options{allplatforms}) {
        my $platformer =
          App::Prove::Elasticsearch::Utils::require_platformer($conf);
        $options{platforms} = &{\&{$platformer . "::get_platforms"}}();
    }

    $self->{planner} = App::Prove::Elasticsearch::Utils::require_planner($conf);
    &{\&{$self->{planner} . "::check_index"}}($conf);

    my $queue = App::Prove::Elasticsearch::Utils::require_queue($conf);
    $self->{queue} = &{\&{$queue . "::new"}}($queue, \@conf);
    $self->{queue}->{requeue} = $options{requeue};

    $self->{searcher} = $self->{queue}->_get_searcher();

    #Use Prove's arg parser to grab tests & globs correctly
    my $proveState = App::Prove::State->new();
    $proveState->extensions($options{exts}) if $options{exts};
    my @tests_filtered = $proveState->get_tests($options{'recurse'}, @args);
    @args = map { basename $_ } grep { -f $_ } @tests_filtered;
    $self->{cases} = \@args;

    $self->{conf}    = $conf;
    $self->{options} = \%options;

    return bless($self, $class);
}

sub run {
    my $self = shift;

    my @plans = _build_plans(
        $self->{planner}, $self->{conf}, $self->{cases},
        %{$self->{options}}
    );

    my $global_result = 0;
    my $queue_result  = 0;
    foreach my $plan (@plans) {

        if ($self->{options}{show}) {
            $plan->{replay} = $self->{cases} if $self->{options}{replay};

            #Get the state of the plan
            $plan->{state} = [];
            @{$plan->{state}} = &{\&{$self->{planner} . "::get_plan_status"}}
              ($plan, $self->{searcher});

            _print_plan($plan, 1);
            next;
        }
        if ($self->{options}{prompt}) {
            _print_plan($plan);
            if (!$plan->{noop}) {
                IO::Prompter::prompt("Do you want to enact the above changes?")
                  or next;
            } else {
                (
                    IO::Prompter::prompt("Do you want to re-queue the plan?")
                      or next
                ) unless $self->{options}{requeue};
                $self->{queue}->{requeue} = 1;
                $queue_result += $self->{queue}->queue_jobs($plan);
                next;
            }
        }

        #Ensure bogus data doesn't get into ES
        delete $plan->{replay};
        delete $plan->{requeue};

        $global_result +=
          &{\&{$self->{planner} . "::add_plan_to_index"}}($plan);
        $queue_result += $self->{queue}->queue_jobs($plan)
          if !$plan->{noop} || $self->{options}{requeue};
    }
    print "$global_result plans failed to be created, examine above output\n"
      if $global_result;
    print "$queue_result plans failed to be queued, examine above output\n"
      if $queue_result;
    return $global_result ? 2 : 0;
}

sub _build_plans {
    my ($planner, $conf, $tests, %options) = @_;

    my @plans;
    my @pgroups = grep { $_ =~ m/PlatformGroups/ } keys(%$conf);

    #filter groups by what we actually passed, if we have any
    if (scalar(@{$options{platforms}}) && !$options{allplatforms}) {

        foreach my $grp (@pgroups) {
            @{$conf->{$grp}} = grep {
                my $grp = $_;
                grep { $grp eq $_ } @{$options{platforms}};
            } @{$conf->{$grp}};
            delete $conf->{$grp} unless scalar(@{$conf->{$grp}});
        }
        @pgroups = grep { $_ =~ m/PlatformGroups/ } keys(%$conf);
    }

    if (scalar(@pgroups)) {

        #break out the groups depending if we are pairwise or not
        if ($options{pairwise}) {

            #Randomize execution order
            @$tests = shuffle(@$tests);

            # The idea here is to have at least one pigeon in each hole.
            # This is accomplished by finding the longest list of groups, and then iterating over everything we have modulo their size.
            my $longest;
            foreach my $pgroup (@pgroups) {
                $longest ||= $pgroup;
                $longest = $pgroup
                  if scalar(@{$conf->{$pgroup}}) > scalar(@{$conf->{$longest}});
            }

            my @last_tests_apportioned;
            for (my $i = 0; $i < scalar(@{$conf->{$longest}}); $i++) {
                my %cloned = %options;
                my @newplats;
                foreach my $pgroup (@pgroups) {
                    my $idx = $i % scalar(@{$conf->{$pgroup}});
                    push(@newplats, $conf->{$pgroup}->[$idx]);
                }
                $cloned{platforms} = \@newplats;

                #Figure out how many tests to dole out to the run
                my @tests_apportioned;
                my $tests_picked =
                  int(scalar(@$tests) / scalar(@{$conf->{$longest}}));
                for (0 .. $tests_picked) {
                    my $picked = shift @$tests;
                    push(@tests_apportioned, $picked) if $picked;
                }

                #Handle the corner case where we are passed less tests than we have platforms
                @tests_apportioned = @last_tests_apportioned
                  if !scalar(@tests_apportioned);
                @last_tests_apportioned = @tests_apportioned;

                push(
                    @plans,
                    _build_plan($planner, \@tests_apportioned, %cloned)
                );
            }
        } else {

            #construct iterator
            my @pigeonholes = map { $conf->{$_} } @pgroups;

            my @iterator = @{$pigeonholes[0]};
            while (scalar(@iterator)) {
                my $subj = shift @iterator;

                #Handle initial elements
                $subj = [$subj] if ref $subj ne 'ARRAY';

                #Break out of the loop if we have no more possibilities to exploit
                if (scalar(@$subj) == scalar(@pigeonholes)) {
                    my %cloned = %options;
                    $cloned{platforms} = $subj;
                    push(@plans, _build_plan($planner, $tests, %cloned));
                    next;
                }

                #Keep pushing partials on to the end of the iterator, until we run out of categories to add
                foreach my $element (@{$pigeonholes[ scalar(@$subj) ]}) {
                    my @partial = @$subj;
                    push(@partial,  $element);
                    push(@iterator, \@partial);
                }
            }

        }
    } else {
        push(@plans, _build_plan($planner, $tests, %options));
    }

    #TODO inject creator & created time into plans
    @plans =
      map { $_->{created} = strftime("%Y-%m-%d %H:%M:%S", localtime()); $_ }
      @plans;

    return @plans;
}

sub _build_plan {
    my ($planner, $tests, %options) = @_;
    $options{tests} = $tests;

    #First, see if we already have a plan like this.
    my $existing = &{\&{$planner . "::get_plan"}}(%options);

    #If not, make the plan.  Otherwise, construct the update statements needed to 'make it so'.
    if (!$existing) {
        $existing = &{\&{$planner . "::make_plan"}}(%options);
    } else {
        $existing = &{\&{$planner . "::make_plan_update"}}($existing, %options);
    }

    return $existing;
}

sub _print_plan {
    my ($plan, $force) = @_;
    if (!$plan->{noop} || $force) {
        print "Name: $plan->{name}\n" if $plan->{name};
        print "SUT version: $plan->{version}\n";
        print "Platforms: " . join(', ', @{$plan->{platforms}}) . "\n";
        print "Pairwise? "
          . ($plan->{pairwise} ne 'false' ? 'yes' : 'no') . "\n";
        print "Created at $plan->{created}\n";
        print "=========================\n";
        if ($plan->{state}) {
            foreach my $t (@{$plan->{state}}) {
                if ($plan->{replay} && $t->{body}) {
                    next
                      if (scalar(@{$plan->{replay}})
                        && !grep { $_ eq $t->{name} } @{$plan->{replay}});
                    print "\n$t->{name}..\n";
                    print "Test Version: $t->{test_version}\n"
                      if $t->{test_version};
                    print "=========================\n";
                    print "$t->{body}";
                }

                my $pln = '';
                if (   ($t->{status} ne 'UNTESTED')
                    && (ref($t->{steps}) eq 'ARRAY')) {
                    my $executed = scalar(@{$t->{steps}});
                    my $planned  = $t->{steps_planned};
                    $pln = "$executed/$planned ";
                }
                printf "%-60s %-10s %s\n", $t->{name}, $pln, $t->{status};
            }
        } else {
            foreach my $t (@{$plan->{tests}}) {
                print "$t\n";
            }
            if ($plan->{update}) {
                if (ref $plan->{update}->{subtraction}->{tests} eq 'ARRAY') {
                    print "\nRemove the following from the plan:\n";
                    print "=========================\n";
                    foreach my $t (@{$plan->{update}->{subtraction}->{tests}}) {
                        print "$t\n";
                    }
                }
                if (ref $plan->{update}->{addition}->{tests} eq 'ARRAY') {
                    print "\nAdd the following to the plan:\n";
                    print "=========================\n";
                    foreach my $t (@{$plan->{update}->{addition}->{tests}}) {
                        print "$t\n";
                    }
                }
            }
        }
    } else {
        print "Plan already exists, and no updates will be made.\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ape::plan - plan testing using elasticsearch

=head1 VERSION

version 0.001

=head1 USAGE

ape plan --version blahblah --platform something -- test1 test2 test3...testN

Will create a test plan and store it in elasticsearch, supposing one does not already exist for the passed version.
Will also queue tests if a non-default Queue module is configured in elastest.conf.

In the event a plan matching your platform(s) and version is found, tests passed but not found in the plan will be added.
Similarly, tests found in the plan but not passed will be removed.

If no platform(s) are provided, the configured (or default) platformer class will be used.

The basename of the tests passed will be used to identify 'what tests need to be run', so be sure to name your tests uniquely.

Tests passed which cannot be found will be ignored.
If no tests are passed, any tests in t/ will be used by default.

=head2 optional switches

=over 4

=item B<--show> - display the proposed plan instead of creating it, and whether or not it already exists (or will be modified by passed arguments).
If the plan already exists, the execution status of the relevant tests will also be displayed.

=item B<--prompt> - display proposed modifications to a plan (if any) will be made on the server.

=item B<--pairwise> - If configured with platform groups (see below), consider the plan satisfied if each platform passed appears at least once.
In the event that a plan update is made, tests will be properly apportioned upon update.

=item B<--all-platforms> - If configured with platform groups, use all those available rather than passing manually with --platform.

=item B<--name> - If you want to differentiate your run from others with the same versions/platforms, use this.

=item B<--recurse> - if passing directories of tests, recurse past the first level to find tests.

=item B<--extension> - If passing directories, check for tests with these extensions.  May be passed multiple times, defaults to t

=item B<--requeue> - Re-queue an existing plan, in case something didn't quite work out.  Use to suppress prompts about re-queueing in --prompt mode.

=item B<--replay> - Dump the body of the test(s) associated when in --show mode.  Filter the tests displayed by passing test names.

=back

=head1 CONFIGURATION

Aside from the usual configuration from L<App::Prove::Plugin::Elasticsearch>,
you can add a new section to describe mutually exclusive platforms (combinations, for my fellow math geeks out there).

It would look something like this:

    [PlatformGroups]
    Operating Systems = CentOS 7 64-bit,CentOS 6 32-bit
    Browsers = Firefox,Chrome
    Interpreters = Perl 5.14,Perl 5.16

And result in plans specifying multiple platforms within the same group requiring the test be run at least once on all said platforms.
For example, a plan created asking for all the above platforms would result in the following 8 runs being needed (2^3):

=over 4

=item CentOS 7 64-bit on Firefox using Perl 5.14

=item CentOS 7 64-bit on Firefox using Perl 5.16

=item CentOS 6 64-bit on Firefox using Perl 5.14

=item CentOS 6 64-bit on Firefox using Perl 5.16

=item CentOS 7 64-bit on Chrome using Perl 5.14

=item CentOS 7 64-bit on Chrome using Perl 5.16

=item CentOS 6 64-bit on Chrome using Perl 5.14

=item CentOS 6 64-bit on Chrome using Perl 5.16

=back

In general, the number of runs you will be required to execute to satisfy the plan will be $num_groups_represented * $num_groups_provided.

=head2 PAIRWISE TESTING

Were you to pass --pairwise, we would randomly mix the configurations to be something like so:

=over 4

=item CentOS 6 64-bit on Firefox using Perl 5.14

=item CentOS 7 64-bit on Chrome using Perl 5.16

=back

This way you would get all your supported platforms tested, but with less testing effort.
Over successive verisons you would cover all the 8 combinations above eventually.

Supposing you have no platform groups defined, it is assumed that no platform is mutually exclusive;
therefore only one run would be required, supposing it satisfied all the provided platforms.

Furthermore, the tests provided will be evenly apportioned amongst the sets of platforms produced, to further expedite testing.

=head2 EXTENSIBILITY

As with all the other utilities here, the backend used to store test plans is extensible by specifying the planner class in elastest.conf.

Setting client.planner=SomeClass

would correspond to App::Prove::Elasticsearch::Planner::SomeClass being loaded and used as the planner backend.

See L<App::Prove::Elasticsearch::Planner::Default> as a template for making planner classes.

=head1 CONSTRUCTOR

=head2 new(@ARGV)

Process the passed configuration and arguments and require the necessary plugins to create or view test plans.

=head1 METHODS

=head2 run()

Creates or views test plans based on your passed data.

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
