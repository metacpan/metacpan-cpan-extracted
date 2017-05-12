package System;
use Moo;

our $VERSION = '0.00';

use Dancer::RPCPlugin::DispatchMethodList;

sub rpc_version {
    return {software_version => $VERSION};
}

sub rpc_ping {
    return "pong";
}

sub rpc_list_methods {
    return Dancer::RPCPlugin::DispatchMethodList::list_methods();
}

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

Returns the string 'pong'.

=head2 rpc_version()

Returns a struct:

    {software_version => 'X.YZ'}

=head2 rpc_list_methods()

Returns a struct for all protocols with all endpoints and functions for that endpoint.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
