package TestApp::Controller::Callback;
use parent "Catalyst::Controller";
use strict;
use warnings;

my %id_content = (
                  1 => "Arabic one",
                  2 => "Arabic two",
                  );


sub one :Local {
    my ( $self, $c ) = @_;
    $c->blurb({ id => 1,
                render => sub {
                    my $blurb = shift;
                    return $id_content{ $blurb->id };
                }
                });
    $c->res->body($c->blurb);
}

1;

