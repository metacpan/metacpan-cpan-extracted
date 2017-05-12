package AutoCode::Compare;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);

our @REGULAR_REF=qw(SCALAR ARRAY HASH);

use constant FALSE=>0;
use constant TRUE =>1;

sub equal {
    my ($class, @array)=@_;
    my @refs=map{ref($_)}@array;
    return 0 unless $refs[0] eq $refs[1];
    my $ref=$refs[0];
    if($ref eq ''){
        return $array[0] eq $array[1];
    }
    my ($x, $y)=@array;
    return TRUE if ref($x) eq ref($y);
    
    if(grep /^$ref$/, @REGULAR_REF){
        my $method="equal_\L$ref";
        return $class->$method(@array);
    }else{
        return $class->equal_object(@array);
    }
}

sub equal_scalar {
    my $class=shift;
    my @scalars=map{my $z=$_; ${$z}}@_;
    return $class->equal(@scalars);
}

sub equal_array {
    my $class=shift;
    my ($x, $y)=@_;
    my @x=@$x;
    my @y=@$y;
    my $max=scalar(@x);
    return FALSE unless $max == scalar(@y);
    return TRUE if $max==0;
    for(my $i=0; $i<$max; $i++){
        return FALSE unless $class->equal($x[$i], $y[$i]);
    }
    return TRUE;
}

sub equal_hash {
    my $class=shift;
    my ($x, $y)=@_;
    my %x=%$x;
    my %y=%$y;
    my @keys=keys %x;
    my $max=scalar(@keys);

    return FALSE unless $max==scalar(keys %y);
    return TRUE if $max==0;

    my $found=0;
    foreach (@keys){
        $found++ if exists $y{$_};
    }
    return FALSE unless $found==$max;

    foreach my $key(@keys){
        return FALSE unless $class->equal($x{$key}, $y{$key});
    }
    return TRUE;
}

sub equal_obj {
    my $class=shift;
    my @array=@_;
    my ($x)=@_;
    my $string="$x";
    $string =~ /^([^=]*=)?(\w+)\((\w+)\)$/;
    my $internal_structure=$2;
    local $_=$internal_structure;
    if(/^ARRAY$/){
        return $class->equal_array(@array);
    }elsif(/^HASH$/){
        return $class->equal_hash(@_);
    }
}

1;
    
