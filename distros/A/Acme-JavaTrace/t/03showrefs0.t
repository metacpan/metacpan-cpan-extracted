use strict;
use Test::More tests => 4;
use Acme::JavaTrace;

my $text = "Advice from Klortho #11901: You can't just make shit up and expect the computer to know what you mean, Retardo!";

eval {
    die bless { type => 'error', text => $text }, 'Exception'
};

isa_ok( $@, 'HASH' );
isa_ok( $@, 'Exception' );
is( $@->{text}, $text, "checking the field text" );
is( $@->{type}, 'error', "checking the field text" );
