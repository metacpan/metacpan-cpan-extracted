package CharsetsTest::SjisToEuc;

use strict;
use warnings;

use Catalyst qw/Charsets::Japanese/;
use Jcode;

sub foo : Global {
    my ($self, $c ) = @_;
    my $bar = $c->req->param('bar');
    my $text = Jcode->new('日本語', 'utf8')->euc;
    $c->res->content_type('text/plain');
    if ($bar eq $text) {
        $c->res->body("bar is EUC-JP");
    }
    else {
        $c->res->body("bar is not EUC-JP");
    }
}

sub buz : Global {
    my ($self, $c ) = @_;
    $c->res->content_type('text/plain');
    $c->res->body(Jcode->new('日本語', 'utf8')->euc);
}

__PACKAGE__->config( charsets => { out => 'Shift_JIS', in => 'EUC-JP'} );
__PACKAGE__->setup;

1;

