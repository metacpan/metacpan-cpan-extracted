#!perl

use Test::More no_plan => 1;

use Test::Deep;
use Test::Exception;
use Test::Group;

use File::Temp qw[tempdir];
use Cwd qw[getcwd];

# my $origdir = getcwd;
# my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
# chdir( $tempdir );

test 'use ok' => sub {
    use_ok 'Apache::Session::Generate::UUID';
};

my $session = {};
my $id;

test 'session creation' => sub {
    ok Apache::Session::Generate::UUID::generate($session), 'generate called ok';
    ok exists $session->{'data'}->{'_session_id'}, 'session id created';
    is keys %{ $session->{'data'} } , 1, 'just one key in the data hashref';
    like $session->{'data'}->{'_session_id'}, qr/^[0-9a-fA-F\-]{36}$/, 'id looks like a uuid';
    $id = $session->{'data'}->{'_session_id'};
};

test 'session uniqueness' => sub {
    Apache::Session::Generate::UUID::generate($session);
    isnt $id, $session->{'data'}->{'_session_id'}, 'old session id does not match new one';
};

test 'session validation' => sub {
    Apache::Session::Generate::UUID::generate($session);
    ok Apache::Session::Generate::UUID::validate($session), 'session id validates';
    $session->{'data'}->{'_session_id'} = 'asdasd' . time;
    dies_ok { Apache::Session::Generate::UUID::validate($session); } 'session id does not validate';
};
