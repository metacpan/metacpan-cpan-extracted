use ExtUtils::MakeMaker;
require 5.008;

WriteMakefile(
    'PREREQ_PM' => { 'Test::More' => 0, CGI::Cookie => 0, Apache2::Const => 0, Apache2::Log => 0, Cache::Memcached => 0 },
    'AUTHOR' => 'Piers Harding <piers@cpan.org>',
    'ABSTRACT' => 'mod_perl replacement for Apache2 authmemcookie authentication module',
    'VERSION_FROM'    => 'lib/Apache/Auth/AuthMemCookie.pm',
    'NAME'    => 'Apache::Auth::AuthMemCookie',
    'clean'   => { 'FILES' },
    'dist'    => { 'TARFLAGS' => 'cvf',
                   'COMPRESS' => 'gzip -9f',
                   'SUFFIX'   => '.tar.gz' },
);

