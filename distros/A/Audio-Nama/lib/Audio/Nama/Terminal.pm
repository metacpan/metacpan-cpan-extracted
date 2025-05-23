# ----------- Terminal related subroutines ---------

package Audio::Nama;
use Modern::Perl '2020';
no warnings 'uninitialized';
use Carp;
use Audio::Nama::Globals qw(:singletons $this_bus $this_track);
use Audio::Nama::Log qw(logpkg logsub);
use Data::Dumper::Concise;
use List::MoreUtils qw(first_index);

sub initialize_prompt {
	$text->{term}->stuff_char(10); # necessary to respond to Ctrl-C at first prompt 
	&{$text->{term_attribs}->{'callback_read_char'}}();
	set_current_bus();
	print prompt();
	$text->{term_attribs}->{already_prompted} = 0;
}

sub initialize_terminal {
	$text->{term} = new Term::ReadLine("Ecasound/Nama");
	$text->{term_attribs} = $text->{term}->Attribs;
	$text->{term_attribs}->{attempted_completion_function} = \&complete;
	$text->{term_attribs}->{already_prompted} = 1;
	($text->{screen_lines}, $text->{screen_columns}) 
		= $text->{term}->get_screen_size();
	logpkg(__FILE__,__LINE__,'debug', "screensize is $text->{screen_lines} lines x $text->{screen_columns} columns");
	detect_spacebar(); 

	revise_prompt();

	# handle Control-C from terminal

	

	$project->{events}->{sigint} = AE::signal('INT', \&cleanup_exit); 
	# responds in a more timely way than $SIG{INT} = \&cleanup_exit; 

	$SIG{USR1} = sub { project_snapshot() };
}

sub end_of_list_sound { system( $config->{hotkey_beep} ) }

sub previous_track {
	end_of_list_sound(), return if $this_track->n == 1;
	do{ $this_track = $ti{$this_track->n - 1} } until !  $this_track->hide;
}
sub next_track {
	end_of_list_sound(), return if ! $ti{ $this_track->n + 1 };
	do{ $this_track = $ti{$this_track->n + 1} } until ! $this_track->hide;
}
sub previous_effect {
	my $op = $this_track->op;
	my $pos = $this_track->pos;
	end_of_list_sound(), return if $pos == 0;
	$pos--;
	set_current_op($this_track->ops->[$pos]);
}
sub next_effect {
	my $op = $this_track->op;
	my $pos = $this_track->pos;
	end_of_list_sound(),return if $pos == scalar @{ $this_track->ops } - 1;
	$pos++;
	set_current_op($this_track->ops->[$pos]);
}
sub previous_param {
	my $param = $this_track->param;
	$param > 1  ? set_current_param($this_track->param - 1)
				: end_of_list_sound()
}
sub next_param {
	my $param = $this_track->param;
	$param < scalar @{ fxn($this_track->op)->params }
		? $project->{current_param}->{$this_track->op}++ 
		: end_of_list_sound()
}
{my $override;
sub revise_prompt {
	logsub((caller(0))[3]);
	# hack to allow suppressing prompt
	$override = ($_[0] eq "default" ? undef : $_[0]) if defined $_[0];
    $text->{term}->callback_handler_install($override//prompt(), \&process_line)
		if $text->{term}
}
}

	
sub prompt { 
	logsub((caller(0))[3]);
	join ' ', 'nama', git_branch_display(), bus_track_display(),'> '
}
sub detect_spacebar {

	# create a STDIN watcher to intervene when space
	# received in column one
	
	$project->{events}->{stdin} = AE::io(*STDIN, 0, sub {
		&{$text->{term_attribs}->{'callback_read_char'}}();
		my $buffer = $text->{term_attribs}->{line_buffer};
		my $trigger = ' ';
		if ( $config->{press_space_to_start} 
				and ($buffer eq $trigger)
				and ! ($mode->song or $mode->live) )
		{ 	
			toggle_transport();	

			# reset command line, read next char
			
			$text->{term_attribs}->{line_buffer} = q();
			$text->{term_attribs}->{point} 		= 0;
			$text->{term_attribs}->{end}   		= 0;
			$text->{term}->stuff_char(10);
			&{$text->{term_attribs}->{'callback_read_char'}}();

			
		}
	});
}
sub throw {
	logsub((caller(0))[3]);
	pager_newline(@_)
}
sub pagers { &pager_newline(join "",@_) } # pass arguments along

sub pager_newline { 

	# Add a newline if necessary to each line
	# push them onto the output buffer
	# print them to the screen
	
	my @lines = @_;
	for (@lines){ $_ .= "\n" if  ! /\n$/ }
	push @{$text->{output_buffer}}, @lines;
	print(@lines);
}

sub paging_allowed {

		# The pager interferes with GUI and testing
		# so do not use the pager in these conditions
		# or if use_pager config variable is not set.
		
		$config->{use_pager} 
		and ! $config->{opts}->{T}
}
sub pager {

	# push array onto output buffer, add two newlines
	# and print on terminal or view in pager
	# as appropriate
	
	logsub((caller(0))[3]);
	my @output = @_;
	@output or return;
	chomp $output[-1];
	$output[-1] .= "\n\n";
	push @{$text->{output_buffer}}, @output;
	page_or_print(@output);
	1
}

sub init_output_buffer { $text->{output_buffer} //= [] };

sub linecount {
	my @output = @_;
	my $linecount = 0;
	for (@output){ $linecount += $_ =~ tr(\n)(\n) }
	$linecount
}

sub page_or_print {
	my (@output) = @_;
	@output = map{"$_\n"} map{ split "\n"} @output;
	return unless scalar @output;
	print(@output), return if !paging_allowed() or scalar(@output) <= $text->{screen_lines} - 2;
	write_to_temp_file_and_view(@output)
}
sub write_to_temp_file_and_view {
	my @output = @_;
	my $fh = File::Temp->new();
	my $fname = $fh->filename;
	print $fh @output;
	file_pager($fname);
}
sub file_pager {

	# given a filename, run the pager on it
	
	logsub((caller(0))[3]);
	my $fname = shift;
	if (! -e $fname or ! -r $fname ){
		carp "file not found or not readable: $fname\n" ;
		return;
    }
	my $pager = $ENV{PAGER} || "/usr/bin/less";
	$pager =~ /less/ and $pager .= qq( -M -i -PM"q=quit pager, /=search, PgUp/PgDown=scroll (line %lt/%L)");
	my $cmd = qq($pager $fname); 
	system $cmd;
}

1;
# command line processing routines

sub get_ecasound_iam_keywords {

	my %reserved = map{ $_,1 } qw(  forward
									fw
									getpos
									h
									help
									rewind
									quit
									q
									rw
									s
									setpos
									start
									stop
									t
									?	);
	
	%{$text->{iam}} = map{$_,1 } 
				grep{ ! $reserved{$_} } split /[\s,]/, ecasound_iam('int-cmd-list');
}
sub load_keywords {
	my @keywords = keys %{$text->{commands}};
 	# complete hyphenated forms as well
 	my %hyphenated = map{my $h = $_; $h =~ s/_/-/g; $h => $_ }grep{ /_/ } @keywords;
	$text->{hyphenated_commands} = \%hyphenated;
	push @keywords, keys %hyphenated;
	push @keywords, grep{$_} map{split " ", $text->{commands}->{$_}->{short}} @keywords;
	push @keywords, keys %{$text->{iam}};
	push @keywords, keys %{$fx_cache->{partial_label_to_full}};
	push @keywords, keys %{$text->{midi_cmd}} if $config->{use_midi};
	push @keywords, "Audio::Nama::";
	@{$text->{keywords}} = @keywords
}

sub complete {
    my ($string, $line, $start, $end) = @_;
	#print join $/, $string, $line, $start, $end, $/;
	my $term = $text->{term};
    return $term->completion_matches($string,\&keyword);
};

sub keyword {
		state $i;	
        my ($string, $state) = @_;
        return unless $text;
        if($state) {
            $i++;
        }
        else { # first call
            $i = 0;
        }
        for (; $i<=$#{$text->{keywords}}; $i++) {
            return $text->{keywords}->[$i] 
				if $text->{keywords}->[$i] =~ /^\Q$string/;
        };
        return undef;
};
1;
__END__