
=head1 NAME

Bot::BasicBot::Pluggable::Module::GoodWithHatenaStar - Tracks Good for people

=head1 SYNOPSIS

Tracks Good for people

=head1 IRC USAGE

Commands:

=over 4

=item <thing>++ # <comment>

Increases the kerma for <thing>

=back

=cut

package Bot::BasicBot::Pluggable::Module::GoodWithHatenaStar;
use strict;
use warnings;
use Carp;
use WWW::HatenaStar;

our $VERSION = '0.01';
use base qw(Bot::BasicBot::Pluggable::Module);

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    if ( $pri == 0 ) {
        if ( $body =~ /([A-Za-z][-A-Za-z\d_]{1,30}[A-Za-z\d])\+\+/ )
        {
            $self->good($1);
        }
    }
}

sub good {
    my ( $self, $who ) = @_;
    my $url = 'http://d.hatena.ne.jp/' . $who . '/';
    $self->add_stars($url);
}

sub add_stars {
    my ( $self, $uri ) = @_;
    croak 'username must be set' unless $self->{Param}->{username};
    croak 'password must be set' unless $self->{Param}->{password};

    my $star = WWW::HatenaStar->new(
        {   config => {
                username => $self->{Param}->{username},
                password => $self->{Param}->{password}
            }
        }
    );
    my $count = $self->{Param}->{count} || 5;
    $star->stars( { uri => $uri, count => $count } );
    $count;
}

1;
