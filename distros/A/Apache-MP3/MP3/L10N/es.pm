
package Apache::MP3::L10N::es;  # Spanish
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);

#  This translation by carenas2@alumni.gs.columbia.edu

sub language_tag {__PACKAGE__->SUPER::language_tag}

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Tocar todas",
 'Shuffle All' => 'Orden aleatorio',  # Stream all in random order
 'Stream All' => 'Tocar todas',

 # This one in just button text
 'Play Selected' => 'Tocar seleccionadas',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "En esta demostraci&oacute;n, tocar est&aacute; limitado a casi [quant,_1,segundo,segundos].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => 'Directorios de &aacute;lbumes ([_1])',
 'Playlists ([_1])' => 'Programas ([_1])',        # .m3u files
 'Song List ([_1])' => 'Lista de canciones ([_1])', # i.e., file list


 'Playlist' => 'Programa',
 'Select' => 'Seleccionar',
 
 'fetch'  => 'descargar',   # this file
 'stream' => 'tocar',    # this file
 
 'Shuffle'  => 'Orden aleatorio',  # a subdirectory, recursively
 'Stream'   => 'Tocar',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'Inicio',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 fue escrito por ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => '?',  # so much more concise than "desconocido"

 # Metadata fields:
 'Artist' => "Artista",
 'Comment' => "Notas",
 'Duration' => "Duraci&oacute;n",
 'Filename' => "Archivo",
 'Genre' => "G&eacute;nero",
 'Album' => "Album",
 'Min' => "Min",
 'Track' => "N&ordm;",  # just the track number (not the track name)
 'Samplerate' => "Frecuencia de muestreo",
 'Bitrate' => "Frecuencia de compresi&oacute;n",
 'Sec' => "Seg",
 'Seconds' => "Segundos",
 'Title' => "T&iacute;tulo",
 'Year' => "A&ntilde;o",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Resumen de Ayuda",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Tocar todas las canciones",
 "= Shuffle-play all Songs" => "= Poner en orden aleatorio y tocar todas las canciones",
 "= Go to earlier directory" => "= Ir a directorio superior",
 "= Stream contents" => "= Tocar contenido",
 "= Enter directory" => "= Entrar en directorio",
 "= Stream this song" => "= Tocar canci&oacute;n",
 "= Select for streaming" => "= Seleccionar canci&oacute;n",
 "= Download this song" => "= Descargar canci&oacute;n",
 "= Stream this song" => "= Tocar canci&oacute;n",
 "= Sort by field" => "= Ordenar por atributo",

);

1;

