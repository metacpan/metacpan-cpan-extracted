use v5.40;
use feature qw[class try];
no warnings 'experimental::class';
#
class Alien::Xrepo::Runtime::Alt v1.0.10 {
    field $base : param;
    field $pkg : reader(pkg_name) : param;
    method package_names ()      { $base->package_names }
    method package_info ()       { $base->package_info($pkg) }
    method alt ( $name = undef ) { $base->alt( $name // $pkg ) }
    method libpath ()            { $base->libpath($pkg) }
    method ffi_lib ()            { $base->libpath($pkg) }
    method bin_dir ()            { $base->bin_dir($pkg) }
    method version ()            { $base->version($pkg) }
    method kind ()               { $base->kind($pkg) }
    method cflags ()             { $base->cflags($pkg) }
    method cflags_static ()      { $base->cflags($pkg) }
    method libs ()               { $base->libs($pkg) }
    method libs_static ()        { $base->libs($pkg) }
    method dynamic_libs ()       { $base->dynamic_libs($pkg) }
    method dist_dir ()           { $base->dist_dir($pkg) }
    method install_type ()       { $base->install_type($pkg) }
    method prepend_to_path ()    { $base->prepend_to_path($pkg) }
    method split_flags ($flags)    { $base->split_flags( $flags, $pkg ) }
    method find_header ($filename) { $base->find_header( $filename, $pkg ) }
    method runtime_deps ()         { $base->runtime_deps($pkg) }
    method foreign_runtime_deps () { $base->foreign_runtime_deps($pkg) }
    method runtime_dep_dirs ()     { $base->runtime_dep_dirs($pkg) }
    method loader_env_var ()       { $base->loader_env_var }
    method runtime_dep_report ()   { $base->runtime_dep_report($pkg) }
};
#
1;
