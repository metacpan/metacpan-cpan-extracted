package Acme::PrettyCure::Girl::CurePeace;
use utf8;
use Moo;

use Math::Random::MT;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Smile/;

has janken_db => (
    is         => 'ro',
    isa        => sub { die "$_[0] is not ArrayRef" if ref($_[0]) ne 'ARRAY' },
    default    => sub {
        [
            qw(0 0 チョキ パー グー チョキ チョキ グー チョキ パー グー パー
              チョキ グー パー グー パー チョキ チョキ パー グー パー チョキ
              パー チョキ パー パー グー チョキ グー パー 0 グー パー チョキ
              グー パー グッチョッパー 0 0 チョキ 0 0 0 チョキ 0 0 0)
        ];
    },
);

sub human_name   {'黄瀬やよい'}
sub precure_name {'キュアピース'}
sub age          {14}
sub challenge { 'ピカピカぴかりんじゃんけんぽん♪ キュアピース!' }
sub challenge_with_jankenpon {
    my ($self, $story_no) = @_;

    my $gen = Math::Random::MT->new();
    my $jankenpon = $story_no ? $self->janken_db->[$story_no-1] 
                              : ( qw/グー チョキ パー/ )[ $gen->rand(3) ];
    $jankenpon ||= "";
    my $words     =  $_[0]->challenge();
    $words =~ s/(?=♪)/（$jankenpon）/;
    return $words;
}
sub color { 226 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/images/character/c3_1.jpg' }

1;
