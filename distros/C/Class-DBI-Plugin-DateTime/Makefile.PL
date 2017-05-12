use strict;
use inc::Module::Install;

name('Class-DBI-Plugin-DateTime');
all_from 'lib/Class/DBI/Plugin/DateTime.pm';

requires 'Class::DBI';
requires 'DateTime';
requires 'Module::Pluggable';

my $y_n;

{
    $y_n = prompt(<<EOM, 'y');

Do you plan to use PostgreSQL? If so, I can add the required prerequisites
to enable PostgreSQL support.

EOM
    if ($y_n =~ /^y(?:es)?$/i) {
        requires 'DBD::Pg';
        requires 'DateTime::Format::Pg';
    }
}

{
    $y_n = prompt(<<EOM, 'y');

Do you plan to use MySQL? If so, I can add the required prerequisites
to enable MySQL support.

EOM
    if ($y_n =~ /^y(?:es)?$/i) {
        requires 'DBD::mysql';
        requires 'DateTime::Format::MySQL';
    }
}

test_requires 'Test::More';

WriteAll;
