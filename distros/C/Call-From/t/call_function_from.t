use strict;
use warnings;

use Test::More;

# ABSTRACT: test call_function_from

use constant _file => sub { [caller]->[1] }
  ->();
sub KENTNL::X::caller { [ @{ [ caller() ] }[ 0 .. 2 ], \@_ ] }
sub _line { [ caller( $_[0] || 0 ) ]->[2] }

use Call::From qw( call_function_from );

my (@args) = ( 5, 3, 1, 2, 4, 6 );
is_deeply(
    call_function_from('KENTNL::Fake')->( \&KENTNL::X::caller, @args ),
    [ 'KENTNL::Fake', _file, _line, \@args ],
    'call_function_from(NAMESPACE)->( CODE, ARGS )',
);
is_deeply(
    call_function_from(undef)->( \&KENTNL::X::caller, @args ),
    [ 'main', _file, _line, \@args ],
    'call_function_from(undef)->( CODE, ARGS )',
);

is_deeply(
    call_function_from(0)->( \&KENTNL::X::caller, @args ),
    [ 'main', _file, _line, \@args ],
    'call_function_from(0)->( CODE, ARGS )',
);

is_deeply(
    call_function_from('KENTNL::Fake')->( 'KENTNL::X::caller', @args ),
    [ 'KENTNL::Fake', _file, _line, \@args ],
    'call_function_from(NAMESPACE)->( FQFNNAME, ARGS )'
);

is_deeply(
    call_function_from( [ 'KENTNL::Fake', 'fakefile' ] )
      ->( 'KENTNL::X::caller', @args ),
    [ 'KENTNL::Fake', 'fakefile', _line, \@args ],
    'call_function_from([NAMESPACE,FILE])->( FQFNNAME, ARGS )'
);

is_deeply(
    call_function_from( [ 'KENTNL::Fake', 'fakefile', 4000 ] )
      ->( 'KENTNL::X::caller', @args ),
    [ 'KENTNL::Fake', 'fakefile', 4000, \@args ],
    'call_function_from([NAMESPACE,FILE,LINE])->( FQFNNAME, ARGS )'
);

done_testing;

