package TestApp::View::Default;

use MRO::Compat;
use warnings;
use strict;

use base qw( Catalyst::View::TT );

sub process {
    my( $self, $c ) = @_;
    if ($c->stash->{'view_death'}) {
        $c->res->status(501);
        die "Death by view";
        
    }
    
    $self->maybe::next::method($c);
}

1;