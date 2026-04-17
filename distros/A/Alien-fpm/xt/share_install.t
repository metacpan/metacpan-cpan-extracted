use Test2::V0;
use Test::Alien;
use Test::Alien::Build;
use Path::Tiny;

use Env qw( @GEM_PATH );

alien_subtest 'share install from gem' => sub {
    local $ENV{ALIEN_FPM_GIT_URL};
    local $ENV{ALIEN_FPM_GIT_BRANCH};
    local $ENV{ALIEN_FPM_VERSION};
    local $ENV{GEM_PATH};

    alienfile_ok filename => 'alienfile';
    alien_install_type_is 'share';
    my $alien = alien_build_ok;
    alien_ok $alien;
    like path($alien->dist_dir, 'bin', 'fpm')->slurp, qr/ruby/, 'write_gemrc set custom shebang';
    unshift @GEM_PATH, $alien->dist_dir;
    run_ok(['fpm', '--version'])->success->note;
};

alien_subtest 'share install from gem with ALIEN_FPM_VERSION' => sub {
    local $ENV{ALIEN_FPM_GIT_URL};
    local $ENV{ALIEN_FPM_GIT_BRANCH};
    local $ENV{ALIEN_FPM_VERSION} = '1.16.0';
    local $ENV{GEM_PATH};

    alienfile_ok filename => 'alienfile';
    alien_install_type_is 'share';
    my $alien = alien_build_ok;
    alien_ok $alien;
    like path($alien->dist_dir, 'bin', 'fpm')->slurp, qr/ruby/, 'write_gemrc set custom shebang';
    unshift @GEM_PATH, $alien->dist_dir;
    run_ok(['fpm', '--version'])
      ->success
      ->out_like(qr/1\.16\.0/, 'correct version installed from gem')
      ->note;
};

alien_subtest 'share install from git' => sub {
    local $ENV{ALIEN_FPM_GIT_URL} = 'https://github.com/jordansissel/fpm.git';
    local $ENV{ALIEN_FPM_GIT_BRANCH} = 'v1.16.0';
    local $ENV{ALIEN_FPM_VERSION};
    local $ENV{GEM_PATH};

    alienfile_ok filename => 'alienfile';
    alienfile_skip_if_missing_prereqs;
    alien_install_type_is 'share';
    my $alien = alien_build_ok;
    alien_ok $alien;
    like path($alien->dist_dir, 'bin', 'fpm')->slurp, qr/ruby/, 'write_gemrc set custom shebang';
    unshift @GEM_PATH, $alien->dist_dir;
    run_ok(['fpm', '--version'])
      ->success
      ->out_like(qr/1\.16\.0/, 'correct branch was cloned')
      ->note;
};

alien_subtest 'share install from git with ALIEN_FPM_VERSION' => sub {
    local $ENV{ALIEN_FPM_GIT_URL} = 'https://github.com/jordansissel/fpm.git';
    local $ENV{ALIEN_FPM_GIT_BRANCH};
    local $ENV{ALIEN_FPM_VERSION} = '1.16.0';
    local $ENV{GEM_PATH};

    alienfile_ok filename => 'alienfile';
    alienfile_skip_if_missing_prereqs;
    alien_install_type_is 'share';
    my $alien = alien_build_ok;
    alien_ok $alien;
    like path($alien->dist_dir, 'bin', 'fpm')->slurp, qr/ruby/, 'write_gemrc set custom shebang';
    unshift @GEM_PATH, $alien->dist_dir;
    run_ok(['fpm', '--version'])
      ->success
      ->out_like(qr/1\.16\.0/, 'correct version from auto-derived git tag')
      ->note;
};

done_testing;
