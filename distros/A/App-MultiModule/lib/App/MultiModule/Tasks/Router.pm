package App::MultiModule::Tasks::Router;
$App::MultiModule::Tasks::Router::VERSION = '1.143160';
use strict;use warnings;
use Data::Dumper;
use IPC::Transit::Router qw(troute troute_config);

use parent 'App::MultiModule::Task';

=head2 message

No docs yet, sorry.

=cut
sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    $self->debug('Router message: ' . Data::Dumper::Dumper $message)
        if $self->{debug};
    $message->{'.ipc_transit_meta'} = {} unless $message->{'.ipc_transit_meta'};
    $message->{'.ipc_transit_meta'}->{overrides} = {}
        unless $message->{'.ipc_transit_meta'}->{overrides};
    $message->{'.ipc_transit_meta'}->{overrides}->{default_to} = 'non-local';
    my $root_object = $args{root_object};
    my $local_queues = {};
    while(my($module_name, $module_info) = each %{$root_object->{all_modules_info}}) {
        next unless $module_info->{config};
        if($root_object->{module} eq 'main') {
            $local_queues->{$module_name} = 1
                unless $module_info->{config}->{is_external};
        } else {
            $local_queues->{$module_name} = 1
                unless $module_info->{is_stateful};
        }
    }
#    $message->{'.ipc_transit_meta'}->{overrides}->{force_local} = $args{root_object}->{managed_queues};
    $message->{'.ipc_transit_meta'}->{overrides}->{force_local} = $local_queues;
    
    troute($message);
}

=head2 set_config

No docs yet, sorry.

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->debug('Router: set_config') if $self->{debug};
    troute_config($config);
}
1;
