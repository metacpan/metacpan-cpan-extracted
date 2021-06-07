package App::venn ;  
our $VERSION = '0.101' ; 
our $DATE = '2021-06-06T13:33+09:00' ; 

=encoding utf8

=head1 NAME

App::venn

=head1 SYNOPSIS

This module provides a Unix-like command `F<venn>'. 
It has a function upon multiple files equivalently draw the Venn Diagam,
although the output shape is quite different as summarized in a TSV table.

=head1 DESCRIPTION

venn ── 複数の集合のベン図のように整理して表示

　ベン図は複数の集合の関係を示します。2個か3個の円を重ね合わて集合の重なりを示す図を数学の教科書で見たことは無いでしょうか。
この例では、ファイルを4個用意する代わりに、プロセス置換を4個同時に使って実験しています。
また実演用に自作シェル関数yをここで最初に定義しています(引数を1文字ずつばらして、改行を挿入する働きをyに持たせます)。

$ function y(){ echo -n $* | perl -pe's/./$&\n/g' } # ← Defined a shell function to demo the next. ↓

$ venn <(y ABCCCC) <(y AABDEF) <(y ABBDEF) <(y DEEEF) # Each <(...) means the process substitution. Each is treated as a file as the result of the contained command. Out follows next 4 lines:

  cardi. file1  file2  file3  file4  strmin strmax
  2.     2      3      3      0      "A"    "B"
  1.     4      0      0      0      "C"
  3.     0      3      3      5      "D"    "F"

　この例では、あたかも{A,B,C,C,C,C}と{A,A,B,D,E,F}と{A,B,B,D,E,F}と{D,E,E,E,F}に相当する4個のファイルがあって、
それぞれは改行区切りで1文字ずつ格納されています。そのようなファイル群(以下、fiel1〜4とする)がvennに与えられています。

　その出力は次のような意味になります。 A,B,C,D,E,Fの6個の文字列は3個のグループに分割されて、
 A〜Bと、Cと、D〜Fになります(右側2列を参照)。 それぞれの異なる要素の数は2,1,3個です(左側1列目ピリオド付きの数を参照)。 
 それらはfile1〜4のどれに「含まれているか／含まれないか」のパターンが 中の4列で「0であるか／0以外の数であるか」で示します。
 0以外の数である場合にその数は、 「文字列がのべ何回含まれているか」を3グループ×4ファイルの全組合せごとに示します。
 最初に書いた「3パターン」とは、異なる6通りのA〜Fの文字列のそれぞれについて4ファイルに「現れたか／否か」を「1／0」で
 表現したときに、Aは1110、Bは1110、Cは1000、Dは0111、Eは0111、Fは0111となって、これら6パターンは異なる3バターンに
 分類出来て、その分類を各グループとしていたのでした。

　このコマンドvennは、多数のファイルに対して、 値の包含関係や重なりを一目で把握するのに便利です。 上記の例だと、
 CとD〜Fは同じファイルに出現しない事が0のパターンから読み取れますし、 file1の持つ2+1+0=3個の文字列とfile4の0+0+5=5個の
 文字列は、 共通部分が無いことが0の出現パターンから読み取れます。 他、たとえばCという文字列は、file1のみにそれ以外に現れず、
 そしてそのような出現パターンを示すのは文字列はCのみに限り、出現回数は4+0+0+0=4であることも読み取れます。

　このvennは実務で使うと非常に便利で、複数ファイルに現れるデータの重なり具合について、多くの知見が一目で得られます。


=head1 SEE ALSO


=cut

1 ;
