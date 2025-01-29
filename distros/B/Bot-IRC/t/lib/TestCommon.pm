package TestCommon;

use Test2::Mock;
use exact;
use exact::class;
use Bot::IRC::Store;
use Bot::IRC;

has mock_store => undef;
has mock_bot   => undef;
has bot        => undef;
has hook_ref   => undef;
has replies    => sub { [] };

around new => sub {
    my ( $orig, $self ) = @_;

    $self = $orig->($self);

    $self->mock_store(
        Test2::Mock->new(
            class    => 'Bot::IRC::Store',
            override => [ qw( new get set ) ],
        )
    );

    $self->mock_bot(
        Test2::Mock->new(
            class    => 'Bot::IRC',
            override => [
                hook     => sub { $self->hook_ref( \$_[2] ) },
                reply    => sub { shift; push( @{ $self->replies }, [@_] ) },
                reply_to => sub { shift; push( @{ $self->replies }, [@_] ) },
            ],
        )
    );

    $self->bot( Bot::IRC->new( connect => { server => 'irc.perl.org' } ) );

    return $self;
};

sub hook {
    my ( $self, $in, $m ) = @_;
    $self->hook_ref->( $self->bot, $in, $m );
}

1;
