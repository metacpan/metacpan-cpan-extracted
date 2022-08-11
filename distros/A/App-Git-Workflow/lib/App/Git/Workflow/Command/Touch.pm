package App::Git::Workflow::Command::Touch;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use DateTime::Format::HTTP;
use File::Touch;
use Term::ANSIColor qw/colored/;
use Path::Tiny;

use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.20);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    get_options( \%option, 'recurse|r!', 'commitish|c=s', );

    for my $file (@ARGV) {
        git_touch($file);
    }
}

sub git_touch {
    my ($file) = @_;
    my $ref = $option{commitish} || 'HEAD';

    if ( -d $file ) {
        my $max_time = 0;

        if ( !$option{recurse} ) {
            return 0;
        }
        my @children = path($file)->children;
        for my $child (@children) {
            my $time = git_touch($child);
            if ( $time > $max_time ) {
                $max_time = $time;
            }
        }

        File::Touch->new( time => $max_time )->touch($file);
        return $max_time;
    }

    my ($log) = $workflow->git->log( '-n1', '--format=format:%ai', $file );

    if ( !$log ) {
        return 0;
    }

    my ( $date, $tz ) = $log =~ /^(.*)\s+([+-]\d{4})$/;
    my $time = DateTime::Format::HTTP->parse_datetime( $date, $tz )->epoch;

    File::Touch->new( time => $time )->touch($file);

    return $time;
}

1;

__DATA__

=head1 NAME

git-touch - Touch files to match the git change times

=head1 VERSION

This documentation refers to git-touch version 1.1.20

=head1 SYNOPSIS

   git-touch [-r|--recurse] [(-c|--commitish) ref] file_or_dir

 OPTIONS:
  -r --recurse
  -c --commitish=[commitish]
                Reference commit to get dates from (Default is current commit)

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-touch

=head1 DESCRIPTION

This will get the last changed time in the git history for a file and set
that time on the file.

If the file is a directory and --recurse is specified then the directories
time will be set to the most rectent changed time for files with in it as
well as changing the times of those files.

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
