use strict;
use warnings;
use Email::Sender::Transport::SMTP;
use Test::More;
use Test::MockModule;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# Email transport may not be necessary. The local machine might do the job
# by default, so this is treated separately from the other email settings.
# The option validation is not tested here but in the options tests. If the
# server is specified but not the port, 25 should be used by default.

my ($host, $port);

my $mockEmailTransport = Test::MockModule->new('Email::Sender::Transport::SMTP');
$mockEmailTransport->mock('new', sub{
                                     my $hr_params = $_[1];
                                     $host = $$hr_params{host};
                                     $port = $$hr_params{port};
                                     });
$mockEmailTransport->mock('host', sub{shift; $host = shift;});
$mockEmailTransport->mock('port', sub{shift; $port = shift;});

$App::ipchgmon::opt_mailserver = 'Outbound mail';
$App::ipchgmon::opt_mailport = 25;
App::ipchgmon::build_transport;
is $host, 'Outbound mail', 'Host populated correctly';
is $port, 25,              'Port populated correctly';

undef $host;
undef $port;
undef $App::ipchgmon::opt_mailport;
$App::ipchgmon::opt_mailserver = 'Outbound mail 2';
App::ipchgmon::build_transport;
is $host, 'Outbound mail 2', 'Host populated correctly when port omitted';
is $port, 25,                'Port populated correctly when omitted';

done_testing();
