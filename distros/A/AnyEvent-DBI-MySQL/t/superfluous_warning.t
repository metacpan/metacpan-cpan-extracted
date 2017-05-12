#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';


local *STDERR;
open STDERR, '>', \my $stderr or die $!;
# failed connect (because of wrong port 3307) will add undefined $dbh into {CachedKids}
AnyEvent::DBI::MySQL->connect($h->dsn.';port=3307', $h->username, $h->password,
    {RaiseError=>0,PrintError=>0});
# passed connect shouldn't print warnings because of undefined $dbh in {CachedKids}
AnyEvent::DBI::MySQL->connect($h->connection_info,
    {RaiseError=>0,PrintError=>0});
# work around warning in EV because ./Build test run `perl -w`
my $cleaned_stderr = join "\n", grep {!/Too late to run CHECK block/} split "\n", $stderr || q{};
is $cleaned_stderr, q{}, 'no warnings';


done_testing();
