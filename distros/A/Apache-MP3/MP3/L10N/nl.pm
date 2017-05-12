
package Apache::MP3::L10N::nl;  # Dutch
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  pieter@hypervision.be,
#  Maarten.Slaets@commerzbankib.com,
#  boumans@frg.eur.nl

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Speel alles",
 'Shuffle All' => 'Willekeurige volgorde',  # Stream all in random order
 'Stream All' => 'Speel alles',

 # This one in just button text
 'Play Selected' => 'Speel selectie',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "De afspeeltijd is beperkt tot ongeveer [quant,_1,seconde,seconden] in deze demonstratie.",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'CD Overzichten ([_1])',
 'Playlists ([_1])' => 'Afspeellijsten ([_1])',        # .m3u files
 'Song List ([_1])' => 'Songlijsten ([_1])', # i.e., file list


 'Playlist' => 'Afspeellijst',
 'Select' => 'Selecteer',

 'fetch'  => 'Download', # Send/download/save this file
 'stream' => 'Speel',    # this file

 'Shuffle'  => 'Willekeurige volgorde',  # a subdirectory, recursively
 'Stream'   => 'Speel',            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Home',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 is geschreven ",
 "_CREDITS_author"        => "door Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",

 'unknown' => '?',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Artiest",
 'Comment' => "Commentaar",
 'Duration' => "Duur",
 'Filename' => "Bestandsnaam",
 'Genre' => "Genre",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "Min",  # abbreviation for "minutes"
 'Track' => "Nr",  # just the track number (not the track name)
 'Sec' => "Sec",  # abbreviation for "seconds"
 'Seconds' => "Seconden",
 'Title' => "Titel",
 'Year' => "Jaar",

 'Samplerate' => "Samplerate",
 'Bitrate' => "Bitrate",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "Overzicht Help functies",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Speel alle nummers",
 "= Shuffle-play all Songs" => "= Speel alle nummers in willekeurige volgorde",
 "= Go to earlier directory" => "= Ga naar vorige directory",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Speel de inhoud",
 "= Enter directory" => "= Ga naar directory",
 "= Stream this song" => "= Speel dit nummer",
 "= Select for streaming" => "= Selecteer dit nummer",
 "= Download this song" => "= Download dit nummer",
 "= Stream this song" => "= Speel dit nummer",
 "= Sort by field" => "= Sorteer",
    # "sort" in the sense of ordering, not separating out.
);

1;

