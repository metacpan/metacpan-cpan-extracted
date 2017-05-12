#
#   DBD::DtfSQLmac - A DBI driver for the dtF/SQL database engine, Macintosh edition
#
#   This module is Copyright (C) 2000-2002 by
#
#       Thomas Wegner
#
#       Email: wegner_thomas@yahoo.com
#
#   All rights reserved.
#
#   This program is free software. You can redistribute it and/or modify 
#   it under the terms of the Artistic License, distributed with Perl.
#




require 5.004;


{ # BEGIN PACKAGE
    package DBD::DtfSQLmac;

    use DBI 1.08;
    
    $DBD::DtfSQLmac::VERSION = '0.3201';

    $DBD::DtfSQLmac::err = 0;           # holds error code   for DBI::err
    $DBD::DtfSQLmac::errstr = "";       # holds error string for DBI::errstr
    $DBD::DtfSQLmac::sqlstate = "";     # holds error state  for DBI::state
    $DBD::DtfSQLmac::drh = undef;       # holds driver handle once initialised


    # Driver handle constructor. This is pretty much straight
    # from the DBD.pm doc.

    sub driver {
        return $drh if $drh;        # already created - return same one
        my($class, $attr) = @_;     
        $class .= "::dr";       
        # not a 'my' since we use it above to prevent multiple drivers
        $drh = DBI::_new_drh($class, {
              'Name'    => 'DtfSQLmac',
              'Version' => $VERSION,
              'Err'     => \$DBD::DtfSQLmac::err,
              'Errstr'  => \$DBD::DtfSQLmac::errstr,
              'State'   => \$DBD::DtfSQLmac::state,
              'Attribution' => 'DBD::DtfSQLmac $VERSION by Thomas Wegner',
        });     
        return $drh;
    }#driver


    # dtF/SQL identifiers as used in a CREATE TABLE statement mapped
    # to internal C type constants 
 
    %DBD::DtfSQLmac::Types = (
                        NULL => 0,
                        CHAR => 1,          # signed char 1 byte   *numeric, don't use quotes*
                        BYTE => 2,          # unsigned char 1 byte
                        SHORT => 3,         # signed integer 2 byte (in create table: smallint, short)
                        WORD => 4,          # unsigned integer 2 byte
                        LONG => 5,          # signed integer 4 byte (in create table: integer, long)
                        LONGWORD => 6,      # unsigned integer 4 byte
                        REAL => 8,          # floating point 8 byte
                        SHORTSTRING => 9,   # string up to 4095 chars + \0 
                        BIT => 11,          # blob
                        DATE => 13,
                        TIME => 14,
                        TIMESTAMP => 15,
                        DECIMAL => 16,                      
                        # the following are synonymous type identifiers for the corresponding type code
                        SMALLINT => 3,
                        INT => 5,
                        INTEGER => 5,
                        FLOAT => 8,
                        'DOUBLE PRECISION' => 8,
                        VARCHAR => 9,
                        'CHAR VARYING' => 9,
                        CHARACTER => 9,
                        'CHAR(' => 9,
                        # note that CHAR(1) denotes a string, while *numeric* CHAR denotes a signed byte in dtF/SQL
                        DEC => 16,
                        NUMERIC => 16,
                        );
    
    
} # END PACKAGE DBD::DtfSQLmac



#
# ============================  DRIVER ===========================
#



{ # BEGIN PACKAGE

    package DBD::DtfSQLmac::dr; # ====== DRIVER ======

    # imp_data_size, according to the DBD doc, is used by DBI and
    # should be set here. 0 is a default which means something
    # like 'no size limit imposed'.

    $DBD::DtfSQLmac::dr::imp_data_size = 0;
    use Mac::DtfSQL;                    
    use strict;
    use Carp;


    # connect to a database
    sub connect {
        my($drh, $dsn, $user, $auth, $attr) = @_;

        # check if the user has specified the optional 'dtf_commit_on_disconnect' value in the DSN
        # if not, set to default = 0 / off
        # expected syntax:  HardDisk:path:to:database;dtf_commit_on_disconnect=1   or
        #                   tcp:host/port;dtf_commit_on_disconnect=0
        #
        # Note: dtF/SQL allows only one connection at a time, so we limit the driver to one connection
        
        my ($dbname, $commit_on_disconnect) = split (/;/, $dsn, 2);
        
        my ($henv, $hcon, $htra, $err, $errstr) = (0, 0, 0, 0, ''); # avoid uninitialized warnings

        my $can_connect = 1;
        my $dbh_exists = $drh->FETCH('dtf_dbh'); # fetch the stored dbh, returns 0 if dbh does not exist 
                                                 # the first time thru 
        if ( $dbh_exists ) { # then check if active
            $can_connect = ! $dbh_exists->FETCH('Active'); # we cannot connect if connection already active
        }

        if ( $can_connect ) { 
                                                    
            # try to connect ...    
            ($henv, $hcon, $htra, $err, $errstr) = Mac::DtfSQL::dtf_connect($dbname, $user, $auth);

            # if something went wrong during connection ... 
            if ( $err ) { 
                return $drh->DBI::set_err($err, $errstr); # in fact, returns undef
            }#if
                    
        } else {
            $errstr = "ERROR(connect): Only one connection (session) is allowed at a time";
            return $drh->DBI::set_err(64, $errstr); # in fact, returns undef # Mac::DtfSQL::DTF_ERR_USER()
        }#if        

        
        # create a 'blank' dbh (call superclass constructor, see above for the constructors prototype
        # and its parameters)
    
        my $dbh = DBI::_new_dbh($drh, {
              'Name' => $dbname,
              'USER' => $user,
              'CURRENT_USER' => $user,
              });
        
        if ($dbh) { 
            # first, store a copy of $dbh as drh attribute, will be needed for disconnect_all
            $drh->STORE('dtf_dbh' => $dbh); # store value as driver attribute
            
            # reset these values in disconnect
            $dbh->STORE('Active' => 1);
            # also store the connection handles as database attributes
            $dbh->{'dtf_henv'} = $henv; 
            $dbh->{'dtf_hcon'} = $hcon;
            $dbh->{'dtf_htra'} = $htra; 
            # init an array_ref holding all dbh's statement handles
            $dbh->{'dtf_dbh_sth'} = []; 
            
            # if the user has specified the optional 'dtf_commit_on_disconnect' value ...
            if ($commit_on_disconnect) {
                if ($commit_on_disconnect =~ /dtf_commit_on_disconnect=(\d+)/ ) {
                    $dbh->STORE('dtf_commit_on_disconnect' => $1); # value must be 0 or 1, STORE checks this
                } else {
                    carp "WARN(connect): Optional attribute must be \"dtf_commit_on_disconnect=x\" with values 0 or 1. \n",
                         "# Commit at disconnect turned OFF (the default).";
                    $dbh->{'dtf_commit_on_disconnect'} = 0; #  NO auto commit at disconnect
                }#if
            } else { # no attribute specified, store default
                $dbh->{'dtf_commit_on_disconnect'} = 0; #   NO commit at disconnect
            }#if
            
        }#if
    
        return $dbh;
    }# connect

 

    # Returns a list of all data sources (databases) available via the DtfSQLmac driver. The driver will be 
    # loaded if not already. If $driver is empty or undef then the value of the DBI_DRIVER environment 
    # variable will be used. Data sources will be returned in a form suitable for passing to the connect
    # method, i.e. they will include the "dbi:$driver:" prefix

    sub data_sources {
        my $curdir = `pwd`;
        chomp $curdir;      
        
        $curdir =~ s/:$// ; # get rid of trailing ':', if any               
                            
        my $dsns_ary_ref = []; # ref to empty array
        if ( ! _check_folders($curdir, $dsns_ary_ref) ) {       
            carp "WARN(data_sources): A file system error occured while collecting the data source list.\n",
                 "# The list is probably empty or incomplete.";
        }   
        return @{$dsns_ary_ref};
    }# data_sources


    # This private sub steps recursively through a directory tree and looks for dtF/SQL database files.

    sub _check_folders {
        my ($dir, $dsns_ary_ref) = @_; # $dir comes without a trailing colon
        local (*FOLDER); # use local for filehandles

        # see perlfaq5.pod, Files and FileHandles:
        # How can I make a filehandle local to a subroutine?

        my(@subfiles, $file, $fullfile, $ftype, $fcreator);

        $dir .= ':'; # append colon; important, if dir is a volume name
        opendir(FOLDER, $dir) || return 0; # on failure, return 0
        # only file and folder names show up, no full paths
        # adding the full path is allways necessary
        @subfiles = readdir(FOLDER); 
        closedir(FOLDER);

        foreach $file (@subfiles) {
            $fullfile = $dir . $file; 
            if (-d $fullfile) { 
                _check_folders($fullfile, $dsns_ary_ref) || return 0; # RECURSION  (on failure, return 0) 
            } elsif (-f $fullfile) {
                ($fcreator, $ftype) = MacPerl::GetFileInfo($fullfile);          
                if ( ($ftype eq 'DTFD') && ($fcreator eq 'dtF=') ) {
                    # we've found a datadase
                    push (@{$dsns_ary_ref}, ('dbi:DtfSQLmac:' . $fullfile) );
                }#if
            }#if
        }#foreach
        return 1; # on success, return 1
    }#sub


    # This sub will be called by DBI's END block on shutdown to do the necessary clean up.
    # If the user hasn't disconnected the dbh via dbh->disconnect (see sub disconnect below), 
    # we will do it here.
    
    sub disconnect_all {
        my ($drh) = shift;
        
        # The dbh is stored as a driver attribute. If dbh->disconnect has already been called, 
        # the 'Active' attribute will be 0. If it is still 1, we need to call dbh->disconnect 
        # here.     
        my $dbh = $drh->FETCH('dtf_dbh'); # fetch the stored dbh, if any
        if ($dbh) {
            return 1 unless $dbh->FETCH('Active'); # don't disconnect already inactive connections
            $dbh->disconnect(); # let disconnect do the work
        }
        return 1;
    }# disconnect_all

        

    sub STORE {
        my ($drh, $attr, $value) = @_;
        
        if ($attr =~ /^dtf_/) {
            $drh->{$attr} = $value;
            return $value;
        }#if
        # call super class 
        $drh->SUPER::STORE($attr, $value);
    }# STORE
    
    
    sub FETCH {
        my ($drh, $attr) = @_;

        if ($attr =~ /^dtf_/) {
            if ( $attr eq 'dtf_dbh' ) {
                if ( !exists($drh->{$attr}) ) {
                    return 0;
                } else {
                    return $drh->{$attr};
                }#if
            } else {
                return $drh->{$attr};
            }
        }#if
        # call super class 
        $drh->SUPER::FETCH($attr);
    }# FETCH
    
    
    sub DESTROY {
        return undef;      
    }

    
} # END DRIVER PACKAGE  $DBD::DtfSQLmac::dr 



#
# ============================  DATABASE  ===========================
#


{ # BEGIN PACKAGE

    package DBD::DtfSQLmac::db; # ====== DATABASE ======

    $DBD::DtfSQLmac::db::imp_data_size = 0;
    
    use Mac::DtfSQL;
    use strict;
    use Carp;

    
    # Excerpt from DBI.pm:
    
    # prepare
    
    # Drivers for engines which don't have the concept of preparing a statement will 
    # typically just store the statement in the returned handle and process it when 
    # $sth->execute is called. Such drivers are likely to be unable to give much useful 
    # information about the statement, such as $sth->{NUM_OF_FIELDS}, until after 
    # $sth->execute has been called.
    
    # dtF/SQL is such a database, i.e. the concept of prepared statements is missing,
    # but we do the best in emulating it.
    
    
    # Prepares a statement for execution.
    sub prepare {
        my ($dbh, $statement) = @_;
       
        # create a 'blank' sth
        my $sth = DBI::_new_sth($dbh, {
             'Statement' => $statement,
           });
        
        # store all sth's that belong to a dbh
        
        my $sth_array_ref = $dbh->{'dtf_dbh_sth'}; 
        push (@{$sth_array_ref}, $sth);                     
        
        # Init bind_param attributes
        $sth->{'dtf_bind_param_values'} = [];       # this array will hold the values of the 
                                                    # binding parameters
        $sth->{'dtf_bind_param_types'} = [];        # this array will hold the parameter types
        
        $statement =~ s/'.*?'//g;   # Step 1: all quoted parts of the statement will be replaced  with the empty 
                                    # string before we count the ? placeholders  (note the minimal search)
        
        my $placeholder_count = $statement =~ tr/?//;  # Step 2: count the remaining ? placeholders
        
        $sth->STORE('NUM_OF_PARAMS', $placeholder_count);   # Number of parameters (?'s)
        $sth->STORE('ChopBlanks' => 0);                     # do not chop trailing blanks by default
        # 'LongReadLen'                                     # *not supported*
        # 'LongTruncOk'                                     # *not supported*

        return $sth;
    }
    
    # commit
    sub commit {
        my $dbh = shift;
        my $htra = $dbh->{'dtf_htra'};          
                
        if ( ($dbh->FETCH('AutoCommit')) && ($dbh->FETCH('Warn')) ) { # AutoCommit is ON, Warn is ON
            carp("Commit ineffective with AutoCommit ON.");
            return 1;
        }           
        my $sql = 'COMMIT';
        my $affectedRecords = 0;
        my $err = Mac::DtfSQL::DtfTraExecuteUpdate($htra , $sql, $affectedRecords);
        if ( $err ) {
            my $errstr = "ERROR(commit): Commit failed";
            return $dbh->DBI::set_err($err, $errstr);
        }#if        
        return 1;
    }

    # rollback
    sub rollback {
        my $dbh = shift;
        my $htra = $dbh->{'dtf_htra'};
        
        if ( ($dbh->FETCH('AutoCommit')) && ($dbh->FETCH('Warn')) ) { # AutoCommit is ON, Warn is ON
            carp("Rollback ineffective with AutoCommit ON.");
            return 1;
        }           
        my $sql = 'ROLLBACK';
        my $affectedRecords = 0;
        my $err = Mac::DtfSQL::DtfTraExecuteUpdate($htra , $sql, $affectedRecords);
        if ( $err ) {
            my $errstr = "ERROR(rollback): Rollback failed";
            return $dbh->DBI::set_err($err, $errstr);
        }#if        
        return 1;
    }


    # Confirms that this particular connection has not been closed
    # and the user is still connected.
    
    sub ping {
        my $dbh = shift;
        # If the connection isn't active, no point in pinging it.
        return 0 unless $dbh->FETCH('Active');

        my $sth = $dbh->prepare_cached(q{   SELECT * FROM ddrel WHERE 1=0
                                        }) || return 0; # ddrel is a system table
        $sth->execute || return 0;
        $sth->finish();
        return 1;
    }

          

    # Excerpt from DBI.pm:
    
    # disconnect
    
    # Disconnects the database from the database handle. Typically only used before exiting 
    # the program. The handle is of little use for the user after disconnecting.

    # The transaction behaviour of the disconnect method is, sadly, undefined.  Some database 
    # systems (such as Oracle and Ingres) will automatically commit any outstanding changes, but 
    # others (such as Informix) will rollback any outstanding changes.  Applications not using 
    # AutoCommit should explicitly call commit or rollback before calling disconnect.

    # DtfSQLmac driver:
    # With DBD::DtfSQLmac, the user is able to specify the transaction behavior on disconnect, i.e.
    # if the (auto-) commit at disconnect attribute (dtf_commit_on_disconnect) is 1, we will commit,
    # if it is 0, we will do nothing; default is 0 (OFF)

    sub disconnect {

    # Sends all neccessaray disconnect messages to the database. Any open  
    # statement and database handles will be closed.

        my $dbh = shift;
        
        my $reqClass = 0;           # request class, see below
        my $affectedRecords = 0;    # no. of affected records   
        my $err = 0;
        my $errstr = '';
        
        # Don't disconnect inactive connections.
        return 1 unless $dbh->FETCH('Active');
        
        # first, finish all active statement handles, if any
        my $sth_array_ref = $dbh->{'dtf_dbh_sth'};
        foreach my $sth ( @{$sth_array_ref} ) {
            if ( $sth->FETCH('Active') ) {
                $sth->finish(); # call the finish method
            }
        }       
        
        my $henv = $dbh->{'dtf_henv'}; 
        my $hcon = $dbh->{'dtf_hcon'};
        my $htra = $dbh->{'dtf_htra'};
        
        # before we disconnect, see if the user forced us to commit (default is no commit)
        
        if ($dbh->{'dtf_commit_on_disconnect'}) {
            my $sql = 'COMMIT';
            $err = Mac::DtfSQL::DtfTraExecuteUpdate($htra , $sql, $affectedRecords);
            if ( $err ) {
                carp ("ERROR(disconnect): Auto commit at disconnect failed.");
                # we warn and proceed
            }#if
        } #if
        # else do nothing, i.e. there is no need for an explicit rollback, dtF/SQL will "forget"
        # any changes on disconnect
        
        # disconnect ...
        ($err, $errstr) = Mac::DtfSQL::dtf_disconnect($henv, $hcon, $htra);
        if ( $err ) {
            return $dbh->DBI::set_err($err, $errstr);
        }
        
        $dbh->{'dtf_henv'} = 0; 
        $dbh->{'dtf_hcon'} = 0;
        $dbh->{'dtf_htra'} = 0;
        $dbh->{'dtf_commit_on_disconnect'} = 0; #  NO auto commit at disconnect, reset to default
        $dbh->STORE('Active' => 0); # now, this dbh is no longer active

        return 1;
    }



    sub STORE {
        my ($dbh, $attr, $value) = @_;
        
        my $err = 0;
        my $errstr = '';
        
        if ($attr =~ /^dtf_/) {
            if ($attr eq 'dtf_commit_on_disconnect') { # must be 0 or 1
                if ( ! ($value == 0 or $value == 1) ) {
                    carp "WARN(STORE): Unsupported dtf_commit_on_disconnect value $value.",
                         "\n# Commit at disconnect turned OFF (the default).";
                    # set dtf_commit_on_disconnect mode to OFF, the default
                    $value = 0;             
                }
            }
            $dbh->{$attr} = $value;
            return $value;
        }
        if ($attr eq 'AutoCommit') {    
            # the first time thru, i.e. when DBI::connect(...) sets the AutoCommit attribute to the 
            # default on, $dbh->{AutoCommit} doesn't exist; $cur_status will be 1 in this case
            my $cur_status = exists($dbh->{AutoCommit}) ? $dbh->{AutoCommit} : 1;
            ($err, $errstr, $value) = _set_AutoCommit_attr($dbh, $value, $cur_status);
            if ( $err ) {
                return $dbh->DBI::set_err($err, $errstr);
            } else {
                $dbh->{AutoCommit} = $value; 
                return $value;
            }#if            
        }
        if ($attr eq 'RowCacheSize') { # unimplemented
            return;
        }
        # pass up to super class
        $dbh->SUPER::STORE($attr, $value);

    }#STORE



    sub FETCH {
        my ($dbh, $attr) = @_;

        if ($attr =~ /^dtf_/) {
            return $dbh->{$attr};
        }
        if ($attr eq 'AutoCommit') {
            my ($err, $errstr, $value) = _get_AutoCommit_attr($dbh);
            if ( $err ) {
                return $dbh->DBI::set_err($err, $errstr);
            }#if
            return $value;
        }
        if ($attr eq 'RowCacheSize') { # unimplemented
            return undef;
        }
        # pass up to super class
        $dbh->SUPER::FETCH($attr);
    }#FETCH
    
    
    # This private method sets the AutoCommit attribute value for the current
    # transaction.
    #
    # ($err, $errstr, $value) = _set_AutoCommit_attr($dbh, $value, $ac_on);
    
    sub _set_AutoCommit_attr {
        my ($dbh, $value, $ac_on) = @_;
        my $err = 0;
        my $errstr = '';
        my $htra = $dbh->{'dtf_htra'};  # get transaction handle
        
        if ( ! ($value == 0 or $value == 1) ) {
            carp("Unsupported AutoCommit value $value. AutoCommit will be set to 1 (=> ON, the default).");
            # set AutoCommit mode to ON
            $err = Mac::DtfSQL::DtfHdlSetAttribute ($htra, Mac::DtfSQL::DTF_TAT_AUTOCOMMIT(), Mac::DtfSQL::AUTO_COMMIT_ON() );
            $value = 1;
        } else { 
            if ($value == 1) { # turn it on
                # according to the DBI spec, changing the AutoCommit attribute from off to on
                # should issue a commit (but only if not already on, this would issue a "Commit ineffective" warning)
                # first time thru, we get invoked by DBI::connect, and because we've set $ac_on to 1, we save the call to commit
                $dbh->commit() unless $ac_on;

                # set it anyway
                $err = Mac::DtfSQL::DtfHdlSetAttribute ($htra, Mac::DtfSQL::DTF_TAT_AUTOCOMMIT(), Mac::DtfSQL::AUTO_COMMIT_ON() );
            } else { # turn it off
                $err = Mac::DtfSQL::DtfHdlSetAttribute ($htra, Mac::DtfSQL::DTF_TAT_AUTOCOMMIT(), Mac::DtfSQL::AUTO_COMMIT_OFF() );
            }            
        }#if
        
        if ( $err ) { # we failed to set the attribute
            $errstr = "ERROR(_set_AutoCommit_attr): Failed to set the AutoCommit attribute";
        }

        return ($err, $errstr, $value);

    }#_set_AutoCommit_attr
    
    
    # This private method retrieves the AutoCommit attribute value from the 
    # current transaction.
    #
    # ($err, $errstr, $value) = _get_AutoCommit_attr($dbh);
    
    sub _get_AutoCommit_attr {
        my $dbh = shift;
        my $err = 0;
        my $errstr = '';
        my $false_or_true = '';
        my $htra = $dbh->{'dtf_htra'};  # get transaction handle
        
        $err = Mac::DtfSQL::DtfHdlQueryAttribute($htra, Mac::DtfSQL::DTF_TAT_AUTOCOMMIT(), $false_or_true);
        
        if ( $err ) { # we failed to get the attribute,
            $errstr = "ERROR(_get_AutoCommit_attr): Failed to get the AutoCommit attribute";
            return ($err, $errstr, 0);
        }
        # we are still here ...
        
        if ($false_or_true eq 'true') {
            return ($err, $errstr, 1); # AutoCommit ON
        } else {
            return ($err, $errstr, 0); # AutoCommit OFF
        }
    }#_get_AutoCommit_attr
    

    # According to the DBI spec, we need to call rollback and
    # disconnect here. Since dtF/SQL "forgets" any changes on
    # disconnect, there is no need to call rollback. We simply
    # call disconnect if there is still an active connection.

    sub DESTROY {
        my $dbh = shift;
        return unless $dbh->FETCH('Active');
        $dbh->disconnect(); # let disconnect do the work
        return undef;
    }#DESTROY
    


    sub type_info_all {
        [ {   
        TYPE_NAME           => 0,
        DATA_TYPE           => 1,
        COLUMN_SIZE         => 2,     # was PRECISION originally
        LITERAL_PREFIX      => 3,
        LITERAL_SUFFIX      => 4,
        CREATE_PARAMS       => 5,
        NULLABLE            => 6,
        CASE_SENSITIVE      => 7,
        SEARCHABLE          => 8,
        UNSIGNED_ATTRIBUTE  => 9,
        FIXED_PREC_SCALE    => 10,    # was MONEY originally
        AUTO_UNIQUE_VALUE   => 11,    # was AUTO_INCREMENT originally
        LOCAL_TYPE_NAME     => 12,
        MINIMUM_SCALE       => 13,
        MAXIMUM_SCALE       => 14,
        NUM_PREC_RADIX      => 15, 
        },     
        [ 'CHAR', DBI::SQL_TINYINT(), # C type code 1 | SQL type number -6
            4,  undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 # signed byte
        ],
        [ 'BYTE', DBI::SQL_TINYINT(), # C type code 2 | SQL type number -6
            3,  undef,  undef,  undef,  1,  0,  2,  1,  undef,  0,  undef,  undef,  undef,  10 # unsigned byte 
        ],
        [ 'SMALLINT', DBI::SQL_SMALLINT(), # C type code 3 | SQL type number 5
            6,  undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 # signed 2 byte
        ],     
        [ 'SHORT', DBI::SQL_SMALLINT(), # C type code 3 | SQL type number 5
            6,  undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 # signed 2 byte
        ],
        [ 'WORD', DBI::SQL_SMALLINT(), # C type code 4 | SQL type number 5
            5,  undef,  undef,  undef,  1,  0,  2,  1,  undef,  0,  undef,  undef,  undef,  10 # unsigned 2 byte
        ],     
        [ 'INTEGER', DBI::SQL_INTEGER(), # C type code 5 | SQL type number 4
            11,     undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 # signed 4 byte
        ],
        [ 'INT', DBI::SQL_INTEGER(), # C type code 5 | SQL type number 4
            11,     undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 # signed 4 byte
        ],
        [ 'LONG', DBI::SQL_INTEGER(), # C type code 5 | SQL type number 4
            11,     undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 # signed 4 byte
        ],
        [ 'LONGWORD', DBI::SQL_INTEGER(), # C type code 6 | SQL type number 4
            10,     undef,  undef,  undef,  1,  0,  2,  1,  undef,  0,  undef,  undef,  undef,  10 # unsigned 4 byte
        ],     
        [ 'REAL', DBI::SQL_DOUBLE() , # C type code 8 | SQL type number 8
            22,     undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 
        ], 
        [ 'FLOAT', DBI::SQL_DOUBLE(), # C type code 8 | SQL type number 8
            22,     undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 
        ],   
        [ 'DOUBLE PRECISION', DBI::SQL_DOUBLE(), # C type code 8 | SQL type number 8
            22,     undef,  undef,  undef,  1,  0,  2,  0,  undef,  0,  undef,  undef,  undef,  10 
        ],         
        [ 'CHAR(', DBI::SQL_CHAR(), # C type code 9 | SQL type number 1
            4095,   "'",    "'",    'max length',   1,  1,  3,  undef,  undef,  0,  undef,  undef,  undef,  undef 
        ],         
        [ 'CHARACTER', DBI::SQL_CHAR(), # C type code 9 | SQL type number 1
            4095,   "'",    "'",    'max length',   1,  1,  3,  undef,  undef,  0,  undef,  undef,  undef,  undef 
        ],
        [ 'VARCHAR', DBI::SQL_VARCHAR(), # C type code 9 | SQL type number 12
            4095,   "'",    "'",    'max length',   1,  1,  3,  undef,  undef,  0,  undef,  undef,  undef,  undef 
        ],
        [ 'CHAR VARYING', DBI::SQL_VARCHAR(), # C type code 9 | SQL type number 12
            4095,   "'",    "'",    'max length',   1,  1,  3,  undef,  undef,  0,  undef,  undef,  undef,  undef 
        ],
        [ 'SHORTSTRING', DBI::SQL_VARCHAR(), # C type code 9 | SQL type number 12
            4095,   "'",    "'",    undef,  1,  1,  3,  undef,  undef, 0,   undef,  undef,  undef,  undef 
        ],
        [ 'DATE', DBI::SQL_DATE(), # C type code 13 | SQL type number 9
            10,     "'",    "'",    undef,  1,  0,  2,  undef,  undef, 0,   undef,  undef,  undef,  undef 
        ],     
        [ 'TIME', DBI::SQL_TIME(), # C type code 14 | SQL type number 10
            12,     "'",    "'",    undef,  1,  0,  2,  undef,  undef, 0,   undef,  undef,  undef,  undef 
        ],         
        [ 'TIMESTAMP', DBI::SQL_TIMESTAMP(), # C type code 15 | SQL type number 11
            23,     "'",    "'",    undef,  1,  0,  2,  undef,  undef, 0,   undef,  undef,  undef,  undef 
        ], 
        [ 'DECIMAL', DBI::SQL_DECIMAL(), # C type code 16 | SQL type number 3
            18,     undef,  undef,  'precision, scale', 1,  0,  2,  0,  0,  0,  undef,  0,  15, 10 
        ], 
        [ 'DEC',  DBI::SQL_DECIMAL(), # C type code 16 | SQL type number 3
            18,     undef,  undef,  'precision, scale', 1,  0,  2,  0,  0,  0,  undef,  0,  15, 10 
        ], 
        [ 'NUMERIC', DBI::SQL_DECIMAL(), # C type code 16 | SQL type number 3
            18,     undef,  undef,  'precision, scale', 1,  0,  2,  0,  0,  0,  undef,  0,  15, 10 
        ],      
        ] # BINARY (blob) type not supported, SQL_BIT not defined in DBI 1.08
    }

    
        
    # Should return a list of table and view names. Views are not supported by dtF/SQL,
    # so we simply return a list of all user table names.
    
    sub tables   { 
        my $dbh = shift;                        # database handle
        my $htra = $dbh->{'dtf_htra'};          # get transaction handle
        my $hres = 0;                           # result handle
        my $reqClass;                           # request class, should be DTF_RC_RESULT_AVAILABLE, see above 
        my $affectedRecords = 0;                # rowcount  
        my $statement = 'SHOW TABLES';          # sql statement

        my $err;        # error code
        my $errstr;     # error message
        my $errgrp;     # error group
        my $errpos;     # error position within the SQL request
        
        my @tables = (); # list of table names we will return
            
        if ( ($htra != 0) && $dbh->FETCH('Active') ) {
            if ( $err = Mac::DtfSQL::DtfTraExecute($htra , $statement, $reqClass, $affectedRecords, $hres) ) # != 0 means error
            {
                #  Any errors resulted from the SQL request
                #  will be processed here.
                
                if ($hres) { # dispose the result handle
                    DtfResDestroy($hres);
                }

                if ( Mac::DtfSQL::DtfHdlGetError($htra, $err, $errstr, $errgrp, $errpos) ) # != 0 means error
                {
                    $errstr = "ERROR(tables): Can't query the transaction error";
                    return $dbh->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
                } else {
                    return $dbh->DBI::set_err($err, "ERROR(tables): " . $errstr . " (group: " .  $errgrp . ")");
                }#if
            }#if

        } else { # we are not active
            $errstr = "ERROR(tables): The connection seems to be closed";
            return $dbh->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
        
        }#if
        
        #
        # Here we have a valid result handle only if $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE(),  
        # else $hres will be NULL (0). The result table may be empty, though ($affectedRecords == 0).
        # Don't get confused by this.
        #
        
        if ( $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE() ) {      
            # We have a result table, which is a two column table, were a row/record looks like
            # <user-table name, table comment>. We are only interested in the first column.
            
            # We have a sequential cursor (by default) and will use DtfResMoveToFirstRow()  
            # and DtfResMoveToNextRow() for iterating through the result.
            
            Mac::DtfSQL::DtfResMoveToFirstRow($hres);

            for (my $row = 0; $row < $affectedRecords; $row++) {
                
                my $data_item = '';     # field data (init to avoid undef warnings)
                my $isNULL = 0;         # NULL indicator (init to avoid undef warnings)
                my $colIndex = 0;       # first column
                
                # We retrieve the column's data as string (DTF_CT_CSTRING), a type hint (last argument)
                # is not nescessary and will be set to 0
                                        
                if ( ! ( $err = Mac::DtfSQL::DtfResGetField($hres, $colIndex, Mac::DtfSQL::DTF_CT_CSTRING(), $data_item, $isNULL, 0)) ) 
                {
                    if ($isNULL) {
                        push (@tables, undef); # undef means NULL, see DBI spec
                    } else {
                        push (@tables, $data_item);
                    }#if
                } else {
                    $errstr = "ERROR(tables): Can't retrieve column data";
                    #  Do not forget to destroy the result handle.
                    Mac::DtfSQL::DtfResDestroy($hres);
                    
                    return $dbh->DBI::set_err($err, $errstr); 
                }#if

                Mac::DtfSQL::DtfResMoveToNextRow($hres);
            }#for row
            
            #  Do not forget to destroy the result handle
            #  after processing it.
            Mac::DtfSQL::DtfResDestroy($hres);
            
        }#if
        
        return @tables;

    }#tables


    # table_col_info retrieves metadata about a table's columns, i.e. for each column its name, 
    # its type (a DBI SQL type number), its type as string (as declared in CREATE TABLE), its 
    # position (starting with 0), its nullable attribute (0 or 1) and the column's comment are 
    # retrieved.
 
    # The result is returned as a hash, where the key is the column name and the value is a 
    # reference to an array holding the DBI SQL type constant , type as string, position, nullable and  
    # comment information:
 
    # %resulthash = (
    #                columnname_0 => ['DBI_type', 'type as string', 'position', 'nullable', 'comment'],
    #                ..
    #                columnname_n => ['DBI_type', 'type as string', 'position', 'nullable', 'comment'],
    # );
 
    # call it with $dbh->func($tablename, 'table_col_info');
    
    sub table_col_info   { 
        my $dbh = shift;                        # database handle
        my $tablename = shift;                  # tablename
        my $htra = $dbh->{'dtf_htra'};          # get transaction handle
        my $hres = 0;                           # result handle
        my $reqClass;                           # request class, should be DTF_RC_RESULT_AVAILABLE, see above 
        my $affectedRecords = 0;                # rowcount  
        my $columncount = 0;                    # columncount

        my $err;        # error code
        my $errstr;     # error message
        my $errgrp;     # error group
        my $errpos;     # error position within the SQL request
        
        my %resulthash = ();    # hash we will return (hash of array references)
                
        my $statement = 'SHOW COLUMNS FOR ' . $tablename;       # SQL statement
        
        if ( ($htra != 0) && $dbh->FETCH('Active') ) {
            if ( $err = Mac::DtfSQL::DtfTraExecute($htra , $statement, $reqClass, $affectedRecords, $hres) ) # != 0 means error
            {
                #  Any errors resulted from the SQL request
                #  will be processed here.
                
                if ($hres) { # dispose the result handle
                    DtfResDestroy($hres);
                }

                if ( Mac::DtfSQL::DtfHdlGetError($htra, $err, $errstr, $errgrp, $errpos) ) # != 0 means error
                {
                    $errstr = "ERROR(table_col_info): Can't query the transaction error";
                    return $dbh->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
                } else {
                    return $dbh->DBI::set_err($err, "ERROR(table_col_info): " . $errstr . " (group: " .  $errgrp . ")");
                }#if
            }#if

        } else { # we are not active
            $errstr = "ERROR(table_col_info): The connection seems to be closed";
            return $dbh->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
        
        }#if
        
        #
        # Here we have a valid result handle only if $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE(),  
        # else $hres will be NULL (0). The result table may be empty, though ($affectedRecords == 0).
        # Don't get confused by this.
        #
        
        if ( $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE() ) {      
            
            # We have a result table ...
            
            if ($affectedRecords > 0) { # ... and this table has rows
            
                if ( ( $columncount = Mac::DtfSQL::DtfResColumnCount($hres) ) != 5 ) { # should be 5
                    $errstr = "ERROR(table_col_info): Unexpected result table for $statement";
                    #  Do not forget to destroy the result handle.
                    Mac::DtfSQL::DtfResDestroy($hres);
                
                    return $dbh->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
                }
            
                # We have a sequential cursor (by default) and will use DtfResMoveToFirstRow()  
                # and DtfResMoveToNextRow() for iterating through the result.
            
                Mac::DtfSQL::DtfResMoveToFirstRow($hres);
            
                my $columnname = '';        # columnname
                my $typestring = '';        # columns data type as string
                my $type = 0;               # columns data type as DBI SQL type number
                my $nullable = '';          # nullable attribute 

                for (my $row = 0; $row < $affectedRecords; $row++) {
                
                    my $data_item = 0;      # field data (init to avoid undef warnings)
                    my $isNULL = 0;         # NULL indicator (init to avoid undef warnings)
                
                    my @rowdata = ();       # a single result set's row

                
                    for (my $col = 0; $col < $columncount; $col++) {
      
                        # We retrieve the column's data as string (DTF_CT_CSTRING), a type hint (last argument)
                        # is not nescessary and will be set to 0
                
                        if ( ! ($err = Mac::DtfSQL::DtfResGetField($hres, $col, Mac::DtfSQL::DTF_CT_CSTRING(), $data_item, $isNULL, 0)) ) # != 0 means error
                        {
                            if ($isNULL) {
                                push (@rowdata, undef); # the DBI spec says, NULL fields should be returned as undef
                            } else {
                                push (@rowdata, $data_item);
                            }#if
                        } else {
                            $errstr = "ERROR(table_col_info): Can't retrieve column data";
                            #  Do not forget to destroy the result handle.
                            Mac::DtfSQL::DtfResDestroy($hres);
                    
                            return $dbh->DBI::set_err($err, $errstr); 
                        }#if
                    }#for col
                
                    $columnname = shift @rowdata;               # first element is column name
                    $typestring = $rowdata[0];                  # columns data type as string, e.g. varchar(20)
                    $type = _str2DBItype( $typestring );        # determine DBI SQL type number
                    unshift @rowdata, $type;                    # append to front of array              
                    $nullable = $rowdata[3];                    # nullable attribute ('' or 'NN' - not null)
                    if ( $nullable =~ /NN/ ) {
                        $rowdata[3] = 0; # is not nullable
                    } else {
                        $rowdata[3] = 1; # is nullable
                    }
                    $resulthash{$columnname} = [ @rowdata ];    # add array_ref to hash
                
                    Mac::DtfSQL::DtfResMoveToNextRow($hres);
                
                }#for row
            
            }#if $affectedRecords > 0 
            
            #  Do not forget to destroy the result handle
            #  after processing it.
            Mac::DtfSQL::DtfResDestroy($hres);
        
        }#if $reqClass
                
        return %resulthash;

    }#table_col_info


    # This private sub determines the DBI SQL type number according to a given dtF/SQL data 
    # type string. It is used in table_col_info, see above.
    
    sub _str2DBItype {
        my ($dtf_typestring) = @_;
        
        # ten supported DBI types
        # DBI::SQL_TINYINT() 
        # DBI::SQL_SMALLINT()       
        # DBI::SQL_INTEGER() 
        # DBI::SQL_DOUBLE()
        # DBI::SQL_CHAR()
        # DBI::SQL_VARCHAR()        
        # DBI::SQL_DATE() 
        # DBI::SQL_TIME()  
        # DBI::SQL_TIMESTAMP()  
        # DBI::SQL_DECIMAL() 
        
        return DBI::SQL_TINYINT()       if ( $dtf_typestring =~ /^byte$/i );    # matches byte      
        return DBI::SQL_SMALLINT()      if ( $dtf_typestring =~ /^small/i );    # matches smallint
        return DBI::SQL_SMALLINT()      if ( $dtf_typestring =~ /^word$/i );    # matches word      
        return DBI::SQL_INTEGER()       if ( $dtf_typestring =~ /^int/i );      # matches integer or int
        return DBI::SQL_INTEGER()       if ( $dtf_typestring =~ /^long/i );     # matches long or longword              
        return DBI::SQL_DOUBLE()        if ( $dtf_typestring =~ /^real$/i );    # matches real
        return DBI::SQL_DOUBLE()        if ( $dtf_typestring =~ /^float$/i );   # matches float
        return DBI::SQL_DOUBLE()        if ( $dtf_typestring =~ /^double/i );   # matches double precision      
        return DBI::SQL_VARCHAR()       if ( $dtf_typestring =~ /var/i );       # matches varchar or char varying
        return DBI::SQL_VARCHAR()       if ( $dtf_typestring =~ /string$/i );   # matches shortstring       
        return DBI::SQL_SMALLINT()      if ( $dtf_typestring =~ /^short$/i );   # matches short     
        return DBI::SQL_CHAR()          if ( $dtf_typestring =~ /^char.*\(/i ); # matches char(20) or character(20)
        return DBI::SQL_TINYINT()       if ( $dtf_typestring =~ /^char$/i );    # matches char      
        return DBI::SQL_DATE()          if ( $dtf_typestring =~ /^date$/i );    # matches date
        return DBI::SQL_TIMESTAMP()     if ( $dtf_typestring =~ /stamp$/i );    # matches timestanmp
        return DBI::SQL_TIME()          if ( $dtf_typestring =~ /^time$/i );    # matches time      
        return DBI::SQL_DECIMAL()       if ( $dtf_typestring =~ /^dec/i );      # matches dec (6,2) or decimal(6,2)
        return DBI::SQL_DECIMAL()       if ( $dtf_typestring =~ /^numeric/i );  # matches numeric(6,2)
        
        # else
        return undef;
        
    }

#
# sub quote  { 
#    
# Using the DBI default quote method is suitable for the DtfSQLmac driver.
# Example: don't -> 'don''t'
#
#}
#



} # END PACKAGE DBD::DtfSQLmac::db



#
# =================================== STATEMENT ============================
#



{ # BEGIN PACKAGE

    package  DBD::DtfSQLmac::st; # ====== STATEMENT ======

    $DBD::DtfSQLmac::st::imp_data_size = 0;

    $DBD::DtfSQLmac::st::_num   = 1; # package global constants
    $DBD::DtfSQLmac::st::_str   = 2;
    $DBD::DtfSQLmac::st::_blob  = 3;
    $DBD::DtfSQLmac::st::_other = 4;
    
    use DBI qw(:sql_types);
    use Mac::DtfSQL;
    use strict;
    use Carp;
    

    # bind_param 
    
    # If a type attribute is provided, it could be one of the following
    #   (a) a DBI type constant, e.g. SQL_INTEGER
    #   (b) a hash reference to a prededefined DBI Type, e.g. {'TYPE' => SQL_INTEGER}
    
    # Note(1): The data type for a placeholder cannot be changed after the first 
    # bind_param call (but it can be left unspecified, in which case it defaults
    # to the previous value). 
        
    # Note(2): This driver currently doesn't support blob (binary large objects) 
    # data. If specified as a type attribute to bind_param, this routine will
    # warn the user.
        
    # Note(3): Undefined bind values or undef are be used to indicate null values.
    
    # Note(4): If no type hint is provided and it is not already known, DBI::SQL_VARCHAR()
    # will be assumed as default type according to the DBI spec.
    
    sub bind_param {
        my ($sth, $pNum, $value, $attr) = @_;
        
        my $param_types = $sth->{'dtf_bind_param_types'}; # type hints
        my $params = $sth->{'dtf_bind_param_values'}; # values
        
        if ( $param_types->[$pNum - 1]) {   # the type attr has previously been set     
            
            # ... only store the value (ignore type hint if provided again)
            $params->[$pNum - 1] = $value;
                    
        } else { # type not already known
            my $type = (ref $attr) ? $attr->{TYPE} : $attr; # $type is a DBI SQL type number or undef if 
                                                            # $attr not specified               
            $type = _map2dtftype($type) if defined($type);  # map the DBI SQL type numbers to DtfSQLmac range
            
            if (defined($type) ) { # ... and valid type hint not equal undef, may be 0 !
                # ... store type hint AND value 
                my $type_grp = _number_or_string($type);    # decide if its a num or str or blob type, this may 
                                                            # return $DBD::DtfSQLmac::st::_other for unsupported 
                                                            # DBI SQL type constants (incl. SQL_ALL_TYPES !)
                
                if ($type_grp == $DBD::DtfSQLmac::st::_other) { # unsupported DBI type constant 
                    my $errstr = "ERROR(bind_param): The DtfSQLmac driver doesn\'t support this type of data (wrong type hint)";
                    return $sth->DBI::set_err(64, $errstr); 
                } elsif ($type_grp == $DBD::DtfSQLmac::st::_blob) { # blob  
                    my $errstr = "ERROR(bind_param): The DtfSQLmac driver doesn\'t support binary data (wrong type hint)";
                    return $sth->DBI::set_err(64, $errstr); 
                } else {
                    $param_types->[$pNum - 1] = $type; # supported DBI SQL type number
                    $params->[$pNum - 1] = $value; 
                }#if
                
            } else { # ... and type hint undef, Grrr...
                # ... store default type (VARCHAR) AND value; this case may fail in execute
                $param_types->[$pNum - 1] = DBI::SQL_VARCHAR();
                $params->[$pNum - 1] = $value;
            }#if
        }#if

        return 1;
    }#bind_param
     
    
    
    # This private sub decides if the DBI SQL type constant is a number, string
    # or a blob.
    # Returns $_num for number, $_str for string, $_blob for binary data (blob) 
    # and undef if there is no match.

    sub _number_or_string {
        my ($dbi_type) = @_;
        
        # SQL_INTEGER and SQL_VARCHAR and SQL_CHAR are the most likely type hints, I assume
        
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_INTEGER();
        return $DBD::DtfSQLmac::st::_str            if $dbi_type == DBI::SQL_VARCHAR();
        return $DBD::DtfSQLmac::st::_str            if $dbi_type == DBI::SQL_CHAR();
        
        # (other) numeric types
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_NUMERIC();
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_DECIMAL();     
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_FLOAT();
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_REAL();
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_DOUBLE();      
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_TINYINT();     
        return $DBD::DtfSQLmac::st::_num            if $dbi_type == DBI::SQL_SMALLINT();
		
		# return $DBD::DtfSQLmac::st::_num          if $dbi_type == DBI::SQL_BIGINT();
		# DBI::SQL_BIGINT() (temporary ?) omitted as of DBI 1.21
		# we now return $DBD::DtfSQLmac::st::_other to indicate that SQL_BIGINT is 
        # an unsupported DBI SQL type constant

      
        # other string types (must be quoted) 
        
        return $DBD::DtfSQLmac::st::_str            if $dbi_type == DBI::SQL_LONGVARCHAR();        
        return $DBD::DtfSQLmac::st::_str            if $dbi_type == DBI::SQL_DATE();
        return $DBD::DtfSQLmac::st::_str            if $dbi_type == DBI::SQL_TIME();
        return $DBD::DtfSQLmac::st::_str            if $dbi_type == DBI::SQL_TIMESTAMP();
        
        # the blob type is not supported
        return $DBD::DtfSQLmac::st::_blob           if $dbi_type == DBI::SQL_BINARY();
        return $DBD::DtfSQLmac::st::_blob           if $dbi_type == DBI::SQL_VARBINARY();
        return $DBD::DtfSQLmac::st::_blob           if $dbi_type == DBI::SQL_LONGVARBINARY();
        		

        return $DBD::DtfSQLmac::st::_other; # otherwise

    }# _number_or_string    



    # DtfSQLmac doesn't support all of the DBI SQL data type numbers (constants). 
    # This private sub maps a SQL data type to the nearest supported DtfSQLmac  
    # data type, i.e. a subrange of the SQL data type numbers. It is needed in 
    # bind_params(), where the user may provide a type hint in the 
    # {TYPE => SQL_INTEGER} or SQL_INTEGER notation.
 
    sub _map2dtftype {
        my ($dbi_type) = @_;
        
        # ten supported types
        # DBI::SQL_TINYINT() 
        # DBI::SQL_SMALLINT()       
        # DBI::SQL_INTEGER() 
        # DBI::SQL_DOUBLE()
        # DBI::SQL_CHAR()
        # DBI::SQL_VARCHAR()        
        # DBI::SQL_DATE() 
        # DBI::SQL_TIME()  
        # DBI::SQL_TIMESTAMP()  
        # DBI::SQL_DECIMAL() 
        
        # The binary types (as of DBI 1.08)
        #   SQL_BINARY 
        #   SQL_VARBINARY 
        #   SQL_LONGVARBINARY
        # are not supported at all.
        
		# SQL_BIGINT (temporary ?) omitted as of DBI 1.21
		# Hence we no longer support it and don't provide a mapping.
		# return DBI::SQL_INTEGER()           	if $dbi_type == DBI::SQL_BIGINT();

				
        # numeric types
		 
		return DBI::SQL_DECIMAL()               if $dbi_type == DBI::SQL_NUMERIC();     
        return DBI::SQL_DOUBLE()                if $dbi_type == DBI::SQL_FLOAT();
        return DBI::SQL_DOUBLE()                if $dbi_type == DBI::SQL_REAL();
     
        # string types
        return DBI::SQL_VARCHAR()               if $dbi_type == DBI::SQL_LONGVARCHAR();
        
        # else
        return $dbi_type;
    }


    # Returns the DBI type code correponding to the given DtfSQLmac
    # type code. This private sub is used in execute(), after we have
    # a result table and need to store the TYPE attributes array
    
    sub _dbi_type {
        my ($dtf_type) = @_;
    
        return DBI::SQL_TINYINT()       if $dtf_type == $DBD::DtfSQLmac::Types{CHAR};               # 1
        return DBI::SQL_TINYINT()       if $dtf_type == $DBD::DtfSQLmac::Types{BYTE};               # 2
        return DBI::SQL_SMALLINT()      if $dtf_type == $DBD::DtfSQLmac::Types{SMALLINT};           # 3
        return DBI::SQL_SMALLINT()      if $dtf_type == $DBD::DtfSQLmac::Types{WORD};               # 4     
        return DBI::SQL_INTEGER()       if $dtf_type == $DBD::DtfSQLmac::Types{INTEGER};            # 5
        return DBI::SQL_INTEGER()       if $dtf_type == $DBD::DtfSQLmac::Types{LONGWORD};           # 6
        return DBI::SQL_DOUBLE()        if $dtf_type == $DBD::DtfSQLmac::Types{FLOAT};              # 8
        return DBI::SQL_CHAR()          if $dtf_type == ($DBD::DtfSQLmac::Types{CHARACTER} * 10);   # 90 !!!
        return DBI::SQL_VARCHAR()       if $dtf_type == $DBD::DtfSQLmac::Types{VARCHAR};            # 9     
        return DBI::SQL_DATE()          if $dtf_type == $DBD::DtfSQLmac::Types{DATE};               # 13
        return DBI::SQL_TIME()          if $dtf_type == $DBD::DtfSQLmac::Types{TIME};               # 14 
        return DBI::SQL_TIMESTAMP()     if $dtf_type == $DBD::DtfSQLmac::Types{TIMESTAMP};          # 15
        return DBI::SQL_DECIMAL()       if $dtf_type == $DBD::DtfSQLmac::Types{DECIMAL};            # 16        
        
        # else
        return undef;       
    }

    
    # The private function _col_nullable retrieves the nullable metadata attribute (0 or 1) for 
    # all columns of a given table
 
    # The result is a hash reference, where the keys are the column name and the value is the
    # boolean nullable attribut (0 or 1)
 
    # \%resulthash = (
    #                columnname_0 => nullable,
    #                ..
    #                columnname_n => nullable,
    # );
 
    # ($err, $errstr, $hash_ref) = _col_nullable($htra, $tablename);
    
    sub _col_nullable   { 
        my $htra = shift;                       # transaction handle
        my $tablename = shift;                  # tablename 
        my $hres = 0;                           # result handle
        my $reqClass;                           # request class, should be DTF_RC_RESULT_AVAILABLE, see above 
        my $affectedRecords = 0;                # rowcount  
        my $columncount = 0;                    # columncount

        my $err;        # error code
        my $errstr;     # error message
        my $errgrp;     # error group
        my $errpos;     # error position within the SQL request
        
        my %resulthash = ();    # hash we will return 
                
        my $statement = 'SHOW COLUMNS FOR ' . $tablename;       # sql statement
        
        if ( $htra != 0 ) {
            if ( $err = Mac::DtfSQL::DtfTraExecute($htra , $statement, $reqClass, $affectedRecords, $hres) ) # != 0 means error
            {
                #  Any errors resulted from the SQL request
                #  will be processed here.
                
                if ($hres) { # dispose the result handle
                    DtfResDestroy($hres);
                }

                if ( Mac::DtfSQL::DtfHdlGetError($htra, $err, $errstr, $errgrp, $errpos) ) # != 0 means error
                {
                    $errstr = "ERROR(_col_nullable): Can't query the transaction error";
                    return ($err, $errstr, 0); 
                } else {
                    return ($err, "ERROR(_col_nullable): " . $errstr . " (group: " .  $errgrp . ")", 0);
                }#if
            }#if

        } else { # transaction handle not valid
            $errstr = "ERROR(_col_nullable): The connection seems to be closed";
            return (64, $errstr, 0); # 64 == Mac::DtfSQL::DTF_ERR_USER()
        
        }#if
        
        #
        # Here we have a valid result handle only if $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE(),  
        # else $hres will be NULL (0). The result table may be empty, though ($affectedRecords == 0).
        # Don't get confused by this.
        #
        
        if ( $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE() ) {      
            
            # We have a result table ...
            
            if ($affectedRecords > 0) { # ... and this table has rows 
            
                if ( ( $columncount = Mac::DtfSQL::DtfResColumnCount($hres) ) != 5 ) { # should be 5
                    $errstr = "ERROR(_col_nullable): Unexpected result table for $statement";
                    #  Do not forget to destroy the result handle.
                    Mac::DtfSQL::DtfResDestroy($hres);
        
                    return (64, $errstr, 0); 
                }
            
                # We have a sequential cursor (by default) and will use DtfResMoveToFirstRow()  
                # and DtfResMoveToNextRow() for iterating through the result.
            
                Mac::DtfSQL::DtfResMoveToFirstRow($hres);
            
                my $columnname = '';        # columnname, column 0
                my $nullable = '';          # nullable attribute , column 3

                for (my $row = 0; $row < $affectedRecords; $row++) {
                
                    my $data_item = 0;      # field data (init to avoid undef warnings)
                    my $isNULL = 0;         # NULL indicator (init to avoid undef warnings)
                
                    my @rowdata = ();       # a single result set's row, filled with (columnname, nullable)

                    foreach my $col (0, 3)  { # col 0 is column name, col 3 is nullable info
      
                        # We retrieve the column's data as string (DTF_CT_CSTRING), a type hint (last argument)
                        # is not nescessary and will be set to 0
                
                        if ( ! ( $err = Mac::DtfSQL::DtfResGetField($hres, $col, Mac::DtfSQL::DTF_CT_CSTRING(), $data_item, $isNULL, 0)) ) # != 0 means error
                        {
                            if ($isNULL) {
                                $errstr = "ERROR(_col_nullable): Unexpected column data NULL ";
                                #  Do not forget to destroy the result handle.
                                Mac::DtfSQL::DtfResDestroy($hres);
                                return (64, $errstr, 0); # field value should not be null
                            } else {
                                push (@rowdata, $data_item);
                            }#if
                        } else {
                            $errstr = "ERROR(_col_nullable): Can't retrieve column data";
                            #  Do not forget to destroy the result handle.
                            Mac::DtfSQL::DtfResDestroy($hres);
                            return ($err, $errstr, 0);
                        }#if
                    }#for col
                
                    # $columnname = $rowdata[0];    # first element is column name
                    # $nullable = $rowdata[1];      # nullable attribute ('' or 'NN' - not null)
                    if ( $rowdata[1] eq 'ERROR' ) {
                        $resulthash{$rowdata[0]} = 2; # unknown
                    } elsif ( $rowdata[1] =~ /NN/ ) {
                        $resulthash{$rowdata[0]} = 0; # is not nullable
                    } else {
                        $resulthash{$rowdata[0]} = 1; # is nullable
                    }
                
                    Mac::DtfSQL::DtfResMoveToNextRow($hres);
                }#for row
            
            }#if $affectedRecords > 0
            
            #  Do not forget to destroy the result handle
            #  after processing it.
            Mac::DtfSQL::DtfResDestroy($hres) if ($hres);
            
        }#if $reqClass
                
        return (0, '', \%resulthash); 

    }#_col_nullable
    



    # query the database

    sub execute {
        my ($sth, @bind_values) = @_;
        my $errstr = ''; # error message 
		my $dbh = $sth->FETCH('Database'); # get database handle
				
        my @params_array = (@bind_values) ? @bind_values : @{$sth->{'dtf_bind_param_values'}}; # values
        my $numParam = $sth->FETCH('NUM_OF_PARAMS');

        if (scalar(@params_array) != $numParam) {  # Grrr...
            $errstr = "ERROR(execute): The number of placeholders (NUM_OF_PARAMS = $numParam) does not match the"
                      . "\n# number of parameter values (count = ". scalar(@params_array) . ") you've provided";
            return $sth->DBI::set_err(64, $errstr); # in fact, returns undef # Mac::DtfSQL::DTF_ERR_USER()
        }

        # check statement for PAIRS of quotes ...
        
        my $statement = $sth->FETCH('Statement');
        
        my $quote_count = ( $statement =~ s/'/'/g );
        if ( ($quote_count % 2) != 0 ) { # not even
            $errstr = "ERROR(execute): SQL statement -- quotes must occur in pair (e.g. don't is quoted as 'don''t')";
            return $sth->DBI::set_err(64, $errstr); # in fact, returns undef # Mac::DtfSQL::DTF_ERR_USER()
        } 

        # substitute placeholders, if any (NUM_OF_PARAMS > 0) ... 
        
        if ($numParam > 0) { # if placeholders

            my @qmark_array = ();
            my $qmark_elements = 0;
            my $type_hint;
            my $type_grp;
            my @param_types_ary = @{$sth->{'dtf_bind_param_types'}}; # type hints, array may be empty

            # first, warn if the number of type hints doesn't match the number of placeholders
        
            if ( $sth->FETCH('Warn') ) { # warn only if Warn is on (should be on by default)
                if ( $numParam  != scalar(@param_types_ary) ) {
                    carp ("WARN(execute): The number of placeholders (NUM_OF_PARAMS = $numParam) does not match the number of type hints"
                         ."\n# (count = ". scalar(@param_types_ary) . "). All values without a type hint will be bound as SQL_VARCHAR, and this may fail.");
                }#if        
            }#if

            # now, begin substitution ...
        
            my @stmt_array = split (/'/, $statement); # all even elements ([0], [2] etc.) are unquoted parts
            my $stmt_elements = @stmt_array;
        
            my ($i, $j) = (0, 0);
        
            for ($i = 1; $i < $stmt_elements; $i += 2) {
                $stmt_array[$i] = "'" . $stmt_array[$i] .  "'"; # (re-) quote the odd array elements
            }
        
            for ($i = 0; $i < $stmt_elements; $i += 2) {
                if ($stmt_array[$i] =~ /\?/) { # substr contains '?' placeholder
                
                    # The split algorithm needs to know, whether the statement substring $stmt_array[$i] ends   
                    # with the placeholder '?'. In this case, there's no string (not even an empty string) for  
                    # the chars "after" the last '?'.               
                    # Example: 
                    # 'WHERE id = ?' will split to one element 'WHERE id = '
                    # Thus we have to replace the placeholder for *all* elements of @qmark_array. If the statement 
                    # substring doesn't end with '?', we have to replace the placeholder for all question mark 
                    # substrings *except the last*. 
                
                    my $sub_last = 1; # replace all substrings except the last
                    if ($stmt_array[$i] =~ /\?$/ ) { # ends with '?'
                        $sub_last = 0; # replace all substrings
                    } 
                
                    @qmark_array = split (/\?/, $stmt_array[$i]); # split statement substr on '?' placeholder
                    $qmark_elements = @qmark_array;             
                
                    for ($j = 0; $j < ($qmark_elements - $sub_last); $j++) { # replace '?' placeholder with actual value
                        my $param_val = shift @params_array; # value
                        if (! defined($param_val) ) { # undef = NULL
                            $qmark_array[$j] = $qmark_array[$j] . 'NULL'; # bind NULL
                        } else {
                            # a $type_hint may not exist, if number of placeholders != number of type hints,
							# in this case, we bind the value as string by default
                            $type_hint = @param_types_ary ? shift @param_types_ary : DBI::SQL_VARCHAR();

							# bind value as string or num according to the type hint by using the quote method
							$qmark_array[$j] = $qmark_array[$j] . $dbh->quote($param_val, $type_hint); 
                        }#if                    
                    }#for
                    # concatenate substrings
                    $stmt_array[$i] = join ('', @qmark_array);
                }#if
            }#for
            # concatenate statement, and that's it
            $statement = join ('', @stmt_array);
            #print "QUERY= $statement\n"; # TEST
        }#if placeholders

        # Now we have a proper SQL string we will send to the database engine using the 
        # function DtfTraExecute() which is typically used for sending SQL requests which 
        # are unknown to the program developer. Note that, other than with DtfTraExecuteQuery(), 
        # the parameter "restype" is missing. Instead, the default result type (DTF_RT_SEQUENTIAL 
        # => sequential cursor), modifiable with DtfHdlSetAttribute(), will be used.
    
        # Description
        # DTF_RT_SEQUENTIAL sequential cursor; restricted to DtfResMoveToFirstRow() and 
        # DtfResMoveToNextRow() for iterating through the result; needs little memory, 
        # independent from the resultÕs size.


        # After the function DtfTraExecute returns, $reqClass will contain the SQL requestÕs 
        # class if the request was executed successfully; $reqClass will be one of the following 
        # values:

        # DTF_RC_ROWS_AFFECTED (= 0)
        #       The statement was of a modifying kind (insert, update, delete statements), and 
        #       affected 0 or more records (check $affectedRecords).
            
        # DTF_RC_RESULT_AVAILABLE (= 1)
        #       The statement was of a querying kind (select, show statements), and returned 0  
        #       or more rows of data ($hres is valid (!= 0), $affectedRecords = row count).

        # DTF_RC_OTHER (= 2)
        #       The statment was of a different kind than the above, for example a create, drop, 
        #       grant, and revoke statement.
 
 
        #  and now execute the statement ...
        my $hres = 0;                               # result handle
        my $reqClass;                               # request class, see above
        my $columncount = 0;                        # columncount :)
        my $affectedRecords = 0;                    # rowcount
        my $htra = $dbh->{'dtf_htra'};              # get transaction handle
        
        my $err;        # error code
        my $errgrp;     # error group
        my $errpos;     # error position within the SQL request
        
        if ( ($htra != 0) && $dbh->FETCH('Active') ) {
            if ( $err = Mac::DtfSQL::DtfTraExecute($htra , $statement, $reqClass, $affectedRecords, $hres) ) # != 0 means error
            {
                #  Any errors resulted from the SQL request
                #  will be processed here.
                
                if ($hres) { # dispose the result handle 
                    DtfResDestroy($hres);
                }

                if ( Mac::DtfSQL::DtfHdlGetError($htra, $err, $errstr, $errgrp, $errpos) ) # != 0 means error
                {
                    $errstr = "ERROR(execute): Can't query the transaction error";
                    return $sth->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
                } else {
                    return $sth->DBI::set_err($err, "ERROR(execute): " . $errstr . " (group: " .  $errgrp . ")");
                }#if
            }#if

        } else { # we are not active
            $errstr = "ERROR(execute): The connection seems to be closed";
            return $sth->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
        
        }#if
                
        # What gets returned from execute?
        # An undef is returned if an error occurs, a successful execute always returns true regardless 
        # of the number of rows affected (even if it's zero, see below). 
        # For a non-select statement, execute returns the number of rows affected (if known). If no rows 
        # were affected then execute returns "0E0" which Perl will treat as 0 but will regard as true.  
        # Note that it is not an error for no rows to be affected by a statement. If the number of rows 
        # affected is not known then execute returns -1.
        
        # NUM_OF_FIELDS: Number of fields (columns) the prepared statement will return. Non-select statements 
        # will have NUM_OF_FIELDS == 0. 

        
        #
        # Here we have a valid result handle only if $reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE(),  
        # else $hres will be NULL (0). The result table may be empty, though ($affectedRecords == 0).
        # Don't get confused by this.
        #
        
        # now, handle the result
        
        # For a statement handle the Active attribute typically means that the handle is a select that may have 
        # more data to fetch ($dbh->finish or fetching all the data should set Active off).
    
        if ($reqClass == Mac::DtfSQL::DTF_RC_OTHER() ) {
            # for example a create, drop, grant, and revoke statement
            $sth->STORE('NUM_OF_FIELDS', 0) unless $sth->FETCH('NUM_OF_FIELDS');
            $sth->{'dtf_rowcount'} = -1;
            $sth->STORE('Active', 0); # there are no rows we can fetch, thus active is 0
            return -1;
      
        } elsif ($reqClass == Mac::DtfSQL::DTF_RC_ROWS_AFFECTED() ) {
            # The statement was of a modifying kind (insert, update, delete statements),
            # and affected 0 or more records.
            $sth->STORE('NUM_OF_FIELDS', 0) unless $sth->FETCH('NUM_OF_FIELDS');
            $sth->{'dtf_rowcount'} = $affectedRecords;
            $sth->STORE('Active', 0); # there are no rows we can fetch, thus active is 0        
        
            return $affectedRecords || '0E0';
        
        } elsif ($reqClass == Mac::DtfSQL::DTF_RC_RESULT_AVAILABLE() ) {      
            # We have a result table.
            # We will build an array of (anonymus) array references (aka list of list -- LoL),  
            # where each array_ref represents a single row with $columncount columns. 
            # A reference to the entire array will be stored as sth attribute.
                
            $columncount = Mac::DtfSQL::DtfResColumnCount($hres);
            
            $sth->STORE('NUM_OF_FIELDS', $columncount) unless $sth->FETCH('NUM_OF_FIELDS'); # set it only once (read only)
            $sth->{'dtf_rowcount'} = $affectedRecords;
            $sth->STORE('Active', 1);

            # 
            #  Step 1: retrieve column information
            #
            
            my $hcol = 0; # column handle # Mac::DtfSQL::DTFHANDLE_NULL()
            
            my $colname;        # Name of column, i.e. field name
            my $columns_table;  # Name of table the column belongs to
            my $definition;     # attribute definition string as used in create table
            my $ctype;          # the C data type code of the column
            my $prec;           # PRECISION 
            my $scale;          # SCALE
      
            my @nameArray = ();         # array of column names
            my @tableArray = ();        # array of corresponding table names
            my @dbi_typeArray = ();     # array of DBI SQL type numbers
            my @precisionArray = ();    # array of precision values
            my @scaleArray = ();        # array of scale values
            my @nullableArray = ();     # array of nullable info
          
            for (my $col = 0; $col < $columncount; $col++) {
                #  Create a column handle from the current result set.

                if ( ! (Mac::DtfSQL::DtfColCreate($hres, $col, $hcol)) ) {
                    
                    $colname = Mac::DtfSQL::DtfColName($hcol);
                    push (@nameArray, $colname);
                                                
                    $columns_table = Mac::DtfSQL::DtfColTableName($hcol);
                    push (@tableArray, $columns_table);
                    
                    $ctype = Mac::DtfSQL::DtfColCType($hcol);
                    
                    # definition attribute, used to distinguish between fixed length char and varchar
                    # != 0 means error
                    $err = Mac::DtfSQL::DtfHdlQueryAttribute($hcol, Mac::DtfSQL::DTF_LAT_DEFINITION, $definition);
                    if (! $err) {
                        if ( ($definition =~ /^character(\d+)$/i) || 
                             ($definition =~ /^char(\d+)$/i) ) {    # matches char(dd) or character(d)
                            $ctype *= 10; # multiply with 10, => fixed length char == 90 while varchar == 9 !
                        }
                    }
                                    
                    # convert the C type code to a DBI SQL data type number
                    push (@dbi_typeArray, _dbi_type($ctype) );
    
                    
                    # determine type precision, the info stored in the database is a bit buggy in some cases,
                    # thus we will do this by hand
                    if ( ($ctype == 9) || ($ctype == 90) || ($ctype == 16) ) { # a char/string or a decimal
                        $err = Mac::DtfSQL::DtfHdlQueryAttribute($hcol, Mac::DtfSQL::DTF_LAT_PRECISION(), $prec);
                        $prec = (! $err) ? $prec : undef;
                    } else { 
                        if ( ($ctype == 1) || ($ctype == 2) ) { # char or byte
                            $prec = 3; # display width should be 4
                        } elsif ( ($ctype == 3) || ($ctype == 4) ) { # smallint/short or word
                            $prec = 5; # display width should be 6
                        } elsif ( ($ctype == 5) || ($ctype == 6) ) { #
                            $prec = 10; # display width should be 11
                        } elsif ($ctype == 8) { # real, float, double
                            $prec = 15; # display width should be 22
                        } elsif ($ctype == 13) { # date yyyy-mm-dd
                            $prec = 10; # display width should be 10
                        } elsif ($ctype == 14) { # time hh:mm:ss[.fff]
                            $prec = 12; # display width should be 12 (wrong in dtF/SQL)
                        } elsif ($ctype == 15) { # timestamp yyyy-mm-dd hh:mm:ss[.fff]
                            $prec = 23; # display width should be 23 (wrong in dtF/SQL)
                        } else {
                            $prec = undef;
                        }                   
                    }#if
                    push (@precisionArray, $prec);
                    
                    # determine scale                   
                    if ($ctype == 16) { # a decimal
                        $err = Mac::DtfSQL::DtfHdlQueryAttribute($hcol, Mac::DtfSQL::DTF_LAT_SCALE(), $scale); 
                        $scale = (! $err) ? $scale : undef;
                    } else {
                        $scale = undef; # for all other types
                    }#if                    
                    push (@scaleArray, $scale);                 

                    #  Do not forget to destroy the column handle
                    #  after processing it.
                    Mac::DtfSQL::DtfColDestroy($hcol);
                    
                } else { # can't create column handle
                    $errstr = "ERROR(execute): Can't create column handle";
                    return $sth->DBI::set_err(64, $errstr); # Mac::DtfSQL::DTF_ERR_USER()
                }#if
            }#for col
            
            $sth->{'dtf_name'} = \@nameArray;
            $sth->{'dtf_table_i'} = \@tableArray; # driver specific, no DBI standard                                                    
            $sth->{'dtf_type'} = \@dbi_typeArray;
            $sth->{'dtf_precision'} = \@precisionArray;
            $sth->{'dtf_scale'} = \@scaleArray;
            
                    
            #
            #  Step 2: retrieve and store result table
            #
            
            my @resulttable = (); # this is my LoL          
            
            # We have a sequential cursor (by default) and will use DtfResMoveToFirstRow()  
            # and DtfResMoveToNextRow() for iterating through the result.
            
            Mac::DtfSQL::DtfResMoveToFirstRow($hres);

            for (my $row = 0; $row < $affectedRecords; $row++) {
                
                my $data_item = 0;      # field data (init to avoid undef warnings)
                my $isNULL = 0;         # NULL indicator (init to avoid undef warnings)
                
                my @rowdata = ();

                if ($columncount > 0) {
                    for (my $col = 0; $col < $columncount; $col++) {    
                        # we retrieve the data as STRING ( DTF_CT_CSTRING ), a type hint (last argument)
                        # is not nescessary and will be set to 0
                        if ( ! ($err = Mac::DtfSQL::DtfResGetField($hres, $col, Mac::DtfSQL::DTF_CT_CSTRING(), $data_item, 
                                $isNULL, 0)) ) # != 0 means error
                        {
                            if ($isNULL) {
                                push (@rowdata, undef); # the DBI spec says, NULL fields should be returned as undef
                            } else {
                                push (@rowdata, $data_item);
                            }#if
                        } else {
                            $errstr = "ERROR(execute): Can't retrieve column data";
                            return $sth->DBI::set_err($err, $errstr); 
                        }#if
                    }#for col
                }#if

                push (@resulttable, [ @rowdata ]); # push the ref to @rowdata at the end of my LoL @resulttable
                Mac::DtfSQL::DtfResMoveToNextRow($hres);
            }#for row
            
            # now store a reference to the @resulttable as data
            $sth->{'dtf_data'} = \@resulttable;
            
            #  Do not forget to destroy the result handle
            #  after processing it.
            Mac::DtfSQL::DtfResDestroy($hres);
            
            #
            # Step 3: retrieve nullable information
            #
            
            # The following is odd: the nullable metadata can only be retrieved via a "SHOW COLUMNS FOR <table>"
            # statement. This will require a new result handle, and therefore we retrieve this information after
            # the result handle for the actual SQL statement was destroyed.
            
            # @tableArray contains all table names, I need a list (hash) of unique table names
            my $table;      
            my %unique_tableHash = ();
            foreach $table (@tableArray) {
                $unique_tableHash{$table} = 1;
            }
                    
            # \%resulthash = (
            #                columnname_0 => nullable, # 0 -> is not nullable (NOT NULL)
            #                ..
            #                columnname_n => nullable, # 1 -> is nullable
            # );
            
            my $hash_ref;
            foreach $table (keys (%unique_tableHash)) {
                ($err, $errstr, $hash_ref) = _col_nullable($htra, $table);
                if ($err) {
                    $unique_tableHash{$table} = 0;
                } else {
                    $unique_tableHash{$table} = $hash_ref;
                }
            }

            $columncount = @nameArray; # column name array
            for (my $col = 0; $col < $columncount; $col++) {
                if ( (  $unique_tableHash{$tableArray[$col]} != 0  ) && 
                     (  exists ( $unique_tableHash{$tableArray[$col]}->{$nameArray[$col]} )  ) 
                   ) {
                        
                    push (@nullableArray, $unique_tableHash{$tableArray[$col]}->{$nameArray[$col]} ); 
                    # 0 => NOT NULL, 1 => can be NULL, 2 for error
                } else {
                    push (@nullableArray, 2); # 2 = unknown
                }#if
            }#for
            
            $sth->{'dtf_nullable'} = \@nullableArray;

        }#if DTF_RC_RESULT_AVAILABLE
        
        return $affectedRecords || '0E0';
        
    }#execute



    
    # fetch one row of data, alias fetchrow_arrayref
    sub fetch {
        my ($sth) = @_;
        my $resulttable_ref = $sth->{'dtf_data'};   # a reference to the @resulttable, which is a LoL
        my $row_ref = shift @{$resulttable_ref};        # get the first row, an array reference
        if (!$row_ref) {  # no more data
            $sth->finish(); # call the finish method automatically
            return undef;
        } else { # return a reference to a row of data
            if ($sth->FETCH('ChopBlanks')) {
                map { $_ =~ s/\s+$//; } @{$row_ref};    # chop the trailing blanks
            }
            return $sth->_set_fbav($row_ref); 
        }#if        
    }

    *fetchrow_arrayref = \&fetch; # required alias for fetchrow_arrayref


    # This will return the number of rows affected after the SQL statement 
    # has been executed; stored in the 'dtf_rowcount' attribute 
    sub rows { 
        my $sth = shift @_;
        return $sth->{'dtf_rowcount'};
    }



    # finish the statement handle
    # the dtf result handle has already been disposed, so there is not much to do
    sub finish { 
        my $sth = shift @_;
        $sth->{'dtf_data'} = undef;
        $sth->STORE('Active', 0);

        $sth->SUPER::finish;
    }



    sub STORE {
        my ($sth, $attr, $value) = @_;
        
        if ($attr =~ /^dtf_/) {
            $sth->{$attr} = $value;
            return 1;
        }
        
        $sth->SUPER::STORE($attr, $value);
    }


    sub FETCH {
        my ($sth, $attr) = @_;
        if ($attr =~ /^dtf_/) {
        
            # dtf_table (array-ref, read-only):         * valid after execute *
            #       Returns a reference to an array of corresponfing table names 
            #       for each column 
        
            if ($attr eq 'dtf_table') {
                return $sth->{'dtf_table_i'};   # dtf_table_i is used internally, this
                                                # makes dtf_table read-only
            } else {            
                return $sth->{$attr};
            }#if
            
        }#if

        # Note that the DtfSQLmac driver cannot provide valid values for all  
        # of the following attributes until after $sth->execute has been called.


        # NAME (array-ref, read-only):      * valid after execute *
        #       Returns a reference to an array of field names for each column 
        #       example: print "First column name: $sth->{NAME}->[0]\n";
            
        if ($attr eq 'NAME') {
            return $sth->{'dtf_name'};
        }   
        
        
        # TYPE  (array-ref, read-only):     * valid after execute *
        #       Returns a reference to an array of integer values for each column. The 
        #       value indicates the data type of the corresponding column.
        
        if ($attr eq 'TYPE') {
            return $sth->{'dtf_type'};
        }
        
        # PRECISION  (array-ref, read-only):    * valid after execute *
        #       Returns a reference to an array of integer values for each column.  For 
        #       nonnumeric columns the value generally refers to either the maximum length 
        #       or the defined length of the column.  For numeric columns the value refers 
        #       to the maximum number of significant digits used by the data type (without 
        #       considering a sign character or decimal point).
        
        if ($attr eq 'PRECISION') {
            return $sth->{'dtf_precision'};
        }
        
        # SCALE  (array-ref, read-only):        * valid after execute *
        #       Returns a reference to an array of integer values for each column. NULL (undef) 
        #       values indicate columns where scale is not applicable. 

        if ($attr eq 'SCALE') {
            return $sth->{'dtf_scale'};
        }
        
        # NULLABLE  (array-ref, read-only):     * valid after execute *
        #       Returns a reference to an array indicating the possibility of each column 
        #       returning a null: 0 = no, 1 = yes, 2 = unknown.
        #       example: print "First column may return NULL\n" if $sth->{NULLABLE}->[0];

        if ($attr eq 'NULLABLE') {
            return $sth->{'dtf_nullable'};
        }
                
        # CursorName  (string, read-only):      * not supported *   
        #       Returns the name of the cursor associated with the statement handle if available. 
        #       If not available or the database driver does not support the "where current of ..." 
        #       SQL syntax then it returns undef. 

        if ($attr eq 'CursorName') {
            return undef; # Not supported.
        }
        
        # RowsInCache  (integer, read-only):    
        #       If the driver supports a local row cache for select statements then this attribute 
        #       holds the number of un-fetched rows in the cache. If the driver doesn't, then it 
        #       returns undef. Note that some drivers pre-fetch rows on execute, others wait till 
        #       the first fetch.
        
        if ($attr eq 'RowsInCache') {
            return undef; # Not supported.
        }

        $sth->SUPER::FETCH($attr);
    }

    # Destroys the $sth object on garbage collection. 
   
    sub DESTROY {
        return undef;
    }


} # END PACKAGE DBD::DtfSQLmac::st
    

1;


__END__

=head1 NAME

DBD::DtfSQLmac - A DBI driver for the dtF/SQL 2.01 database engine, Macintosh edition

=head1 SYNOPSIS

    use DBI 1.08;
    # or
    use DBI 1.08 qw(:sql_types :utils);


    $dsn = "dbi:DtfSQLmac:HardDisk:path:to:database";
    # or
    $dsn = "dbi:DtfSQLmac:HardDisk:path:to:database;dtf_commit_on_disconnect=1";

    # get a list of all available data sources (databases), the 
    # search will start in the current directory
    @ary = DBI->data_sources('DtfSQLmac');
    
    # specify the commit behavior when diconnecting from a database
    $dbh ->{dtf_commit_on_disconnect} = 1;
    
    # retrieve metadata about a table's columns
    %resulthash = $dbh->func($tablename, 'table_col_info'); 

    # The additional statement handle attribute dtf_table holds a reference to 
    # an array of table names for each result set's column
    $ary_ref = $sth->{dtf_table}; # valid after execute, read-only

 
    # For everything else, see the DBI module documentation and the corresponding 
    # sections in this document for differences and/or additions.


=head1 REQUIREMENTS

=head2 For MacPerl 5.2.0r4

  MacPerl 5.2.0r4 (5.004)
  DBI 1.08 (Mac build for MacPerl 5.2.0r4)
  Mac::DtfSQL 0.3201 (part of the distribution)

=head2 For MacPerl 5.6.1 (and higher)

  MacPerl >= 5.6.1
  DBI >= 1.08 (Mac build for MacPerl 5.6.1)
  Mac::DtfSQL 0.3201 (part of the distribution)


=head1 DESCRIPTION

DBD::DtfSQLmac is a DBI driver for the dtF/SQL 2.01 database engine, Macintosh edition. dtF/SQL is a 
relational database engine for Mac OS, Windows 95/NT, and several Unix platforms from sLAB Banzhaf & Soltau oHG 
(http://www.slab.de/), Boeblingen, Germany. The dtF/SQL database engine implements an impressive set of ANSI SQL-92 
functionality. It is designed as an embedded database for product developers. Best of all, it's free for 
non-commercial use. 

The state of free (or nearly free) relational databases on the Macintosh running classic Mac OS isn't great, thus 
dtF/SQL is a remarkable exception. Because of the lack of free relational databases, the number of Perl DBI drivers 
usable for the Macintosh is limited (in fact, there's only a handful). This module should help to alleviate the 
situation.

DBD::DtfSQLmac, a pure Perl driver, could not be used stand-alone. It could only be used in conjunction 
with the Mac::DtfSQL module (part of the distribution), which is the Perl interface to the dtF/SQL database 
engine. While the Mac::DtfSQL extension module does all the dirty work talking to the dtF/SQL C API, this module, 
DBD::DtfSQLmac, offers the standard Perl DBI API to relational databases.

This module should run on a PowerPC Macintosh with Mac OS 7.x/8.x/9.x right out of the box. Unfortunately, users of 
a 68K Mac are a bit out of luck, because I cannot provide a pre-built version of the Mac::DtfSQL extension 
module for them. One will need a Metrowerks Codewarrior compiler and linker to build a version for CFM 68K Macs running
MacPerl 5.2.0r4 (see the Mac::DtfSQL module documentation for more information). However, be aware that support for 
dynamic loading of shared libraries has been dropped for the 68K versions of the new MacPerl 5.6.1 (and higher) tool 
and application. Hence, you will have to link the Mac::DtfSQL extension I<statically> into your MacPerl 5.6.1 binary.

The DBD::DtfSQLmac driver currently has two main limitations: First, it could only be used in single-user 
mode (i.e. locally), because the dtF/SQL Database-Server, needed for a network connection, doesn't work as 
expected (at least on a single Mac, acting both as a client and server; I haven't tested it in a network). 
Second, due to the underlying database engine, the driver is limited to one connection at a time.

Please see the Mac::DtfSQL module documentation for more information on the dtF/SQL 2.01 database engine and
how to get it.


=head1 INSTALLATION

=head2 Installation for MacPerl 5.2.0r4

First, install the Mac build of the DBI 1.08 module, available from the MacPerl Module Porters Page 
(http://dev.macperl.org/mmp/). As with every module, use Chris Nandor's B<installme.plx> droplet for installation. This 
installer is part of the cpan-mac-0.50 module, available from CPAN (http://www.perl.com/CPAN-local/authors/id/CNANDOR/) 
or via Chris Nandor's MacPerl page: http://pudge.net/macperl/.

After you've installed the DBI module, simply drop the packed archive C<DBD-DtfSQLmac-0.3201.tar.gz> or the
unpacked folder C<DBD-DtfSQLmac-0.3201> on the installme.plx droplet. Answer the upcoming question "Convert 
all text and MacBinary files?" with "Yes". This should install the module properly. 

Afterwards, you have to install the dtF/SQL 2.01 shared library 'dtFPPCSV2.8K.shlb'
by hand. The dtF/SQL 2.01 shared library comes with the distribution that you have
to download from sLAB's web site (see the README document or DtfSQL.pm for details).
Either put the 'dtFPPCSV2.8K.shlb' shared library (or at least an alias to it) in 
the SAME folder as the shared library 'DtfSQL' that comes with this module (by 
default, this folder is ':site_perl:MacPPC:auto:Mac:DtfSQL:) or put the dtF/SQL 2.01 
shared library in the System Extensions folder. This is crucial since this module 
can only be used in conjunction with the dtF/SQL 2.01 shared library.

To be sure that everything is ok and the module loads properly, run the test.pl script 
first. Then run the test scripts located in the 't' folder. Some samples are provided 
in the 'samples' folder, to help you getting started.

More details may be found in the INSTALL.5004 document.

=head2 Installation for MacPerl 5.6.1 (and higher)

Always install the the DBI module first. The pre-built DBI module (version 1.21 as of this writing) 
for MacPerl 5.6.1 is available via the MacPerl Module Porters page (http://dev.macperl.org/mmp/). 
As with every module, use the installme.plx droplet for installation. This droplet is part of 
the MacPerl 5.6.1 distribution. 

After you've installed the DBI module, simply drop the DBD-DtfSQLmac-0.3201.tar.gz 
packed archive or the unpacked folder DBD-DtfSQLmac-0.3201 on the installme.plx 
droplet. Answer the upcoming question "Convert all text and MacBinary files?" with 
"Yes". This should install the module properly. 

Afterwards, you have to install the dtF/SQL 2.01 shared library 'dtFPPCSV2.8K.shlb'
by hand. The dtF/SQL 2.01 shared library comes with the distribution that you have
to download from sLAB's web site (see the README document or DtfSQL.pm for details).
Either put the 'dtFPPCSV2.8K.shlb' shared library (or at least an alias to it) in 
the SAME folder as the shared library 'DtfSQL' that comes with this module (by 
default, this folder is ':site_perl:MacPPC:auto:Mac:DtfSQL:) or put the dtF/SQL 2.01 
shared library in the System Extensions folder. This is crucial since this module 
can only be used in conjunction with the dtF/SQL 2.01 shared library.

To be sure that everything is ok and the module loads properly, run the test.pl script 
first. Then run the test scripts located in the 't' folder. Some samples are provided 
in the 'samples' folder, to help you getting started.

More details may be found in the INSTALL.561 document.


=head1 MEMORY REQUIREMENTS

 A minimum of 10MB / 11MB of RAM assigned to the MacPerl 5.2.0r4 / 5.6.1 application.
 A minimum of 11MB / 12MB of RAM assigned to the MPW Shell for running the MacPerl 5.2.0r4 / 5.6.1 tool.

This module requires quite a bit of RAM, as noted above. These values were determined by running the DBI test suite 
that comes with this module. They should be regarded as the absolute minimum. The MacPerl 5.6.1 application and tool 
will need at least 1MB more RAM than the MacPerl 5.2.0r4 application and tool. However, as your database grows, be 
prepared to assign more memory to MacPerl. If the memory assigned is less than the minimum, the MacPerl application 
or tool may crash during connection. Otherwise, the MacPerl application and the tool usually report an "out of memory!" 
or a "Can't connect as user X" error. However, if you get such an out of memory error, it's better to quit the 
corresponding application (and assign more RAM to it). If you try to run another script, you can crash your computer.


=head1 CREATE AND DROP A DATABASE

The following is quoted from the DBI FAQ:

=over 0

" 5.5 How can I create or drop a database with DBI?

Database creation and deletion are concepts that are entirely too abstract to be adequately supported by DBI. 
For example, Oracle does not support the concept of dropping a database at all! Also, in Oracle, the database 
server essentially is the database, whereas in mSQL, the server process runs happily without any databases created 
in it. The problem is too disparate to attack in a worthwhile way.

Some drivers, therefore, support database creation and deletion through the private func() methods. You should 
check the documentation for the drivers you are using to see if they support this mechanism. "

=back

The DtfSQLmac driver does not have a dedicated method for creation and deletion of a database. Either use the 
dtfAdmin tool (PPC only) to create an (empty) database or use the C<createSampleDB.pl> script as a template for 
your own database creation script. It's not a great challenge (see also the documentation of the Mac::DtfSQL 
module). To delete a database, simply drop it into the trash.


=head1 LIMITATIONS OF THE DATABASE ENGINE

See the dtF/SQL (KNOWN) LIMITATIONS section in the Mac::DtfSQL module documentation for limitations of 
the dtF/SQL database engine.


=head1 THE DBI CLASS 

=head2 DBI Class Methods 

=over 4

=item B<connect>    

 $dsn = "dbi:DtfSQLmac:SampleDB.dtf";
 $dbh = DBI->connect( $dsn, 
                      'dtfadm', 
                      'dtfadm', 
                      {RaiseError => 1, AutoCommit => 0} 
                    ) || die "Can't connect to database: " . DBI->errstr;

Generally, works as expected. Please note that the DtfSQLmac driver is limited to one connection at  
a time. You will get an error message, if you try to establish a second connection to the B<same> or 
B<another> database.

The AutoCommit and PrintError attributes for each connection default to on (see below and in the DBI.pm pod
for more information regarding the AutoCommit and PrintError attributes). However, it is B<strongly recommended> 
that AutoCommit is explicitly defined as required rather than rely on the default. Future versions of the DBI 
may issue a warning if AutoCommit is not explicitly defined.

=item B<data_sources>

 @ary = DBI->data_sources('DtfSQLmac');

Returns a list of all data sources (databases) available via the DtfSQLmac driver. The search for
dtF/SQL databases starts in the B<current working directory> and will recursively step down the 
directory tree. Use the C<chdir> function to set the directory you want to start with. The default 
working directory is determined according to the following rules: 
 
The current working directory for a script on the Mac is the location of the MacPerl application, if  
the running script has not been saved yet. If the script is saved to disk, then the current directory 
is the location of that script.  Unless you are using the MPW perl tool, in which case the current 
directory is the directory you are currently in with the MPW shell. Use the C<cwd()> function exported
by the Cwd.pm module to figure out what the current working directory is:
 
    use Cwd;
    $curdir = cwd(); # full path to the current working directory
    
All files of type 'DTFD' with creator 'dtF=' will be recognized as dtF/SQL database files.


=item B<trace,>

=item B<available_drivers>

Work as expected.

S< >

=back

=head2 DBI Utility Functions 

=over 4

=item B<neat,>

=item B<neat_list,>

=item B<looks_like_number>

Work as expected.

S< >

=back

=head2 DBI Dynamic Attributes

=over 4

=item B<$DBI::err,>

=item B<$DBI::errstr,>

=item B<$DBI::state,>

=item B<$DBI::rows>

Work as expected.

S< >

=back

=head1 METHODS COMMON TO ALL HANDLES 

=over 4

=item B<err,>


=item B<errstr,>

=item B<state,>

=item B<trace,>

=item B<trace_msg>

Work as expected.

=item B<func>

Generally, works as expected. The only additional driver specific method (i.e. non-portable) you 
are able to call is the B<table_col_info> method. It works on a database handle, thus you have to 
call C<func> as a method for a valid database handle $dbh. It allows you to retrieve metadata about 
a table's columns. Pass it a table name as an argument:
 
    %resulthash = $dbh->func($tablename, 'table_col_info');
 
The C<table_col_info> prototype could be declared as follows:
 
S<    >B<%resulthash = table_col_info ($tablename);>
 

C<table_col_info> retrieves metadata about a table's columns, i.e. for each column its name, its type 
(a DBI SQL type number), its type as string (as declared in CREATE TABLE), its position (starting 
with 0), its nullable attribute (0 or 1, where 0 means NOT nullable) and the column's comment are 
retrieved.
 
The result is returned as a hash, where the key is the column name and the value is a reference to
an array holding the type, type as string, position, nullable and comment information:
 
    %resulthash = (
                    columnname_0 => [$DBI_type, 'type as string', $position, $nullable, 'comment'],
                    ..
                    columnname_n => [$DBI_type, 'type as string', $position, $nullable, 'comment'],
    );
 
If you use the keys function to get at all column names, don't rely on their order to determine the
column's position; always use the array's position element ( $resulthash{$columnname}->[2] ). If the
table doesn't exist, an empty hash is returned (but no error is raised).
 
S< >

=back


=head1 ATTRIBUTES COMMON TO ALL HANDLES

This section describes attributes common to all handles. 
    
Example:

    $h->{AttributeName} = ...;    # set/write
    ... = $h->{AttributeName};    # get/read

The following attributes are handled by DBI itself and not by DBD::DtfSQLmac, thus they all should  
work like expected:

=over 4

=item B<Warn> (boolean, inherited) ,

=item B<Kids> (integer, read-only) ,

=item B<ActiveKids> (integer, read-only) ,

=item B<CachedKids> (hash ref) ,

=item B<CompatMode> (boolean, inherited) ,

=item B<InactiveDestroy> (boolean) ,    *Not used by DBD::DtfSQLmac*

=item B<PrintError> (boolean, inherited) ,

=item B<RaiseError> (boolean, inherited) ,

=item B<ChopBlanks> (boolean, inherited) ,

=item B<LongReadLen> (unsigned integer, inherited) ,    *Not supported by DBD::DtfSQLmac*

=item B<LongTruncOk> (boolean, inherited) ,    *Not supported by DBD::DtfSQLmac*

=item B<Taint> (boolean, inherited) 

=back

The following common DBI attribute is handled by DBD::DtfSQLmac and works as expected:

=over 4 


=item B<Active> (boolean, read-only)
 
S< >

=back

=head1 DBI DATABASE HANDLE OBJECTS 

=head2 Database Handle Methods 

=over 4

=item B<selectrow_array,>   

=item B<selectall_arrayref>

Work as expected.


=item B<prepare>    

    $sth = $dbh->prepare($statement)   || die $dbh->errstr;

Generally, works as expected. However, the dtF/SQL database engine doesn't support the concept of prepared 
statements. This is nothing you have to worry about, as the DtfSQLmac driver does a fairly good job on emulating 
this concept. But you should B<keep in mind> that the DtfSQLmac driver is unable to give much useful information 
about a statement, such as $sth->{NUM_OF_FIELDS}, until after $sth->execute has been called.

=item B<prepare_cached,>    

=item B<do,>    

=item B<commit,>    
 
=item B<rollback,>  

=item B<disconnect,>    

=item B<ping>   

Work as expected. 

=item B<table_info>

Not supported.

=item B<tables> 

    @usertables = $dbh->tables;
    
The I<tables> method returns the names of all usertables. Views are not supported by the dtF/SQL database engine.
Note that the five system tables C<ddrel>, C<ddfield>, C<dduser>, C<ddindex> and C<ddfkey> are B<not> included in 
this list.

=item B<type_info_all,>

=item B<type_info>

Work as expected. See the discussion of supported datatypes in the Statement Handle Attributes section.

=item B<quote>  

    $sql = $dbh->quote($value);
    $sql = $dbh->quote($value, $data_type);

Generally, works as expected. dtF/SQL's quote character for string/character datatype values is the single quotation 
mark "'". Thus,

    $dbh->quote("Don't");

would return C<'Don''t'> (including the outer quotation marks).

S< >

=back

=head2 Database Handle Attributes

This section describes attributes specific to database handles.

Example:

    $dbh->{AutoCommit} = ...;       # set/write
    ... = $dbh->{AutoCommit};       # get/read

=over 4 

=item B<AutoCommit>  (boolean)

dtF/SQL supports transactions as units of work, i.e. a transaction is always active. (To be precise, you can abort
a transaction, but the next SQL statement implicitly starts a new transaction, while the BEGIN TRANSACTION statement 
explicitly starts a transaction -- see the SQL Reference.) Transactions consist of an 
arbitrary number of database requests, regardless of their complexity. dtF/SQL ensures that all operations within 
a transaction are performed successfully, or not at all. With this transaction concept you can guarantee data 
integrity and consistency. Internally, only one transaction per client is allowed at a time, i.e. a client 
application cannot nest transactions.

If the AutoCommit attribute is true, then database changes cannot be rolled-back (undone). If false then database 
changes automatically occur within a 'transaction' which must either be committed or rolled-back using the commit or 
rollback methods.

According to the DBI convention, the DtfSQLmac driver defaults to AutoCommit mode true (or on if you like).

B<Important note:> Changing the AutoCommit attribute from off to on will issue a commit, i.e. all outstanding changes 
will implicitely be committed (made permanent) and cannot be rolled-back (undone) afterwards. B<Be careful with this
feature.> You might want to do a rollback before changing the AutoCommit mode! Changing AutoCommit from on to off has 
no immediate effect.

The AutoCommit attribute is discussed in greater detail in the DBI.pm pod.

=item B<Driver>  (handle),  

=item B<Name>  (string) 

Work as expected.

=item B<RowCacheSize>  (integer)    

Not supported.

=item B<dtf_commit_on_disconnect> (boolean)

C<dtf_commit_on_disconnect> is a B<private> driver database handle attribute (as indicated by the starting 
phrase dtf_). It specifies the commit behavior when you disconnect from a database. The DBI spec complains, 
that the transaction behavior of the disconnect method is undefined for most databases (see the documentation
for the disconnect method in the DBI module). With the C<dtf_commit_on_disconnect> attribute, you are able to 
make this behavior explicit for the DtfSQLmac driver: 0 means no commit on disconnect, while 1 means the 
opposite. You can either supply the attribute's setting as part of the data source name (separated by a semicolon), 
e.g.

    $dsn = "dbi:DtfSQLmac:SampleDB.dtf;dtf_commit_on_disconnect=1";
    
or, after you've created a database handle $dbh, set its value as usual with

    $dbh->{dtf_commit_on_disconnect} = 1;

The default value is 0, that is, no automatic commit on disconnect. Don't mistake this attribute with the I<AutoCommit>
attribute, which specifies whether (or not) B<each statement> should automatically be committed.

S< >

=back
        

=head1 DBI STATEMENT HANDLE OBJECTS 


=head2 Statement Handle Methods
 
=over 4

=item B<bind_param>

    $rc = $sth->bind_param($p_num, $bind_value)  || die $sth->errstr;
    $rv = $sth->bind_param($p_num, $bind_value, \%attr)     || ...
    $rv = $sth->bind_param($p_num, $bind_value, $bind_type) || ...

Generally, works as expected. The bind_param method can be used to bind (assign/associate) a value with a placeholder
embedded in the prepared statement. Placeholders are indicated with the question mark character (?). For example:

   $sth = $dbh->prepare("SELECT firstname, lastname FROM clients WHERE firstname = ?");
   $sth->bind_param(1, "Thomas", SQL_VARCHAR);  # placeholders are numbered from 1
   $sth->execute;


B<Note> that the ? is B<not> enclosed in quotation marks even when the placeholder represents a string. Every question
mark enclosed in single quotes will not be recognized as a placeholder by the DtfSQLmac driver. This allows you to insert
string data that may contain a question mark. 

B<Note> also that you should B<not> quote the actual value that you intend to bind to the placeholder, since that's 
done internally by the driver. E.g. don't make a call like

    $sth->execute($dbh->quote($firstname)); # don't do that !

[ Side-note: Due to the dtF/SQL quoting rules, where a single quotation mark must be doubled if you want 
to insert it as data (e.g. don't must be quoted as 'don''t'), a valid SQL statement has an B<even> number 
of single quotes (or pairs of quotes, if you like). The execute method will check this and raise an error, 
if the quotes don't occur in pairs. ]

Undefined bind values or undef are be used to indicate NULL values.

The third parameter can be used to hint at the data type the placeholder should have. Either use

    $sth->bind_param(1, $value, { TYPE => SQL_INTEGER });
or 
    $sth->bind_param(1, $value, SQL_INTEGER); 
    
as a short-cut.

The DtfSQLmac driver is only interested in knowing if the placeholder should be bound as a number or a string. It's
sufficient if you either pass SQL_VARCHAR for string types or SQL_INTEGER for numeric types to bind_param (but you 
are not restricted to these two, see below). After the first call of bind_param, the type hint for that particular 
placeholder is "frozen", i.e. all subsequent calls to bind_param could be made without a type hint for that placeholder.
If the type hint is provided again, it will be ignored. In other words, you cannot change the type hint of a parameter
after the first call to bind_param (but it can be left unspecified, in which case it defaults to the previous value).
If your first call to bind_param for a particular placeholder has no type hint, SQL_VARCHAR is assumed as a default 
and cannot be changed afterwards. This may or may not be what you wanted, so be careful. Please note that the undef 
value, which indicates a NULL value, is compatible with every type. All undef values will be bound as the string NULL,
without quotation marks, even if the type is a string type (SQL_VARCHAR). 

Don't abuse placeholders for any element of a SQL statement that is not associated with a table's field, 
i.e. don't use a placeholder for a table name, column name, SQL-clause etc. A placeholder should always be treated 
as a column-parameter that has a column's data type (for which you then can provide the actual data). However, the 
DtfSQLmac driver doesn't prevent you from doing weird things with placeholders. But your code will probably fail with
other drivers, i.e. your code will not be portable.   


B<Data Types for Placeholders>

The TYPE value you provide to bind_param indicates a standard (non-driver-specific) type for this parameter. The 
DtfSQLmac driver supports the following ten DBI SQL type constants:

    SQL_TINYINT     (numeric) 
    SQL_SMALLINT    (numeric)  
    SQL_INTEGER     (numeric)  
    SQL_DOUBLE      (numeric)  
    SQL_DECIMAL     (numeric)  
    SQL_CHAR        (string type)
    SQL_VARCHAR     (string type)
    SQL_DATE        (string type) 
    SQL_TIME        (string type) 
    SQL_TIMESTAMP   (string type)

While the four following defined DBI SQL type numbers

    SQL_LONGVARCHAR -> SQL_VARCHAR
    SQL_NUMERIC     -> SQL_DECIMAL
    SQL_FLOAT       -> SQL_DOUBLE
    SQL_REAL        -> SQL_DOUBLE

will be mapped to their nearest corresponding DBI SQL type constant as shown, the three (as of DBI 1.08) binary 
data types (blob)

    SQL_BINARY
    SQL_VARBINARY
    SQL_LONGVARBINARY 
    
and 

    SQL_BIGINT (omitted/deprecated as of DBI 1.21)
	
are not supported at all. (Note that SQL_BIGINT was formerly mapped to SQL_INTEGER, but beginning with version
0.3201 of this module this mapping is no longer provided, since DBI 1.21 omitted SQL_BIGINT.) Likewise, B<any 
other> DBI SQL type constant found in more recent versions of the DBI module are not supported at all. You 
will get an error message if you specify one of these constants.

B<Please note:> With the DtfSQLmac driver, we always retrieve field values as string. This is done even for field values that have
a decimal (fixed point number) data type, although the underlying Mac::DtfSQL module allows the retrieval as decimal 
object for these fields (see the Mac::DtfSQL module documentation for details). Thus, all data you may retrieve from
the database is a scalar in Perl. These scalars will contain either numbers or strings. In general, conversion from 
one form to another is transparent, i.e. happens automatically in Perl. Generally, if a string represents a decimal, 
it is converted to a scalar holding a floating point number in arithmetical operations. Due to this conversion the 
accuracy may suffer. However, in order to avoid this, you are able to create a decimal object, assign it a value 
from a string that represents a decimal, perform arithmetical operations with it and then store it back to the 
database (see the C<dbi_6_update-decimal.pl> sample script).

See also the section on Placeholders and Bind Values in the DBI documentation for more information. 

=item B<bind_param_inout>   

Not supported.

=item B<execute,>

=item B<fetchrow_arrayref,> 

=item B<fetchrow_array,>    

=item B<fetchrow_hashref,>  

=item B<fetchall_arrayref,> 

=item B<finish> 

Work as expected.

=item B<rows>   

    $rv = $sth->rows;

Returns the number of rows affected by the last executed statement. 

Returns -1, if the statement is not a row affecting statement, for example a create, drop, grant, and revoke 
statement. If the statement was of a modifying kind (insert, update, delete statements), the number of affected 
records is returned. For select statements, the number of rows in the result set will be returned. You can always
rely on the returned row count information, as the dtF/SQL database engine is able to return valid values even 
for select statements.

=item B<bind_columns,>  

=item B<dump_results>   

Work as expected.

S< >

=back


=head2 Statement Handle Attributes

This section describes attributes specific to statement handles. Most of these attributes are read-only.

Example:

    ... = $sth->{NUM_OF_FIELDS};      # get/read

Note that the DtfSQLmac driver cannot provide valid values for most of the attributes until after 
$sth->execute has been called (except for the NUM_OF_PARAMS attribute, which is valid after $sth = $dbh->prepare). 


=over 4


=item B<NUM_OF_PARAMS>  (integer, read-only)    *Valid after prepare*

The number of parameters (placeholders) in the prepared statement. 


=item B<NUM_OF_FIELDS>  (integer, read-only)    *Valid after execute*   

Number of fields (columns) the prepared statement will return. Non-select statements will have NUM_OF_FIELDS == 0.


=item B<NAME>  (array-ref, read-only)    *Valid after execute*     

Returns a reference to an array of field names for each result set's column. The names may contain spaces but should 
not be truncated or have any trailing space. Note that the names have the letter case (upper, lower or mixed) as 
defined in the CREATE TABLE statement. Portable applications should use NAME_lc or NAME_uc.

    print "First column name: $sth->{NAME}->[0]\n";

Undef for non-select statements.


=item B<NAME_lc>  (array-ref, read-only)    *Valid after execute*  

Like NAME in the  manpage but always returns lowercase names. 


=item B<NAME_uc>  (array-ref, read-only)    *Valid after execute*

Like NAME in the  manpage but always returns uppercase names. 


=item B<dtf_table>  (array-ref, read-only) *Valid after execute

This is a B<private> driver statement handle attribute (as indicated by the starting phrase dtf_). As a convenience
for the user, it returns a reference to an array of corresponding table names for each result set's column. Thus, 
for each field name in the NAME array, you can easily determine the table name this particular column/field belongs 
to. 


=item B<TYPE>  (array-ref, read-only)   *Valid after execute*

Returns a reference to an array of integer values for each result set's column. The value indicates the data type 
of the corresponding column. Note that the binary data type (blob -- binary large objects) is not supported. Returns
undef for non-select statements.

The DtfSQLmac driver internally uses the following ten DBI SQL type constants:

    SQL_TINYINT        (= -6)
    SQL_SMALLINT       (=  5)
    SQL_INTEGER        (=  4) 
    SQL_DOUBLE         (=  8) 
    SQL_DECIMAL        (=  3)
    SQL_CHAR           (=  1)
    SQL_VARCHAR        (= 12) 
    SQL_DATE           (=  9)
    SQL_TIME           (= 10) 
    SQL_TIMESTAMP      (= 11)
    
Run the C<dbi_108_types.pl> script (part of the distribution) to get a complete list of all DBI 1.08 SQL type numbers.

All possible dtF/SQL types as used in a CREATE TABLE statement are mapped to the standard DBI SQL type numbers as 
shown in the following table.


    DBI SQL type const |   dtF/SQL type *              |   dtF/SQL internal C type 
 ----------------------+-------------------------------+-----------------------------------------
    SQL_TINYINT        |   CHAR (numeric) **           |   char (1 byte)   
    SQL_TINYINT        |   BYTE                        |   unsigned char (1 byte) 
                       |                               |
    SQL_SMALLINT       |   SMALLINT or SHORT           |   short (2 byte),    
    SQL_SMALLINT       |   WORD                        |   unsigned short (2 byte)
                       |                               |
    SQL_INTEGER        |   INTEGER or INT or LONG      |   int, long (4 byte signed)    
    SQL_INTEGER        |   LONGWORD                    |   unsigned long (4 byte unsigned)
                       |                               |
    SQL_DOUBLE         |   REAL                        |   double
    SQL_DOUBLE         |   FLOAT                       |   double 
    SQL_DOUBLE         |   DOUBLE                      |   double 
                       |                               | 
    SQL_DECIMAL        |   DECIMAL(precision,scale) or |   DTFDECIMAL 
                       |   DEC(p,s) or NUMERIC(p,s)    | 
                       |                               |
    SQL_CHAR           |   CHAR(x) ** or CHARACTER(x)  |   String max. 4095 characters
                       |   (fixed length)              |   + \0 (Nul char)        
                       |                               | 
    SQL_VARCHAR        |   SHORTSTRING or VARCHAR(x)   |   String max. 4095 characters
                       |   or CHAR VARYING(x)          |   + \0 (Nul char)
                       |                               | 
    SQL_DATE           |   DATE                        |   String: yyyy-mm-dd or yyyy/mm/dd
    SQL_TIME           |   TIME                        |   String: hh:mm:ss[.fff] (24 hour) *** 
    SQL_TIMESTAMP      |   TIMESTAMP                   |   String: yyyy-mm-dd hh:mm:ss[.fff] ***
                       |                               |
    SQL_BINARY         |   BIT   (not supported)       |   char[]   (not supported) 
    SQL_VARBINARY      |   BIT   (not supported)       |   char[]   (not supported) 
    SQL_LONGVARBINARY  |   BIT   (not supported)       |   char[]   (not supported) 


 *   As used in a CREATE TABLE statement
 **  Note: While CHAR means a numeric data type (signed byte), CHAR(x) means a character string 
     of some fixed length x. Internally, 'CHAR(' is used to denote a string/character data type.
 *** with optional second fractions

    
Note that in some cases two or more dtF/SQL types are mapped to the same DBI SQL type constant (e.g. the CHAR 
and BYTE numeric types are both mapped to SQL_TINYINT). This is not an error, as the DBI specification 
explicitely allows type I<variants>, for example a signed or unsigned variant (see the documentation for the 
C<type_info()> method). Thus, all possible values for TYPE have at least one entry in the output of the 
C<type_info_all()> method. 

Undef for non-select statements.


=item B<PRECISION>  (array-ref, read-only)    *Valid after execute*

Returns a reference to an array of integer values for each result set's column. Depending on the TYPE of the column, 
the following values are returned:

    SQL_TINYINT:    precision is 3, and the display width should be 4 (for the sign) 
 
    SQL_SMALLINT:   precision is 5, and the display width should be 6 (for the sign)

    SQL_INTEGER:    precision is 10, and the display width should be 11 (for the sign) 

    SQL_DOUBLE:     precision is 15, and the display width should be 22 (for the sign + decimal 
                    point + the letter E + a sign + 2 or 3 digits)
 
    SQL_DECIMAL:    precision is the precision as declared in the type definition of the CREATE 
                    TABLE statement, and the display width should be precision + 2 (for the 
                    sign + decimal point) 

    SQL_CHAR:       precision is the max. length as declared in the type definition of the CREATE
                    TABLE statement, and the display width should be the same                    
                    
    SQL_VARCHAR:    precision is the max. length as declared in the type definition of the CREATE
                    TABLE statement or 4095 if you've used the SHORTSTRING type, and the display 
                    width should be the same 
                      
    SQL_DATE:       precision is 10, and the display width should be the same (yyyy-mm-dd)

    SQL_TIME:       precision is 12, and the display width should be the same (hh:mm:ss[.fff]) 
 
    SQL_TIMESTAMP:  precision is 23, and the display width should be the same 
                    (yyyy-mm-dd hh:mm:ss[.fff]) 


=item B<SCALE>  (array-ref, read-only)    <Valid after execute>     

Returns a reference to an array of integer values for each column. Actually, scale is only valid when the TYPE is
a decimal (SQL_DECIMAL). For all other data types, an undef value is returned (to indicate that scale is not 
applicable). 

Undef for non-select statements.

=item B<NULLABLE>  (array-ref, read-only)    <Valid after execute>

Works as expected. Returns a reference to an array indicating the possibility of each column returning a 
null: 0 = no (i.e. declared as NOT NULL or PRIMARY KEY), 1 = yes, 2 = unknown.

Undef for non-select statements.

=item B<CursorName>  (string, read-only)    

Not supported.

=item B<Statement>  (string, read-only) 

Returns the statement string passed to the C<$dbh-E<gt>prepare> method. 

=item B<RowsInCache>  (integer, read-only)

Not supported.


S< >

=back

 

=head1 KNOWN BUGS

No known bugs. Please report bugs to the author.



=head1 AUTHOR AND COPYRIGHT

=over 0

Thomas Wegner    t_wegner@gmx.net

=back

Copyright (c) 2000-2002 Thomas Wegner. All rights reserved. This program is
free software. You may redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.



=head1 SEE ALSO

DBI, Mac::DtfSQL, The dtF/SQL 2.01 documentation: Introduction.pdf, C/C++/Java Reference.pdf, Programmer's Manual.pdf
and SQL Reference.pdf

For general DBI information and questions, see the DBI home page at

    http://dbi.perl.org/


=cut
