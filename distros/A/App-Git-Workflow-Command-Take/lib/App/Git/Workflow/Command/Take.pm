package App::Git::Workflow::Command::Take;

# Created on: 2015-06-05 11:38:28
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
use Path::Tiny;
use File::Copy qw/copy/;

our $VERSION  = 0.4;
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    my ($self) = @_;

    get_options(
        \%option,
        'quiet|q',
        'ours|mine',
        'theirs',
    );

    my @conflicts = (
        map  { /^ \s+ both \s modified: \s+(.*)$/xms; $1 }
        grep { /^ \s+ both \s modified: \s+/xms }
        $workflow->git->status()
    );

    if (!@ARGV) {
        @ARGV = ('./');
    }

    CONFLICT:
    for my $conflict (@conflicts) {

        PATH:
        for my $path (@ARGV) {
            $path =~ s{^[.]/}{};
            next PATH unless $conflict =~ /^\Q$path\E/;

            resolve($conflict);

            next CONFLICT;
        }
    }

    return;
}

sub resolve {
    my ($file) = @_;

    print "Resolving $file\n";

    my %states = (
        ours   => qr/^<<<<<<</,
        theirs => qr/^=======/,
        keep   => qr/^>>>>>>>/,
    );
    my $state = 'keep';
    my $side  = $option{theirs} ? 'theirs' : 'ours';
    my $read  = path($file)->openr;
    my $tmp   = path($file . '.tmp');
    my $write = $tmp->openw;

    LINE:
    while (my $line = <$read>) {
        for my $check (keys %states) {
            if ( $line =~ /$states{$check}/ ) {
                $state = $check;
                next LINE;
            }
        }

        print {$write} $line if $state eq 'keep' || $state eq $side;
    }

    close $write;
    unlink $file;
    copy $tmp, $file;
    unlink $tmp;

    return;
}

1;

__DATA__

=head1 NAME

App::Git::Workflow::Command::Take - Resolve merge conflicts by only taking one side of each conflicted section

=head1 VERSION

This documentation refers to git-take-mine version 0.4

=head1 SYNOPSIS

   git-take-mine [option] [path_or_file]

 OPTIONS:
  -q --quiet    Suppress notifying of files changed
     --ours     Take choanges from current branch throwing away other branches changes
     --theirs   Take changes from merging branch throwing away current branches changes

  -v --verbose  Show more detailed option
     --VERSION  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-take-mine

=head1 DESCRIPTION

C<git take> provides a way of quickly resolving conflicts by taking only one
side of the conflict. It does this differently to C<git checkout --ours> /
C<git checkout --theirs> as it only takes the conflicted part not the whole
of one side of the merge. Where this can come in handy is for merging things
with version number (eg pom.xml) where only the version number conflicts and
there may be other changes in the file that should be taken.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Finds the conflicted files to resolve

=head2 C<resolve ($file)>

Resolves conflicts in C<$file> in favor of C<--ours> or C<--theirs>.

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
