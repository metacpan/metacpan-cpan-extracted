package StompRole;
use Moose::Role;
use namespace::autoclean;

after 'disconnect' => sub {
    delete shift->{___activemq};
};

package TestServer;
use strict;
use warnings;
use Alien::ActiveMQ;
use Test::More;
use Exporter qw/import/;
use FindBin;

our $ACTIVEMQ_VERSION = '5.2.0';

our @EXPORT = qw/ start_server check_amq_broker /;

my $mq;

sub check_amq_broker {
    my ($stomp);

    eval {
        $stomp = Net::Stomp->new( { hostname => 'localhost', port => 61613 } );
    };
    if ($@) {

        unless (Alien::ActiveMQ->is_version_installed($ACTIVEMQ_VERSION)) {
            plan 'skip_all' => 'No ActiveMQ server installed by Alien::ActiveMQ, try running the "install-activemq" command';
            exit;
        }

        $mq ||= Alien::ActiveMQ->run_server($ACTIVEMQ_VERSION);

        eval {
            $stomp = Net::Stomp->new( { hostname => 'localhost', port => 61613 } );
        };
        if ($@) {
            plan 'skip_all' => 'No ActiveMQ server listening on 61613: ' . $@;
            exit;
        }
    }

    return $stomp;
}

sub start_server {
    my $stomp = check_amq_broker();

    $SIG{CHLD} = 'IGNORE';
    unless (fork()) {
        my $libs = join(' ', map { "-I$_" } @INC);
        $ENV{CATALYST_CONFIG}=shift if @_;
        system("$^X $libs $FindBin::Bin/script/stomptestapp_stomp.pl --oneshot");

        # Let our tests complete - we need to sleep here otherwise we get a timing issue
        # problem which I don't fully understand. Without it, sometimes the test works,
        # somethimes it doesn't!
        sleep 2;

        exit 0;
    }
    diag "server started, waiting for spinup...";
    sleep($ENV{NET_STOMP_DELAY}||20);

    $stomp->{___activemq} = $mq if $mq;
    StompRole->meta->apply($stomp);
    return $stomp;
}

1;
