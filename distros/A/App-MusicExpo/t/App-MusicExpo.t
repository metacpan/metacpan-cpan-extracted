#!/usr/bin/perl -wT
use v5.14;
use warnings;

use Test::More tests => 46;

use Scalar::Util qw/looks_like_number/;
use Storable qw/thaw/;

BEGIN { use_ok('App::MusicExpo'); }

my %data = (
	title       => 'Cellule',
	artist      => 'Silence',
	year        => 2005,
	album       => 'L\'autre endroit',
	tracknumber => 1,
	tracktotal  => 9,
	genre       => 'Electro'
);

my %handled = map { $_ => 1 } App::MusicExpo::extensions_handled;

sub test {
	my ($format, $sub, $file) = @_;
	my ($ext) = $file =~ /(\..+)$/;

  SKIP:
	{
		skip "Cannot handle $ext files (tag-reading module missing)", 9 unless $handled{$ext};
		  my $info = thaw $sub->($file);
		is $info->{format}, $format, "$format format";
		for (sort keys %data) {
			my $op = looks_like_number $data{$_} ? '==' : 'eq';
			cmp_ok $info->{$_}, $op, $data{$_}, "$format $_"
		}
		is $info->{file}, $file, "$format file";
	}
}

test FLAC   => \&App::MusicExpo::flacinfo,   'empty.flac';
test MP3    => \&App::MusicExpo::mp3info,    'empty3.mp3';
test Vorbis => \&App::MusicExpo::vorbisinfo, 'empty.ogg';
test AAC    => \&App::MusicExpo::mp4info,    'empty4.aac';
test Opus   => \&App::MusicExpo::opusinfo,   'empty2.opus';
