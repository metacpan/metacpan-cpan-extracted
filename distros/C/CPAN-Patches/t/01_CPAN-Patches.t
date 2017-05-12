#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 7;
use Test::Dirs 0.03;
use Test::Differences;
use Test::Exception;

use File::Temp;
use File::chdir;
use File::Find::Rule;

use FindBin qw($Bin);
use lib File::Spec->catfile($Bin, 'lib');
use lib File::Spec->catfile($Bin, '..', 'lib');

BEGIN {
    use_ok ( 'CPAN::Patches' ) or exit;
}

exit main();

sub main {
    my $src1      = File::Spec->catdir($Bin, 'to-patch', 'Acme-CPAN-Patches');
    my $src1_res1 = File::Spec->catdir($Bin, 'to-patch', 'Acme-CPAN-Patches.result');
    my $src1_res2 = File::Spec->catdir($Bin, 'to-patch', 'Acme-CPAN-Patches.result2');
    my $set1      = File::Spec->catdir($Bin, 't-patches-set');
    my $set2      = File::Spec->catdir($Bin, 't-patches-set2');
    my $tmp_dir   = temp_copy_ok($src1, 'copy Acme::CPAN::Patches to tmp folder');
    my $empty_dir = File::Temp->newdir();

    my $cpanp = CPAN::Patches->new(
        patch_set_locations => [ $empty_dir, $set1 ],
    );
    my $cpanp2 = CPAN::Patches->new(
        patch_set_locations => [ $empty_dir, $set2 ],
    );

    do {
        local $CWD = $tmp_dir;
        is($cpanp->get_module_folder, File::Spec->catdir($set1, 'acme-cpan-patches'), 'get_module_folder()');

        eq_or_diff(
            [ $cpanp->get_patch_series ],
            [
                map { File::Spec->catdir($Bin, 't-patches-set', 'acme-cpan-patches', 'patches', $_) }
                '30_but-first.patch', '10_but-second.patch'
            ],
            'get series'
        );
    };

    lives_ok { $cpanp->patch($tmp_dir) } 'apply patches';

    # clean-up back-up patch files
    my @orig_files = File::Find::Rule->file()
        ->name( '*.orig' )
        ->in( $tmp_dir );
    foreach my $orig_file (@orig_files) {
        unlink($orig_file);
    }

    is_dir($tmp_dir, $src1_res2, 'patches applied');

    dies_ok { $cpanp2->patch($tmp_dir) } 'apply patches to do not apply';

    return 0;
}

