package Acme::PriPara::MainMembers::HojoSophy;
use Mouse;
extends 'Acme::PriPara::MainMembers';
use utf8;

no Mouse;

sub pripara_change { #override
    my ($self, $option) = @_; 
    return unless (defined $option && $option eq 'Red Flash');
    $self->{has_pripara_changed} = 1;
}

1;

__DATA__

@@ HojoSophy
firstname: そふぃ
lastname: 北条
age: 14
birthday: 7/30
blood_type: AB
cv: 久保田未夢
costume_brand: Holic Trick
color: パープル
