
use strict;
use warnings;
use Test::More;
use Beam::Emitter;
BEGIN {
    eval { require Test::LeakTrace; Test::LeakTrace->import( 'no_leaks_ok' ) };
    if ( $@ ) {
        plan skip_all => 'Test::LeakTrace required for this test';
        exit;
    }
    if ( $ENV{COVERAGE} ) {
        plan skip_all => 'Fails during coverage tests ($ENV{COVERAGE}=1). Skipping';
        exit;
    }
}

{
    package My::Emitter;
    use Moo;
    with 'Beam::Emitter';
}


no_leaks_ok {
    my $b = My::Emitter->new;
    my $cb; $b->on( foo => $cb = sub { $_[0]->emitter->un( foo => $cb ); undef $cb } );
    $b->emit( 'foo' );
};

no_leaks_ok {
    my $b = My::Emitter->new;
    my $cb; $cb = $b->on( foo => sub { $cb->() } );
    $b->emit( 'foo' );
};

no_leaks_ok {
    my $b = My::Emitter->new;
    my $cb; $cb = $b->on( foo => sub { $cb->() } );
};

no_leaks_ok {
    my $b = My::Emitter->new;
    my $cb; $cb = $b->on( foo => sub { } );
    $b->emit( 'foo' );
    $cb->();
};

done_testing;
