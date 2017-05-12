#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Find;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %test_requires = (
    'Test::DBGp'        => 0.06,
);

WriteMakefile(
    NAME              => "DBGp::Client",
    VERSION_FROM      => "lib/DBGp/Client.pm",
    ABSTRACT_FROM     => "lib/DBGp/Client.pm",
    AUTHOR            => 'Mattia Barbon <mbarbon@cpan.org>',
    PREREQ_PM         => {
        'XML::Parser'               => 0,
        'XML::Parser::EasyTree'     => 0,
        ( $mm_ver < 6.5503 ?
              %test_requires :
              () ),
    },
    ( $mm_ver >= 6.48 ?     ( MIN_PERL_VERSION  => 5.006 ) :
                            () ),
    ( $mm_ver >= 6.64 ?     ( TEST_REQUIRES     => \%test_requires ) :
      $mm_ver >= 6.5503 ?   ( BUILD_REQUIRES    => \%test_requires ) :
                            ( ) ),
    ( $mm_ver >= 6.31 ?     ( LICENSE           => 'perl_5' ) :
                            () ),
    ( $mm_ver >= 6.46 ?
      ( META_MERGE  => {
          "meta-spec" => { version => 2 },
          resources   => {
              license     => [ 'http://dev.perl.org/licenses/' ],
#              homepage    => 'https://github.com/mbarbon/dbgp-client',
              bugtracker  => {
                  web    => 'https://github.com/mbarbon/dbgp-client/issues',
              },
              repository  => {
                  url  => 'git@github.com:mbarbon/dbgp-client.git',
                  web  => 'https://github.com/mbarbon/dbgp-client',
                  type => 'git',
              },
          },
        },
      ) : () ),
);
