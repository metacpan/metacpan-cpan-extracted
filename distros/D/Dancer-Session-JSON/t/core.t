use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer ':syntax';
use Dancer::ModuleLoader;
use Dancer::Logger;
use File::Path qw(mkpath rmtree);

use Dancer::Session::JSON;

BEGIN {
    Dancer::ModuleLoader->load( 'File::Temp', '0.22' )
        or plan skip_all => 'File::Temp 0.22 required';

    plan tests => 11;
}

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;

my $session = Dancer::Session::JSON->create();
isa_ok $session, 'Dancer::Session::JSON';

ok( defined( $session->id ), 'ID is defined' );

is( Dancer::Session::JSON->retrieve('XXX'),
    undef, "unknown session is not found" );

my $s = Dancer::Session::JSON->retrieve( $session->id );
is_deeply $s, $session, "session is retrieved";

is_deeply(
    Dancer::Session::JSON->retrieve( $session->id ),
    $session->retrieve( $session->id ),
    'exact session content',
);

my $json_file = $session->_json_file;
like $json_file, qr/\.json$/, 'session file have valid name';

$session->{foo} = 42;
$session->flush;
$s = Dancer::Session::JSON->retrieve( $s->id );
is_deeply $s, $session, "session is changed on flush";

my $id = $s->id;
$s->destroy;
$session = Dancer::Session::JSON->retrieve($id);
is $session, undef, 'session is destroyed';

my $session_dir = "$dir/sessions";
ok( -d $session_dir, "session dir was created");
rmtree($session_dir);
eval { $session = Dancer::Session::JSON->create() };
my $error = $@;
like(
    $@,
    qr{Can't open '.*\.*json':.*},
    'session dir was not recreated',
);

Dancer::Session::JSON->reset();
$session = Dancer::Session::JSON->create();
ok( -d $session_dir, "session dir was recreated");
