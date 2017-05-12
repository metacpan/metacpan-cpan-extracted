
package Apache::MP3::L10N::de;  # German
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);

# Translators, in no particular order:
#  corion@informatik.uni-frankfurt.de

sub language_tag {__PACKAGE__->SUPER::language_tag}

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Alles abspielen",
 'Shuffle All' => 'Alles mischen',  # Stream all in random order
 'Stream All' => 'Alles streamen',

 # This one in just button text
 'Play Selected' => 'Auswahl abspielen',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "In dieser Demo ist das Streaming auf etwa [quant,_1,Sekunde,Sekunden] begrenzt.",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'CD Alben ([_1])',
 'Playlists ([_1])' => 'Listen ([_1])',        # .m3u files
 'Song List ([_1])' => 'Liste aller Lieder ([_1])', # i.e., file list


 'Playlist' => 'Liste',
 'Select' => 'Ausw&auml;hlen',

 'fetch'  => 'download',   # this file
 'stream' => 'abspielen',    # this file

 'Shuffle'  => 'Mischen',  # a subdirectory, recursively
 'Stream'   => 'Spielen',            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Start',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 wurde von ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => " programmiert.",


 'unknown' => 'unbekannt',

 # Metadata fields:
 'Artist' => "K&uuml;nstler",
 'Comment' => "Kommentar",
 'Duration' => "Dauer",
 'Filename' => "Datei",
 'Genre' => "Genre",
 'Album' => "Album",
 'Min' => "Min",
 'Track' => "Nr.",  # just the track number (not the track name)
 'Samplerate' => "Samplerate",
 'Bitrate' => "Bitrate",
 'Sec' => "Sec",
 'Seconds' => "Secunden",
 'Title' => "Titel",
 'Year' => "Jahr",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Kurzanleitung",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Alle Lieder abspielen",
 "= Shuffle-play all Songs" => "= Alle Lieder gemischt abspielen",
 "= Go to earlier directory" => "= Zu einem h&ouml;heren Verzeichnis wechseln",
 "= Stream contents" => "= Inhalt abspielen",
 "= Enter directory" => "= Zu Verzeichnis wechseln",
 "= Stream this song" => "= Dieses Lied abspielen",
 "= Select for streaming" => "= Dieses Lied ausw&auml;hlen",
 "= Download this song" => "= Dieses Lied downloaden",
 "= Stream this song" => "= Dieses Lied abspielen",
 "= Sort by field" => "= Nach dem Feld sortieren",

);

1;

