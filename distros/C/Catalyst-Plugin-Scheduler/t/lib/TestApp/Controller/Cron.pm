package TestApp::Controller::Cron;

use strict;
use warnings;
use base 'Catalyst::Controller';
use IO::File;

sub every_minute : Private {
    my ( $self, $c ) = @_;
    
    # write out a file so the test knows we did something
    my $fh = IO::File->new( $c->path_to( 'every_minute.log' ), 'w' )
        or die "Unable to write log file: $!";
    close $fh;
    
    # this tests that events cannot change the output
    $c->res->output( 'every_minute' );
}

sub test_errors : Private {
    my ( $self, $c ) = @_;
    
    die 'oops';
}

1;
