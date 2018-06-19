#!/usr/bin/env perl

=head1 testrail_migrate.pl [OPTIONS] pattern1...patternN

Migrates TestRail test results into the test results database.
Only migrates tests from plans/runs with names matching the provided pattern.  If no patterns are provided, all will be indexed.

Requires you have a functioning ~/.testrailrc (see L<App::Prove::Plugin::TestRail>), and ~/.elastest.conf (see L<App::Prove::Elasticsearch>).

=head2 OPTIONS

=over 4

=item B<--project>: Index plans only from the provided project(s).  May be passed multiple times.

=item B<--only-last>: Only index the last result for a given test, such as ones that had to be re-run to pass.

=item B<--since>: Only index the plans which have been completed since the provided unix timestamp.

=item B<--ingest>: Keep ingesting new data over and over every 5 minutes.  Allows you to enjoy (some of) the benefits of App::Prove::Elasticsearch without actually integrating it in your testsuite.

=back

=cut

package TestRail::Migrate2ES;

use strict;
use warnings;

use Getopt::Long qw{GetOptionsFromArray};
use TestRail::API();
use TestRail::Utils();
use File::HomeDir qw{my_home};
use List::Util qw{any reduce};
use POSIX qw{strftime};

use App::Prove::Elasticsearch::Utils;
use App::Prove::Elasticsearch::Indexer;

our $case_cache = {};
our $sec_cache  = {};

if (!caller()) {
    my %ARGS = main(@ARGV);
    exit 0 unless delete $ARGS{ingest};
    foreach my $k (keys(%ARGS)) { delete $ARGS{$k} unless $ARGS{$k}; }

    my $extra_args = delete $ARGS{patterns};

    my $projects = delete $ARGS{projects};
    my $olast = delete $ARGS{'only-last'};
    my @args = map { ("--$_" => $ARGS{$_}) } keys(%ARGS);
    push(@args,'--only-last') if $olast;
    push(@args,map { ('--project' => $_ ) } @$projects) if scalar(@$projects);
    push(@args,('--ingest',@$extra_args));

    print "Sleeping 5 minutes...\n";
    sleep 300;
    exec $0,@args;
}

sub main {
    my @args = @_;
    my $options;

    GetOptionsFromArray(\@args,
        'project=s@' => \$options->{projects},
        'index-plan' => \$options->{'index-plan'},
        'no-tests'   => \$options->{'no-tests'},
        'only-last'  => \$options->{'only-last'},
        'since=i'    => \$options->{'since'},
        ingest       => \$options->{ingest},
    );
    my @patterns = @args;

    my %ret = %$options;
    $ret{'since'}    = time(); #XXX this is imperfect, and could lead to double ingest, but --ingest shouldn't be used on a long term basis.
    $ret{'patterns'} = \@patterns;

    my $trconf = TestRail::Utils::parseConfig(my_home());
    my $tr = TestRail::Utils::getHandle($trconf);
    $tr->{step_field} = $trconf->{step_results};
    $tr->{'only-last'} = $options->{'only-last'};

    my $esconf = App::Prove::Elasticsearch::Utils::process_configuration();
    my $indexer = App::Prove::Elasticsearch::Utils::require_indexer($esconf);
    &{ \&{$indexer . "::check_index"} }($esconf);

    $tr->{current_status_map} = [];
    $tr->{current_status_map} = reduce {
        my $ret;
        $ret = $a;
        $ret->{$b->{id}} = $b->{name};
        $ret->{$a->{id}} = $a->{name};
        $ret
    } @{$tr->getPossibleTestStatuses()};

    my $projects = $tr->getProjects();
    @$projects = grep {my $subj = $_; any { $subj->{name} eq $_ } @{$options->{projects}} } @$projects if scalar(@{$options->{projects}});

    foreach my $project (@$projects) {

        my $runs  = $tr->getRuns($project->{id});
        @$runs = grep {my $subj = $_; any { $subj->{name} =~ m/$_/ } @patterns } @$runs if @patterns;

        my $plans = $tr->getPlans($project->{id});
        @$plans = grep {my $subj = $_; any { $subj->{name} =~ m/$_/ } @patterns } @$plans if @patterns;

        #Filter by completed-on if provided
        if ($options->{since}) {
            @$runs  = grep { $_->{completed_on} && $_->{completed_on} >= $options->{since} } @$runs;
            @$plans = grep { $_->{completed_on} && $_->{completed_on} >= $options->{since} } @$plans;
        }

        foreach my $plan (@$plans) {
            my $planRuns = $tr->getChildRuns($tr->getPlanByID($plan->{id}));
            push(@$runs,@$planRuns);
        }

        foreach my $run (reverse @$runs) {
			unless ($run->{passed_count}         + $run->{failed_count}         + $run->{blocked_count} +
				    $run->{custom_status1_count} + $run->{custom_status2_count} + $run->{custom_status3_count} +
					$run->{custom_status4_count} + $run->{custom_status5_count} + $run->{custom_status6_count} +
					$run->{custom_status7_count}
			) {
				print "Run $run->{id} had no results, skipping...\n";
				next;
			}

			my @documents;
			print "Examining run $run->{id}...\n";
            my $tests = $tr->getTests($run->{id});
            foreach my $test (@$tests) {
                if (!$test->{case_id}) {
                    print "Encountered malformed test.  Skipping.\n";
                    next;
                }

                $test->{section} = get_section_info($tr,$test->{case_id});

                $test->{config} = $run->{config};
				my @rdocs = build_document($tr,$test);
				unless (@rdocs) {
					print "No results for $test->{title}, skipping...\n";
					next;
				}
				print "Adding ".scalar(@rdocs)." results for $test->{title}...\n";
                push(@documents,@rdocs);
            }
			next unless scalar(@documents);
			print "Indexing ".scalar(@documents)." documents...";
	        &{ \&{$indexer . "::bulk_index_results"} }(@documents);
			print "Done!\n";
        }
    }
    return %ret;
}

sub get_section_info {
    my ($tr,$cid) = @_;

    return $case_cache->{$cid} if $case_cache->{$cid};

    my $c = $tr->getCaseByID($cid);
    my $s = _get_sec($tr,$c->{section_id});
    $case_cache->{$cid} = $s;
    return $s;
}

sub _get_sec {
	my ($tr,$sec) = @_;
	return $sec_cache->{$sec} if $sec_cache->{$sec};

    my $s = $tr->getSectionByID($sec);
	$sec_cache->{$sec} = $s->{name};
	return $s->{name};
}

sub build_document {
    my ($tr,$test) = @_;

    my $results = $tr->getTestResults($test->{id});

	my @documents;
    foreach my $result (@$results) {
        next unless $result->{status_id};
        next if $tr->{current_status_map}->{$result->{status_id}} eq 'untested';
        next if $tr->{current_status_map}->{$result->{status_id}} eq 'duplicate';

        my $test_mangled = {
            body     => $result->{comment},
            elapsed  => translate_elapsed($result->{elapsed}),
            occurred => strftime("%Y-%m-%d %H:%M:%S",localtime($result->{created_on})),
            status   => translate_status($tr->{current_status_map}->{$result->{status_id}}),
            executor => translate_author($tr,$result->{created_by}),
            version  => $result->{version},
            name     => $test->{title},
            path     => $test->{section},
        };

        $test_mangled->{defect}   = $result->{defects} if $result->{defects}; #XXX this may need more work if we have multi-defects on a case
        $test_mangled->{platform} = $test->{config}    if $test->{config}; #XXX this will need more work if we use multi-config
        $test_mangled->{steps}    = translate_steps($tr,$result->{"custom_$tr->{step_field}"}) if $tr->{step_field} && $result->{"custom_$tr->{step_field}"};

		push(@documents,$test_mangled);
        last if $tr->{'only-last'};
    }
	return @documents;
}

sub translate_status {
    my $status = shift;
    return 'UNTESTED' unless $status;
    return 'NOT OK' if grep {$_ eq $status} ('failed','retest');
    return 'OK' if grep {$_ eq $status} ('passed');
    return 'SKIP' if $status eq 'skip';
    return 'TODO FAILED' if $status eq 'todo_fail';
    return 'TODO PASSED' if $status eq 'todo_pass';
    return $status; #custom statuses will be imported 'as-is'
}

sub translate_steps {
    my ($tr,$steps) = @_;
    my $ctr = 1;
    my @new_steps = map { {
        number  => $ctr++,
        text    => $_->{content},
        status  => translate_status($tr->{current_status_map}->{$_->{status_id}}),
    }  } @$steps;
    return \@new_steps;
}

sub translate_elapsed {
    my $elapsed   = shift;
    return 0 unless $elapsed;
    my ($hours)   = $elapsed =~ m/(\d+)h/;
    my ($minutes) = $elapsed =~ m/(\d+)m/;
    my ($seconds) = $elapsed =~ m/(\d+)s/;

    $hours   //= 0;
    $minutes //= 0;
    $seconds //= 0;

    return int($hours) * 3600 + int($minutes) * 60 + int($seconds);
}

sub translate_author {
    my ($tr,$user) = @_;
    my $u = $tr->getUserByID($user);
    return $u->{name};
}
