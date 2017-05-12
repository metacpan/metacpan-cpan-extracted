package Apache::MP3::L10N::hr;  # Croatian
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}


# Translators: ivans@ordecon.com

sub encoding { "windows-1250" } # Central European MSWindows

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Sviraj sve",
 'Shuffle All' => 'Sviraj sve sluèajnim redosljedom',  # Stream all in random order
 'Stream All' => 'Sviraj sve',

 # This one in just button text
 'Play Selected' => 'Sviraj oznaèeno',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "U ovoj demonstraciji, sviranje je ogranièeno na otprilike [quant,_1,sekundu,sekunda].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => 'Popis albuma ([_1])',
 'Playlists ([_1])' => 'Liste za sviranje ([_1])',
 'Song List ([_1])' => 'Popis pjesama ([_1])',

 'Playlist' => 'Popis sviranja',
 'Select' => 'Izaberi',
 
 'fetch'  => 'Preuzmi',   # this file
 'stream' => 'Sviraj',    # this file
 
 'Shuffle'  => 'Sviraj sluèajnim redosljedom',  # a subdirectory, recursively
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

 "= Stream all songs" => "= Sviraj sve pjesme",
 "= Shuffle-play all Songs" => "= Sviraj sve pjesme sluèajnim redosljedom",
 "= Go to earlier directory" => "= Prijeði na prethodni direktorij",
 "= Stream contents" => "= Sviraj sadržaj",
 "= Enter directory" => "= Uði u direktorij",
 "= Stream this song" => "= Sviraj ovu pjesmu",
 "= Select for streaming" => "= Oznaèi pjesmu za sviranje",
 "= Download this song" => "= Preuzmi ovu pjesmu",
 "= Stream this song" => "= Sviraj ovu pjesmu",
 "= Sort by field" => "= Poredaj po polju",

);

1;

