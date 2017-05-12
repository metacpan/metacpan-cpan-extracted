package Apache::MP3::L10N::ms;  # Malay
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Shanai <shanai@tm.net.my>

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Main Semua",
 'Shuffle All' => 'Main secara Rawak',  # Stream all in random order
 'Stream All' => 'Main Semua',

 # This one in just button text
 'Play Selected' => 'Main yang dipilih',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "Dalam demo ini, mainan hanya dihadkan kepada [quant,_1,saat,saat].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'Direktori CD ([_1])',
 'Playlists ([_1])' => 'Senarai Mainan ([_1])',        # .m3u files
 'Song List ([_1])' => 'Senarai Lagu ([_1])', # i.e., file list


 'Playlist' => 'Senarai Mainan',
 'Select' => 'Pilih',

 'fetch'  => 'pindah terima',   # this file
 'stream' => 'main',    # this file

 'Shuffle'  => 'Rawak',  # a subdirectory, recursively
 'Stream'   => 'Main',            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Laman Utama',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 dihasilkan ",
 "_CREDITS_author"        => "oleh Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",

 'unknown' => 'tidak diketahui',

 # Metadata fields:
 'Artist' => "Artis",
 'Comment' => "Nota",
 'Duration' => "Tempoh",
 'Filename' => "Nama Fail",
 'Genre' => "Genre",
 'Album' => "Album",
 'Min' => "Min",
 'Track' => "Track",  # just the track number (not the track name)
 'Samplerate' => "Samplerate",
 'Bitrate' => "Bitrate",
 'Sec' => "Saat",
 'Seconds' => "Saat",
 'Title' => "Tajuk",
 'Year' => "Tahun",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Bantuan Ringkas",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Mainkan semua lagu",
 "= Shuffle-play all Songs" => "= Mainkan semua lagu secara rawak",
 "= Go to earlier directory" => "= Pergi ke direktori awal",
 "= Stream contents" => "= Mainkan kandungan",
 "= Enter directory" => "= Masuk direktori",
 "= Stream this song" => "= Mainkan lagu ini",
 "= Select for streaming" => "= Pilih untuk dimainkan",
 "= Download this song" => "= Pindah terima lagu ini",
 "= Stream this song" => "= Mainkan lagu ini",
 "= Sort by field" => "= Isih mengikut medan",

);

1;

