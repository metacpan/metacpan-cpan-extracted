#!perl
#===============================================================================
#   DBD::TemplateSS - A sample class for DBI with SQL::Statement
#   This module is Copyright (C) 2002 Kawai,Takanori (Hippo2000) Japan
#   All rights reserved.
#===============================================================================
require 5.004;
use strict;
#%%%% DBD::TemplateSS =================================================================
package DBD::TemplateSS;  #<< Change
require DBI;
require SQL::Statement;
require SQL::Eval;
use vars qw($VERSION $err $errstr $sqlstate $drh);
$VERSION = '0.01';      #<< Change
$err = 0;               # holds error code   for DBI::err
$errstr =  '';          # holds error string for DBI::errstr
$sqlstate = '00000';    # holds sqlstate for DBI::sqlstate
$drh = undef;           # holds driver handle once initialised
use vars qw($DBD_IGNORECASE);
$DBD_IGNORECASE = 1;
#>>>>> driver (DBD::TemplateSS) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub driver($$){
#0. already created - return it
    return $drh if $drh;
#1. not created(maybe normal case)
    my($sClass, $rhAttr) = @_;
    $sClass .= '::dr';
    $drh = DBI::_new_drh($sClass,   
        {   Name        => $sClass,
            Version     => $VERSION,
            Err         => \$DBD::TemplateSS::err,
            Errstr      => \$DBD::TemplateSS::errstr,
            State       => \$DBD::TemplateSS::sqlstate,
            Attribution => 'DBD::TemplateSS by KAWAI,Takanori',  #<< Change
        }
    );
    return $drh;
}
#%%%% DBD::TemplateSS::dr =============================================================
package DBD::TemplateSS::dr;
$DBD::TemplateSS::dr::imp_data_size = 0;
#>>>>> connect (DBD::TemplateSS::dr) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub connect($$;$$$) {
    my($drh, $sDbName, $sUsr, $sAuth, $rhAttr)= @_;
#1. create database-handle
    my $dbh = DBI::_new_dbh($drh, {
        Name         => $sDbName,
        USER         => $sUsr,
        CURRENT_USER => $sUsr,
    });
#2. Parse extra strings in DSN(key1=val1;key2=val2;...)
    foreach my $sItem (split(/;/, $sDbName)) {
        $dbh->STORE($1, $2) if ($sItem =~ /(.*?)=(.*)/);
    }
#3. Add Extra attributes
    foreach my $sKey (keys %$rhAttr) {
        $dbh->STORE($sKey, $rhAttr->{$sKey});
    }
    $dbh->{AutoCommit}  =1;

#4. Initialize
    my @aReqF = qw(open_table seek fetch_row push_row truncate drop);
    my @aMissing=();
    for my $sFunc (@aReqF) {
        push @aMissing, $sFunc unless(defined($dbh->{tmplss_func_}->{$sFunc}));
    }
    die "Set " . join(',', @aMissing) if(@aMissing);

    &{$dbh->{tmplss_func_}->{connect}}($drh, $dbh) 
                if(defined($dbh->{tmplss_func_}->{connect})); #<<-- Change
    return $dbh;
}
#>>>>> data_sources (DBD::TemplateSS::dr) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub data_sources ($;$) {
    my($drh, $rhAttr) = @_;
    my $sDbdName = 'TemplateSS';
    my @aDsns = ();

    @aDsns = &{$rhAttr->{tmplss_datasources}} ($drh)
        if(defined($rhAttr->{tmplss_datasources}));   #<<-- Change

    return (map {"dbi:$sDbdName:$_"} @aDsns);
}
#>>>>> disconnect_all (DBD::TemplateSS::dr) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub disconnect_all($) { }

#%%%%% DBD::TemplateSS::db =============================================================
package DBD::TemplateSS::db;
$DBD::TemplateSS::db::imp_data_size = 0;
#>>>>> prepare (DBD::TemplateSS::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub prepare {
    my($dbh, $sStmt, $rhAttr) = @_;
#1. Create blank sth
    my $sth = DBI::_new_sth($dbh, { Statement   => $sStmt, });
    return $sth unless($sth);
# 2. Get Class
    my $sClass = $sth->FETCH('ImplementorClass');
    $sClass =~ s/::st$/::Statement/;
# 3. create DBD::TemplateSS::Statement
    $@ = '';
    my($oStmt) = eval { $sClass->new($sStmt) };
    if ($@) {
    #3.1 error
        return $dbh->DBI::set_err(1, $@)
    }
    else {
    #3.2 succeed
        $sth->STORE('NUM_OF_PARAMS', scalar($oStmt->params()));
        $sth->STORE('tmplss_stmt__'  , $oStmt);
        $sth->STORE('tmplss_params__', []);
        &{$dbh->{tmplss_func_}->{prepare}}($dbh, $sth, $sStmt, $rhAttr)
            if(defined($dbh->{tmplss_func_}->{prepare}));     #-->> Change
    }
    return $sth;
}
#>>>>> commit (DBD::TemplateSS::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub commit ($) {
    my($dbh) = shift;
    &{$dbh->{tmplss_func_}->{commit}} ($dbh)
            if(defined($dbh->{tmplss_func_}->{commit}));  #-->> Change
}
#>>>>> rollback (DBD::TemplateSS::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub rollback ($) {
    my($dbh) = shift;
    &{$dbh->{tmplss_func_}->{rollback}} ($dbh)
            if(defined($dbh->{tmplss_func_}->{rollback}));    #-->> Change
    return 1;
}
#>>>>> tmplss_func_ (DBD::TemplateSS::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#-->>Change
sub tmplss_func($@) {
    my($dbh, @aRest) = @_;
    return unless($dbh->{tmplss_func_}->{funcs});

    my $sFunc = pop(@aRest);
    &{$dbh->{tmplss_func_}->{funcs}->{$sFunc}}($dbh, @aRest)
            if(defined($dbh->{tmplss_func_}->{funcs}->{$sFunc}));
}
#<<--Change
#>>>>> table_info (DBD::TemplateSS::db) -----------------------------------------------
sub table_info ($) {
    my($dbh) = @_;
#-->> Change 
    my ($raTables, $raName) = 
            &{$dbh->{tmplss_func_}->{table_info}}($dbh)
                        if(defined($dbh->{tmplss_func_}->{table_info}));
#<<-- Change 
    return undef unless $raTables;
#2. create DBD::Sponge driver
    my $dbh2 = $dbh->{'_sponge_driver'};
    if (!$dbh2) {
        $dbh2 = $dbh->{'_sponge_driver'} = DBI->connect("DBI:Sponge:");
        if (!$dbh2) {
            $dbh->DBI::set_err( 1, $DBI::errstr);
            return undef;
            $DBI::errstr .= ''; #Just for IGNORE warning
        }
    }
#3. assign table info to the DBD::Sponge driver
    my $sth = $dbh2->prepare("TABLE_INFO", 
            { 'rows' => $raTables, 'NAMES' => $raName });
    if (!$sth) {
        $dbh->DBI::set_err(1, $dbh2->errstr());
    }
    return  $sth;
}
#>>>>> quote (DBD::TemplateSS::db) ----------------------------------------------------
sub quote ($$;$) {
    my($dbh, $sObj, $iType) = @_;
    return &{$dbh->{tmplss_func_}->{quote}}($dbh, $sObj, $iType)
                        if(defined($dbh->{tmplss_func_}->{quote})); #<<-- Change
#1.Numeric
    if (defined($iType)  &&
        ($iType == DBI::SQL_NUMERIC()   || $iType == DBI::SQL_DECIMAL()   ||
         $iType == DBI::SQL_INTEGER()   || $iType == DBI::SQL_SMALLINT()  ||
         $iType == DBI::SQL_FLOAT()     || $iType == DBI::SQL_REAL()      ||
         $iType == DBI::SQL_DOUBLE()    || $iType == DBI::TINYINT())) {
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
    return "'$sObj'";
}
#>>>>> type_info_all (DBD::TemplateSS::db) --------------------------------------------
sub type_info_all ($) {
    my ($dbh) = @_;
    my $raType = &{$dbh->{tmplss_func_}->{type_info_all}}($dbh)     #<<-- Change
                        if(defined($dbh->{tmplss_func_}->{type_info_all}));
    $raType ||= 
        [
            [ 'VARCHAR',                #TYPE_NAME
                DBI::SQL_VARCHAR(),     #DATA_TYPE
                undef,                  #PRECISION
                "'",                    #LITERAL_PREFIX
                "'",                    #LITERAL_SUFFIX
                undef,                  #CREATE_PARAMS
                0,                      #NULLABLE
                1,                      #CASE_SENSITIVE
                1,                      #SEARCHABLE
                0,                      #UNSIGNED_ATTRIBUTE
                0,                      #MONEY
                0,                      #AUTO_INCREMENT
                undef,                  #LOCAL_TYPE_NAME
                0,                      #MINIMUM_SCALE
                0                       #MAXIMUM_SCALE
            ],
        ];
    return [
        {   TYPE_NAME       =>  0, DATA_TYPE      =>  1, PRECISION      =>  2,
            LITERAL_PREFIX  =>  3, LITERAL_SUFFIX =>  4, CREATE_PARAMS  =>  5,
            NULLABLE        =>  6, CASE_SENSITIVE =>  7, SEARCHABLE     =>  8,
            UNSIGNED_ATTRIBUTE =>  9, MONEY       => 10, AUTO_INCREMENT => 11,
            LOCAL_TYPE_NAME => 12, MINIMUM_SCALE  => 13, MAXIMUM_SCALE  => 14,
        },
        @$raType,
    ];
}
#>>>>> disconnect (DBD::TemplateSS::db) -----------------------------------------------
sub disconnect ($) { 
    my ($dbh) = @_;
    &{$dbh->{tmplss_func_}->{disconnect}}($dbh)
                        if(defined($dbh->{tmplss_func_}->{disconnect}));
    1;
}
#>>>>> FETCH (DBD::TemplateSS::db) ----------------------------------------------------
sub FETCH ($$) {
    my ($dbh, $sAttr) = @_;
# 1. AutoCommit
    return $dbh->{$sAttr} if ($sAttr eq 'AutoCommit');
# 2. lower cased = Driver private attributes 
    return $dbh->{$sAttr} if ($sAttr eq (lc $sAttr));
# 3. pass up to DBI to handle
    return $dbh->SUPER::FETCH($sAttr);
}
#>>>>> STORE (DBD::TemplateSS::db) ----------------------------------------------------
sub STORE ($$$) {
    my ($dbh, $sAttr, $sValue) = @_;
#1. AutoCommit
    if ($sAttr eq 'AutoCommit') {
        if(defined($dbh->{tmplss_func_}->{rollback})) {
            $dbh->{$sAttr} = ($sValue)? 1: 0;
        }
        else{
    #Rollback
            warn("Can't disable AutoCommit with no rollback func", -1)
                                    unless($sValue);
            $dbh->{$sAttr} = 1;
        }
        return 1;
    } 
#2. Driver private attributes are lower cased
    elsif ($sAttr eq (lc $sAttr)) {
        $dbh->{$sAttr} = $sValue;
        return 1;
    }
#3. pass up to DBI to handle
    return $dbh->SUPER::STORE($sAttr, $sValue);
}
#>>>>> DESTROY (DBD::TemplateSS::db) --------------------------------------------------
sub DESTROY($) {
    my($dbh) = @_;
    &{$dbh->{tmplss_func_}->{dbh_destroy}}($dbh)
                        if(defined($dbh->{tmplss_func_}->{dbh_destroy}));
}

#%%%%% DBD::TemplateSS::st ============================================================
package DBD::TemplateSS::st;
$DBD::TemplateSS::st::imp_data_size = 0;

#>>>>> bind_param (DBD::TemplateSS::st) -----------------------------------------------
sub bind_param ($$$;$) {
    my($sth, $param, $value, $attribs) = @_;
    return $sth->DBI::set_err(2, "Can't bind_param $param, too big")
        if ($param >= $sth->FETCH('NUM_OF_PARAMS'));
    $sth->{tmplss_params__}->[$param] = $value;  #<<Change (tmplss_)
    return 1;
}
#>>>>> execute (DBD::TemplateSS::st) --------------------------------------------------
sub execute($@) {
    my ($sth, @aRest) = @_;
#1. Set Parameters
#1.1 Get Parameters
    my ($raParams, @aRec);
    $raParams = (@aRest)? [@aRest] : $sth->{tmplss_params__};  #<<Change (tmplss_)
#1.2 Check Param count
    my $iParams = $sth->FETCH('NUM_OF_PARAMS');
    if ($iParams && scalar(@$raParams) != $iParams) { #CHECK FOR RIGHT # PARAMS.
        return $sth->DBI::set_err((scalar(@$raParams)-$iParams), 
                "..execute: Wrong number of bind variables (".
                (scalar(@$raParams)-$iParams)." too many!)");
    }
#2. Execute
    my $oStmt = $sth->{tmplss_stmt__};
    my $oResult = eval { $oStmt->execute($sth, $raParams); };
    if ($@) {
        return $sth->DBI::set_err( 1, $@);
    }

#3. Set NUM_OF_FIELDS
    if ($oStmt->{NUM_OF_FIELDS}  &&  !$sth->FETCH('NUM_OF_FIELDS')) {
        $sth->STORE('NUM_OF_FIELDS', $oStmt->{'NUM_OF_FIELDS'});
    }
#4. AutoCommit
    $sth->{Database}->commit if($sth->{Database}->FETCH('AutoCommit'));
    return $oResult;
}
#>>>>> fetch (DBD::TemplateSS::st) ----------------------------------------------------
sub fetch ($) {
    my ($sth) = @_;
#1. ref of get data
    my $raData = $sth->{tmplss_stmt__}->{data}; #<<Change (tmplss_)
    if (!$raData  ||  ref($raData) ne 'ARRAY') {
        return $sth->DBI::set_err( 1, 
                "Attempt to fetch row from a Non-SELECT Statement");
    }
#2. get data
    my $raDav = shift @$raData;
    unless ($raDav) {
        $sth->finish;
        return undef;
    }
    if ($sth->FETCH('ChopBlanks')) {
        map { $_ =~ s/\s+$//; } @$raDav;
    }
    $sth->_set_fbav($raDav);
}
*fetchrow_arrayref = \&fetch;
#>>>>> rows (DBD::TemplateSS::st) -----------------------------------------------------
sub rows ($) { shift->{tmplss_stmt__}->{NUM_OF_ROWS} };   #<<Change tmplss_
#>>>>> finish (DBD::TemplateSS::st) ---------------------------------------------------
sub finish ($) {
    my ($sth) = @_;
#-->> Change (if you want)
    &{$sth->{Database}->{tmplss_func_}->{finish}}($sth)
        if(defined($sth->{Database}->{tmplss_func_}->{finish}));
#<<-- Change
    $sth->SUPER::finish();
    return 1;
}
#>>>>> FETCH (DBD::TemplateSS::st) ----------------------------------------------------
sub FETCH ($$) {
    my ($sth, $attrib) = @_;
#NAME
    return $sth->FETCH('tmplss_stmt__')->{'NAME'} if ($attrib eq 'NAME');
#TYPE... Statement attribute
    return [(DBI::SQL_VARCHAR()) x $sth->FETCH('NUM_OF_FIELDS')]
        if($attrib eq 'TYPE');
    return [(-1) x $sth->FETCH('NUM_OF_FIELDS')]
        if($attrib eq 'PRECISION');
    return [(undef) x $sth->FETCH('NUM_OF_FIELDS')]
        if($attrib eq 'SCALE');
    return [(1) x $sth->FETCH('NUM_OF_FIELDS')]
        if($attrib eq 'NULLABLE');
    return undef if($attrib eq 'RowInCache');
    return undef if($attrib eq 'CursorName');
# Private driver attributes are lower cased
    return $sth->{$attrib} if ($attrib eq (lc $attrib));
    return $sth->SUPER::FETCH($attrib);
}
#>>>>> STORE (DBD::TemplateSS::st) ----------------------------------------------------
sub STORE ($$$) {
    my ($sth, $attrib, $value) = @_;
#1. Private driver attributes are lower cased
    if ($attrib eq (lc $attrib)) {
        $sth->{$attrib} = $value;
        return 1;
    }
    else {
        return $sth->SUPER::STORE($attrib, $value);
    }
}
#>>>>> DESTROY (DBD::TemplateSS::st) --------------------------------------------------
sub DESTROY {
    my ($sth) = @_;
    &{$sth->{Database}->{tmplss_func_}->{sth_destroy}}($sth)
        if(defined($sth->{Database}->{tmplss_func_}->{sth_destroy}));
}

#%%%%% DBD::TemplateSS::Statement =====================================================
package DBD::TemplateSS::Statement;
@DBD::TemplateSS::Statement::ISA = qw(SQL::Statement);
#>>>>> open_table (DBD::TemplateSS::Statement) ----------------------------------------
sub open_table ($$$$$) {
    my($oThis, $sth, $sTable, $bCreMode, $lockMode) = @_;
    $sTable    = uc($sTable) if($DBD::TemplateSS::DBD_IGNORECASE);

    my $rhItem = 
        &{$sth->{Database}->{tmplss_func_}->{open_table}}
                ($sth, $sTable, $bCreMode, $lockMode); #<<-- Change

    die "Set col_names" unless($rhItem->{col_names});
    my $i=0;
    foreach my $sNm (@{$rhItem->{col_names}}) {
        $rhItem->{col_nums}{$sNm} = $i++;
    }

    my $sClass = ref($oThis);
    $sClass =~ s/::Statement/::Table/;
    bless($rhItem, $sClass);
    return $rhItem;
}
#>> Just for no warning-----------------------------------------------
$DBD::TemplateSS::dr::imp_data_size = 0;
$DBD::TemplateSS::db::imp_data_size = 0;
$DBD::TemplateSS::st::imp_data_size = 0;
*DBD::TemplateSS::st::fetchrow_arrayref = \&DBD::TemplateSS::st::fetch;
#<< Just for no warning------------------------------------------------

#%%%% DBD::TemplateSS::Table ==========================================================
package DBD::TemplateSS::Table;
@DBD::TemplateSS::Table::ISA = qw(SQL::Eval::Table);
#>>>>> seek (for "INSERT" , "DELETE" and "UPDATE") -----------------------------
sub seek ($$$$) {
    my($oThis, $sth, $iPos, $iWhence) = @_;
#1. Range check
    die $oThis . "->seek: Illegal whence argument ($iWhence)" 
                    if($iWhence < 0) ||($iWhence > 2);
#-->> Change
    &{$sth->{Database}->{tmplss_func_}->{seek}} ($oThis, $sth, $iPos, $iWhence); 
#<<-- Change
}
#>>>>> fetch_row (for "SELECT ... FETCH") --------------------------------------
sub fetch_row ($$) {
    my($oThis, $sth) = @_;
#-->>Change
    $oThis->{row} = 
        &{$sth->{Database}->{tmplss_func_}->{fetch_row}}($oThis, $sth);
#<<--Change
    return $oThis->{row};
}
#>>>>> push_row (for "INSERT" , "DELETE" and "UPDATE") -------------------------
sub push_row ($$$) {
    my($oThis, $sth, $raFields) = @_;
#-->>Change
    &{$sth->{Database}->{tmplss_func_}->{push_row}} ($oThis, $sth, $raFields);
#<--Change
    return 1;
}
#>>>>> truncate (for "DELETE" and "UPDATE") ------------------------------------
sub truncate ($$) {
    my($oThis, $sth) = @_;
#-->>Change
    &{$sth->{Database}->{tmplss_func_}->{truncate}} ($oThis, $sth);
#<<--Change
    return 1;
}
#>>>>> drop  (for "DROP TABLE") ------------------------------------------------
sub drop ($$) {
    my($oThis, $sth) = @_;
#-->>Change
    &{$sth->{Database}->{tmplss_func_}->{drop}} ($oThis, $sth);
#<<--Change
    return 1;
}
#>>>>> push_names (for "CREATE TABLE") -----------------------------------------
sub push_names ($$$) {
    my($oThis, $sth, $raNames) = @_;
    map { $_ = uc($_) } @$raNames if($DBD::TemplateSS::DBD_IGNORECASE);

    my $raNm = ();
    $raNm = &{$sth->{Database}->{tmplss_func_}->{push_names}} 
            ($oThis, $sth, $raNames)
            if(defined($sth->{Database}->{tmplss_func_}->{push_names}));
    $raNm ||=$raNames;

    $oThis->{col_names}   = $raNm;
    my $i=0;
    foreach my $sNm (@$raNm) {
        $oThis->{col_nums}{$sNm} = $i++;
    }
    return 1;
}
#>>>>> column_num (for "SELECT ... FETCH")  ------------------------------------
sub column_num($$) {
    my($oThis, $sCol) =@_;
    $sCol = uc($sCol) if($DBD::TemplateSS::DBD_IGNORECASE);
    return $oThis->SUPER::column_num($sCol);
}
#>>>>> column (for "SELECT ... FETCH") -----------------------------------------
sub column($$;$) {
    my($oThis, $sCol, $sVal) =@_;
    $sCol = uc($sCol) if($DBD::TemplateSS::DBD_IGNORECASE);
    return (defined $sVal)? 
        $oThis->SUPER::column($sCol, $sVal) : $oThis->SUPER::column($sCol);
}
1;
__END__

=head1 NAME

DBD::TemplateSS -  A template/sample class for DBI drivers with SQL::Statement.

This is still B<alpha version>.

=head1 SYNOPSIS

    use DBI;
    $hDb = DBI->connect("DBI:TemplateSS:", '', '',
        {AutoCommit => 1, RaiseError=> 1,
                 tmplss_func_ => {
                    connect    => \&connect,
                    prepare => \&prepare,
                    execute => \&execute,
                    fetch   => \&fetch,
                    rows    => \&rows,
                    name    => \&name,
                    table_info    => \&table_info,
                 },
                 tmplss_your_var => 'what you want',
          )
        or die "Cannot connect: " . $DBI::errstr;
    $hSt = $hDb->prepare("CREATE TABLE a (id INTEGER, name CHAR(10))")
        or die "Cannot prepare: " . $hDb->errstr();
    ...
    $hDb->disconnect();

=head1 DESCRIPTION

This is still B<alpha version>.

The DBD::TemplateSS module is a DBI driver with SQL::Statement.
You can make DBD with simply define function described below;

=head1 Functions

You can/should defined these functions to make DBD.
I<required> means "You should define that function".
Please refer I<example/tmps*.pl>, for more detail.

=head2 Driver Level

=over 4

=item datasources

=item connect

=back

=head2 Database Level

=over 4

=item prepare

=item commit

=item rollback

=item table_info

=item disconnect

=item dbh_destroy

=item quote

=item type_info

=item funcs

=back

=head2 Statement (Handle) Level

=over 4

=item finish

=item sth_destroy

=back 

=head2 Statement (SQL::Statement) Level

=over 4

=item open_table    I<(required)>

=back 

=head2 Table (SQL::Statement) Level

=over 4

=item seek      I<(required)>

=item fetch_row I<(required)>

=item push_row  I<(required)>

=item truncate  I<(required)>

=item drop      I<(required)>

=back 

=head1 AUTHOR

Kawai Takanori (Hippo2000) kwitknr@cpan.org

=head1 SEE ALSO

DBI, DBI::DBD, SQL::Statement

=head1 COPYRIGHT

Copyright (c) 2002 KAWAI,Takanori
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
