package App::GHGen::Fixer;

use v5.36;
use strict;
use warnings;
use YAML::XS qw(LoadFile DumpFile);
use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw(
	apply_fixes
	can_auto_fix
	fix_workflow
);

our $VERSION = '0.06';

=head1 NAME

App::GHGen::Fixer - Auto-fix workflow issues

=head1 SYNOPSIS

    use App::GHGen::Fixer qw(apply_fixes);

    my $fixed = apply_fixes($workflow, \@issues);

=head1 FUNCTIONS

=head2 can_auto_fix($issue)

Determine whether a given issue can be automatically resolved.

=head3 Purpose

Act as a capability gate before calling C<apply_fixes>.  Returns true only
for the four issue types that the Fixer knows how to handle.

=head3 Arguments

=over 4

=item C<$issue> (HashRef, required)

An issue hash with at least a C<type> key.  Recognised types are
C<performance>, C<security>, C<cost>, and C<maintenance>.

=back

=head3 Returns

C<1> (true) when the issue type is auto-fixable; C<0> (false) otherwise.

=head3 Side Effects

None.  Pure predicate.

=head3 Usage Example

    if (can_auto_fix($issue)) {
        apply_fixes($workflow, [$issue]);
    }

=head3 API SPECIFICATION

=head4 Input

    { issue => { type => 'hashref', required => 1 } }

=head4 Output

    { type => 'scalar' }   # boolean: 1 or 0

=head3 FORMAL SPECIFICATION

    can_auto_fix : Issue → 𝔹

    FixableTypes ≔ { performance, security, cost, maintenance }

    can_auto_fix(i) ≡ i.type ∈ FixableTypes

=cut

sub can_auto_fix($issue) {
	my %fixable = (
		'performance' => 1,  # Can add caching
		'security'    => 1,  # Can update action versions and add permissions
		'cost'        => 1,  # Can add concurrency, filters
		'maintenance' => 1,  # Can update runners
	);

	return $fixable{$issue->{type}} // 0;
}

=head2 apply_fixes($workflow, $issues)

Apply all auto-fixable changes from C<$issues> directly to C<$workflow>.

=head3 Purpose

Iterate over C<$issues>, skip issues that are not auto-fixable, and call
the appropriate internal fix routine for each fixable type/message
combination.  Modifies C<$workflow> in place.

=head3 Arguments

=over 4

=item C<$workflow> (HashRef, required)

The parsed workflow hash to be mutated.

=item C<$issues> (ArrayRef[HashRef], required)

The issues to process.  Each must have C<type> and C<message> keys.

=back

=head3 Returns

The number of individual fix operations applied (an integer ≥ 0).

=head3 Side Effects

Modifies C<$workflow> in place.

=head3 Usage Example

    my $n = apply_fixes($workflow, \@issues);
    say "$n fix(es) applied.";

=head3 API SPECIFICATION

=head4 Input

    {
        workflow => { type => 'hashref',  required => 1 },
        issues   => { type => 'arrayref', required => 1 },
    }

=head4 Output

    { type => 'scalar' }   # non-negative integer

=head3 FORMAL SPECIFICATION

    apply_fixes : Workflow × seq Issue → ℕ

    applied ≔ ∑ { fix(w, i) ∣ i ∈ issues, can_auto_fix(i) }
    result  ≔ applied

    Mutates w by applying each fix in sequence.

=cut

sub apply_fixes($workflow, $issues) {
	my $modified = 0;

	for my $issue (@$issues) {
		next unless can_auto_fix($issue);

        if ($issue->{type} eq 'performance' && $issue->{message} =~ /caching/) {
            $modified += add_caching($workflow);
        }
        elsif ($issue->{type} eq 'security' && $issue->{message} =~ /unpinned/) {
            $modified += fix_unpinned_actions($workflow);
        }
        elsif ($issue->{type} eq 'security' && $issue->{message} =~ /permissions/) {
            $modified += add_permissions($workflow);
        }
        elsif ($issue->{type} eq 'maintenance' && $issue->{message} =~ /outdated action/) {
            $modified += update_actions($workflow);
        }
        elsif ($issue->{type} eq 'cost' && $issue->{message} =~ /concurrency/) {
            $modified += add_concurrency($workflow);
        }
        elsif ($issue->{type} eq 'cost' && $issue->{message} =~ /triggers/) {
            $modified += add_trigger_filters($workflow);
        }
        elsif ($issue->{type} eq 'maintenance' && $issue->{message} =~ /runner/) {
            $modified += update_runners($workflow);
        } elsif ($issue->{type} eq 'performance' && $issue->{message} =~ /missing timeout-minutes/) {
		$modified += add_missing_timeout($workflow);
	}
    }

	return $modified;
}

=head2 fix_workflow($file, $issues)

Load a workflow YAML file, apply fixes, and write it back to disk.

=head3 Purpose

Persist the results of C<apply_fixes> by reading the workflow from C<$file>
with C<YAML::XS::LoadFile>, calling C<apply_fixes>, and rewriting the file
with C<YAML::XS::DumpFile> when at least one fix was applied.

=head3 Arguments

=over 4

=item C<$file> (Str, required)

Path to a YAML workflow file.  Passed directly to C<YAML::XS::LoadFile>.

=item C<$issues> (ArrayRef[HashRef], required)

Issues to fix, each with C<type> and C<message> keys.

=back

=head3 Returns

The number of fixes applied (an integer ≥ 0).  The file is only rewritten
when the count is greater than zero.

=head3 Side Effects

Reads C<$file> from disk; rewrites C<$file> in place when fixes are applied.

=head3 Usage Example

    my $n = fix_workflow('.github/workflows/ci.yml', \@issues);
    say "$n fix(es) written to ci.yml.";

=head3 API SPECIFICATION

=head4 Input

    {
        file   => { type => 'scalar',  required => 1 },
        issues => { type => 'arrayref', required => 1 },
    }

=head4 Output

    { type => 'scalar' }   # non-negative integer

=head3 FORMAL SPECIFICATION

    fix_workflow : Path × seq Issue → ℕ

    w       ≔ LoadFile(file)
    fixes   ≔ apply_fixes(w, issues)
    fixes > 0 → DumpFile(file, w)

    result ≔ fixes

=cut

sub fix_workflow($file, $issues) {
	my $workflow = LoadFile($file);
	my $fixes = apply_fixes($workflow, $issues);

	if ($fixes > 0) {
		DumpFile($file, $workflow);
	}

    return $fixes;
}

# Fix implementations

sub add_caching($workflow) {
	my $jobs = $workflow->{jobs} or return 0;
	my $modified = 0;

    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;

        # Check if already has caching
        my $has_cache = grep { $_->{uses} && $_->{uses} =~ /actions\/cache/ } @$steps;
        next if $has_cache;

        # Detect project type and add appropriate cache
        my $cache_step = detect_and_create_cache_step($steps);
        next unless $cache_step;

        # Insert cache step after checkout
        my $insert_at = 0;
        for my $i (0 .. $#$steps) {
            if ($steps->[$i]->{uses} && $steps->[$i]->{uses} =~ /actions\/checkout/) {
                $insert_at = $i + 1;
                last;
            }
        }

        splice @$steps, $insert_at, 0, $cache_step;
        $modified++;
    }

    return $modified;
}

sub detect_and_create_cache_step($steps) {
    # Detect project type from steps
    for my $step (@$steps) {
        my $run = $step->{run} // '';

        # Node.js
        if ($run =~ /npm (install|ci)/ || ($step->{uses} && $step->{uses} =~ /setup-node/)) {
            return {
                name => 'Cache dependencies',
                uses => 'actions/cache@v5',
                with => {
                    path => '~/.npm',
                    key => '${{ runner.os }}-node-${{ hashFiles(\'**/package-lock.json\') }}',
                    'restore-keys' => '${{ runner.os }}-node-',
                },
            };
        }

        # Python
        if ($run =~ /pip install/ || ($step->{uses} && $step->{uses} =~ /setup-python/)) {
            return {
                name => 'Cache pip packages',
                uses => 'actions/cache@v5',
                with => {
                    path => '~/.cache/pip',
                    key => '${{ runner.os }}-pip-${{ hashFiles(\'**/requirements.txt\') }}',
                    'restore-keys' => '${{ runner.os }}-pip-',
                },
            };
        }

        # Rust
        if ($run =~ /cargo (build|test)/) {
            return {
                name => 'Cache cargo',
                uses => 'actions/cache@v5',
                with => {
                    path => "~/.cargo/bin/\n~/.cargo/registry/index/\n~/.cargo/registry/cache/\n~/.cargo/git/db/\ntarget/",
                    key => '${{ runner.os }}-cargo-${{ hashFiles(\'**/Cargo.lock\') }}',
                },
            };
        }

        # Go
        if ($run =~ /go (build|test)/ || ($step->{uses} && $step->{uses} =~ /setup-go/)) {
            return {
                name => 'Cache Go modules',
                uses => 'actions/cache@v5',
                with => {
                    path => '~/go/pkg/mod',
                    key => '${{ runner.os }}-go-${{ hashFiles(\'**/go.sum\') }}',
                    'restore-keys' => '${{ runner.os }}-go-',
                },
            };
        }
    }

    return undef;
}

sub fix_unpinned_actions($workflow) {
	my $jobs = $workflow->{jobs} or return 0;
	my $modified = 0;

    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            next unless $step->{uses};

            if ($step->{uses} =~ /^(.+)\@(master|main)$/) {
                my $action = $1;
                # Map to appropriate version
                my $version = get_latest_version($action);
                $step->{uses} = "$action\@$version";
                $modified++;
            }
        }
    }

    return $modified;
}

sub add_permissions($workflow) {
	return 0 if $workflow->{permissions};

	$workflow->{permissions} = { contents => 'read' };
	return 1;
}

sub update_actions($workflow) {
	my $jobs = $workflow->{jobs} or return 0;
	my $modified = 0;

    my %updates = (
        'actions/cache@v4' => 'actions/cache@v5',
        'actions/cache@v3' => 'actions/cache@v5',
        'actions/checkout@v5' => 'actions/checkout@v6',
        'actions/checkout@v4' => 'actions/checkout@v6',
        'actions/checkout@v3' => 'actions/checkout@v6',
        'actions/setup-node@v3' => 'actions/setup-node@v4',
        'actions/setup-python@v4' => 'actions/setup-python@v5',
        'actions/setup-go@v4' => 'actions/setup-go@v5',
    );

    for my $job (values %$jobs) {
        my $steps = $job->{steps} or next;
        for my $step (@$steps) {
            next unless $step->{uses};

            for my $old (keys %updates) {
                if ($step->{uses} =~ /^\Q$old\E/) {
                    $step->{uses} = $updates{$old};
                    $modified++;
                }
            }
        }
    }

    return $modified;
}

sub add_concurrency($workflow) {
	return 0 if $workflow->{concurrency};

    $workflow->{concurrency} = {
        group => '${{ github.workflow }}-${{ github.ref }}',
        'cancel-in-progress' => 'true',
    };
    return 1;
}

sub add_trigger_filters($workflow) {
	my $on = $workflow->{on} or return 0;
	my $modified = 0;

    # If 'on' is just 'push', expand it
    if (ref $on eq 'ARRAY' && grep { $_ eq 'push' } @$on) {
        $workflow->{on} = {
            push => {
                branches => ['main', 'master'],
            },
            pull_request => {
                branches => ['main', 'master'],
            },
        };
        $modified++;
    }
    elsif (ref $on eq 'HASH' && $on->{push} && ref $on->{push} eq '') {
        # 'push' with no filters
        $on->{push} = {
            branches => ['main', 'master'],
        };
        $modified++;
    }

    return $modified;
}

sub add_missing_timeout($workflow) {
    my $jobs = $workflow->{jobs} or return 0;
    my $modified = 0;

    for my $job_name (keys %$jobs) {
        my $job = $jobs->{$job_name};

        # Skip if timeout already exists
        next if exists $job->{'timeout-minutes'};

        # Insert default timeout
        $job->{'timeout-minutes'} = 30;
        $modified++;
    }

	return $modified;
}

sub update_runners($workflow) {
	my $jobs = $workflow->{jobs} or return 0;
	my $modified = 0;

    my %runner_updates = (
        'ubuntu-18.04' => 'ubuntu-latest',
        'ubuntu-16.04' => 'ubuntu-latest',
        'macos-10.15'  => 'macos-latest',
        'windows-2016' => 'windows-latest',
    );

    for my $job (values %$jobs) {
        my $runs_on = $job->{'runs-on'} or next;

        if (exists $runner_updates{$runs_on}) {
            $job->{'runs-on'} = $runner_updates{$runs_on};
            $modified++;
        }
    }

    return $modified;
}

sub get_latest_version($action) {
    my %versions = (
        'actions/checkout' => 'v6',
        'actions/cache' => 'v5',
        'actions/setup-node' => 'v4',
        'actions/setup-python' => 'v5',
        'actions/setup-go' => 'v5',
        'actions/upload-artifact' => 'v4',
        'actions/download-artifact' => 'v4',
    );

    return $versions{$action} // 'v4';  # Default fallback
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 COPYRIGHT AND LICENSE

Copyright 2025-2026 Nigel Horne.

Usage is subject to license terms.

The license terms of this software are as follows:

=cut

1;
