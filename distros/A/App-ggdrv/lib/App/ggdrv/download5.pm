package App::ggdrv::download5 ;
use strict ; 
use warnings ; 
use feature qw [ say ] ; 
use FindBin qw [ $Bin ] ; 
use Getopt::Std ; 
use Cwd ;

return 1 ; 

sub download5 { 
  getopts 'p', \my %o ;
  $ARGV[0] //= '.' ;
  my $cwd = getcwd  ;
  my $dir = shift @ARGV ; # ここで shift しないと、次の while(<>)が機能しない。
  qx [ mkdir -p $dir ] if $o{p} ; 
  chdir $dir or die  ;   # say cwd ; exit ;   say cwd ;
  while ( <> ) {
    chomp ; 
    my @F = split /\t/ , $_ ;
    my $cmd = "$0 download -20 $F[1] $F[2]" ;
    print $cmd ;
    qx[ $cmd ] ; 
    say "" ; 
  }
  chdir $cwd ;
}



=encoding utf8

=head1

 ggdrv download5 LOCAL_DIR < VAR_FILE
  LOCAL_DIR : ローカルのディレクトリ。
  VAR_FILE : 5列のTSV形式ファイルとなる。 "200   FILE_ID  FILE_NAME   MIMETYPE   drive#file"
  約1.5秒ごとに1ファイルをダウンロードするであろう。

 オプション : 
  -p  : mkdir -p LOCAL_DIR する。
 

=cut
