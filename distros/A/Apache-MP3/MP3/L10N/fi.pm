
#---------------------------------------------------------------------------
package Apache::MP3::L10N::fi;  # Finnish (suomi)
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  jhi@iki.fi

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Soita kaikki",
 'Shuffle All' => "Sekoita kaikki",  # Stream all in random order
 'Stream All' => "Kuuntele kaikki",

 # This one in just button text
 'Play Selected' => "Soita valitut",
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "Tässä demossa kuuntelu on rajoitettu [quant,_1,sekuntiin].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "CD-levyt ([_1])",
 'Playlists ([_1])' => "Soittolistat ([_1])",        # .m3u files
 'Song List ([_1])' => "Kappalelistat ([_1])", # i.e., file list


 'Playlist' => "Soittolista",
 'Select' => "Valitse",
 
 'fetch'  => "hae", # Send/download/save this file
 'stream' => "soita",    # this file
 
 'Shuffle'  => "Sekoita",  # a subdirectory, recursively
 'Stream'   => "Soita",    # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => "Kotisivu",


 'unknown' => "?",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "artisti",
 'Comment' => "huomioita",
 'Duration' => "kesto",
 'Filename' => "tiedosto",
 'Genre' => "tyyli",  # i.e., what kind of music
 'Album' => "albumi",
 'Min' => "min",  # abbreviation for "minutes"
 'Track' => "nro",  # just the track number (not the track name)
 'Sec' => "s",  # abbreviation for "seconds"
 'Seconds' => "sekuntia",
 'Title' => "nimi",
 'Year' => "vuosi",

 'Samplerate' => "Alkuperäinen äänenlaatu",
 'Bitrate' => "Soittoäänenelaatu",

 # Now the stuff for the help page:

 'Quick Help Summary' => "Pika-apu",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Kuuntele kappaleet",
 "= Shuffle-play all Songs" => "= Sekoita kappaleet",
 "= Go to earlier directory" => "= Edellinen kansio",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Kuuntele sisältö",
 "= Enter directory" => "= Mene hakemistoon",
 "= Stream this song" => "= Kuuntele kappale",
 "= Select for streaming" => "= Valitse kuunneltavaksi",
 "= Download this song" => "= Tallenna kappale",
 "= Stream this song" => "= Kuuntele kappale",
 "= Sort by field" => "= Järjestä kentän mukaan",
    # "sort" in the sense of ordering, not separating out.

 "_CREDITS_before_author" => "Apache::MP3:n tekijä ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",

);

1;

