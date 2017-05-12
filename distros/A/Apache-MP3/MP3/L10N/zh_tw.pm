
package Apache::MP3::L10N::zh_tw;  # Traditional Chinese
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);

# Translators, in no particular order:
#  autrijus@autrijus.org

sub encoding {'big5'}
sub language_tag {__PACKAGE__->SUPER::language_tag}

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "全部播放",
 'Shuffle All' => '隨機播放',  # Stream all in random order
 'Stream All' => '串流播放',

 # This one in just button text
 'Play Selected' => '播放選取範圍',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "在示範模式下, 僅能播放約 [quant,_1,秒,秒] 的串流.",
 
 # Headings:
 'CD Directories ([_1])' => '光碟目錄 ([_1])',
 'Playlists ([_1])' => '曲目清單 ([_1])',        # .m3u files
 'Song List ([_1])' => '歌曲列表 ([_1])', # i.e., file list


 'Playlist' => '曲目',
 'Select' => '選取',
	 
 'fetch'  => '下載',   # this file
 'stream' => '串流',    # this file
 
 'Shuffle'  => '隨機',  # a subdirectory, recursively
 'Stream'   => '串流',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => '首頁',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 的作者是 ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => '未命名',

 # Metadata fields:
 'Artist' => "作者",
 'Comment' => "註解",
 'Duration' => "長度",
 'Filename' => "檔案",
 'Genre' => "類型",
 'Album' => "專輯",
 'Min' => "分",
 'Track' => "音軌",  # just the track number (not the track name)
 'Samplerate' => "取樣頻率",
 'Bitrate' => "傳輸頻率",
 'Sec' => "秒",
 'Seconds' => "秒鐘",
 'Title' => "標題",
 'Year' => "年",


 # Now the stuff for the help page:

 'Quick Help Summary' => "輔助說明一覽",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= 將所有歌曲以串流方式播放",
 "= Shuffle-play all Songs" => "= 隨機播放所有歌曲",
 "= Go to earlier directory" => "= 返回先前目錄",
 "= Stream contents" => "= 將其內容以串流方式播放",
 "= Enter directory" => "= 進入目錄",
 "= Stream this song" => "= 將目前歌曲以串流方式播放",
 "= Select for streaming" => "= 選取欲進行串流的歌曲",
 "= Download this song" => "= 下載這首歌曲",
 "= Stream this song" => "= 將目前歌曲以串流方式播放",
 "= Sort by field" => "= 以某項欄位排序",

 # Playlist.pm
 "Add to Playlist" => "外[入播放清單",
 "Add All to Playlist" => "全部外[入播放清單",
 "Current Playlist" => "現行播放清單",
 "Clear All" => "全部清除",
 "Clear Selected" => "清除選取範圍",
 "Playlist contains [quant,_1,song,songs]." => "播放清單中共有 [quant,_1,首,首] 歌曲。",
 "Your playlist is now full. No more songs can be added." => "播放清單已滿，無法新增歌曲。",

);

1;

