#---------------------------------------------------------------------------
package Apache::MP3::L10N::it;  # Italian
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
# Stefano Rodighiero, larsen@perlmonk.org
# Andrea Maestrutti, maestrutti@friuli.com

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Suona tutti i brani",
 'Shuffle All' => "Suona tutti i brani in ordine casuale",  # Stream all in random order
 'Stream All' => "Suona tutti i brani",

 # This one in just button text
 'Play Selected' => "Suona i brani selezionati",
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
	=> "In questa demo, la riproduzione dei brani è limitata a [quant,_1,secondo,secondi] circa.",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "Elenco degli album ([_1])",
 'Playlists ([_1])' => "Elenchi di brani da suonare([_1])",        # .m3u files
 'Song List ([_1])' => "Elenco dei brani ([_1])", # i.e., file list


 'Playlist' => "Elenco dei brani da suonare",
 'Select' => "Seleziona",
 
 'fetch'  => "scarica", # Send/download/save this file
 'stream' => "suona",    # this file
 
 'Shuffle'  => "Suona in ordine casuale",  # a subdirectory, recursively
 'Stream'   => "Suona",            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => "Home",


 'unknown' => "sconosciuto",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Artista",
 'Comment' => "Commento",
 'Duration' => "Durata",
 'Filename' => "Nome del file",
 'Genre' => "Genere",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "Min",  # abbreviation for "minutes"
 'Track' => "Traccia",  # just the track number (not the track name)
 'Sec' => "Sec",  # abbreviation for "seconds"
 'Seconds' => "Secondi",
 'Title' => "Titolo",
 'Year' => "Anno",

 'Samplerate' => "Frequenza di campionamento",
 'Bitrate' => "Qualità audio",

 # Now the stuff for the help page:

 'Quick Help Summary' => "Riepilogo funzionalità",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Suona tutti i brani",
 "= Shuffle-play all Songs" => "= Suona tutti i brani in ordine casuale",
 "= Go to earlier directory" => "= Vai alla cartella superiore",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Suona i brani nella cartella",
 "= Enter directory" => "= Apri la cartella",
 "= Stream this song" => "= Suona il brano",
 "= Select for streaming" => "= Seleziona i brani da suonare",
 "= Download this song" => "= Scarica il brano",
 "= Stream this song" => "= Suona il brano",
 "= Sort by field" => "= Ordina per campo",
    # "sort" in the sense of ordering, not separating out.

 "_CREDITS_before_author" => "Apache::MP3 è stato scritto da ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",

);

1;

