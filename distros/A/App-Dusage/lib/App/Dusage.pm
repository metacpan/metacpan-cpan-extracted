#! perl

use strict;
use warnings;

package App::Dusage;

=head1 NAME

dusage - provide disk usage statistics

=head1 SYNOPSIS

    dusage [options] ctlfile

      -a  --allstats          provide all statis
      -f  --allfiles          also report file statistics
      -g  --gather            gather new data
      -i input  --data=input  input data as obtained by 'du dir'
			      or output with -g
      -p dir  --dir=dir       path to which files in the ctlfile are relative
      -r  --retain            do not discard entries which do not have data
      -u  --update            update the control file with new values
      -L                      resolve symlinks
      -h  --help              this help message
      --man		      show complete documentation
      --debug                 provide debugging info

      ctlfile                 file which controls which dirs to report
			      default is dir/.du.ctl

=head1 DESCRIPTION

Ever wondered why your free disk space gradually decreases? This
program may provide you with some useful clues.

B<dusage> is a Perl program which produces disk usage statistics.
These statistics include the number of blocks that files or
directories occupy, the increment since the previous run (which is
assumed to be the day before if run daily), and the increment since 7
runs ago (which could be interpreted as a week, if run daily).

B<dusage> is driven by a control file that describes the names of the
files (directories) to be reported. It also contains the results of
previous runs.

When B<dusage> is run, it reads the control file, optionally gathers
new disk usage values by calling the B<du> program, prints the report,
and optionally updates the control file with the new information.

Filenames in the control file may have wildcards. In this case, the
wildcards are expanded, and all entries reported. Both the expanded
names as the wildcard info are maintained in the control file. New
files in these directories will automatically show up, deleted files
will disappear when they have run out of data in the control file (but
see the B<-r> option).

Wildcard expansion only adds filenames that are not already on the list.

The control file may also contain filenames preceded with an
exclamation mark C<!>; these entries are skipped. This is meaningful
in conjunction with wildcards, to exclude entries which result from a
wildcard expansion.

The control file may have lines starting with a dash C<-> that is
I<not> followed by a C<Tab>, which will cause the report to start a
new page here. Any text following the dash is placed in the page
header, immediately following the text ``Disk usage statistics''.

The available command line options are:

=over 4

=item B<-a> B<--allstats>

Reports the statistics for this and all previous runs, as opposed to
the normal case, which is to generate the statistics for this run, and
the differences between the previous and 7th previous run.

=item B<-f> B<--allfiles>

Reports file statistics also. Default is to only report directories.

=item B<-g> B<--gather>

Gathers new data by calling the B<du> program. See also the C<-i>
(B<--data>) option below.

=item B<-i> I<file> or <--data> I<file>

With B<-g> (B<--gather>), write the obtained raw info (the output of the B<du> program) to this file for subsequent use.

Without B<-g> (B<--gather>), a data file written in a previous run is reused.

=item B<-p> I<dir> or B<--dir> I<dir>

All filenames in the control file are interpreted relative to this
directory.

=item B<-L> B<--follow>

Follow symbolic links.

=item B<-r> B<--retain>

Normally, entries that do not have any data anymore are discarded.
If this option is used, these entries will be retained in the control file.

=item B<-u> B<--update>

Update the control file with new values. Only effective if B<-g>
(B<--gather>) is also supplied.

=item B<-h> B<--help> B<-?>

Provides a help message. No work is done.

=item B<--man>

Provides the complete documentation. No work is done.

=item B<--debug>

Turns on debugging, which yields lots of trace information.

=back

The default name for the control file is
I<.du.ctl>, optionally preceded by the name supplied with the
B<-p> (B<--dir>) option.

=head1 EXAMPLES

Given the following control file:

    - for manual pages
    maildir
    maildir/*
    !maildir/unimportant
    src

This will generate the following (example) report when running the
command ``dusage -gu controlfile'':

    Disk usage statistics for manual pages     Wed Nov 23 22:15:14 2000

     blocks    +day     +week  directory
    -------  -------  -------  --------------------------------
       6518                    maildir
	  2                    maildir/dirent
	498                    src

After updating the control file, it will contain:

    - for manual pages
    maildir 6518::::::
    maildir/dirent  2::::::
    maildir/*
    !maildir/unimportant
    src     498::::::

The names in the control file are separated by the values with a C<Tab>;
the values are separated by colons. Also, the entries found by
expanding the wildcard are added. If the wildcard expansion had
generated a name ``maildir/unimportant'' it would have been skipped.

When the program is rerun after one day, it could print the following
report:

    Disk usage statistics for manual pages      Thu Nov 23 17:25:44 2000

     blocks    +day     +week  directory
    -------  -------  -------  --------------------------------
       6524       +6           maildir
	  2        0           maildir/dirent
	486      -12           src

The control file will contain:

    - for manual pages
    maildir 6524:6518:::::
    maildir/dirent  2:2:::::
    maildir/*
    !maildir/unimportant
    src     486:498:::::

It takes very little fantasy to imagine what will happen on subsequent
runs...

When the contents of the control file are to be changed, e.g. to add
new filenames, a normal text editor can be used. Just add or remove
lines, and they will be taken into account automatically.

When run without B<-g> (B<--gather>) option, it reproduces the report
from the previous run.

When multiple runs are required, save the output of the B<du> program 
in a file, and pass this file to B<dusage> using the B<-i> (B<--data>)
option.

Running the same control file with differing values of the B<-f>
(B<--allfiles>) or B<-r> (B<--retain>) options may cause strange
results.

=head1 COMPATIBILITY NOTICE

This program is rewritten for Perl 5.005 and later. However, it is
still fully backward compatible with its 1990 predecessor.

=head1 AUTHOR

Johan Vromans, C<< <JV at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-App-Dusage.

You can find documentation for this module with the perldoc command.

    perldoc App::Dusage

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 LICENSE

Copyright (C) 1990, 2000, 2021, Johan Vromans

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
