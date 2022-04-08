package App::Git::Workflow::Command::BranchAge;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use List::MoreUtils qw/zip/;
use Term::ANSIColor qw/colored/;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;
use DateTime::Format::HTTP;
use Data::Dumper qw/Dumper/;

our $VERSION  = version->new(1.1.18);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option = (
    master => 'origin/master',
);

sub run {
    get_options(
        \%option,
        'all|a',
        'remote|r',
        'reverse|R',
        'unmerged|u!',
        'master|m=s',
        'limit|n=i',
        'format|f=s',
        'files|F!',
        'quiet|q',
    );
    my $fmt = join "-%09-%09-", qw/
        %(authordate)
        %(authoremail)
        %(authorname)
        %(body)
        %(HEAD)
        %(objectname)
        %(objecttype)
        %(refname)
        %(refname:short)
        %(subject)
    /;
    my @headings = qw/
        authordate
        authoremail
        authorname
        body
        HEAD
        objectname
        objecttype
        refname
        short
        subject
    /;

    my $arg = '';
    if ( $option{remote} ) {
        $arg .= ' -r';
    }
    my $match = '';
    my $files;
    if (@ARGV) {
        if ($option{files}) {
            $files = join ' ', @ARGV;
        }
        else {
            $match = @ARGV ? shift @ARGV : '';
        }
    }

    my @branches = `git branch $arg --format='$fmt'`;
    my $i = 0;
    my $last = '';
    my @data;

    for my $branch (@branches) {
        chomp $branch;
        if ($last) {
            $last .= "\n";
        }
        $last .= $branch;
        my @cols = split /-\t-\t-/, $last;
        if (@cols < @headings) {
            next;
        }

        $last = '';
        $branch = { zip @headings, @cols };
        next if $match && $branch->{short} !~ /$match/;
        warn 'bad head' if !$branch->{HEAD};
        next if !$branch->{HEAD};
        if ( defined $option{unmerged} ) {
            next if unmerged($branch->{short}, $option{master});
        }

        if ($files) {
            my $date = `git log -n 1 --format=format:%ai $branch->{short} -- $files`;
            chomp $date;

            if ($date) {
                $date = $branch->{authordate};
            }
        }

        my ($date, $tz) = $branch->{authordate} =~ /^(.*)\s+([+-]\d{4})$/;
        if ($date && $tz) {
            $branch->{age} = DateTime::Format::HTTP->parse_datetime($date, $tz)->iso8601;
        }
        else {
            $Data::Dumper::Sortkeys = 1;
            $Data::Dumper::Indent = 1;
            die Dumper $branch;
        }
        push @data, $branch;
    }

    my %max = map {$_ => length $_} @headings;
    for my $branch (@data) {
        for my $key (keys %{$branch}) {
            $max{$key} = length $branch->{$key} if !$max{$key} || $max{$key} < length $branch->{$key};
        }
    }

    @data = sort {$a->{age} cmp $b->{age}} @data;
    if ($option{reverse}) {
        @data = reverse @data;
    }

    my $count = 1;
    my $fmt_out = $option{verbose} ? "%-age\t%-authorname\t%-short"
        : $option{quiet}       ? '%short'
        : $option{format}      ? $option{format}
        :                        "%age\t%short";
    my ($format, @fields) = formatted($fmt_out, \%max);

    if ($option{limit} && @data > $option{limit}) {
        @data = splice @data, @data - $option{limit}, $option{limit};
    }
    for my $branch (@data) {
        printf $format, map {$branch->{$_}} @fields;
    }
}

sub formatted {
    my ($format, $max) = @_;
    my @fields;
    my $fmt = '';
    my @fmt_parts = split /%([+-]?)(\((?:[a-z]+)\)|[a-z]+)/, $format;

    while (defined (my $fixed = shift @fmt_parts)) {
        my $align = shift @fmt_parts;
        my $name = shift @fmt_parts;
        $name =~ s/^[(]|[)]$//g;
        push @fields, $name;
        $fmt .= $fixed . ( $align ? "%$align$max->{$name}s" : "%s" );
    }

    return ("$fmt\n", @fields);
}

my %dest;
sub unmerged {
    my ($source, $dest) = @_;

    if ( ! $dest{$dest} ) {
        @{$dest{$dest}} = map {/^(.*)\n/; $1} `git log --format=format:%H $dest`;
        die "No destination branch commits for '$dest'" if !@{$dest{$dest}};
    }

    my $source_sha = `git log --format=format:%H -n 1 $source`;
    chomp $source_sha;

    return scalar grep {$_ && $_ eq $source_sha} @{$dest{$dest}};
}

1;

__DATA__

=head1 NAME

git-branch-age - grep tags

=head1 VERSION

This documentation refers to git-branch-age version 1.1.18

=head1 SYNOPSIS

   git-branch-age [option] regex

 OPTIONS:
  regex         grep's perl (-P) regular expression
  -a --all      All branches (remote and local
  -r --remote   Remote branches only
  -R --reverse  Reverse the branch sort order
  -u --unmerged
                Only show branches not merged to --master
     --no-unmerged
                Only show branches merged to master
  -m --master[=]str
                Branch to check against for --unmerged and --no-unmerged
                (Default origin/master)
  -n --limit[=]int
                Limit the out put to this number
  -f --format[=]str
                Specify a format for the output
                eg normal format would be --format="%age %short"
                   verbose format would be --format="%age %authorname $short"
                format keys:
                  - authordate
                  - authoremail
                  - authorname
                  - body
                  - HEAD
                  - objectname
                  - objecttype
                  - refname
                  - short
                  - subject

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-branch-age

=head1 DESCRIPTION

Short hand for running

C<git branch | grep -P 'regex'>

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<unmerged ($source, $dest)>

Check if there are any commits in C<$source> that are not in C<$dest>

=head2 C<formatted ($format, $max)>

Creates a format for printf to output a line

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
