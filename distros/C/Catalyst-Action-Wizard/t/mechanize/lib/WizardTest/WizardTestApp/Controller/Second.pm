package WizardTestApp::Controller::Second;

use base qw/Catalyst::Controller/;

use strict;
use warnings;

use Data::Dumper;


sub preved_step : Local {
    my ($self, $c) = @_;

    my $w = $c->wizard->stash;

    $w->{'test'} = 'ok';

    $w->{test2} = 'this also ok' if !($w->{testsub} && $w->{detach}) || $_[2];

    $c->wizard->goto_next;
}

1;

__END__
