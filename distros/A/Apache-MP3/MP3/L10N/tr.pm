
package Apache::MP3::L10N::tr;  # Turkish
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
# Alper Tugay MIZRAK   amizrak@cs.ucsd.edu

sub encoding { "iso-8859-9" }   #Latin 5
  # Change as necessary if you use a different encoding.
  # I advise using whatever encoding is most widely supported
  # in web browsers.

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # Note: Basically, "stream" means "play" for this system.

 # These are links as well as button text:
 'Play All' => "Hepsini Çal",
 'Shuffle All' => "Hepsini Karıştır",  # Stream all in random order
 'Stream All' => "Hepsini Çal",

 # This one in just button text
 'Play Selected' => "Seçileni Çal",
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "Bu gösteride, çalma süresi yaklaşık [quant,_1,saniye,saniye] ile sınırlıdır.",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "CD Dizinleri ([_1])",
 'Playlists ([_1])' => "Program ([_1])",        # .m3u files
 'Song List ([_1])' => "Şarki Listesi ([_1])", # i.e., file list


 'Playlist' => "Program",
 'Select' => "Seç",
 
 'fetch'  => "Getir", # Send/download/save this file
 'stream' => "Çal",    # this file
 
 'Shuffle'  => "Karıştır",  # a subdirectory, recursively
 'Stream'   => "Çal",            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => "Ev",


 'unknown' => "bilinmiyor",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Sanatçı",
 'Comment' => "Açıklama",
 'Duration' => "Süre",
 'Filename' => "Dosya İsmi",
 'Genre' => "Tür",  # i.e., what kind of music
 'Album' => "Albüm",
 'Min' => "Dak",  # abbreviation for "minutes"
 'Track' => "Track numarası",  # just the track number (not the track name)
 'Sec' => "Sn",  # abbreviation for "seconds"
 'Seconds' => "Saniye",
 'Title' => "Başlık",
 'Year' => "Yıl",

 'Samplerate' => "Orijinal Ses Kalitesi",
 'Bitrate' => "Ses Kalitesi",

 # Now the stuff for the help page:

 'Quick Help Summary' => "Hızlı Yardım Özeti",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Tüm şarkıları çal",
 "= Shuffle-play all Songs" => "= Tüm şarkıları karıştır-çal",
 "= Go to earlier directory" => "= Bir önceki dizin",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Parça içeriği",
 "= Enter directory" => "= Dizin girin",
 "= Stream this song" => "= Bu şarkıyı çal",
 "= Select for streaming" => "= Çalmak için seç",
 "= Download this song" => "= Bu şarkıyı yükle",
 "= Stream this song" => "= Bu şarkıyı çal",
 "= Sort by field" => "= Özelliğe göre sırala",
    # "sort" in the sense of ordering, not separating out.

 "_CREDITS_before_author" => "Apache::MP3, ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  " tarafından yazılmıştır.",

);

1;

