package Acme::PrettyCure::Girl::Role::DokiDoki;
use utf8;
use Moo::Role;

sub _excla {
    '!' x (scalar(@_)+1);
}

before 'transform' => sub {
    my ($self, @buddies) = @_;

    unless ($buddies[0] && $buddies[0]->is_precure) {
        my $excla = _excla @buddies;
        $self->say(sprintf 'プリキュア%s ラブリンク%s L・O・V・E%s', $excla, $excla, $excla);
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

    if (scalar(@buddies) == 0) {
        # Only some of the messages call out to the user by name (%s).
        my $message = $self->message;
        $message = sprintf $message, scalar getpwuid $> if $message =~ /%s/;
        $self->say($message);
    } elsif($first) {
        my $excla = _excla @buddies;
        $self->say(sprintf '響け、愛の鼓動%s ドキドキ!プリキュア%s', $excla, $excla);
    }
};



1;

