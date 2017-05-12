#!/usr/bin/perl -w
use strict;
use Test::More;
use DBI;

if ($^O !~ /Win32/i) {
    plan skip_all => "DBD::WMI only works on Win32 so far";
} else {
    plan tests => 5;
};

my $dbh = DBI->connect('dbi:WMI:');
isa_ok $dbh, 'DBI::db';

my @tests = map { [ split /\s*=>\s*/m ]} grep { /\S/ } split /^$/m, q{

SELECT * FROM Win32_Process
=> *
=> Single asterisk

SELECT foo,bar FROM Win32_Process
=> foo,bar
=> Two columns

SELECT foo,count(bar) FROM Win32_Process
=> foo,count(bar)
=> Function (not implemented but gets passed through)

ASSOCIATORS OF {Win32_Directory.Name='C:\WINNT'}
  WHERE ResultClass = CIM_DataFile
=> *
=> Non-SELECT statement gets asterisk

};

for (@tests) {
    my ($wql,$expected,$name) = @$_;
    next unless $wql =~ /\S/;
    chomp $expected;
    chomp $name;
    my $sth = $dbh->prepare($wql);
    if (! is join(",", @{ $sth->{wmi_return_columns}}), $expected,$name) {
        diag $wql;
    };
};
