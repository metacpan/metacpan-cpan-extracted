use strict;
use ExtUtils::MakeMaker;

require 5.005;

WriteMakefile(
    'NAME'           => 'Authen::Htpasswd',
    'ABSTRACT'       => 'Interface to read and modify Apache .htpasswd files',
    'AUTHOR'         => 'David Kamholz <dkamholz@cpan.org>',
    'INSTALLDIRS'    => 'site',
    'LICENSE'        => 'perl',
    'VERSION_FROM'   => 'lib/Authen/Htpasswd.pm',
    'PREREQ_PM'      => {
         'Class::Accessor::Fast' => 0,
         'IO::LockedFile'        => 0,
         'Digest'                => 0,
         'Digest::SHA1'          => 0,
         'Crypt::PasswdMD5'      => 0,
         'Scalar::Util'          => 0,
    },

);
