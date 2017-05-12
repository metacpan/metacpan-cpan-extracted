#netinterface.pl
# 	- Displays network interfaces and information
#       - Alexander Breibach, 2010-01-05

use strict;
use warnings;

use DBI;
use Text::TabularDisplay;

my $dbh = DBI->connect("DBI:Sys:") or die $DBI::errstr;
my $st  = $dbh->prepare("SELECT * FROM netint") or die $dbh->errstr;
my $num = $st->execute() or die $st->errstr;

my $row;
my $table = Text::TabularDisplay->new( @{$st->{NAME_lc}} );
   $table->add(@{$row})
           while ($row = $st->fetchrow_arrayref);
    print $table->render . "\n";

# GetOpt succeed, else failed
