use utf8;
use strict;
use warnings;

use DR::Tnt::FullCb;
package DR::Tnt::Client::AE;
use Mouse;
use Carp;
use AnyEvent;
$Carp::Internal{ (__PACKAGE__) }++;


with 'DR::Tnt::Role::Logging';
has host                => is => 'ro', isa => 'Str', required => 1;
has port                => is => 'ro', isa => 'Str', required => 1;
has user                => is => 'ro', isa => 'Maybe[Str]';
has password            => is => 'ro', isa => 'Maybe[Str]';
has reconnect_interval  => is => 'ro', isa => 'Maybe[Num]';
has hashify_tuples      => is => 'ro', isa => 'Bool', default => 0;
has lua_dir             => is => 'ro', isa => 'Maybe[Str]';
has utf8                => is => 'ro', isa => 'Bool', default => 1;

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
            driver              => 'async',
            utf8                => $self->utf8,
        )
    };

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
    *{ $m } = sub {
        my $self = shift;
        unshift @_ => $m;
        $self->request(@_);
    }
}


sub request {
    my $cb = pop;
    my ($self, @args) = @_;

    my $m = $args[0];

    @args = ('select', @args[1, 2, 3], 1, 0, 'EQ') if $m eq 'get';
    
    $self->_fcb->request(@args,
        sub {
            my ($status, $message, $resp) = @_;
            unless ($status eq 'OK') {
                if ($m eq 'ping') {
                    $cb->(0);
                    return;
                }
                $cb->(undef);
                return;
            }

            goto $m;

            ping:
            auth:
                $cb->(1);
                return;

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
                $cb->($resp->[0]);
                return;

            select:
            call_lua:
            eval_lua:
                $cb->($resp);
                return;
        }
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

DR::Tnt::Client::AE - AnyEvent (async) driver for tarantool

=head1 SYNOPSIS

    use DR::Tnt;
    my $tnt = tarantool
                    host            => $host,
                    port            => $port,
                    user            => $user,
                    password        => $password,
                    lua_dir         => $lua_dir,
                    hashify_tuples  => 1,
                    driver          => 'async'
    ;

    # the same
    use DR::Tnt::Client::AE;
    my $tnt = DR::Tnt::Client::AE->new(
                    host            => $host,
                    port            => $port,
                    user            => $user,
                    password        => $password,
                    lua_dir         => $lua_dir,
                    hashify_tuples  => 1,
                    driver          => 'async'
    );


    $tnt->ping(sub {
        my $res = shift;
        if ($res) {
            say "ping ok";
        } else {
            say "can not ping: %s: %s", @{ $tnt->last_error };
        }
    });

    $tnt->select($space, 'index', 'key', sub {
        my ($list) = @_;
        if ($list) {

        } else {
            say "can not select: %s: %s", @{ $tnt->last_error };
        }
    });

=cut
