package App::Git::Workflow::Command::Cat;

# Created on: 2015-06-18 16:41:14
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

our $VERSION  = 0.3;
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    my ($self) = @_;

    get_options(
        \%option,
        'revision|r=s',
        'quiet|q',
    );

    my $revision = $option{revision} || 'HEAD';
    my $file     = shift @ARGV;

    print scalar $workflow->git->show("$revision:$file");

    return;
}

1;

__DATA__

=head1 NAME

App::Git::Workflow::Command::Cat - Show the content of a git file.

=head1 VERSION

This documentation refers to App::Git::Workflow::Command::Cat version 0.3

=head1 SYNOPSIS

   git-since-release [option]

 OPTIONS:
  -q --quiet    Suppress notifying of files changed

  -v --verbose  Show more detailed option
     --VERSION  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-since-release

=head1 DESCRIPTION

C<git-since-release> finds out how many commits the repository is since the
latest release (determined by the latest tag).

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Run the command

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
