#!/usr/bin/perl
use ExtUtils::MakeMaker;

# Write the makefile
WriteMakefile(
    'NAME'      => 'Config::Universal',
    'VERSION_FROM' => 'lib/Config/Universal.pm', # finds $VERSION

    'PREREQ_PM' => { 
         XML::DOM   => undef,
         HTTP::Response => undef,
         HTTP::Request::Common => undef,
         LWP::UserAgent => undef,
       },
    'dist'      => { COMPRESS => "gzip -9f" },
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'lib/Config/Universal.pm',
         AUTHOR     => 'Hartmut Vogler <hartmut.vogler@T-Systems.com>') : ()),
);
