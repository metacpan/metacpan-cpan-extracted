package App::MusicExpo;
use 5.014000;
use strict;
use warnings;

our $VERSION = '1.002001';

use HTML::Template::Compiled qw//;
use Memoize qw/memoize/;

use DB_File qw//;
use Encode qw/encode/;
use File::Basename qw/fileparse/;
use Fcntl qw/O_RDWR O_CREAT/;
use Getopt::Long;
use Storable qw/thaw freeze/;
use sort 'stable';

##################################################

my $default_template;

our $prefix='/music/';
our $cache='';
our $template='';

GetOptions (
	'template:s' => \$template,
	'prefix:s' => \$prefix,
	'cache:s' => \$cache,
);

sub flacinfo{
	my $file=$_[0];
	my $flac=Audio::FLAC::Header->new($file);

	freeze +{
		format => 'FLAC',
		title => $flac->tags('TITLE'),
		artist => $flac->tags('ARTIST'),
		year => $flac->tags('DATE'),
		album => $flac->tags('ALBUM'),
		tracknumber => $flac->tags('TRACKNUMBER'),
		tracktotal => $flac->tags('TRACKTOTAL'),
		genre => $flac->tags('GENRE'),
		file => scalar fileparse $file,
	}
}

sub mp3info{
	my $file=$_[0];
	my %tag = map { encode 'UTF-8', $_ } %{MP3::Info::get_mp3tag $file};
	my @trkn = split m#/#s, $tag{TRACKNUM} // '';

	freeze +{
		format => 'MP3',
		title => $tag{TITLE},
		artist => $tag{ARTIST},
		year => $tag{YEAR},
		album => $tag{ALBUM},
		tracknumber => $trkn[0],
		tracktotal => $trkn[1],
		genre => $tag{GENRE},
		file => scalar fileparse $file,
	}
}

sub vorbisinfo{
	my $file=$_[0];
	my $ogg=Ogg::Vorbis::Header::PurePerl->new($file);

	freeze +{
		format => 'Vorbis',
		title => scalar $ogg->comment('TITLE'),
		artist => scalar $ogg->comment('artist'),
		year => scalar $ogg->comment('DATE'),
		album => scalar $ogg->comment('ALBUM'),
		tracknumber => scalar $ogg->comment('TRACKNUMBER'),
		tracktotal => scalar $ogg->comment('TRACKTOTAL'),
		genre => scalar $ogg->comment('GENRE'),
		file => scalar fileparse $file,
	}
}

sub mp4_format ($){ ## no critic (ProhibitSubroutinePrototypes)
	my $encoding = $_[0];
	return 'AAC' if $encoding eq 'mp4a';
	return 'ALAC' if $encoding eq 'alac';
	"MP4-$encoding"
}

sub mp4info{
	my $file=$_[0];
	my %tag = map { ref() ? $_ : encode 'UTF-8', $_ } %{MP4::Info::get_mp4tag $file};
	my %info = %{MP4::Info::get_mp4info $file};

	freeze +{
		format => mp4_format $info{ENCODING},
		title => $tag{TITLE},
		artist => $tag{ARTIST},
		year => $tag{YEAR},
		album => $tag{ALBUM},
		tracknumber => $tag{TRACKNUM},
		tracktotal => ($tag{TRKN} ? $tag{TRKN}->[1] : undef),
		genre => $tag{GENRE},
		file => scalar fileparse $file,
	};
}

sub opusinfo {
	my $file = $_[0];
	my $of = Audio::Opusfile->new_from_file($file);
	my $tags = $of->tags;

	my %data = (
		format => 'Opus',
		title => $tags->query('TITLE'),
		artist => $tags->query('ARTIST'),
		year => $tags->query('DATE'),
		album => $tags->query('ALBUM'),
		tracknumber => $tags->query('TRACKNUMBER'),
		tracktotal => $tags->query('TRACKTOTAL'),
		genre => $tags->query('GENRE'),
		file => scalar fileparse $file
	);

	freeze \%data;
}

my @optional_modules = (
	[ 'Audio::FLAC::Header', \&flacinfo, '.flac' ],
	[ 'MP3::Info', \&mp3info, '.mp3' ],
	[ 'Ogg::Vorbis::Header::PurePerl', \&vorbisinfo, '.ogg', '.oga' ],
	[ 'MP4::Info', \&mp4info, '.mp4', '.aac', '.m4a' ],
	[ 'Audio::Opusfile', \&opusinfo, '.opus' ]
);

my %info;

for (@optional_modules) {
	my ($module, $coderef, @extensions_handled) = @$_;
	if (eval "require $module") {
		$info{$_} = $coderef for @extensions_handled
	}
}

unless (%info) {
	warn 'No tags-reading module detected. Install one of the following modules: ' . join ', ', map { $_->[0] } @optional_modules;
}

sub normalizer{
	"$_[0]|".(stat $_[0])[9]
}

sub make_fragment{ join '-', map { lc =~ y/a-z0-9/_/csr } @_ }

sub extensions_handled { keys %info }

sub run {
	if ($cache) {
		tie my %cache, 'DB_File', $cache, O_RDWR|O_CREAT, 0644; ## no critic (ProhibitTie)
		$info{$_} = memoize $info{$_}, INSTALL => undef, NORMALIZER => \&normalizer, LIST_CACHE => 'FAULT', SCALAR_CACHE => [HASH => \%cache] for keys %info;
	}

	my %files;
	for my $file (@ARGV) {
		my ($basename, undef, $suffix) = fileparse $file, keys %info;
		next unless $suffix;
		$files{$basename} //= [];
		push @{$files{$basename}}, thaw scalar $info{$suffix}->($file);
	}

	my $ht=HTML::Template::Compiled->new(
		default_escape => 'HTML',
		global_vars => 2,
		$template eq '' ? (scalarref => \$default_template) : (filename => $template),
	);

	my @files;
	for (sort keys %files) {
		my @versions = @{$files{$_}};
		my %entry = (formats => [], map { $_ => '?' } qw/title artist year album tracknumber tracktotal genre/);
		for my $ver (@versions) {
			push @{$entry{formats}}, {format => $ver->{format}, file => $ver->{file}};
			for my $key (keys %$ver) {
				$entry{$key} = $ver->{$key} if $ver->{$key} && $ver->{$key} ne '?';
			}
		}
		delete $entry{$_} for qw/format file/;
		$entry{fragment} = make_fragment @entry{qw/artist title/};
		push @files, \%entry
	}

	@files = sort { $a->{title} cmp $b->{title} } @files;
	$ht->param(files => \@files, prefix => $prefix);
	print $ht->output; ## no critic (RequireCheckedSyscalls)
}

$default_template = <<'HTML';
<!DOCTYPE html>
<title>Music</title>
<meta charset="utf-8">
<link rel="stylesheet" href="musicexpo.css">
<script async defer type="application/javascript" src="player.js"></script>

<div id="player"></div>

<table border>
<thead>
<tr><th>Title<th>Artist<th>Album<th>Genre<th>Track<th>Year<th>Type
<tbody><tmpl_loop files>
<tr><td class="title"><a href="#<tmpl_var fragment>" data-hash="#<tmpl_var fragment>"><tmpl_var title></a><td class="artist"><tmpl_var artist><td class="album"><tmpl_var album><td class="genre"><tmpl_var genre><td class="track"><tmpl_var tracknumber>/<tmpl_var tracktotal><td class="year"><tmpl_var year><td class="formats"><tmpl_loop formats><a href="<tmpl_var ...prefix><tmpl_var ESCAPE=URL file>"><tmpl_var format></a> </tmpl_loop></tmpl_loop>
</table>
HTML

1;

__END__

=encoding utf-8

=head1 NAME

App::MusicExpo - script which generates a HTML table of music tags

=head1 SYNOPSIS

  use App::MusicExpo;
  App::MusicExpo->run;

=head1 DESCRIPTION

App::MusicExpo creates a HTML table from a list of songs.

The default template looks like:

    | Title   | Artist  | Album           | Genre   | Track | Year | Type |
    |---------+---------+-----------------+---------+-------+------+------|
    | Cellule | Silence | L'autre endroit | Electro | 01/09 | 2005 | FLAC |

where the type is a download link. If you have multiple files with the same
basename (such as C<cellule.flac> and C<cellule.ogg>), they will be treated
as two versions of the same file, so a row will be created with two download
links, one for each format.

=head1 OPTIONS

=over

=item B<--template> I<template>

Path to the HTML::Template::Compiled template used for generating the music table. If '' (empty), uses the default format. Is empty by default.

=item B<--prefix> I<prefix>

Prefix for download links. Defaults to '/music/'.

=item B<--cache> I<filename>

Path to the cache file. Created if it does not exist. If '' (empty), disables caching. Is empty by default.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
