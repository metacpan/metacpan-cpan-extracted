#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Differences;

use lib 't/lib';
use AETest;

{
    my $return = AETest->test( [qw(renamepackagefrompath -f lib/New/Path.pm)], <<'CODE' );
package Old::Package;
use strict; use warnings;
CODE
    like( $return->stdout, qr/package New::Path;/, 'RenamePackage... file does not exists' );
    diag $return->stderr if $return->stderr;
    is( $return->error, undef, '... no error' );
}


{
    my $return = AETest->test( [qw(renamepackagefrompath -f lib/App/EditorTools.pm)], <<'CODE' );
package Old::Package;
use strict; use warnings;
CODE
    like( $return->stdout, qr/package App::EditorTools;/, 'RenamePackage... exists' );
    is( $return->error, undef, '... no error' );
}

SKIP: {
    my $symlink_exists = eval { symlink('lib/App','A'); 1 };
    skip 'System must support symlinks to check them', 2 unless $symlink_exists;
    my $return = AETest->test( [qw(renamepackagefrompath -f A/EditorTools.pm)], <<'CODE' );
package Old::Package;
use strict; use warnings;
CODE
    like( $return->stdout, qr/package App::EditorTools;/, 'RenamePackage... thru symlink' );
    is( $return->error, undef, '... no error' );
    unlink 'A';
}

done_testing;
