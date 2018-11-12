package App::fftrim;
use 5.006;
use strict;
use warnings;
no warnings 'once';
no warnings 'uninitialized';
use feature 'say';
use Cwd;
our ($opt, $usage,
	$current_dir,
	$control,
	$control_file,
	$dotdir ,
	$profile,
	$fh,
	$encoding_params,
	%length,
	$framerate,
	$finaldir,
	@lines,
	$is_error,
	@source_files,
	$concat_target,
);
sub initial_setup {

	$dotdir = join_path($ENV{HOME}, '.fftrim');
	my $did_something;
	if ( ! -d $dotdir)
	{	mkdir $dotdir;
		$did_something++;
		my $default = join_path($dotdir, 'default');
		say STDERR qq(\n$default contains ffmpeg options to merge by default.);
		print STDERR qq(\nShall I populate this file with sample compression settings ? [y/n] );
		my $answer = <STDIN>;
		open my $fh, '>', $default;
		if ($answer =~ /YyJj/)
		{
			my @lines = <DATA>;
			print $fh @lines;	
			say STDERR "Done! Edit this file to suit your needs or create additional profiles";
		}
		else {print $fh "\n"}
	}
	print "\n";
	$did_something;
}

sub process_args {


	$current_dir = getcwd;

	$profile = join_path($dotdir, $opt->{profile} // 'default');
	if (-r $profile)
	{
		open $fh, '<', $profile;
		$encoding_params = join '', grep {! /^#/} <$fh>;
		$encoding_params =~ s/\n/ /g;
	}

	# handle command line mode 
	if ($opt->{in} and $opt->{out} ){
		if ($opt->{in} =~ /\s/)
		{
			@source_files = split ' ', $opt->{in};
			$framerate = video_framerate($source_files[0]);
			say "source files: ", join '|', @source_files;
			$concat_target = $opt->{concat_only} ? $opt->{out} : to_mp4($source_files[0]);
			say "concat target: $concat_target";
			concatenate_video($concat_target, @source_files);
		}
		compress_and_trim_video($concat_target//$opt->{in}, $opt->{out}, $opt->{start} // 0, $opt->{end})
			unless $opt->{concat_only};
		exit
	}

	# batch mode

	# support old filename
	($control_file) = grep{ -e } map{ join_path($opt->{source_dir},$_) }  qw(CONTROL CONTENTS);
	-e $control_file or die "CONTROL file not found in $opt->{source_dir}";

	$finaldir = $opt->{target_dir};
	mkdir $finaldir unless -e $finaldir;
	-d $finaldir or die "$finaldir is not a directory!";

	open my $fh, '<',$control_file;
	(@lines) = grep {! /^\s*$/ and ! /^\s*#/} map{ chomp; $_ } <$fh>;

	process_lines(); # check for errors;
	say(STDERR "Errors found. Fix $control_file and try again."), exit if $is_error;
	process_lines("really do it! (but still may be a test)");

}
sub get_lengths {
	my @source_files = @_;
		for (@source_files)
		{
			next if defined $length{$_};
			my $len = video_length($_);
			$length{$_} = seconds($len);
		}

}

sub process_lines { 
	my $do = shift;
	foreach my $line (@lines){
		$line =~ s/\s+$//;
		say STDERR "line: $line";
		my ($source_files, $target, $start, $end) = split /\s+:\s+/, $line;
		my @source_files = map{ join_path($opt->{source_dir}, $_)} split " ", $source_files;
		$framerate = video_framerate($source_files[0]);
		get_lengths(@source_files);
		say STDERR qq(no target for source files "$source_files". Using source name.) if not $target;
		if ( ! $target ) { 
			$target = to_mp4($source_files[0]);
		}
		else {
			# pass filenames with extension, otherwise append .mp4
			$target = mp4($target) unless $target =~ /\.[a-zA-Z]{3}$/ 
		}
		{
		no warnings 'uninitialized';
		say STDERR "source files: @source_files";
		say STDERR "target: $target";
		say STDERR "start time: $start";
		say STDERR "end time: $end";
		say(STDERR qq(no source files in line!! $line)), $is_error++, if not @source_files;
		my @missing = grep { ! -r } @source_files;
		say(STDERR qq(missing source files: @missing)), $is_error++, if @missing;
		}

		next unless $do;
		my $compression_source;
		if (@source_files > 1)
		{
			my $concat_target = to_mp4($source_files[0]);
			say STDERR "concat target: $concat_target";
			concatenate_video($concat_target, @source_files);
			$compression_source = $concat_target;
		} 
		else 
		{ 
			$compression_source = $source_files[0];
		}
			my $final = trim_target($target); 
			$start = decode_cutpoint($start, \@source_files);
			$end = decode_cutpoint($end, \@source_files);
			say STDERR "decoded start: $start, decoded end: $end";
			compress_and_trim_video(
				$compression_source,
				$final, 
				$start,
				$end
			);
	}
}
sub name_part  { my ($name) = $_[0] =~ /(.+?)(\.[a-zA-Z]{1,3})$/}
sub mp4 { $_[0] . '.mp4' }
sub to_mp4 { mp4( $opt->{old_concat} ? name_part($_[0]): $_[0]) }

sub trim_target { "$finaldir/$_[0]" }

sub concatenate_video {
	my ($target, @sources) = @_;
	file_level_concat($target, @sources);
}

sub file_level_concat {
	my ($target, @sources) = @_;
	$target .= ".mp4" unless $target =~ /mp4$/;
	say(STDERR "$target: file exists, skipping"), return if file_exists($target);
	my $parts = join '|', @sources;
	my $cmd = qq(ffmpeg -i concat:"$parts" -codec copy $target);
	say STDERR "concatenating: @sources -> $target";
	say $cmd;
	system $cmd unless simulate();
}

sub compress_and_trim_video {
	my ($input, $output, $start, $end) = @_;
	say "compress and trim args: ",join " | ",$input, $output, $start, $end;
	say(STDERR "$output: file exists, skipping"), return if file_exists( $output );
   	my $target_framerate;
   	$target_framerate = $opt->{auto_frame_rate}
							? $framerate
							: $opt->{frame_rate};
	$start //= 0;
	my @args = "ffmpeg";
	push @args, "-i $input";
	push @args, "-to $end" if $end;
	push @args, $encoding_params;
	push @args, "-ss $start" if $start;
	push @args, "-r $target_framerate" if $target_framerate;
	push @args, $output;
	my $cmd = join " ",@args;
	say $cmd;
	system $cmd unless simulate();
}
sub seconds {
	my $hms = shift;
	my $count = $hms =~ tr/:/:/;
	$count //= 0;
	# case 1, seconds only
	if (! $count)
	{
		return $hms
	}
	elsif($count == 1)
	{
		# m:s
	
		my ($m,$s) = split ':', $hms;
		return $m * 60 + $s
	}
	elsif($count == 2)
	{
		my ($h,$m,$s) = split ':', $hms;
		return $h * 3600 + $m * 60 + $s
	}
	else { die "$hms: something wrong, detected too many ':' characters" }
}
sub hms {
	my $seconds = shift;
	my $whole_hours = int( $seconds  / 3600 );
	$seconds -= $whole_hours * 3600;
	my $whole_minutes = int( $seconds / 60 );
	$seconds -= $whole_minutes * 60;
	$whole_minutes = "0$whole_minutes" if $whole_minutes < 10;
	$seconds = "0$seconds" if $seconds < 10;
	my $output;
	$output .=  "$whole_hours:" if $whole_hours;
	$output .=  "$whole_minutes:" if $whole_minutes > 0 or $whole_hours;
	$output .= $seconds;
	$output
}
sub decode_cutpoint {
	my ($pos, $sources) = @_;
	return unless $pos;
	# 1+2+24:15
	# 3-24:15 3rd file
	my ($nth, $time) = $pos =~ /(\d+)-([\d:]+)/;
	my $cutpoint; # this is a position in the final source file
	my $segments; # this is the count of the preceeding source files included at full length
 	if ($nth){
 		$cutpoint = $time;	
 		$segments = $nth - 1;
 	}
	else {
		my (@segments) = $pos =~ /(\d\+)?(\d\+)?(\d\+)?([^+]+)$/;
		$cutpoint = (pop @segments) // 0;
		$segments = 0;
		if (@segments){
			@segments = map{ s/\+\s*//g; $_ } grep{$_} @segments;
			$segments =  scalar @segments;
		}
	}
	my $total_length = seconds($cutpoint);
	$total_length += $length{$sources->[$_]} for 0 .. $segments - 1;
	hms($total_length)
}
sub join_path { join '/',@_ }

sub simulate { $opt->{n} or $opt->{m} }
sub file_exists { $opt->{m} ? 0 : -e $_[0] }

sub video_length {
	my $videofile = shift;
	my $result = qx(ffmpeg -i "$videofile" 2>&1 | grep Duration | cut -d ' ' -f 4 | sed s/,//);
	chomp $result;
	$result
}
sub video_framerate {
	my $videofile = shift;
	my $result = qx(ffprobe "$videofile" 2>&1);
	my ($fps) = $result =~ /(\d+(.\d+)?) fps/;
}
=head1 NAME

B<fftrim> - concatenate, trim and compress video files

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

see 'man fftrim' or 'perldoc fftrim'.

=cut
1; # End of App::fftrim
