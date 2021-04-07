require 'perldutl.pl';
require 'connection.pl';

$PL = "$^X";
$cont = 0;
while($cont == 0)
{
  print "Using perl installed at: $PL. Do you want to continue(y/n)?\n";
  $cont= <STDIN>;
  chomp($cont);
  if($cont eq 'y')
  {
    $cont = 1;
  }
  elsif($cont eq 'n')
  {
    print "Exiting...\n";
    exit 0;
  }
  else
  {
    $cont=0;
  }
}

print "#####################################################\n\n";
print "Using...\n";
print "DBI: $DBI::VERSION\n";
print "DBD::DB2: $DBD::DB2::VERSION\n";
print "USERID: $USERID\n";

$len = length($PASSWORD);
print "PASSWORD: ";
for($i=0; $i<$len; $i++)
{ print "*"; }
print "\n";
print "PORT: $PORT\n";
print "HOST: $HOSTNAME\n";
print "DATABASE: $DATABASE\n";

$setup = 1;
$cleanup = 1;
$runall = 1;

while($arg = shift)
{

  if($arg eq 'nosetup')
  {
    print "'nosetup' specified, databases will not be created or dropped\n";
    $setup = 0;
    $cleanup = 0;
  }
  elsif($arg eq 'nocleanup')
  {
    print "'nocleanup' specified, databases will not be dropped\n";
    $cleanup = 0;
  }
  elsif(substr($arg,0,6) eq 'perld0')
  {
    $arg =~ s/.pl$//;
    $runall = 0;
    $tc{$arg} = 1;
  }
  else
  {
    print "Usage: perld [nosetup] [nocleanup] [testcase] [testcase]...\n\n";
    exit 0;
  }
}

###############################################################################
# Setup
###############################################################################

if($setup == 1)
{
  system("$PL perld000_createTables.pl");
}

#################################################################################
# Run testcases
#################################################################################
system("$PL perld001_connValid.pl") if ($runall || $tc{perld001_connValid});
system("$PL perld002_connInvalidDBName.pl") if ($runall || $tc{perld002_connInvalidDBName});
system("$PL perld003_connInvalidUserID.pl") if ($runall || $tc{perld003_connInvalidUserID});
system("$PL perld004_connInvalidPassword.pl") if ($runall || $tc{perld004_connInvalidPassword});
system("$PL perld005_connValidDBIEnvVars.pl") if ($runall || $tc{perld005_connValidDBIEnvVars});
system("$PL perld006_connValidDBIEnvVarsEmptyUserIDPassword.pl") if ($runall || $tc{perld006_connValidDBIEnvVarsEmptyUserIDPassword});
system("$PL perld007_connValid3ConnWithoutDiscon.pl") if ($runall || $tc{perld007_connValid3ConnWithoutDiscon});
system("$PL perld008_connValid3ConnWithDiscon.pl") if ($runall || $tc{perld008_connValid3ConnWithDiscon});
system("$PL perld009_testAutoCommintOFF.pl") if ($runall || $tc{perld009_testAutoCommintOFF});
system("$PL perld010_testAutoCommintON.pl") if ($runall || $tc{perld010_testAutoCommintON});
system("$PL perld011_testAutoCommitOFFAndCommit.pl") if ($runall || $tc{perld011_testAutoCommitOFFAndCommit});
system("$PL perld012_testAutoCommitOFFAndRollback.pl") if ($runall || $tc{perld012_testAutoCommitOFFAndRollback});
system("$PL perld013_testAutoCommitONAndRollback.pl") if ($runall || $tc{perld013_testAutoCommitONAndRollback});
system("$PL perld014_testAutoCommitONAndCommit.pl") if ($runall || $tc{perld014_testAutoCommitONAndCommit});
system("$PL perld015_resetAutoCommitMultTimes.pl") if ($runall || $tc{perld015_resetAutoCommitMultTimes});
system("$PL perld016_disconWithoutCallingFinish.pl") if ($runall || $tc{perld016_disconWithoutCallingFinish});
system("$PL perld017_disconWithAutocomOFFRollback.pl") if ($runall || $tc{perld017_disconWithAutocomOFFRollback});
system("$PL perld018_verify017RolledBack.pl") if ($runall || $tc{perld018_verify017RolledBack});
system("$PL perld019_stmtWithVendorEscape.pl") if ($runall || $tc{perld019_stmtWithVendorEscape});
system("$PL perld020_stmtWithHostVars.pl") if ($runall || $tc{perld020_stmtWithHostVars});
system("$PL perld021_stmtUpdateReturnRowsAffected.pl") if ($runall || $tc{perld021_stmtUpdateReturnRowsAffected});
system("$PL perld022_stmtRowsAffectedUnknown.pl") if ($runall || $tc{perld022_stmtRowsAffectedUnknown});
system("$PL perld023_stmtReturnsUndefOnError.pl") if ($runall || $tc{perld023_stmtReturnsUndefOnError});
system("$PL perld024_stmtWithParamMarkers.pl") if ($runall || $tc{perld024_stmtWithParamMarkers});
system("$PL perld025_stmtNumParamsNumFieldsWithoutParamMarkers.pl") if ($runall || $tc{perld025_stmtNumParamsNumFieldsWithoutParamMarkers});
system("$PL perld026_stmtNumParamsNumFieldsWithParamMarkers.pl") if ($runall || $tc{perld026_stmtNumParamsNumFieldsWithParamMarkers});
system("$PL perld027_stmtNumParamsNumFieldsOnNonSelectWithParamMarkers.pl") if ($runall || $tc{perld027_stmtNumParamsNumFieldsOnNonSelectWithParamMarkers});
system("$PL perld028_stmtCreateTableWithNonGraphicTypes.pl") if ($runall || $tc{perld028_stmtCreateTableWithNonGraphicTypes});
system("$PL perld029_stmtInsertPrepareAndExecute.pl") if ($runall || $tc{perld029_stmtInsertPrepareAndExecute});
system("$PL perld030_stmtSelectBindPrepareExecuteUsingBindCol.pl") if ($runall || $tc{perld030_stmtSelectBindPrepareExecuteUsingBindCol});
system("$PL perld031_stmtCreateTableNumberDataTypes.pl") if ($runall || $tc{perld031_stmtCreateTableNumberDataTypes});
system("$PL perld032_stmtInsertPrepareExecuteNumberDataTypes.pl") if ($runall || $tc{perld032_stmtInsertPrepareExecuteNumberDataTypes});
system("$PL perld033_stmtSelectNumberDataTypesUsingBindCol.pl") if ($runall || $tc{perld033_stmtSelectNumberDataTypesUsingBindCol});
system("$PL perld034_stmtReuseStmtHandle.pl") if ($runall || $tc{perld034_stmtReuseStmtHandle});
system("$PL perld035_stmtCreateTableBITData.pl") if ($runall || $tc{perld035_stmtCreateTableBITData});
system("$PL perld036_stmtInsertPrepareExecuteBITData.pl") if ($runall || $tc{perld036_stmtInsertPrepareExecuteBITData});
system("$PL perld037_stmtSelectBITDataUsingBindCol.pl") if ($runall || $tc{perld037_stmtSelectBITDataUsingBindCol});
system("$PL perld038_stmtCreateTableGraphicDataTypes.pl") if ($runall || $tc{perld038_stmtCreateTableGraphicDataTypes});
system("$PL perld039_stmtInsertPrepareExecuteGraphicDataTypes.pl") if ($runall || $tc{perld039_stmtInsertPrepareExecuteGraphicDataTypes});
system("$PL perld040_stmtSelectGraphicDataTypesUsingBindCol.pl") if ($runall || $tc{perld040_stmtSelectGraphicDataTypesUsingBindCol});
system("$PL perld041stmt_SelectGraphicDataTypesUsingBindColumns.pl") if ($runall || $tc{perld041stmt_SelectGraphicDataTypesUsingBindColumns});
system("$PL perld042_stmtTryFetchWithoutExecute.pl") if ($runall || $tc{perld042_stmtTryFetchWithoutExecute});
system("$PL perld043_stmtTryFetchForNonSelect.pl") if ($runall || $tc{perld043_stmtTryFetchForNonSelect});
system("$PL perld044_stmtCheckActiveAttrForStmtHandleAfterFinish.pl") if ($runall || $tc{perld044_stmtCheckActiveAttrForStmtHandleAfterFinish});
system("$PL perld045_stmtCheckActiveAttrForStmtHandleAfterFinish1.pl") if ($runall || $tc{perld045_stmtCheckActiveAttrForStmtHandleAfterFinish1});
system("$PL perld046_stmtCheckActiveAttrForStmtHandleOnError.pl") if ($runall || $tc{perld046_stmtCheckActiveAttrForStmtHandleOnError});
system("$PL perld047_stmtCompareReturnRowsResultforExecuteAndRows.pl") if ($runall || $tc{perld047_stmtCompareReturnRowsResultforExecuteAndRows});
system("$PL perld048_stmtCompareReturnRowsResultforExecuteAndRows1.pl") if ($runall || $tc{perld048_stmtCompareReturnRowsResultforExecuteAndRows1});
system("$PL perld049_stmtCompareReturnRowsResultforExecuteAndRows2.pl") if ($runall || $tc{perld049_stmtCompareReturnRowsResultforExecuteAndRows2});
system("$PL perld050_stmtExecuteReturnsUndefOnError.pl") if ($runall || $tc{perld050_stmtExecuteReturnsUndefOnError});
system("$PL perld051_verifyDBHandleOnInactiveDestroy.pl") if ($runall || $tc{perld051_verifyDBHandleOnInactiveDestroy});
system("$PL perld052_verifyCachedKidsAttr.pl") if ($runall || $tc{perld052_verifyCachedKidsAttr});
system("$PL perld053_retrieveCLOBData.pl") if ($runall || $tc{perld053_retrieveCLOBData});
system("$PL perld054_testDefaultChopBlanksSetting.pl") if ($runall || $tc{perld054_testDefaultChopBlanksSetting});
system("$PL perld055_testSetChopBlanksON.pl") if ($runall || $tc{perld055_testSetChopBlanksON.pl});
system("$PL perld056_testSetChopBlanksOFF.pl") if ($runall || $tc{perld056_testSetChopBlanksOFF});
system("$PL perld057_testChopBkanksChangedFromDBH.pl") if ($runall || $tc{perld057_testChopBkanksChangedFromDBH});
system("$PL perld058_testChangingOfChopBlanksValue.pl") if ($runall || $tc{perld058_testChangingOfChopBlanksValue});
system("$PL perld059_testChopBlanksONDuringConnect.pl") if ($runall || $tc{perld059_testChopBlanksONDuringConnect});
system("$PL perld060_pingConnWithNormalDisconnect.pl") if ($runall || $tc{perld060_pingConnWithNormalDisconnect});
system("$PL perld061_pingConnWithForceAppAll.pl") if ($runall || $tc{perld061_pingConnWithForceAppAll});
system("$PL perld062_pingConnWithdb2stop.pl") if ($runall || $tc{perld062_pingConnWithdb2stop});
system("$PL perld063_testBindParamArray.pl") if ($runall || $tc{perld063_testBindParamArray});
system("$PL perld064_testExecuteArray.pl") if ($runall || $tc{perld064_testExecuteArray});
system("$PL perld065_testBindParamArray2.pl") if ($runall || $tc{perld065_testBindParamArray2});
system("$PL perld066_testBindParamArrayWithUpdate.pl") if ($runall || $tc{perld066_testBindParamArrayWithUpdate});
system("$PL perld067_connIncorrectDBNameRemote.pl") if ($runall || $tc{perld067_connIncorrectDBNameRemote});
system("$PL perld068_connIncorrectUIDRemote.pl") if ($runall || $tc{perld068_connIncorrectUIDRemote});
system("$PL perld069_connIncorrectPassRemote.pl") if ($runall || $tc{perld069_connIncorrectPassRemote});
system("$PL perld070_connIncorrectHostRemote.pl") if ($runall || $tc{perld070_connIncorrectHostRemote});
system("$PL perld071_connIncorrectPortRemote.pl") if ($runall || $tc{perld071_connIncorrectPortRemote});
system("$PL perld072_connIncorrectProtocolRemote.pl") if ($runall || $tc{perld072_connIncorrectProtocolRemote});
system("$PL perld073_connValidRemote.pl") if ($runall || $tc{perld073_connValidRemote});
system("$PL perld074_connValidDBIEnvVarsRemote.pl") if ($runall || $tc{perld074_connValidDBIEnvVarsRemote});
system("$PL perld075_connValidStringInvalidParamsRemote.pl") if ($runall || $tc{perld075_connValidStringInvalidParamsRemote});
system("$PL perld076_connInvalidStringInvalidParamsRemote.pl") if ($runall || $tc{perld076_connInvalidStringInvalidParamsRemote});
system("$PL perld077_conn7ConnectionsRemote.pl") if ($runall || $tc{perld077_conn7ConnectionsRemote});
system("$PL perld078_testGetInfoForString.pl") if ($runall || $tc{perld078_testGetInfoForString});
system("$PL perld079_testGetInfoFor16BitInteger.pl") if ($runall || $tc{perld079_testGetInfoFor16BitInteger});
system("$PL perld080_testGetInfoFor32BitInteger.pl") if ($runall || $tc{perld080_testGetInfoFor32BitInteger});
system("$PL perld081_connWithSchema.pl") if ($runall || $tc{perld081_connWithSchema});
system("$PL perld082_connWithDefaultSchema.pl") if ($runall || $tc{perld082_connWithDefaultSchema});
system("$PL perld083_testDB2LoginTimeoutLocal.pl") if ($runall || $tc{perld083_testDB2LoginTimeoutLocal});
system("$PL perld084_testDB2LoginTimeoutRemote.pl") if ($runall || $tc{perld084_testDB2LoginTimeoutRemote});
system("$PL perld085_stmtCreateTableXMLColumn.pl") if ($runall || $tc{perld085_stmtCreateTableXMLColumn});
system("$PL perld086_stmtInsertXMLColumn.pl") if ($runall || $tc{perld086_stmtInsertXMLColumn});
system("$PL perld087_stmtSelectXMLUsingBindCol.pl") if ($runall || $tc{perld087_stmtSelectXMLUsingBindCol});
system("$PL perld088_stmtSelectXMLUsingBindColumns.pl") if ($runall || $tc{perld088_stmtSelectXMLUsingBindColumns});
system("$PL perld089_stmtRetrieveXMLUsingBLOBRead.pl") if ($runall || $tc{perld089_stmtRetrieveXMLUsingBLOBRead});
system("$PL perld090_testStoredProc.pl") if ($runall || $tc{perld090_testStoredProc.pl});
system("$PL perld_trusted_context.pl") if ($runall || $tc{perld_trusted_context});
system("$PL perld091_connAttrApplicationName.pl") if ($runall || $tc{perld091_connAttrApplicationName});
system("$PL perld092_typeDecfloat.pl") if ($runall || $tc{perld092_typeDecfloat});
system("$PL perld093_testStoredPrcMultResultset.pl") if ($runall || $tc{perld093_testStoredPrcMultResultset});
system("$PL perld094_testSQLRowCount.pl") if ($runall || $tc{perld094_testSQLRowCount});
system("$PL perld095_chopblanks_test.pl") if ($runall || $tc{perld095_chopblanks_test});
system("$PL perld_null_clob_test.pl") if ($runall || $tc{perld_null_clob_test});
system("$PL perld_test_sql_warning.pl") if ($runall || $tc{perld_test_sql_warning});

#################################################################################
# Cleanup
#################################################################################
if($cleanup)
{
  system("$PL perld000_createTables.pl unpop");
}

print "\n#####################################################\n";
