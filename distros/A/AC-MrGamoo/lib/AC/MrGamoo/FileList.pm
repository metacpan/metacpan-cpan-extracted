# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 17:04 (EST)
# Function: get list of files to map
#
# $Id: FileList.pm,v 1.1 2010/11/01 18:41:42 jaw Exp $

package AC::MrGamoo::FileList;
use AC::MrGamoo::Customize;
use AC::Import;
use strict;

our @ISA    = 'AC::MrGamoo::Customize';
our @EXPORT = qw(get_file_list);
our @CUSTOM = @EXPORT;

1;

=head1 NAME

AC::MrGamoo::FileList - get list of files

=head1 SYNOPSIS

    emacs /myperldir/Local/MrGamoo/FileList.pm
    copy. paste. edit.

    use lib '/myperldir';
    my $m = AC::MrGamoo::D->new(
        class_filelist    => 'Local::MrGamoo::FileList',
    );

=head1 IMPORTANT

You can fire up the system, and get the servers talking to each other, and
perform some limited tests without this file.

But you must provide this file in order to actually run map/reduce jobs.

=head1 DESCRIPTION

MrGamoo only runs map/reduce jobs.
It is up to you to get the files on to the servers
and keep track of where they are. And to tell MrGamoo.

Some people keep the file meta-information in a sql database.
Some people keep the file meta-information in a yenta map.
Some people keep the file meta-information in the filesystem.

When a new job starts, your C<get_file_list> function will be
called with the job config, and should return an arrayref
of matching files along with meta-info.

Each element of the returned arrayref should be a hashref
containing at least the following fields:

=head2 filename

the name of the file, relative to the C<basedir> in your config file.

    filename    => 'www/2010/01/17/23/5943_prod_5x2N5qyerdeddsNi'

=head2 location

an arrayref of servers where this file is located. the locations
should be the persistent-ids of the servers (see MySelf).

if the same file is replicated on multiple servers, mrgamoo will
be able to both intelligently determine which servers will process
which files, as well as recover from failures.

    location	=> [ 'mrm@athena.example.com', 'mrm@zeus.example.com' ]

=head2 size

this should be the size of the file, in bytes. mrgamoo will consider
the sizes of files in determining which servers will process which files.

    size	=> 10843

=head1 BUGS

none. you write this yourself.

=head1 SEE ALSO

    AC::MrGamoo

=head1 AUTHOR

    You!

=cut
