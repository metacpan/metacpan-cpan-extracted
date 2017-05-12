#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Fact::PlatformInfo;
use Test::More  tests => 3;

my $report = {
    platform_info => {
        osname      => 'TestOS',
        archname    => 'Test OS',
        osvers      => '1.00',
        oslabel     => 'test-os',
        is32bit     => 1,
        is64bit     => 0,
        osflag      => 'TestOS',
        codename    => 'Tester',
        kernel      => 'test',
    }
};

{
  my $fact = CPAN::Testers::Fact::PlatformInfo->new(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content     => {
      osname        => $report->{platform_info}{osname}     ,
      archname      => $report->{platform_info}{archname}   ,
      osvers        => $report->{platform_info}{osvers}     ,
      oslabel       => $report->{platform_info}{oslabel}    ,
      is32bit       => $report->{platform_info}{is32bit}    ,
      is64bit       => $report->{platform_info}{is64bit}    ,
      osflag        => $report->{platform_info}{osflag}     ,
      codename      => $report->{platform_info}{codename}   ,
      kernel        => $report->{platform_info}{kernel}
    },
  );

  isa_ok($fact,'CPAN::Testers::Fact::PlatformInfo');

  my $content = $fact->content_metadata();
  is($content->{osname},$report->{platform_info}{osname},'returns osname');

  my $types = $fact->content_metadata_types();
  is($types->{osname},'//str','returns osname type');
}
