package App::Git::Workflow::Command::TagGrep;

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

our $VERSION  = version->new(1.1.16);
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
        'insensitive|i',
        'unmerged|u!',
        'master|m=s',
        'limit|n=i',
    );

    $ARGV[0] ||= '';
    my $grep = $option{insensitive} ? "(?i:$ARGV[0])" : $ARGV[0];
    shift @ARGV;

    my $count = 1;

    for my $tag ( sort {_sorter()} grep {/$grep/} $workflow->git->tag ) {
        if ( $option{unmerged} ) {
            next if unmerged($tag, $option{master});
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
                    `git show $tag:$file`;
                if (@contents) {
                    if (!$shown++) {
                        print "$tag\n";
                    }
                    print " $file\n";
                    print @contents;
                    print "\n";
                }
            }
        }
        else {
            if ( $option{colour} ) {
                $tag =~ s/($grep)/colored ['red'], $1 /egxms;
            }
            print "$tag\n";
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

git-tag-grep - grep tags (and optionally files with them)

=head1 VERSION

This documentation refers to git-tag-grep version 1.1.16

=head1 SYNOPSIS

   git-tag-grep [option] regex
   git-tag-grep ((-s|--search) regex) [option] regex -- file(s)

 OPTIONS:
  regex         grep's perl (-P) regular expression
  file          When a file is specified the regexp will be run on the file
                not the tag name.
  -v            Find all tags that don't match regex
  -u --unmerged
                Only show tags not merged to --master
     --no-unmerged
                Only show tags merged to master
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
     --man      Prints the full documentation for git-tag-grep

  Note: to search in all tags set the regex to ''
    eg git tag-grep --search thin '' -- file1 file2

=head1 DESCRIPTION

Short hand for running

C<git tag | grep -P 'regex'>

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<unmerged ($source, $dest)>

Check if there are any commits in C<$source> that are not in C<$dest>

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
