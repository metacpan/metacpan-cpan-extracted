use strict;
use warnings;

use Test::More;
use File::Temp 'tempdir';
use FindBin;
use File::Spec::Functions qw/catfile updir/;
use Carp;
my $mhere = catfile( $FindBin::Bin, updir, 'bin', 'mhere' );

my $dir = tempdir( CLEANUP => 1 );
local $ENV{APP_MODULES_HERE} = $dir;
my $usage = <<'EOF';
USAGE: mhere Module [ ... ]
EXAMPLES:
    mhere Carp                                    # copy Carp.pm in @INC to cwd
    mhere -r Carp                                 # copy Carp and all under it.
    mhere Carp CGI                                # copy both Carp.pm and CGI.pm
    APP_MODULES_HERE=outlib mhere Carp            # copy to outlib dir in cwd
    mhere -l outlib Carp                          # ditto
    APP_MODULES_HERE=/tmp/ mhere Carp             # copy to /tmp/
    mhere -l /tmp/ Carp                           # ditto
    mhere Carp --dry-run                          # don't actually copy
EOF

is( `$^X $mhere`,        $usage, 'mhere without args shows usage' );
is( `$^X $mhere -h`,     $usage, 'mhere -h shows useage too' );
is( `$^X $mhere -h Foo`, $usage, 'mhere -h Foo shows usage too' );

is( `$^X $mhere strict`, 'copied module(s): strict' . "\n", 'mhere strict' );
is(
    `$^X $mhere File::Spec::Functions`,
    'copied module(s): File::Spec::Functions' . "\n",
    'mhere File::Spec::Functions'
);

compare_files(
    $INC{'strict.pm'},
    catfile( $dir, 'strict.pm' ),
    'copied strict.pm is indeed a copy'
);

compare_files(
    $INC{'File/Spec/Functions.pm'},
    catfile( $dir, 'File', 'Spec', 'Functions.pm' ),
    'copied File/Spec/Functions.pm is indeed a copy'
);

is(
    `$^X $mhere strict File::Spec::Functions`,
    'copied module(s): strict, File::Spec::Functions' . "\n",
    'mhere strict, File::Spec::Functions'
);

SKIP: {
    eval { require File::Copy::Recursive };
    skip 'need File::Copy::Recursive to use -r', 3 if $@;
    is( `$^X $mhere Carp -r`, 'copied module(s): Carp' . "\n", 'mhere Carp' );

    compare_files(
        $INC{'Carp.pm'},
        catfile( $dir, 'Carp.pm' ),
        'copied Carp.pm is indeed a copy'
    );

    compare_files(
        $INC{'Carp/Heavy.pm'},
        catfile( $dir, 'Carp', 'Heavy.pm' ),
        'copied Carp/Heavy.pm is indeed a copy'
    );
}


# test if the source and the destination is the same file
is(
    `$^X -I$dir $mhere strict`,
    '0 modules are copied' . "\n",
    "don't copy if the source and destination are the same path"
);

my $another_dir = tempdir( CLEANUP => 1 );
is(
    `$^X $mhere -l $another_dir strict`,
    'copied module(s): strict' . "\n",
    'mhere -l $another_dir strict'
);
compare_files(
    $INC{'strict.pm'},
    catfile( $another_dir, 'strict.pm' ),
    'copied strict.pm is indeed a copy'
);

sub compare_files {
    my ( $a, $b, $msg ) = @_;
    open my $ori_fh, '<', $a or die $!;
    open my $new_fh, '<', $b or die $!;

    {
        local $/;
        is( <$ori_fh>, <$new_fh>, $msg || "$a and $b have the same content" )
    }
}

done_testing();
