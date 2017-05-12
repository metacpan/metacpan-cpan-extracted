use strict;
use warnings;

use utf8;
use Test::More;
use Test::Exception;

use Dancer::Session::DBIC;
use Dancer qw(:syntax :tests);

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use DBICx::TestDatabase;
use Test::WibbleObject;

test_session_schema('Test::Schema');
test_session_schema('Test::Custom', {resultset => 'Custom',
                                     id_column => 'customs_id',
                                     data_column => 'custom_data'});

sub test_session_schema {
    my ($schema_class, $schema_options) = @_;

    my $schema = DBICx::TestDatabase->new($schema_class);

    set session => 'DBIC';
    set session_options => {
                            %{$schema_options || {}},
                            schema => sub {return $schema},
                           };

    my $session = session->create;

    isa_ok($session, 'Dancer::Session::DBIC');

    my $session_id = session->id;

    ok(defined($session_id) && $session_id > 0, 'Testing session id')
        || diag "Session id: ", $session_id;

    session foo => 'bar';

    my $session_value = session('foo');

    ok($session_value eq 'bar', 'Testing session value')
        || diag "Session value: ", $session_value;

    # destroy session
    session->destroy;

    my $next_session_id = session->id;

    my $resultset = $schema_options->{resultset} || 'Session';
    my $ret = $schema->resultset($resultset)->find($session_id);

    ok(! defined($ret), 'Testing session destruction')
        || diag "Return value: ", $ret;

    # testing with utf8 character
    session camel => 'ラクダ';

    my $camel = session('camel');

    ok ($camel eq 'ラクダ', 'Testing utf-8 characters in the session.')
        || diag "Return values: ", $camel;


    # to_json allows objects
    my ( $wibble, $data );

    lives_ok( sub { $wibble = Test::WibbleObject->new() },
        "create Test::WibbleObject" );
    isa_ok( $wibble, "Test::WibbleObject" );
    lives_ok( sub { $wibble->name("Foo")}, "wibble name set to Foo" );

    lives_ok( sub { session wibble => $wibble }, "put wibble in session" );

    lives_ok( sub { $data = session('wibble') }, "get wibble out of session" );

    is_deeply( $data, { name => "Foo" }, "returned data is good" );
}

done_testing;
