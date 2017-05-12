package App::JobLog::Command::info;
$App::JobLog::Command::info::VERSION = '1.042';
# ABSTRACT: provides general App::JobLog information

use App::JobLog -command;
use autouse 'File::Temp'          => qw(tempfile);
use autouse 'Pod::Usage'          => qw(pod2usage);
use autouse 'Carp'                => qw(carp);
use autouse 'App::JobLog::Config' => qw(log DIRECTORY);
use Class::Autouse qw(Config File::Spec);

use Modern::Perl;
no if $] >= 5.018, warnings => "experimental::smartmatch";

# using quasi-pod -- == instead of = -- to make this work with Pod::Weaver

sub execute {
    my ( $self, $opt, $args ) = @_;
    $self->simple_command_check($args);
    my ( $fh, $fn ) = tempfile( UNLINK => 1 );
    my ($executable) = reverse File::Spec->splitpath($0);
    my $text;
    my @options = ( -verbose => 2, -exitval => 0, -input => $fn );
    for ( $opt->verbosity ) {
        when ('man') {
            $text =
                $self->_header($executable)
              . $self->_body($executable)
              . $self->_footer($executable);
            my $perldoc =
              File::Spec->catfile( $Config::Config{scriptdir}, 'perldoc' );
            unless ( -e $perldoc ) {
                carp 'Cannot find perldoc. Text will not be paged.';
                push @options, -noperldoc => 1;
            }
        }
        when ('verbose') {
            $text =
                $self->_header($executable)
              . $self->_basic_usage($executable)
              . $self->_footer($executable);
            push @options, -noperldoc => 1;
        }
        default {
            $text =
              $self->_header($executable) . <<END . $self->_footer($executable);

==head1 For More Information

  $executable info --help
END
            push @options, -noperldoc => 1;
        }
    }

    $text = <<END;
$text
==cut
END
    $text =~ s/^==(\w)/=$1/gm;
    print $fh $text;
    $fh->close;
    pod2usage(@options);
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'describe job log' }

sub full_description {
    <<END
Describes application and provides usage information.
END
}

sub options {
    return (
        [
            "verbosity" => hidden => {
                one_of => [
                    [ 'verbose|v' => 'longer documentation' ],
                    [ 'man'       => 'extensive documentation in pager' ],
                ],
            }
        ]
    );
}

# obtain all the
sub _unambiguous_prefixes {
    my ( $self, $command ) = @_;

    # borrowing this from App::Cmd::Command::commands
    my @commands =
      map { ( $_->command_names )[0] } $self->app->command_plugins;
    my %counts;
    for my $cmd (@commands) {
        for my $prefix ( _prefixes($cmd) ) {
            $counts{$prefix}++;
        }
    }
    my @prefixes;
    for my $prefix ( _prefixes($command) ) {
        push @prefixes, $prefix if $counts{$prefix} == 1;
    }
    return @prefixes;
}

# obtain all the prefixes of a word
sub _prefixes {
    my $cmd = shift;
    my @prefixes;
    for ( my ( $i, $lim ) = ( 0, length $cmd ) ; $i < $lim ; ++$i ) {
        push @prefixes, substr $cmd, 0, $lim - $i;
    }
    return @prefixes;
}

sub _header {
    my ( $self, $executable ) = (@_);
    return <<END;
==head1 Job Log

work log management

version @${[ $App::JobLog::Command::info::VERSION // 'DEVELOPMENT' ]}

This application allows one to keep a simple, human readable log
of one's activities. B<Job Log> also facilitates searching, summarizing,
and extracting information from this log as needed.
END
}

sub _body {
    my ( $self, $executable ) = (@_);
    return $self->_basic_usage($executable) . $self->_advanced_usage();
}

sub _basic_usage {
    my ( $self, $executable ) = (@_);
    return <<END;

==head1 Usage

B<Job Log> keeps a log of events and notes. If you begin a new task you type

   $executable @{[App::JobLog::Command::add->name]} what I am doing now

and it appends the following, modulo changes in time, to @{[log]}:

   2011 2 1 15 19 12::what I am doing now

The portion before the first colon is a timestamp in year month day hour minute second format.
The portion after the second colon is your description of the event.

If you wish to take a note, you type

   $executable @{[App::JobLog::Command::note->name]} something I should remember

and it appends the following to @{[log]}:

   2011 2 1 15 19 12<NOTE>:something I should remember

Again, the portion before the first colon is a timestamp. The portion after the E<lt>NOTEE<gt> is
the body of the note.

The text between the two colons, or between the first colon and the E<lt>NOTEE<gt> tag, which is blank in these
examples, is a list of space-delimited tags one can use to categorize things. For
instance, if you were performing this task for Acme Widgets you might have typed

   $executable @{[App::JobLog::Command::add->name]} -t "Acme Widgets" what I am doing now

producing

   2011 2 1 15 19 12:Acme\\ Widgets:what I am doing now

Note the I<\\> character. This is the escape character which neutralizes any special value of
the character after it -- I<\\>, I<:>, or a whitespace character.

You may tag an event multiple times. E.g.,

   $executable @{[App::JobLog::Command::add->name]} -t "Acme Widgets" -t foo -t bar what I am doing now

producing

   2011 2 1 15 19 12:Acme\\ Widgets foo bar:what I am doing now

For readability it is probably best to avoid spaces in tags.

Since one usually works on a particular project for an extended period of time, if you specify no tags
the event or note is given the same tags as the preceding event/note. For example,

   $executable @{[App::JobLog::Command::add->name]} -t foo what I am doing now
   $executable @{[App::JobLog::Command::add->name]} now something else

would produce something like

   2011 2 1 15 19 12:foo:what I am doing now
   2011 2 1 16 19 12:foo:now something else

When you are done with the last task of the day, or your stop to take a break, you type

   $executable @{[App::JobLog::Command::done->name]}

which adds something like

   2011 2 1 16 19 12:DONE

to the log. Note the single colon. In this case I<DONE> is not a tag. Tags are always sandwiched between
two delimiters. I<DONE> here just marks the line as the end of a task.

When you come back to work you can type

   $executable @{[App::JobLog::Command::resume->name]}

to add a new line to the log with the same description and tags as the last task you began.

==head2 Summary Commands

The log is of little use if you cannot extract useful reports of what it contains. For this there are a
variety of commands.

==over 8

==item B<@{[App::JobLog::Command::summary->name]}>

The most extensive and featureful log report command. Example:

 \$ job summary yesterday
 Monday, 14 March
    9:46 - 10:11 am  0.41  widgets  modifying name normalization code to use dates
   10:17 - 10:55 am  0.62  widgets  modifying name normalization code to use dates
     1:49 - 2:08 pm  0.32  widgets  testing PGA file to see whether Felix Frankfurter is still there

   TOTAL HOURS 1.35
    widgets    1.35

==item B<@{[App::JobLog::Command::last->name]}>

The last event recorded. Example:

 \$ job last
 Tuesday, 15 March
   5:07 pm - ongoing  0.00  foo  muttering

   TOTAL HOURS 0.00
   foo         0.00

==item B<@{[App::JobLog::Command::today->name]}>

Everything you've done today. Example:

 \$ job today
 Tuesday, 15 March
   11:33 - 11:35 am  0.04  widgets  checking up on Lem's issue with pipeline
   11:38 - 11:46 am  0.12  widgets  checking up on Lem's issue with pipeline; figuring out null pointer in multi-threaded code
    12:40 - 1:11 pm  0.52  widgets  debugging null pointers

   TOTAL HOURS 0.68
    widgets    0.68

==back

==head2 Obtaining Further Information

If you wish further information there are severals routes:

==over 8

==item B<$executable>

If you invoke B<Job Log> without any arguments you will receive a list of its commands.

==item B<$executable commands>

Another way to obtain a list of commands.

==item B<--help>

Every command has a C<--help> option which will provide minimal help text and a complete list of the options the command
understands.

==item B<$executable help <command>>

The C<help> command will provide a command's full usage text.

==item B<$executable @{[__PACKAGE__->name]} --man>

This command's C<--man> option provides still more extensive help text.

==item B<perldoc>

The Perl modules of which this application is composed each have their own documentation. For example, try

  perldoc App::JobLog

==back

B<TIP:> any unambigous prefix of a command will do. All the following are equivalent:

@{[join "\n", map {"   $executable $_ doing something"} $self->_unambiguous_prefixes(App::JobLog::Command::add->name)]}

This means that for almost all commands you need only use the first letter of the command name.
END
}

sub _advanced_usage {
    my ( $self, $executable ) = (@_);
    return <<END;

==head1 Environment Variables

B<Job Log> is sensitive to a single environment variable:

==head2 @{[DIRECTORY()]}

By default B<Job Log> keeps the log and all other files in a hidden directory called F<.joblog> in your home
directory. If @{[DIRECTORY()]} is set, however, it will keep its files here. This is mostly useful for
testing, though if you find F<.joblog> already is in use by some other application you can use this variable
to prevent collisions. Collisions will only occur if the files F<log> or F<config.ini> exist in this
directory, and B<Job Log> will only alter these files if you append an event to the log or modify some
configuration parameters.

All other configuration is done through the B<@{[App::JobLog::Command::configure->name]}> command.

==head1 Time Expressions

B<Job Log> goes to considerable trouble to interpret whatever time expressions you might throw at it.
For example, it understands all of the following:

   1
   11/24 to today
   17 dec, 2024
   1 april, 2022 to 1-23-2002
   2023.6.5 - 10.26.2020
   2-22 till yesterday
   24 apr
   27 november, 1995 through 10
   3-4-2004
   3-9 - today
   4.23- 16 november, 1992
   8/1/1997 through yesterday
   june 14
   last month - 6.14
   pay period
   2010
   June 2010
   2010/6
   Feb 1 - 14
   ever

Every expression represents an interval of time. It either names an interval or defines it as the span from
the beginning of one interval to the end of another.

==head2 Time Grammar

Here is a complete BNF-style grammar of the time expressions understood by B<Job Log>. In this set of rules
C<s> represents some amount of whitespace, C<d> represents a digit, and C<\\x>, where C<x> is a number,
represents a back reference to the corresponding matched group in the same rule. After the first three
rules the remainder are alphabetized to facilitate finding them in the list. All expressions must match the
first rule.

If you find this system of rules opaque or unwieldy, you can use the B<@{[App::JobLog::Command::parse->name]}>
command to test an expression and see what time interval it is interpreted as.

@{[_bnf()]}
END
}

sub _footer {
    my ( $self, $executable ) = (@_);
    return <<END;

==head1 License etc.

 Author        David Houghton
               dfhoughton\@gmail.com
 Copyright (c) 2011
 License       Perl_5
END
}

# the complete bnf diagram for time grammar, also maintained
# in App::JobLog::TimeGrammar for lack of introspection in pod
sub _bnf {
    return <<END;
              <expression> = s* ( <ever> | <span> ) s*
                    <ever> = "all" | "always" | "ever" | [ [ "the" s ] ( "entire" | "whole" ) s ] "log"
                    <span> = <date> [ <span_divider> <date> ]

                      <at> = "at" | "@"
                 <at_time> = [ ( s | s* <at> s* ) <time> ]
              <at_time_on> = [ <at> s ] <time> s "on" s
               <beginning> = "beg" [ "in" [ "ning" ] ]
                    <date> = <numeric> | <verbal>
               <day_first> = d{1,2} s <month>
                 <divider> = "-" | "/" | "."
                 <dm_full> = d{1,2} s <month> [ "," ] s d{4}
                     <dom> = d{1,2}
                    <full> = <at_time_on> <full_no_time> | <full_no_time> <at_time>
              <full_month> = "january" | "february" | "march" | "april" | "may" | "june" | "july" | "august" | "september" | "october" | "november" | "december"
            <full_no_time> = <dm_full> | <md_full>
            <full_weekday> = "sunday" | "monday" | "tuesday" | "wednesday" | "thursday" | "friday" | "saturday"
                     <iso> = d{4} ( <divider> ) d{1,2} \\1 d{1,2}
                      <md> = d{1,2} <divider> d{1,2}
                 <md_full> = <month> s d{1,2} "," s d{4}
          <modifiable_day> = <at_time_on> <modifiable_day_no_time> | <modifiable_day_no_time> <at_time>
  <modifiable_day_no_time> = [ <modifier> s ] <weekday>
        <modifiable_month> = [ <month_modifier> s ] <month>
       <modifiable_period> = [ <period_modifier> s ] <period>
                <modifier> = "last" | "this" | "next"
                   <month> = <full_month> | <short_month>
               <month_day> = <at_time_on> <month_day_no_time> | <month_day_no_time> <at_time>
       <month_day_no_time> = <month_first> | <day_first>
             <month_first> = <month> s d{1,2}
          <month_modifier> = <modifier> | <termini> [ s "of" ]
                      <my> = <month> [","] s <year>
            <named_period> = <modifiable_day> | <modifiable_month> | <modifiable_period>
                     <now> = "now"
                 <numeric> = <year> | <ym> |<at_time_on> <numeric_no_time> | <numeric_no_time> <at_time>
         <numeric_no_time> = <us> | <iso> | <md> | <dom>
                     <pay> = "pay" | "pp" | "pay" s* "period"
                  <period> = "week" | "month" | "year" | <pay>
         <period_modifier> = <modifier> | <termini> [ s "of" [ s "the" ] ]
         <relative_period> = [ <at> s* ] <time> s <relative_period_no_time> | <relative_period_no_time> <at_time> | <now>
 <relative_period_no_time> = "yesterday" | "today" | "tomorrow"
             <short_month> = "jan" | "feb" | "mar" | "apr" | "may" | "jun" | "jul" | "aug" | "sep" | "oct" | "nov" | "dec"
           <short_weekday> = "sun" | "mon" | "tue" | "wed" | "thu" | "fri" | "sat"
            <span_divider> = s* ( "-"+ | ( "through" | "thru" | "to" | "til" [ "l" ] | "until" ) ) s*
                 <termini> = [ "the" s ] ( <beginning> | "end" )
                    <time> = d{1,2} [ ":" d{2} [ ":" d{2} ] ] [ s* <time_suffix> ]
             <time_suffix> = ( "a" | "p" ) ( "m" | ".m." )
                      <us> = d{1,2} ( <divider> ) d{1,2} \\1 d{4}
                  <verbal> = <my> | <named_period> | <relative_period> | <month_day> | <full>
                 <weekday> = <full_weekday> | <short_weekday>
                    <year> = d{4}
                      <ym> = <year> <divider> d{1,2}
END
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::info - provides general App::JobLog information

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job help info
 job info

 Describes application and provides usage information.


 	-q --quiet         minimal documentation
 	-v --man --verbose  extensive documentation in pager
 	--help             this usage screen

=head1 DESCRIPTION

The synopsis says it all. For command specific help you should try the help command:

 houghton@NorthernSpy:~$ job help summary
 job summary [-iMmTtV] [long options...] <date or date range>

 List events with certain properties in a particular time range. Only the portions
 of events falling within the range will be listed.

 Events may be filtered in numerous ways: by tag, time of day, or terms used in descriptions.
 If tags to match are provided, only those events that contain at least one such tag will be shown. If
 tags not to match are provided, only those events that contain none of these tags will be shown.

 if you provide description filters to match or avoid, these will be interpreted as regexes. try 'perldoc perlre'

This module is basically a number of globs of POD munged a bit, concatenated in various ways, and passed
to L<Pod::Usage>.

=head1 SEE ALSO

L<Pod::Usage>, L<App::JobLog::Command::help>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
