use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Path::Tiny qw[path];
use File::Temp qw[tempdir];
use Alien::Xrepo;
use Config;
use experimental 'class';
#
my $tmp  = path( tempdir( CLEANUP => 1 ) );
my $repo = Alien::Xrepo->new( root => $tmp, verbose => 0 );
#
subtest cmake => sub {
    my $TODO  = q[this ain't *that* important if we pass everything else...];
    my $cmake = $repo->install('cmake');
    skip_all 'cmake could not be installed from the xrepo registry' unless $cmake;
    is $cmake->kind, 'binary', '->kind is binary';
    my @bin_dirs = $cmake->bin_dir;
    ok @bin_dirs, 'bin_dir is populated';
    my $dir = $bin_dirs[0];
    ok -d $dir, 'bin_dir exists on disk';

    # Resolve the executable name (cmake.exe on Windows, bare cmake elsewhere).
    my $tool = $^O eq 'MSWin32' ? 'cmake.exe' : 'cmake';
    my $exe  = path($dir)->child($tool);
    ok -e $exe, "Found executable: $exe";
    subtest absolute => sub {
        my ( $out, $exit );
        {
            # Use Capture::Tiny if available (it's a runtime prereq of the dist).
            try {
                require Capture::Tiny;
                ( $out, undef, $exit ) = Capture::Tiny::capture { system $exe->absolute, '--version' };
            }
            catch ($e) {
                $out  = `"$exe" --version 2>&1`;
                $exit = $? >> 8;
            }
        }
        ok $exit == 0, 'cmake --version exited 0';
        like $out, qr{cmake\s+version\s+\d}, 'cmake --version reported a version: ' . ( $out // '' );
    };
    subtest path => sub {
        local $ENV{PATH} = join $Config{path_sep}, ( @bin_dirs, $ENV{PATH} );
        my $any_exit = system 'cmake', '--version';
        ok $any_exit == 0, 'bare cmake resolves from bin_dir via PATH';
    }
};
#
done_testing;
