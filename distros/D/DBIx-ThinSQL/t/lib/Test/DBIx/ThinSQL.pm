package Test::DBIx::ThinSQL;
use strict;
use warnings;
use Exporter::Tidy default => [
    qw/
      run_in_tempdir
      /
];
use File::chdir;
use Path::Tiny;

$DBIx::ThinSQL::SHARE_DIR = path('share')->absolute;

sub run_in_tempdir (&) {
    my $sub = shift;
    my $cwd = $CWD;
    my $tmp = Path::Tiny->tempdir( CLEANUP => 1 );

    local $CWD = $tmp;
    $sub->();

    $CWD = $cwd;
}

1;
