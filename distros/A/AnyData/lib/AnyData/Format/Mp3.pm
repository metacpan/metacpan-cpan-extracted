######################################################################
package AnyData::Format::Mp3;
######################################################################
#
# copyright 2000 by Jeff Zucker <jeff@vpservices.com>
# all rights reserved
#
######################################################################

=head1 NAME

AnyData::Format::Mp3 - tied hash and DBI access to Mp3 files

=head1 SYNOPSIS

 use AnyData;
 my $playlist = adTie( 'Passwd', ['c:/My Music/'] );
 while (my $song = each %$playlist){
    print $song->{artist} if $song->{genre} eq 'Reggae'
 }

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('playlist','Mp3,['c:/My Music'],'ad_catalog');
 my $playlist = $dbh->selectall_arrayref( qq{
     SELECT artist, title FROM playlist WHERE genre = 'Reggae'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This module provides a tied hash interface and a DBI/SQL interface to MP files.  It creates an in-memory database or hash from the Mp3 files themselves without actually creating a separate database file.  This means that the database is automatically updated just by moving files in or out of the directories.

Many mp3 (mpeg three) music files contain a header describing the song
name, artist, and other information about the music.

Simply choose 'Mp3' as the format and give a reference to an array of directories containing mp3 files.  Each file in those directories will become a record containing the fields:

 song
 artist
 album
 year
 genre
 filename
 filesize

This module is a submodule of the AnyData.pm and DBD::AnyData.pm modules.  Refer to their documentation for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut
use strict;
use warnings;
use AnyData::Format::Base;
use AnyData::Storage::FileSys;
use AnyData::Storage::File;
use vars qw( @ISA $VERSION);
@AnyData::Format::Mp3::ISA = qw( AnyData::Format::Base );

$VERSION = '0.12';

sub new {
    my $class = shift;
    my $self  = shift ||  {};
    #use Data::Dumper; die Dumper $self;
    my $dirs = $self->{dirs} || $self->{file_name} || $self->{recs};
    $self->{col_names} = 'song,artist,album,year,genre,filename,filesize';
    $self->{recs}   = 
    $self->{records}   = get_data( $dirs );
    return bless $self, $class;
}

sub storage_type { 'RAM'; }

sub read_fields {
    my $self = shift;
    my $thing = shift;
    return @$thing if ref $thing eq 'ARRAY';
    return split ',', $thing;
}

sub write_fields { die "WRITING NOT IMPLEMENTED FOR FORMAT Mp3"; }

sub get_data {
    my $dirs = shift;
    my $table = [];
    my @files = AnyData::Storage::FileSys::get_filename_parts(
	{},
        part => 'ext',
        re   => 'mp3',
        dirs => $dirs
    );
    for my $file_info(@files) {
        my $file = $file_info->[0];
        my $cols = get_mp3_tag($file) || next;
        my $filesize = -s $file;
        $filesize = sprintf "%1.fmb", $filesize/1000000;
        my @row  = (@$cols,$file,$filesize);
        push @$table, \@row;
        # 'file_name,path,ext,fullpath,size,'
        # 'name,artist,album,year,comment,genre';
    }
    return $table;
}

sub get_mp3_tag {
    my($file)   = shift;
    my $adf = AnyData::Storage::File->new;
    my(undef,$fh,undef) = $adf->open_local_file($file,'r');
    local $/ = '';
    $fh->seek(-128,2);
    my $str = <$fh> || '';
    $fh->close;
    return undef if !($str =~ /^TAG/);
    #$file = sprintf("%-255s",$file);
    #$str =~ s/^TAG(.*)/$file$1/;
    $str =~ s/^TAG(.*)/$1/;
    my $genre = $str;
    $genre =~ s/^.*(.)$/$1/g;
    $str =~ s/(.)$//g;
    $genre = unpack( 'C', $genre );
my @genres =("Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Eurotechno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise", "Alternative Rock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Show Tunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", "Swing", "Fast-Fusion", "Bebop", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", "Folklore", "Ballad", "Power Ballad", "Rhytmic Soul", "Freestyle", "Duet", "Punk Rock", "Drum Solo", "Acapella", "Euro-House", "Dance Hall", "Goa", "Drum & Bass", "Club-House", "Hardcore", "Terror", "Indie", "BritPop", "Negerpunk", "Polsk Punk", "Beat", "Christian Gangsta Rap", "Heavy Metal", "Black Metal", "Crossover", "Contemporary Christian", "Christian Rock", "Unknown");
    $genre = $genres[$genre] || '';
    my @cols = unpack 'A30 A30 A30 A4 A30', $str;
    my $comment = pop @cols;
    #print $comment;
    @cols = map{$_ || ''} @cols;
    push @cols, $genre;
    return \@cols;
}
1;
