use strict;
use DBI;
print<<"----";
#------------------------------------------------------------
# Test for skiphiddedn 
#  This option is created by Ilia Sotnikov.
#  Thank you, Ilia.
----
my $hDb = DBI->connect("DBI:Excel:file=thidden.xls", undef, undef, 
                    {xl_vtbl => 
                            {TESTV => 
                                {
                                    sheetName => 'TEST',
                                    ttlRow    => 0,
                                    startCol  => 1,
                                    colCnt    => 3,
                                    datRow    => 1,
                                    datLmt    => 2,
                                }
                            }
                    });
print<<"----";
#--------------------------------------------------------------
# 1. SELECT(with no params)
#--------------------------------------------------------------
----
my $hSt = $hDb->prepare(q/SELECT * FROM TEST/);
$hSt->execute();
my $raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 2. SELECT(vtbl)
#--------------------------------------------------------------
----
$hSt = $hDb->prepare(q/SELECT * FROM TESTV/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 3. SELECT(with condition)
#--------------------------------------------------------------
----
$hSt = $hDb->prepare(q/SELECT NAME FROM TEST WHERE Dept='HIDDEN'/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 4. SELECT(vtbl:with condition)
#--------------------------------------------------------------
----
$hSt = $hDb->prepare(q/SELECT NAME FROM TEST WHERE NAME <> 'Emp2'/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#==============================================================
# SKIPHIDDEN
#==============================================================
----
my $hDbS = DBI->connect("DBI:Excel:file=thidden.xls", undef, undef, 
                    {
                    xl_skiphidden => 1,
                    xl_vtbl =>
                            {TESTV => 
                                {
                                    sheetName => 'TEST',
                                    ttlRow    => 0,
                                    startCol  => 1,
                                    colCnt    => 3,
                                    datRow    => 1,
                                    datLmt    => 2,
                                }
                            }
                    });
print<<"----";
#--------------------------------------------------------------
# 1. SELECT(with no params, skip hiddedn)
#--------------------------------------------------------------
----
$hSt = $hDbS->prepare(q/SELECT * FROM TEST/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 2. SELECT(vtbl, skip hidden)
#--------------------------------------------------------------
----
$hSt = $hDbS->prepare(q/SELECT * FROM TESTV/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 3. SELECT(with condition)
#--------------------------------------------------------------
----
$hSt = $hDbS->prepare(q/SELECT NAME FROM TEST WHERE Dept='HIDDEN'/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 4. SELECT(vtbl:with condition)
#--------------------------------------------------------------
----
$hSt = $hDbS->prepare(q/SELECT NAME FROM TEST WHERE NAME <> 'Emp2'/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#==============================================================
# SKIPHIDDEN+IGONORECASE
#==============================================================
----
my $hDbSI = DBI->connect("DBI:Excel:file=thidden.xls", undef, undef, 
                    {
                    xl_skiphidden => 1,
                    xl_ignorecase => 1,
                    xl_vtbl =>
                            {TESTV => 
                                {
                                    sheetName => 'TEST',
                                    ttlRow    => 0,
                                    startCol  => 1,
                                    colCnt    => 3,
                                    datRow    => 1,
                                    datLmt    => 2,
                                }
                            }
                    });
print<<"----";
#--------------------------------------------------------------
# 1. SELECT(with no params, skip hiddedn)
#--------------------------------------------------------------
----
$hSt = $hDbSI->prepare(q/SELECT * FROM test/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 2. SELECT(vtbl, skip hidden)
#--------------------------------------------------------------
----
$hSt = $hDbSI->prepare(q/SELECT * FROM testv/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 3. SELECT(with condition)
#--------------------------------------------------------------
----
$hSt = $hDbSI->prepare(q/SELECT naMe FROM TeSt WHERE dEPT='HIDDEN'/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
print<<"----";
#--------------------------------------------------------------
# 4. SELECT(vtbl:with condition)
#--------------------------------------------------------------
----
$hSt = $hDbSI->prepare(q/SELECT name FROM tEst WHERE NamE <> 'Emp2'/);
$hSt->execute();
$raName = $hSt->{NAME_uc};
print join "\t", @$raName, "\n";
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print join ("\t", @$raRes), "\n";
}
