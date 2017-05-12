#!/usr/bin/perl -w
use warnings;
use strict;

use lib 'lib';

use Test::More;

unless ($ENV{'AMAZON_S3_EXPENSIVE_TESTS'}) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 8;
}

my $aws_access_key_id     = $ENV{'AWS_ACCESS_KEY_ID'};
my $aws_secret_access_key = $ENV{'AWS_ACCESS_KEY_SECRET'};

use Amazon::SimpleDB;

my $sdb =
  Amazon::SimpleDB->new(
                  {
                   aws_access_key_id     => $aws_access_key_id,
                   aws_secret_access_key => $aws_secret_access_key
                  }
  );

ok($sdb);
ok($sdb->isa('Amazon::SimpleDB'));

my $domainname = 'amazon-simpledb-test-' . lc $aws_access_key_id;

ok($sdb->create_domain($domainname));

my $r_domains = $sdb->domains;
ok($r_domains->is_success);

my ($test1) = grep { $_->name eq $domainname } $r_domains->results;
ok($test1);

my $r_delete_domain = $sdb->delete_domain($domainname);
ok($r_delete_domain->is_success);

my $r_domains2 = $sdb->domains;
ok($r_domains2->is_success);

my ($test2) = grep { $_->name eq $domainname } $r_domains2->results;
ok(!$test2); # gone?
