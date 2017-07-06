use t::boilerplate;

use Test::More;
use Capture::Tiny qw( capture );
use Config;
use Class::Usul::Constants qw( AS_PARA AS_PASSWORD CONFIG_EXTN
                               ENCODINGS LOG_LEVELS );

BEGIN { Class::Usul::Constants->Assert( sub { 1 } ) }

use Class::Usul::Crypt     qw( decrypt encrypt );
use Class::Usul::Functions qw( :all );
use English                qw( -no_match_vars );
use File::Spec::Functions  qw( catdir catfile updir );

is AS_PARA()->{fill}, 1, 'As paragraph';

my $v = (AS_PASSWORD)[ 1 ]; is $v, 1, 'As password';

$v = (ENCODINGS)[ 0 ]; is $v, 'ascii', 'Encodings';

Class::Usul::Constants->Config_Extn( '.yml' );
is CONFIG_EXTN(), '.yml', 'Config extension mutator';

Class::Usul::Constants->Log_Levels( [ 'debug' ] );
$v = (LOG_LEVELS)[ 0 ]; is $v, 'debug', 'Log levels mutator';

is abs_path( catfile( 't', updir, 't' ) ), File::Spec->rel2abs( 't' ),
   'abs_path';

is app_prefix( 'Test::Application' ), 'test_application', 'app_prefix';
is app_prefix( undef ), q(), 'app_prefix - undef arg';

my $list = arg_list( 'key1' => 'value1', 'key2' => 'value2' );

is $list->{key2}, 'value2', 'arg_list';

is assert, 1, 'assert - can set coderef';

like assert_directory( 't' ), qr{ t \z }mx, 'assert_directory - true';
ok ! assert_directory( 'dummy' ),           'assert_directory - false';

my $encoded = base64_encode_ns( 'This is a test' );

is base64_decode_ns( $encoded ), 'This is a test', 'base64 encode/decode';

my $before = time; my $id = bsonid_time( bsonid ); my $after = time;
my $bool   = $before <= $id && $id <= $after ? 1 : 0;

ok $bool, 'bsonid_time';

$before = time; $id = bson64id_time( bson64id ); $after = time;
$bool   = $before <= $id && $id <= $after ? 1 : 0;

ok $bool, 'bson64id_time';

is class2appdir( 'Test::Application' ), 'test-application', 'class2appdir';

is classdir( 'Test::Application' ), catdir( qw( Test Application ) ),
   'classdir';

is classfile( 'Test::Application' ), catfile( qw( Test Application.pm ) ),
   'classfile';

my $token = create_token( 'test' );

ok $token eq q(ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff)
   || $token
      eq q(9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08)
   || $token eq q(a94a8fe5ccb19ba61c4c0873d391e987982fbbd3)
   || $token eq q(098f6bcd4621d373cade4e832627b4f6), 'create_token';

ok length cwdp > 0, 'Current working directory - physical';

is distname( 'Test::Application' ), 'Test-Application', 'distname';

ok defined elapsed, 'elapsed';

my ($stdout, $stderr, $exit) = capture { emit 'test'; }; chomp $stdout;

is $stdout, 'test', 'emit';

($stdout, $stderr, $exit) = capture { emit_err 'test'; }; chomp $stderr;

is $stderr, 'test', 'emit_err';

eval {
   ensure_class_loaded( 'Class::Usul::Response::IPC' );
   Class::Usul::Response::IPC->new;
};

ok !exception, 'ensure_class_loaded';

is env_prefix( 'Test::Application' ), 'TEST_APPLICATION', 'env_prefix';

is unescape_TT( escape_TT( '[% test %]' ) ), '[% test %]',
   'escape_TT/unscape_TT';

my $path = find_source( 'Class::Usul::Functions' );

is $path, abs_path( catfile( qw( lib Class Usul Functions.pm ) ) ),
   'find_source';

is first_char 'ab', 'a', 'first_char';

SKIP: {
   $ENV{AUTHOR_TESTING} or skip 'fqdn test only for developers', 1;
   is fqdn( 'localhost' ), 'localhost', 'fqdn';
}

SKIP: {
   $ENV{AUTHOR_TESTING} or skip 'fullname test only for developers', 1;
   ok defined fullname(), 'fullname';
}

is hex2str( '41' ), 'A', 'hex2str - A';

is home2appldir( catdir( qw( opt myapp v0.1 lib MyApp ) ) ),
   catdir( qw( opt myapp v0.1 ) ), 'home2appldir';

ok is_arrayref( [] ),   'is_arrayref - true';
ok ! is_arrayref( {} ), 'is_arrayref - false';

ok is_coderef( sub {} ), 'is_coderef - true';
ok ! is_coderef( {} ),   'is_coderef - false';

ok is_hashref( {} ),   'is_hashref - true';
ok ! is_hashref( [] ), 'is_hashref - false';

ok is_member( 2, 1, 2, 3 ),   'is_member - true';
ok ! is_member( 4, 1, 2, 3 ), 'is_member - false';

ok defined loginid(), 'loginid';
ok defined logname(), 'logname';

my $src = { 'key2' => 'value2', }; my $dest = {};

merge_attributes $dest, $src, { 'key1' => 'value3', }, [ 'key1', 'key2', ];

is $dest->{key1}, q(value3), 'merge_attributes - default';
is $dest->{key2}, q(value2), 'merge_attributes - source';

is my_prefix( catfile( 'dir', 'prefix_name' ) ), 'prefix', 'my_prefix';

is pad( 'x', 7, q( ), 'both'  ), '   x   ', 'pad - both';
is pad( 'x', 7, q( ), 'left'  ), '      x', 'pad - left';
is pad( 'x', 7, q( ), 'right' ), 'x      ', 'pad - right';

is prefix2class( q(test-application) ), qw(Test::Application), 'prefix2class';

my $pair = socket_pair;

ok defined $pair->[ 0 ] && defined $pair->[ 1 ], 'socket_pair';

is split_on__( q(a_b_c), 1 ), q(b), 'split_on__';

is split_on_dash( 'a-b-c', 1 ), 'b', 'split_on_dash';

is squeeze( q(a  b  c) ), q(a b c), 'squeeze';

is strip_leader( q(test: dummy) ), q(dummy), 'strip_leader';

is sub_name(), q(main), 'sub_name';

SKIP: {
   $Config{d_symlink} or skip 'No symlink support', 1;

   my $path = catfile( qw( t test_symlink ) );
   my $src  = File::Spec->rel2abs( catdir( qw( t locale ) ) );

   symlink [ qw( t locale ) ], [ qw( t test_symlink ) ];
   ok -l $path, 'Creates default symlink';  -e $path and unlink $path;

   symlink [ qw( locale ) ], [ qw( test_symlink ) ], 't';
   ok -l $path, 'Creates relative symlink'; -e $path and unlink $path;

   symlink $src, [ qw( test_symlink ) ], 't';
   ok -l $path, 'Creates relative symlink from absolute path';
   -e $path and unlink $path;

   #symlink 'tmp', File::Spec->rel2abs( catdir( qw( t test_symlink ) ) ), q();
   #ok -l $path, 'Creates null symlink';
   #-e $path and unlink $path;

   # TODO: Test with an absolute path for base
}

eval { throw( error => q(eNoMessage) ) };

my $e = exception; $EVAL_ERROR = undef;

like $e->as_string, qr{ eNoMessage }msx, 'try/throw/catch';

is trim( q(  test string  ) ), q(test string), 'trim - spaces';

is trim( q(/test string/), q(/) ), q(test string), 'trim - other chars';

eval { untaint_cmdline( '&&&' ) }; $e = exception; $EVAL_ERROR = undef;

is $e->class, q(Tainted), 'untaint_cmdline';

eval { untaint_identifier( 'no-chance' ) }; $e = exception; $EVAL_ERROR = undef;

is $e->class, q(Tainted), 'untaint_identifier';

eval { untaint_path( '$$$' ) }; $e = exception; $EVAL_ERROR = undef;

is $e->class, q(Tainted), 'untaint_path';

eval { untaint_path( 'x$x' ) }; $e = exception; $EVAL_ERROR = undef;

is $e->class, q(Tainted), 'untaint_path - 2';

is length urandom, 64, 'Urandom';

SKIP: {
   $ENV{AUTHOR_TESTING} or skip 'UUID test only for developers', 1;
   ok length uuid, 'uuid';
}

my $secret = whiten 'hostname."XYZZY"';
my $enc    = encrypt { seed => $secret }, 'This is plain text';

is decrypt( { seed => $secret }, $enc ),  'This is plain text', 'Whiten';

is { zip( qw( a b c ), qw( 1 2 3 ) ) }->{b}, 2, 'zip';

# Function compostion
is chain( sub { 1 }, sub { $_[ 0 ] + 1 }, sub { $_[ 0 ] + 2 } ), 4, 'chain';

sub compose_test { my $v = shift; $v //= 0; return $v + 1 } my $f = sub { 1 };

is compose( \&compose_test )->(), 1, 'compose';
is compose( \&compose_test, $f )->(), 2, 'compose - non default function';

$f = sub { 1 + $_[ 0 ] };

is compose( \&compose_test, $f )->( 1 ), 3, 'compose - with args';

is curry( sub { $_[ 0 ].$_[ 1 ] }, 'a' )->( 'b' ), 'ab', 'curry';

is factorial( 5 ), 120, 'factorial';

is fibonacci( 9 ), 34, 'fibonacci';

is product( 1, 2, 3, 4 ), 24, 'product';

is sum( 1, 2, 3, 4 ), 10, 'sum';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
