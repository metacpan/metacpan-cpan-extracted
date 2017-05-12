package ComplexWizardTestApp::Controller::First;

use base qw/Catalyst::Controller/;

use strict;
use warnings;

use Data::Dumper;

sub edit : Local {
    my ($self, $c) = @_;

    $c->wizard('/first/login', -detach => '/first/edit')->goto_next 
            unless $c->session->{loggedin};

    $c->res->body('login ok') if $c->session->{loggedin};
}

sub login : Local {
    my ($self, $c) = @_;

    $c->wizard('/first/login_submit');

    $c->res->body(<<EOF);
<html>
    <head>
        <title>Test login</title>
    </head>
    <body>
        @{[delete $c->wizard->stash->{error} || '']}
        <form name="login" action="@{[ $c->wizard->uri_for_next ]}">
	    @{[ $c->wizard->id_to_form ]}
            <input name="username">
            <input name="password" type="password">
        </form>
    </body>
</html>
EOF

    $c->res->content_type('text/html');
}

sub login_submit : Local {
    my ($self, $c) = @_;

    my $p = $c->req->params;

    if ($p->{username} eq 'user' && $p->{password} eq 'userpassword') {
        $c->session->{loggedin} = 1;
        $c->wizard->goto_next;
    } else {
        $c->wizard->stash->{error} = 'Incorrect login'; 
        #$c->wizard->detach_prev(2);
        $c->wizard->back_to( -detach => '/fi/login'	);
        $c->wizard->back_to( -detach => '/first/login'	);
    }
}

sub generate_hops {
    my ($self, $c) = @_;

    return $c->session->{hops} if $c->session->{hops};

    my @hops = (1..10);

    my $i = 0;
    while($i++ < 8) {
        my @exchange = (int rand(9),int rand(9));
        @hops[@exchange] = @hops[reverse @exchange];
    }

    return $c->session->{hops} = [ @hops ];
}

sub ready_for_fun : Local Path('/first/edit/ready_for_fun') {
    my ($self, $c) = @_;

    my $hops = $self->generate_hops($c);

    $c->session->{fun}{$hops->[0]} = 'ok';

    $c->res->body( join ',', map { "h$_" } @$hops );
}

sub fun : Local {
    my ($self, $c, $funnumber) = @_;

    if ($funnumber eq 'last') {
        return $c->wizard('/first/eatme')->goto_next;
    }

    if (    $funnumber && $funnumber == $c->session->{hops}[0] 
        &&  $c->session->{fun}{$funnumber} eq 'ok'

    ) {
        shift @{$c->session->{hops}};

        $c->session->{fun}{$c->session->{hops}[0] || ''} = 'ok';

        # anyway, these will be added only once
        $c->wizard(
            map { '/first/fun/'.$_ } (@{$c->session->{hops}}, 'last')
        )->goto_next;
    } else {
        die 'error!';
    }
}

sub eatme : Local {
    my ($self, $c) = @_;

    $c->wizard('/first/drinkme')->goto_next;
}

sub drinkme : Local {
    my ($self, $c) = @_;

    $c->res->body(<<EOF);
<html>
<body>
    eated and drinked, thanks
    <a href="/first/test/followme">Hi there!</a>
</body>
</html>
EOF

    $c->res->content_type('text/html');
}

sub all_ok : Local Path('/first/test/followme') {
    $_[1]->res->body('all ok!');
}

1;

__END__
