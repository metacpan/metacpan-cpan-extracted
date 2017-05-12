package Apache::MultiAuth;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw( command_table );
use Apache::src ();


my $directives = [
    {   name      => 'AuthModule',
        errmsg    => 'a list of modules to use for authentication (order is important!)'.
        args_how  => 'ITERATE',
    },
    {
        name      => 'DumpAuthModules',
        errmsg    => 'dumps the configured AuthModules to the error log (for debugging)',
        args_how  => 'FLAG',
    },
];

command_table($directives);
        
WriteMakefile(
    'NAME'         => __PACKAGE__,
    'VERSION_FROM' => 'MultiAuth.pm',
    'PMLIBDIRS'    => [ 'lib' ],
    'INC'          => Apache::src->new->inc,
    'PREREQ_PM'    => { },
    'clean'        => { 'FILES' => '*.xs *.xs.orig' },
);


