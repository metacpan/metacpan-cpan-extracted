package App::Git::Workflow::Command::Recent;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage ();
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = 1.0.2;
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    my $self = shift;

    get_options(
        \%option,
        'since|s=s',
        'day|d',
        'week|w',
        'month|m',
        'out|o=s',
        'quiet|q',
    );

    # get a list of recent commits
    my @commits = $self->recent_commits(\%option);

    # find the files in each commit
    my %changed = $self->changed_from_shas(@commits);

    # display results
    my $out = 'out_' . ($option{out} || 'text');

    if ($self->can($out)) {
        $self->$out(\%changed);
    }

    return;
}

sub out_text {
    my ($self, $changed) = @_;

    for my $file (sort keys %$changed) {
        print "$file\n";
        print "  Changed by : " . ( join ', ', @{ $changed->{$file}{users} } ), "\n";
        print "  In branches: " . ( join ', ', @{ $changed->{$file}{branches} } ), "\n";
    }

    return;
}

sub out_perl {
    my ($self, $changed) = @_;

    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Indent = 1;
    print Dumper $changed;

    return;
}

sub out_json {
    my ($self, $changed) = @_;

    require JSON;
    print JSON::encode_json($changed);

    return;
}

sub recent_commits {
    my ($self, $option) = @_;

    my @args = ('--since', $option->{since} );

    if ( !$option->{since} ) {
        my (undef,undef,undef,$day,$month,$year) = localtime;
        $year += 1900;
        $month++;

        @args = $option->{week} ? ('--since', sprintf "%04d-%02d-%02d", $year - 1, $month, $day )
            : $option->{month}  ? ('--since', sprintf "%04d-%02d-%02d", $year, $month - 1, $day )
            :                     ('--since', sprintf "%04d-%02d-%02d", $year, $month, $day - 1 );
    }

    return $workflow->git->rev_list('--all', @args);
}

sub changed_from_shas {
    my ($self, @commits) = @_;
    my %changed;

    for my $sha (@commits) {
        my $changed = $workflow->commit_details($sha, branches => 1, files => 1, user => 1);
        for my $file (keys %{ $changed->{files} }) {
            $changed{$file} ||= { branches => {} };
            $changed{$file}{users}{$changed->{user}}++;
            $changed{$file}{branches} = {
                %{ $changed{$file}{branches} },
                %{ $changed->{branches} },
            };
        }
    }

    for my $file (sort keys %changed) {
        $changed{$file}{users}    = [ sort keys %{ $changed{$file}{users   } } ];
        $changed{$file}{branches} = [ sort keys %{ $changed{$file}{branches} } ];
    }

    return %changed;
}

1;

__DATA__

=head1 NAME

git-recent - Find what files have been changed recently in a repository

=head1 VERSION

This documentation refers to git-recent version 1.0.2

=head1 SYNOPSIS

   git-recent [-since=YYYY-MM-DD|--day|--week|--month] [(-o|--out) [text|json|perl]]
   git-recent --help
   git-recent --man
   git-recent --version

 OPTIONS:
  -s --since[=]iso-date
                Show changed files since this date
  -d --day      Show changed files from the last day (Default action)
  -w --week     Show changed files from the last week
  -m --month    Show changed files from the last month
  -o --out[=](text|json|perl)
                Specify how to display the results
                    - text : Nice human readable format (Default)
                    - json : as a JSON object
                    - perl : as a Perl object
  -q --quiet    Don't show who has changed the file or where it was changed

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-recent

=head1 DESCRIPTION

C<git-recent> finds all files that have been changed in all branches in the
repository. This allows collaborators to quickly see who is working on what
even if it's in a different branch.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<recent_commits ($options)>

Gets a list of recent commits

=head2 C<changed_from_shas (@commits)>

Takes a list of commits and returns a HASH of files changed, by whom and in
what branches.

=head2 C<out_text ($changed)>

Displays changed files in a textural format

=head2 C<out_perl ($changed)>

Displays changed files in a Perl format

=head2 C<out_json ($changed)>

Displays changed files in a JSON format

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
