package App::Git::Workflow::Command::Files;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    %option = (
        age => 28,
    );
    get_options(
        \%option,
        'since|s=s',
        'age|a=i',
        'tag|t=s',
        'branch|b=s',
        'local|l',
        'max_history|max-history|m=i',
    ) or return;

    # do stuff here
    $workflow->{VERBOSE} = $option{verbose};
    $workflow->{TEST   } = $option{test};

    my $action = @ARGV && __PACKAGE__->can("do_$ARGV[0]") ? 'do_' . shift @ARGV : 'do_changed';

    my ($release) = $workflow->releases(%option);

    return __PACKAGE__->$action($release, @ARGV);
}

sub do_local {
    my (undef, $release) = @_;

    # get local branch changed files vs prod
    my @local_files = map {/(.*)$/; $1} $workflow->git->diff('--name-only', $release->{name});
    my $all_files   = files_changed();
    my ($type, $name) = $workflow->current();
    my %files;

    # iterate over all locally changed files
    for my $file (@local_files) {
        warn "$file\n" if $option{verbose};

        # check that it has been modified in recent times
        if ($all_files->{$file}) {
            # iterate over each commit id to eliminate them from the current branch
            for my $sha (@{ $all_files->{$file}{sha} }) {
                warn "    $sha\n" if $option{verbose} && $option{verbose} > 1;

                # get a list of branches that the file changed on (apart from the current)
                my @branches =
                    grep {$_ ne $name}
                    map {m{ ([^/\s]*) $}xms; $1}
                    $workflow->git->branch(qw/-a --contains/, $sha);

                next if !@branches;

                my $show = $workflow->git->show($sha);
                my ($author) = $show =~ /^Author: \s+ (.*?) \s+ </xms;
                push @{ $files{$file}{branches} }, @branches;
                push @{ $files{$file}{authors} }, $author;
            }
        }
    }
    for my $file (sort keys %files) {
        my %branches = map { $_ => 1 } @{ $files{$file}{branches} };
        my %authors = map { $_ => 1 } @{ $files{$file}{authors} };
        print "$file\n";
        print "    Modified in : " . (join ', ', sort keys %branches) . "\n";
        print "             by : " . (join ', ', sort keys %authors) . "\n";
    }
}

sub do_changed {
    my $files = files_changed();
    print
        map  { sprintf "%4d %s\n", $files->{$_}{count}, $_ }
        sort { $files->{$a}{count} <=> $files->{$b}{count} || $a cmp $b }
        keys %$files;
}

sub files_changed {
    my $args = $option{since} ? "--since=$option{since}" : "--max-age=" . ( time - 60 * 60 * 24 * $option{age} );
    my @commits = $workflow->git->rev_list('--all', $args);
    my %files;

    for my $id (@commits) {
        chomp $id;
        my (undef, @files) = $workflow->git->show(qw/--name-only --oneline/, $id);
        for my $file (@files) {
            chomp $file;
            $files{$file}{count}++;
            push @{ $files{$file}{sha} }, $id;
        }
    }

    return \%files;
}

1;

__DATA__

=head1 NAME

git-files - Get information on files changed across branches.

=head1 VERSION

This documentation refers to git-files version 1.1.4

=head1 SYNOPSIS

   git-files [changed] [(-s|--age) days] [(-s|--since) YYYY-MM-DD] [-v|--verbose]
   git-files local [(-s|--age) days] [(-s|--since) YYYY-MM-DD] [-v|--verbose]
   git-files set [-v|--verbose]
   git-files

 SUB COMMANDS:
  changed       Files that have changed
  local         See if any locally (to the branch) modified files have been
                modified in other branches.
  set           Sets files modified time to the date they were last committed.

 OPTIONS:
  -a --age[=]days
                Age in days to look changed files
  -s --since[=]YYYY-MM-DDTHH::MM
                Files changed since date
  -t --tag[=]tag
                Tag to use to define a release
  -b --branch[=]branch
                Branch to use to define a release
  -l --local
                Use master as release
  -m --max-history[=]int
                Limit getting release history to this number of commits

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-files

=head1 DESCRIPTION

The C<git-files> command helps to find out which files are being actively
changed by whom and where those files changes are occurring. The aim is to
help developers see if other developers are working on the same files. This
should reduce the potential for conflicts later on (or at least start the
process to resolve those conflicts).

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<do_local ($release)>

=head2 C<do_changed ()>

=head2 C<files_changed ()>

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
