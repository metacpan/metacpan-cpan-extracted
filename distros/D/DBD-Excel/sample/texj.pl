use strict;
use DBI;
use Spreadsheet::ParseExcel::FmtJapan2;
my $oFmtJ = Spreadsheet::ParseExcel::FmtJapan2->new( Code => 'euc');
my $hDb = DBI->connect("DBI:Excel:file=dbdtest.xls", undef, undef, 
                        { xl_fmt => $oFmtJ,
                          xl_vtbl => 
                            {TESTV => 
                                {
                                    sheetName => 'TEST_V',
                                    ttlRow    => 5,
                                    startCol  => 1,
                                    colCnt    => 4,
                                    datRow    => 6,
                                    datLmt    => 4,
                                }
                            }
                        });
print<<"----";
#--------------------------------------------------------------
# 1. SELECT(with no params)
----
my $hSt = $hDb->prepare(q/SELECT * FROM TEST/);
$hSt->execute();
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 2. SELECT(with params)
----
$hSt = $hDb->prepare(q/SELECT * FROM TEST WHERE No > ? AND Age < ?/);
$hSt->execute(1, 50);
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 3. INSERT(with params)
----
$hSt = $hDb->prepare(q/INSERT INTO TEST VALUES (?, ?, ?, ?, ?)/);
$hSt->execute(4, 'Newman 4', 'New Dept', 30, 'newman4@hippo2000.net');
$hSt->execute(5, 'Newman 5', 'New Dept', 32, 'newman5@hippo2000.net');
print<<"----";
#--------------------------------------------------------------
# 4. DELETE(with params)
----
$hSt = $hDb->prepare(q/DELETE FROM TEST WHERE No = ?/);
$hSt->execute(1);
$hSt->execute(3);
print<<"----";
#--------------------------------------------------------------
# 5. UPDATE(with params)
----
$hSt = $hDb->prepare(q/UPDATE TEST SET Mail = ? WHERE No = ?/);
$hSt->execute('Mail Upd', 2);
print<<"----";
#--------------------------------------------------------------
# 6. SELECT(again)
----
$hSt = $hDb->prepare(q/SELECT * FROM TEST/);
$hSt->execute();
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 7. CREATE TABLE, DROP TABLE
----
$hDb->do(q/CREATE TABLE NEW_TBL (ID CHAR(10), NO INTEGER, NAME VARCHAR(200))/);
$hDb->do(q/DROP TABLE DEL_TEST/);

print<<"----";
#--------------------------------------------------------------
# 1. SELECT(with no params): VTBL
----
$hSt = $hDb->prepare(q/SELECT * FROM TESTV/);
$hSt->execute();
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 2. SELECT(with params)
----
$hSt = $hDb->prepare(q/SELECT * FROM TESTV WHERE No > ? /);
$hSt->execute(1);
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 3. UPDATE(with params)
----
$hSt = $hDb->prepare(q/UPDATE TESTV SET Age = ? WHERE No = ?/);
$hSt->execute(50, 3);
print<<"----";
#--------------------------------------------------------------
# 4. DELETE(with params)
----
$hSt = $hDb->prepare(q/DELETE FROM TESTV WHERE No = ?/);
$hSt->execute(2);
print<<"----";
#--------------------------------------------------------------
# 5. INSERT(with params)
----
$hSt = $hDb->prepare(q/INSERT INTO TESTV VALUES (?, ?, ?, ?, ?)/);
$hSt->execute(4, 'Newman 4', 'New Dept', 30, 'KABA');
$hSt->execute(5, 'Newman 5', 'New Dept', 32, 'DESUYO');
print<<"----";
#--------------------------------------------------------------
# 6. SELECT(again)
----
$hSt = $hDb->prepare(q/SELECT * FROM TESTV/);
$hSt->execute();
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 7. List tables, data sources
----
foreach my $sTbl ($hDb->func('list_tables')){
    print "TABLE: $sTbl\n";
}
my $hDr = DBI->install_driver("Excel");
foreach my $sDsn ($hDr->data_sources({xl_data => '.'})) { 
    print "DSN: $sDsn\n";
}
print<<"----";
#--------------------------------------------------------------
# 8. Japanese test
----
my $hStJ = $hDb->prepare(q/SELECT * FROM TEST_JAPAN/);
$hStJ->execute();
while(my $raRes = $hStJ->fetchrow_arrayref()) {
    print "DATA:", join(',', map {$_||=''} @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 9. Save this Excel file
----
$hDb->func('newxlj.xls', 'save');
