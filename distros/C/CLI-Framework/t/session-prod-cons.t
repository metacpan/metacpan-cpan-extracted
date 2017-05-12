use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More tests => 2;

use File::Spec;
open( my $devnull, '>', File::Spec->devnull() );
select $devnull;

my ($SHARED_KEY, $SHARED_VALUE) = ('shared-key', '* producer was here *');

my $SHARED_VALUE_CACHED_IN_INIT = '* shared value set in app init() method *';

my $app = Test::Of::Session::Persistence->new();
@ARGV = ( "--app_opt=$SHARED_VALUE_CACHED_IN_INIT", 'prod', 'a', 'b' );
$app->run();

is( $app->cache->get( 'app_opt' ), $SHARED_VALUE_CACHED_IN_INIT,
    'init() method in application class correctly stores data in cache' );

@ARGV = qw( cons );
$app->run();

is( $app->cache->get( $SHARED_KEY ), $SHARED_VALUE, 'values stored in cache persist' );

close $devnull;

############################
#
#   APPLICATION CLASS
#
############################

# application WRITES TO the cache
package Test::Of::Session::Persistence;
use base qw( CLI::Framework );

use strict;
use warnings;

sub option_spec {
    [ 'app_opt=s' => 'option to test setting a cache key in init() method of application class' ],
}

sub init {
    my ($self, $opts) = @_;

    for my $key (keys %$opts ) {
        $self->cache->set( $key => $opts->{$key} );
    }
}

sub command_map {
    console             => 'CLI::Framework::Command::Console',
    'session-producer'  => 'Producer',
    'session-consumer'  => 'Consumer',
}

sub command_alias {
    'prod' => 'session-producer',
    'cons' => 'session-consumer',
}

############################
#
#   COMMAND CLASSES
#
############################

# command that WRITES TO the cache
package Producer;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

sub run {
    my ($self, $opts, @args) = @_;

    # If args provided, treat them as set of key-value pairs to be added to
    # the cache...
    die 'zero or even number of args required' if @args % 2;
    my %kv = @args;
    for my $key (keys %kv) {
        $self->cache->set( $key => $kv{$key} );
    }
    $self->cache->set($SHARED_KEY => $SHARED_VALUE);

    return '';
}

#-------

# command that READS FROM the cache
package Consumer;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

sub run {
    my ($self, $opts, @args) = @_;
    my $value_passed_by_producer = $self->cache->get( $SHARED_KEY );

    return $value_passed_by_producer;
}

#-------

__END__

=pod

=head1 PURPOSE

Test session persistence in CLIF

=cut
