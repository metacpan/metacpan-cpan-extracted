use strict;
#%%%%% main ====================================================================
use DBI;
my $hDb = DBI->connect('dbi:TemplateSS:', '', '', 
        {RaiseError=>1, AutoCommit=> 1,
            tmplss_func_ => {
                connect     => \&connect,
                prepare     => \&prepare,
                commit      => \&commit,
                rollback    => \&rollback,
                finish      => \&finish,

                open_table  => \&open_table,
                seek        => \&seek,
                fetch_row   => \&fetch_row,
                push_row    => \&push_row,
                truncate    => \&truncate,
                drop        => \&drop,

                table_info    => \&table_info,
                funcs       => {
                    save_files => \&save_files
                },
            },
        }
    ) or die "Can't connect $DBI::errstr";

print "-->>Data Source\n";
my @aDs = DBI->data_sources('TemplateSS', 
            { tmplss_datasources  => \&datasources, });
print join("\n", @aDs), "\n";

print "-->>Table Info\n";
my $sth = $hDb->table_info('', '', '');
while(my $raD = $sth->fetchrow_arrayref()) {
    print join(':', map{ $_||=''} @$raD), "\n";
}

print "-- ALL Rows --\n";
my $hSt = $hDb->prepare('SELECT * FROM ANYFMT');
$hSt->execute(); 
while(my $raD = $hSt->fetchrow_arrayref()) {
    print join(':', @$raD), "\n";
}
print "---Where ----\n";
$hSt = $hDb->prepare('SELECT NAME FROM ANYFMT WHERE name like ?');
$hSt->execute('%o');
while(my $raD = $hSt->fetchrow_arrayref()) {
    print join(':', @$raD), "\n";
}
$hSt = $hDb->prepare('INSERT INTO ANYFMT VALUES (?, ?, ?, ?)');
$hSt->execute('Matui,Gojira', 'Tokyo', 'Right', 28);
$hDb->do(q/UPDATE ANYFMT SET team='Kyoto' WHERE NAME = 'Nakama,Nori'/);
$hDb->do(q/DELETE FROM ANYFMT WHERE age >=40/);

print "--ALL Rows(order by age)--\n";
$hSt = $hDb->prepare('SELECT * FROM ANYFMT ORDER BY AGE');
$hSt->execute(); 
while(my $raD = $hSt->fetchrow_arrayref()) {
    print join(':', @$raD), "\n";
}
$hDb->disconnect;

#%%%%% DRH(datasources) ========================================================
sub datasources($) {
    my ($drh) = @_;
#1. Open specified directry
    opendir(DIR, '.') or 
        die DBI::set_err($drh, 1, "Cannot open directory '.'");
    my @aDsns = grep { ($_ ne '.') and  ($_ ne '..') and  (-d $_) } readdir(DIR);
    closedir DIR;
    return ('', @aDsns);
}
#%%%%% DRH/DBH ================================================================
#>>>>> connect -----------------------------------------------------------------
sub connect($$) {
    my ($drh, $dbh) = @_;
    $dbh->{tmplss_data_pool_}={};
}
#%%%%% DBH =====================================================================
#>>>>> prepare, commit, rollback -----------------------------------------------
sub prepare($$$$) { my($dbh, $sth, $sStmt, $rhAttr) = @_; return ; }
sub commit($)     { my($dbh) = @_; }
sub rollback($)   { my($dbh) = @_; }

#>>>>> table_info --------------------------------------------------------------
sub table_info($) {
    my($dbh) = @_;
    my @aTables;
#1. Open specified directry
    my $sDir = ($dbh->FETCH('tmplss_dir')) ? $dbh->FETCH('tmplss_dir') : '.';
    if (!opendir(DIR, $sDir)) {
        DBI::set_err($dbh, 1, "Cannot open directory $sDir");
        return undef;
    }
#2. Check and push it array
    my $sFile;
    while (defined($sFile = readdir(DIR))) {
        next if($sFile !~/\.sfm$/i);
        my $sFullPath = "$sDir/$sFile";
        if (-f $sFullPath) {
            my $sF = $sFile;
            $sF =~ s/\.sfm$//;
            push(@aTables, [undef, undef, $sF, 'TABLE', 'Some Format']);
        }
    }
    return (\@aTables, 
            ['TABLE_QUALIFIER', 'TABLE_OWNER', 'TABLE_NAME', 
             'TABLE_TYPE', 'REMARKS']);
}
#%%%%% STH =====================================================================
#>>>>> finish ------------------------------------------------------------------
sub finish($)     { my($sth) = @_; }
#%%%%% STH/Statement ===========================================================
#>>>>> open_table --------------------------------------------------------------
sub open_table($$$$) {
    my ($sth, $sTable, $bCreMode, $lockMode) = @_;

#0. Init
    my $rhData = $sth->{Database}->FETCH('tmplss_data_pool_');
    my $sDir   = $sth->{Database}->FETCH('tmplss_dir') || '.';
#1. Create Mode
    if ($bCreMode) {
        die "$sDir/$sTable.sfm Already exists" if(-e "$sDir/$sTable.sfm");
    #1.2 create table object(DBD::TemplateSS::Table)
        $rhData->{$sTable} = 
            { tmplss_rows   => [], col_nums  => {}, col_names => [], };
    }
    else {
    # 1.2.3 open "$sTable.sfm"
        unless(exists $rhData->{$sTable}) {
            die "$sDir/$sTable.sfm not exists" unless (-f "$sDir/$sTable.sfm");
            open(IN, "<$sDir/$sTable.sfm") || die "Can't open table $sTable.sfm";
            my @aRows=();
            while(my $sRec = <IN>) {
                chomp $sRec;
                if($sRec =~ /^(.{20})(.*)\t(.*)$/) {
                    my ($sCol1, $sCol2_3, $sCol4) = ($1, $2, $3);
                    $sCol1 =~ s/\s+$//;
                    my ($sCol2, $sCol3) = split /,/, $sCol2_3;
                    push @aRows, [$sCol1, $sCol2, $sCol3, $sCol4];
                }
            }
            close IN;
            my @aColName =();
            my %hColName =();
            $rhData->{$sTable} = {
                col_nums    => \%hColName, 
                col_names   => \@aColName,
                tmplss_rows   => \@aRows,
            };

            my $raNames = ['name', 'team', 'position', 'age'];
            map { $_ = uc($_) } @$raNames if($DBD::TemplateSS::DBD_IGNORECASE);
            $DBD::TemplateSS::DBD_IGNORECASE+=0;
            my $sWk;
            for(my $i = 0; $i<=$#$raNames; $i++) {
                $sWk = $raNames->[$i];
                push @aColName, $sWk;
                $hColName{$sWk} = $i;
            }
        }
    }
    my $rhItem = $rhData->{$sTable};
    $rhItem->{tmplss_table}         = $sTable;
    $rhItem->{tmplss_currow}        = 0;
    return $rhItem;
}

#%%%%% table ===================================================================
#>>>>> seek --------------------------------------------------------------------
sub seek($$$$){
    my ($oTbl, $sth, $iPos, $iWhence) = @_;
    my $iRow = $oTbl->{tmplss_currow};
    if    ($iWhence == 0){ $iRow = $iPos;  } 
    elsif ($iWhence == 1){ $iRow += $iPos; } 
    elsif ($iWhence == 2){ $iRow = $#{$oTbl->{tmplss_rows}} + 1; } # last of data
    $oTbl->{tmplss_currow} = $iRow if($iRow >=0 );
    return $iRow;
}
#>>>>> fetch_row ---------------------------------------------------------------
sub fetch_row($$){
    my ($oTbl, $sth) = @_;
    my $raItem = $oTbl->{tmplss_rows};
    my $raRow = undef;
    if($oTbl->{tmplss_currow} <= $#{$raItem}) {
        $raRow = $raItem->[$oTbl->{tmplss_currow}];
        ++$oTbl->{tmplss_currow};
    }
    return $raRow;
}
#>>>>> push_row ----------------------------------------------------------------
sub push_row($$$){
    my($oTbl, $sth, $raFields) = @_;
    my $raData = $oTbl->{tmplss_rows};
    $raData->[$oTbl->{tmplss_currow}] = $raFields;
    ++$oTbl->{tmplss_currow};
}
#>>>>> truncate ----------------------------------------------------------------
sub truncate($$){
    my($oTbl, $sth) = @_;
    $#{$oTbl->{tmplss_rows}} = $oTbl->{tmplss_currow}-1;
}
#>>>>> drop --------------------------------------------------------------------
sub drop($$) {
    my($oTbl, $sth) = @_;
    my $sDir   = $sth->{Database}->FETCH('tmplss_dir') || '.';
    my $sTable = $oTbl->{tmplss_table};
    unlink "$sDir/$sTable.sfm";
}
