use strict;
use warnings;
use Config::IniFiles;
use DBI;
use DBIx::Connect::FromConfig -in_dbi;

my $config = Config::IniFiles->new(-file => \*DATA);
my $dbh = DBI->connect_from_config(config => $config);

my $n = shift || int(11900 + rand(64));
print $dbh->selectrow_array("SELECT advice FROM klortho WHERE number=?", {}, $n), $/;

__END__

[database]
driver   = CSV
database = t/db
options  = csv_sep_char=|
