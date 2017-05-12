
package Apache::MP3::L10N::ar;  # Arabic
use strict;
use Apache::MP3::L10N::RightToLeft;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N::RightToLeft);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Isam Bayazidi <bayazidi|@arabeyes.org>

sub encoding { "utf-8" }   

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified


 # These are links as well as button text:
 'Play All' => "أعرض الكل",
 'Shuffle All' => 'أعرض الكل عشوائيا',  # Stream all in random order
 'Stream All' => 'أعرض الكل',

 # This one in just button text
 'Play Selected' => 'أعرض ما هو مختار',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "في هذا العرض التجريبي، يستمر العرض لحوالي [quant,_1,ثانية,ثواني].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => 'أدلة الألبوم ([_1])',
 'Playlists ([_1])' => 'قوائم العرض ([_1])',        # .m3u files
 'Song List ([_1])' => 'قائمة الأغاني ([_1])', # i.e., file list


 'Playlist' => 'قائمة عرض',
 'Select' => 'أختر',
 
 'fetch'  => 'ثبت', # Send/download/save this file
 'stream' => 'أعرض',    # this file
 
 'Shuffle'  => 'أعرض عشوائيا',  # a subdirectory, recursively
 'Stream'   => 'أعرض',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'موطن',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 تم تطويره من قبل ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'مجهول',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "الفنان",
 'Comment' => "ملاحظات",
 'Duration' => "المدة",
 'Filename' => "أسم الملف",
 'Genre' => "النوع",  # i.e., what kind of music
 'Album' => "ألبوم",
 'Min' => "دقيقة",  # abbreviation for "minutes"
 'Track' => "Track",  # just the track number (not the track name)
 'Sec' => "ثانية",  # abbreviation for "seconds"
 'Seconds' => "ثواني",
 'Title' => "عنوان",
 'Year' => "السنة",

 'Samplerate' => "معدل التحويل",
 'Bitrate' => "معدل الإرسال",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "مساعدة سريعة ملخصة",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= أعرض كل الأغاني",
 "= Shuffle-play all Songs" => "= أعرض كل الأغاني بشكل عشوائي",
 "= Go to earlier directory" => "= أذهب إلى الدليل السابق",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= أعرض المحتويات",
 "= Enter directory" => "= أدخل الدليل",
 "= Stream this song" => "= أعرض هذه الأغنية",
 "= Select for streaming" => "= أختر هذه للعرض",
 "= Download this song" => "= حمل هذه الأغنية",
 "= Stream this song" => "= أعرض هذه الأغنية",
 "= Sort by field" => "= أعد الترتيب بناء على الحقل",
    # "sort" in the sense of ordering, not separating out.
);

1;

