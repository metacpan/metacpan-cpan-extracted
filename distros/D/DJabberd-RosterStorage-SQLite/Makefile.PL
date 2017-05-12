#!/usr/bin/perl
use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME         => 'DJabberd::RosterStorage::SQLite',
              VERSION_FROM => 'lib/DJabberd/RosterStorage/SQLite.pm',
              ABSTRACT_FROM => 'lib/DJabberd/RosterStorage/SQLite.pm',
              PREREQ_PM    => {
                  'DJabberd'                => '0.80',
                  'DBD::SQLite'             => '1.08',
                  'DBI',                    => 0,
              },
              AUTHOR     => 'Brad Fitzpatrick <brad@danga.com>',
              );

