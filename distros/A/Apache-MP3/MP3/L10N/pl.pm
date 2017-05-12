
package Apache::MP3::L10N::pl;  # Polish
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#   Piotr Klaban <makler@man.torun.pl>

sub encoding { "iso-8859-2" }   # Latin-2

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Odtwarzaj wszystko",
 'Shuffle All' => "Odtwarzaj losowo",  # Stream all in random order
 'Stream All' => "Odtwarzaj wszystko",

 # This one in just button text
 'Play Selected' => "Odtwarzaj wybrane",
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "W wersji demo, odtwarzanie jest ograniczone w przybli¿eniu do [quant,_1,sekundy,second]",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "Katalogi CD ([_1])",
 'Playlists ([_1])' => "Lista odtwarzania ([_1])",        # .m3u files
 'Song List ([_1])' => "Spis piosenek ([_1])", # i.e., file list


 'Playlist' => "Lista odtwarzania",
 'Select' => "Zaznacz",
 
 'fetch'  => "¶ci±gaj", # Send/download/save this file
 'stream' => "odtwarzaj",    # this file
 
 'Shuffle'  => "Pomieszaj",  # a subdirectory, recursively
 'Stream'   => "Odtwarzaj",            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => "Strona domowa",


 'unknown' => "nieznany",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Artysta",
 'Comment' => "Komentarz",
 'Duration' => "Czas trwania",
 'Filename' => "Nazwa pliku",
 'Genre' => "Gatunek",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "Min",  # abbreviation for "minutes"
 'Track' => "¦cie¿ka",  # just the track number (not the track name)
 'Sec' => "Sek",  # abbreviation for "seconds"
 'Seconds' => "Sekund",
 'Title' => "Tytu³",
 'Year' => "Rok",

 'Samplerate' => "Samplerate",
 'Bitrate' => "Bitrate",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "Pomoc w pigu³ce",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Odtwarzaj wszystkie piosenki",
 "= Shuffle-play all Songs" => "= Odtwarzaj w porz. losowym",
 "= Go to earlier directory" => "= Przejd¼ do katalogu wy¿ej",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Odtwarzaj zawarto¶æ",
 "= Enter directory" => "= Wejd¼ do katalogu",
 "= Stream this song" => "= Odtwarzaj ten utwór",
 "= Select for streaming" => "= Zaznacz odtwarzanie",
 "= Download this song" => "= ¦ci±gnij ten utwór",
 "= Stream this song" => "= Odtwarzaj ten utwór",
 "= Sort by field" => "= Uszereguj wg pola",
    # "sort" in the sense of ordering, not separating out.


 # The following three phrases are used for composing the sentence that
 # means, in your language, "Apache::MP3 was written by Lincoln D. Stein."
 #
 # For example, some laguages express this as
 #   "Apache::MP3 by Lincoln D. Stein is written."
 # In that case, _CREDITS_before_author would be "Apache::MP3 by",
 # _CREDITS_author would be "Lincoln. D. Stein", and
 # _CREDITS_after_author would be "was written."
 #
 # If you're not sure how to do this, then just tell me the translation
 # for the whole sentence, and I'll take care of it.

 "_CREDITS_before_author" => "Autorem Apache::MP3 jest ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",

);

1;

