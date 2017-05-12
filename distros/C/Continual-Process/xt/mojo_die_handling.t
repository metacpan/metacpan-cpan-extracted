use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval { require Mojo::IOLoop; Mojo::IOLoop->import; 1 }) {
        plan skip_all => "Mojo::IOLoop is required for this test";
    }
}

use Mojo::IOLoop;
use v5.12;
use Test::Exception;

lives_ok {
    Mojo::IOLoop->timer(
        0 => sub { die 'test' }
    );
    
    Mojo::IOLoop->timer(
        0 => sub { say 'test' }
    );
    
    
    Mojo::IOLoop->one_tick();
} 'die is only printed to stderr';

done_testing(1);
