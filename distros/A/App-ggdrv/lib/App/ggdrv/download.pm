package App::ggdrv::download ; 
use strict; 
use warnings ;
use Getopt::Std ; 
use Net::Google::Drive ; 

return 1 ; 

sub download {
  getopts '~',\my%o ;
  my $gfile = $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ;
  my $cid  = qx [ sed -ne's/^CLIENT_ID[ =:\t]*//p' $gfile ] =~ s/\n$//r ; #"54525797.....34dseo.apps.googleusercontent.com" ;
  my $csec = qx [ sed -ne's/^CLIENT_SECRET[ =:\t]*//p' $gfile ] =~ s/\n$//r ; # "GOCSP...YUbpe1" ; 
  my $rtoken = qx [ sed -ne's/^REFRESH_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ; 
  my $atoken  = qx [ sed -ne's/^ACCESS_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ; 
  my $disk = Net::Google::Drive->new( -client_id => $cid, -client_secret => $csec, -access_token => $atoken, -refresh_token => $rtoken );

  do { my @f = $ARGV[0] ? ($ARGV[0] ) : () ; my $r = $disk->uploadFile( -source_file => $ARGV[1], -parents => [ @f ] ) ; exit } if $o{'~'} ; 
  $disk->downloadFile( -file_id => $ARGV[0], -dest_file => $ARGV[1] ) or do { use Carp ; croak "Failure to download." } ;
}

=encoding utf8

=head1

 ggdrv --download file_id local_file_name  # ダウンロード
 ggdrv --download -~ folder_id local_file_name  # アップロード

   グーグルドライブの1個のファイルをローカルにダウンロードする。
   file_idは33文字。(file_idが44文字の場合はうまくいかないようだ。)
   local_file_name はスラッシュを含んでもいけない(ようだ)。i.e. カレントディレクトリへのみDL。)
   
 オプション: 
   -~  : アップロードする反対方向になる。引数2個は、folder_id と local_file_name のペアを並べること。

 開発メモ: 
   * ダウンロードするファイルの様々な情報を画面に出したい。
   * もう少し情報の出し方を親切にしたいかも。
   * -~ で動く部分について。任意のフォルダーに権限があれば他人のアカウントでもアップロードは出来る。
   * しかし、他人のアカウントのルートのフォルダーはどうやって指定すれば良いのか? 33文字のIDはどうやって取得すれば良いのか??  

=cut

