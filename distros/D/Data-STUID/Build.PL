use strict;
BEGIN {
    my @plugins = qw(Repository CPANfile);
    if (! -f "README.mkdn") {
        push @plugins, "ReadmeMarkdownFromPod";
    }
    require Module::Build::Pluggable;
    Module::Build::Pluggable->import(@plugins);
}

my $builder = Module::Build::Pluggable->new(
    license             => 'artistic_2',
    dynamic_config      => 0,
    no_index            => { 'directory' => [ 'inc' ] },
    module_name         => 'Data::STUID',
    configure_requires  => {
        'Module::Build'                         => '0.40',
        'Module::Build::Pluggable'              => '0.05',
        'Module::Build::Pluggable::CPANfile'    => '0.01',
    },
);

$builder->create_build_script;
if (-f "META.yml" && ! -f "MYMETA.yml") { # fallback if we don't have CPAN::Meta
    require File::Copy;
    File::Copy::copy("META.yml", "MYMETA.yml") or warn "Error: $!\n";
    if ( -f 'MYMETA.yml' ) {
        warn "Copied META.yml to MYMETA.yml for bootstrapping\n";
    } else {
        warn "Could not copy META.yml to MYMETA.yml.  That's odd!\n";
    }
}
