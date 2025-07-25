# ----------- Ecasound cleanup (post-recording) -----------
package Audio::Nama::EcasoundCleanup;
use Role::Tiny;
use v5.36;
our $VERSION = 1.0;
sub cleanup {
	my $self = shift;
	Audio::Nama::rec_cleanup();
}


package Audio::Nama;
use v5.36;
use Cwd;
use File::Spec::Functions qw(splitpath);
use Audio::Nama::Globals qw(:all);

sub rec_cleanup {  
	logsub((caller(0))[3]);
	logpkg(__FILE__,__LINE__,'debug',"transport still running, can't cleanup"), return if $this_engine->running;
	if( my (@files) = new_files_were_recorded() )
	{
		if( my @rec_tracks = Audio::Nama::ChainSetup::engine_wav_out_tracks() )
		{
			$project->{playback_position} = 0;
			$setup->{_last_rec_tracks} = \@rec_tracks;
		}

		if( grep /Mixdown/, @files) { 
				mixdown_postprocessing() ;
				mixplay();
		}
		post_rec_configure() 
	}
}
sub mixdown_postprocessing {
	logsub((caller(0))[3]);
	nama_cmd('mixplay');
	my ($oldfile) = $tn{Mixdown}->full_path =~ m{([^/]+)$};
	$oldfile = join_path('.wav',$oldfile);
	my $tag_name = join '-', $project->{name}, current_branch();
	my $version = $tn{Mixdown}->playback_version;

	# simplify the tagname basename 
	# 
	# 	untitled-master        -> untitled
	#   untitled-premix-branch -> untitled-premix
	
	$tag_name =~ s/-branch$//;
	$tag_name =~ s/-master$//;
	$tag_name .= "_$version";

	delete_existing_mixdown_tag_and_convenience_encodings($tag_name);

	# create symlink in project_dir()
	
	my $was_in = getcwd;
	chdir project_dir() or die "couldn't chdir: $!";
	my $newfile = "$tag_name.wav";
	logpkg(__FILE__,__LINE__,'debug',"symlinking oldfile: $oldfile, newfile: $newfile");
	symlink $oldfile, $newfile or throw("symlink didn't work: $!");
	tag_mixdown_commit($tag_name, $newfile, $oldfile) if $config->{use_git};

	my $sha = git_sha(); # possibly undef
	my $encoding = $config->{mixdown_encodings};
	my $comment;
	if ($sha or $encoding){
		$comment .= "tagged " if $sha;
		$comment .= "and " if $sha and $encoding;
		$comment .= "encoded " if $encoding;
		$comment .= "as $tag_name ";
		$comment .= "(commit $sha)" if $sha;
	}
	$tn{Mixdown}->add_system_version_comment($version, $comment);
	pager_newline($comment);	
	encode_mixdown_file($oldfile,$tag_name);
	chdir $was_in;
}
sub tag_mixdown_commit {
	logsub((caller(0))[3]);
	my ($name, $newfile, $mixdownfile) = @_;
	logpkg(__FILE__,__LINE__,'debug',"tag_mixdown_commit: @_");

	my ($sym) = $newfile =~ m([^/]+$);
	my ($mix) = $mixdownfile =~ m([^/]+$);

	# we want to tag the normal playback state
	
	local $quiet = 1;
	mixoff();

	my $msg = "State for $sym ($mix)";
	project_snapshot($msg);
	git('tag', $name, '-m', $mix);
}
sub delete_existing_mixdown_tag_and_convenience_encodings {
	logsub((caller(0))[3]);
	my $name = shift;
	logpkg(__FILE__,__LINE__,'debug',"name: $name");
		git('tag', '-d', $name);
		foreach( qw(mp3 ogg wav) ){
			my $file = join_path(project_dir(),"$name.$_");
			unlink $file if -e $file;
		}
	}
sub encode_mixdown_file {
	state $shell_encode_command = {
		mp3 => q(lame -h --ta "$artist" --ty $year --tt "$title" $input_file $output_file),
		ogg => q(oggenc -o $output_file -a "$artist" -t "$title" -d "$date" $input_file)
	};	
	my($mixdownfile, $tag_name, @formats) = @_;
	@formats or @formats = split " ", $config->{mixdown_encodings};
	logpkg(__FILE__,__LINE__,'debug',"formats: @formats");
	my $artist = $project->{artist} || qx(whoami);
	my $title = $project->{name};
	my $date = qx(date);
	chomp($date, $artist);
	my ($year) = $date =~ /(\d{4})$/;
	my $input_file = $mixdownfile;
	for my $format( @formats ){
		my $output_file = join_path(project_dir(),"$tag_name.$format");
		logpkg(__FILE__,__LINE__,'debug',"artist $artist, title $title, date $date, year $year, input file $input_file, output file $output_file");
		my $cmd = eval qq(qq($shell_encode_command->{$format}));
		logpkg(__FILE__,__LINE__,'debug',"Mixdown encoding command:\n$cmd");
		system $cmd; 
	}

}
		
sub adjust_offset_recordings {
	for( Audio::Nama::ChainSetup::engine_wav_out_tracks()){
		no warnings 'uninitialized';
		if (my $mark = $setup->{offset_run}->{mark}){
			$_->set(playat => $mark);
			logpkg(__FILE__,__LINE__,'debug',$_->name, ": offsetting to $mark");
		}
	}
}
sub post_rec_configure {

		$ui->global_version_buttons(); # recreate
		adjust_offset_recordings();

		# toggle recorded tracks to PLAY for auditioning
		
		map{ $_->set(rw => PLAY) } @{$setup->{_last_rec_tracks}};
		
		undef $mode->{offset_run} if ! defined $this_edit;
		$ui->refresh();
		request_setup();
		reconfigure_engine();
}
sub new_files_were_recorded {
 	return unless my @files = Audio::Nama::ChainSetup::really_recording();
	logpkg(__FILE__,__LINE__,'debug',join $/, "intended recordings:", @files);
	my @recorded =
		grep { 	my ($name, $version) = /([^\/]+)_(\d+).wav$/;
				if (-e ) {
					if (-s  > 44100) { # 0.5s x 16 bits x 44100/s
						logpkg(__FILE__,__LINE__,'debug',"File size >44100 bytes: $_");
						$tn{$name}->set(version => $version) if $tn{$name};
						$ui->update_version_button($tn{$name}->n, $version);
					1;
					}
					else { unlink $_; 0 }
				}
		} @files;
	if(@recorded){
		refresh_wav_cache();
		pager(join " ", "recorded:", map{ filename($_) } @recorded);
	}
	map{ _get_wav_info($_) } @recorded;
	@recorded 
} 
sub filename {
	my $path = shift;
	my(undef, undef, $name) = splitpath($path);
	$name
}
1;
__END__