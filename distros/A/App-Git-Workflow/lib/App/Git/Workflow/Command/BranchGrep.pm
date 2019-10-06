package App::Git::Workflow::Command::BranchGrep;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use Term::ANSIColor qw/colored/;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.6);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option = (
    master => 'origin/master',
);

sub run {
    get_options(
        \%option,
        'search|s=s',
        'colour|color|c',
        'remote|r',
        'all|a',
        'insensitive|i',
        'unmerged|u!',
        'master|m=s',
        'limit|n=i',
    );

    $ARGV[0] ||= '';
    my @options;
    push @options, '-r' if $option{remote};
    push @options, '-a' if $option{all};
    my $grep = $option{insensitive} ? "(?i:$ARGV[0])" : $ARGV[0];
    shift @ARGV;

    my $count = 1;

    for my $branch ( sort {_sorter()} grep { $option{v} ? !/$grep/ : /$grep/ } $workflow->git->branch(@options) ) {
        my $clean_branch = $branch;
        $clean_branch =~ s/^..//;
        $clean_branch =~ s/ -> .*$//;

        if ( $option{unmerged} ) {
            next if unmerged($clean_branch, $option{master});
        }

        last if $option{limit} && $count++ > $option{limit};

        if (@ARGV) {
            my $shown = 0;
            for my $file (@ARGV) {
                my @contents = map {
                        my $found = $_;
                        if ($option{colour}) {
                            $found =~ s/($grep)/colored ['red'], $1/egxms;
                        }
                        $found
                    }
                    grep {/$option{search}/}
                    `git show $clean_branch:$file`;
                if (@contents) {
                    if (!$shown++) {
                        print "$clean_branch\n";
                    }
                    print " $file\n";
                    print @contents;
                    print "\n";
                }
            }
        }
        else {
            if ( $option{colour} ) {
                $branch =~ s/($grep)/colored ['red'], $1/egxms;
            }
            print "$branch\n";
        }
    }
}

sub _sorter {
    no warnings;
    my $A = $a;
    my $B = $b;
    $A =~ s/(\d+)/sprintf "%06d", $1/egxms;
    $B =~ s/(\d+)/sprintf "%06d", $1/egxms;
    $A cmp $B;
}

my @master;
sub unmerged {
    my ($branch, $master) = @_;

    if ( ! @master ) {
        @master = map {/^(.*)\n/; $1} `git log --format=format:%H $master`;
        die "No master" if !@master;
    }

    my $source_sha = `git log --format=format:%H -n 1 $branch`;
    chomp $source_sha;

    return scalar grep {$_ && $_ eq $source_sha} @master;
}

1;

__DATA__

=head1 NAME

git-branch-grep - grep for branch names (and optionally files with them)

=head1 VERSION

This documentation refers to git-branch-grep version 1.1.6

=head1 SYNOPSIS

   git-branch-grep [--remote|-r|--all|-a] regex
   git-branch-grep ((-s|--search) regex) [--remote|-r|--all|-a] regex -- file(s)

 OPTIONS:
  regex         grep's perl (-P) regular expression
  file          When a file is specified the regexp will be run on the file
                not the branch name.
  -r --remote   List all remote branches
  -a --all      List all branches
  -v            Find all branches that don't match regex
  -u --unmerged
                Only show branches not merged to --master
     --no-unmerged
                Only show branches merged to master
  -m --master[=]str
                Branch to check against for --unmerged and --no-unmerged
                (Default origin/master)
  -n --limit[=]int
                Limit the out put to this number
  -s --search[=]regex
                Search term for looking within files

     --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-branch-grep

  Note: to search in all branches set the regex to ''
    eg git branch-grep --search thin '' -- file1 file2

=head1 DESCRIPTION

Short hand for running

C<git branch (-r|-a)? | grep -P 'regex'>

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

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

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
