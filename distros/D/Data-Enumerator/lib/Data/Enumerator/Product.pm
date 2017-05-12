package Data::Enumerator::Product;
use strict;
use warnings;
use base qw/Data::Enumerator::Base/;

sub __flatten{
    my ( $array ) = @_;
    return $array unless ref $array;
    return $array unless ref $array eq 'ARRAY';
    return @$array;
}

sub iterator {
    my ( $self ) = @_;
    my ( $a,$b ) = @{ $self->object };
    my $iter_a  = $a->iterator;
    my $iter_b  = $b->iterator;
    my $value_a = $iter_a->();
    my $iterator;$iterator = sub {
        while(1){
            my $value_b = $iter_b->();
            if( $self->is_last( $value_a )){
                # aが最後までいったら終了
                return $self->LAST;
            }
            if( $self->is_last($value_b)){
                # 最後まで行ったら、iterator再生成
                $iter_b = $b->iterator;
                # aを次の値にする
                $value_a = $iter_a->();
                # この条件でもう一度
                next;
            }
            return [__flatten($value_a),__flatten($value_b)];
        }
    };
    return $iterator;
}


1;
