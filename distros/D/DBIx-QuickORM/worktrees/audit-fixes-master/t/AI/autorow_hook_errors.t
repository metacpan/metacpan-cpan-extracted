use Test2::V0;
use File::Temp qw/tempdir/;
use File::Path qw/make_path/;

# Regression: _autorow_hook must not swallow a compile error in a user's
# autorow base class (silently substituting the stock Row and losing the user's
# methods). Only a genuinely-absent base falls back; a broken one rethrows.

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
make_path("$dir/MyBroken", "$dir/MyGood");

open(my $b, '>', "$dir/MyBroken/Base.pm") or die $!;
print $b "package MyBroken::Base;\nuse strict; use warnings;\nthis is not valid perl \@\@\@ ;\n1;\n";
close $b;

open(my $g, '>', "$dir/MyGood/Base.pm") or die $!;
print $g "package MyGood::Base;\nuse parent 'DBIx::QuickORM::Row';\n1;\n";
close $g;

push @INC, $dir;

like(
    dies { DBIx::QuickORM->_autorow_hook('MyBroken::Base', undef, 'x') },
    qr/Array found where operator expected|valid perl|syntax/i,
    "a base class that fails to compile rethrows instead of silently using the stock Row",
);

ok(
    lives { DBIx::QuickORM->_autorow_hook('MyTotally::Absent::Base', undef, 'x') },
    "a genuinely absent base class falls back to the stock Row",
);

ok(
    lives { DBIx::QuickORM->_autorow_hook('MyGood::Base', undef, 'x') },
    "a valid base class loads normally",
);

done_testing;
