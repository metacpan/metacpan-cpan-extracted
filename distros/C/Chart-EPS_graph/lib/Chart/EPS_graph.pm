# $Source: /usr/pkg/lib/perl5/site_perl/5.8.0/Chart/EPS_graph.pm $
# $Date: 2006-08-19 $

package Chart::EPS_graph;

use strict;
use warnings;
use Carp qw(carp croak);
use Config;
use IPC::Open3;
use English qw(-no_match_vars);
use Chart::EPS_graph::PS;
require File::Find;

our ($VERSION) = '$Revision: 0.01 $' =~ m{ \$Revision: \s+ (\S+) }xm;

my $EMPTY = q{};

# The test module is stand-alone OO and makes own object.
sub full_test {
	my ($ignored, $dir_path) = @_;
	require Chart::EPS_graph::Test;
	return Chart::EPS_graph::Test->full_test($dir_path);
}

# Yack at user about what goes on.
sub verbose {
	ref( my $self = shift ) or croak 'Oops! Method verbose() is instance, not class.';
	print $_[0] if $_[1] <= $self->{verbosity};
	return 'Pthhht! to Perl::Critic';
}

sub version { return $VERSION }

# Create new object.
sub new {
	ref( my $class = shift ) and croak 'Oops! Method new() is class, not instance.';
	my $self = {};
	for (keys %Chart::EPS_graph::PS::ps_defaults){
		$self->{$_} = $Chart::EPS_graph::PS::ps_defaults{$_}
	}
	if ( $_[0] ) { $self->{pg_width}  = shift }
	if ( $_[0] ) { $self->{pg_height} = shift }
	$self->{ps_header}   = $Chart::EPS_graph::PS::ps_header;
	$self->{ps_header}   =~
		s/BoundingBox:.*\n/BoundingBox: 0 0 $self->{pg_width} $self->{pg_height}\n/m;
	$self->{names}       = [];
	$self->{data}        = [];
	$self->{y1}          = [];
	$self->{y2}          = [];
	$self->{shown}       = [];
	$self->{not_shown}   = [];
	$self->{close_gap}   = 0;
	$self->{x_is_zeroth} = 1;
	$self->{x_scale}     = 1;
	$self->{ps_path}     = $EMPTY;
	$self->{verbosity}   = 1; # 0 = Quiet, 1 = Info, 2 = Diagnostic.
	bless $self, $class;
	return $self;
}

# Allow user to change defaults and input data.
sub set {
	ref( my $self = shift ) or croak 'Oops! Method set() is instance, not class.';
	my %user_defs = @_;
	while ( my ($key, $value) = each %user_defs ) {
		if ( exists $self->{$key}) {$self->{$key} = $value }
		else { carp "Oops! Key '$key' non-existant in hash '$self'.\n" }
	}                                             
	return 'Pthhht! to Perl::Critic';
}

# Make custom adjustments to default Prolog defs.
sub ps_defs_insert {
	ref( my $self = shift ) or croak 'Oops! Method ps_defs_insert() is instance, not class.';
	$self->chans_elect();
	my $str = ();

	$str .= "/bg_color ($self->{bg_color}) def \n";
	$str .= "/fg_color ($self->{fg_color}) def \n";
	$str .= '/web_colors [ ';
	for ( @{$self->{web_colors}} ) { $str .= "/$_ " }
	$str .= "] def \n";

	$str .= "/font_name /$self->{font_name} def \n";
	$str .= "/font_size $self->{font_size} def \n";


	# Set not-to-be-shown labels as empty strings.
	$str .= "/label_top ($self->{label_top}) def \n";
	$str .= "/label_y1 ($self->{label_y1}) def \n";
	$str .= "/label_y1_2 ($self->{label_y1_2}) def \n";
	$str .= "/label_y2 ($self->{label_y2}) def \n";
	$str .= "/label_y2_2 ($self->{label_y2_2}) def \n";
	$str .= "/label_x ($self->{label_x}) def \n";
	$str .= "/label_x_2 ($self->{label_x_2}) def \n";

	$str .= '/fake_col_zero_flag ';
	$str .= $self->{x_is_zeroth} ? 'false' : 'true';
	$str .= " def \n";

	$str .= "/fake_col_zero_scale $self->{x_scale} def \n";

	$str .= "/data_sets 1 def \n";

	# This is an ugly, ex-post-facto hack.
	# When chans skipped, patch up the bottom string to cover up remove gap in
	# channel ID's. In short, make legend ID match the gap-free curve ID.
	if ($self->{close_gap}) {
		$self->{shown} = [ @{ $self->{y1} }, @{ $self->{y2} } ];
		my @gap_free = gap_free_skip( $self->{shown}, $self->{not_shown} );
		for my $i ( 0 .. $#gap_free ) {
			$self->{label_x_proc} =~ s/  $self->{shown}->[$i] /  $gap_free[$i] /m;
			$self->{label_x_proc} =~ s/  $self->{shown}->[$i] show_color_id/ $gap_free[$i] show_color_id/m;
		}
	}

	$str .= $self->{label_x_proc}; # List of chans shown

	# An array of data chans embeded in PostScript but whose curves are not to be shown
	# and their colors skipped over by those curves which are shown.
	$str .= '/not_shown [ ';
	$str .= join q{ }, @{$self->{not_shown}} unless $self->{close_gap}; # 'Pthhht!'
	$str .= " ] def \n";

	# Y2 axis (re-)numbered for PostScript.
	$str .= '/y2 [';
	if ($self->{close_gap}) {
		$str .= join q{ }, gap_free_skip( $self->{y2}, $self->{not_shown} );
	}
	else {
		$str .= join q{ }, @{ $self->{y2} };
	}

	$str .= "] def \n";    # Y2 axis
	return $str;
}

# Given two arrays retrun a copy of 2nd array after decrementing its elements
# for each lesser element of 1st array. Used to provide PostScript with /column_arrays
# named 0 thru N with no gaps when chans have been skipped over to graph.
sub gap_free_skip {
	my ( $shown_aref, $not_shown_aref ) = @_; # Local, not part of $self->{foo} hash!
	my @gap_free = @$shown_aref;
	for my $i ( 0 .. $#gap_free ) {
		for my $j (@$not_shown_aref) {

			# Index decremented for each gap beneath it.
			if ( $j < $shown_aref->[$i] ) { --$gap_free[$i] }
		}
	}
	return @gap_free;
}

# Assign an arrow character from Symbol font to
# indicate which Y axis ought be read from.
sub y_arrow {
	ref( my $self = shift ) or croak 'Oops! Method y_arrow() is instance, not class.';
	my $i = shift;
	my $arrow = $EMPTY;
	my @y2 = @{$self->{y2}};
	if (@y2) {
		$arrow = '\254';
		for (@y2) { $arrow = '\256' if $_ == $i}
	}
	return $arrow;
}

# PostScript strings are ( ) delimited!
sub ps_str_esc {
	ref( my $self = shift ) or croak 'Oops! Method ps_str_esc() is instance, not class.';
	$_[0] =~ s/\(/\\(/gm;
	$_[0] =~ s/\)/\\)/gm;
	$self->verbose( "ps_str_esc(): $_[0] \n", 2);
	return $_[0];
}

# Build label for chans shown, list of those not to show.
sub chans_elect {
	ref( my $self = shift ) or croak 'Oops! Method chans_elect() is instance, not class.';

	for ( @{ $self->{names} } ) { $_ = $self->ps_str_esc($_) }

	my @ps_string_list = qw(
		label_top
		label_x
		label_x_2
		label_y1
		label_y1_2
		label_y2
		label_y2_2
	);

	for (@ps_string_list) { $self->{$_} = $self->ps_str_esc($self->{$_}) }

	# Collect list of shown-channel names
	# Prettify them into a graph legend good for B&W, not just color.
	for (@{ $self->{y1} }, @{ $self->{y2} }) {
		my $arrow = $self->y_arrow($_);
		$self->{label_x_proc} .= " ($arrow$_) $_ show_color_id ($self->{names}->[$_]  ) show ";
	}

	# Determine list of channels not to show.
	for ( 1 .. $#{$self->{names}} ) {

		# Mitigate an RE between Perl & PostScript by swaping all
		# escaped-for-PostScript string delimiters with Perl RE dots.
		my $re = $self->{names}->[$_];
		$re =~ tr/\\()/.../;

		push @{$self->{not_shown}}, $_ unless $self->{label_x_proc} =~ m/$re/m;

		# Problems may still exist between Perl RE's and PostScript syntax.
		# Diagnose these via CLI if in doubt by setting $verbosity = 2.
		$self->verbose(
			"RE Check 1: \n\t" . $self->{label_x_proc}
			. "\n\t =~ \n\t$re" . "\n"
			, 2
		);
		$self->verbose(
			'RE Check 2: not_shown = '
			. join(', ', @{$self->{not_shown}}) . "\n\n"
			, 2
		);
	}

	$self->{label_x_proc} = "/label_x_proc { $self->{label_x_proc} } def \n";
	$self->verbose( "LABEL X PROC: $self->{label_x_proc} \n", 2);
	return 'Pthhht! to Perl::Critic';
}

# Output data in PostScript file format.
sub write_eps {
	ref( my $self = shift ) or croak 'Oops! Method write_eps() is instance, not class.';
	$self->{ps_path} = qq|$_[0]|;
	local $OUTPUT_AUTOFLUSH = 1; # from 'use ENGLISH'

	my ( $ps_user_defs ) = $self->ps_defs_insert();

	if ( open my $fh, '>', "$self->{ps_path}" ) {

		# Embed filename sans path in PostScript header.
		$self->{ps_header} =~ s/%%Title:/%%Title: ($self->{ps_path})/m;

		# Embed document font resources.
		my $doc_rsrcs = "font Symbol $self->{font_name}";
		$self->{ps_header} =~ s/%%DocumentResources:/%%DocumentResources: $doc_rsrcs/m;

		# IMPORTANT NOTE: Know that Perl::Critic errs about the package vars
		# named like "$Chart::EPS_graph::PS::ps_foo" below. They are needed!

		print {$fh} $self->{ps_header};
		print {$fh} $Chart::EPS_graph::PS::ps_web_colors_dict;
		print {$fh} $Chart::EPS_graph::PS::ps_prolog_generic;
		print {$fh} $Chart::EPS_graph::PS::ps_prolog_graphing;
		print {$fh} $Chart::EPS_graph::PS::ps_prolog_data_arrays;
		print {$fh} $Chart::EPS_graph::PS::ps_prolog_drawing;
		print {$fh} $ps_user_defs;
		print {$fh} "/pg_width $self->{pg_width} def \n";
		print {$fh} "/pg_height $self->{pg_height} def \n";
		for ( $self->chans_pl2ps() ) { print {$fh} $_ }
		print {$fh} $Chart::EPS_graph::PS::ps_tail;
		close $fh;
		$self->verbose("Okay, EPS file written to path '$self->{ps_path}' \n", 1);
	}
	else { print qq|Oops! Cannot write to $self->{ps_path}: $!\n| }
	return 'Pthhht! to Perl::Critic';
}

# Convert kept Perl $self->{data} to sequential PostScript /column_arrays.
sub chans_pl2ps {
	ref( my $self = shift ) or croak 'Oops! Method chans_pl2ps() is instance, not class.';
	my @graph_ps;
	my $k = $self->{x_is_zeroth} ? 0 : 1; # Preserve /channel_array-0 for X axis only.

	# Write data from all chans into PostScript arrays
	for my $i ( 0 .. $#{$self->{data}} ) {
		my $array_ps = ' [ ';
		for ( 0 .. $#{ $self->{data}->[0] } ) {
			$array_ps .= sprintf '%.3e ', $self->{data}->[$i][$_];
		}
		$array_ps .= " ] def \n\n";

		# If skipping chans, is this chan among those not shown?
		my $flg = 0;
		if ($self->{close_gap}) {
			for (@{$self->{not_shown}}) {
				if ( $_ == $i ) { $flg = 1; last; }
			}
		}

		# Renumber chans so that PostScript progs /column_array's will
		# be innumerated in sequence with no gaps.
		if ( $i == 0 || $flg == 0 ) {
			$array_ps = "/column_array-$k $array_ps";
			push @graph_ps, $array_ps;
			++$k;
		}
	}
	push @graph_ps, "\n true \n";
	return @graph_ps;
}

# Narrow the search of directories made by win32_seek.
# If executable in dir named by numerical version, reduce the number of
# searched directories by matching to a regex.
sub single_dir {
	my ($parent, $re) = @_;
	my @fewer;
	opendir DIR, $parent || croak "Can't open $parent at sub single_dir().";
	my @files = readdir DIR;
	closedir DIR;
	for (@files) { push @fewer, $_ if $_ =~ m/$re/m}
	return scalar @fewer == 1 ? $fewer[0] : 0;
}

# On Win32 different veresions may be located variously.
# Not knowing which version user has, we mush seek it.
sub win32_seek {
	our ($reg_ex, $start_path) = @_;
	our $cmd_exe = $EMPTY;

	sub seek_exe {
		if (m/$reg_ex/m) { $cmd_exe = qq|"$File::Find::name"| }
		return 'Pthhht! to Perl::Critic';
	}

	# Hunt for its full path.
	File::Find::find(\&seek_exe, $start_path);

	$cmd_exe = qq|$cmd_exe|;
	$cmd_exe =~ s/\\/\//gm;
	return $cmd_exe;
}

# On Win32 different veresions may be located variously.
sub win32_run_gs {
	ref( my $self = shift ) or croak 'Oops! Method win32_run_gs() is instance, not class.';
	my $gs_args = shift;
	$self->verbose("Busy hunting for Ghostscript's executable...\n", 1);
	my $cmd = win32_seek('gswin32\.exe$','C:/Program Files/gs/');
	$self->verbose("Path to GhostScript: $cmd \n", 2);
	if ($cmd =~ m/gswin32/m) {
		`$cmd $gs_args`; # 'Pthhht!'
	} else {
		carp 'Oops! Could not find Ghostscript. Is it installed? '
	}                                   
	return 'Pthhht! to Perl::Critic';
}

# On Win32 different versions may be located variously.
sub win32_run_gimp {
	ref( my $self = shift ) or croak 'Oops! Method win32_run_gimp() is instance, not class.';
	my $path = 'C:/Program Files/';
	$self->verbose("Busy hunting for The GIMP's executable...\n", 1);
	my $sub_dir = single_dir($path, 'GIMP-');
	$path .= "$sub_dir/" if $sub_dir;
	$self->verbose("Search path to The GIMP: $path \n", 2);
	my $cmd = win32_seek('gimp-[2-9]\.[2-9]+\.exe$', $path);
	$self->verbose("Path to The GIMP: $cmd \n", 2);
	if ($cmd =~ m/gimp-/m) {
		system qq|start $cmd $cmd|, qq|"$self->{ps_path}"|
	}
	else { carp 'Oops! Could not find The GIMP. Is it installed? '}
	return 'Pthhht! to Perl::Critic';
}

# Cause *.eps graph to be converted/displayed in by separate program.
# Configured so may be called by Chart::EPS_graph::Test.pm
sub display {                                              
	ref( my $self = shift ) or croak 'Oops! Method display() is instance, not class.';
	my $cmd;
	my $gs_args = q{ }
		. '-dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m '
		. "-dDEVICEWIDTHPOINTS=$self->{pg_width} "
		. "-dDEVICEHEIGHTPOINTS=$self->{pg_height} "
		. '-dTextAlphaBits=2 -dGraphicsAlphaBits=4 -r96x96 '
		. qq|-sOutputFile="$self->{ps_path}.png" |
		. qq|"$self->{ps_path}" |;
		$self->verbose("Ghostscript args:\n$gs_args\n", 2);

	# Test OS: if not Windoze do as for UNIX-like.
	if ( $Config::Config{'osname'} =~ m/Win32/im ) {
		if (!$_[0] || $_[0] =~ m/EPS/im) { # Default argument.
			$cmd = qq|"gsview32.exe"|; # Perl::Critic errs about quotes here.
			system qq|start $cmd $cmd|, qq|"$self->{ps_path}"|;
		}
		elsif ($_[0] =~ m/^GIMP$/im)  { $self->win32_run_gimp() }
		elsif ($_[0] =~ m/^GS$/im) { $self->win32_run_gs($gs_args) }
		else {
			carp 'Oops! Sub display() expects "EPS", "GIMP", "GS" or nothing'
				. "not '$_[0]'.\n"
		}
	}
	else {

		# UNIX users get different choices.
		if (!$_[0] || $_[0] =~ m/EPS/im) { $cmd = 'gv --spartan ' } # Default
		elsif ($_[0] && $_[0] =~ m/GIMP/im)  { $cmd = 'gimp ' }
		elsif ($_[0] && $_[0] =~ m/GS/im)  { $cmd = 'gs' . $gs_args }
		else {
			carp 'Oops! Sub display() expects "EPS", "GIMP", "GS" or nothing'
				. " not '$_[0]'.\n";
		}

		$cmd .= qq|$self->{ps_path}|;

		`$cmd &` # Advice by Perl::Critic on backticks crashes program here.
	}                                         
	return 'Pthhht! to Perl::Critic';
}

1;

__END__

=head1 NAME

Chart::EPS_graph.pm

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	# Create anew a 600 x 600 points (not pixels!) EPS file
	my $eps = Chart::EPS_graph->new(600, 600);

	# Choose minimum required display info
	$eps->set(
		label_top => 'Graph Main Title',
		label_y1  => 'Y1 Axis Measure (Units)',
		label_y2  => 'Y2 Axis Measure (Units)',
		label_x   => 'X Axis Measure (Units)',
	);

	# Choose 6 of 13 named chans, 4 at left, 2 at right
	$eps->set(
		names => \@all_13_name_strings,
		data  => \@all_13_data_arefs,
		y1    => [7, 8, 10, 11],
		y2    => [9, 12],
	);


	# Choose  optional graph features
	$eps->set(
		label_y1_2 => 'Extra Y1 Axis Info',
		label_y2_2 => 'Extra Y2 Axis Info',
		label_x_2  => 'Extra X Axis Info',

		# Any common browser color no matter how hideous.
		bg_color   => 'DarkOliveGreen',
		fg_color   => 'HotPink',
		web_colors => ['Crimson', 'Lime', 'Indigo', 'Gold', 'Snow', 'Aqua'],

		# Any known I<PostScript> font no matter how illegible
		font_name  => 'ZapfChancery-MediumItalic',
		font_size  => 18,

		# See POD about this one. But in brief:
		# If set to "1" channel innumeration gaps will be closed.
		# If set to "0" (the default) they will be left as they are.
		close_gap  => 0,

		# If the 0th channel is not for the X axis (the default) then the
		# data point count is used as the X axis, which you may scale.
		# So if X were Time in seconds, with no 0th channel having acutally
		# recorded it, but each data point were known to be 0.5 seconds...
		$self->{x_is_zeroth} = 0;   # Boolean, so '1' or '0'.
		$self->{x_scale}     = 2;   # Have 10th datapoint show as 20, etc.
	);

	# Write output as EPS
	$eps->write_eps( cwd() . '/whatever.eps' ); # Write to a file.

	# View, convert or edit the EPS output
	$eps->display();       # Display in viewer (autodetects 'gv' or 'gsview.exe').
	$eps->display('GS');   # Convert to PNG via Ghostscript.
	$eps->display('GIMP'); # Open for editng in The GIMP.

=head1 DESCRIPTION

Creates line graphs in I<PostScript> as C<*.eps> format. 

Viewing accomplished via calls to I<Ghostscript> and/or to C<gv> on unix
and/or to C<GSView.exe> on Win32.

Coversion to C<*.png> accomplished via system calls to I<Ghostscript> on Unix 
and/or to C<GSView.exe> on Win32.

=head1 MAIN FEATURES

=head2 Dual Y Axes

You may have two Y axes, one each to left and right. The I<PostScript> code
will auto-reconcile a grid for optimum alignment between both of these Y axes.
By optimum I mean that scales will be adjusted such that curves traverse the
entirety of available Y-axis space.

=head2 143 Colors

You may use as many of the named colors from the W3C table at
C<http://www.w3schools.com/html/html_colornames.asp> as you like in any order
that you like.

=head2 Display, Convert or edit EPS Graph

Asked to display an EPS graph, a 3rd party viewer (C<gv> on UNIX, C<gsview.exe>
on Win32), coverter I<Ghostscript> or editor I<The GIMP> will be called up to
display, convert or edit the EPS graph.

=head2 Channel Innumeration Gaps

These you may either close or leave open. For example, suppose you have ten
channels total but only wish to graph five of them. And suppose those channels
are staggerd thus: 1, 3, 5, 6, 9. Closing the innumeration gap would make
those channels appear on the graph as if they were numbered 1, 2, 3, 4, 5. They
would also display in the first five colors, those which are most appealing and
afford the best contrast.

Closing the innumeration gap makes a stand-alone graph easier to read. Should
you, however, have more than one graph, with different channel sets on each,
then it is a bad idea. Better in such a case that each color be true to a
channel than easier upon the eye.

Closing the gap will also reduce file size considerably, as detailed next.

=head3 When you call C<$foo-E<gt>set{close_gap =E<gt> 0};>

Data arrays for all channels, even those not to be shown, will be embeded into
the I<PostScript> output file. Traces which are shown will display their true
channel numbers and be colorized in accordance with that true number.

Say, for instance, you are only showing Channel 12. It will be labeled as trace
number 12 and display in the 12th color. This makes a lot of sense when you
have a dozen graphs layed out on a table for none-too-bright customers to argue
over.

Why do this? The I<PostScript> program was originally written to run stand-
alone. This feature makes it easy to have one file and, with a minor hand edit,
generate any number of subsets for all all possible graphs by simply editing
the /not_shown array. 

=head3 When you call C<$foo-E<gt>set{close_gap =E<gt> 1};>

Data arrays for only those channels assigned to a Y axis will be embeded into
the I<PostScript> output file. Traces which are shown will display new channel
numbers (1 thru N) without any gaps and be colorized in accordance with that
new number.

=head1 SUBROUTINES/METHODS

These are pretty much fully covered in the synopsis.

=head1 DIAGNOSTICS

A separate test module exists to fully test this one. See POD at head of that
module for full details. But in short, you may call the full test on a single
line, or broken over two, as below...

	perl -e "use Chart::EPS_graph::Test; \ 
	Chart::EPS_graph::Test->full_test('/some/dir');"


...and thereby obtain a multi-step report as below...

	Testing Chart::EPS_graph.pm in path '/some/dir/'
	Okay! File 'foo.eps' has expected first two lines.
	Okay! File 'foo.eps' looks fresh: 0 seconds old.
	Okay! File 'foo.eps' looks big enough, 28319 bytes.
	Okay! Ghostscript created 'foo.eps.png'.
	Okay! File 'foo.eps.png' looks fresh: 1 seconds old.
	Okay! File 'foo.eps.png' looks big enough, 105828 bytes.
	Glad Tidings! All tests okay for Chart::EPS_graph.

Had there been a problem of any kind, one or more of the above lines would have
begun as I<Oops!> followed by a few terse details. 

You can also inspect the example files personally via I<The GIMP> or 
I<ImageMagick> as you choose. I<You can, that is, unless it was the CPAN
build proccess which made the call; in which case those files will have
been deleted immediately after each was measured.>

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration. It auto-searches for its dependencies
by calling to C<File::Find>.

My goal, as always, is OS-independence, but only have recources to design and
test on these two platforms only:

=over 4

=item NetBSD 2.0.2 running Perl 5.8.7

Which I am happy to run on my P4 tower and both of my laptops at home.

=item WinXP SP2 running ActiveState Perl 5.8.0.

Which I am saddled with having to suffer the use of at work.

=back

=head1 DEPENDENCIES

Because output is to I<PostScript> most users will want to convert the output 
to some other graphics format. Built-in methods for converting to C<*.png> are
provided. The method of choice, of course, is I<Ghostscript>.


=head2 Ghostscript

The I<Ghostscript> interpreter for I<PostScript> files is free and available
for all platforms. This is what will make sense of your C<*.eps> files and
convert them for viewing on screen. But since it is command-line only (no GUI)
most folks talk to it only through GUI-enabled viewer programs. This module
avoids all that, just talking to I<Ghostscript> for you. Nevertheless, you may
wish to employ a GUI-enabled viewer.

F<http://www.ghostscript.com/>

=head2 Other PostScript Viewers

These too are free. They generally work by interfacing with I<Ghostscript> on
your behalf, saving you the hassle of having to deal with I<Ghostscript>'s
command-line (non-GUI) interface. These are all much more user-friendly.

=over 4

=item FOR WINDOWS ONLY

The program C<GSView.exe> will display C<*.eps> files and also convert them to
to other formats. Conversion from C<*.eps> to C<*.png> is excellent.

=item FOR UNIX ONLY

The program C<gv> will display C<*.eps> files very well. It will not, however
convert them to any other formats.

=item FOR ALL

The Gnu Image Management Program (aka I<The GIMP>) is a full-bodied graphic
image editor which, among its many other features, can also read in C<*.eps>
files via Ghostscript. And any format it can read it, it can also convert and
write out. I<The GIMP> is, of course, both free and open-source.

F<http://www.gimp.org/>

When you open an C<*.eps> file in I<The GIMP> it will pop up a menu for how you
want the C<*.eps> file to be read in. Select the I<Try Bounding Box> checkbox.
Then note the two I<antialiasing> radio buttons. Select I<weak> for text and
I<strong> for graphics. This will make bring up an image which looks just like
the default both which C<gv> and C<GSView> provide.

=back

=head1 INCOMPATIBILITIES

None known as yet.

=head1 BUGS AND LIMITATIONS

Owing to inbuilt addressing limitations of I<PostScript>, data sets may not
exceed 65,535 data points.

This program, being free software, carries absolutely no warranties or
guarantees of any kind, neither expressed, implied, or even vaguely hinted at.

=head1 SCRIPT HISTORY

The I<PostScript> definitions herein embeded derive from a standalone
I<PostScript> program named C<OmniGraph.ps> which I wrote sometime circa 1992.
This I did in response to frustrations over an upgrade by Measurments Group to
the software in their System 5000 strain gage instrument versus the graphing
feature in their older System 4000.

I'd already gotten kind of handy in I<PostScript> from wrangling with the
I<PostScript> prolog files of I<Amiga 2000> programs like I<Excellence!> and
I<Gold Disk> so as to publish in Esperanto for which I could find no fonts.
But that I was able to deal with on my own in due course, and for several
platforms besides my own beloved I<Amiga>.

As an aside I cannot refrain from relating that this particular frustration
also proved to be the font (pun intended) of my initial anger and dismay at
Microsoft. Since once I had learnt how to solve this problem for both the
I<Amiga> and for the I<Macintosh> I next turned, as a community service, to
do so for I<MS Word> and found it imposible. How so? Entirely because
Mr. Gates had done two things to thwart me: First he'd encrypted MS Word's
I<PostScript> prolog file for no good reason. And second, once I had managed
to decrypt said prolog, I next found the fiend to have therein called the
I<PostScript> 'exitserver' command entirely contrary to warnings forbidding
such in the official I<PostScript> docs. My Microsoft-ish experiences since
have only deepened that sentiment further.

As an aside, you may further wish to know that the reason folks now publish 
telephone numbers as 123.555.1212 versus the more traditional 123-555-1212
may also be blamed on Mr. Gates. MSWord sorely frustrated users for lack of 
a non-breaking hyphen (which Amiga, Apple, NEXT and several others all had). 
So to keep telphone numbers from wrapping on a line, poor sods stuck with 
MSWord started using periods. But I digress...

From there I went kind of wild with I<PostScript>, using it in all manner of
ways for which it was probably not intended. This I could in no wise have done
without the continuing example of Don Lancaster, noted I<PostScript> guru, for
his many excellent articles in I<Publish> magazine and elsewhere.

Ref. F<http://www.tinaja.com>

Most of those ancient efforts have now lain fallow many a year. But once again,
this time in frustration over a (for most folks, trifling) lack in the Perl
module C<GD::Graph::lines>, I have resurrected my old, trusty C<OmniGraph.ps>
and grafted it piecemeal, with some changes, into this new module
C<Chart::EPS_graph.pm> so as to work around that specific issue where
C<GD::Graph::lines> chokes on dual Y axes needing multiple channels.

=head1 AUTHOR

Gan Uesli Starling <F<gan@starling.us>>

=head1 LICENSE AND COPYRIGHT

This program is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

Copyright (c) 2006 Gan Uesli Starling. All rights reserved.

=cut

