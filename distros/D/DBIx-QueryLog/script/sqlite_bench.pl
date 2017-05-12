use strict;
use warnings;
use lib 'lib';
use t::Util;
use File::Spec;

use DBIx::QueryLog ();

my $dbh = t::Util->new_dbh;

local *STDERR;
open STDERR, '>', File::Spec->devnull or die $!;

my $enabled;
my $disabled;
cmpthese 5000, {
    original => sub {
        DBIx::QueryLog->unimport unless $disabled++;
        $dbh->selectrow_arrayref('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
    },
    logging => sub {
        DBIx::QueryLog->import unless $enabled++;
        $dbh->selectrow_arrayref('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
    },
};
