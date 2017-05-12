use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $t = Test::Compile::Internal->new(verbose=>1);

my @modules = $t->all_pm_files();

eval { require SVN::Core; require SVN::Fs; 1 } or do {
    $t->diag($@);
    $t->diag("SVN::Core/Fs unavailable, skipping compilation test of App::KGB::Client::Subversion");
    @modules = grep { $_ !~ m,App/KGB/Client/Subversion.pm$, } @modules;
};

eval { require Git; 1 } or do {
    $t->diag($@);
    $t->diag("Git unavailable, skipping compilation test of App::KGB::Client::Git");
    @modules = grep { $_ !~ m,App/KGB/Client/Git.pm$, } @modules;
};

$t->ok( $t->pm_file_compiles($_), "$_ compiles" ) for @modules;

$t->done_testing();
