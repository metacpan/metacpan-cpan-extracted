#!/usr/bin/perl

# --------------------------------------------------------------------------
# This program was used, along with the music_info.csv file, to populate the
# database with the information in the following tables: album_song, artist,
# song.  I just made up the information in the other tables.
# --------------------------------------------------------------------------

use warnings;
use strict;

use Text::CSV_XS;
use File::Spec;

use lib '!!- path_projects_dir -!!/Example/common-modules';
use lib '!!- path_projects_dir -!!/Example/applications/example_1';

use example_1;
my $webapp = example_1->new(
    PARAMS => {
        'framework_app_dir' => '!!- path_projects_dir -!!/Example/applications/example_1',
    }
);

my $config = $webapp->conf->context;

CDBI::Example::example->setup_tables;

my $csv = Text::CSV_XS->new();

my $status;
my @columns;

my @alldata = ();

while ( my $line = <> ) {

    $status = $csv->parse($line);
    @columns = $csv->fields();

    my %data = ();

    $data{artist}        = $columns[0] || $alldata[$#alldata]->{artist};
    $data{album}         = $columns[1] || $alldata[$#alldata]->{album};
    $data{album_year}    = $columns[2] || $alldata[$#alldata]->{album_year};
    $data{song_name}     = $columns[3];
    $data{song_tracknum} = $columns[4];

    push @alldata, \%data;
}

# a representative @alldata is shown following the __END__, below

foreach my $row ( @alldata ) {

    my $artist = CDBI::Example::example::Artist->find_or_create
	({
	    artist_name => $row->{artist}
	});

    my $album = CDBI::Example::example::Album->find_or_create
	({
	    album_name => $row->{album},
	    artist_id  => $artist->artist_id,
	    album_year => $row->{album_year},
	});

    my $song = CDBI::Example::example::Song->find_or_create
	({
	    song_name => $row->{song_name},
	    artist_id => $artist->artist_id,
	});

    my $album_song = CDBI::Example::example::AlbumSong->find_or_create
	({
	    album_id  => $album->album_id,
	    song_id   => $song->song_id,
	    track_num => $row->{song_tracknum},
	});
}

exit 0;

__END__

# --------------------------------------------------------------------------
# Note that this program would recreate the following array given albums.csv
# --------------------------------------------------------------------------

@alldata = (
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Trip Like I Do',
               'song_tracknum' => '1',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Busy Child',
               'song_tracknum' => '2',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Cherry Twist',
               'song_tracknum' => '3',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'High Roller',
               'song_tracknum' => '4',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Comin\' Back',
               'song_tracknum' => '5',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Keep Hope Alive',
               'song_tracknum' => '6',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Vapor Trail',
               'song_tracknum' => '7',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'She\'s My Pusher',
               'song_tracknum' => '8',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Jaded',
               'song_tracknum' => '9',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Vegas',
               'song_name' => 'Bad Stone',
               'song_tracknum' => '10',
               'album_year' => '1997'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'PHD',
               'song_tracknum' => '1',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Wild, Sweet And Cool',
               'song_tracknum' => '2',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Roll It Up',
               'song_tracknum' => '3',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Murder',
               'song_tracknum' => '4',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Name of the Game',
               'song_tracknum' => '5',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'The Winner',
               'song_tracknum' => '6',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Ready For Action',
               'song_tracknum' => '7',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Ten Miles Back',
               'song_tracknum' => '8',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Over The Line',
               'song_tracknum' => '9',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Blowout',
               'song_tracknum' => '10',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Tweekend',
               'song_name' => 'Tough Guy / Name of the Game',
               'song_tracknum' => '11',
               'album_year' => '2001'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Starting Over',
               'song_tracknum' => '1',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Born Too Slow',
               'song_tracknum' => '2',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'True Grit',
               'song_tracknum' => '3',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'The American Way',
               'song_tracknum' => '4',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'I Know It\'s You',
               'song_tracknum' => '5',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Realizer',
               'song_tracknum' => '6',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Broken Glass',
               'song_tracknum' => '7',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Weapons Of Mass Distortion',
               'song_tracknum' => '8',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Bound Too Long',
               'song_tracknum' => '9',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Acetone',
               'song_tracknum' => '10',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'High And Low',
               'song_tracknum' => '11',
               'album_year' => '2004'
             },
             {
               'artist' => 'Crystal Method',
               'album' => 'Legion Of Boom',
               'song_name' => 'Wide Open',
               'song_tracknum' => '12',
               'album_year' => '2004'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'So Easy',
               'song_tracknum' => '1',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'Eple',
               'song_tracknum' => '2',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'Sparks',
               'song_tracknum' => '3',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'In Space',
               'song_tracknum' => '4',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'Poor Leno',
               'song_tracknum' => '5',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'A Higher Place',
               'song_tracknum' => '6',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'Royksopp\'s Night Out',
               'song_tracknum' => '7',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'Remind Me',
               'song_tracknum' => '8',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => 'She\'s So',
               'song_tracknum' => '9',
               'album_year' => '2002'
             },
             {
               'artist' => 'Royksopp',
               'album' => 'Melody A.M.',
               'song_name' => '40 Years Back / Come',
               'song_tracknum' => '10',
               'album_year' => '2002'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Brakhage',
               'song_tracknum' => '1',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Miss Modular',
               'song_tracknum' => '2',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'The Flower Called Nowhere',
               'song_tracknum' => '3',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Diagonals',
               'song_tracknum' => '4',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Prisoner of Mars',
               'song_tracknum' => '5',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Rainbo Conversation',
               'song_tracknum' => '6',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Refractions In The Plastic Pulse',
               'song_tracknum' => '7',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Parsec',
               'song_tracknum' => '8',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Ticker-Tape Of The Unconscious',
               'song_tracknum' => '9',
               'album_year' => '1997'
             },
             {
               'artist' => 'Stereolab',
               'album' => 'Dots And Loops',
               'song_name' => 'Contronatura',
               'song_tracknum' => '10',
               'album_year' => '1997'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'The Ring',
               'song_tracknum' => '1',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Microjam',
               'song_tracknum' => '2',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Freezone',
               'song_tracknum' => '3',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Biscuit Face',
               'song_tracknum' => '4',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Beveled Egde',
               'song_tracknum' => '5',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Compound',
               'song_tracknum' => '6',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Spin Out',
               'song_tracknum' => '7',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'One At A Day',
               'song_tracknum' => '8',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Manaka',
               'song_tracknum' => '9',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Different Bend',
               'song_tracknum' => '10',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Double Fine Zone',
               'song_name' => 'Further Down The Road',
               'song_tracknum' => '11',
               'album_year' => '1999'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Pressure',
               'song_tracknum' => '1',
               'album_year' => '1994'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Subway',
               'song_tracknum' => '2',
               'album_year' => '1994'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Ping Pong',
               'song_tracknum' => '3',
               'album_year' => '1994'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Voices Of The Earth',
               'song_tracknum' => '4',
               'album_year' => '1994'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Floatilla',
               'song_tracknum' => '5',
               'album_year' => '1994'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Q11',
               'song_tracknum' => '6',
               'album_year' => '1994'
             },
             {
               'artist' => 'Spacetime Continuum',
               'album' => 'Sea Biscuit',
               'song_name' => 'Low Frequency Inversion Field',
               'song_tracknum' => '7',
               'album_year' => '1994'
             }
	);



