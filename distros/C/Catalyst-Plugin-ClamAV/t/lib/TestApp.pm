package TestApp;

use strict;
use Catalyst;
use Data::Dumper;

our $VERSION = '0.01';

TestApp->config(
    name   => 'TestApp',
    clamav => {
       socket_name => $ENV{CLAMAV_SOCKET_NAME},
       socket_host => $ENV{CLAMAV_SOCKET_HOST},
       socket_port => $ENV{CLAMAV_SOCKET_PORT},
    },
);

TestApp->setup( qw/ClamAV/ );

sub upload : Local {
    my ( $self, $c ) = @_;

    my $num = $c->clamscan( 'file1', 'file2' );
    if($num > 0){
        $c->log->info('VIRUS found.');
    } elsif ($num == 0) {
        $c->log->info('VIRUS not found.');
    } else {
        $c->log->info('not checked.');
    }

    $c->res->output( $num );
}

sub upload_detailed : Local {
    my ( $self, $c ) = @_;

    my @virus = $c->clamscan( 'file1', 'file2' );
    my $num   = scalar @virus;

    if($num > 0){
        $c->log->info('VIRUS found.');
        $c->log->info( Dumper(@virus) );
    } elsif ($num == 0) {
        $c->log->info('VIRUS not found.');
    } else {
        $c->log->info('not checked.');
    }

    $c->res->output( $num );
}

1;
