use strict;
use warnings;
use lib qw(lib);

use Test::More tests => 2;
use AnyEvent;
use AnyEvent::Mac::Pasteboard;

my $TIMEOUT_SEC = 3;

diag("wait $TIMEOUT_SEC seconds for test.");

sub say { print @_, "\n"; }

my $cv = AE::cv;

my $paste_tick1 = new_ok( 'AnyEvent::Mac::Pasteboard', [
    multibyte => 1,
    interval  => 3,
    on_change => sub {
        my $content = shift;
        #say "on_change execute";
        #say qq(content is "$content");
    },
    on_unchange => sub {
        my $content = shift;
        #say "on_unchange execute";
        #say qq(content is "$content");
    },
    on_error => sub {
        #say "on_error execute. throw process.";
        $cv->send;
    },
], "interval simple digit version");

my $paste_tick2 = new_ok( 'AnyEvent::Mac::Pasteboard', [
    multibyte => 1,
    interval  => [1,1,2,2,3,4,5],
    on_change => sub {
        my $content = shift;
        #say "on_change execute";
        #say qq(content is "$content");
    },
    on_unchange => sub {
        my $content = shift;
        #say "on_unchange execute";
        #say qq(content is "$content");
    },
    on_error => sub {
        #say "on_error execute. throw process.";
        $cv->send;
    },
], "interval arrayref that contains some digits version");

my $timeout = AE::timer $TIMEOUT_SEC, 0, sub { $cv->send(); };

$cv->recv;
