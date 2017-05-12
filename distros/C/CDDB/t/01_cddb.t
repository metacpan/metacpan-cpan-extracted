#!perl -w
# vim: filetype=perl
# 
# Copyright 1998-2020 Rocco Caputo <rcaputo@cpan.org>.  All rights
# reserved.  This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

use strict;
use CDDB;
use Test::More tests => 25;

BEGIN {
	select(STDOUT); $|=1;
};

my ($i, $result);

### test connecting

my $cddb = new CDDB(
	Host           => 'freedb.freedb.org',
	Port           => 8880,
	Submit_Address => 'test-submit@freedb.org',
	Debug          => 0,
);

ok(defined($cddb), "cddb object built okay");

### test genres

my @test_genres = sort qw(
	blues classical country data folk jazz misc newage reggae rock
	soundtrack
);

my @cddb_genres = sort $cddb->get_genres();

is_deeply(\@cddb_genres, \@test_genres, "got expected genres");

### helper sub: replace != tests with "not off by 5%"

sub not_near {
	my ($live, $test) = @_;
	return (abs($live-$test) > ($test * 0.05));
}

### sample TOC info for next few tests

# A CD table of contents is a list of tracks acquired from whatever Your
# Particular Operating System uses to manage CD-ROMs.  Often, it's some
# sort of API or ioctl() interface.  You're on your own here.
#
# Whatever you use should return the TOC as a list of whitespace-delimited
# records.  Each record should have three fields: the track number, the
# minutes offset of the track's beginning, the seconds offset of the track's
# beginning, and the leftover frames of the track's offset.  In other words,
#    track_number M S F  (where M S and F are defined in the CD-I spec.)
#
# Special information is indicated by these "virtual" track numbers:
#   999: lead-out information (same as regular track format)
#  1000: error reading TOC (minutes and seconds are unused; frame
#        contains a text message describing the error)
#
# Sample TOC information:

my @toc = (
	"1   0  3  71",  # track  1 starts at 00:03 and 71 frames
	"999 5 44   4",  # leadout  starts at 05:44 and  4 frames
);

### calculate CDDB ID

my ($id, $track_numbers, $track_lengths, $track_offsets, $total_seconds) =
	$cddb->calculate_id(@toc);

is($id, '03015501', 'calculated expected id');
is($total_seconds, 344, 'total time matches');

my @test_numbers = qw(001);
my @test_lengths = qw(05:41);
my @test_offsets = qw(296);

is_deeply($track_numbers, \@test_numbers, 'got expected track numbers');
is_deeply($track_lengths, \@test_lengths, 'got expected track lengths');
is_deeply($track_offsets, \@test_offsets, 'got expected track offsets');

### test looking up discs (one match)

my @discs = $cddb->get_discs($id, $track_offsets, $total_seconds);
my $disc_count = @discs;

my ($genre, $disc_id, $title) = @{$discs[0]};
is($disc_count, 2, 'got expected disc count');

ok(scalar(grep { $_->[0] eq 'misc' } @discs), 'got expected disc genre');

ok(scalar(grep { $_->[1] eq '03015501' } @discs), 'retrieved disc is expected id');

#is($discs[0][1], '03015501', 'retrieved disc is expected id');

like($discs[0][2], qr/freedb.*test/i, 'retrieved disc has expected title');

### test macro lookup

$cddb->disconnect();
my @other_discs = $cddb->get_discs_by_toc(@toc);

is_deeply($other_discs[0], $discs[0], 'disc by toc matches disc by id');

### test gathering disc details

$cddb->disconnect();
my $disc_info = $cddb->get_disc_details($genre, $disc_id);

# -><- uncomment if you'd like to see all the details
# foreach my $key (sort keys(%$disc_info)) {
#   my $val = $disc_info->{$key};
#   if (ref($val) eq 'ARRAY') {
#     print STDERR "\t$key: ", join('; ', @{$val}), "\n";
#   }
#   else {
#     print STDERR "\t$key: $val\n";
#   }
# }

is($disc_info->{'disc length'}, '344 seconds', 'disc is expected length');
is($disc_info->{'discid'}, $disc_id, 'disc id matches expectation');
is($disc_info->{'dtitle'}, $title, 'disc title matches expectation');
is_deeply($disc_info->{'offsets'}, $track_offsets, 'disc offsets match');

my @test_titles = ( "01-test" );

my $ok_tracks = 0;
$i = 0; $result = 'ok';
foreach my $detail_title (@{$disc_info->{'ttitles'}}) {
	my ($detail_norm, $test_norm) = (lc($detail_title), lc($test_titles[$i++]));

	next unless $detail_norm eq $test_norm;
	$ok_tracks++;
}

ok($ok_tracks >= @test_titles / 2, 'enough track titles match expectation');

### test fuzzy matches ("the freeside tests")

$id = 'a70cfb0c';
$total_seconds = 3323;
my @fuzzy_offsets = qw(
	0 20700 37275 57975 78825 102525 128700 148875 167100 184500 209250
	229500
);

@discs = $cddb->get_discs($id, \@fuzzy_offsets, $total_seconds);
ok(scalar(@discs), 'retrieved at least one disc');

($genre, $disc_id, $title) = @{$discs[0]};
ok((length $genre), 'retrieved disc has a genre');
ok((length($disc_id) == 8), 'retrieved disc id is proper length');
ok((length $title), 'retrieved disc has a title');

$id = 'c509b810';
$total_seconds = 2488;
@fuzzy_offsets = qw(
	0 11250 19125 33075 47850 58950 69075 80175 91500 105975 120225
	142425 152325 163200 167850 182775
);

@discs = $cddb->get_discs($id, \@fuzzy_offsets, $total_seconds);
ok(@discs > 1, 'retrieved discs from fuzzy offset');

### test CDDB submission
# <bekj> dngor It's not Polite to have tests fail when things are OK,
# Makes CPAN choke :(

SKIP: {
	unless ($cddb->can_submit_disc()) {
		skip(
			"Mail::Internet; Mail::Header; and MIME::QuotedPrint needed to submit",
			1
		);
	}

	eval {
		$cddb->submit_disc(
			Genre       => 'classical',
			Id          => 'b811a20c',

			# iso-8859-1 u with diaeresis (umlaut) for testing
			Artist      => "Vario\xDCs",
			DiscTitle   => 'Cartoon Classics',
			Offsets     => $disc_info->{'offsets'},
			TrackTitles => $disc_info->{'ttitles'},

			# odd revision for testing
			Revision    => 123,
		);

		pass("submitted a test disc; check your e-mail for confirmation");
	};

	# skip if SMTPHOSTS and default are bad
	if ($@) {
		skip($@, 1);
	}
};

### Test fetch-by-query.

my $query = (
	"cddb query d30ffd0e 14 150 19705 40130 59947 77417 96730 109345" .
	" 131927 149287 167635 185130 206002 229075 279870 4095"
);

@discs = $cddb->get_discs_by_query($query);
is($discs[0][0], 'rock', 'fetch-by-query retrieved expected genre');
is($discs[0][1], 'd30ffd0e', 'fetch-by-query retrieved expected id');

__END__

sub developing {
																				# CD-ROM interface
	$cd = new CDROM($device) or die $!;
																				# loads CD TOC
	@toc = $cd->toc();
																				# returs an array like:


	$toc[0] = [ # track 999 is the lead-out information
							# track 1000 indicates an error
							$track_number,
							# next three fields are CD-i MSF information, broken apart
							$offset_minutes, $offset_seconds, $offset_frames,
						];
																				# rips a track to a file
	$cd->rip(track => 2, file => '/tmp/track-2', format => 'wav') or die $!;
	$cd->rip(start => '12:34/0', stop => '15:57/0', file => '/tmp/msfrange',
					 format => 'wav'
					) or die $!;

	# synchronous methods wait for finish
	$cd->play(track => 1, method => synchronous);

	# asynch methods return right away
	$cd->play(track => 2, method => asynchronous);

	# returns what's going on ('playing', 'ripping', etc.)
	# used to poll the device during asynchronous operations?
	$cd->status();

	# fill out the interface
	$cd->stop();
	$cd->pause();
	$cd->resume();

	# whimsy.  virtually useless stuff, but why not?
	$cd->seek(track => 1);
	$cd->seek(offset => '12:34/0');
	$cd->seek(offset => '-0:34/0');
	$cd->seek(offset => '+0:34/0');
}
