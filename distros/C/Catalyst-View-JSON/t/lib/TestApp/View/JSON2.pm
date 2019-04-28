package TestApp::View::JSON2;
use base qw( Catalyst::View::JSON );

sub encode_json {
    my($self, $c, $data) = @_;
    return qq({"foo":"fake"});
}

1;
