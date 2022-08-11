package App::Git::Workflow::Command::RemoteDelete;

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

our $VERSION  = version->new(1.1.20);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option = (
    remote   => 'origin',
    branches => [],
);

sub run {
    get_options(
        \%option,
        'local|l',
        'force|f!',
        'no_verify|no-verify|n',
    );

    if (@ARGV > 1 ) {
        ($option{remote}, @{$option{branches}}) = @ARGV;
    }
    else {
        $option{branches}[0] = shift @ARGV;
    }

    for my $branch (@{ $option{branches} }) {
        if ($option{verbose}) {
            warn "git push ".($option{no_verify} ? '--no-verify' : ()). " --delete $option{remote} $branch\n";
        }

        $workflow->git->push(($option{no_verify} ? '--no-verify' : ()), '--delete', $option{remote}, $branch);

        if ( $option{local} ) {
            $workflow->git->branch('-d', ($option{force} ? '-f' : ()), $branch);
        }
    }
}

1;

__DATA__

=head1 NAME

git-remote-delete - Delete remote branches

=head1 VERSION

This documentation refers to git-remote-delete version 1.1.20

=head1 SYNOPSIS

   git-remote-delete [option] [remote-name]

 OPTIONS:
  remote-name   The name of the remote to delete from (Default origin)

  -l --local    Also delete the local branch
  -f --force    Force delete if local branch is out of date
  -n --no-verify
                Don't run git pre-push hooks

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-remote-delete

=head1 DESCRIPTION

Short hand for running

C<git push origin --delete 'branch'>

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
