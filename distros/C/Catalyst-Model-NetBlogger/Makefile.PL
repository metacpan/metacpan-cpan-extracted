# $Id: /local/CPAN/Catalyst-Model-NetBlogger/Makefile.PL 1392 2008-03-08T01:58:08.842672Z claco  $
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Catalyst-Model-NetBlogger';
license 'artistic';
perl_version '5.008000';
all_from 'lib/Catalyst/Model/NetBlogger.pm';

requires 'Catalyst' => 5.33;
requires 'Net::Blogger' => 1.01;

tests "t/*.t t/*/*.t";
clean_files "Catalyst-Model-NetBlogger-* t/var t/TestApp";

eval {
    system 'pod2text lib/Catalyst/Model/NetBlogger.pm > README';
};

auto_install;
WriteAll;
