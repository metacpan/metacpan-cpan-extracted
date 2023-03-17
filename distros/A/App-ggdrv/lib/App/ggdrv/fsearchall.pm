package App::ggdrv::fsearchall ;
use strict; use warnings;
use feature 'say' ; 
use Data::Dumper ; 
use Getopt::Std ; 
use HTTP::Tiny ;
use JSON ; 

my ( $GOOGLE_DRIVE_API , $gfile , $atoken , $count_limit , $uri , %o ) ;
return 1 ; 

sub fsearchall () { 
  #exit ;
  getopts 'g:D' , \%o ;
  $GOOGLE_DRIVE_API = "https://www.googleapis.com/drive/v3/files" ;
  $gfile = $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ;
  $atoken = qx [ sed -ne's/^ACCESS_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ;
  say $atoken ;
  $count_limit = $o{g} // 2 ; 
  # 全てのファイルを取得する
  $uri = URI -> new ( $GOOGLE_DRIVE_API ) ;
  $uri -> query_form ( access_token => $atoken ) ;
  & files ( $uri ) ;
}

sub files {
  binmode STDOUT, ":utf8" ;
  my $uri = shift;
  #say "\$uri=$uri" ;
  my $count = 0 ; # URIの中身から取り出した nextPageToken を引っ張り出した回数
  my $fnum = 0 ; # ファイルの個数
  my $ht = HTTP::Tiny->new();
  while ( $count < $count_limit ) {
    my $contents = decode_json( $ht->get($uri)->{content} );
    do { print Dumper $contents ; $contents->{error} ? last : next } if $o{D} ;
    $uri->query_form( access_token => $atoken, pageToken => $contents->{nextPageToken} ) ;
    for my $content ( @{ $contents->{files} } ) {
      print  sprintf ("%05d ", ++ $fnum ) . "=" x 20 . "\n" ;
      printf( "%-8s: %s\n", "id",     $content->{id} );
      printf( "%-8s: %s\n", "name",   $content->{name} );
      printf( "%-8s: %s\n", "mimeType", $content->{mimeType} );
      printf( "%-8s: %s\n", "kind",   $content->{kind} );
      print "=" x 20 . "\n";
    }
    last if ! $contents->{nextPageToken}; # 最終ページには nextPageToken キーが無い
  }
  continue { 
    $count ++ ;
  }
}

=encoding utf8

=head1


 ドライブのファイルの一覧を出力。何らかの手段でこのプログラムにアクセストークンを与えることが必要。

　オプション : 
  -g N : 何回ページをたぐるか? 未指定なら2。
  #-D   : 取ってきたデータを Dumper で出力する。エラーが起きたときの様子を調べるのに便利。

その他 : 
  - 1万個ファイルがあると、全部見せるのに、1分間の時間がかかるであろう。
  - 内部で、HTTP::Tinyを用いる。Net::Google::OAuthを使っていない。
  - fsearchと fsearchall が有ることで、万一、片方に不具合があった場合に心強い。

=cut

