package App::Git::Workflow::Command::SinceRelease;

# Created on: 2014-03-11 20:58:59
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

our $VERSION  = 0.4;
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    my ($self) = @_;

    get_options(
        \%option,
        'quiet|q',
    );

    # get newest tag
    my $tag = $self->newest_tag;
    return if $option{quiet} && !$tag;

    # get rev-parse --all -n 100
    # stop processing when commit is tag
    my $count = 0;
    my %seen;
    for my $id (reverse $workflow->git->rev_parse("--all")) {
        next if $seen{$id}++;
        my $details = $workflow->commit_details($id);
        next if $details->{time} < $tag;
        $count++;
    }

    print "Ahead by $count commit" . ($count != 1 ? 's' : '') . "\n" if !$option{quiet} || $count;

    return;
}

sub newest_tag {
    my ($self) = @_;
    my ($max_tag, $max_time) = ('', 0);

    for my $tag ($workflow->git->tag) {
        my $details = $workflow->commit_details($tag);
        if ($details->{time} > $max_time) {
            $max_time = $details->{time};
            $max_tag = $tag;
        }
    }

    return $max_time;
}

1;

__DATA__

=head1 NAME

App::Git::Workflow::Command::SinceRelease - Finds out how many commits a branch is since latest release

=head1 VERSION

This documentation refers to git-since-release version 0.4

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

Executes the git workflow command

=head2 C<newest_tag ()>

Returns the most recently created tag

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
