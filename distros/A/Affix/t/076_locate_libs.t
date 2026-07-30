use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
use Config;
$|++;
#
subtest 'locate_libs returns empty for non-existent library' => sub {
    skip_all 'locate_libs not available' unless defined &Affix::locate_libs;
    my @libs = Affix::locate_libs('totally_nonexistent_library_xyz');
    is scalar @libs, 0, 'locate_libs returns empty for missing lib';
};
#
subtest 'locate_libs with version parameter' => sub {
    skip_all 'locate_libs not available' unless defined &Affix::locate_libs;
    my @libs = Affix::locate_libs( 'totally_nonexistent_library_xyz', 0 );
    ok scalar @libs >= 0, 'locate_libs with version=0 returns results without crash';
};
#
subtest 'locate_libs finds kernel32 on Windows' => sub {
    skip_all 'locate_libs not available' unless defined &Affix::locate_libs;
    skip_all 'Windows-only test'         unless $^O eq 'MSWin32';
    my @libs = Affix::locate_libs('kernel32');
    ok scalar @libs > 0, 'locate_libs found kernel32.dll';
};
#
subtest 'libm and libc return values' => sub {
    my $m = libm();
    ok defined $m, 'libm() returns a defined value';
    my $c = libc();
    ok defined $c, 'libc() returns a defined value';
};
#
subtest 'libm and libc are usable for loading' => sub {
    my $m = libm();
    skip_all 'libm() returned undef' unless defined $m;
    ok ref($m) eq 'Affix::Memory' || ref($m) eq 'Path::Tiny' || !ref($m), 'libm() returns Affix::Memory, Path::Tiny, or path string';
};
done_testing;
