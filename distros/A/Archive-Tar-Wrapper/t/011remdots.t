use strict;
use warnings;
use Archive::Tar::Wrapper;
use Test::More;

my $arch    = Archive::Tar::Wrapper->new();
my @samples = (
    [ '.',         '..',      'ar',     'ogoyugfyu', 'iohoihoi', 'pojij' ],
    [ '..',        'buiv',    'oihoih', 'oiggf',     '.' ],
    [ 'uiuig',     'ohphpui', 'nuvg',   '.',         '..' ],
    [ 'uigbyufcd', 'opkokj',  '.',      '..',        'ugoig' ],
    [ 'uigbyufcd', '.',       'opkokj', '..',        'ugoig' ]
);

plan tests => scalar(@samples);

for my $sample_ref (@samples) {
    $arch->_rem_dots($sample_ref);
    ok( has_no_dots($sample_ref), 'all dots removed' )
      or diag( explain($sample_ref) );
}

sub has_no_dots {
    my $entries_ref = shift;
    my $result      = 1;

    for my $entry ( @{$entries_ref} ) {
        if ( ( $entry eq '.' ) or ( $entry eq '..' ) ) {
            $result = 0;
            last;
        }
    }

    return $result;
}
