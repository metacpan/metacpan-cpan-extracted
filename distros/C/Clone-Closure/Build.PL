use Module::Build;

use Config;

if ($Config{use5005threads}) {
    warn "This module is incompatible with 5005threads\n";
    exit 0;
}
if ($Config{useithreads} and $] < 5.008001) {
    warn "This module is incompatible with ithreads before perl 5.8.1\n";
    exit 0;
}

Module::Build->new(
    module_name     => "Clone::Closure",
    license         => "perl",
    requires        => {
        "XSLoader"          => 0,
    },
    build_requires  => {
        "Test::More"        => "0.88",
        "Data::Dumper"      => 0,
        "Scalar::Util"      => "1.14",
        "Task::Weaken"      => 0,
        "Taint::Runtime"    => 0,
        "File::Temp"        => "0.16",
    },
    include_dirs            => ".",
    meta_merge              => {
        resources => {
            repository => "http://github.com/mauzo/Clone-Closure",
        },
    },
)->create_build_script;
