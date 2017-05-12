use strict;
use warnings;

use Test::More;

# ABSTRACT: Test $_call_from

use Call::From qw( $_call_from );
use constant _file => sub { [caller]->[1] }
  ->();
sub _caller { [ @{ [caller] }[ 0 .. 2 ], \@_ ] }
sub _line { [ caller( $_[0] || 0 ) ]->[2] }

my @args = ( 5, 3, 1, 2, 4, 6 );

is_deeply(
    main->$_call_from( undef, _caller => @args ),
    [ 'main', _file, _line, [ 'main', @args ] ],
    "->_call_from( undef, METHOD, ARGS )"
);

is_deeply(
    main->$_call_from( 0, _caller => @args ),
    [ 'main', _file, _line, [ 'main', @args ] ],
    "->_call_from( NUMBER, METHOD, ARGS )"
);

is_deeply(
    main->$_call_from( 'Fake::Package', _caller => @args ),
    [ 'Fake::Package', _file, _line, [ 'main', @args ] ],
    "->_call_from( PACKAGE, METHOD, ARGS )"
);

is_deeply(
    main->$_call_from(
        [ 'Fake::Package', 'fake_file_name' ], _caller => @args
    ),
    [ 'Fake::Package', 'fake_file_name', _line, [ 'main', @args ] ],
    "->_call_from([ PACKAGE, FILE ], METHOD, ARGS )"
);

is_deeply(
    main->$_call_from(
        [ 'Fake::Package', 'fake_file_name', 1000 ],
        _caller => @args
    ),
    [ 'Fake::Package', 'fake_file_name', 1000, [ 'main', @args ] ],
    "->_call_from([ PACKAGE, FILE, LINE ], METHOD, ARGS )"
);

done_testing;

