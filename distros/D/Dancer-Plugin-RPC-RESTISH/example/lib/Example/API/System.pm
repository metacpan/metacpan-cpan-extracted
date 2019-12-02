package Example::API::System;
use Moo;

our $VERSION = '0.001';

has app_version => (
    is       => 'ro',
    required => 1,
);
has app_name => (
    is       => 'ro',
    required => 1,
);
has active_since => (
    is       => 'ro',
    required => 1,
);

use Dancer::RPCPlugin::DispatchMethodList;

use version;
use POSIX ();

=head2 get_status

=for restish GET@status get_status /system

=for jsonrpc status get_status /system

=head3 Arguments

None

=head3 Responses

=over

=item B<Success>

    {
        app_version  => "v" . $self->app_version,
        app_name     => $self->app_name,
        active_since => POSIX::strftime("%Y-%m-%dT%H:%M:%S%z", localtime($self->active_since)),
        hostname     => (POSIX::uname)[1],
        running_pid  => $$,
    }

=back

=cut

sub get_status {
    my $self = shift;

    return {
        app_version  => "v" . version->parse($self->app_version)->numify,
        app_name     => $self->app_name,
        active_since => POSIX::strftime("%Y-%m-%dT%H:%M:%S%z", localtime($self->active_since)),
        hostname     => (POSIX::uname)[1],
        running_pid  => $$,
    };
}

=head2 list_methods

=for restish GET@methods list_methods            /system

=for restish GET@methods/:plugin list_methods    /system

=for jsonrpc list_methods list_methods           /system

=head3 Arguments

Named, Struct (or in path)

=over

=item plugin => <any | jsonrpc|restish|restrpc|xmlrpc> (Default 'any')

In rest-context:

    http://service.example.com/system/list_methods/restish

=back

=cut

sub list_methods {
    my $self = shift;
    my %args = %{ $_[0] };
    my $plugin = $args{plugin} // 'any';

    my $dispatch =  Dancer::RPCPlugin::DispatchMethodList->new;
    return $dispatch->list_methods($args{plugin}//'any');
}

use namespace::autoclean;
1;
