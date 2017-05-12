use strict;
#%%%%% main ====================================================================
use DBI;
my $hDb = DBI->connect('dbi:Template:', '', '', 
        {RaiseError=>1, AutoCommit=> 1,
            tmpl_func_ => {
                connect => \&connect,
                prepare => \&prepare,
                execute => \&execute,
                fetch   => \&fetch,
                rows    => \&rows,
                name    => \&name,
                table_info    => \&table_info,
            },
        }
    ) or die "Can't connect $DBI::errstr";

print "-->>Data Source\n";
my @aDs = 
        DBI->data_sources('TemplateSS', 
            { tmplss_datasources  => \&datasources, });
print join("\n", @aDs), "\n";

print "-->>Table Info\n";
my $sth = $hDb->table_info('', '', '');
while(my $raD = $sth->fetchrow_arrayref()) {
    print join(':', map {$_||=''} @$raD), "\n";
}

print "--ALL--\n";
my $hSt = $hDb->prepare('SEL ANYFMT');
$hSt->execute();
while(my $raD = $hSt->fetchrow_arrayref()) {
    print join(':', @$raD), "\n";
}
print "---REC 2 and 1 ----\n";
$hSt = $hDb->prepare('SEL ANYFMT [2, ?]');
$hSt->execute(1);
while(my $raD = $hSt->fetchrow_arrayref()) {
    print join(':', @$raD), "\n";
}
$hSt = $hDb->prepare('INS ANYFMT [?, ?, ?, ?]');
$hSt->execute('Matui,Gojira', 'Tokyo', 'Right', 28);
$hDb->do(q/UPD ANYFMT [1, 'Nakama,Nori', 'Kyoto', 'First', 32]/);
$hDb->do(q/DEL ANYFMT [2, 1]/);

print "--ALL--\n";
$hSt = $hDb->prepare('SEL ANYFMT');
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
        return DBI::set_err($drh, 1, "Cannot open directory '.'");
    my @aDsns = grep { ($_ ne '.') and  ($_ ne '..') and  (-d $_) } readdir(DIR);
    closedir DIR;
    return ('', @aDsns);
}
#%%%%% DRH/DBH =================================================================
#>>>>> connect -----------------------------------------------------------------
sub connect($$) {
    my ($drh, $dbh) = @_;
    $dbh->{tmpl_data_pool_}={};
}
#%%%%% DBH =====================================================================
#>>>>> prepare, commit, rollback -----------------------------------------------
sub prepare($$$$) { 
    my($dbh, $sth, $sStmt, $rhAttr) = @_;
    return ($sStmt =~ tr/?//);  # bind_params
}
#>>>>> commit, rollback --------------------------------------------------------
#sub commit($)     {    my($dbh) = @_; }
#sub rollback($)   { my($dbh) = @_; }

#>>>>> table_info --------------------------------------------------------------
sub table_info($) {
    my($dbh) = @_;
    my @aTables;
#1. Open specified directry
    my $sDir = ($dbh->FETCH('tmpl_dir'));
    $sDir ||= '.';
    if (!opendir(DIR, $sDir)) {
        DBI::set_err($dbh, 1, "Cannot open directory $sDir");
        return undef;
    }
#2. Check and push it array
    my $sFile;
    while (defined($sFile = readdir(DIR))) {
#   while($sFile =glob("$sDir/*.sfm")) {
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
#>>>>> execute, fetch, rows, name, finish --------------------------------------
sub execute($$){
    my($sth, $raParam) = @_;

#1.3 Replace Placeholder with parameters
    my $sStmt = $sth->FETCH('Statement');
    foreach my $sRep (@$raParam) {
        my $sQ = $sth->{Database}->quote($sRep);
        $sStmt =~ s/\?/$sQ/;
    }

#2. Parse command
    my ($sCmd, $sFile) = ($sStmt=~/(\S+)\s+(\S+)\s*/);
    return $sth->DBI::set_err(2, "No table specified") unless(defined $sFile);

    my $sRest = $';
    my $raData;
    if($sRest) {
        $raData = eval ($sRest);
        return $sth->DBI::set_err(2, "ERROR $sRest $@") if($@);
        return $sth->DBI::set_err(2, 
                qq/You should set array ref ($sRest)/) 
        if (ref($raData) ne 'ARRAY');
    }

#2.1 Get data from file
    my $rhData = $sth->{Database}->FETCH('tmpl_sf_data_pool');
    unless(exists $rhData->{$sFile}) {
        my $sDir = $sth->FETCH('tmpl_sf_dir') || '.';
       open(IN, "<$sDir/$sFile.sfm") ||
            return $sth->DBI::set_err(2, "Can't open table $sFile");
        my @aRows=();
        $rhData->{$sFile} = \@aRows;
        $sth->{Database}->STORE('tmpl_sf_data_pool', $rhData);
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
    }
#3. Execute command
    my $iRet = -1;
    if($sCmd eq 'INS') {
        if($raData) {
            push @{$rhData->{$sFile}},  $raData;
        }
        else {
            return $sth->DBI::set_err(2, 'You should set data for INSERT') ;
        }
    }
    elsif($sCmd eq 'SEL') {
        my @aRows = @{$rhData->{$sFile}};
        @aRows = @aRows[@$raData] if($raData);
        $sth->STORE('tmpl_sf_row_data', \@aRows);
        $iRet = scalar @aRows || '0E0';
    }
    elsif($sCmd eq 'UPD') {
        if($raData) {
            my $iPos = shift @$raData;
            @{$rhData->{$sFile}}->[$iPos] = $raData;
        }
        else {
            return $sth->DBI::set_err(2, 'You should set data for UPDATE');
        }
    }
    elsif($sCmd eq 'DEL') {
        if($raData) {
            splice @{$rhData->{$sFile}}, $raData->[0], $raData->[1];
        }
        else {
            $rhData->{$sFile} = [];
        }
    }
    else{
        return $sth->DBI::set_err(2, "$sCmd is not supported");
    }
#3.3 Set NUM_OF_FIELDS
    $sth->STORE('NUM_OF_FIELDS', 4);
}
sub fetch($)  {
    my($sth) = @_;
    my $raData = $sth->FETCH('tmpl_sf_row_data');
    return (undef, 1, 1) if (!$raData  ||  ref($raData) ne 'ARRAY');
    my $raDav = shift @$raData;
    return (defined $raDav)? 
            ($raDav, undef, undef) : (undef, 1, undef);
}
sub rows($)   {
    my($sth) = @_;
    return (defined $sth->FETCH('tmpl_sf_row_data'))? 
            scalar @{$sth->FETCH('tmpl_sf_row_data')} : -1;
}
sub name($)   {
    my($sth) = @_;
    return ['name', 'addr', 'birth', 'age'];
}
sub finish($) {
    my($sth) = @_;
    $sth->{tmpl_sf_row_data}=undef;
}
