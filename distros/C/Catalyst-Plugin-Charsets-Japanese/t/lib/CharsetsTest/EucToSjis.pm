package CharsetsTest::EucToSjis;

use strict;
use warnings;

use Catalyst qw/Charsets::Japanese/;
use Jcode;

sub foo : Global {
    my ($self, $c ) = @_;
    my $bar = $c->req->param('bar');
    my $text = Jcode->new('日本語', 'utf8')->sjis;
    $c->res->content_type('text/plain');
    if ($bar eq $text) {
        $c->res->body("bar is Shift_JIS");
    }
    else {
        $c->res->body("bar is not Shift_JIS");
    }
}

sub buz : Global {
    my ($self, $c ) = @_;
    $c->res->content_type('text/plain');
    $c->res->body(Jcode->new('日本語', 'utf8')->sjis);
}

__PACKAGE__->config( charsets => { out => 'EUC-JP', in => 'Shift_JIS'} );
__PACKAGE__->setup;

1;

