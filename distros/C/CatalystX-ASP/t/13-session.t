#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 16;

use FindBin;
use lib "$FindBin::Bin/lib";

use Moose;
use Path::Tiny;
use Mock::CatalystX::ASP;

BEGIN { use_ok 'CatalystX::ASP'; }
BEGIN { use_ok 'CatalystX::ASP::Session'; }

my $root = path( $FindBin::Bin, '../t/lib/TestApp/root' )->realpath;

my $asp = CatalystX::ASP->new(
    c             => mock_c,
    GlobalPackage => mock_asp->GlobalPackage,
    Global        => $root,
);
my $Session = $asp->Session;

is( $Session->Lock,
    undef,
    'Unimplemented method $Session->Lock'
);
is( $Session->UnLock,
    undef,
    'Unimplemented method $Session->UnLock'
);
$Session->{foo} = 'bar';
is( mock_c->session->{foo},
    'bar',
    'Storing key in $Session resulted in copy in $c->session'
);
mock_c->session->{bar} = 'foo';
is( $Session->{bar},
    'foo',
    'Fetching key in $Session resulted in copy from $c->session'
);
is( grep( /foo|bar|IsAbandoned|Timeout/, keys %$Session ),
    4,
    'All expected keys in $Session exist'
);
ok( exists $Session->{foo},
    'Exists on $Session for existing key'
);
ok( !exists $Session->{baz},
    'Not exists on $Session for not existing key'
);
is( delete $Session->{foo},
    'bar',
    'Deleting key from $Session returned value'
);
is( grep( /bar|IsAbandoned|Timeout/, keys %$Session ),
    3,
    'All expected keys in $Session exist'
);
isnt( mock_c->session->{foo},
    'bar',
    'Deleted key also not existing in $c->session'
);
%$Session = ();
is_deeply( $Session,
    {},
    'Clearing $Session resulted in empty hash'
);
is_deeply( mock_c->session,
    {},
    'Clearing $Session resulted in empty hash for $c->session'
);
$Session->{foo} = 'bar';
like( scalar $Session,
    qr/^CatalystX::ASP::Session/,
    'Scalar context of $Session returns hash type'
);
isnt( $Session,
    mock_c->session,
    'Ensure $Session and $c->session are different'
);
