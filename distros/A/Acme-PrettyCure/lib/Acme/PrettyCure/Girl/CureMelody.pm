package Acme::PrettyCure::Girl::CureMelody;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Suite/;

use List::MoreUtils qw/any/;

sub human_name   {'北条響'}
sub precure_name {'キュアメロディ'}
sub age          {14}
sub challenge { '爪弾くは荒ぶる調べ! キュアメロディ!' }
sub color { 199 }
sub image_url { 'http://www.toei-anim.co.jp/tv/suite_precure/character/00_01/01.jpg' }

before 'transform' => sub {
    my ($self, @buddies) = @_;

    die "奏がいないと変身できないニャ!" unless any {ref($_) =~ /CureRhythm/} @buddies;

    unless ($buddies[0] && $buddies[0]->is_precure) {
        $self->say('絶対に許さない' . ('!' x (scalar(@buddies)+1)) );
    }
};

1;
