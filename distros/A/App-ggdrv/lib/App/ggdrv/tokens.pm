package App::ggdrv::tokens ; #use strict;
use warnings;
use 5.030 ; 
use feature 'say' ;
use Net::Google::OAuth ; #use Exporter 'import';
use POSIX qw [ strftime ] ; 
use Term::ANSIColor qw[ color :constants ] ; $Term::ANSIColor::AUTORESET = 1 ;


my ($gfile, $cid, $csec, $email, $scope, $rtoken0, $atoken0 ) ;
return 1 ; 

sub tokens ( $$$ ) { 
  my $get = $_[0] ;
  my $try = $_[1] ;
  my $atoken = $_[2] ; 
  $gfile = ( $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ) ;
  #open my $FH , '<' , $gfile ; while (<$FH>){say $_ } ;
  my $mtime = [ stat $gfile ]->[9] ; # 更新時刻 ## $gfile がコマンドラインからは見えるのに、このプログラムからは見えない不具合あり。
  #say "@tmp" ;
  #say qx [ ls -l $gfile ] ; exit ;  
  $cid = qx [ sed -ne's/^CLIENT_ID[ =:\t]*//p' $gfile ] =~ s/\n$//r ; #"54525797.....34dseo.apps.googleusercontent.com" ;
  $csec = qx [ sed -ne's/^CLIENT_SECRET[ =:\t]*//p' $gfile ] =~ s/\n$//r ; # "GOCSP...YUbpe1" ; 
  $email = qx [ sed -ne's/^EMAIL[ =:\t]*//p' $gfile ] =~ s/\n$//r ;
  $scope = 'drive'; #my $SCOPE  = 'spreadsheets';
  $rtoken0 = qx [ sed -ne's/^REFRESH_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ; #"1//0e8......yLDJyrKxXNJY" ; 
  $atoken0 = qx [ sed -ne's/^ACCESS_TOKEN[ =:\t]*//p' $gfile ] =~ s/\n$//r ; #"1//0e8......yLDJyrKxXNJY" ; 
  $atoken ? atoken ($try) : $get ? get_tokens () : show_tokens ( $try ) ; 
  say "Modified time of the setup variable file : " , strftime( "%Y-%m-%d %H:%M:%S." , localtime $mtime ) if defined $mtime ;
  1 ;
}

sub show_tokens () { 
  say REVERSE "REFRESH TOKEN from the setup file: " ;
  say $rtoken0 , " (". length($rtoken0)." chars)" ; 
  say REVERSE "ACCESS  TOKEN from the setup file: " ;
  say $atoken0 , " (". length($atoken0)." chars)" ; 
  1 ; 
}

# アクセストークンとリフレッシュトークンを獲得する。
sub get_tokens ( $ ) { 
  my $try = $_[0] ; 
  say YELLOW "次の英文をよく読み、それを実行せよ。途中で「続行」のボタンを2回押すことになるであろう。" ;
  say 'Paste the following url into your browser. Push "Continue" button twice. Then copy the URL on your browser to paste here.' ;
  my $oauth = Net::Google::OAuth->new( -client_id => $cid, -client_secret => $csec ) ;
  $oauth->generateAccessToken( -scope => $scope, -email => $email ) ;
  my $atoken = $oauth -> getAccessToken () ;
  my $rtoken = $oauth -> getRefreshToken () ; 
  print "This is ACCESS TOKEN:\n"; print "=" x 20 . "\n"; print $atoken . "\n"; print "=" x 20 . "\n" ;
  print "This is REFRESH TOKEN:\n";  print "=" x 20 . "\n"; print $rtoken . "\n"; print "=" x 20 . "\n" ;
  qx [ sed -i.bak -e's|^\\(REFRESH_TOKEN[ =:\t]*\\).*\$|\\1$rtoken|' $gfile ] if ! $try ; 
  qx [ sed -i.bak -e's/^\\(ACCESS_TOKEN[ =:\t]*\\).*\$/\\1$atoken/'  $gfile ] if ! $try ; 
  1 ;
}

# クライアントIDとクライアントシークレット、リフレッシュトークン(計3個の情報)から、アクセストークンを取得する。
sub atoken ( $ ) { 
  my $try = $_[0] ;
  my $oauth = Net::Google::OAuth->new( -client_id => $cid, -client_secret => $csec ) ;
  my $x1 = $oauth -> refreshToken ( -refresh_token => $rtoken0 )  ;
  my $atoken = $oauth -> getAccessToken () ;
  say $atoken ;
  qx [ sed -i.bak -e's/^\\(ACCESS_TOKEN[ =:\t]*\\).*\$/\\1$atoken/' $gfile ] if ! $try ;
  # qxが\を解釈するので、この行を編集するときは要注意。
  # qxに sed で行末を表す$を渡す際に、$が何かPerlの変数として解釈されないように、\が前に必要。
  # sed では Mac だと -i に引数が必要。
  # sed では、\1 にキャプチャするための括弧は、元々\が必要。それをqxに渡す場合に\をさらに前に追加。
}

