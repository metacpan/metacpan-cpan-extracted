use strict;
#For Not-Ascii Characterset(Japanese etc.)
use DBI;
use Spreadsheet::ParseExcel::FmtJapan2;
my $oFmtJ = Spreadsheet::ParseExcel::FmtJapan2->new( Code => 'euc');
my $hDb = DBI->connect("DBI:Excel:file=testj.xls", undef, undef, 
                        { xl_fmt => $oFmtJ,
                          xl_vtbl => 
                            {TESTJ => 
                                {
                                    sheetName => 'ÆüËÜ¸ì',
                                    ttlRow    => undef,
                                    startCol  => 0,
                                    colCnt    => 5,
                                    datRow    => 1,
                                }
                            }
                        });
my $hSt = $hDb->prepare(q/SELECT COL_1_, COL_2_ FROM TESTJ/);
$hSt->execute();
while(my $raRes = $hSt->fetchrow_arrayref()) {
    print "DATA:", join(',', @$raRes), "\n";
}
