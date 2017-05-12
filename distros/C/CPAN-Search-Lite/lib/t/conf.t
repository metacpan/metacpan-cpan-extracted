#!/usr/bin/perl
use strict;
use warnings;
no warnings 'redefine';

use Test;
use Cwd;
use File::Spec::Functions;
use CPAN::Search::Lite::Index;
*CPAN::Search::Lite::Index::DESTROY = sub {};
use Config::IniFiles;

plan tests => 28;

my $cwd = getcwd;
my $tdir = catdir $cwd, 't';
ok (-d $tdir);

{
  my $config = catfile $tdir, 'cpan.conf';
  ok (-f $config);
  my $index = CPAN::Search::Lite::Index->new(config => $config);
  ok(defined $index);
  
  my $cfg = Config::IniFiles->new(-file => $config);
  ok (defined $cfg);
  
  my @sections = $cfg->Sections();
  foreach my $section (@sections) {
    my @parameters = $cfg->Parameters($section);
    foreach my $parameter(@parameters) {
      ok($index->{$parameter}, $cfg->val($section, $parameter));
    }
  }
}

{
  my $config = catfile $tdir, 'cpan1.conf';
  $ENV{CSL_CONFIG_FILE} = $config;
  my $index = CPAN::Search::Lite::Index->new();
  ok(defined $index);
  
  my $cfg = Config::IniFiles->new(-file => $config);
  ok (defined $cfg);
  
  my @sections = $cfg->Sections();
  foreach my $section (@sections) {
    my @parameters = $cfg->Parameters($section);
    foreach my $parameter(@parameters) {
      if ($parameter eq 'ignore') {
        my @values = $cfg->val($section, $parameter);
        foreach my $i(0 .. $#values) {
          ok($values[$i], $index->{ignore}->[$i]);
        }
      }
      else {
        ok($index->{$parameter}, $cfg->val($section, $parameter));
      }
    }
  }
}

