
use strict;
use lib qw(blib/lib);
use Acme::Void;

push my @test, sub {

    eval {
	void->foo;
    };
    return if $@;

    return 1;
},

sub {

    eval {
	void->void;
    };
    return if $@;

    return 1;
},

sub {

    eval {
	void()->foo;
    };
    return if $@;

    return 1;
},

sub {

    eval {
	void void->void;
    };
    return if $@;

    return 1;
},

sub {

    eval {
	void = void->void;
    };
    return if $@;

    return 1;
},

;

sub foo { 1 }

printf "1..%d\n", scalar @test;
for(0..$#test){
    $test[$_]->()
	or print "not ";

    printf "ok %d\n", $_ + 1;
}

