package Audio::Nama::Wav;
our $VERSION = 1.001;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Util qw(:all);
use Audio::Nama::Assign qw(:all);
use Audio::Nama::Util qw(join_path);
use Audio::Nama::Log qw(logsub logpkg);
use Memoize qw(memoize unmemoize); # called by code in Audio::Nama::Memoize.pm
use warnings;
no warnings qw(uninitialized);
use Carp;

use Role::Tiny;

sub wav_length {
	my $track = shift;
	Audio::Nama::wav_length($track->full_path)
}
sub wav_format{
	my $track = shift;
	Audio::Nama::wav_format($track->full_path)
}

	
sub dir {
	my $self = shift;
	 $self->project  
		? join_path(Audio::Nama::project_root(), $self->project, '.wav')
		: Audio::Nama::this_wav_dir();
}

sub basename {
	my $self = shift;
	$self->target || $self->name
}

sub full_path { my $track = shift; join_path($track->dir, $track->current_wav) }

sub group_last {
	my $track = shift;
	my $bus = $bn{$track->group}; 
	$bus->last;
}

sub last { $_[0]->versions->[-1] || 0 }
sub current_wav {
	my $track = shift;
	my $last = $track->current_version;
	if 	($track->rec){ 
		$track->name . '_' . $last . '.wav'
	} elsif ( $track->rw eq PLAY){ 
		my $filename = $track->targets->{ $track->playback_version } ;
		$filename
	} else {
		logpkg(__FILE__,__LINE__,'debug', "track ", $track->name, ": no current version") ;
		undef; 
	}
}

sub current_version {	
	my $track = shift;

	# two possible version numbers, depending on REC/PLAY status
	
	if 	($track->rec)
	{ 
		my $last = $config->{use_group_numbering} 
					? Audio::Nama::Bus::overall_last()
					: $track->last;
		return ++$last
	}
	elsif ($track->play){ return $track->playback_version } 
	else { return 0 }
}

sub playback_version {
	my $track = shift;
	return $track->version if $track->version 
				and grep {$track->version  == $_ } @{$track->versions} ;
	$track->last;
}
sub targets { # WAV file targets, distinct from 'target' attribute
	my $self = shift;
	_targets(dir => $self->dir, name => $self->basename)
}
sub versions {
	my $self = shift;
	_versions(dir => $self->dir, name => $self->basename) 
}


sub get_versions {
	my %args = @_;
	$args{sep} //= '_';
	$args{ext} //= 'wav';
	my ($sep, $ext) = ($args{sep}, $args{ext});
	my ($dir, $basename) = ($args{dir}, $args{name});
	logpkg(__FILE__,__LINE__,'debug',"getver: dir $dir basename $basename sep $sep ext $ext");
	my %versions = ();
	for my $candidate ( candidates($dir) ) {
	#	logpkg(__FILE__,__LINE__,'debug',"candidate: $candidate");
	
		my( $match, $dummy, $num) = 
			( $candidate =~ m/^ ( $basename 
			   ($sep (\d+))? 
			   \.$ext ) 
			  $/x
			  ); # regex statement
		if ( $match ) { $versions{ $num || 'bare' } =  $match }
	}
	logpkg(__FILE__,__LINE__,'debug',sub{"get_version: " , Audio::Nama::json_out(\%versions)});
	%versions;
}

sub candidates {
	my $dir = shift;
	$dir =  File::Spec::Link->resolve_all( $dir );
	opendir my $wavdir, $dir or die "cannot open $dir: $!";
	my @candidates = readdir $wavdir;
	closedir $wavdir;
	@candidates = grep{ ! (-s join_path($dir, $_) == 44 ) } @candidates;
	#logpkg(__FILE__,__LINE__,'debug',join $/, @candidates);
	@candidates;
}

sub _targets {
	
	my %args = @_;

#	$Audio::Nama::debug2 and print "&targets\n";
	
		my %versions =  get_versions(%args);
		if ($versions{bare}) {  $versions{1} = $versions{bare}; 
			delete $versions{bare};
		}
	logpkg(__FILE__,__LINE__,'debug',sub{"\%versions\n================\n", json_out(\%versions)});
	\%versions;
}

sub _versions {  
#	$Audio::Nama::debug2 and print "&versions\n";
	my %args = @_;
	[ sort { $a <=> $b } keys %{ _targets(%args)} ]  
}
1;