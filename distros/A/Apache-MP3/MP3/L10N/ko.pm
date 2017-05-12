#---------------------------------------------------------------------------
package Apache::MP3::L10N::ko;  # 'KO' means Korean language. The nation code is 'KR'.
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Apache::MP3::L1ON::ko
# Date: 2002-05-05
# Translation: 박종복 (Park, Jong-Pork), mailing@NO-SPAM.okclub.com(remove NO-SPAM.)
# Homepage: http://seoul.pm.org and http://www.okclub.com

sub encoding { "euc-kr" }

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # Note: Basically, "stream" means "play" for this system.

 # These are links as well as button text:
 'Play All' => "전체 재생",
 'Shuffle All' => "임의 재생",  # Stream all in random order
 'Stream All' => "전체 재생",

 # This one in just button text
 'Play Selected' => "선택 곡 재생",
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "이 곡은 데모입니다. 재생 시간이 약 [quant,_1,초,초] 만큼 제한됩니다.",
  #분량
 # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "CD 디렉터리 ([_1])",
 'Playlists ([_1])' => "재생 목록 파일들 ([_1])",        # .m3u files
 'Song List ([_1])' => "재생 파일들 목록 ([_1])", # i.e., file list


 'Playlist' => "재생 목록",
 'Select' => "선택",
 
 'fetch'  => "전송", # Send/download/save this file
 'stream' => "재생",    # this file
 
 'Shuffle'  => "임의 재생",  # a subdirectory, recursively
 'Stream'   => "전체 재생",            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"

 'Home' => "홈페이지",


 'unknown' => "?",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "가수",
 'Comment' => "설명",
 'Duration' => "재생 시간",
 'Filename' => "파일명",
 'Genre' => "장르",  # i.e., what kind of music
 'Album' => "앨범",
 'Min' => "분",  # abbreviation for "minutes"
 'Track' => "트랙;",  # just the track number (not the track name)
 'Sec' => "초",  # abbreviation for "seconds"
 'Seconds' => "초",
 'Title' => "제목",
 'Year' => "년도",

 'Samplerate' => "샘플레이트",
 'Bitrate' => "비트레이트",

 'Quick Help Summary' => "빠른 도움말",
 # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= 전체 곡을 재생",
 "= Shuffle-play all Songs" => "= 전체 곡 중에 임의로 선택 재생",
 "= Go to earlier directory" => "= 상위 디렉터리로 이동",
 "= Stream contents" => "= 재생 형태",
 "= Enter directory" => "= 해당 디렉터리로 이동",
 "= Stream this song" => "= 이 곡을 재생",
 "= Select for streaming" => "= 선택한 곡을 재생",
 "= Download this song" => "= 이 곡을 전송받음",
 "= Stream this song" => "= 이 곡을 재생",
 "= Sort by field" => "= 해당 항목으로 재정렬",


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

 "_CREDITS_before_author" => "Apache::MP3 모듈의 저작자는 ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  " 입니다.",

);

1;

