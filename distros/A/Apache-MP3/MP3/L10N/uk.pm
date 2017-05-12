
#---------------------------------------------------------------------------
package Apache::MP3::L10N::uk;  # Ukrainian
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Nikolayev Dmitry, nicky@nm.ru or nick@perl.dp.ua

sub encoding { "windows-1251" }   # Windows
  # Change as necessary if you use a different encoding.
  # I advise using whatever encoding is most widely supported
  # in web browsers.

# Below I use a lot of &foo; codes, but you don't have to.

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # Note: Basically, "stream" means "play" for this system.

 # These are links as well as button text:
 'Play All' => "Грати все",
 'Shuffle All' => "Грати все у довільному порядку",  # Stream all in random order
 'Stream All' => "Грати все",

 # This one in just button text
 'Play Selected' => "Грати вибране",

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "В цієй демо-версії довжина гри обмежена [quant,_1,секунда,секунди].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => "Альбомні каталоги ([_1])",
 'Playlists ([_1])' => "Файли списків ([_1])",        # .m3u files
 'Song List ([_1])' => "Список пісень ([_1])", # i.e., file list


 'Playlist' => "Список файлів для виконання",
 'Select' => "Выбрати",

 'fetch'  => "скачати", # Send/download/save this file
 'stream' => "грати",    # this file

 'Shuffle'  => "Грати за довільним порядком",  # a subdirectory, recursively
 'Stream'   => "Грати",            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => "На головну",


 'unknown' => "?",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Виконавець",
 'Comment' => "Коментарі",
 'Duration' => "Довжина",
 'Filename' => "Ім'я файла",
 'Genre' => "Жанр",  # i.e., what kind of music
 'Album' => "Альбом",
 'Min' => "Мін",  # abbreviation for "minutes"
 'Track' => "Трек",  # just the track number (not the track name)
 'Sec' => "Сек",  # abbreviation for "seconds"
 'Seconds' => "Секунди",
 'Title' => "Назва",
 'Year' => "Рік",

 'Samplerate' => "Якість до стискання",
 'Bitrate' => "Якість пысля стискання",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "Допомога",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Грати все",
 "= Shuffle-play all Songs" => "= Грати все за довільним порядком",
 "= Go to earlier directory" => "= Йти до батьківського каталога",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Грати зміст каталога",
 "= Enter directory" => "= Увійти до каталога",
 "= Stream this song" => "= Виконати цю пісню",
 "= Select for streaming" => "= Вибрати для виконання",
 "= Download this song" => "= Скачати цю пісню",
 "= Stream this song" => "= Виконати цю пісню",
 "= Sort by field" => "= Сортувати по ...",
    # "sort" in the sense of ordering, not separating out.


 # The following three phrases are used for composing the sentence that
 # means, in your language, "Apache::MP3 was written by Lincoln D. Stein."
 #
 # For example, some laguages express this as
 #   "Apache::MP3 by Lincoln D. Stein is written."
 # In that case, _CREDITS_before_author would be "Apache::MP3 by",
 # _CREDITS_author would be "Lincoln. D. Stein", and
 # _CREDITS_after_author would be "was written."
 #
 # If you're not sure how to do this, then just tell me the translation
 # for the whole sentence, and I'll take care of it.

 "_CREDITS_before_author" => "Автором Apache::MP3 є ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",

);

1;

