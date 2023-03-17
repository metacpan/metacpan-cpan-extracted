package App::ggdrv::upload ;
use strict;
use warnings;
use feature 'say' ; 
use HTTP::Request::Common;
use JSON qw/encode_json decode_json/;
use LWP::UserAgent;
use Getopt::Std ; 
use Carp; 

my ($gfile , $atoken, $GOOGLE_DRIVE_UPLOAD_API , %o);
return 1 ;

sub upload { 
  getopts 'f:m:' , \%o ;
  $o{f} //= '' ; # フォルダ名
  $o{m} //= 'text/plain' ; # MIMEタイプ
  $gfile = $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ;
  $atoken = qx [ sed -ne's/^ACCESS_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ;
  $GOOGLE_DRIVE_UPLOAD_API = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" ;
  & f_each ( $_ ) for @ARGV ; 
}

sub f_each ( $ ) { 
  binmode STDOUT, ":utf8";
  my $mimeType = $o{m} ; 
  my $ej1 = encode_json { name => $_[0] , mimeType => $mimeType , $o{f} ne q[] ? ( parents  => [ $o{f} ] ): () } ;
  my $res = LWP::UserAgent -> new -> request (
    POST $GOOGLE_DRIVE_UPLOAD_API ,
    'Content-Type' => 'multipart/form-data' ,
    Authorization =>  "Bearer $atoken" ,
    Content => [
      metadata => [ undef, undef , 'Content-Type' => 'application/json;charset=UTF-8' , 'Content' => $ej1 ] ,
      file => [ $_[0] ] ,
    ] ,
    ) ;
  my $j = decode_json ( $res->content ) ; 
  say join "\t" , map { $_ // 'undef' } $res->code , $j->{id}, $j->{name}, $j->{mimeType} , $j->{kind} ; 
}

=encoding utf8

=head1

 $0  -f 目的のフォルダID ファイル名 [ファイル名] [ファイル名] ..

  指定したファイルを指定したGoogleドライブのフォルダにアップロードする。
  (同じ名前のファイルも複数回、このプログラムを実行すると、新規に次々とGoogleドライブにアップロードされる。少し要注意。)

  このプログラムは HTTP::Request::Common を用いていて、Net::Google::OAuthを使わない。

  オプション: 
    -f STR : 指定しないか、空文字だと、グーグル直下のディレクトリになる。
    -m TYPE : text/csv　などを指定。 未指定なら text/plain ;


出力例: 

# 200
# {
#  "kind": "drive#file",
#  "id": "1...(全部で33文字-_英数大文字小文字)bag",
#  "name": "test.txt",
#  "mimeType": "text/plain"
# }


=cut
