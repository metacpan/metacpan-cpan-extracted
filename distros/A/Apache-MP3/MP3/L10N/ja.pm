
package Apache::MP3::L10N::ja;  # Japanese
# Encoded in Shift_JIS, de facto standard of MP3 tags in Japan
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);

# Translator: miyagawa@bulknews.net

sub encoding {'shift_jis'} # Shift-JIS
sub language_tag {__PACKAGE__->SUPER::language_tag}

sub sworp {
  # Treat [ and ] as literal; use { and } as the metacharacters.
  my @in = @_;
  foreach my $x (@in) {
    $x =~ s/\[/~[/g;
    $x =~ s/\]/~]/g;
    $x =~ tr<{}><[]>;
  }
  @in;
}

%Lexicon = (sworp(
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => 'プレイ',
 'Shuffle All' => 'シャッフル',  # Stream all in random order
 'Stream All' => 'ストリーミング',

 # This one in just button text
 'Play Selected' => 'チェックしたものをプレイ',
 
 "In this demo, streaming is limited to approximately {quant,_1,second,seconds}."
  => "このデモでは、ストリーミングは {quant,_1,秒,秒} に限定されています。",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ({_1})' => 'CD ディレクトリ ({_1})',
 'Playlists ({_1})' => 'プレイリスト ({_1})',
 'Song List ({_1})' => 'ファイルリスト ({_1})',

 'Playlist' => 'プレイリスト',
 'Select' => '選択',
 
 'fetch'  => 'ダウンロード',   # this file
 'stream' => 'ストリーミング',    # this file
 
 'Shuffle'  => 'シャッフル',  # a subdirectory, recursively
 'Stream'   => 'ストリーミング',            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => 'Home',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 by ",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'unknown',

 # Metadata fields:
 'Artist' => 'アーティスト',
 'Comment' => 'コメント',
 'Duration' => '演奏時間',
 'Filename' => 'ファイル名',
 'Genre' => 'ジャンル',
 'Album' => 'アルバム',
 'Min' => '分',
 'Track' => 'トラック',  # just the track number (not the track name)
 'Samplerate' => 'サンプルレート',
 'Bitrate' => 'ビットレート',
 'Sec' => '秒',
 'Seconds' => '秒',
 'Title' => 'タイトル',
 'Year' => '年',


 # Now the stuff for the help page:

 'Quick Help Summary' => 'クイックヘルプ',
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => '= すべての曲をストリーミング',
 "= Shuffle-play all Songs" => '= すべての曲をシャッフルして演奏',
 "= Go to earlier directory" => '= 上のディレクトリへ',
 "= Stream contents" => '= コンテンツをストリーミング',
 "= Enter directory" => '= ディレクトリを開く',
 "= Stream this song" => '= この曲をストリーミング',
 "= Select for streaming" => '= ストリーミング用にチェック',
 "= Download this song" => '= この曲をダウンロード',
 "= Stream this song" => '= この曲をストリーミング',
 "= Sort by field" => '= フィールドでソート',

));

1;

