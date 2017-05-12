package Apache::MP3::L10N::ca;  # Catalan
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  lou@visca.com

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Escoltar tot",
 'Shuffle All' => 'Barrejar tot',  # Stream all in random order
 'Stream All' => 'Escoltar tot',

 # This one in just button text
 'Play Selected' => 'Escoltar les seleccions',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "En aquesta demostraci&oacute;, la reproducci&oacute; en temps real es limita a [quant,_1,segon,segons].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "Directoris dels CD's ([_1])",
 'Playlists ([_1])' => 'Programes ([_1])',        # .m3u files
 'Song List ([_1])' => 'Llista de can&ccedil;ons ([_1])', # i.e., file list


 'Playlist' => 'Programa',
 'Select' => 'Seleccionar',
 
 'fetch'  => 'baixar',   # this file
 'stream' => 'escoltar',    # this file
 
 'Shuffle'  => 'Barrejar',  # a subdirectory, recursively
 'Stream'   => 'Escoltar',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'P&agrave;gina inicial',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 &eacute;s de ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'desconegut',

 # Metadata fields:
 'Artist' => "Artista",
 'Comment' => "Comentaris",
 'Duration' => "Llargada",
 'Filename' => "Nom d'arxiu",
 'Genre' => "G&egrave;nere",
 'Album' => "&Agrave;lbum",
 'Min' => "Minuts",
 'Track' => "N&uacute;m;",  # just the track number (not the track name)
 'Samplerate' => "Velocitat de conversi&oacute; per canal",
 'Bitrate' => "Kilobits per segon",
 'Sec' => "Segon",
 'Seconds' => "Segons",
 'Title' => "T&iacute;tol",
 'Year' => "Any",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Resum de funcions",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Escoltar totes les can&ccedil;ons",
 "= Shuffle-play all Songs" => "= Barrejar i escoltar totes les can&ccedil;ons",
 "= Go to earlier directory" => "= Anar al directori anterior",
 "= Stream contents" => "= Escoltar el contingut",
 "= Enter directory" => "= Entrar el directori",
 "= Stream this song" => "= Escoltar aquesta can&ccedil;&oacute;",
 "= Select for streaming" => "= Seleccionar aquesta can&ccedil;&oacute;",
 "= Download this song" => "= Baixar aquesta can&ccedil;&oacute;",
 "= Stream this song" => "= Escoltar aquesta can&ccedil;&oacute;",
 "= Sort by field" => "= Ordenar per atribut",

);

1;

