package Data::Cube;
use 5.008005;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Data::Nest;
use Scalar::Util qw/looks_like_number/;

our $VERSION = "0.02";

sub new {
    my $self = shift;

    my @dims = @_;

    bless {
        cells    => {},

        dims     => [@dims],
        currentdims => [@dims],
        records  => [],
        measures => {"count", sub { my @data = @_; scalar @data;}},
        hiers    => {},
        invHiers    => {},
        cells    => undef,
    }, $self;
};

# cubeの複製
sub clone {
    my $self = shift;
    my $cube = new Data::Cube();
    $cube->{dims} = $self->{dims};
    $cube->{currentdims} = $self->{currentdims};
    $cube->{measures} = $self->{measures};
    $cube->{hiers} = $self->{hiers};

    $cube;
}

############################################################
# utility functions
#
# 文字列/数値を比較する
sub is_same {
    my $self = shift;
    my ($a, $b) = @_;
    if(looks_like_number($a) and looks_like_number($b)){
        return 1 if $a == $b;
    }elsif(looks_like_number($a)){
        return 1 if $a == $b;
    }else{
        return 1 if $a eq $b;
    }
    0;
}

# 条件フィルター
sub recordFilter {
    my $self = shift;
    my $cond = shift;
    my $record = shift;

    return if(ref $cond ne "HASH");
    return if(ref $record ne "HASH");

    for my $key (keys %$cond){
        return 0 unless exists $record->{$key};
        my $val = $cond->{$key};
        if(ref $val eq "CODE"){
            return 0 unless $val->($record->{$key});
        }elsif(ref $val eq "ARRAY"){
            return 0 unless ($val->[0] <= $record->{$key} and $record->{$key} <= $val->[1]);
        }else{
            return 0 unless $self->is_same($val, $record->{$key});
        }
    }
    1;
}

############################################################
# data put
#
# データを追加する
sub put {
    my $self = shift;
    my @data = @_;

    if(scalar @data == 1 and ref $data[0] eq 'ARRAY'){
        @data = @{$data[0]};
    }
    for my $dat (@data){
        push @{$self->{records}}, $dat;
    }
};

############################################################
# dimension
#
# 次元の取得
sub get_dimension {
    my $self = shift;
    $self->{dims};
};

# 現在の次元値の取得
sub get_current_dimension {
    my $self = shift;
    $self->{currentdims};
};

# 現在の順序の変更
sub reorder_dimension {
    my $self = shift;
    $self;
}

sub get_dimension_component {
    my $self = shift;
    my $dim = shift;
    return {} unless $dim;

    my %components;
    for my $record (@{$self->{records}}){
        next unless exists $record->{$dim};
        $components{$record->{$dim}} = 0 unless $components{$record->{$dim}};
        $components{$record->{$dim}}++;
    }
    \%components;
}

# 次元の追加
sub add_dimension {
    my $self = shift;
    my $dim = shift;
    push @{$self->{dims}}, $dim;
    push @{$self->{currentdims}}, $dim;
    $self;
};

# 次元の削除
sub remove_dimension {
    my $self = shift;
    my $rmdim = shift;
    while(my ($i, $dim) = each @{$self->{dims}}){
        if($self->is_same($dim, $rmdim)){
            splice @{$self->{dims}}, $i, 1;
            splice @{$self->{currentdims}}, $i, 1;
            last;
        }
    }
    $self;
};

############################################################
# hierarchy
#
# 階層の追加
sub add_hierarchy {
    my $self = shift;
    my $child = shift;
    my $parent = shift;
    my $rule = shift;

    $self->{hiers}{$parent} = $child;
    $self->{invHiers}{$child} = $parent;

    if($rule and ref $rule eq "CODE"){
        foreach my $record (@{$self->{records}}){
            $record->{$parent} = $rule->($record->{$child});
        }
    }
    $self;
}

############################################################
# measure
#
# 演算をセットする
sub add_measure {
    my $self = shift;
    my $name = shift;
    my $func = shift;

    # TODO: validation

    $self->{measures}{$name} = $func;
    $self;
};

############################################################
# cube methods
#
# 一つの要素についてより詳細な分割を行う
sub drilldown {
    my $self = shift;
    my @dims = @_;

    for my $dim (@dims){
        if($self->{hiers}{$dim}){
            my $cdim_cnt = 0;
            for my $cdim (@{$self->{currentdims}}){
                if ($self->is_same($cdim, $dim)){
                    $self->{currentdims}[$cdim_cnt] = $self->{hiers}{$dim};
                    $cdim_cnt++;
                }
            }
        }
    }
    $self;
};

# いくつかの要素を一つの要素にまとめ上げる
sub drillup {
    my $self = shift;
    my @dims = @_;

    for my $dim (@dims){
        if($self->{invHiers}{$dim}){
            my $cdim_cnt = 0;
            for my $cdim (@{$self->{currentdims}}){
                if ($self->is_same($cdim, $dim)){
                    $self->{currentdims}[$cdim_cnt] = $self->{invHiers}{$dim};
                    $cdim_cnt++;
                }
            }
        }
    }
    $self;
};


# ひとつの要素を固定し取り出す
sub slice {
    my $self = shift;
    my %cond = @_; # sliceの条件

    my $slicedDice = $self->dice(%cond)->rollup();
    if($slicedDice){
        return $slicedDice->[0];
    }
    return undef;

};

# サブキューブを取り出す
#
# $cube->dice(Country => "US", Product => "Pencil")
#
sub dice {
    my $self = shift;
    my %ranges = @_;

    my $subCube = $self->clone();
    my @subRecords = grep { $self->recordFilter(\%ranges, $_); } @{$self->{records}};
    $subCube->{records} = \@subRecords;
    $subCube;
};

# すべてのセルで演算を行う
sub rollup {
    my $self = shift;
    my %opt = @_;

    my @Dims = @{$self->{currentdims}};

    my $nest = new Data::Nest(%opt);
    foreach my $dim (@Dims){
        $nest->key($dim);
    }
    foreach my $name (keys %{$self->{measures}}){
        $nest->rollup($name, $self->{measures}{$name});
    }
    $nest->keyname("dim");
    $self->{cells} = $nest->entries($self->{records});
    $self->{cells};
};

############################################################
# measures
#
# 日付表示から月表示への変形
sub fromDateToMonth {
    my $d = shift;
    warn $d."\n";
    if($d =~ /^(\d+)\/(\d+)\/(\d+)/){
        my ($m, $d, $Y) = ($1, $2, $3);
        return "$Y/$m";
    }
    undef;
};

1;
__END__

=encoding utf-8

=head1 NAME

Data::Cube - It's new $module

=head1 SYNOPSIS

    use Data::Cube;

    my $cube = new Data::Cube("Product", "Country"); # specify dimension

=head1 DESCRIPTION

Data::Cube is perl implementation of [DataCube](http://en.wikipedia.org/wiki/OLAP_cube).
DataCube is concept in order to process multidimensional data array.

==head2 METHODS

    my $cube = new Data::Cube();
    $cube->add_dimension();
    $cube->add_hierarchy();
    $cube->add_measure();

    $cube->reorder_dimension();

    $cube->dice();
    $cube->slide();

    $cube->rollup();

=head1 LICENSE

Copyright (C) muddydixon.
Apache License Version 2.0

=head1 AUTHOR

muddydixon E<lt>muddydixon@gmail.comE<gt>

=cut
