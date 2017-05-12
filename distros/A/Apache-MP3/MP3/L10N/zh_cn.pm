
package Apache::MP3::L10N::zh_cn;  # Simplified Chinese
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);

# Translators, in no particular order:
#  autrijus@autrijus.org

sub encoding {'euc-cn'} # euc-cn (gb2312)
sub language_tag {__PACKAGE__->SUPER::language_tag}

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "全部播放",
 'Shuffle All' => '随机播放',  # Stream all in random order
 'Stream All' => '串流播放',

 # This one in just button text
 'Play Selected' => '播放选取范围',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "在示范模式下, 仅能播放约 [quant,_1,秒,秒] 的串流.",
 
 # Headings:
 'CD Directories ([_1])' => '光盘目录 ([_1])',
 'Playlists ([_1])' => '曲目清单 ([_1])',        # .m3u files
 'Song List ([_1])' => '歌曲列表 ([_1])', # i.e., file list


 'Playlist' => '曲目',
 'Select' => '选取',
 
 'fetch'  => '下载',   # this file
 'stream' => '串流',    # this file
 
 'Shuffle'  => '随机',  # a subdirectory, recursively
 'Stream'   => '串流',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => '首页',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 的作者是 ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => '未命名',

 # Metadata fields:
 'Artist' => "作者",
 'Comment' => "注解",
 'Duration' => "长度",
 'Filename' => "档案",
 'Genre' => "类型",
 'Album' => "专辑",
 'Min' => "分",
 'Track' => "音轨",  # just the track number (not the track name)
 'Samplerate' => "取样频率",
 'Bitrate' => "传输频率",
 'Sec' => "秒",
 'Seconds' => "秒钟",
 'Title' => "标题",
 'Year' => "年",


 # Now the stuff for the help page:

 'Quick Help Summary' => "辅助说明一览",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= 将所有歌曲以串流方式播放",
 "= Shuffle-play all Songs" => "= 随机播放所有歌曲",
 "= Go to earlier directory" => "= 返回先前目录",
 "= Stream contents" => "= 将其内容以串流方式播放",
 "= Enter directory" => "= 进入目录",
 "= Stream this song" => "= 将目前歌曲以串流方式播放",
 "= Select for streaming" => "= 选取欲进行串流的歌曲",
 "= Download this song" => "= 下载这首歌曲",
 "= Stream this song" => "= 将目前歌曲以串流方式播放",
 "= Sort by field" => "= 以某项栏位排序",

 # Playlist.pm
 "Add to Playlist" => "加入播放清单",
 "Add All to Playlist" => "全部加入播放清单",
 "Current Playlist" => "现行播放清单",
 "Clear All" => "全部清除",
 "Clear Selected" => "清除选取范围",
 "Playlist contains [quant,_1,song,songs]." => "播放清单中共有 [quant,_1,首,首] 歌曲。",
 "Your playlist is now full. No more songs can be added." => "播放清单已满，无法新增歌曲。",

);

1;

