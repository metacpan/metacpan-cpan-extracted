use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::PasswordManager',
    VERSION_FROM  => 'lib/App/PasswordManager.pm',
    PREREQ_PM     => {
        'Crypt::PBKDF2'  => 0,
        'File::HomeDir'   => 0,
        'File::Spec'      => 0,
        'JSON'            => 0,
    },
    ABSTRACT      => 'Simple password manager for adding, listing, editing, deleting, and copying passwords to the clipboard',
    AUTHOR        => 'Luiz Felipe de Castro Vilas Boas <luizfelipecastrovb@gmail.com>',
    LICENSE       => 'MIT',
    META_MERGE    => {
        resources => {
            repository => 'https://gitlab.com/olooeez/app-passmanager', 
        },
    },
    INSTALLDIRS => 'site',
    EXE_FILES   => ['script/password_manager'],
);

