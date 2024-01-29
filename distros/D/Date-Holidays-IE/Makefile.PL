#!perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Date::Holidays::IE',
    VERSION_FROM      => 'lib/Date/Holidays/IE.pm',
    PREREQ_PM         => { 'Date::Holidays::Super' => 0},
    ABSTRACT_FROM     => 'lib/Date/Holidays/IE.pm',
    AUTHOR            => 'Aaron Trevena <teejay@cpan.org>',
    LICENSE           => 'perl'
);
