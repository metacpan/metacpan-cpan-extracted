use utf8;
use strict;
use warnings;

package DR::Tnt::Client::Coro;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Coro;
use Mouse;

sub driver { 'async' }

sub request {
    my ($self, @args) = @_;

    my $cb = Coro::rouse_cb;
    
    my $m = $args[0];

    @args = ('select', @args[1, 2, 3], 1, 0, 'EQ') if $m eq 'get';

    $self->_fcb->request(@args, $cb);
    my ($status, $message, $resp) = Coro::rouse_wait $cb;

    return $self->_response($m, $status, $message, $resp);
}

with 'DR::Tnt::Client::Role::LikeSync';

__PACKAGE__->meta->make_immutable;
