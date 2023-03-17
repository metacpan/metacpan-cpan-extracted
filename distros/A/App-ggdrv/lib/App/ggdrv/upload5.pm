package App::ggdrv::upload5 ; 
use strict ; 
use warnings ; 
use feature qw [ say ] ; 
use FindBin qw [ $Bin ] ;
use Getopt::Std ; 
use Cwd ; 
use Carp ;
return 1 ;

sub upload5 { 
  getopts 'm:n', \my %o ;
  $o{m} //= 'text/plain' ;
  $ARGV[1] //= '.' ; # ローカルのディレクトリ名。
  my $cwd = getcwd ;
  chdir $ARGV[1] or die ; 
  my @files = grep { -f } <*>  ; # ディレクトリは対象外となる。
  my $out = '' ; # 
  #print qx[ $FindBin::Bin/upload11.pl -m $o{m} -f $ARGV[0] $_ ] for @files ; 
  do { print qx [ $0 upload -20 -m $o{m} -f $ARGV[0] $_ ] for @files } if ! $o{n} ; 
  do { say qq [ $0 upload -20 -m $o{m} -f $ARGV[0] $_ ] for @files } if $o{n} ; 
  chdir $cwd ;
}


=encoding utf8

=head1

 ggdrive updoad5 FOLDER_ID LOCAL_DIR > VAR_FILE

  FOLDER_ID : GoogleドライブのフォルダーのID (33文字)
  LOCAL_DIR : ローカルのディレクトリ。そこの直下にある通常ファイルが全てアップロードされる。未指定だと . (現行ディレクトリ)。
  VAR_FILE : 5列のTSV形式ファイルとなる。各行は「HTTPステータスコード 新規のファイルID ファイル名 MIMETYPE "drive#file"」

  約1.5秒ごとに1ファイルアップロードするであろう(sleepではない。グーグルドライブ側でそれだけの時間がかかる)。

 オプション : 

  -m MIMETYPE : MIMEタイプを指定する。
  -n : ドライランになる。単に実行するコマンドを出力する。


=cut
