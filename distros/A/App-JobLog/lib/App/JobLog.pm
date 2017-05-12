package App::JobLog;
$App::JobLog::VERSION = '1.042';
use App::Cmd::Setup -app;

# ABSTRACT: base of work log application

sub allow_any_unambiguous_abbrev { 1 }

sub command_groups {
  'primary',
  [qw( add done resume when summary edit )],
  'secondary',
  [qw( today last note modify truncate vacation configure )],
  'informational',
  [qw( help commands info tags parse )]
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog - base of work log application

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job
 Available commands:

 primary:
         add: log an event
        done: mark current task as done
      resume: resume last task
        when: report when work is done for the day
     summary: list tasks with certain properties in a particular time range
        edit: open a text editor to edit the log

 secondary:
       today: what has happened today
        last: describe the last task recorded
        note: take a note
      modify: add details to last event
    truncate: shorten the log to contain only those moments after a given date
    vacation: list or define days off
   configure: set or display various parameters

 informational:
        help: display a command's help screen
    commands: list the application's commands
        info: describe job log
        tags: list tags employed in log or some subrange thereof
       parse: parse a time expression

 houghton@NorthernSpy:~$ job summary this week
 Sunday, 27 February, 2011
    8:00 - 9:39 am  1.65  widgets  improving debugging rig to handle batches of files and to print all output to files for later comparison; checking code changes
                                   into github

 Monday, 28 February
   8:00 - 10:47 am  2.79  widgets  gussying up pdf conversion

 Tuesday,  1 March
    8:00 - 9:23 am  1.39  widgets  adding handling of simplified pdf docs

 Friday,  4 March
    1:48 - 2:55 pm  1.11  widgets  trying to get Eclipse working properly again
    3:50 - 5:30 pm  1.66  widgets  figuring out why some files are really, really slow

   TOTAL HOURS 8.60
   widgets     8.60
 houghton@NorthernSpy:~$ job today
 No events in interval specified.
 houghton@NorthernSpy:~$ job add --clear-tags messing around
 houghton@NorthernSpy:~$ job a messing around some more
 houghton@NorthernSpy:~$ job done
 houghton@NorthernSpy:~$ job to
 Sunday,  6 March, 2011
   9:02 - 9:03 am  0.01  messing around; messing around some more

   TOTAL HOURS 0.01
 houghton@NorthernSpy:~$ job resume
 houghton@NorthernSpy:~$ job to
 Sunday,  6 March, 2011
      9:02 - 9:03 am  0.01  messing around; messing around some more
   9:03 am - ongoing  0.00  messing around some more

   TOTAL HOURS 0.01
 houghton@NorthernSpy:~$ job configure --list
 day length                          8
 editor                   /usr/bin/vim
 hidden columns                   none
 merge              adjacent same tags
 pay period length                  14
 precision                           2
 start pay period           2009-01-11
 sunday begins week               true
 time zone                       local
 workdays                        MTWHF
 houghton@NorthernSpy:~$ job conf --precision 1
 precision set to 1
 houghton@NorthernSpy:~$ job to
 Sunday,  6 March, 2011
      9:02 - 9:03 am  0.0  messing around; messing around some more
   9:03 am - ongoing  0.0  messing around some more

   TOTAL HOURS 0.0
 houghton@NorthernSpy:~$ job d
 houghton@NorthernSpy:~$ job note maybe I should take more notes
 houghton@NorthernSpy:~$ job to
 Sunday,  6 March, 2011
   9:02 - 9:03 am  0.0  messing around; messing around some more
   9:03 - 9:06 am  0.0  messing around some more

   TOTAL HOURS 0.1
 houghton@NorthernSpy:~$ cat ~/.joblog/log

...

 2011  3  1  8  0  0:widgets:adding handling of simplified pdf docs
 2011  3  1  9 23 24:DONE
 # 2011/03/04
 2011  3  4 13 48 42:widgets:trying to get Eclipse working properly again
 2011  3  4 14 55 34:DONE
 2011  3  4 15 50 46:widgets:figuring out why some files are really, really slow
 2011  3  4 17 30  7:DONE
 # 2011/03/06
 2011  3  6  9  2 58::messing around
 2011  3  6  9  3 13::messing around some more
 2011  3  6  9  3 18:DONE
 2011  3  6  9  3 48::messing around some more
 2011  3  6  9  6 30:DONE
 2011  3  6  9  6 35<NOTE>:maybe I should take more notes

=head1 DESCRIPTION

B<App::JobLog> provides a simple command line utility for keeping track of what you do when. The underlying
design goals were to keep it fast, simple, and idiot proof and to keep the generated documents human readable
and comprehensible. The usual form of such a document is a log -- a series of line-delimited events, each containing
a time stamp, a description, and perhaps other meta-data. The problem with a log is that it's usually a little
numbing to scroll through it for anything but the most recent events, and with a job log what you usually want
isn't time stamps but durations. So in addition to a logging facility we want a report extraction facility. Finally,
we often want to filter out particular activities and categorize them in various ways, so along with the time stamps
and descriptions we want tags. That's about it. Besides this minimal functionality we want the log to impose as few
restrictions as possible so that we don't need to think about how it works. We don't want to worry about characters
with special valence so the log has to handle its own escaping of spaces and colons and so forth. We don't want to
worry about character encoding so the log has to be in Unicode (utf8).

B<App::JobLog> keeps its documents, by default, in a hidden directory in your home directory called F<.joblog/>. These
documents are a README file explaining to anyone who stumbles across the directory what it's function is, a log, called
F<log>, a configuration file, called F<config.ini>, a vacation file, called F<vacation>, and perhaps log backups.

To perform any action with B<App::JobLog> one invokes the executable with a command and a list of options. These commands
are listed below.

=head2 COMMANDS

=over 8

=item B<help>

Provides extended help information for a particular command. E.g.

 houghton@NorthernSpy:~$ job help summary
 job summary [-iMmTtV] [long options...] <date or date range>

 List events with certain properties in a particular time range. Only the portions
 of events falling within the range will be listed.

 Events may be filtered in numerous ways: by tag, time of day, or terms used in descriptions.
 ...

=item B<commands>

Provides the list of available commands.

=item L<add|App::JobLog::Command::add>

Appends an event to the end of the log. See L<App::JobLog::Command::add>.

=item L<configure|App::JobLog::Command::configure>

Lists or modifies configuration parameters. See L<App::JobLog::Command::configure>.

=item L<done|App::JobLog::Command::done>

Appends an event to the log marking the last event as done. See L<App::JobLog::Command::done>.

=item L<edit|App::JobLog::Command::edit>

Edit the log safely. See L<App::JobLog::Command::edit>.

=item L<info|App::JobLog::Command::info>

Provides extended general help text. See L<App::JobLog::Command::info>.

=item L<last|App::JobLog::Command::last>

Describes the last event in the log. See L<App::JobLog::Command::last>.

=item L<modify|App::JobLog::Command::modify>

Modifies the last event in the log. See L<App::JobLog::Command::modify>.

=item L<note|App::JobLog::Command::note>

Adds a note to the log -- text independent of any task. See L<App::JobLog::Command::note>.

=item L<parse|App::JobLog::Command::parse>

Parse a time expression to discover what the application understands it to mean.
See L<App::JobLog::Command::parse>.

=item L<resume|App::JobLog::Command::resume>

Resumes the last closed event in the log. See L<App::JobLog::Command::resume>.

=item L<summary|App::JobLog::Command::summary>

Presents a portion of the log in more human readable form. See L<App::JobLog::Command::summary>.

=item L<tags|App::JobLog::Command::tags>

List only the tags used to categorize tasks. See L<App::JobLog::Command::tags>.

=item L<today|App::JobLog::Command::today>

Summarizes everything done today. See L<App::JobLog::Command::today>.

=item L<truncate|App::JobLog::Command::truncate>

Pares off and stores the older portion of the log. See L<App::JobLog::Command::truncate>.

=item L<vacation|App::JobLog::Command::vacation>

Allows viewing and modification of a simple database of vacation times kept separately from the log.
See L<App::JobLog::Command::vacation>.

=item L<when|App::JobLog::Command::when>

Reports when you'll have worked the expected number of hours given how many hours you put in in the
specified period (the same day, by default).
See L<App::JobLog::Command::when>.

=back

=head2 WHY NOT A DATABASE?

We basically want database functionality out of our job log -- random access, selecting rows by various
properties, nice reports. Why not use SQLite, say, or Berkeley DB? Well first of all, that adds dependencies,
and we want fewer of those. And except in extraordinary circumstances we are only adding events in sequence and we
will only be interested in the most recent ones. Even when we don't just want the most recent events we
don't need truly random access to the whole log but an interval -- all the lines from one point to another.
We only need a slightly glorified log. A database is overkill. Finally, as soon as we maintain our data in
a database it becomes an opaque blob and our editing interface becomes much more complicated to
write, use, and maintain. We need to write a shell, GUI, or ncurses interface and figure out how to provide
the editor with search facilities, the context in which she is making edits, and perhaps an undo/redo stack.
If it's a text file we just pop up an editor and validate the log on close. So I stuck with a log.

=head1 ACKNOWLEDGEMENTS

Thanks to Ricardo Signes for the redoubtable L<App::Cmd> which wires this all together, Dave Rolsky for L<DateTime>,
which does all the calendar math, and Ingy dE<ouml>t Net for L<IO::All>, which, via L<Tie::File> (thanks, Mark Jason
Dominus), makes random access to a log file trivial.

Thanks also to my wife Paula, who was my only beta tester other than myself.

=head1 SEE ALSO

L<App::Cmd>, L<DateTime>, L<IO::All>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
