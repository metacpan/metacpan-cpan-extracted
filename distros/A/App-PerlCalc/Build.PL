if (-d ".git") { # Are we in our development tree? If so, create MANIFEST.
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    print $manifest "MANIFEST\n";
    open $dir, '-|', 'git', 'ls-files' or die "Couldn't run git: $!";
    while (<$dir>) { print $manifest $_ unless /^\./ }
}

use Module::Build;
Module::Build->new(
    module_name => 'App::PerlCalc',
    license     => 'perl',
    dist_author => 'David Caldwell <david@porkrind.org>',
    requires      => {
        perl => '5.8.0',
    },
    recommends    => {
        Term::ReadLine => 0,
    },
    build_requires => {
        Test::Script::Run => 0,
    },
    script_files => ['pc'],
)->create_build_script;
