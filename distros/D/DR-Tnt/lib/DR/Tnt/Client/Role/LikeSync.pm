use utf8;
use strict;
use warnings;

use DR::Tnt::FullCb;
package DR::Tnt::Client::Role::LikeSync;
use Mouse::Role;
with 'DR::Tnt::Role::Logging';
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

has host                => is => 'ro', isa => 'Str', required => 1;
has port                => is => 'ro', isa => 'Str', required => 1;
has user                => is => 'ro', isa => 'Maybe[Str]';
has password            => is => 'ro', isa => 'Maybe[Str]';
has reconnect_interval  => is => 'ro', isa => 'Maybe[Num]';
has hashify_tuples      => is => 'ro', isa => 'Bool', default => 0;
has lua_dir             => is => 'ro', isa => 'Maybe[Str]';
has utf8                => is => 'ro', isa => 'Bool', default => 1;

has raise_error         => is => 'ro', isa => 'Bool', default => 1;

requires 'request', 'driver';

my @methods = qw(
    select
    update
    insert
    replace
    delete
    call_lua
    eval_lua
    ping
    auth
    get
);

for my $m (@methods) {
    no strict 'refs';
    *{ $m } = sub :method {
        my $self = shift;
        unshift @_ => $m;
        $self->request(@_);
    }
}

sub _response {
    my ($self, $m, $status, $message, $resp) = @_;
    unless ($status eq 'OK') {
        return 0 if $m eq 'ping';
        return undef unless $self->raise_error;
        croak $message;
    }

    goto $m;

    ping:
    auth:
        return 1;

    get:
    update:
    insert:
    replace:
    delete:
        $self->_log(error =>
            'Method %s returned more than one result (%s items)',
            $m,
            scalar @$resp
        ) if @$resp > 1;
        return $resp->[0];

    select:
    call_lua:
    eval_lua:
        return $resp;
}

has _fcb =>
    is      => 'ro',
    isa     => 'Object',
    handles => [ 'last_error' ],
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        DR::Tnt::FullCb->new(
            logger              => $self->logger,
            host                => $self->host,
            port                => $self->port,
            user                => $self->user,
            password            => $self->password,
            reconnect_interval  => $self->reconnect_interval,
            hashify_tuples      => $self->hashify_tuples,
            lua_dir             => $self->lua_dir,
            driver              => $self->driver,
            utf8                => $self->utf8,
        )
    };


1;
