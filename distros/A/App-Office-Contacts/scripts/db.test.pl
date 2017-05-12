#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use App::Office::Contacts::Database::Library;
use App::Office::Contacts::Util::Logger;

use DBI;

use DBIx::Simple;

# ---------

my($library) = App::Office::Contacts::Database::Library -> new;
my($logger)  = App::Office::Contacts::Util::Logger -> new;
my($config)  = $logger -> module_config;

say "dsn: $$config{dsn}. username: $$config{username}. password: $$config{password}. ";
say 'Results from DBI:';

my($attr) = {RaiseError => 1};
my($dbh)  = DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr);
my($sql)  = 'select name from people where upper(name) like ? order by name';
my($sth)  = $dbh -> prepare($sql);
my($name) = 'ÉÉ';

$sth -> execute("%$name%");

while (my $record = $sth -> fetch)
{
	say $$record[0];
}

$dbh -> disconnect;

say 'Results from DBIx::Simple:';

my($simple) = DBIx::Simple -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr);
my($result) = $simple -> query('select name from people where upper(name) like ? order by name', "%$name%")
		|| die $simple -> error;
my(@list_1) = $result -> flat; # Not -> list!
my($list_2) = $library -> decode_list(@list_1);

say "Result:  $_" for @list_1;
say "Decoded: $_" for @$list_2;
