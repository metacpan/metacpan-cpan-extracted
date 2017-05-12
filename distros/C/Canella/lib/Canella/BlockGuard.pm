package Canella::BlockGuard;
use Moo;
use Guard ();

has name => (
    is => 'ro',
    required => 1,
);

has guard => (
    is => 'ro',
    required => 1,
    handles => [ qw(cancel) ],
);

has should_fire_cb => (
    is => 'ro',
    required => 1,
);

sub BUILDARGS {
    my ($class, %args) = @_;

    if ( my $code = delete $args{code} ) {
        $args{guard} = Guard::guard(\&$code);
    }

    $args{name} ||= join ".", "block_guard", time(), {}, $$, rand();
    return \%args;
}

sub should_fire {
    $_[0]->should_fire_cb->(@_);
}

1;
