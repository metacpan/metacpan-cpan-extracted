#!/usr/bin/perl
use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME         => 'DJabberd::Delivery::OfflineStorage',
              VERSION_FROM => 'lib/DJabberd/Delivery/OfflineStorage.pm',
              ABSTRACT_FROM => 'lib/DJabberd/Delivery/OfflineStorage.pm',
              PREREQ_PM    => {
                  'DJabberd'                => '0.80',
                  'DBD::SQLite'             => '1.08',
                  'DBI',                    => 0,
              },
              AUTHOR     => 'Piers Harding <piers@cpan.org>',
              );

