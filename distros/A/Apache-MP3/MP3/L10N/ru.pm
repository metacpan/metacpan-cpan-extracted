
#---------------------------------------------------------------------------
package Apache::MP3::L10N::ru;  # Russian
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators for this module, in no particular order:
#  Nikolayev Dmitry, nicky@nm.ru or nick@perl.dp.ua

sub encoding { "windows-1251" }   # Windows

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Играть всё",
 'Shuffle All' => "Играть всё в произвольном порядке",  # Stream all in random order
 'Stream All' => "Играть всё",

 # This one in just button text
 'Play Selected' => "Играть выбранные",

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "В этой демо-версии проигрывание ограничено приблизително [quant,_1,секунда,секунды].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => "Альбомные каталоги ([_1])",
 'Playlists ([_1])' => "Файлы списков ([_1])",        # .m3u files
 'Song List ([_1])' => "Список песен ([_1])", # i.e., file list


 'Playlist' => "Список файлов для воспроизведения",
 'Select' => "Выбрать",

 'fetch'  => "скачать", # Send/download/save this file
 'stream' => "играть",    # this file

 'Shuffle'  => "Играть в произвольном порядке",  # a subdirectory, recursively
 'Stream'   => "Играть",            # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => "На главную",


 'unknown' => "?",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Исполнитель",
 'Comment' => "Комментарии",
 'Duration' => "Длина",
 'Filename' => "Имя файла",
 'Genre' => "Жанр",  # i.e., what kind of music
 'Album' => "Альбом",
 'Min' => "Мин",  # abbreviation for "minutes"
 'Track' => "Трэк",  # just the track number (not the track name)
 'Sec' => "Сек",  # abbreviation for "seconds"
 'Seconds' => "Секунды",
 'Title' => "Название",
 'Year' => "Год",

 'Samplerate' => "Качество перед сжатием",
 'Bitrate' => "Качество после сжатия",

 # Now the stuff for the help page:

 'Quick Help Summary' => "Помощь",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Играть всё",
 "= Shuffle-play all Songs" => "= Играть все песни в произвольном порядке",
 "= Go to earlier directory" => "= Идти к родительскому каталогу",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Играть содержание каталога",
 "= Enter directory" => "= Войти в каталог",
 "= Stream this song" => "= Играть эту песню",
 "= Select for streaming" => "= Выбрать для воспроизведения",
 "= Download this song" => "= Скачать эту песню",
 "= Stream this song" => "= Играть эту песню",
 "= Sort by field" => "= Сортировать по ...",
    # "sort" in the sense of ordering, not separating out.

 "_CREDITS_before_author" => "Автором Apache::MP3 является ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",

);

1;

