use strict;
use warnings;

use Test::More;

use AlignDB::IntSpan;

# new and valid
{
    my @data = (
        [ '1.2',   'syntax' ],
        [ '1-2-3', 'syntax' ],
        [ '1,,2',  'syntax' ],
        [ '--',    'syntax' ],
        [ 'abc',   'syntax' ],
        [ '2-1',   'order' ],

        # These are valid here but not in Set::IntSpan
        # [ '1,1,1,1', 'order' ],
        # [ '2,1',     'order' ],
        # [ '3-4,1-2', 'order' ],
    );
    my $count = 1;
    for my $t (@data) {
        my $runlist  = $t->[0];
        my $expected = $t->[1];

        eval { AlignDB::IntSpan->new($runlist) };
        printf "# AlignDB::IntSpan->new( %s ) -> %s", $runlist, $@;
        like( $@, qr{$expected}, "error-new $count" );

        my $valid = AlignDB::IntSpan->valid($runlist);
        printf "# AlignDB::IntSpan->valid( %s ) -> %s", $runlist, $@;
        ok( $valid or ( $@ !~ qr{$expected} ), "error-valid $count" );

        $count++;
    }
    print "\n";
}

done_testing();
