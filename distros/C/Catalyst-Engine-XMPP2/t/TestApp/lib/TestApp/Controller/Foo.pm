package TestApp::Controller::Foo;

use base qw(Catalyst::Controller);

sub iq_req : Local {
    my ($self, $c) = @_;
    $c->res->body('Hello '.$c->req->body);
}

sub iq_req_xml : Local {
    my ($self, $c) = @_;
    $c->res->content_type('application/xml');
    $c->res->body('<hello>'.$c->req->body.'</hello>');
}

sub message : Local {
    my ($self, $c) = @_;
    my $text = $c->req->body;
    $c->engine->send_message($c,'foo@jabber.org', 'normal',
                             sub {
                                 my $writer = shift;
                                 my $content = $text;
                                 $writer->raw('<hello>'.$content.'</hello>');
                             });
}

sub presence : Local {
    my ($self, $c) = @_;
    my $text = $c->req->body;
    $c->engine->send_presence($c, 'normal',
                              sub {
                                  my $writer = shift;
                                  my $content = $text;
                                  $writer->raw('<hello>'.$content.'</hello>');
                              });
}

__PACKAGE__;
