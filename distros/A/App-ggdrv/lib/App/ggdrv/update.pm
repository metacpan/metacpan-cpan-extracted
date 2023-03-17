package App::ggdrv::update ; 
use strict ; 
use warnings ;
use feature 'say' ; 
use HTTP::Request::Common ;
use JSON qw[ encode_json ] ;
use LWP::UserAgent ;
use URI::QueryParam ;
use URI ;

my ($GOOGLE_DRIVE_UPLOAD_API , $gfile , $atoken ) ; 
return 1 ; 

sub update {
  $GOOGLE_DRIVE_UPLOAD_API = "https://www.googleapis.com/upload/drive/v3/files/";
  $gfile = $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ;
  $atoken = qx [ sed -ne's/^ACCESS_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ;
  while ( my ($file,$id) = splice @ARGV , 0 , 2 ) { f_each ($file,$id) }
  # & f_each ( split /:/, $_ , 2 ) for @ARGV ; 
}

sub f_each ( $$ ) { 
  my $URI = URI->new( $GOOGLE_DRIVE_UPLOAD_API . $_[1] );
  $URI->query_param( uploadType => 'multipart' );
  my $ua  = LWP::UserAgent->new;
  my $res = $ua->request(
    PATCH $URI,
    'Content-Type' => 'multipart/form-data',
    Authorization  => "Bearer $atoken" ,
    Content    => [
      metadata => [
        undef, undef, # undef => undef と書くことは出来るだろうか?
        'Content-Type' => 'application/json;charset=UTF-8',
        'Content' => encode_json( {} ) #name=>'temp.txt', mimeType=>'text/plain', parents  => ['10_33chars_in_total'], id => $target_fileid},
      ],
      file => [ $_[0] ] #["./anotherName.txt"],
    ],
  );
  print $res->code . "\n";
  print $res->content . "\n";
}


=encoding utf8

=head1

 ggdrv --update  ファイル名1 ファイルid1  [ファイル名2 ファイルid2]  [ファイル名3 ファイルid3] ..

  Googleドライブのフォルダーの指定するファイルIDにローカルのファイルを更新する。
  引数の数は、偶数個とすること。 
  ローカルのファイル名は、アップロード先のファイル名とは一致しないことがある(そのファイルIDの前のファイルと同じものになる)。　

開発上のメモ:    複数のファイルに対応したい。
標準出力への出力の例: 

# 200
# {
#  "kind": "drive#file",
#  "id": "1..(33文字)....f",
#  "name": "example.txt",
#  "mimeType": "text/plain"
# }

 アクセストークンの有効期限の30分が切れていたりすると、上記は"message": "Invalid Credentials"が現れるであろう。
