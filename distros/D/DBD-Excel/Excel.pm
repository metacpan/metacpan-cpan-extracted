#!perl
#===============================================================================
#   DBD::Excel - A class for DBI drivers that act on Excel File
#
#   This module is Copyright (C) 2001 Kawai,Takanori (Hippo2000) Japan
#   All rights reserved.
#
#   You may distribute this module under the terms of either the GNU
#   General Public License or the Artistic License, as specified in
#   the Perl README file.
#===============================================================================
require 5.004;
use strict;
require DynaLoader;
require DBI;
require SQL::Statement;
require SQL::Eval;
require Spreadsheet::ParseExcel::SaveParser;

#===============================================================================
# DBD::Excel
#===============================================================================
package DBD::Excel;

use vars qw(@ISA $VERSION $hDr $err $errstr $sqlstate);
@ISA = qw(DynaLoader);

$VERSION = '0.06';

$err = 0;           # holds error code   for DBI::err
$errstr = "";       # holds error string for DBI::errstr
$sqlstate = "";     # holds error state  for DBI::state
$hDr = undef;       # holds driver handle once initialised

#-------------------------------------------------------------------------------
# driver (DBD::Excel)
#    create driver-handle
#-------------------------------------------------------------------------------
sub driver {
#0. already created - return it
    return $hDr if $hDr;

#1. not created(maybe normal case)
    my($sClass, $rhAttr) = @_;
    $sClass .= "::dr";
    $hDr = DBI::_new_drh($sClass,   #create as 'DBD::Excel' + '::dr'
        {
            'Name'    => 'Excel',
            'Version' => $VERSION,
            'Err'     => \$DBD::Excel::err,
            'Errstr'  => \$DBD::Excel::errstr,
            'State'   => \$DBD::Excel::sqlstate,
            'Attribution' => 'DBD::Excel by Kawai,Takanori',
        }
    );
    return $hDr;
}
#===============================================================================
# DBD::Excel::dr
#===============================================================================
package DBD::Excel::dr; 

$DBD::Excel::dr::imp_data_size = 0;

#-------------------------------------------------------------------------------
# connect (DBD::Excel::dr)
#    connect database(ie. parse specified Excel file)
#-------------------------------------------------------------------------------
sub connect($$@) {
    my($hDr, $sDbName, $sUsr, $sAuth, $rhAttr)= @_;
#1. create database-handle
    my $hDb = DBI::_new_dbh($hDr, {
        Name         => $sDbName,
        USER         => $sUsr,
        CURRENT_USER => $sUsr,
    });
#2. parse extra strings in DSN(key1=val1;key2=val2;...)
    foreach my $sItem (split(/;/, $sDbName)) {
        if ($sItem =~ /(.*?)=(.*)/) {
            $hDb->STORE($1, $2);
        }
    }
#3.check file and parse it
    return undef unless($hDb->{file});
    my $oExcel = new Spreadsheet::ParseExcel::SaveParser;
    my $oBook = $oExcel->Parse($hDb->{file}, $rhAttr->{xl_fmt});
    return undef unless defined $oBook;

    my %hTbl;
    for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
        my $oWkS = $oBook->{Worksheet}[$iSheet];
        $oWkS->{MaxCol} ||=0;
        $oWkS->{MinCol} ||=0;
#        my($raColN, $rhColN) = _getColName($oWkS, 0, $oWkS->{MinCol}, 
#                            $oWkS->{MaxCol}-$oWkS->{MinCol}+1);
        my $MaxCol = defined ($oWkS->{MaxCol}) ? $oWkS->{MaxCol} : 0;
        my $MinCol = defined ($oWkS->{MinCol}) ? $oWkS->{MinCol} : 0;
            my($raColN, $rhColN, $iColCnt) = 
                _getColName($rhAttr->{xl_ignorecase}, 
                            $rhAttr->{xl_skiphidden}, 
                            $oWkS, 0, $MinCol, $MaxCol-$MinCol+1);
=cmmt
        my $HidCols=0;
        if $rhAttr->{xl_skiphidden} {
            for (my $i = $MinCol, $HidCols = 0; $i <= $MaxCol; $i++) {
                $HidCols++ if $oWkS->{ColWidth}[$i] && $oWkS->{ColWidth}[$i] == 0;
            };
        }
=cut
        my $sTblN = ($rhAttr->{xl_ignorecase})? uc($oWkS->{Name}): $oWkS->{Name};
        $hTbl{$sTblN} = {
                    xl_t_vtbl        => undef,
                    xl_t_ttlrow      => 0,
                    xl_t_startcol    => $oWkS->{MinCol},
#                    xl_t_colcnt      => $oWkS->{MaxCol}-$oWkS->{MinCol}+1,
                    xl_t_colcnt      => $iColCnt, # $MaxCol - $MinCol - $HidCols + 1,
                    xl_t_datrow      => 1,
                    xl_t_datlmt      => undef,

                    xl_t_name        => $sTblN, 
                    xl_t_sheetno     => $iSheet,
                    xl_t_sheet       => $oWkS,
                    xl_t_currow      => 0,
                    col_nums        => $rhColN,
                    col_names       => $raColN,
            };
    }
    while(my($sKey, $rhVal)= each(%{$rhAttr->{xl_vtbl}})) {
        $sKey = uc($sKey) if($rhAttr->{xl_ignorecase});
        unless($hTbl{$rhVal->{sheetName}}) {
            if ($hDb->FETCH('Warn')) {
                warn qq/There is no "$rhVal->{sheetName}"/;
            }
            next;
        }
        my $oWkS = $hTbl{$rhVal->{sheetName}}->{xl_t_sheet};
        my($raColN, $rhColN, $iColCnt) = _getColName(
                            $rhAttr->{xl_ignorecase}, 
                            $rhAttr->{xl_skiphidden}, 
                            $oWkS, $rhVal->{ttlRow}, 
                            $rhVal->{startCol}, $rhVal->{colCnt});
        $hTbl{$sKey} = {
            xl_t_vtbl        => $sKey,
            xl_t_ttlrow      => $rhVal->{ttlRow},
            xl_t_startcol    => $rhVal->{startCol},
            xl_t_colcnt      => $iColCnt, #$rhVal->{colCnt},
            xl_t_datrow      => $rhVal->{datRow},
            xl_t_datlmt      => $rhVal->{datLmt},

            xl_t_name     => $sKey,
            xl_t_sheetno  => $hTbl{$rhVal->{sheetName}}->{xl_t_sheetno},
            xl_t_sheet    => $oWkS,
            xl_t_currow   => 0,
            col_nums     => $rhColN,
            col_names    => $raColN,
        };
    }
    $hDb->STORE('xl_tbl',    \%hTbl);
    $hDb->STORE('xl_parser', $oExcel);
    $hDb->STORE('xl_book',   $oBook);
    $hDb->STORE('xl_skiphidden', $rhAttr->{xl_skiphidden}) if $rhAttr->{xl_skiphidden};
    $hDb->STORE('xl_ignorecase', $rhAttr->{xl_ignorecase}) if $rhAttr->{xl_ignorecase};
    return $hDb;
}
#-------------------------------------------------------------------------------
# _getColName (DBD::Excel::dr)
#    internal use
#-------------------------------------------------------------------------------
sub _getColName($$$$$$) {
    my($iIgnore, $iHidden, $oWkS, $iRow, $iColS, $iColCnt) = @_;
    my $iColMax;    #MAXIAM Range of Columns (Contains HIDDEN Columns)

    my $iCntWk = 0;
    my $MaxCol = defined ($oWkS->{MaxCol}) ? $oWkS->{MaxCol} : 0;
     if(defined $iColCnt) {
        if(($iColS + $iColCnt - 1) <= $MaxCol){
            $iColMax = $iColS + $iColCnt - 1;
        }
        else{
            $iColMax = $MaxCol;
        }
    }
    else {
        $iColMax = $MaxCol;
    }
#2.2 get column name
    my (@aColName, %hColName);
    for(my $iC = $iColS; $iC <= $iColMax; $iC++) {
        next if($iHidden &&($oWkS->{ColWidth}[$iC] == 0));
        $iCntWk++;
        my $sName;
        if(defined $iRow) {
            my $oWkC = $oWkS->{Cells}[$iRow][$iC];
            $sName = (defined $oWkC && defined $oWkC->Value)?
            $oWkC->Value: "COL_${iC}_";
        }
        else {
            $sName = "COL_${iC}_";
        }
        if(grep(/^\Q$sName\E$/, @aColName)) {
            my $iCnt = grep(/^\Q$sName\E_(\d+)_$/, @aColName);
            $sName = "${sName}_${iCnt}_";
        }
        $sName = uc($sName) if($iIgnore);
        push @aColName, $sName;
        $hColName{$sName} = ($iC - $iColS);
    }
    return (\@aColName, \%hColName, $iColCnt);
}
#-------------------------------------------------------------------------------
# data_sources (DBD::Excel::dr)
#    Nothing done
#-------------------------------------------------------------------------------
sub data_sources ($;$) {
    my($hDr, $rhAttr) = @_;
#1. Open specified directry
    my $sDir = ($rhAttr and exists($rhAttr->{'xl_dir'})) ? $rhAttr->{'xl_dir'} : '.';
    if (!opendir(DIR, $sDir)) {
        DBI::set_err($hDr, 1, "Cannot open directory $sDir");
        return undef;
    }
#2. Check and push it array
    my($file, @aDsns, $sDrv);
    if ($hDr->{'ImplementorClass'} =~ /^dbd\:\:([^\:]+)\:\:/i) {
        $sDrv = $1;
    } else {
        $sDrv = 'Excel';
    }
    my $sFile;
    while (defined($sFile = readdir(DIR))) {
        next if($sFile !~/\.xls$/i);
        my $sFullPath = "$sDir/$sFile";
        if (($sFile ne '.') and  ($sFile ne '..') and  
            (-f $sFullPath)) {
            push(@aDsns, "DBI:$sDrv:file=$sFullPath");
        }
    }
    return @aDsns;
}
#-------------------------------------------------------------------------------
# disconnect_all, DESTROY (DBD::Excel::dr)
#    Nothing done
#-------------------------------------------------------------------------------
sub disconnect_all { }
sub DESTROY        { }

#===============================================================================
# DBD::Excel::db
#===============================================================================
package DBD::Excel::db; 

$DBD::Excel::db::imp_data_size = 0;
#-------------------------------------------------------------------------------
# prepare (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub prepare ($$;@) {
    my($hDb, $sStmt, @aAttr)= @_;

# 1. create a 'blank' dbh
    my $hSt = DBI::_new_sth($hDb, {'Statement' => $sStmt});

# 2. set attributes
    if ($hSt) {
        $@ = '';
        my $sClass = $hSt->FETCH('ImplementorClass');
# 3. create DBD::Excel::Statement
        $sClass =~ s/::st$/::Statement/;
        my($oStmt) = eval { $sClass->new($sStmt) };
    #3.1 error
        if ($@) {
            DBI::set_err($hDb, 1, $@);
            undef $hSt;
        } 
    #3.2 succeed
        else {
            $hSt->STORE('xl_stmt', $oStmt);
            $hSt->STORE('xl_params', []);
            $hSt->STORE('NUM_OF_PARAMS', scalar($oStmt->params()));
        }
    }
    return $hSt;
}

#-------------------------------------------------------------------------------
# disconnect (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub disconnect ($) { 1; }
#-------------------------------------------------------------------------------
# FETCH (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub FETCH ($$) {
    my ($hDb, $sAttr) = @_;
#1. AutoCommit always 1
    if ($sAttr eq 'AutoCommit') {
        return 1;
    } 
#2. Driver private attributes are lower cased
    elsif ($sAttr eq (lc $sAttr)) {
        return $hDb->{$sAttr};
    }
#3. pass up to DBI to handle
    return $hDb->DBD::_::db::FETCH($sAttr);
}
#-------------------------------------------------------------------------------
# STORE (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub STORE ($$$) {
    my ($hDb, $sAttr, $sValue) = @_;
#1. AutoCommit always 1
    if ($sAttr eq 'AutoCommit') {
        return 1 if $sValue; # is already set
        die("Can't disable AutoCommit");
    } 
#2. Driver private attributes are lower cased
    elsif ($sAttr eq (lc $sAttr)) {
        $hDb->{$sAttr} = $sValue;
        return 1;
    }
#3. pass up to DBI to handle
    return $hDb->DBD::_::db::STORE($sAttr, $sValue);
}
#-------------------------------------------------------------------------------
# DESTROY (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub DESTROY ($) {
    my($oThis) = @_;
#1. Save as Excel faile
#    $oThis->{xl_parser}->SaveAs($oThis->{xl_book}, $oThis->{file});
    undef;
}

#-------------------------------------------------------------------------------
# type_info_all (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub type_info_all ($) {
    [
         {   TYPE_NAME         => 0,
             DATA_TYPE         => 1,
             PRECISION         => 2,
             LITERAL_PREFIX    => 3,
             LITERAL_SUFFIX    => 4,
             CREATE_PARAMS     => 5,
             NULLABLE          => 6,
             CASE_SENSITIVE    => 7,
             SEARCHABLE        => 8,
             UNSIGNED_ATTRIBUTE=> 9,
             MONEY             => 10,
             AUTO_INCREMENT    => 11,
             LOCAL_TYPE_NAME   => 12,
             MINIMUM_SCALE     => 13,
             MAXIMUM_SCALE     => 14,
         },
         [ 'VARCHAR', DBI::SQL_VARCHAR(),
           undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
           ],
         [ 'CHAR', DBI::SQL_CHAR(),
           undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
           ],
         [ 'INTEGER', DBI::SQL_INTEGER(),
           undef,  "", "", undef,0, 0,1,0,0,0,undef,0,  0
           ],
         [ 'REAL', DBI::SQL_REAL(),
           undef,  "", "", undef,0, 0,1,0,0,0,undef,0,  0
           ],
#        [ 'BLOB', DBI::SQL_LONGVARBINARY(),
#          undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
#          ],
#        [ 'BLOB', DBI::SQL_LONGVARBINARY(),
#          undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
#          ],
#        [ 'TEXT', DBI::SQL_LONGVARCHAR(),
#          undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
#          ]
     ]
}
#-------------------------------------------------------------------------------
# table_info (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub table_info ($) {
    my($hDb) = @_;

#1. get table names from Excel
    my @aTables;
    my $rhTbl = $hDb->FETCH('xl_tbl');
    while(my($sTbl, $rhVal) = each(%$rhTbl)) {
        my $sKind = ($rhVal->{xl_t_vtbl})? 'VTBL' : 'TABLE';
        push(@aTables, [undef, undef, $sTbl, $sKind, undef]);
        
    }
    my $raNames = ['TABLE_QUALIFIER', 'TABLE_OWNER', 'TABLE_NAME',
                     'TABLE_TYPE', 'REMARKS'];

#2. create DBD::Sponge driver
    my $hDb2 = $hDb->{'_sponge_driver'};
    if (!$hDb2) {
        $hDb2 = $hDb->{'_sponge_driver'} = DBI->connect("DBI:Sponge:");
        if (!$hDb2) {
            DBI::set_err($hDb, 1, $DBI::errstr);
            return undef;
        }
    }
    # Temporary kludge: DBD::Sponge dies if @aTables is empty. :-(
    return undef if !@aTables;

#3. assign table info to the DBD::Sponge driver
    my $hSt = $hDb2->prepare("TABLE_INFO", 
            { 'rows' => \@aTables, 'NAMES' => $raNames });
    if (!$hSt) {
        DBI::set_err($hDb, 1, $hDb2->errstr());
    }
   return  $hSt;
}

#-------------------------------------------------------------------------------
# list_tables (DBD::Excel::db)
#-------------------------------------------------------------------------------
sub list_tables ($@) {
    my($hDb) = @_;      #shift;
    my($hSt, @aTables);
#1. get table info
    if (!($hSt = $hDb->table_info())) {
        return ();
    }
#2. push them into array
    while (my $raRow = $hSt->fetchrow_arrayref()) {
        push(@aTables, $raRow->[2]);
    }
    @aTables;
}

#-------------------------------------------------------------------------------
# quote (DBD::Excel::db)
#  (same as DBD::File)
#-------------------------------------------------------------------------------
sub quote ($$;$) {
    my($oThis, $sObj, $iType) = @_;

#1.Numeric
    if (defined($iType)  &&
        ($iType == DBI::SQL_NUMERIC()   ||
         $iType == DBI::SQL_DECIMAL()   ||
         $iType == DBI::SQL_INTEGER()   ||
         $iType == DBI::SQL_SMALLINT()  ||
         $iType == DBI::SQL_FLOAT()     ||
         $iType == DBI::SQL_REAL()      ||
         $iType == DBI::SQL_DOUBLE()    ||
         $iType == DBI::TINYINT())) {
        return $sObj;
    }
#2.NULL
    return 'NULL' unless(defined $sObj);

#3. Others
    $sObj =~ s/\\/\\\\/sg;
    $sObj =~ s/\0/\\0/sg;
    $sObj =~ s/\'/\\\'/sg;
    $sObj =~ s/\n/\\n/sg;
    $sObj =~ s/\r/\\r/sg;
    "'$sObj'";
}

#-------------------------------------------------------------------------------
# commit (DBD::Excel::db)
#  (No meaning for this driver)
#-------------------------------------------------------------------------------
sub commit ($) {
    my($hDb) = shift;
    if ($hDb->FETCH('Warn')) {
#        warn("Commit ineffective while AutoCommit is on", -1);
        warn("Commit ineffective with this driver", -1);
    }
    1;
}
#-------------------------------------------------------------------------------
# rollback (DBD::Excel::db)
#  (No meaning for this driver)
#-------------------------------------------------------------------------------
sub rollback ($) {
    my($hDb) = shift;
    if ($hDb->FETCH('Warn')) {
#        warn("Rollback ineffective while AutoCommit is on", -1);
        warn("Rollback ineffective with this driver", -1);
    }
    0;
}
#-------------------------------------------------------------------------------
# save (DBD::Excel::db) private_func
#-------------------------------------------------------------------------------
sub save ($;$) {
    my($oThis, $sFile) = @_;
#1. Save as Excel file
    $sFile ||= $oThis->{file};
    $oThis->{xl_parser}->SaveAs($oThis->{xl_book}, $sFile);
    undef;
}
#===============================================================================
# DBD::Excel::st
#===============================================================================
package DBD::Excel::st;

$DBD::Excel::st::imp_data_size = 0;
#-------------------------------------------------------------------------------
# bind_param (DBD::Excel::st)
#  set bind parameters into xl_params 
#-------------------------------------------------------------------------------
sub bind_param ($$$;$) {
    my($hSt, $pNum, $val, $rhAttr) = @_;
    $hSt->{xl_params}->[$pNum-1] = $val;
    1;
}
#-------------------------------------------------------------------------------
# execute (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub execute {
    my ($hSt, @aRest) = @_;
#1. Set params
    my $params;
    if (@aRest) {
        $hSt->{xl_params} = ($params = [@aRest]);
    } 
    else {
        $params = $hSt->{xl_params};
    }
#2. execute
    my $oStmt = $hSt->{xl_stmt};
    my $oResult = eval { $oStmt->execute($hSt, $params); };
    if ($@) {
        DBI::set_err($hSt, 1, $@);
        return undef;
    }
#3. Set NUM_OF_FIELDS
    if ($oStmt->{NUM_OF_FIELDS}  &&  !$hSt->FETCH('NUM_OF_FIELDS')) {
        $hSt->STORE('NUM_OF_FIELDS', $oStmt->{'NUM_OF_FIELDS'});
    }
    return $oResult;
}
#-------------------------------------------------------------------------------
# execute (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub fetch ($) {
    my ($hSt) = @_;
#1. ref of get data
    my $raData = $hSt->{xl_stmt}->{data};
    if (!$raData  ||  ref($raData) ne 'ARRAY') {
        DBI::set_err($hSt, 1,
             "Attempt to fetch row from a Non-SELECT statement");
        return undef;
    }
#2. get data
    my $raDav = shift @$raData;
    return undef if (!$raDav);
    if ($hSt->FETCH('ChopBlanks')) {
        map { $_ =~ s/\s+$//; } @$raDav;
    }
    $hSt->_set_fbav($raDav);
}
#alias
*fetchrow_arrayref = \&fetch;

#-------------------------------------------------------------------------------
# FETCH (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub FETCH ($$) {
    my ($hSt, $sAttr) = @_;

# 1.TYPE (Workaround for a bug in DBI 0.93)
    return undef if ($sAttr eq 'TYPE');

# 2. NAME
    return $hSt->FETCH('xl_stmt')->{'NAME'} if ($sAttr eq 'NAME');

# 3. NULLABLE
    if ($sAttr eq 'NULLABLE') {
        my($raName) = $hSt->FETCH('xl_stmt')->{'NAME'}; # Intentional !
        return undef unless ($raName) ;
        my @aNames = map { 1; } @$raName;
        return \@aNames;
    }
# Private driver attributes are lower cased
    elsif ($sAttr eq (lc $sAttr)) {
        return $hSt->{$sAttr};
    }
# else pass up to DBI to handle
    return $hSt->DBD::_::st::FETCH($sAttr);
}
#-------------------------------------------------------------------------------
# STORE (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub STORE ($$$) {
    my ($hSt, $sAttr, $sValue) = @_;
#1. Private driver attributes are lower cased
    if ($sAttr eq (lc $sAttr)) {
        $hSt->{$sAttr} = $sValue;
        return 1;
    }
#2. else pass up to DBI to handle
    return $hSt->DBD::_::st::STORE($sAttr, $sValue);
}
#-------------------------------------------------------------------------------
# DESTROY (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub DESTROY ($) {
    undef;
}
#-------------------------------------------------------------------------------
# rows (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub rows ($) { shift->{xl_stmt}->{NUM_OF_ROWS} };
#-------------------------------------------------------------------------------
# finish (DBD::Excel::st)
#-------------------------------------------------------------------------------
sub finish ($) { 1; }

#===============================================================================
# DBD::Excel::Statement
#===============================================================================
package DBD::Excel::Statement;

@DBD::Excel::Statement::ISA = qw(SQL::Statement);
#-------------------------------------------------------------------------------
# open_table (DBD::Excel::Statement)
#-------------------------------------------------------------------------------
sub open_table ($$$$$) {
    my($oThis, $oData, $sTable, $createMode, $lockMode) = @_;

#0. Init
    my $rhTbl = $oData->{Database}->FETCH('xl_tbl');
#1. Create Mode
    $sTable = uc($sTable) if($oData->{Database}->FETCH('xl_ignorecase'));
    if ($createMode) {
        if(defined $rhTbl->{$sTable}) {
            die "Cannot create table $sTable : Already exists";
        }
#1.2 create table object(DBD::Excel::Table)
        my @aColName;
        my %hColName;
        $rhTbl->{$sTable} = {
                    xl_t_vtbl        => undef,
                    xl_t_ttlrow      => 0,
                    xl_t_startcol    => 0,
                    xl_t_colcnt      => 0,
                    xl_t_datrow      => 1,
                    xl_t_datlmt      => undef,

                    xl_t_name        => $sTable,
                    xl_t_sheetno     => undef,
                    xl_t_sheet       => undef,
                    xl_t_currow  => 0,
                    col_nums  => \%hColName,
                    col_names => \@aColName,
        };
    }
    else {
        return undef unless(defined $rhTbl->{$sTable});
    }
    my $rhItem = $rhTbl->{$sTable};
    $rhItem->{xl_t_currow}=0;
    $rhItem->{xl_t_database} = $oData->{Database};
    my $sClass = ref($oThis);
    $sClass =~ s/::Statement/::Table/;
    bless($rhItem, $sClass);
    return $rhItem;
}

#===============================================================================
# DBD::Excel::Table
#===============================================================================
package DBD::Excel::Table;

@DBD::Excel::Table::ISA = qw(SQL::Eval::Table);
#-------------------------------------------------------------------------------
# column_num (DBD::Excel::Statement)
#   Called with "SELECT ... FETCH"
#-------------------------------------------------------------------------------
sub column_num($$) {
    my($oThis, $sCol) =@_;
    $sCol = uc($sCol) if($oThis->{xl_t_database}->FETCH('xl_ignorecase'));
    return $oThis->SUPER::column_num($sCol);
}
#-------------------------------------------------------------------------------
# column(DBD::Excel::Statement)
#   Called with "SELECT ... FETCH"
#-------------------------------------------------------------------------------
sub column($$;$) {
    my($oThis, $sCol, $sVal) =@_;
    $sCol = uc($sCol) if($oThis->{xl_t_database}->FETCH('xl_ignorecase'));
    if(defined $sVal) {
        return $oThis->SUPER::column($sCol, $sVal);
    }
    else {
        return $oThis->SUPER::column($sCol);
    }
}
#-------------------------------------------------------------------------------
# fetch_row (DBD::Excel::Statement)
#   Called with "SELECT ... FETCH"
#-------------------------------------------------------------------------------
sub fetch_row ($$$) {
    my($oThis, $oData, $row) = @_;

    my $skip_hidden = 0;
    $skip_hidden = $oData->{Database}->FETCH('xl_skiphidden') if
    $oData->{Database}->FETCH('xl_skiphidden');

#1. count up currentrow
    my $HidRows = 0;
    if($skip_hidden) {
        for (my $i = $oThis->{xl_t_sheet}->{MinRow}; $i <= $oThis->{xl_t_sheet}->{MaxRow}; $i++) {
            $HidRows++ if $oThis->{xl_t_sheet}->{RowHeight}[$i] == 0;
        };
    }

    my $iRMax = (defined $oThis->{xl_t_datlmt})? 
                    $oThis->{xl_t_datlmt} : 
                    ($oThis->{xl_t_sheet}->{MaxRow} - $oThis->{xl_t_datrow} - $HidRows + 1);
    return undef if($oThis->{xl_t_currow} >= $iRMax);
    my $oWkS = $oThis->{xl_t_sheet};

#2. get row data
    my @aRow = ();
    my $iFlg = 0;
    my $iR = $oThis->{xl_t_currow} + $oThis->{xl_t_datrow};
    while((!defined ($oThis->{xl_t_sheet}->{RowHeight}[$iR])|| 
           $oThis->{xl_t_sheet}->{RowHeight}[$iR] == 0) && 
       $skip_hidden) { 
        ++$iR;
        ++$oThis->{xl_t_currow};
        return undef if $iRMax <= $iR - $oThis->{xl_t_datrow} - $HidRows;
    };

    for(my $iC = $oThis->{xl_t_startcol} ;
            $iC < $oThis->{xl_t_startcol}+$oThis->{xl_t_colcnt}; $iC++) {
        next if($skip_hidden &&($oWkS->{ColWidth}[$iC] == 0));
        push @aRow, (defined $oWkS->{Cells}[$iR][$iC])? 
                            $oWkS->{Cells}[$iR][$iC]->Value : undef;
        $iFlg = 1 if(defined $oWkS->{Cells}[$iR][$iC]);
    }
    return undef unless($iFlg); #No Data
    ++$oThis->{xl_t_currow};
    $oThis->{row} = (@aRow ? \@aRow : undef);
    return \@aRow;
}
#-------------------------------------------------------------------------------
# push_names (DBD::Excel::Statement)
#   Called with "CREATE TABLE"
#-------------------------------------------------------------------------------
sub push_names ($$$) {
    my($oThis, $oData, $raNames) = @_;
#1.get database handle
    my $oBook = $oData->{Database}->{xl_book};
#2.add new worksheet
    my $iWkN = $oBook->AddWorksheet($oThis->{xl_t_name});
    $oBook->{Worksheet}[$iWkN]->{MinCol}=0;
    $oBook->{Worksheet}[$iWkN]->{MaxCol}=0;

#2.1 set names
    my @aColName =();
    my %hColName =();
    for(my $i = 0; $i<=$#$raNames; $i++) {
        $oBook->AddCell($iWkN, 0, $i, $raNames->[$i], 0);
        my $sWk = ($oData->{Database}->{xl_ignorecase})? 
                    uc($raNames->[$i]) : $raNames->[$i];
        push @aColName, $sWk;
        $hColName{$sWk} = $i;
    }
    $oThis->{xl_t_colcnt}  = $#$raNames + 1;
    $oThis->{xl_t_sheetno} = $iWkN;
    $oThis->{xl_t_sheet}   = $oBook->{Worksheet}[$iWkN];
    $oThis->{col_nums}    = \%hColName;
    $oThis->{col_names}   = \@aColName;
    return 1;
}
#-------------------------------------------------------------------------------
# drop (DBD::Excel::Statement)
#   Called with "DROP TABLE"
#-------------------------------------------------------------------------------
sub drop ($$) {
    my($oThis, $oData) = @_;

    die "Cannot drop vtbl $oThis->{xl_t_vtbl} : " if(defined $oThis->{xl_t_vtbl});

#1. delete specified worksheet
    my $oBook     = $oData->{Database}->{xl_book};
    splice(@{$oBook->{Worksheet}}, $oThis->{xl_t_sheetno}, 1 );
    $oBook->{SheetCount}--;

    my $rhTbl = $oData->{Database}->FETCH('xl_tbl');

    while(my($sTbl, $rhVal) = each(%$rhTbl)) {
        $rhVal->{xl_t_sheetno}-- 
            if($rhVal->{xl_t_sheetno} > $oThis->{xl_t_sheetno});
    }
    $rhTbl->{$oThis->{xl_t_name}} = undef;

    return 1;
}
#-------------------------------------------------------------------------------
# push_row (DBD::Excel::Statement)
#   Called with "INSERT" , "DELETE" and "UPDATE"
#-------------------------------------------------------------------------------
sub push_row ($$$) {
    my($oThis, $oData, $raFields) = @_;
    if((defined $oThis->{xl_t_datlmt}) &&
                    ($oThis->{xl_t_currow} >= $oThis->{xl_t_datlmt})) {
        die "Attempt to INSERT row over limit";
        return undef ;
    }
#1. add cells at current row
    my @aFmt;
    for(my $i = 0; $i<=$#$raFields; $i++) {
        push @aFmt, 
            $oThis->{xl_t_sheet}->{Cells}[$oThis->{xl_t_datrow}][$oThis->{xl_t_startcol}+$i]->{FormatNo};
    }
    for(my $i = 0; $i<$oThis->{xl_t_colcnt}; $i++) {
        my $oFmt = $aFmt[$i];
        $oFmt ||= 0;
        my $oFld = $raFields->[$i];
        $oFld ||= '';

        $oData->{Database}->{xl_book}->AddCell(
            $oThis->{xl_t_sheetno}, 
            $oThis->{xl_t_currow} + $oThis->{xl_t_datrow}, 
            $i + $oThis->{xl_t_startcol}, 
            $oFld,
            $oFmt
            );
    }
    ++$oThis->{xl_t_currow};
    return 1;
}
#-------------------------------------------------------------------------------
# seek (DBD::Excel::Statement)
#   Called with "INSERT" , "DELETE" and "UPDATE"
#-------------------------------------------------------------------------------
sub seek ($$$$) {
    my($oThis, $oData, $iPos, $iWhence) = @_;

    my $iRow = $oThis->{xl_t_currow};
    if ($iWhence == 0) {
        $iRow = $iPos;
    } 
    elsif ($iWhence == 1) {
        $iRow += $iPos;
    } 
    elsif ($iWhence == 2) {
        my $oWkS = $oThis->{xl_t_sheet};
        my $iRowMax = (defined $oThis->{xl_t_datlmt})? 
                       $oThis->{xl_t_datlmt} : 
                       ($oWkS->{MaxRow} - $oThis->{xl_t_datrow});
        my $iR;
        for($iR = 0; $iR <= $iRowMax; $iR++) {
            my $iFlg=0; 
            for(my $iC = $oThis->{xl_t_startcol}; 
                $iC < $oThis->{xl_t_startcol} + $oThis->{xl_t_colcnt};
                $iC++) {
                if(defined $oWkS->{Cells}[$iR+$oThis->{xl_t_datrow}][$iC]) {
                    $iFlg = 1;
                    last;
                }
            }
            last unless($iFlg);
        }
        $iRow = $iR + $iPos;
    } 
    else {
        die $oThis . "->seek: Illegal whence argument ($iWhence)";
    }
    if ($iRow < 0) {
        die "Illegal row number: $iRow";
    }
    return $oThis->{xl_t_currow} = $iRow;
}
#-------------------------------------------------------------------------------
# truncate (DBD::Excel::Statement)
#   Called with "DELETE" and "UPDATE"
#-------------------------------------------------------------------------------
sub truncate ($$) {
    my($oThis, $oData) = @_;
    for(my $iC = $oThis->{xl_t_startcol}; 
        $iC < $oThis->{xl_t_startcol} + $oThis->{xl_t_colcnt}; $iC++) {
            $oThis->{xl_t_sheet}->{Cells}[$oThis->{xl_t_currow}+$oThis->{xl_t_datrow}][$iC] = undef;
    }
    $oThis->{xl_t_sheet}->{MaxRow} = $oThis->{xl_t_currow}+$oThis->{xl_t_datrow} - 1
        unless($oThis->{xl_t_vtbl});
    return 1;
}
1;

__END__

=head1 NAME

DBD::Excel -  A class for DBI drivers that act on Excel File.

This is still B<alpha version>.

=head1 SYNOPSIS

    use DBI;
    $hDb = DBI->connect("DBI:Excel:file=test.xls")
        or die "Cannot connect: " . $DBI::errstr;
    $hSt = $hDb->prepare("CREATE TABLE a (id INTEGER, name CHAR(10))")
        or die "Cannot prepare: " . $hDb->errstr();
    $hSt->execute() or die "Cannot execute: " . $hSt->errstr();
    $hSt->finish();
    $hDb->disconnect();

=head1 DESCRIPTION

This is still B<alpha version>.

The DBD::Excel module is a DBI driver.
The module is based on these modules:

=over 4

=item *
Spreadsheet::ParseExcel

reads Excel files.

=item *
Spreadsheet::WriteExcel

writes Excel files.

=item *
SQL::Statement

a simple SQL engine.

=item *
DBI

Of course. :-)

=back

This module assumes TABLE = Worksheet.
The contents of first row of each worksheet as column name.

Adding that, this module accept temporary table definition at "connect" method 
with "xl_vtbl".

ex.
    my $hDb = DBI->connect(
            "DBI:Excel:file=dbdtest.xls", undef, undef, 
                        {xl_vtbl => 
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

For more information please refer sample/tex.pl included in this distribution.

=head2 Metadata

The following attributes are handled by DBI itself and not by DBD::Excel,
thus they all work like expected:

    Active
    ActiveKids
    CachedKids
    CompatMode             (Not used)
    InactiveDestroy
    Kids
    PrintError
    RaiseError
    Warn                   (Not used)

The following DBI attributes are handled by DBD::Excel:

=over 4

=item AutoCommit

Always on

=item ChopBlanks

Works

=item NUM_OF_FIELDS

Valid after C<$hSt-E<gt>execute>

=item NUM_OF_PARAMS

Valid after C<$hSt-E<gt>prepare>

=item NAME

Valid after C<$hSt-E<gt>execute>; undef for Non-Select statements.

=item NULLABLE

Not really working, always returns an array ref of one's.
Valid after C<$hSt-E<gt>execute>; undef for Non-Select statements.

=back

These attributes and methods are not supported:

    bind_param_inout
    CursorName
    LongReadLen
    LongTruncOk

Additional to the DBI attributes, you can use the following dbh
attribute:

=over 4

=item xl_fmt

This attribute is used for setting the formatter class for parsing.

=item xl_dir

This attribute is used only with C<data_sources> on setting the directory where 
Excel files ('*.xls') are searched. It defaults to the current directory (".").

=item xl_vtbl

assumes specified area as a table.
I<See sample/tex.pl>.

=item xl_skiphidden

skip hidden rows(=row height is 0) and hidden columns(=column width is 0).
I<See sample/thidden.pl>.

=item xl_ignorecase

set casesensitive or not about table name and columns. 
Default is sensitive (maybe as SQL::Statement).
I<See sample/thidden.pl>.

=back


=head2 Driver private methods

=over 4

=item data_sources

The C<data_sources> method returns a list of '*.xls' files of the current
directory in the form "DBI:Excel:xl_dir=$dirname".

If you want to read the subdirectories of another directory, use

    my($hDr) = DBI->install_driver("Excel");
    my(@list) = $hDr->data_sources( 
                    { xl_dir => '/usr/local/xl_data' } );

=item list_tables

This method returns a list of sheet names contained in the $hDb->{file}.
Example:

    my $hDb = DBI->connect("DBI:Excel:file=test.xls");
    my @list = $hDb->func('list_tables');

=back


=head1 TODO

=over 4

=item More tests

First of all...

=item Type and Format

The current version not support date/time and text formating.

=item Joins

The current version of the module works with single table SELECT's
only, although the basic design of the SQL::Statement module allows
joins and the likes.

=back


=head1 KNOWN BUGS

=over 8

=item *

There are too many TODO things. So I can't determind what is BUG. :-)

=back

=head1 AUTHOR

Kawai Takanori (Hippo2000) kwitknr@cpan.org

  Homepage:
    http://member.nifty.ne.jp/hippo2000/            (Japanese)
    http://member.nifty.ne.jp/hippo2000/index_e.htm (English)

  Wiki:
    http://www.hippo2000.net/cgi-bin/KbWiki/KbWiki.pl  (Japanese)
    http://www.hippo2000.net/cgi-bin/KbWikiE/KbWiki.pl (English)

=head1 SEE ALSO

DBI, Spreadsheet::WriteExcel, Spreadsheet::ParseExcel, SQL::Statement


=head1 COPYRIGHT

Copyright (c) 2001 KAWAI,Takanori
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
