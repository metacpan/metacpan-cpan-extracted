#!/usr/bin/perl
use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME         => 'DJabberd::Authen::UserLimit',
              VERSION_FROM => 'lib/DJabberd/Authen/UserLimit.pm',
              ABSTRACT_FROM => 'lib/DJabberd/Authen/UserLimit.pm',
              PREREQ_PM    => {
                  'DJabberd'                => '0.80',
              },
              AUTHOR     => 'Michael Scherer <misc@zarb.org>',
              );

