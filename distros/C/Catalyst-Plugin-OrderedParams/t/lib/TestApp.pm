package TestApp;

use strict;
use Catalyst;
use Data::Dumper;

our $VERSION = '0.01';

TestApp->config(
    name => 'TestApp',
);

TestApp->setup( qw/OrderedParams/ );

sub default : Private {
    my ( $self, $c ) = @_;
    
    my @params = $c->req->param();
    
    if ( my $output = $self->dump( \@params ) ) {
        $c->res->headers->content_type('text/plain');
        $c->res->output($output);
        return 1;
    }

    return 0;
}

sub dump {
    my ( $self, $reference ) = @_;

    return unless $reference;

    my $dumper = Data::Dumper->new( [ $reference ] );
    $dumper->Indent(1);
    $dumper->Purity(1);
    $dumper->Useqq(0);
    $dumper->Deepcopy(1);
    $dumper->Quotekeys(0);
    $dumper->Terse(1);

    return $dumper->Dump;
}

1;
