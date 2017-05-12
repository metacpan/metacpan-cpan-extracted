
package Apache::MP3::L10N::is;  # Icelandic
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Kristinn Gylfason, kristgy@ieee.org
#  Arnar M. Hrafnkelsson, addi@umich.edu

sub encoding { "iso-8859-1" }   # Latin-1
  # Change as necessary if you use a different encoding

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Spila allt",
 'Shuffle All' => 'Spila í slembiröð',  # Stream all in random order
 'Stream All' => 'Spila allt',

 # This one in just button text
 'Play Selected' => 'Spila valin',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "Í þessari sýniútgáfu er spilun takmörkuð við u.þ.b. [quant,_1,sekúndu,sekúndur].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => 'Diskamöppur ([_1])',
 'Playlists ([_1])' => 'Spilunarlistar ([_1])',        # .m3u files
 'Song List ([_1])' => 'Lagalisti ([_1])', # i.e., file list


 'Playlist' => 'Spilunarlisti',
 'Select' => 'Veldu',
 
 'fetch'  => 'sækja', # Send/download/save this file
 'stream' => 'spila',    # this file
 
 'Shuffle'  => 'Rugla röð',  # a subdirectory, recursively
 'Stream'   => 'Spila',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'Heim',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 var skrifað af ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'óþekkt',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Flytjandi",
 'Comment' => "Athugasemd",
 'Duration' => "Lengd",
 'Filename' => "Skráarnafn",
 'Genre' => "Tegund",  # i.e., what kind of music
 'Album' => "Plata",
 'Min' => "m",  # abbreviation for "minutes"
 'Track' => "Lag",  # just the track number (not the track name)
 'Sec' => "s",  # abbreviation for "seconds"
 'Seconds' => "Sekúndur",
 'Title' => "Titill",
 'Year' => "Ár",

 'Samplerate' => "Söfnunartíðni",
 'Bitrate' => "Bitaflæði",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "Hjálp: Stutt yfirlit",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Spila öll lög",
 "= Shuffle-play all Songs" => "= Spila öll lög í slembiröð",
 "= Go to earlier directory" => "= Fara í síðustu möppu",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Spila innihald",
 "= Enter directory" => "= Fara í möppu",
 "= Stream this song" => "= Spila þetta lag",
 "= Select for streaming" => "= Velja til spilunar",
 "= Download this song" => "= Sækja þetta lag",
 "= Stream this song" => "= Spila þetta lag",
 "= Sort by field" => "= Raða eftir tagi",
    # "sort" in the sense of ordering, not separating out.
);

1;

