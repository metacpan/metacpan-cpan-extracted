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

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    get_options(
        \%option,
        'remote|r',
        'insensitive|i',
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
        warn 'bad head' if !$branch->{HEAD};
        next if !$branch->{HEAD};

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

    @data = sort {$a->{age} cmp $b->{age}} @data;
    if ($option{reverse}) {
        @data = reverse @data;
    }
    for my $branch (@data) {
        printf "%s\t%s\n", $branch->{age}, $branch->{short};
    }
}

1;

__DATA__

=head1 NAME

git-branch-age - grep tags

=head1 VERSION

This documentation refers to git-branch-age version 1.1.4

=head1 SYNOPSIS

   git-branch-age [option] regex

 OPTIONS:
  regex         grep's perl (-P) regular expression

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
