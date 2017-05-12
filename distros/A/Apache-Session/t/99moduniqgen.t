use Test::More;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan tests => 4;

my $package = 'Apache::Session::Generate::ModUniqueId';
use_ok $package;

#my $origdir = getcwd;
#my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
#chdir( $tempdir );

$ENV{UNIQUE_ID} = '12345678790abcdef';

my $session = {};

Apache::Session::Generate::ModUniqueId::generate($session);

ok exists($session->{data}->{_session_id}), 'session id created';

ok keys(%{$session->{data}}) == 1, 'just one key in the data hashref';

is $session->{data}->{_session_id}, $ENV{UNIQUE_ID},
   'id matches UNIQUE_ID env param';

#chdir( $origdir );
