use utf8;
use strict;
use warnings;

package DR::Tnt::Client::Sync;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Mouse;

sub driver { 'sync' }

sub request {
    my ($self, @args) = @_;

    my ($status, $message, $resp);
    my $cb = sub { ($status, $message, $resp) = @_ };
    
    my $m = $args[0];

    @args = ('select', @args[1, 2, 3], 1, 0, 'EQ') if $m eq 'get';

    $self->_fcb->request(@args, $cb);
   
    return $self->_response($m, $status, $message, $resp);
}

with 'DR::Tnt::Client::Role::LikeSync';

__PACKAGE__->meta->make_immutable;
