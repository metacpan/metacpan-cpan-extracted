#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use Data::Dumper;

BEGIN { use_ok('Config::Validate') };

my $cv = Config::Validate->new;

{ # normal domain test case

  my @valid = qw(www.google.com google.com com 3com.com);
  $cv->schema({ testdomain => { type => 'domain' }});

  foreach my $domain (@valid) {
    my $value = { testdomain => $domain };
    eval { $cv->validate($value) };
    is($@, '', "valid domain case succeeded ($domain)");
  }

  my @invalid = qw(test/domain.com _blah.com);
  $cv->schema({ testdomain => { type => 'domain' }});

  foreach my $domain (@invalid) {
    my $value = { testdomain => $domain };
    eval { $cv->validate($value) };
    my $error = quotemeta("[/testdomain]: '$domain' is not a valid domain name.");
    like($@, "/$error/", "invalid domain case succeeded as expected ($domain)");
  }
}

{ # normal hostname test case

  my @valid = qw(www.google.com google.com com 3com.com);
  $cv->schema({ testhostname => { type => 'hostname' }});

  foreach my $hostname (@valid) {
    my $value = { testhostname => $hostname };
    eval { $cv->validate($value) };
    is($@, '', "valid hostname case succeeded ($hostname)");
  }

  my @invalid = qw(test/hostname.com _blah.com);
  $cv->schema({ testhostname => { type => 'hostname' }});

  foreach my $hostname (@invalid) {
    my $value = { testhostname => $hostname };
    eval { $cv->validate($value) };
    my $error = quotemeta("[/testhostname]: '$hostname' is not a valid hostname.");
    like($@, "/$error/", "invalid hostname case succeeded as expected ($hostname)");
  }
}

