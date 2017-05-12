
package Apache::MP3::L10N::sk;  # Slovak
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
# Radovan Hrabcak duffy@duffy.sk

sub encoding { "iso-8859-2" }   # Latin-2
  # Change as necessary if you use a different encoding

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified


 # These are links as well as button text:
 'Play All' => "Prehra» v¹etko",
 'Shuffle All' => 'Náhodné poradie',  # Stream all in random order
 'Stream All' => 'Prehra» v¹etko', # What's the difference between Strema All and Play All?

 # This one in just button text
 'Play Selected' => 'Prehra» vybrané',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "V tomto deme, je prehrávanie obmedzené; na pribli¾ne [quant,_1,sekundu,sekúnd].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'CD adresáre ([_1])',
 'Playlists ([_1])' => 'Playlisty (.m3u) ([_1])',        # .m3u files
 'Song List ([_1])' => 'Zoznam skladieb ([_1])', # i.e., file list


 'Playlist' => 'Playlist',
 'Select' => 'Vybra»',

 'fetch'  => 'ulo¾i»', # Send/download/save this file
 'stream' => 'hra»',    # this file

 'Shuffle'  => 'Náhodné poradie',  # a subdirectory, recursively
 'Stream'   => 'Prehra»',            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Na zaèiatok',

 # Credits
 "_CREDITS_before_author" => 'Apache::MP3 bol napísaný ',
 "_CREDITS_author"        => 'Lincolnom D. Steinom',
 "_CREDITS_after_author"  => ".",


 'unknown' => '?',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Interpret",
 'Comment' => "Poznámky",
 'Duration' => "Då¾ka",
 'Filename' => "Názov",
 'Genre' => "®áner",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "min.",  # abbreviation for "minutes"
 'Track' => "Skladba",  # just the track number (not the track name)
 'Sec' => "sek.",  # abbreviation for "seconds"
 'Seconds' => "Sekúnd",
 'Title' => "Názov",
 'Year' => "Rok",

 'Samplerate' => "Kvalita pôvodného zvuku",
 'Bitrate' => "Kvalita zvuku (bitrate)",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Prehµad nápovedy",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Prerha»; v¹etky skladby",
 "= Shuffle-play all Songs" => "= Prerha» v¹etky skladby v náhodnom poradí",
 "= Go to earlier directory" => "= O úroveò vy¹¹ie",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Prehra» obsah",
 "= Enter directory" => "= Do adresára",
 "= Stream this song" => "= Prehra» túto skladbu",
 "= Select for streaming" => "= Vybra» na prehratie",
 "= Download this song" => "= Ulo¾i» túto skladbu",
 "= Stream this song" => "= Prehra» túto skladbu",
 "= Sort by field" => "= Usporiada» podµa",
    # "sort" in the sense of ordering, not separating out.
);

1;

