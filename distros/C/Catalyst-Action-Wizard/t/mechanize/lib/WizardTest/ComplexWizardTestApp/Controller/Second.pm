package ComplexWizardTestApp::Controller::Second;

use base qw/Catalyst::Controller/;

use strict;
use warnings;

sub def : Local {
    my ($self, $c, $arg) = @_;

    return $c->res->body('OK!') if $arg && $arg == 2;

    return $c->wizard(
	'/second/def_second', 
	'/second/def/2'
    )->goto_next;
}

sub def_second : Local {
    $_[1]->wizard->goto_next;
}

1;

__END__
