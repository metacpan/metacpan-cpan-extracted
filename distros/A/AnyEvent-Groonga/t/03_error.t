use strict;
use warnings;
use AnyEvent::Groonga;
use Test::More tests => 4;
use Try::Tiny;

{
    my $g = AnyEvent::Groonga->new;
    $g->groonga_path("dummy");
    try {
        my $result
            = $g->call( select => { table => "test", query => "something" } )
            ->recv;
    }
    catch {
        like( $_, qr/can not find gronnga_path/ );
    }
}

{
    my $g = AnyEvent::Groonga->new;
    $g->protocol("local_db");
    $g->groonga_path("dummy");
    try {
        my $result
            = $g->call( select => { table => "test", query => "something" } )
            ->recv;
    }
    catch {
        like( $_, qr/can not find gronnga_path/ );
    }
}

{
    my $g = AnyEvent::Groonga->new;
    $g->protocol("dummy");
    try {
        my $result
            = $g->call( select => { table => "test", query => "something" } )
            ->recv;
    }
    catch {
        like( $_, qr/dummy is not supported protocol/ );
    }
}

{
    my $g = AnyEvent::Groonga->new;
    $g->protocol("http");
    try {
        my $result = $g->call( dummy => {} )->recv;
    }
    catch {
        like( $_, qr/dummy is not supported command/ );
    }
}
