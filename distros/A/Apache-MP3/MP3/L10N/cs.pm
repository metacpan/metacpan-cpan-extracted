
package Apache::MP3::L10N::cs;  # Czech
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Rado Hrabcak duffy@duffy.sk

sub encoding { "iso-8859-2" }   # Latin-2
  # Change as necessary if you use a different encoding

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified


 # These are links as well as button text:
 'Play All' => "Prohrát v¹echno",
 'Shuffle All' => 'Prohrát v náhodném poøadí',  # Stream all in random order
 'Stream All' => 'Prohrát v¹echno',

 # This one in just button text
 'Play Selected' => 'Prohrát vybrané',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "V tomto demu je prohrávaní omezeno na [quant,_1,sekundu,sekund].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'CD adresáøe ([_1])',
 'Playlists ([_1])' => 'Playlisty ([_1])',        # .m3u files
 'Song List ([_1])' => 'Seznam skladeb ([_1])', # i.e., file list


 'Playlist' => 'Playlist',
 'Select' => 'Vybrat',

 'fetch'  => 'ulo¾it', # Send/download/save this file
 'stream' => 'prohrát',    # this file

 'Shuffle'  => 'Náhodné poøadí',  # a subdirectory, recursively
 'Stream'   => 'Prohrát',            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Na zaèátek',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 byl napsan ",
 "_CREDITS_author"        => "Lincolnem D. Steinem", 
 "_CREDITS_after_author"  => ".",

 # Let me know if this word order isn't good for your language.


 'unknown' => '?',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Interpret",
 'Comment' => "Poznámky",
 'Duration' => "Délka",
 'Filename' => "Název",
 'Genre' => "®áner",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "min.",  # abbreviation for "minutes"
 'Track' => "Skladba",  # just the track number (not the track name)
 'Sec' => "sek.",  # abbreviation for "seconds"
 'Seconds' => "Sekund",
 'Title' => "Název",
 'Year' => "Rok",

 'Samplerate' => "Kvalita pùvodního zvuku",
 'Bitrate' => "Kvalita zvuku (bitrate)",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "Pøehled nápovìdy",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Prohrát v¹echny skladby",
 "= Shuffle-play all Songs" => "= Prohrát v¹echny skladby v náhodném poøadí",
 "= Go to earlier directory" => "= O ùroveò vý¹",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Prohrát obsah",
 "= Enter directory" => "= Do adresáøe",
 "= Stream this song" => "= Prohrát tuto skladbu",
 "= Select for streaming" => "= Vybrát pro prohráti",
 "= Download this song" => "= Ulo¾it tuto skladbu",
 "= Stream this song" => "= Prohrát tuto skladbu",
 "= Sort by field" => "= Seøadit dle",
    # "sort" in the sense of ordering, not separating out.
);

1;

