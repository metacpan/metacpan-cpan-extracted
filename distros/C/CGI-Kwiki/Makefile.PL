use inc::Module::Install;

name         ('CGI-Kwiki');
version_from ('lib/CGI/Kwiki.pm');
author       ('Brian Ingerson <ingy@cpan.org>');
abstract     ("A Quickie Wiki that's not too Tricky");
license      ('perl');

include_deps   ('Test::More', 5.004);
build_requires ('Test::More', 0);

clean_files('t/kwiki');

install_script('kwiki-install');

&Meta->write;
&Makefile->write;
