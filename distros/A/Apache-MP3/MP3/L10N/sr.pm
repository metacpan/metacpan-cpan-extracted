package Apache::MP3::L10N::sr;  # Serbian (in Roman script)
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}


# Translators: zoc@ziplip.com

sub encoding { "iso-8859-2" } # Latin-2

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Sviraj sve",
 'Shuffle All' => 'Sviraj sve sluèajnim redosledom',  # Stream all in random order
 'Stream All' => 'Sviraj sve',

 # This one in just button text
 'Play Selected' => 'Sviraj izabrano',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "U ovoj demonstraciji, sviranje je ogranièeno na otprilike [quant,_1,sekundu,sekunda].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => 'Popis albuma ([_1])',
 'Playlists ([_1])' => 'Liste za sviranje ([_1])',
 'Song List ([_1])' => 'Popis pesama ([_1])',

 'Playlist' => 'Popis pesama',
 'Select' => 'Izaberi',
 
 'fetch'  => 'Dobavi',   # this file
 'stream' => 'Sviraj',    # this file
 
 'Shuffle'  => 'Sviraj sluèajnim redosledom',  # a subdirectory, recursively
 'Stream'   => 'Sviraj',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'Poèetna stranica',

 # Credits
 "_CREDITS_before_author" => "Autor Apache::MP3 modula je ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'nepoznato',

 # Metadata fields:
 'Artist' => "Izvoðaè",
 'Comment' => "Komentar",
 'Duration' => "Trajanje",
 'Filename' => "Ime datoteke",
 'Genre' => "Vrsta",
 'Album' => "Album",
 'Min' => "Min",
 'Track' => "Broj",  # just the track number (not the track name)
 'Samplerate' => "Velièina uzorka",
 'Bitrate' => "Kolièina bitova",
 'Sec' => "Sek",
 'Seconds' => "Sekunde",
 'Title' => "Naslov",
 'Year' => "Godina",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Skraæene upute",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Sviraj sve pesme",
 "= Shuffle-play all Songs" => "= Sviraj sve pesme sluèajnim redosledom",
 "= Go to earlier directory" => "= Preði na prethodni direktorij",
 "= Stream contents" => "= Sviraj sadr¾aj",
 "= Enter directory" => "= Uði u direktorij",
 "= Stream this song" => "= Sviraj ovu pesmu",
 "= Select for streaming" => "= Izaberi pesmu za sviranje",
 "= Download this song" => "= Preuzmi ovu pesmu",
 "= Stream this song" => "= Sviraj ovu pesmu",
 "= Sort by field" => "= Poreðaj po polju",

);

1;

