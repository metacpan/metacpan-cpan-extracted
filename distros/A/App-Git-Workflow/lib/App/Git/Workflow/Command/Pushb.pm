package App::Git::Workflow::Command::Pushb;

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
use App::Git::Workflow::Brs;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow::Brs->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    get_options(
        \%option,
        'n',
    );

    my $new_branch = shift @ARGV;
    if ( ! $new_branch ) {
        die "git pushb: no other branch\n";
    }

    my @lines = $workflow->get_brs();
    my ($sha, $current) = $workflow->current();

    unshift @lines, "$current";
    $workflow->git->checkout($new_branch);

    $workflow->set_brs(@lines);

    print join ' ', @lines, "\n";
}

1;

__DATA__

=head1 NAME

git-pushb - Help pushb many commits

=head1 VERSION

This documentation refers to git-pushb version 1.1.4

=head1 SYNOPSIS

   git-pushb [option] branch

 OPTIONS:

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-pushb

=head1 DESCRIPTION

Change to branch saving the current branch / commit so you can switch back
at a point

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
