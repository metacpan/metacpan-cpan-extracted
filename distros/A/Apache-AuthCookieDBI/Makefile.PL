# $Id: Makefile.PL,v 1.3.2.1 2007/02/01 18:29:21 matisse Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'          => 'Matisse Enzer (matisse@cpan.org)',
    # 'ORIGINAL_AUTHOR' => 'Jacob Davies (jacob@well.com)',
    'NAME'            => 'Apache::AuthCookieDBI',
    'VERSION_FROM'    => 'AuthCookieDBI.pm',                   # finds $VERSION
    'PREREQ_PM'       => {
        'Apache::AuthCookie' => '0',
        'Date::Calc'         => '0',
        'Digest::MD5'        => '0',
        'Apache::DBI'        => '0',
        'Apache::Constants'  => '0',
        'Apache'             => '0',
        'DBI'                => '0',
    }
);
