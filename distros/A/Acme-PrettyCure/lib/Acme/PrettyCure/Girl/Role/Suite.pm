package Acme::PrettyCure::Girl::Role::Suite;
use utf8;
use Moo::Role;

our $SUITE = [
    '',
    'ふたり',
    '三人',
    'みんな',
];

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
        $self->say('届け、' . $SUITE->[scalar(@buddies)] . 'の組曲!');
        $self->say('スイートプリキュア' . ('!' x (scalar(@buddies)+1)) );
    }
};



1;

