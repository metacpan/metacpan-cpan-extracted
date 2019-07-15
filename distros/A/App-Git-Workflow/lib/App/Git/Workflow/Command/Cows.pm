package App::Git::Workflow::Command::Cows;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Getopt::Long;
use Pod::Usage ();
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    get_options(
        \%option,
        'quiet|q',
    );

    my @files = map { /^#\s+modified:\s+(.*)\n/ }
        grep {/^#\s+modified:\s+/ }
        $workflow->git->status;

    for my $file (@files) {
        my $diff = $workflow->git->diff('--ignore-all-space', $file);
        chomp $diff;

        if ( !$diff ) {
            warn "\t$file\n" unless $option{quiet};
            $workflow->git->checkout($file);
        }
    }

    return;
}

1;

__DATA__

=head1 NAME

git-cows - checkout whitespace only changed files

=head1 VERSION

This documentation refers to git-cows version 1.1.4

=head1 SYNOPSIS

   git-cows [option]

 OPTIONS:
  -q --quiet    Suppress notifying of files changed

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-cows

=head1 DESCRIPTION

C<git-cows> resets any files that only contain whitespace changes.
This is done by finding all files modified (as shown by a C<git status>) and
run them through C<git diff -w>. If any file results in no out put is shown
(i.e. the changes are only white spaces) the file is then C<git checkout>ed to
remove those changes.

This makes it easier make your commits clean of pointless whitespace only
changes and makes others work easier.

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
