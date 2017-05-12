#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 6;

use FindBin;
use lib "$FindBin::Bin/lib";

use Moose;
use Path::Tiny;
use Mock::CatalystX::ASP;

BEGIN { use_ok 'CatalystX::ASP'; }
BEGIN { use_ok 'CatalystX::ASP::Application'; }

my $root = path( $FindBin::Bin, '../t/lib/TestApp/root' )->realpath;

my $asp = CatalystX::ASP->new(
    c             => mock_c,
    GlobalPackage => mock_asp->GlobalPackage,
    Global        => $root,
);
my $Session     = $asp->Session;
my $Application = $asp->Application;

is( $Application->Lock,
    undef,
    'Unimplemented method $Application->Lock'
);
is( $Application->UnLock,
    undef,
    'Unimplemented method $Application->UnLock'
);
$Session->{foo} = 'baz';
is_deeply( $Application->GetSession( mock_c->sessionid ),
    { foo => 'baz', IsAbandoned => 0, Timeout => 60 },
    '$Application->GetSession returned hash matching expected $Session'
);
is( $Application->SessionCount,
    undef,
    'Unimplemented method $Application->SessionCount'
);
