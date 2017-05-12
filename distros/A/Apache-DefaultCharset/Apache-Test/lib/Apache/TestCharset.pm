package Apache::TestCharset;
use strict;
use Apache::DefaultCharset;

sub handler {
    my $r = shift;
    my $charset = Apache::DefaultCharset->new($r);
    $r->send_http_header;
    $r->print("charset:$charset\n");
    $r->print("charset_r:", $r->add_default_charset_name, "\n");
}

1;
