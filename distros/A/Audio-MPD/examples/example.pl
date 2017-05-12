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
use Data::Dumper;
use Audio::MPD;

### NOTE! ###
# THIS SCRIPT DOES NOT CONTAIN ERRORHANDLING, AND MAY THEREFORE FAIL ON
# CERTAIN ACTIONS
############

#my $x = MPD->new('localhost',2100); # Do this for specifing server and/or port.
my $x = Audio::MPD->new('localhost', 6601);

print "Example: Shows Audio::MPD used to write mpc-like output\n\n";
print($x->get_title,"\n");
print("[".$x->{state}."] #".($x->{song} || 'n/a')."/".$x->{playlistlength}."   ".$x->get_time_format."\n");
print("volume: ".$x->{volume}."%  repeat: ".$x->{repeat}."   random: ".$x->{random}."\n");

print "\n\nExample: Shows list of all files, directories and playlists in a specific directory.\n";



my @array = $x->listallinfo('Misc');
foreach(@array)
{
	print $_->{'file'} || $_->{'directory'} || $_->{'playlist'},"\n";
}



print "\n\nExample: Shows how to get information from the playlist. \@playlist is a reference, so don't change it :)\n\n";
my $playlist = $x->playlist;
print "Song 1 filename: ".$playlist->[1]{'file'}."\n";
print "Song 2 time: ".$playlist->[2]{'Time'}." seconds\n";

my $foo = $x->get_time_info;
print "Current song info: \n";
print "Minutes: ".$foo->{'minutes_so_far'}."\n";
print "Seconds: ".$foo->{'seconds_so_far'}."\n";
