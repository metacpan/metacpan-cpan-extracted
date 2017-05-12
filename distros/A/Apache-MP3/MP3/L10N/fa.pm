package Apache::MP3::L10N::fa;  # Farsi / Persian
use strict;
use Apache::MP3::L10N::RightToLeft;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N::RightToLeft);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
# Arash Bijanzadeh  <a.bijanzadeh@linuxiran.org>

sub encoding { "utf-8" }   

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified


 # These are links as well as button text:
 'Play All' => "پخش همه",
 'Shuffle All' => 'پخش تصادفى',  # Stream all in random order
 'Stream All' => ' اجراى همه  ',

 # This one in just button text
 'Play Selected' => 'پخش انتخابى',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
 => "در اين نمونه اجرا محدود به [quant,_1,ثانيه,ثانيه] است.",

 # =>"  [quant,_1,second,]اين يک نمونه است پخش مستقيم محدود به ",
 # در اين نمونه اجرا محدود به 5 ثانيه است
 
 # Headings:
 'CD Directories ([_1])' => 'دايرکتورى هاى لوح  ([_1])',
 'Playlists ([_1])' => 'ليست پخش ([_1])',        # .m3u files
 'Song List ([_1])' => 'ليست آوازها ([_1])', # i.e., file list


 'Playlist' => 'ليست پخش',
 'Select' => 'انتخاب',
 
 'fetch'  => 'ثبت', # Send/download/save this file
 'stream' => 'پخش مستقيم',    # this file
 
 'Shuffle'  => 'تصادفى',  # a subdirectory, recursively
 'Stream'   => 'پخش مستقيم',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'خانه',

 'unknown' => 'ناشناس',
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "هنرمند",
 'Comment' => "ملاحظات",
 'Duration' => "مدت",
 'Filename' => "نام پرونده",
 'Genre' => "ژانر",  # i.e., what kind of music
 'Album' => "آلبوم",
 'Min' => "دقيقة",  # abbreviation for "minutes"
 'Track' => "Track",  # just the track number (not the track name)
 'Sec' => "ثانيه",  # abbreviation for "seconds"
 'Seconds' => "ثانيه",
 'Title' => "عنوان",
 'Year' => "سال",

 'Samplerate' => "کيفيفيت صداى مبدا",
 'Bitrate' => "کيفيت صدا",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "خلاصه کمک مختصر!",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "=اجراى تمام آوازها",
 "= Shuffle-play all Songs" => "= پخش تصادفى تمامى آوازها",
 "= Go to earlier directory" => "= بازگشت به دايرکتورى قبلى",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= اجراى محتويات",
 "= Enter directory" => "= ورود به دايرکتورى",
 "= Stream this song" => "= اجراى اين آواز",
 "= Select for streaming" => "= انتخاب براى اجرا",
 "= Download this song" => "= دريافت اين آواز",
 "= Stream this song" => "= اجراى اين آواز",
 "= Sort by field" => "=  بر اساس فيلد مرتب کن",
    # "sort" in the sense of ordering, not separating out.
);

1;

