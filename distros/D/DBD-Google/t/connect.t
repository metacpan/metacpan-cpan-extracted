#!/usr/bin/perl
# vim: set ft=perl:

use DBI;
use File::Spec::Functions qw(catfile);
use FindBin qw($Bin);
use Test::More;

plan tests => 7;

my %opts = ("oe" => "utf-8",
            "ie" => "utf-8",
            "safe" => 0,
            "filter" => 1);
my $user = 'x' x 32;
my $dbh = DBI->connect("dbi:Google:", $user, undef, \%opts);

ok(defined $dbh, "DBI->connect('dbi:Google:', '$user') works");
is($dbh->FETCH('driver_google_opts')->{'safe'}, 0, "safe => 0");
is($dbh->FETCH('driver_google_opts')->{'filter'}, 1, "filter => 1");
is($dbh->FETCH('driver_google_opts')->{'oe'}, 'utf-8', 'oe => utf-8');
is($dbh->FETCH('driver_google_opts')->{'ie'}, 'utf-8', 'ie => utf-8');

my $google = $dbh->FETCH('driver_google');
ok($google, "Net::Google instance is retrievable via ".
            '$dbh->FETCH("driver_google")');

my $google_key = -d 't' ? catfile($Bin, 'sample-key')
                        : catfile($Bin, 't', 'sample-key');
$dbh = DBI->connect("dbi:Google:", $google_key);
ok(defined $dbh, "DBI->connect('dbi:Google:', '$google_key') works");
