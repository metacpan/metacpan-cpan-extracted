use Module::Build;
Module::Build->new(
    module_name => 'Darcs::Notify',
    license     => 'perl',
    dist_author => 'David Caldwell <david@porkrind.org>',
    requires    => { 'Darcs::Inventory'  => '1.1',
                     'Mail::Send'        => 0,
    },
    script_files=> [qw"darcs-notify"],
)->create_build_script;
