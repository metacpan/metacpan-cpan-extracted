package Acme::PrettyCure::Girl::Role::Fresh;
use utf8;
use Moo::Role;

before 'transform' => sub {
    my ($self, @buddies) = @_;

    unless ($buddies[0] && $buddies[0]->is_precure) {
        $self->say('チェインジ・プリキュア! ビートアップ' . ('!' x (scalar(@buddies)+1)) );
    }
};

after 'transform' => sub {
    my ($self, @buddies) = @_;

    my $first = 0;
    unless ($buddies[0] && $buddies[0]->is_precure) {
        $first = 1;
    }

    for my $buddy (@buddies) {
        unless ($buddy->is_precure) {
            $buddy->transform($self);
        }
    }

    if ($first) {
        $self->say('フレッシュプリキュア' . ('!' x (scalar(@buddies)+1)) );
    }
};



1;

