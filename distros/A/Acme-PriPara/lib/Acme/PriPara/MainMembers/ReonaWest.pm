package Acme::PriPara::MainMembers::ReonaWest;
use Mouse;
extends 'Acme::PriPara::MainMembers';
use utf8;

no Mouse;

sub name {
    my ($self) = @_;
    return $self->firstname . '・' . $self->lastname;
}

sub pripara_change {
    my ($self, $twin) = @_;
    $self->{has_pripara_changed} = 1 if ref $twin eq 'Acme::PriPara::MainMembers::DorothyWest';
}


1;

__DATA__

@@ ReonaWest
firstname: レオナ
lastname: ウェスト
age: 13
birthday: 2/5
blood_type: A
cv: 若井友希
costume_brand: Fortune Party
color: レッド
