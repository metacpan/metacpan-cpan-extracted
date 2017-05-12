
package Apache::MP3::L10N::sl;  #Slovenian
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  zoc@ziplip.com

sub encoding { "iso-8859-2" }   # Latin-2

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified


 # These are links as well as button text:
 'Play All' => "Predvajaj vse",
 'Shuffle All' => 'Nakljuèno predvajaj',  # Stream all in random order
 'Stream All' => 'Predvajaj vse',

 # This one in just button text
 'Play Selected' => 'Predvajaj oznaèeno',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "V tej predstavitvi je predvajanje omejeno na pribli¾no [quant,_1,sekunda,sekund/e/i].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'Seznam albumov ([_1])',
 'Playlists ([_1])' => 'Izbrane skladbe ([_1])',        # .m3u files
 'Song List ([_1])' => 'Seznam skladb ([_1])', # i.e., file list


 'Playlist' => 'Izbrane skladbe',
 'Select' => 'Izberi',

 'fetch'  => 'Prevzemi', # Send/download/save this file
 'stream' => 'Predvajaj',    # this file

 'Shuffle'  => 'Nakljuèno predvajaj',  # a subdirectory, recursively
 'Stream'   => 'Predvajaj',            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Prva stran',

 # Credits
 "_CREDITS_before_author" => "Avtor Apache::MP3 modula je ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'neznano',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Izvajalec",
 'Comment' => "Komentar",
 'Duration' => "Trajanje",
 'Filename' => "Ime datoteke",
 'Genre' => "Vrsta",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "Min",  # abbreviation for "minutes"
 'Track' => "©tevilka",  # just the track number (not the track name)
 'Sec' => "Sec",  # abbreviation for "seconds"
 'Seconds' => "Sekund",
 'Title' => "Naslov",
 'Year' => "Letnica",

 'Samplerate' => "Vzorèna hitrost",
 'Bitrate' => "Bitna hitrost",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Hitra pomoè",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Predvajaj vse skladbe",
 "= Shuffle-play all Songs" => "= Nakljuèno predvajaj vse skladbe",
 "= Go to earlier directory" => "= Pojdi nazaj na prej¹nji imenik",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Predvajaj vsebino",
 "= Enter directory" => "= Pojdi v imenik",
 "= Stream this song" => "= Predvajaj to skladbo",
 "= Select for streaming" => "= Izberi za predvajanje",
 "= Download this song" => "= Shrani to skladbo",
 "= Stream this song" => "= Predvajaj to skladbo",
 "= Sort by field" => "= Sortiraj po polju",
    # "sort" in the sense of ordering, not separating out.
);

1;

