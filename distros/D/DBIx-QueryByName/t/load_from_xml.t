#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib File::Spec->catdir("..","lib"), File::Spec->catdir($FindBin::Bin,"..","lib");
use Test::More;
use Data::Dumper;
use File::Temp qw(tempfile);
use Fcntl;

BEGIN {

    # skip test if missing dependency
    foreach my $m ('XML::Parser','XML::SimpleObject','Test::Exception') {
        eval "use $m";
        plan skip_all => "test require missing module $m" if $@;
    }

    plan tests => 69;

    use_ok("DBIx::QueryByName");
}

# now we can start testing!
my $dbh = DBIx::QueryByName->new();
is(ref $dbh, 'DBIx::QueryByName', "new: bless properly");

# faked query file
sub print_to_file {
    my $file = shift;
    my $str = shift;
    open(FILE,"> $file") or die "failed to open file $file: $!";
    print FILE $str;
    close(FILE);
}

my (undef,$tmpq) = tempfile();
print_to_file($tmpq,'<queries><query name="WriteNewTest" params="Username,Password,Host,Value">SELECT Write_New_Tese(?,?,?,?)</query></queries>');

#
# test load's argument checking
#

throws_ok { $dbh->load() } qr/undefined session name/, "load: error on no arguments";
throws_ok { $dbh->load(session => undef) } qr/undefined session name/, "load: error on undefined session";
throws_ok { $dbh->load(session => 'name') } qr/unknown or undefined load source/, "load: error on undefined source";
throws_ok { $dbh->load(from_xml_file => 'file') } qr/undefined session name/, "load: error on from_xml_file but no session";
throws_ok { $dbh->load(session => undef, no_known_tag => 'file') } qr/undefined session name/, "load: error on undefined 1st argument";
throws_ok { $dbh->load(session => 'name', no_known_tag => 'file') } qr/unknown or undefined load source/, "load: error on unknown tag";
throws_ok { $dbh->load(session => 'name', no_known_tag => 'file', from_xml_file => $tmpq) } qr/unexpected arguments/, "load: error on unexpected arguments";

throws_ok { $dbh->load(session => 'name', from_xml_file => 'file') } qr/no such file: \[file\]/, "load: error on non existing xml file";
throws_ok { $dbh->load(session => 'name', from_xml_file => undef) } qr/undefined xml file/, "load: error on undefined from_xml_file";

#
# now load some invalid query files
#

print_to_file($tmpq,'');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/failed to parse xml/, "load: croak on empty query file";

print_to_file($tmpq,'oaeunscaosneuhk');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/failed to parse xml/, "load: croak on non xml query file";

print_to_file($tmpq,'<html><body>blabla<\html><\body>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/failed to parse xml/, "load: croak on invalid xml query file";
print_to_file($tmpq,'<html><body>blabla</html></body>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/failed to parse xml/, "load: croak on wrong xml tag order";

print_to_file($tmpq,'<html><body>blabla</body></html>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/failed to parse xml/, "load: croak on xml with no queries node";

print_to_file($tmpq,'<queries></queries>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/invalid xml: no .query. nodes/, "load: croak when no <query> child node";

print_to_file($tmpq,'<queries>blabla<query>aouaoue</query></queries>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/invalid xml: no name attribute in query node/, "load: croak when no name attribute in <query>";

foreach my $c (split(//,'!?:;/\|{}[]()~^#*-+%@$,')) {
    print_to_file($tmpq,'<queries><query name="aoueaou'.$c.'" params="bob">aouaoue</query></queries>');
    throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/invalid query name: contain non alfanumeric characters/, "load: croak when name contains [$c]";
}

print_to_file($tmpq,'<queries>blabla<query name="aoueaou">aouaoue</query></queries>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/invalid xml: no params attribute in query node/, "load: croak when no params attribute in <query>";

print_to_file($tmpq,'<queries>blabla<query name="aoueaou">aouaoue</query></queries>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/invalid xml: no params attribute in query node/, "load: croak when no params attribute in <query>";

foreach my $c (split(//,'!?:;/\|{}[]()~^#*-+%@$')) {
    print_to_file($tmpq,'<queries><query name="aoueaou" params="bip'.$c.'cbop">aouaoue</query></queries>');
    throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/invalid query parameter: contain non alfanumeric characters/, "load: croak when params contains [$c]";
}

print_to_file($tmpq,'<queries>blabla<query name="aoueaou" params="bip,bop">aouaoue</query><query name="aoueaou" params="trip,trop"></query></queries>');
throws_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } qr/query already imported .query_name .. aoueaou, /, "load: croak query imported twice";

$dbh = DBIx::QueryByName->new();

my $q = <<__END4__;
<queries>
<!--
        <query name="WriteNewTest" params="Username,Password,Host,Value">SELECT Write_New_Tese(?,?,?,?)</query>
-->
        <query name="GetDailyHourlyActivityDistribution" params="User_name,Password,Host,FromDate,ToDate">SELECT Get_Daily_Hourly_Activity_Distribution(?,?,?,?,?)</query>
        <query name="Lookup_Transaction_Source" params="Username,Password,Host,StatementReference">SELECT * FROM Lookup_Transaction_Source(?,?,?,?)</query>
</queries>
__END4__

print_to_file($tmpq,$q);
lives_ok { $dbh->load(session => 'q', from_xml_file => $tmpq) } "no problem on well formatted queries";

$q = <<__END5__;
<queries>
        <query name="ParamsWithSpaces" params=" Username , Password , Host   , Value">SELECT Write_New_Tese(?,?,?,?)</query>
</queries>
__END5__

print_to_file($tmpq,$q);
lives_ok { $dbh->load(session => 'r', from_xml_file => $tmpq) } "spaces are accepted in param list";

# will break if QueryPool gets refactored...
my $params = $dbh->_query_pool->{ParamsWithSpaces}->{params};
is_deeply($params, ['Username','Password','Host','Value'], "params were parsed correctly");




