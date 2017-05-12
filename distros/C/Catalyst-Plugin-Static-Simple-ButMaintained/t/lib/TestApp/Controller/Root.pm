package TestApp::Controller::Root;

use strict;
use warnings;
use File::Spec::Functions;

use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace => '');

sub default : Private {
    my ( $self, $c ) = @_;
    
    $c->res->output( 'default' );
}

sub subtest : Local {
    my ( $self, $c ) = @_;

    $c->res->output( $c->subreq('/subtest2') );
}

sub subtest2 : Local {
    my ( $self, $c ) = @_;
    
    $c->res->output( 'subtest2 ok' );
}

sub serve_static : Local {
    my ( $self, $c, $ct ) = @_;
    
    my $file = catfile( $FindBin::Bin, 'lib', 'TestApp.pm' );

    my %args;
    $args{content_type} = $ct if defined $ct;
    
    $c->serve_static_file( $file, \%args );
}

sub serve_static_ext_jpg : Local {
    my ( $self, $c, $ct ) = @_;
    
    my $file = catfile( $FindBin::Bin, 'lib', 'TestApp.pm' );

    $c->serve_static_file( $file, {ext=>'jpg'} );
}

sub serve_static_404 : Local {
    my ( $self, $c ) = @_;
    
    my $file = catfile( $FindBin::Bin, 'lib', 'foo.pm' );
    
    $c->serve_static_file( $file );
}

1;
