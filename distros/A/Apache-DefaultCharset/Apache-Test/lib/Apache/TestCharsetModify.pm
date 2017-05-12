package Apache::TestCharsetModify;
use strict;
use Apache::DefaultCharset;

sub handler {
    my $r = shift;
    my $charset = Apache::DefaultCharset->new($r);
    $charset->name('euc-kr');
    $r->send_http_header('text/html');
    $r->print("charset:$charset");
}

1;
