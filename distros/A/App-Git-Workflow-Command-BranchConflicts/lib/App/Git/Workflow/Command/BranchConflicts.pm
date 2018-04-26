package App::Git::Workflow::Command::BranchConflicts;

# Created on: 2015-04-12 06:56:18
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Pod::Usage ();
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;
use Capture::Tiny qw/capture_stderr/;

our $VERSION  = 0.5;
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    my ($self) = @_;

    get_options(
        \%option,
        'remote|r',
        'both|a',
        'merge|m=s',
        'since|s=s',
        'ignore|i=s',
        'quiet|q',
    );

    my ($type, @arg) = $option{remote} ? (qw/remote -r/) : $option{both} ? (qw/both -a/) : ();
    my @branches
        = $option{merge}
        ? map {/^\s+(.*)$/; $1} $workflow->git->branch(@arg, '--no-merged', $option{merge})
        : $workflow->branches($type);
    my %conflicts;

    # check all branches for conflicts with other branches
    while (@branches > 1) {
        my $first_branch = shift @branches;
        next if $option{since} && !$workflow->git->log(qw/-n1 --since/, $option{since}, $first_branch);

        print "Checking $first_branch\n" if $option{verbose};

        $self->checkout_branch($first_branch);

        for my $branch (@branches) {
            next if $option{since} && !$workflow->git->log(qw/-n1 --since/, $option{since}, $branch);
            if ( $self->merge_branch_conflicts($branch) ) {
                push @{ $conflicts{$first_branch} }, $branch;
            }
        }

        $workflow->git->reset('HEAD');
        $workflow->git->clean('-xfd');
        $workflow->git->checkout('.');
        capture_stderr {
            $workflow->git->checkout('-');
        };
    }

    if (%conflicts) {
        print "Conflicting branches:\n";
        for my $branch (sort keys %conflicts) {
            print "  $branch\n", map {"    $_\n"} @{ $conflicts{$branch} };
        }
    }
    else {
        print "No conflicts.\n";
    }

    $self->cleanup();

    return;
}

my @checkouts;
sub checkout_branch {
    my ($self, $branch) = @_;

    my $local = 'branch-conflicts-' . sprintf '%03i', scalar @checkouts;
    capture_stderr {
        $workflow->git->checkout('-b', $local, '--no-track', $branch);
    };

    push @checkouts, $local;

    return $local;
}

sub merge_branch_conflicts {
    my ($self, $branch) = @_;

    capture_stderr {
        eval { $workflow->git->merge('--no-commit', $branch) };
    };
    my $status = $workflow->git->status;
    eval { $workflow->git->merge('--abort'); };

    if ($option{ignore}) {
        $status =~ s/both (?:added|modified): \s+ $option{ignore}//;
    }

    return $status =~ /both (?:added|modified)/;
}

sub cleanup {

    while ( my $branch = shift @checkouts) {
        $workflow->git->branch('-D', $branch);
    }

    return;
}
1;

__DATA__

=head1 NAME

App::Git::Workflow::Command::BranchConflicts - Module to find git branches that would conflict if merged

=head1 VERSION

This documentation refers to App::Git::Workflow::Command::BranchConflicts version 0.5

=head1 SYNOPSIS

   git-branch-conflicts [--remote|-r|--all|-a] [(--merge|-m) branch] [(--since|-s) date] [(--ignore|-i) regex]

 OPTIONS:
  -r --remote   List all remote branches
  -a --all      List all branches
  -m --merge[=]branch
                Operate only on branches not merged with this branch
  -s --since[=]date
                Only look at branches that have changes since this date
  -i --ignore[=]regex
                Ignore any files matching this regex that conflict during
                test merges (e.g. pom.xml changes)
  -q --quiet    quite output

     --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-branch-grep

=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Entry point to running conflict checking

=head2 C<checkout_branch ($branch)>

Checks out branch in temporary branch

=head2 C<merge_branch_conflicts ($branch)>

Tries merging branch into current branch

=head2 C<cleanup ()>

Deletes all temporary branches

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
