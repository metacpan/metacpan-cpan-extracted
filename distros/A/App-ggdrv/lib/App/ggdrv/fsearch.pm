package App::ggdrv::fsearch ; 
use strict; use warnings ;
use feature 'say' ;
use Carp ;
use Net::Google::Drive ; 

my ($gfile, $cid, $csec, $rtoken, $atoken, $disk, $file_name , $files , $fnum ) ; 
return 1 ;

sub fsearch () { 
  $gfile = $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ;
  $cid = qx [ sed -ne's/^CLIENT_ID[ =:\t]*//p' $gfile ] =~ s/\n$//r ; # クライアントID
  $csec = qx [ sed -ne's/^CLIENT_SECRET[ =:\t]*//p' $gfile ] =~ s/\n$//r ; # クライアントシークレット
  $rtoken = qx [ sed -ne's/^REFRESH_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ; 
  $atoken = qx [ sed -ne's/^ACCESS_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ; 
  $disk = Net::Google::Drive->new( 
    -client_id => $cid, -client_secret => $csec, -refresh_token => $rtoken , -access_token  => $atoken );

  $file_name = $ARGV[0] // '*' ; # ファイル一覧を出力。## アスタリスクで全部のファイルの情報を取ってくる。ただし最大100個のようである。

  $files = $disk->searchFileByNameContains( -filename => $file_name ) or croak "File '$file_name' not found";
  $fnum = 0 ;
  binmode STDOUT, ":utf8";
  do { say join"\t",sprintf('%03d',++$fnum),$_->{kind},$_->{id},qq["$_->{name}"],$_->{mimeType} } for @{$files} ;

}

=encoding utf8

=head1

   最大100個のファイルを取り出す。
   ワイルドカードを使ったファイル名で検索ができる。IDを突き止めることが出来る。

開発メモ: 
   * 4個の内のアクセストークンについては、設定は必要だがデタラメでも良い様だ。
   * そのファイルの親フォルダとか、あるフォルダが含むファイルとかの情報も欲しい。
   * ワイルドカードを使って検索する機能があるとしても、 限られた中だけから100個だけからということは無かろうか?

=cut


