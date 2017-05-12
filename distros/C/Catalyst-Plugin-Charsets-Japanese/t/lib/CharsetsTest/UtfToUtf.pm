package CharsetsTest::UtfToUtf;

use strict;
use warnings;

use Catalyst qw/Charsets::Japanese/;
use Jcode;

sub foo : Global {
    my ($self, $c ) = @_;
    my $bar = $c->req->param('bar');
    my $text = Jcode->new('日本語', 'utf8')->utf8;
    utf8::decode($text) unless utf8::is_utf8($text);
    $c->res->content_type('text/plain');
    if ($bar eq $text) {
        $c->res->body("bar is UTF-8");
    }
    else {
        $c->res->body("bar is not UTF-8");
    }
}

sub buz : Global {
    my ($self, $c ) = @_;
    $c->res->content_type('text/plain');
    $c->res->body(Jcode->new('日本語', 'utf8')->utf8);
}

__PACKAGE__->config( charsets => { out => 'UTF-8', in => 'UTF-8'} );
__PACKAGE__->setup;

1;

