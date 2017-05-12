package WizardTestApp::Controller::First;

use base qw/Catalyst::Controller/;

use strict;
use warnings;
use Data::Dumper;


sub first_step : Local {
    my ($self, $c, $detach) = @_;


    my $w = $c->wizard->stash;

    $w->{testsub} = 1    if $c->req->params->{testsub};
    $w->{detach} = 1     if $c->req->params->{detach};

    my @steps = ('/first/second_step', '/first/first_step');

    @steps = (
	'/first/second_step',
	-detach => [ '/first/first_step', 'detach!' ]
    )
            if $w->{detach};

    $c->wizard(@steps);

    return if $c->wizard->goto_next;

    $c->res->body('Thats ok!') 
        if 
            delete $w->{'test'} && 
	    $w->{test2} &&
            $w->{test2} eq 'this also ok' && 
            (!$w->{detach} || ($detach || '') eq 'detach!');
}

sub second_step : Local {
    my ($self, $c) = @_;

    my $w = $c->wizard->stash;

    if ($w->{testsub}) {

        my @sub = ('/second/preved_step');

        if ($w->{detach}) {
            @sub = (-detach => ['/second/preved_step', 10 ]);
        }

        $c->wizard(
	    '-sub' => [ @sub ]
	    , '/first/second_step'
        )->goto_next;
    } else {
        $c->wizard( '/second/preved_step' , '/first/second_step' )->goto_next;
    }
}

1;

__END__
