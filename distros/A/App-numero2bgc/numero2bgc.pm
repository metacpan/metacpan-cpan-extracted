package App::numero2bgc ;  
our $VERSION = '0.021' ; 
our $DATE = '2022-10-29T21:46+09:00' ; 

=encoding utf8

=head1 NAME

App::numero2bgc - Put colors on the background of each number from input text.

=head1 SYNOPSIS

 numero2bgc

   入力のテキストを読み取り、数値の部分を (Regexp::Commons::number を使って)
   抽出して、背景に ANSIエスケープシーケンスによる色を付ける。
   最小値は青、緑を経由して、最大値は赤。15段階。
   (出現数値をuniq化した上で、28分位点をとり、奇数番目の値14個を抽出して、
   それを閾値として、色は段階的に変化させる。) 

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

1 ;
