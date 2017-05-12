package App::TimelogTxt;

use warnings;
use strict;
use 5.010;

use autodie;
use App::CmdDispatch;
use Getopt::Long qw(:config posix_default);
use App::TimelogTxt::Utils;
use App::TimelogTxt::Day;
use App::TimelogTxt::File;
use App::TimelogTxt::Event;

our $VERSION = '0.22';

# Initial configuration information.
my %config = (
    editor => '',
    dir    => '',
    defcmd => '',
);

my $config_file =  _normalize_path( '~/.timelogrc' );

# Dispatch table for commands
my %commands = (
    'start' => {
        code     => \&start_event,
        clue     => 'start {event description}',
        abstract => 'Start timing a new event.',
        help     => 'Stop the current event and start timing a new event.',
    },
    App::TimelogTxt::Utils::STOP_CMD() => {
        code => sub { my $app = shift; log_event( $app, App::TimelogTxt::Utils::STOP_CMD() ); },
        clue => App::TimelogTxt::Utils::STOP_CMD(),
        abstract => 'Stop timing the current event.',
        help     => 'Stop timing the current event.',
    },
    'init' => {
        code     => \&init_timelog,
        clue     => 'init [directory]',
        abstract => 'Create the timelog directory and configuration.',
        help     => 'Create the directory and configuration file used by timelog
if they do not already exist.',
    },
    'push' => {
        code     => \&push_event,
        clue     => 'push {event description}',
        abstract => 'Save the current event and start timing new.',
        help     => 'Save the current event on stack and start timing new event.',
    },
    'pop' => {
        code     => \&pop_event,
        clue     => 'pop',
        abstract => 'Return to last pushed event.',
        help     => 'Stop last event and restart top event on stack.',
    },
    'drop' => {
        code     => \&drop_event,
        clue     => 'drop [all|{n}]',
        abstract => 'Drop items from stack.',
        help     => 'Drop one or more events from top of event stack, or all
if argument supplied.',
    },
    'ls' => {
        code     => \&list_events,
        clue     => 'ls [date]',
        abstract => 'List events.',
        help     => 'List events for the specified day. Default to today.',
    },
    'lsproj' => {
        code     => \&list_projects,
        clue     => 'lsproj',
        abstract => 'List known projects.',
        help     => 'List known projects.',
    },
    'lstk' => {
        code     => \&list_stack,
        clue     => 'lstk',
        abstract => 'Display items on the stack.',
        help     => 'Display items on the stack.',
    },
    'edit' => {
        code     => \&edit_logfile,
        clue     => 'edit',
        abstract => 'Edit the timelog file.',
        help     => 'Open the timelog file in the current editor',
    },
    'report' => {
        code     => \&daily_report,
        clue     => 'report [date [end date]] [project regexes]',
        abstract => 'Task report.',
        help     => 'Display a report for the specified days and projects.',
    },
    'summary' => {
        code     => \&daily_summary,
        clue     => 'summary [date [end date]] [project regexes]',
        abstract => 'Short summary report.',
        help     => q{Display a summary of the appropriate days' projects.},
    },
    'hours' => {
        code     => \&report_hours,
        clue     => 'hours [date [end date]] [project regexes]',
        abstract => 'Hours report.',
        help     => q{Display the hours worked for each of the appropriate days
and projects.},
    },
    'curr' => {
        code     => \&current_event,
        clue     => 'curr',
        abstract => 'Display current event.',
        help     => q{Display the current event (if any) and the time since the
event started.},
    },
);

# Sub class of App::CmdDispatch that initializes configuration information
# specific to this program. It also provides access to that configuration.
{
    package Timelog::CmdDispatch;
    use base 'App::CmdDispatch';

    sub new
    {
        my $self = App::CmdDispatch::new( @_ );
        $self->init();
        $self->{_timelog_out_fh} = \*STDOUT;
        return $self;
    }

    sub _logfile   { return $_[0]->get_config()->{'logfile'}; }
    sub _stackfile { return $_[0]->get_config()->{'stackfile'}; }
    sub _out_fh    { return $_[0]->{_timelog_out_fh}; }

    # Support injection of an output filehandle for testing.
    sub _set_out_fh { return $_[0]->{_timelog_out_fh} = $_[1]; }

    sub init
    {
        my ($self) = @_;
        my $config = $self->get_config();

        $config->{editor} ||= $config{editor} || $ENV{'VISUAL'} || $ENV{'EDITOR'} || 'vim';
        $config->{dir}    ||= $config{dir} || App::TimelogTxt::_normalize_path( '~/timelog' );
        $config->{defcmd} ||= $config{defcmd} || App::TimelogTxt::Utils::STOP_CMD();
        $config->{dir} = App::TimelogTxt::_normalize_path( $config->{'dir'} );
        foreach my $d ( [qw/logfile timelog.txt/], [qw/stackfile stack.txt/] )
        {
            $config->{ $d->[0] } = "$config->{'dir'}/$d->[1]";
        }
        return;
    }

}

sub run
{
    GetOptions(
        "dir=s"    => \$config{'dir'},
        "editor=s" => \$config{'editor'},
        "conf=s"   => \$config_file,
    );

    my $options = {
        config           => (-f $config_file ? $config_file : undef),
        default_commands => 'help shell',
        'help:post_hint' =>
            "\nwhere [date] is an optional string specifying a date of the form YYYY-MM-DD
or a day name: yesterday, today, or sunday .. saturday and [project regexes]
is a list of strings of regular expressions matching project names.\n",
        'help:post_help' =>
            "\nwhere [date] is an optional string specifying a date of the form YYYY-MM-DD
or a day name: yesterday, today, or sunday .. saturday and [project regexes]
is a list of strings of regular expressions matching project names.\n",
    };
    my $app = Timelog::CmdDispatch->new( \%commands, $options );

    # Handle default command if none specified
    @ARGV = split / /, $app->get_config()->{'defcmd'} unless @ARGV;

    $app->run( @ARGV );

    return;
}

# Command handlers

sub init_timelog
{
    my ($app, $dir) = @_;
    require File::Path;
    my $config = $app->get_config();
    $dir //= $config->{'dir'};
    $dir = _normalize_path( $dir );
    File::Path::mkpath( $dir ) unless -d $dir;
    unless( -f $config_file )
    {
        open my $fh, '>', $config_file;
        # don't supply the editor value, default to the environment
        print {$fh} <<"EOF";
dir=$dir
defcmd=$config->{defcmd}

[alias]
EOF
    }
    print "timelog initialized\n";
    return;
}

sub log_event
{
    my $app    = shift;
    my $task = "@_";
    if( App::TimelogTxt::Utils::is_stop_cmd( $task ) || App::TimelogTxt::Utils::has_project( $task ) )
    {
        open my $fh, '>>', $app->_logfile;
        my $event = App::TimelogTxt::Event->new( $task, time );
        print {$fh} $event->to_string, "\n";
    }
    else
    {
        die "Event has no project.\n";
    }
    return;
}

sub edit_logfile
{
    my ( $app ) = @_;
    system $app->get_config()->{'editor'}, $app->_logfile;
    return;
}

sub list_events
{
    my ( $app, $day ) = @_;
    my $stamp = App::TimelogTxt::Utils::day_stamp( $day );

    _each_logline( $app, sub { print if 0 == index $_, $stamp; } );
    return;
}

sub list_projects
{
    my ( $app ) = @_;
    my %projects;
    _each_logline(
        $app,
        sub {
            my ( @projs ) = m/\+(\S+)/g;
            @projects{@projs} = ( 1 ) x @projs if @projs;
        }
    );
    print "$_\n" foreach sort keys %projects;
    return;
}

sub daily_report
{
    my ( $app, @filters ) = @_;

    my $summaries = extract_day_tasks( $app, @filters );

    foreach my $summary ( @{$summaries} )
    {
        $summary->print_day_detail( $app->_out_fh );
    }
    return;
}

sub daily_summary
{
    my ( $app, @filters ) = @_;

    my $summaries = extract_day_tasks( $app, @filters );

    foreach my $summary ( @{$summaries} )
    {
        $summary->print_day_summary( $app->_out_fh );
    }
    return;
}

sub report_hours
{
    my ( $app, @filters ) = @_;

    my $summaries = extract_day_tasks( $app, @filters );

    foreach my $summary ( @{$summaries} )
    {
        $summary->print_hours( $app->_out_fh );
    }
    return;
}

sub start_event
{
    my ( $app, @event ) = @_;
    log_event( $app, @event );
    return;
}

sub push_event
{
    my ( $app, @event ) = @_;
    my $stack = _stack( $app );
    $stack->push( _get_last_event( $app ) );
    log_event( $app, @event );
    return;
}

sub pop_event
{
    my ( $app ) = @_;
    return unless -f $app->_stackfile;
    my $stack = _stack( $app );
    my $event = $stack->pop;
    die "Event stack is empty.\n" unless $event;
    log_event( $app, $event );
    return;
}

sub drop_event
{
    my ( $app, $arg ) = @_;
    return unless -f $app->_stackfile;
    my $stack = _stack( $app );
    $stack->drop( $arg );
    return;
}

sub list_stack
{
    my ($app) = @_;
    return unless -f $app->_stackfile;
    my $stack = _stack( $app );
    $stack->list( $app->_out_fh );
    return;
}

sub current_event
{
    my ($app) = @_;
    my $fh = $app->_out_fh;

    my $event = _get_last_full_event( $app );
    if( $event->is_stop )
    {
        print {$fh} "Not in event.\n";
        return;
    }

    # Use day summary object to get duration and to report.
    my $summary = App::TimelogTxt::Day->new( $event->stamp );
    $summary->start_task( $event );
    $summary->update_dur( $event, time );

    print {$fh} $event->to_string, "\nDuration: ";
    $summary->print_duration( $fh );

    return;
}

# Extract the daily events from the timelog.txt file and generate the list of Day
# objects that encapsulates them.

sub extract_day_tasks
{
    my ( $app, @args ) = @_;

    my ($stamp, $estamp, $pstamp, @filters) = _process_extraction_args( @args );
    my ( $summary, $last, @summaries );
    my $prev_stamp = '';

    open my $fh, '<', $app->_logfile;
    my $file = App::TimelogTxt::File->new( $fh, $pstamp, $estamp );

    while( defined( my $line = $file->readline ) )
    {
        my $event;
        eval {
            $event = App::TimelogTxt::Event->new_from_line( $line );
        } or next;
        if( $prev_stamp ne $event->stamp )
        {
            my $new_stamp = $event->stamp;
            my $new_summary = App::TimelogTxt::Day->new( $new_stamp );
            if( $summary and !$summary->is_complete() )
            {
                $summary->close_day( $last );
                # Need to build a new last item beginning at midnight for the
                # Previous event.
                my $start = $summary->day_end()+1;
                $last = App::TimelogTxt::Event->new( $last->task(), $start );
                $new_summary->start_task( $last );
            }
            $summary = $new_summary;
            push @summaries, $summary;
            $prev_stamp = $new_stamp;
        }
        $summary->update_dur( $last, $event->epoch );
        $summary->start_task( $event );
        $last = ($event->is_stop() ? undef : $event );
    }

    # If the first summary is the day before we were supposed to report,
    #   drop it.
    shift @summaries if @summaries && $summaries[0]->date_stamp() eq $pstamp;

    return [] unless $summary;
    my $end_time;
    if( $summary->is_complete() )
    {
        $summary->update_dur( $last, $end_time );
    }
    else
    {
        my $datestamp = $summary->date_stamp() || $stamp;
        if( App::TimelogTxt::Utils::is_today( $datestamp ) )
        {
            $end_time = time;
            $summary->update_dur( $last, $end_time );
        }
        else
        {
            $summary->close_day( $last );
            $end_time = App::TimelogTxt::Utils::stamp_to_localtime( $datestamp );
        }
    }

    return if $summary->is_empty;

    return _filter_summaries( \@filters, \@summaries );
}

sub _filter_summaries
{
    my ( $filters, $summaries ) = @_;

    return $summaries unless @{$filters};

    my $filter = join( '|', map { "(?:$_)" } @{$filters} );
    my $filter_re = qr/$filter/;
    return [
        grep { $_->has_tasks }
        map { $_->day_filtered_by_project( $filter_re ) }
        @{$summaries}
    ];
}

sub _process_extraction_args
{
    my ($day, @args) = @_;

    # First argument is always the day
    my $stamp = App::TimelogTxt::Utils::day_stamp( $day );
    die "No day provided.\n" unless defined $stamp;
    my $eday = shift @args;
    my $estamp = App::TimelogTxt::Utils::day_end( $eday ? App::TimelogTxt::Utils::day_stamp( $eday ) : $stamp );
    if( !defined $estamp )
    {
        $estamp = App::TimelogTxt::Utils::day_end( $stamp );
        unshift @args, $eday if $eday;
    }

    # I need to start one day before to deal with the possibility that first
    #   task was held over midnight.
    my $pstamp = App::TimelogTxt::Utils::prev_stamp( $stamp );

    return ($stamp, $estamp, $pstamp, @args);
}

# Utility functions

# Find user's home directory
sub _home
{
    return $ENV{HOME} if defined $ENV{HOME};
    if( $^O eq 'MSWin32' )
    {
        return "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" if defined $ENV{HOMEPATH};
        return $ENV{USERPROFILE} if defined $ENV{USERPROFILE};
    }
    return '/';
}

# Resolve ~ notation and convert to an absolute path.
sub _normalize_path
{
    my ($path) = @_;

    my $home = _home();
    $path =~ s/~/$home/;

    return $path;
}

sub _each_logline
{
    my ( $app, $code ) = @_;
    open my $fh, '<', $app->_logfile;
    $code->() while( <$fh> );
    return;
}

sub _stack
{
    my ($app) = @_;
    require App::TimelogTxt::Stack;
    return App::TimelogTxt::Stack->new( $app->_stackfile );
}

sub _get_last_full_event
{
    my ( $app ) = @_;
    my $event_line;
    _each_logline( $app, sub { $event_line = $_; } );
    return App::TimelogTxt::Event->new_from_line( $event_line );
}

sub _get_last_event
{
    my $event = _get_last_full_event( @_ );

    return $event->task;
}

1;
__END__

=head1 NAME

App::TimelogTxt - Commandline tracking of time for tasks and projects.

=head1 VERSION

This document describes App::TimelogTxt version 0.22

=head1 SYNOPSIS

    use App::TimelogTxt;
    App::TimelogTxt::run();

=head1 DESCRIPTION

This module encapsulates all of the functionality of the timelog application.
This module delegates much of the heavy lifting to other modules. It does
handle the UI work and the configuration file.

=head1 INTERFACE

At the moment, the only real interface to this file is the C<run> command.

In the methods below, the C<$app> parameter is an object of the class
C<Timelog::CmdDispatch>. This is a subclass of L<App::CmdDispatch> that adds
support needed for some of our configuration.

=head2 run()

This is the main routine of the module. It creates the command parser object,
parses the command line and dispatches the work to the correct function.

=head2 init_timelog( $app, $dir )

Implementation of the 'init' command.

This routine creates the log directory if the directory doesn't exist. The
optional C<$dir> argument is the path to this directory. If C<$dir> is not
provided, use the default F<~/timelog> directory. If the configuration file
doesn't exist, it creates that as well using the currently known values.

=head2 log_event( $app, @event );

Add the specified event to the end of timelog.txt

=head2 edit_logfile( $app )

Implementation of the 'edit' command.

Open the F<timelog.txt> file in the configured editor.

=head2 list_events( $app, $day )

Implementation of the 'ls' command.

Display the events for the supplied C<$day>. If no C<$day> is supplied, use
today.

=head2 list_projects( $app )

Implementation of the 'lsproj' command.

Extract all C<+project> entries from the events in F<timelog.txt> and display
a sorted list, one per line.

=head2 daily_report( $app, $day, $end_day )

Implementation of the 'report' command.

Display a report of all events for the given days on STDOUT. If C<$end_day> is
not supplied, only display the report for C<$day>. If C<$day> is not supplied,
default to today.

=head2 daily_summary( $app, $day, $end_day )

Implementation of the  'summary' command.

Display a report of all project times for the given days on STDOUT. If
C<$end_day> is not supplied, only display the report for C<$day>. If C<$day> is
not supplied, default to today.

=head2 report_hours( $app, $day, $end_day )

Implementation of the 'hours' command.

Display a report of the hours the given days on STDOUT. If C<$end_day> is not
supplied, only display the report for C<$day>. If C<$day> is not supplied,
default to today.

=head2 extract_day_tasks( $app, $day, $end_day )

Read the timelog.txt file and create an array of L<App::TimelogTxt::Day>
objects that contain the information for the days from C<$day> to C<$end_day>.

=head2 start_event( $app, @event )

Implementation of the 'start' command.

Add an event to the F<timelog.txt> file.

=head2 push_event( $app, @event )

Implementation of the 'push' command.

Copy the current item from the timelog file to the stack and add the supplied
event to the timelog file.

=head2 pop_event( $app )

Implementation of the 'pop' command.

Remove the most recent event from the stack and add it as a new event to the
timelog file.

=head2 drop_event( $app, $arg )

Implementation of the 'drop' command.

Remove one or more items from the stack. If C<$arg> is not supplied, remove one
item. If C<$arg> is a positive number, remove that many items from the stack.
If C<$arg> is C<'all'>, clear the stack file.

=head2 list_stack( $app )

Implementation of the 'lstk' command.

Print the current stack on STDOUT.

=head2 current_event( $app )

Implementation of the 'curr' command.

Print the most recennt timelog event on STDOUT along with the duration since
the start of the event. If not in an event, report that.

=head1 CONFIGURATION AND ENVIRONMENT

App::TimelogTxt requires no environment variables, but may use VISUAL or
EDITOR if an editor is not configured in F<~/.timelogrc>.

App::TimelogTxt uses the file F<~/.timelogrc> for configuration information.

The configuration file is expected to contain data in two major parts:

=head2 General Configuration

The first section defined general configuration information in a key=value
format. The recognized keys are:

=over 4

=item editor

The editor to use when opening the timelog file with the C<edit> command.
If not specified, it will use the value of either the C<VISUAL> or C<EDITOR>
environment variables. If non are found, it will default to C<vim>.

=item dir

The directory in which to find the timelog data files. Defaults to the
C<timelog> directory in the user's home directory.

=item defcmd

The default command to by used if none is supplied to timelog. By default,
this is the 'B<stop>' command.

=back

=head2 Command Aliases

The config file may also contain an '[alias]' section that defines command
aliases. Each alias is defined as a C<shortname=expanded string>

For example, if you regularly need to make entries for reading email and
triaging bug reports you might want the following in your configuration.

  [alias]
    email = start +Misc @Email
    triage = start +BugTracker @Triage

=head1 DEPENDENCIES

App::CmdDispatch, Getopt::Long, File::Path, autodie.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-timelogtxt@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< <gwadej@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< <gwadej@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
