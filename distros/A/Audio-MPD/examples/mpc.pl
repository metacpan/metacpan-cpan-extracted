#!/usr/bin/perl -w
#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use Encode;
use Audio::MPD;
use constant VERSION => '0.10.0';

my $x = Audio::MPD->new('localhost',6600);

# mpctime() - For getting the time in the same format as `mpc` writes it
sub mpctime
{
    my($psf,$tst) = split /:/, $x->{'time'};
    return sprintf("%d:%02d (%d%%)",
           ($psf / 60), # minutes so far
           ($psf % 60), # seconds - minutes so far
           $psf/($tst/100)); # Percent
}

sub help
{
  print "mpc version: ".VERSION."\n";
  print "mpc\t\t\t\tDisplays status\n";
  print "mpc add <filename>\t\tAdd a song to the current playlist\n";
  print "mpc del <playlist #>\t\tRemove a song from the current playlist\n";
  print "mpc play <number>\t\tStart playing a <number> (default: 1)\n";
  print "mpc next\t\t\tPlay the next song in the current playlist\n";
  print "mpc prev\t\t\tPlay the previous song in the current playlist\n";
  print "mpc pause\t\t\tPauses the currently playing song\n";
  print "mpc stop\t\t\tStop the currently playing song\n";
  print "mpc seek <0-100>\t\tSeeks to the position specified in seconds\n";
  print "mpc clear\t\t\tClears the current playlist\n";
  print "mpc shuffle\t\t\tShuffle the current playlist\n";
  print "mpc move <from> <to>\t\tMove song in playlist\n";
  print "mpc playlist\t\t\tPrint the current playlist\n";
  print "mpc listall [<song>]\t\tList all songs in the music dir\n";
  print "mpc ls [<dir>]\t\t\tList the contents of <dir>\n";
  print "mpc lsplaylists\t\t\tLists currently available playlists\n";
  print "mpc load <file>\t\t\tLoad <file> as a playlist\n";
  print "mpc save <file>\t\t\tSaves a playlist as <file>\n";
  print "mpc rm <file>\t\t\tRemoves a playlist\n";
  print "mpc volume [+-]<num>\t\tSets volume to <num> or adjusts by [+-]<num>\n";
  print "mpc repeat <on|off>\t\tToggle repeat mode, or specify state\n";
  print "mpc random <on|off>\t\tToggle random mode, or specify state\n";
  #print "mpc search <type> <queries>\tSearch for a song\n";
  print "mpc crossfade [sec]\t\tSet and display crossfade settings\n";
  print "mpc update\t\t\tScans music directory for updates\n";
  print "mpc version\t\t\tReports version of MPD\n";
  print "For more information about these and other options look man 1 mpc\n";
  exit;
}

# status() - For showing the current status
sub status
{
	$x->_get_status;
  my $repeat = ($x->{repeat} == 1 ? 'on ' : 'off'); # Let's show the repeat-status a bit nicer
  my $random = ($x->{random} == 1 ? 'on ' : 'off'); # And the same for random
  if($x->{state} eq 'play' || $x->{state} eq 'pause') { # If MPD is either playing or paused
    print decode_utf8($x->get_title)."\n";
    print "[".($x->{state} eq 'play' ? 'playing' : 'paused')."] #".($x->{song}+1)."/".$x->{playlistlength}."\t".mpctime."\n";
    print "volume: ".$x->{volume}."%   repeat: ".$repeat."  random: ".$random."\n";
  } elsif($x->{state} eq 'stop') { # If MPD is stopped, we don't show much
     print "volume: ".$x->{volume}."%   repeat: ".$repeat."  random: ".$random."\n";
  }
  exit;
}

sub play { $x->play($ARGV[1] ? ($ARGV[1]-1) : 0); status; }
sub stop { $x->stop(); status; }
sub pause { $x->pause(); status; }
sub add {
	if($ARGV[1] || $ARGV[1] eq '') {
		$x->add($ARGV[1]);
	} else {
		while(<STDIN>) {
			chomp;
			$x->add($_);
		}
	}
}
sub del {
	if(defined($ARGV[1])) {
		$x->delete($ARGV[1]-1);
	} else {
		help;
	}
}
sub next { $x->next(); status; }
sub prev { $x->prev(); status; }
sub seek {
	if(defined($ARGV[1])) {
		$x->seek($ARGV[1]); status;
	} else {
		help;
	}
}
sub clear { $x->clear(); }
sub shuffle { $x->shuffle(); }
sub move {
	if(defined($ARGV[1]) && defined($ARGV[2])) {
		$x->move($ARGV[1]-1,$ARGV[2]-1);
	} else {
		help;
	}
}
sub playlist
{
	my $playlist = $x->playlist;
	for(my $i = 0 ; $i < $x->{playlistlength} ; $i++)
	{
		my $title = ($playlist->[$i]{'Artist'} && $playlist->[$i]{'Title'} ? $playlist->[$i]{'Artist'}." - ".$playlist->[$i]{'Title'} : $playlist->[$i]{'file'});
		print "#".($i+1).") ".$title."\n";
	}
}
sub listall
{
	my @list = $x->listall($ARGV[1]);
	foreach my $item (@list)
	{
		print "$1\n" if $item =~ /(?:file):\s(.+)/;
	}
}
sub ls
{ 
	foreach my $tmp ($x->lsinfo($ARGV[1]))
	{
		my %hash = %{$tmp};
		if($hash{'directory'} || $hash{'file'})
		{
			print $hash{'directory'} || $hash{'file'};
			print "\n";
		}
	}
}
sub lsplaylists
{
	#while(my %hash = $x->nextinfo)
	foreach my $tmp ($x->lsinfo())
	{
		my %hash = %{$tmp};
		print $hash{'playlist'}."\n" if $hash{'playlist'};
	}
}
sub load {
	if(defined($ARGV[1])) {
		$x->load($ARGV[1]);
	} else {
		help;
	}
}
sub save {
	if(defined($ARGV[1])) {
		$x->save($ARGV[1]);
	} else {
		help;
	}
}
sub rm {
	if(defined($ARGV[1])) {
		$x->rm($ARGV[1]);
	} else {
		help;
	}
}
sub volume {
	if(defined($ARGV[1])) {
		$x->set_volume($ARGV[1]);
		status;
	} else {
		help;
	}
}
sub repeat {
	if(defined($ARGV[1])) {
		$x->set_repeat($ARGV[1]);
		status;
	} else {
		help;
	}
}
sub random {
	if(defined($ARGV[1])) {
		$x->set_random($ARGV[1]);
		status;
	} else {
		help;
	}
}
sub search
{
	die('No way!') if $ARGV[1] !~ /^(filename|artist|title|album)$/;
	my @list = $x->search($ARGV[1],$ARGV[2]);
	foreach my $hash (@list) 
	{
		my %song = %$hash;
		print $song{'file'}."\n";
	}
}
sub crossfade {
	if(defined($ARGV[1])) {
		$x->set_fade($ARGV[1]);
	} else {
		help;
	}
}
sub update { $x->updatedb(); }
sub version { print "mpd version: ".$x->{version}."\n"; }

# main() - Main sub
sub main
{
  status if !$ARGV[0];
  help if $ARGV[0] !~ /^(add|del|play|next|prev|pause|stop|seek|clear|shuffle|move|playlist|listall|ls|lsplaylists|load|save|rm|volume|repeat|random|search|crossfade|update|version)$/;
  goto &{ $ARGV[0] };
}

# Let's start!
main;
