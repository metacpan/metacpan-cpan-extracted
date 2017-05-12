package PluginTestApp::Controller::Root;

use base 'Catalyst::Controller';
use Data::Dumper ();
use Scalar::Util qw(weaken);

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash->{'cookies'} = {
        Catalyst => { value => 'Cool',     path => '/' }, 
        Cool     => { value => 'Catalyst', path => '/' },
        CoolCat  => { value => {'Cool' => 'Catalyst'}, path => '/' },
        BadCat   => { value => {'_hashedcookies_meoww' => 'Catalyst'}, path => '/' },
    };
}

sub default : Path('/') {
    my ( $self, $c ) = @_;
    $c->forward('/root/testrequest');
}

sub testrequest : Global {
    my ( $self, $c ) = @_;
    my %cookies = %{$c->stash->{'cookies'}};

    # we're testing cookies, here, so this is a little ditty to
    # set them for us, based on what url path was requested
    
    for (split '/', $c->req->path) {
        $c->log->debug( "$_ => $cookies{ $_ }" ) if $c->debug;
        if (exists $cookies{ $_ } and defined $cookies{ $_ }) {
            $c->res->cookies->{ $_ } = $cookies{ $_ };
        }
    }
}

sub end : Private {
    my ( $self, $c ) = @_;

    my $reference = $c->request;
    my $context = delete $reference->{_context};
    my $body = delete $reference->{_body};

    my $dumper = Data::Dumper->new( [$reference] );
    $dumper->Indent(1);
    $dumper->Purity(1);
    $dumper->Useqq(0);
    $dumper->Deepcopy(1);
    $dumper->Quotekeys(0);
    $dumper->Terse(1);

    my $output = $dumper->Dump;

    $c->response->header( 'X-Catalyst-Plugins' => [$c->registered_plugins] );
    $c->res->headers->content_type('text/plain');
    $c->res->output($output);

    $reference->{_context} = $context;
    weaken( $reference->{_context} );
    $reference->{_body} = $body;
}

1;
