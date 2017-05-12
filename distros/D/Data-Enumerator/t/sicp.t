use strict;
use warnings;
use Test::More;
use List::MoreUtils qw/uniq/;
use Data::Enumerator qw/pattern generator/;

=pod

Baker, Cooper, Fletcher, MillerとSmithは五階建てアパートの異なる階に住んでいる。
Bakerは最上階に住むのではない。Cooperは最下階に住むのではない。
Fletcherは最上階にも最下階にも住むのではない。
MillerはCooperより上の階に住んでいる。
SmithはFletcherの隣の階に住むのではない。
FletcherはCooperの隣の階に住むのではない。
それぞれはどの階に住んでいるか。

=cut
my $try = generator(
    {   Baker    => pattern( 1 .. 5 ),
        Cooper   => pattern( 1 .. 5 ),
        Fletcher => pattern( 1 .. 5 ),
        Miller   => pattern( 1 .. 5 ),
        Smith    => pattern( 1 .. 5 ),
    })
    ->where(
        # 全員が異なる階に済んでいる
        sub { is_uniq( values %{ $_[0] } ); } )
    ->where( 
        # Bakerは最上階でない
        sub  { not( $_[0]->{Baker} == 5 ); } )
    ->where( 
        # Cooperは最下階でない
        sub  { not( $_[0]->{Cooper} == 1 ) } )
    ->where(
        # Fletcherは最上階にも最下階にも住むのではない。
        sub {
         not(  ( $_[0]->{Fletcher} == 1 )
            or ( $_[0]->{Fletcher} == 5 ) );
        })
    ->where(
        # MillerはCooperより上の階に住んでいる。
        sub {( $_[0]->{Miller} > $_[0]->{Cooper} )})
    ->where(
        # SmithはFletcherの隣の階に住むのではない。
        sub { not ( abs( $_[0]->{Smith} - $_[0]->{Fletcher} ) == 1 );})
    ->where(
        # FletcherはCooperの隣の階に住むのではない。
        sub { not ( abs( $_[0]->{Fletcher} - $_[0]->{Cooper} ) == 1 );});

sub is_uniq {
    my (@list) = @_;
    return ( scalar( uniq(@list) ) == scalar @list );
}

is_deeply( $try->list,{ Baker => 3, Cooper => 2, Fletcher => 4, Miller => 5, Smith => 1 });
::done_testing;
