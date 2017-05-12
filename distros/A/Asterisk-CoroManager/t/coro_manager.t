#!perl
#-*-cperl-*-

use strict;
use warnings;
use Coro;
use Module::Build;
use Test::More tests => 7;

# Plan:
#
# 1. use Asterisk::CoroManager
# 2. Create class instance
# 3. Connect
#  Add event-handler for some userevent
#  Add default userevent-handler
# 4. Trigger that userevent and check that it gets triggered
# 5. Trigger some random userevent and check for default uevent triggering
# 6. Sendcommand want hash
# 7. Sendcommand want ref

BEGIN
{
    open my $oldout, ">&STDOUT"     or die "Can't dup STDOUT: $!";
    open STDOUT, ">/dev/null"       or die "Can't dup STDOUT: $!";

    use_ok('Asterisk::CoroManager');
}

my  $build  = Module::Build->current;

our $ASTMAN = Asterisk::CoroManager->new({
                                          host   => $build->notes('ami_host'  ),
                                          port   => $build->notes('ami_port'  ),
                                          user   => $build->notes('ami_user'  ) || 'nop',
                                          secret => $build->notes('ami_secret') || 'nop',
                                         });

isa_ok( $ASTMAN, 'Asterisk::CoroManager' );

SKIP: {
    skip "Can't test without a manager account", 5
      unless( $build->notes('ami_user') );


    if ( $ASTMAN->connect )
    {
        pass( 'connection' );

        # Add an event handler for user event AutoTest
        $ASTMAN->add_uevent_callback( 'AutoTest', sub{ pass('uevent_callback') });

        # Add a default user event handler
        $ASTMAN->add_default_uevent_callback( sub{ pass('default_uevent_callback') });

        async {
            # Sent UserEvent to asterisk server.  It should trigger that
            # UserEvent, being catched by handler above
            $ASTMAN->sendcommand({
                                  Action => 'UserEvent',
                                  UserEvent => 'AutoTest',
                                 });

            # Another UserEvent, to be caught by default user event handler.
            $ASTMAN->sendcommand({
                                  Action => 'UserEvent',
                                  UserEvent => 'SomeOtherTest',
                                 });

            # Trying a sendcommand with hash-ref returning
            my $resp = $ASTMAN->sendcommand({ Action => 'Ping' });
            if (ref $resp eq 'HASH' and
	    $resp->{Ping} eq 'Pong' )
            {
                pass('sendcommand hash-ref');
            }
            else
            {
                fail('sendcommand hash-ref');
            }

            # Trying a sendcommand with hash returning
            my %resp = $ASTMAN->sendcommand({ Action => 'Ping' });
            if ($resp{Ping} eq 'Pong')
            {
                pass('sendcommand hash');
            }
            else
            {
                fail('sendcommand hash');
            }

            $ASTMAN->disconnect;
        };

        $ASTMAN->eventloop;
    }
    else
    {
        fail( 'connection'              );
        fail( 'uevent_callback'         );
        fail( 'default_uevent_callback' );
        fail( 'sendcommand hash-ref'    );
        fail( 'sendcommand hash'        );
    }
}
