package App::ggdrv::crecord ; 
use Term::ANSIColor qw[ color :constants ] ; $Term::ANSIColor::AUTORESET = 1 ;
	
sub crecord { 

$| = 1 ;
my $run = $_[0] ;
my $GFILE = $ENV{ GGDRV_API } // "~/.ggdrv2303v1" ;
print YELLOW << "EOB1" if ! $run ;
下記をコピペして実行せよ。そして、生成されたファイル(すぐ次の行)を直接編集して、EMAIL, CLIENT_ID, CLIENT_SECRET の3個の値を設定せよ。
コピペして実行する代わりに「$0 crecord --run 」を実行しても良い。その場合も生成された $GFILE を手動で3個の値を編集せよ。
これら3個の値は、console.cloud.google.com の (使っているプロジェクトの)「APIとサービス」の「認証情報」を見れば良いであろう。
EOB1

my $cmd = << "EOB1" ;
GGDRV_API=$GFILE
touch \$GGDRV_API 
chmod 600 \$GGDRV_API # 他のユーザーに書き込んだファイルは読めないようにするパーミッションの設定が必要だったと思われる。
cat > \$GGDRV_API << EOF
##
## このファイルは、キーとバリューの形式で情報を読み取るプログラムに使われる。
##  * キーとバリューの間は 半角空白、タブ文字、コロン(:)、イコール文字(=)とその組合せのみが許容される。
##  * バリューの文字列は、改行文字の直前までであることを想定している。
##  * コメントアウトの書式は想定されない。
##  * バリュー(値;左から2列目)を削除したい場合、その左側の1列(キー)を表す文字列は残すこと。後で再び何かのプログラムが書き込むことがあるからである。
##
##  初めてこのスクリプトを実行する前に、下記の項目を GCPのコンソールの「APIとサービス」の「認証情報」からひとつをクリックして、
##  IDとsecretをコピーして、下記にペーストすることになるであろう。
##
 
EMAIL			tulamili@gmail.com
CLIENT_ID		5......................apps.googleusercontent.com
CLIENT_SECRET   G......RJ0g3N32cCw9
 
# 次の値は、それぞれ、6ヶ月、60分間、不使用が続くと、更新が必要である(以下は手動編集をしなくても、ggdrvによりコマンドで設定可能)。
REFRESH_TOKEN	1//0e...(103文字;途中で2個のスラッシュ文字を含む。sedやperlでs関数を使う時など区切り文字に気をつけること)..
ACCESS_TOKEN	ya29....(165文字)...................................................
EOF
EOB1

print ON_BRIGHT_BLACK BOLD $cmd ;
do { qx [ $cmd ] ; print BRIGHT_RED "The above commands are executed !! "} if $run ;
print color('reset') ;

1 ; 

}
