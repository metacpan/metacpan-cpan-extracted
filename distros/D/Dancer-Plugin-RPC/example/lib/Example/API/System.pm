package Example::API::System;
use Moo;
use Types::Standard qw( Str Num );

our $VERSION = '0.00';

use Dancer::RPCPlugin::DispatchMethodList;
use Dancer::RPCPlugin::ErrorResponse;

use version;
use POSIX ();

has app_version => (
    is       => 'ro',
    isa      => Str,
    required => 1
);
has app_name => (
    is       => 'ro',
    isa      => Str,
    required => 1
);
has active_since => (
    is       => 'ro',
    isa      => Num,
    required => 1
);

sub rpc_version {
    my $self = shift;
    return {
        software_version => $self->app_version
    };
}

sub rpc_ping {
    return "pong";
}

sub rpc_status {
    my $self = shift;
    return {
        app_version  => "v" . version->parse($self->app_version)->numify,
        app_name     => $self->app_name,
        active_since => scalar(localtime($self->active_since)),
        hostname     => (POSIX::uname)[1],
        running_pid  => $$,
    };
}

sub rpc_list_methods {
    my %args = %{$_[1]};
    while (my ($k, $v) = each %args) {
        delete $args{$k} if $k ne 'plugin';
    }
    if ($args{plugin} && $args{plugin} !~ /^(?:xmlrpc|jsonrpc|restrpc|any)$/) {
        return error_response(
            error_code    => -32001,
            error_message => "Unknown plugin ($args{plugin})",
        );
    }

    my $dispatch =  Dancer::RPCPlugin::DispatchMethodList->new;
    return $dispatch->list_methods($args{plugin}//'any');
}

use namespace::autoclean;
1;

=head1 NAME

System - Interface to basic system function.

=head1 SYNOPSIS

    my $system = System->new();

    my $pong = $system->rpc_ping();
    my $version = $system->rpc_version();
    my $methods = $system->rpc_list_methods();

=head1 DESCRIPTION

=head2 rpc_ping()

=for jsonrpc ping rpc_ping /system

=for restrpc ping rpc_ping /system

=for xmlrpc ping rpc_ping  /system

Returns the string 'pong'.

=head2 rpc_version()

=for jsonrpc version rpc_version /system

=for restrpc version rpc_version /system

=for xmlrpc version rpc_version  /system

Returns a struct:

    {software_version => 'X.YZ'}

=head2 rpc_status

=for jsonrpc status rpc_status /system

=for restrpc status rpc_status /system

=for xmlrpc status rpc_status  /system

Returns:

    {
        app_version => ...,
        app_name    => ...,
        active_since => ...,
    }

=head2 rpc_list_methods()

=for jsonrpc list_methods rpc_list_methods /system

=for restrpc list_methods rpc_list_methods /system

=for xmlrpc list_methods rpc_list_methods  /system

Returns a struct for all protocols with all endpoints and functions for that endpoint.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
