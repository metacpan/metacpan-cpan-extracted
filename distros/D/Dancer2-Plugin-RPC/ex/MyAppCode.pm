package MyAppCode;
use warnings;
use strict;

our $VERSION = '0.000_01';

=head1 NAME

MyAppCode - Demo code for the service...

=head1 DESCRIPTION

=head2 do_ping()

returns 'pong'

=for xmlrpc ping do_ping

=for jsonrpc ping do_ping

=for restrpc ping do_ping

=cut

sub do_ping { return 'pong' }

=head2 do_version()

Returns a struct:

    {software => 2.000_00}

=for xmlrpc version do_version

=for jsonrpc version do_version

=for restrpc version do_version

=cut

sub do_version {
    return {software => $VERSION};
}

=head2 do_methodlist

Returns a list of all known methods.

=for xmlrpc methodList do_methodlist

=for jsonrpc method.list do_methodlist

=for restrpc method_list do_methodlist

=cut

sub do_methodlist {
    my %args = ref($_[1]) eq 'HASH' ? %{$_[1]} : ();
    while (my ($k, $v) = each %args) {
        delete $args{$k} if $k ne 'plugin';
    }

    use Dancer2::RPCPlugin::DispatchMethodList;
    my $dispatch =  Dancer2::RPCPlugin::DispatchMethodList->new;
    return $dispatch->list_methods($args{plugin}//'any');
}

__END__
