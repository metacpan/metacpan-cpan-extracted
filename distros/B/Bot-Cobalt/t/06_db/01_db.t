use Test::More tests => 37;
use strict; use warnings FATAL => 'all';

use 5.10.1;
use Fcntl qw/ :flock /;
use File::Spec;
use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok( 'Bot::Cobalt::DB' ); }

my $workdir = File::Spec->tmpdir;
my $tempdir = tempdir( CLEANUP => 1, DIR => $workdir );

my ($fh, $path) = _newtemp();
my $db;

ok( $db = Bot::Cobalt::DB->new( File => $path ), 'Cobalt::DB new()' );
can_ok( $db, 'dbopen', 'dbclose', 'put', 'get', 'dbkeys' );

ok( $db->dbopen, 'Temp database open' );

#diag("This should produce a warning:");
{
  local *STDERR;
  my $myerr;
  open *STDERR, '+<', \$myerr;
  ok( !$db->dbopen, 'Cannot reopen' );
  ok( $myerr, "Got no-reopen warning" );
}

is( $db->File, $path, 'Temp database File');

ok( $db->is_open, 'Temp database is_open' );

ok( $db->put('testkey', { Deep => { Hash => 1 } }), 'Database ref put()');

ok( ($db->dbkeys)[0] eq 'testkey', 'DB has expected dbkeys()');
my $ref;
ok( $ref = $db->get('testkey'), 'Database get()' );
is_deeply( $ref,
  { Deep => { Hash => 1 } }
);

undef $ref;

is( $db->dbkeys, 1, 'Database dbkeys()' );

$db->dbclose;

ok( !$db->is_open, 'Temp database closed' );

ok( $db->dbopen, 'Temp database reopen' );

ok( $ref = $db->get('testkey'), 'Database get() 2' );
is_deeply( $ref,
  { Deep => { Hash => 1 } }
);

ok( $db->put('scalarkey', "A scalar"), 
  'Inserting scalar string' 
);
is( $db->get('scalarkey'), "A scalar",
  'Retrieve and compare scalar' 
);

ok( $db->put('intkey', 2),
  'Inserting scalar int'
);
is( $db->get('intkey'), 2, 
  'Retrieve and compare int'
);

is( $db->dbkeys, 3, "DB has expected num. of keys");
my @keys;
ok( @keys = $db->dbkeys, 'list dbkeys()');
ok(

  (
     (grep { $_ eq 'testkey' } @keys)
  && (grep { $_ eq 'scalarkey' } @keys)
  && (grep { $_ eq 'intkey' } @keys)
  ),

  'DB has expected keys'
);

ok( $db->del('intkey'), 'Database del() 1' );
ok( $db->del('testkey'), 'Database del() 2' );
is( $db->dbkeys, 1, "DB has expected keys after del");
is( ($db->dbkeys)[0], 'scalarkey', "DB has expected key after del");

ok( $db->put('unicode', "\x{263A}"), "UTF8 put()" );
is( $db->get('unicode'), "\x{263A}", "UTF8 get()" );

my $uni = "\x{263A}";
utf8::encode($uni);
ok( $db->put($uni, "Data"), "UTF8 encoded key put()" );
is( $db->get($uni), "Data", "UTF8 encoded key get()" );

$db->dbclose;

ok( $db->dbopen(ro => 1), 'Database RO open' );
is( $db->get('scalarkey'), 'A scalar', 'Database RO get' );
$db->dbclose;

undef $db;

ok( $db = Bot::Cobalt::DB->new($path), 'Single-arg new()' );
ok( $db->dbopen(ro => 1), 'Database RO open #2' );
is( $db->get('scalarkey'), 'A scalar', 'DB RO get #2' );

$db->dbclose;

sub _newtemp {
    my ($fh, $filename) = tempfile( 'tmpdbXXXXX', 
      DIR => $tempdir, UNLINK => 1 
    );
    flock $fh, LOCK_UN;
    return($fh, $filename)
}
