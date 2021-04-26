package App::JESP::Cmd;
$App::JESP::Cmd::VERSION = '0.016';
use App::Cmd::Setup -app;
use strict; use warnings;

use App::JESP;

use Data::Dumper;
use Log::Any::Adapter;

=head1 NAME

App::JESP::Cmd - Command line interface.

=cut

=head2 global_opt_spec

Adds verbosity level

See L<App::Cmd>

=cut

sub global_opt_spec {
    my ($self) = @_;
    return (
        [ "verbose|v", "log additional output" ],
        [ "lib-inc|I=s@", "additional \@INC dirs", {
            callbacks => { 'always fine' => sub { unshift @INC, @{$_[0]}; } }
        } ],
        $self->SUPER::global_opt_spec,
    );
}

=head2 execute_command

See L<App::Cmd>

=cut

sub execute_command {
    my ($self, $cmd, $opts, @args) = @_;
    if( $self->global_options()->{verbose} ){
        Log::Any::Adapter->set( 'Stdout' , log_level => 'debug' );
    }else{
        Log::Any::Adapter->set( 'Stdout' , log_level => 'info' );
    }

    return $self->SUPER::execute_command( $cmd , $opts , @args );
}
1;
