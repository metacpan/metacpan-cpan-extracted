#!perl

use strict;
use lib 't/lib';

use Authen::Simple;
use MyAdapter;
use MyCache;
use MyLog;

use Test::More tests => 7;

my $log    = MyLog->new;
my $simple = Authen::Simple->new(
    MyAdapter->new( credentials => {}, log => $log ),
    MyAdapter->new( credentials => { user => 'password' }, log => $log ),
);

ok( $simple );
ok( $simple->authenticate( 'user', 'password' ) );
ok( !$simple->authenticate( 'john', 'password' ) );

like( $log->messages->[-4], qr/Failed to authenticate user 'user'/ );
like( $log->messages->[-3], qr/Successfully authenticated user 'user'/ );
like( $log->messages->[-2], qr/Failed to authenticate user 'john'/ );
like( $log->messages->[-1], qr/Failed to authenticate user 'john'/ );
