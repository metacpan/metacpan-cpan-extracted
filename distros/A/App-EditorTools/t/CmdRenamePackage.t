#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Differences;

use lib 't/lib';
use AETest;

{
    my $return = AETest->test( [qw(renamepackage -n App::EditorTools)], <<'CODE' );
package Old::Package;
use strict; use warnings;
CODE
    like( $return->stdout, qr/package App::EditorTools;/, 'RenamePackage' );
    is( $return->error, undef, '... no error' );
}

done_testing;
