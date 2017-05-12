# $Id$
use strict;
use warnings;
use inc::Module::Install 1.00;

name 'DBIx-Class-UUIDColumns';
license 'perl';
perl_version '5.008001';
all_from 'lib/DBIx/Class/UUIDColumns.pm';

homepage  'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=dbsrgits/DBIx-Class-UUIDColumns.git';
resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'git://git.shadowcat.co.uk/dbsrgits/DBIx-Class-UUIDColumns.git';
resources 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-UUIDColumns';

requires 'DBIx::Class' => '0.07005';

if (
    !eval 'require Data::UUID' &&
    !eval 'require ARE::UUID' &&
    !eval 'require UUID' &&
    !eval 'require Win32::Guidgen' &&
    !eval 'require Win32API::GUID' &&
    !eval 'require Data::Uniqid' &&
    !eval 'require UUID::Random'
    ) {
    requires 'Data::UUID';
};

requires 'Class::Accessor::Grouped';
build_requires 'DBD::SQLite'     => '1.11';

recommends 'Data::UUID';
recommends 'Data::Uniqid';
recommends 'APR::UUID';
recommends 'UUID';
recommends 'Win32::Guidgen';
recommends 'Win32API::GUID';
recommends 'UUID::Random';

tests 't/*.t';
clean_files "DBIx-Class-UUIDColumns-* t/var";

eval {
    system 'pod2text lib/DBIx/Class/UUIDColumns.pm > README';
};

auto_install;

WriteMakefile;
