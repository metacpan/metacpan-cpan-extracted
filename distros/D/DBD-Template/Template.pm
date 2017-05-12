#!perl
#===============================================================================
#   DBD::Template - A sample class for DBI
#   This module is Copyright (C) 2002 Kawai,Takanori (Hippo2000) Japan
#   All rights reserved.
#===============================================================================
require 5.004;
use strict;
#%%%% DBD::Template =================================================================
package DBD::Template;  #<< Change
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
#>>>>> driver (DBD::Template) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub driver($$){
#0. already created - return it
    return $drh if $drh;
#1. not created(maybe normal case)
    my($sClass, $rhAttr) = @_;
    $sClass .= '::dr';
    $drh = DBI::_new_drh($sClass,   
        {   Name        => $sClass,
            Version     => $VERSION,
            Err         => \$DBD::Template::err,
            Errstr      => \$DBD::Template::errstr,
            State       => \$DBD::Template::sqlstate,
            Attribution => 'DBD::Template by KAWAI,Takanori',  #<< Change
        }
    );
    return $drh;
}
#%%%% DBD::Template::dr =============================================================
package DBD::Template::dr;
$DBD::Template::dr::imp_data_size = 0;
#>>>>> connect (DBD::Template::dr) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
    my @aReqF = qw(prepare execute fetch rows name);
    my @aMissing=();
    for my $sFunc (@aReqF) {
        push @aMissing, $sFunc unless(defined($dbh->{tmpl_func_}->{$sFunc}));
    }
    die "Set " . join(',', @aMissing) if(@aMissing);

    &{$dbh->{tmpl_func_}->{connect}}($drh, $dbh) 
                if(defined($dbh->{tmpl_func_}->{connect})); #<<-- Change
    return $dbh;
}
#>>>>> data_sources (DBD::Template::dr) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub data_sources ($;$) {
    my($drh, $rhAttr) = @_;
    my $sDbdName = 'Template';
    my @aDsns = ();

    @aDsns = &{$rhAttr->{tmpl_datasources}} ($drh)
        if(defined($rhAttr->{tmpl_datasources}));   #<<-- Change

    return (map {"dbi:$sDbdName:$_"} @aDsns);
}
#>>>>> disconnect_all (DBD::Template::dr) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub disconnect_all($) { }

#%%%%% DBD::Template::db =============================================================
package DBD::Template::db;
$DBD::Template::db::imp_data_size = 0;
#>>>>> prepare (DBD::Template::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub prepare {
    my($dbh, $sStmt, $rhAttr) = @_;
#1. Create blank sth
    my $sth = DBI::_new_sth($dbh, { Statement   => $sStmt, });
    return $sth unless($sth);
# 2. Init parameters and store parameter
    $sth->STORE('tmpl_params__', []);
    my $iPrm = &{$dbh->{tmpl_func_}->{prepare}}($dbh, $sth, $sStmt, $rhAttr);
    $sth->STORE('NUM_OF_PARAMS', $iPrm);
    return $sth;
}
#>>>>> commit (DBD::Template::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub commit ($) {
    my($dbh) = shift;
    &{$dbh->{tmpl_func_}->{commit}} ($dbh)
            if(defined($dbh->{tmpl_func_}->{commit}));  #-->> Change
}
#>>>>> rollback (DBD::Template::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub rollback ($) {
    my($dbh) = shift;
    &{$dbh->{tmpl_func_}->{rollback}} ($dbh)
            if(defined($dbh->{tmpl_func_}->{rollback}));    #-->> Change
    return 1;
}
#>>>>> tmpl_func_ (DBD::Template::db) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#-->>Change
sub tmpl_func($@) {
    my($dbh, @aRest) = @_;
    return unless($dbh->{tmpl_func_}->{funcs});

    my $sFunc = pop(@aRest);
    &{$dbh->{tmpl_func_}->{funcs}->{$sFunc}}($dbh, @aRest)
            if(defined($dbh->{tmpl_func_}->{funcs}->{$sFunc}));
}
#<<--Change
#>>>>> table_info (DBD::Template::db) -----------------------------------------------
sub table_info ($) {
    my($dbh) = @_;
#-->> Change 
    my ($raTables, $raName) = 
            &{$dbh->{tmpl_func_}->{table_info}}($dbh)
                        if(defined($dbh->{tmpl_func_}->{table_info}));
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
#>>>>> quote (DBD::Template::db) ----------------------------------------------------
sub quote ($$;$) {
    my($dbh, $sObj, $iType) = @_;
    return &{$dbh->{tmpl_func_}->{quote}}($dbh, $sObj, $iType)
                        if(defined($dbh->{tmpl_func_}->{quote}));   #Change

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
#>>>>> type_info_all (DBD::Template::db) --------------------------------------------
sub type_info_all ($) {
    my ($dbh) = @_;

    my $raType = &{$dbh->{tmpl_func_}->{type_info_all}}($dbh)
                        if(defined($dbh->{tmpl_func_}->{type_info_all}));   #Change
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
#>>>>> disconnect (DBD::Template::db) -----------------------------------------------
sub disconnect ($) { 
    my ($dbh) = @_;
    &{$dbh->{tmpl_func_}->{disconnect}}($dbh)
                        if(defined($dbh->{tmpl_func_}->{disconnect}));
    1;
}
#>>>>> FETCH (DBD::Template::db) ----------------------------------------------------
sub FETCH ($$) {
    my ($dbh, $sAttr) = @_;
# 1. AutoCommit
    return $dbh->{$sAttr} if ($sAttr eq 'AutoCommit');
# 2. lower cased = Driver private attributes 
    return $dbh->{$sAttr} if ($sAttr eq (lc $sAttr));
# 3. pass up to DBI to handle
    return $dbh->SUPER::FETCH($sAttr);
}
#>>>>> STORE (DBD::Template::db) ----------------------------------------------------
sub STORE ($$$) {
    my ($dbh, $sAttr, $sValue) = @_;
#1. AutoCommit
    if ($sAttr eq 'AutoCommit') {
        if(defined($dbh->{tmpl_func_}->{rollback})) {
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
#>>>>> DESTROY (DBD::Template::db) --------------------------------------------------
sub DESTROY($) {
    my($dbh) = @_;
    &{$dbh->{tmpl_func_}->{dbh_destroy}}($dbh)
                        if(defined($dbh->{tmpl_func_}->{dbh_destroy}));
}

#%%%%% DBD::Template::st ============================================================
package DBD::Template::st;
$DBD::Template::st::imp_data_size = 0;
#>>>>> bind_param (DBD::Template::st) -----------------------------------------------
sub bind_param ($$$;$) {
    my($sth, $param, $value, $attribs) = @_;
    return $sth->DBI::set_err(2, "Can't bind_param $param, too big")
        if ($param >= $sth->FETCH('NUM_OF_PARAMS'));
    $sth->{tmpl_params__}->[$param] = $value;  #<<Change (tmpl_)
    return 1;
}
#>>>>> execute (DBD::Template::st) --------------------------------------------------
sub execute($@) {
    my ($sth, @aRest) = @_;
#1. Set Parameters
#1.1 Get Parameters
    my ($raParams, @aRec);
    $raParams = (@aRest)? [@aRest] : $sth->{tmpl_params__};  #<<Change (tmpl_)
#1.2 Check Param count
    my $iParams = $sth->FETCH('NUM_OF_PARAMS');
    if ($iParams && scalar(@$raParams) != $iParams) { #CHECK FOR RIGHT # PARAMS.
        return $sth->DBI::set_err((scalar(@$raParams)-$iParams), 
                "..execute: Wrong number of bind variables (".
                (scalar(@$raParams)-$iParams)." too many!)");
    }
#2. Execute
    my($oResult, $iNumFld, $sErr) = 
        &{$sth->{Database}->{tmpl_func_}->{execute}}($sth, $raParams);
    if ($sErr) { return $sth->DBI::set_err( 1, $@); }
#3. Set NUM_OF_FIELDS
    if ($iNumFld  &&  !$sth->FETCH('NUM_OF_FIELDS')) {
        $sth->STORE('NUM_OF_FIELDS', $iNumFld);
    }
#4. AutoCommit
    $sth->{Database}->commit if($sth->{Database}->FETCH('AutoCommit'));
    return $oResult;
}
#>>>>> fetch (DBD::Template::st) ----------------------------------------------------
sub fetch ($) {
    my ($sth) = @_;

#1. get data
    my ($raDav, $bFinish, $bNotSel) = 
        &{$sth->{Database}->{tmpl_func_}->{fetch}}($sth); #<<Change (tmpl_);

    return $sth->DBI::set_err( 1, 
        "Attempt to fetch row from a Non-SELECT Statement") if ($bNotSel);

    if ($bFinish) {
        $sth->finish;
        return undef;
    }

    if ($sth->FETCH('ChopBlanks')) {
        map { $_ =~ s/\s+$//; } @$raDav;
    }
    $sth->_set_fbav($raDav);
}
*fetchrow_arrayref = \&fetch;
#>>>>> rows (DBD::Template::st) -----------------------------------------------------
sub rows ($) { 
    my($sth) = @_;
    return &{$sth->{Database}->{tmpl_func_}->{rows}}($sth); #<<Change (tmpl_)
}
#>>>>> finish (DBD::Template::st) ---------------------------------------------------
sub finish ($) {
    my ($sth) = @_;
#-->> Change (if you want)
    &{$sth->{Database}->{tmpl_func_}->{finish}}($sth)
        if(defined($sth->{Database}->{tmpl_func_}->{finish}));
#<<-- Change
    $sth->SUPER::finish();
    return 1;
}
#>>>>> FETCH (DBD::Template::st) ----------------------------------------------------
sub FETCH ($$) {
    my ($sth, $attrib) = @_;
#NAME
    return &{$sth->{Database}->{tmpl_func_}->{name}}($sth) #<<Change (tmpl_)
                if ($attrib eq 'NAME');
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
#>>>>> STORE (DBD::Template::st) ----------------------------------------------------
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
#>>>>> DESTROY (DBD::Template::st) --------------------------------------------------
sub DESTROY {
    my ($sth) = @_;
    &{$sth->{Database}->{tmpl_func_}->{sth_destroy}}($sth)
        if(defined($sth->{Database}->{tmpl_func_}->{sth_destroy}));
}
#>> Just for no warning-----------------------------------------------
$DBD::Template::dr::imp_data_size = 0;
$DBD::Template::db::imp_data_size = 0;
$DBD::Template::st::imp_data_size = 0;
*DBD::Template::st::fetchrow_arrayref = \&DBD::Template::st::fetch;
#<< Just for no warning------------------------------------------------
1;
__END__

=head1 NAME

DBD::Template -  A template/sample class for DBI drivers.

This is still B<alpha version>.

=head1 SYNOPSIS

    use DBI;
    $hDb = DBI->connect("DBI:Template:", '', '',
        {AutoCommit => 1, RaiseError=> 1,
                tmpl_func_ => {
                    connect => \&connect,
                    prepare => \&prepare,
                    execute => \&execute,
                    fetch   => \&fetch,
                    rows    => \&rows,
                    name    => \&name,
                    table_info    => \&table_info,
                },
                tmpl_your_var => 'what you want', #...
            )
        or die "Cannot connect: " . $DBI::errstr;
    $hSt = $hDb->prepare("CREATE TABLE a (id INTEGER, name CHAR(10))")
        or die "Cannot prepare: " . $hDb->errstr();
    ...
    $hDb->disconnect();

=head1 DESCRIPTION

This is still B<alpha version>.

The DBD::Template module is a DBI driver.
You can make DBD with simply define function described below;

=head1 Functions

You can/should defined these functions to make DBD.
I<required> means "You should define that function".
Please refer I<example/tmpl*.pl>, for more detail.

=head2 Driver Level

=over 4

=item datasources

=item connect

=back

=head2 Database Level

=over 4

=item prepare   I<(required)>

=item commit

=item rollback

=item table_info

=item disconnect

=item dbh_destroy

=item quote

=item type_info

=item funcs

=back

=head2 Statement Level

=over 4

=item execute   I<(required)>

=item fetch I<(required)>

=item rows  I<(required)>

=item name  I<(required)>

=item finish

=item sth_destroy

=back 

=head1 AUTHOR

Kawai Takanori (Hippo2000) kwitknr@cpan.org

=head1 SEE ALSO

DBI, DBI::DBD

=head1 COPYRIGHT

Copyright (c) 2002 KAWAI,Takanori
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
