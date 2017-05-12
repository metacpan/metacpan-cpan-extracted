use strict;
use lib '.';
use inc::Module::Install;

name                ('Cookie-XS');
license             ('perl');
author              ('Agent Zhang <agentzh@yahoo.cn>');
perl_version        ('5.006001');
all_from            ('lib/Cookie/XS.pm');

requires           ('CGI::Cookie::XS' => '0.15');
build_requires     ('Test::More');
#requires           ('CGI::Cookie::XS');

warn "WARNING!!! This module is now obsolete; please use CGI::Cookie::XS instead.\n";

auto_install();
WriteAll();

