use strict;
use warnings;

use Test::More;

# ABSTRACT: Check call_method_from behaviour
use constant _file => sub { [caller]->[1] }
  ->();
sub _caller { return [ @{ [ caller() ] }[ 0 .. 2 ], \@_ ] }
sub _line { return [caller]->[2] }

our $call_caller_line   = 18;
our $call_caller_2_line = 25;

sub call_caller {
    my ( $self, $context, @args ) = @_;
#line 18
    return $self->${ \call_method_from($context) }( '_caller', @args );
}

sub call_caller_2 {
    my ( $self, @args ) = @_;
#line 25
    return $self->call_caller(@args);
}

use Call::From qw( call_method_from );

is_deeply(
    main->call_caller_2( 0, 1, 2, 3 ),
    [ 'main', _file, $call_caller_line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from(0) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( 1, 1, 2, 3 ),
    [ 'main', _file, $call_caller_2_line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from(1) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( 2, 1, 2, 3 ),
    [ 'main', _file, _line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from(2) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( undef, 1, 2, 3 ),
    [ 'main', _file, $call_caller_line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from(undef) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( 'KENTNL::Fake::Package', 1, 2, 3 ),
    [ 'KENTNL::Fake::Package', _file, $call_caller_line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from(PKGNAME) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( [], 1, 2, 3 ),
    [ 'main', _file, $call_caller_line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from([]) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( ['KENTNL::Fake::Package'], 1, 2, 3 ),
    [ 'KENTNL::Fake::Package', _file, $call_caller_line, [ 'main', 1, 2, 3, ] ],
    "inv->\${ \\call_method_from([PKGNAME]) }( method => ARGS )"
);

is_deeply(
    main->call_caller_2( [ 'KENTNL::Fake::Package', 'fake/file' ], 1, 2, 3 ),
    [
        'KENTNL::Fake::Package', 'fake/file',
        $call_caller_line, [ 'main', 1, 2, 3, ]
    ],
    "inv->\${ \\call_method_from([PKGNAME,FILE]) }( method => ARGS )"
);
is_deeply(
    main->call_caller_2(
        [ 'KENTNL::Fake::Package', 'fake/file', _line() + 10000 ],
        1, 2, 3
    ),
    [
        'KENTNL::Fake::Package', 'fake/file',
        _line() + 10000, [ 'main', 1, 2, 3, ]
    ],
    "inv->\${ \\call_method_from([PKGNAME,FILE]) }( method => ARGS )"
);

done_testing;

