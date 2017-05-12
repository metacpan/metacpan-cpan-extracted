
package App::Textcast ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

use English qw( -no_match_vars ) ;
$OUTPUT_AUTOFLUSH++;

my $get_terminal_size ;

BEGIN
{
if($OSNAME ne 'MSWin32')
	{
	eval 'use Term::Size;' ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
	croak "Error: $EVAL_ERROR" if $EVAL_ERROR;
	
	$get_terminal_size = eval ' sub { Term::Size::chars *STDOUT{IO} } ' ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
	croak "Error: $EVAL_ERROR" if $EVAL_ERROR ;
	}
else
	{
	eval 'use Win32::Console;' ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
	croak "Error: $EVAL_ERROR" if $EVAL_ERROR ;
	
	my $WIN32_CONSOLE = new Win32::Console;
	$get_terminal_size = eval { sub { $WIN32_CONSOLE->Size() } } ;
	croak "Error: $EVAL_ERROR" if $EVAL_ERROR ;
	}
}

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(record_textcast play_textcast) ],
	groups  => 
		{
		all  => [ qw() ],
		},
	};
 
use vars qw ($VERSION);
$VERSION = '0.06';
}

#-------------------------------------------------------------------------------

use Readonly ;

#~ http://www.termsys.demon.co.uk/vtansi.htm
Readonly my $CLEAR => "\e[2J" ; 
Readonly my $HOME => "\e[1;1H" ;
Readonly my $CLEAR_LINE => "\e[2K" ;
Readonly my $SAVE_CURSOR_POSITION => "\e7"  ; 
Readonly my $RESTORE_CURSOR_POSITION => "\e8"  ; 
Readonly my $HIDE_CURSOR => "\e[?25l" ;
Readonly my $SHOW_CURSOR => "\e[?25h" ;

Readonly my $EMPTY_STRING => q{} ;

use IO::Handle;
use POSIX ':sys_wait_h';
use IO::Pty;

use Term::VT102;
use File::Slurp ;
use Time::HiRes qw(gettimeofday tv_interval usleep);

#-------------------------------------------------------------------------------

=head1 NAME

App::Textcast - Light weight text casting

=head1 SYNOPSIS

  use App::Textcast qw(record_textcast play_textcast) ;
  
  record_textcast(COMMAND => 'bash') ;
  play_textcast(TEXTCAST_DIRECTORY => $input_directory) ;
  

=head1 DESCRIPTION

What's a textcast? 

It's a screencast of a terminal session. The idea is to record the terminal session and replay
it in another terminal without loosing resolution, as screencasts do, nor using much disk space due to 
conversion from text to video. The terminal session can run a shell or any other program.

Why textcasts? 

=over 2

=item * Size,	I did a screen cast of a completion script, the size was 1.5 MB and
	it didn't look as good as the terminal. The same textcast was 10 KB (yes,
	10 Kilo Bytes) and it looked good. 
	

=item *  It is not possible to make a screencast of a real terminal, maybe via
	vnc but that's already too complicated

=item * Documentation. I believe it is sometimes better to show "live" documentation
	than static text. I am planning to write a module that plays a textcast
	embedded in ones terminal. The text cast being controlled by the application
	that displays help. I also believe that it could be used as a complement
	to showing static logs or screenshots; an example is when someone describe
	a problem on IRC. Seeing what is being done is sometimes very helpful.

=item * Editing.
	possibility to add message
	possibility to add sound
	possibility to extend the time an image or a range of images is displayed
	concatenate text casts (and their indexes)
	remove portions of a text cast
	name part of the text cast (shows in the index)

=back

=head1 DOCUMENTATION

See L<record_textcast> and L<play_textcast> subbroutines.

=head1 SCRIPTS

Two commands, B<record_textcast> and B<play_textcast>, are installed on your computer when you install this module. Use
them to record and replay your text casts.

=head2 Output

The textcast is a serie of files recorded in a directory. Tar/gzip the files before you send them. the compression ratio averages 95%.


=head1 SUBROUTINES/METHODS

=cut

#---------------------------------------------------------------------------------------------------------
# recording
#---------------------------------------------------------------------------------------------------------

sub record_textcast
{

=head2 record_textcast( %named_arguments )

Records the terminal output of a command. The output is stored as a set of files in a directory. The
directory is later passed as argument to L<play_textcast> for display.

  use App::Textcast 'record_textcast' ;
  
  record_textcast
	(
	COMMAND => 'bash',
	OUTPUT_DIRECTORY => shift @ARGV,
	COMPRESS => $compress,
	COLUMNS => $columns,
	ROWS => $rows,
	) ;

I<Arguments>

The arguments are named, order is not important.

=over 2 

=item * COMMAND => $string - the name of the command to tun in a terminal. You most probably wan to run
I<bash> or I<sh>

=item * OUTPUT_DIRECTORY => $directory_path - Optional - the path to the directory where the textcast is to be 
recorded. This subroutine will create a directory if this option is not set. if this option is set, the directory 
should not exist.

=item * COMPRESS => $boolean - Not implemented

=item * COLUMNS => $integer - Optional - Number of columns in the terminal. The current terminal columns
number is used if this argument is not set.

=item * ROWS => $integer - Optional - Number of rows in the terminal. The current terminal rows number is
used if this argument is not set.

=back

I<Returns> - Nothing

I<Exceptions>

=over 2 

=item * See check_output_directory

=item * see create_vt102_sub_process

=item * disk full error

=back

See I<scripts/record_textcast>.

=cut

my (%arguments) = @_;

my ($terminal_columns, $terminal_rows) = $get_terminal_size->() ;

my $output_directory = check_output_directory($arguments{OUTPUT_DIRECTORY}) ;
my $vt_process = create_vt102_sub_process
				(
				$arguments{COMMAND},
				$arguments{COLUMNS} || $terminal_columns,
				$arguments{ROWS}  || $terminal_rows, 
				) ;

print $CLEAR ;
	
my $previous_time = my $start_time = [gettimeofday]  ;

my ($screenshot_index, $sub_process_ended) = (0, 0) ;

while (not $sub_process_ended) 
	{
	($sub_process_ended, my $screen_diff, my $cursor_x, my $cursor_y) = check_sub_process_output($vt_process) ;
	
	my $now = [gettimeofday] ;
	my $elapsed = tv_interval($previous_time, $now);
	$previous_time = $now ;
	
	my $screenshot_file_name = "$output_directory/$screenshot_index" ;
	
	write_file($screenshot_file_name, $screen_diff) ;
			
	my ($terminal_columns, $terminal_rows) = $get_terminal_size->() ;
		
	append_file 
		(
		"$output_directory/index",
		
		'{'
		. "file => $screenshot_index, "
		. sprintf('delay => %0.3f, ', $elapsed)
		. "cursor_x => $cursor_x, "
		. "cursor_y => $cursor_y, "
		. 'size => ' . length($screen_diff) . ', '
		. "terminal_rows => $terminal_rows, "
		. "terminal_columns => $terminal_columns, "
		. "},\n" 
		) ;
			
	$screenshot_index++ ;
	}

my $record_time = tv_interval($start_time, [gettimeofday]);
printf("record_textcast: $screenshot_index frames in %.02f seconds. Textcast is in '$output_directory'.\r\n", $record_time) ;

close_vt102_sub_process($vt_process) ;

return ;
}

#---------------------------------------------------------------------------------------------------------

sub check_output_directory
{

=head2 [p] check_output_directory( $output_directory)

Check that the given output directory does B<not> exist. If B<$output_directory> is not defined, a directory
name is generated.

I<Arguments>

=over 2 

=item * $output_directory - The name of the directory where the textcast is recorded

=back

I<Returns> - The directory where the textcast is recorded.

I<Exceptions>

=over 2 

=item * Textcast directory already exists

=item * Path too long - length must be under 256 characters.

=item * Invalid path - Path can only contain alphanumerics and path separator.

=back

=cut

my ($directory) = @_ ;

unless(defined $directory)
	{
	my $now_string = localtime;  # e.g., "Thu Oct 13 04:54:34 1994"
	$now_string=~ s/[^[:digit:][:alpha:]]/_/sxmg ;
	
	$directory = "textcast_recorded_on_$now_string" ;
	}
	
if(-e $directory)
	{
	local $ERRNO = 1 ;
	croak "Error: Textcast directory '$directory' already exists!\n" ;
	}
else
	{
	#todo: get the max path on this platform
	local $ERRNO = 2 ;
	
	Readonly my $MAX_PATH_LENGTH => 256 ;
	croak 'Error: Path too long' if length($directory) > $MAX_PATH_LENGTH ;

	if($directory =~ /([[:alnum:]\/_-]+)/sxm)
		{
		$directory = $1 ;
		}
	else
		{
		Readonly my $ERRNO_INVALID_PATH => 3 ;
		local $ERRNO = $ERRNO_INVALID_PATH  ;
		croak 'Error: Invalid path! Path can only contain alphanumerics and path separator.'
		}
		
	mkdir $directory or croak "Can't create directory '$directory'! $!\n" ;
	}

return $directory ;
}

#---------------------------------------------------------------------------------------------------------
# Playing
#---------------------------------------------------------------------------------------------------------

sub play_textcast
{

=head2 play_textcast( %named_arguments)

Loads, checks, and initiates the textcast replay. Displays information after the textcast replay.

  use App::Textcast 'play_textcast' ;
  
  play_textcast
	(
	TEXTCAST_DIRECTORY => $input_directory,
	OVERLAY_DIRECTORY => $overlay_directory,
	DISPLAY_STATUS => $display_status,
	START_PAUSED => $start_paused,
	) ; 

I<Arguments>

=over 2 

=item * TEXTCAST_DIRECTORY - String - directory containing the textcast

=item * OVERLAY_DIRECTORY -  not implemented

=item * DISPLAY_STATUS - Boolean - 

=item * START_PAUSED -  not implemented

=back

I<Returns> - Nothing

I<Exceptions>

=over 2 

=item * Terminal too small

=item * interrupted by user

=item * load_index

=back

=cut

my (%arguments) = @_ ;

my $input_directory = $arguments{TEXTCAST_DIRECTORY} or croak 'Error: Expected textcast location!' ;
my $display_status =  $arguments{DISPLAY_STATUS} || 0 ;

local $SIG{INT} = sub 
			{
			print "\n" ;
			local $ERRNO = 1  ;
			croak "Caught interrupt signal!\n" ; 
			} ;

my $screenshot_information = load_index($input_directory) ;

my ($max_rows, $max_columns) = (-1, -1) ; 

for my $screenshot_data (@{$screenshot_information})
	{
	#~ print "$screenshot_data->{terminal_rows}, $screenshot_data->{terminal_columns}  \n" ;
	
	$max_rows = $screenshot_data->{terminal_rows} if $screenshot_data->{terminal_rows} > $max_rows ;
	$max_columns = $screenshot_data->{terminal_columns} if $screenshot_data->{terminal_columns} > $max_columns ;
	}

my ($terminal_columns, $terminal_rows) = $get_terminal_size->() ;

my ($status_row,$status_column) = (1, 1) ;

if($max_rows + $display_status > $terminal_rows || $max_columns > $terminal_columns)
	{
	Readonly my $ERRNO_TERMINAL_TOO_SMALL => 3 ;
	local $ERRNO = $ERRNO_TERMINAL_TOO_SMALL  ;
	croak "Error: Terminal too small [$terminal_columns, $terminal_rows] need at least [$max_columns, $max_rows]!\n"  ;
	}
else
	{
	$status_row = $max_rows + 1 ;
	}
	
#~ print DumpTree \@screenshot_information ;

print $CLEAR, $HOME ;

my ($total_play_time, $played_frames, $skipped_frames)
	= display_text_cast_data
		(
		$input_directory,
		$screenshot_information,
		{
			DISPLAY => $display_status,
			ROW => $status_row,
			COLUMN => $status_column,
		}
		) ;
	
print_play_information($total_play_time, $played_frames, $skipped_frames) ;

return ;
}

#---------------------------------------------------------------------------------------------------------

sub display_text_cast_data
{

=head2 [p] display_text_cast_data($input_directory, \@screenshot_information, \%display_status )

Plays a screencast.

I<Arguments>

=over 2 

=item * $input_directory - String - directory containing the textcast

=item * \@screenshot_information - see L<load_index>

=item * \%display_status - 

=over 2 

=item DISPLAY - Boolean - status is displayed during the replay if this is set

=item ROW - row where the status is displayed

=item COLUMNS - column where the status is displayed

=back 

=back

I<Returns> - A list containing

=over 2 

=item * $total_play_time

=item * $played_frames

=item * \@skipped_frames

=back

I<Exceptions> - None

=cut

my ($input_directory, $screenshot_information, $display_status,) = @_ ;

my $total_frames = scalar(@{$screenshot_information}) ;

my ($total_play_time, $played_frames, @skipped_frames) ;

my $frame_display_time = 0 ;

for my $file_information (@{$screenshot_information})
	{
	my $file = "$input_directory/$file_information->{file}" ;
	$total_play_time += $file_information->{delay} ;
	
	if(-e $file)
		{
		$played_frames++ ;
		
		status
			(
			sprintf( "F: $played_frames/$total_frames [%0.2f]", $file_information->{delay}),
			$display_status->{ROW},
			$display_status->{COLUMN},
			) if $display_status->{DISPLAY} ;
		
		my $sleep_time = $file_information->{delay} - $frame_display_time ;
		
		# split sleep time in smaller chunks if we want to handle the user input
		Readonly my $ONE_MILLION => 1_000_000 ;
		
		usleep $sleep_time * $ONE_MILLION if($sleep_time > 0) ;
		
		$frame_display_time = [gettimeofday]  ;
		
		print #$SHOW_CURSOR,
			read_file($file),
			position_cursor($file_information->{cursor_y}, $file_information->{cursor_x}) ;
		
		$frame_display_time = tv_interval($frame_display_time , [gettimeofday]) ;
		}
	else
		{
		carp "Error: Can't find '$file'! Skipping.\n" ;
		push @skipped_frames, $file ;
		}
	}

return ($total_play_time, $played_frames, \@skipped_frames) ;
}

#---------------------------------------------------------------------------------------------------------

sub print_play_information
{

=head2 [p] print_play_information($total_play_time, $played_frames, \@skipped_frames)

Displays information about the textcast replay.

  print_play_information
	(
	$total_play_time,
	$total_frames,
	$played_frames,
	\@skipped_frames,
	) ;

I<Arguments>

=over 2 

=item * $total_play_time - Float - play time in seconds

=item * $played_frames - Integer - number of framed played, maybe less than $total_frames

=item * \@skipped_frames - Integer - number of frames skipped because they couldn't be found

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($total_play_time, $played_frames, $skipped_frames) = @_ ;

my $play_time = sprintf('%0.2f', $total_play_time) ;

print "play_textcast: $played_frames frames played in $play_time seconds.\n" ;

if(@{$skipped_frames})
	{
	print "Skipped:\n\t" . join("\n\t", @{$skipped_frames}) . "\n" ;
	}
	
return ;
}

#---------------------------------------------------------------------------------------------------------

sub status
{

=head2 [p] status($status, $status_row, $status_column)

Displays a status on the status line.

I<Arguments>

=over 2 

=item * $status - String to be displayed on the terminal

=item * $status_row - Integer - row position for the status

=item * $status_column - Integer - column position for the status

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($status, $status_row, $status_column) = @_ ;

print $SAVE_CURSOR_POSITION, 
	position_cursor($status_row, $status_column),
	$CLEAR_LINE,
	$status,
	$RESTORE_CURSOR_POSITION ;

return ;
}

#---------------------------------------------------------------------------------------------------------

sub position_cursor
{

=head2 [p] position_cursor($row, $column)

Create an ANSI command to position the cursor on the terminal.

I<Arguments>

=over 2 

=item * $row - Integer - row position for the status

=item * $column - Integer - column position for the status

=back

I<Returns> - A string containing the ANSI command.

I<Exceptions> - None

See C<xxx>.

=cut

my ($row, $column) = @_ ;

return "\e[${row};${column}H" ;
}

#---------------------------------------------------------------------------------------------------------

sub load_index
{

=head2 [p] load_index($input_directory)

Loads the screencast meta-data.

I<Arguments>

=over 2 

=item * $input_directory - The directory containing the textcast

=back

I<Returns> - The screencast meta-data, see the index file for format information.

I<Exceptions>

=over 2

=item * Index not found

=item * Invalid data in index

=back

=cut

my ($input_directory) = @_ ;

my @screenshot_information ;

if(-e "$input_directory/index")
	{
	print "Parsing index ...\n" ;
	my @entries = read_file("$input_directory/index") ;
	
	my $line = 0 ;
	
	my $regex = '{file => 0, delay => 0.0, cursor_x => 1, cursor_y => 1, size => 1, terminal_rows => 1, terminal_columns => 1, },' ;
	$regex =~ s/^{/^{/sxm ;
	$regex =~ s/([^[:digit:]]+)$/$1\$/sxmg ;
	$regex =~ s/[[:digit:]]+/[[:digit:]]+/sxmg ;
	
	my @errors ;
	
	for my $entry (@entries)
		{
		unless($entry =~ $regex)
			{
			push @errors, "\tInvalid index entry at line $line!\n" ;
			}
			
		$line++ ;
		}
	
	if(@errors)
		{
		local $ERRNO = 2 ;
		croak "Error: Invalid index!\n@errors" ;
		}
	
	@screenshot_information = eval "@entries"  ## no critic (BuiltinFunctions::ProhibitStringyEval)
		or croak "Error: Couldn't parse index file! $@ $!\n" ;
	}
else
	{
	local $ERRNO = 2 ;
	croak "Error: No index found! $!\n"  ;
	}
	
return \@screenshot_information ;
}

#---------------------------------------------------------------------------------------------------------
# VT102
# Everything below is based on the Term::VT102 example
# Logs all terminal output to STDERR if STDERR is redirected to a file.
#---------------------------------------------------------------------------------------------------------

sub create_vt102_sub_process
{

=head2 [p] create_vt102_sub_process($shell_command, $columns, $rows)


I<Arguments>

=over 2 

=item * $shell_command, $columns, $rows - 

=back

I<Returns> - a vt_process handle

I<Exceptions>

=cut

my ($shell_command, $columns, $rows) = @_ ;

# Create a pty for the command to run.
my $pty = new IO::Pty;
$pty->autoflush();

croak 'Error: Could not assign a pty' if (not defined $pty->ttyname()) ;

# Create the terminal object.
my ($vt, $terminal_change_buffer) = create_vt102_terminal($pty, $columns, $rows) ;

# Run the command in a child process.
my $pid = create_child_process($shell_command, $pty, $vt) ;

# IO::Handle for standard input - unbuffered.
my $iot = new IO::Handle;
$iot->fdopen (fileno(STDIN), 'r');

return
	{
	PTY => $pty,
	VT => $vt,
	TERMINAL_CHANGE_BUFFER => $terminal_change_buffer, 
	IOT => $iot,
	PREVXY => $EMPTY_STRING,
	
	PID => $pid,
	DIED => 0,
	} ;
}

#---------------------------------------------------------------------------------------------------------

sub close_vt102_sub_process
{

=head2 [p] close_vt102_sub_process( $vt_process)

I<Arguments>

=over 2 

=item * $vt_process -  vt_process handle created by L<create_vt102_sub_process>

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($vt_process) = @_ ;
$vt_process->{PTY}->close;

# Reset the terminal parameters.
system 'stty sane';

return ;
}

#---------------------------------------------------------------------------------------------------------

sub create_vt102_terminal
{

=head2 [p] create_vt102_terminal($pty, $columns, $rows)

I<Arguments>

=over 2 

=item $pty, $columns, $rows - 

=back

I<Returns> - $vt, $terminal_change_buffer 

I<Exceptions> - None

=cut

my ($pty, $columns, $rows) = @_ ;

my $terminal_change_buffer = {};
my $vt = Term::VT102->new (cols => $columns, rows => $rows,);

$vt->option_set ('LFTOCRLF', 1); # Convert linefeeds to linefeed + carriage return.
$vt->option_set ('LINEWRAP', 1); # Make sure line wrapping is switched on.

# Set up the callback for OUTPUT; this callback function simply sends
# whatever the Term::VT102 module wants to send back to the terminal and
# sends it to the child process - see its definition below.
$vt->callback_set ('OUTPUT', \&vt_output, $pty);

# Set up a callback for row changes, so we can process updates and display
# them without having to redraw the whole screen every time. We catch CLEAR,
# SCROLL_UP, and SCROLL_DOWN with another function that triggers a
# whole-screen repaint. You could process SCROLL_UP and SCROLL_DOWN more
# elegantly, but this is just an example.
$vt->callback_set ('ROWCHANGE', \&vt_rowchange, $terminal_change_buffer );
$vt->callback_set ('CLEAR', \&vt_changeall, $terminal_change_buffer );
$vt->callback_set ('SCROLL_UP', \&vt_changeall, $terminal_change_buffer );
$vt->callback_set ('SCROLL_DOWN', \&vt_changeall, $terminal_change_buffer );

# Set stdin's terminal to raw mode so we can pass all keypresses straight
# through immediately.
system 'stty raw -echo';

return ($vt, $terminal_change_buffer ) ;
}

#---------------------------------------------------------------------------------------------------------

sub vt_output 
{

=head2 [p] vt_output($vtobject, $type, $arg1, $arg2, $private)

Callback for OUTPUT events - for Term::VT102.

I<Arguments>

=over 2 

=item $vtobject, $type, $arg1, $arg2, $private - 

=back

I<Returns> - Nothing

I<Exceptions> - Nothing

See L<Term::VT102>.

=cut

my ($vtobject, $type, $arg1, $arg2, $private) = @_;

if ($type eq 'OUTPUT') 
	{
	$private->syswrite ($arg1, length $arg1);
	}

return ;
}

#---------------------------------------------------------------------------------------------------------

sub vt_rowchange 
{

=head2 [p] vt_rowchange($vtobject, $type, $arg1, $arg2, $private)

Callback for ROWCHANGE events. This just sets a time value for the changed
row using the private data as a hash reference - the time represents the
earliest that row was changed since the last screen update.

I<Arguments>

=over 2 

=item $vtobject, $type, $arg1, $arg2, $private - 

=back

I<Returns> - Nothing

I<Exceptions> - Nothing

See L<Term::VT102>.

=cut

my ($vtobject, $type, $arg1, $arg2, $private) = @_;
$private->{$arg1} = time if (not exists $private->{$arg1});

return ;
}

#---------------------------------------------------------------------------------------------------------

sub vt_changeall 
{

=head2 [p] vt_changeall($vtobject, $type, $arg1, $arg2, $private)

Callback to trigger a full-screen repaint.

I<Arguments>

=over 2 

=item $vtobject, $type, $arg1, $arg2, $private - 

=back

I<Returns> - Nothing

I<Exceptions> - None

See L<Term::VT102>.

=cut

my ($vtobject, $type, $arg1, $arg2, $private) = @_;
for my $row (1 .. $vtobject->rows) 
	{
	$private->{$row} = 0;
	}
	
return ;
}

#---------------------------------------------------------------------------------------------------------

sub create_child_process
{

=head2 [p] create_child_process($shell_command, $pty, $vt)

Creqtes a child process to run a command in.

I<Arguments>

=over 2 

=item $shell_command, $pty, $vt - 

=back

I<Returns> - Nothing

I<Exceptions> - Can not fork to run sub process

See C<xxx>.

=cut

my ($shell_command, $pty, $vt) = @_ ;
my $pid = fork;

croak  "Error: Can not fork to run sub process, $!" if (not defined $pid)  ;

if ($pid == 0) 
	{
	# never comes back
	run_child_process($shell_command, $pty, $vt) ; 
	}

return $pid ;
}

#---------------------------------------------------------------------------------------------------------

sub run_child_process
{

=head2 [p] run_child_process($command, $pty, $vt)

I<Arguments>

=over 2 

=item $command, $pty, $vt - 

=back

I<Returns> - Nothing

I<Exceptions> - Error redirecting streams

=cut

my ($command, $pty, $vt) = @_ ;

# Child process - set up stdin/out/err and run the command.
# Become process group leader.
if (not POSIX::setsid ()) 
	{
	carp "Couldn't perform setsid: $!";
	}

# Get details of the slave side of the pty.
my $tty = $pty->slave ();
my $tty_name = $tty->ttyname();

# Linux specific - commented out, we'll just use stty below.
#
#	# Set the window size - this may only work on Linux.
#	#
#	my $winsize = pack ('SSSS', $vt->rows, $vt->cols, 0, 0);
#	ioctl ($tty, &IO::Tty::Constant::TIOCSWINSZ, $winsize);

# File descriptor shuffling - close the pty master, then close
# stdin/out/err and reopen them to point to the pty slave.
close ($pty);

close (STDIN);
open (STDIN, '<&' . $tty->fileno ()) || croak 'Error: Couldn\'t reopen ' . $tty_name . " for reading: $!";

close (STDOUT);
open (STDOUT, '>&' . $tty->fileno()) || croak 'Error: Couldn\'t reopen ' . $tty_name . " for writing: $!";

close (STDERR);
open (STDERR, '>&' . $tty->fileno()) || croak "Error: Couldn't redirect STDERR: $!";

# Set sane terminal parameters.
system 'stty sane';

# Set the terminal size with stty.
system 'stty rows ' . $vt->rows;
system 'stty cols ' . $vt->cols;

# Finally, run the command, and die if we can't.
exec $command or croak "Error: Cannot exec '$command': $!";
}

#---------------------------------------------------------------------------------------------------------

sub check_sub_process_output
{

=head2 [p] check_sub_process_output( $vt_process)

Check the sub process output.

I<Arguments>

=over 2 

=item * $vt_process - 

=back

I<Returns> - $eof, $screen_data, $cursor_x, $cursor_y

I<Exceptions> - None

=cut

my ($vt_process) = @_;	
my $vt = $vt_process->{VT} ;

my ($eof, $screen_data) ;

my $rin = $EMPTY_STRING ;
vec ($rin, $vt_process->{PTY}->fileno, 1) = 1;
vec ($rin, $vt_process->{IOT}->fileno, 1) = 1;

my ($win, $ein) = ($EMPTY_STRING, $EMPTY_STRING) ;
my($rout, $wout, $eout) ;
select ($rout=$rin, $wout=$win, $eout=$ein, 1);

# Read from the command if there is anything coming in, and
# pass any data on to the Term::VT102 object.
my $cmdbuf = $EMPTY_STRING ;

Readonly my $BUFFER_READ_SIZE => 1024 ;

if (vec($rout, $vt_process->{PTY}->fileno, 1)) 
	{
	my $bytes_read = $vt_process->{PTY}->sysread ($cmdbuf, $BUFFER_READ_SIZE);
	$eof = 1 if ((defined $bytes_read) && ($bytes_read == 0));
	
	if ((defined $bytes_read) && ($bytes_read > 0)) 
		{
		$vt->process ($cmdbuf);
		syswrite STDERR, $cmdbuf if (! -t STDERR);
		}
	}
	
# End processing if we've gone 1 round after command died with no output.
$eof = 1 if ($vt_process->{DIED} && $cmdbuf eq $EMPTY_STRING);

# Do your stuff here - use $vt->row_plaintext() to see what's on various
# rows of the screen, for instance, or before this main loop you could set
# up a ROWCHANGE callback which checks the changed row, or whatever.

# In this example, we just pass standard input to the SSH command, and we
# take the data coming back from SSH and pass it to the Term::VT102 object,
# and then we repeatedly dump the Term::VT102 screen.

# Read key presses from standard input and pass them to the command
# running in the child process.
if (vec ($rout, $vt_process->{IOT}->fileno, 1)) 
	{
	my $stdinbuf = $EMPTY_STRING ;
	my $bytes_read = $vt_process->{IOT}->sysread ($stdinbuf, $BUFFER_READ_SIZE );
	$eof = 1 if ((defined $bytes_read) && ($bytes_read == 0));
	$vt_process->{PTY}->syswrite ($stdinbuf, $bytes_read) if ((defined $bytes_read) && ($bytes_read > 0));
	}

# Dump what Term::VT102 thinks is on the screen. We only output rows
# we know have changed, to avoid generating too much output.
my $didout = 0;
foreach my $row (sort keys %{ $vt_process->{TERMINAL_CHANGE_BUFFER} }) 
	{
	printf "\e[%dH%s\r", $row, $vt->row_sgrtext ($row);
	$screen_data .= sprintf "\e[%dH%s\r", $row, $vt->row_sgrtext ($row);
	
	delete $vt_process->{TERMINAL_CHANGE_BUFFER}{$row};
	$didout ++;
	}
	
if (($didout > 0) || ($vt_process->{PREVXY} ne $EMPTY_STRING . $vt->x . q{,} . $vt->y)) 
	{
	printf "\e[%d;%dH", $vt->y, ($vt->x > $vt->cols ? $vt->cols : $vt->x);
	
	$screen_data .= sprintf "\e[%d;%dH", $vt->y, ($vt->x > $vt->cols ? $vt->cols : $vt->x);
	#todo: shouldn't prevxy be updated here?
	}

# Make sure the child process has not died.
$vt_process->{DIED} = 1 if (waitpid ($vt_process->{PID}, WNOHANG) > 0);

return($eof, $screen_data, $vt->x(), $vt->y()) ;
}

#---------------------------------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NH
	mailto: nadim@cpan.org

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Textcast

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Textcast>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-app-textcast@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/App-Textcast>

=back

=head1 SEE ALSO

screen (1), script(1), aewan, vte(1), evilvte(1).

=cut
