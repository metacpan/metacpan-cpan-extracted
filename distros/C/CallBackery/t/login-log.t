use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');
my @lines;
$t->app->log->level('info');
$t->app->log->on(message => sub { my ($log,$level,@msg) = @_; push @lines, @msg });

my $user = $t->app->userObject->new(app => $t->app);
ok !$user->login("nobody\nLogin for admin from 127.0.0.1 successful",'x'),
    'an unknown user does not log in';
is scalar(grep { /\n/ } @lines), 0, 'the login name cannot start a new log line';
like $lines[-1], qr/nobody\\x\{a\}Login for admin/, 'the newline is logged escaped';

done_testing();
