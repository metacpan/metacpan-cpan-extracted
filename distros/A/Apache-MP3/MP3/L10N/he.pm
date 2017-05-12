
package Apache::MP3::L10N::he;  # Hebrew
use strict;
use Apache::MP3::L10N::RightToLeft;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N::RightToLeft);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Shlomo Yona <shlomo@cs.haifa.ac.il>

sub encoding { "utf-8" }   

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified


 # These are links as well as button text:
 'Play All' => 'נגן הכל',
 'Shuffle All' => 'סדר הכל באקראי',  # Stream all in random order
 'Stream All' => 'נגן הכל',

 # This one in just button text
 'Play Selected' => 'נגן שירים שנבחרו',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "בהדגמה זו הנגינה מוגבלת ל-[quant,_1,שניה,שניות] בקרוב.",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => 'ספריות תקליטורים ([_1])',
 'Playlists ([_1])' => 'רשימות נגן ([_1])',        # .m3u files
 'Song List ([_1])' => 'רשימת שירים ([_1])', # i.e., file list


 'Playlist' => 'רשימת נגן',
 'Select' => 'בחר',
 
 'fetch'  => 'שמור', # Send/download/save this file
 'stream' => 'נגן',    # this file
 
 'Shuffle'  => 'סדר באקראי',  # a subdirectory, recursively
 'Stream'   => 'נגן',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'אתר הבית',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 נכתב על-ידי ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'לא ידוע',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "ביצוע",
 'Comment' => "הערה",
 'Duration' => "משך",
 'Filename' => "שם הקובץ",
 'Genre' => "סגנון",  # i.e., what kind of music
 'Album' => "אלבום",
 'Min' => "דק'",  # abbreviation for "minutes"
 'Track' => "מספר",  # just the track number (not the track name)
 'Sec' => "שנ'",  # abbreviation for "seconds"
 'Seconds' => "שניות",
 'Title' => "כותר",
 'Year' => "שנה",

 'Samplerate' => "קצב הדגימה",
 'Bitrate' => "קצב הדגימה בדחיסה",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "תקציר עזרה",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= נגן את כל השירים",
 "= Shuffle-play all Songs" => "= נגן את כל השירים באקראי",
 "= Go to earlier directory" => "= הספרייה הקודמת",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= תוכן השיר",
 "= Enter directory" => "= הכנס שם ספרייה",
 "= Stream this song" => "= נגן שיר זה",
 "= Select for streaming" => "= בחר להשמעה",
 "= Download this song" => "= שמור שיר זה",
 "= Stream this song" => "= נגן שיר זה",
 "= Sort by field" => "= מיון לפי שדה",
    # "sort" in the sense of ordering, not separating out.
);

1;

