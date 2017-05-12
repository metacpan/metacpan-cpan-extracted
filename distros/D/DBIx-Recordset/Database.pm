
###################################################################################
#
#   DBIx::Recordset - Copyright (c) 1997-2000 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS IS BETA SOFTWARE!
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Database.pm,v 1.18 2001/07/09 19:59:48 richter Exp $
#
###################################################################################


package DBIx::Database::Base ;

use strict 'vars' ;

use vars qw{$LastErr $LastErrstr *LastErr *LastErrstr *LastError $PreserveCase} ;

*LastErr        = \$DBIx::Recordset::LastErr ;
*LastErrstr     = \$DBIx::Recordset::LastErrstr ;
*LastError      = \&DBIx::Recordset::LastError ;
*PreserveCase   = \$DBIx::Recordset::PreserveCase;


use Carp qw(confess);

use File::Spec ;
use DBIx::Recordset ;
use Text::ParseWords ;


## ----------------------------------------------------------------------------
##
## savecroak
##
## croaks and save error
##


sub savecroak

    {
    my ($self, $msg, $code) = @_ ;

    $LastErr	= $self->{'*LastErr'}	    = $code || $dbi::err || -1 ;
    $LastErrstr = $self->{'*LastErrstr'}    = $msg || $DBI::errstr || ("croak from " . caller) ;

    #$Carp::extra = 1 ;
    #Carp::croak $msg ;
    confess($msg);
    }

## ----------------------------------------------------------------------------
##
## DoOnConnect
##
## in $cmd  sql cmds
##

sub DoOnConnect

    {
    my ($self, $cmd) = @_ ;
    
    if ($cmd)
        {
        if (ref ($cmd) eq 'ARRAY')
            {
            foreach (@$cmd)
                {
                $self -> do ($_) ;
                }
            }
        elsif (ref ($cmd) eq 'HASH')
            {
            $self -> DoOnConnect ($cmd -> {'*'}) ;
            $self -> DoOnConnect ($cmd -> {$self -> {'*Driver'}}) ;
            }
        else
            {
            $self -> do ($cmd) ;
            }
        }
    }
  

## ----------------------------------------------------------------------------
##
## DBHdl
##
## return DBI database handle
##

sub DBHdl ($)

    {
    return $_[0] -> {'*DBHdl'} ;
    }


## ----------------------------------------------------------------------------
##
## do an non select statement 
##
## $statement = statement to do
## \%attr     = attribs (optional)
## @bind_valus= values to bind (optional)
## or 
## \@bind_valus= values to bind (optional)
## \@bind_types  = data types of bind_values
##

sub do($$;$$$)

    {
    my($self, $statement, $attribs, @params) = @_;
    
    $self -> {'*LastSQLStatement'} = $statement ;

    my $ret ;
    my $bval ;
    my $btype ;
    my $dbh ;
    my $sth ;

    if (@params > 1 && ref ($bval = $params[0]) eq 'ARRAY' && ref ($btype = $params[1]) eq 'ARRAY')
        {
        if ($self->{'*Debug'} > 1) { local $^W = 0 ; print DBIx::Recordset::LOG "DB:  do '$statement' bind_values=<@$bval> bind_types=<@$btype>\n" } ;
        $dbh = $self->{'*DBHdl'} ;
        $sth = $dbh -> prepare ($statement, $attribs) ;
        my $Numeric = $self->{'*NumericTypes'} || {} ;
        local $^W = 0 ; # avoid warnings
        if (defined ($sth))
            {
            for (my $i = 0 ; $i < @$bval; $i++)
                {
                $bval -> [$i] += 0 if (defined ($bval -> [$i]) && defined ($btype -> [$i]) && $Numeric -> {$btype -> [$i]}) ;
                #$sth -> bind_param ($i+1, $bval -> [$i], $btype -> [$i]) ;
                #$sth -> bind_param ($i+1, $bval -> [$i], $btype -> [$i] == DBI::SQL_CHAR()?DBI::SQL_CHAR():undef ) ;
		my $bt = $btype -> [$i] ;
                $sth -> bind_param ($i+1, $bval -> [$i], (defined ($bt) && $bt <= DBI::SQL_CHAR())?{TYPE=>$bt}:undef ) ;
                }
            $ret = $sth -> execute ;
            }
        }
    else
        {
        print DBIx::Recordset::LOG "DB:  do $statement <@params>\n" if ($self->{'*Debug'} > 1) ;
        
        $ret = $self->{'*DBHdl'} -> do ($statement, $attribs, @params) ;
        }

    print DBIx::Recordset::LOG "DB:  do returned " . (defined ($ret)?$ret:'<undef>') . "\n" if ($self->{'*Debug'} > 2) ;
    print DBIx::Recordset::LOG "DB:  ERROR $DBI::errstr\n"  if (!$ret && $self->{'*Debug'}) ;
    print DBIx::Recordset::LOG "DB:  in do $statement <@params>\n" if (!$ret && $self->{'*Debug'} == 1) ;

    $LastErr	= $self->{'*LastErr'}	    = $DBI::err ;
    $LastErrstr = $self->{'*LastErrstr'}    = $DBI::errstr ;
    
    return $ret ;
    }


## ----------------------------------------------------------------------------
##
## QueryMetaData
##
## $table        = table (multiple tables must be comma separated)
##


sub QueryMetaData($$)

    {
    my ($self, $table) = @_ ;
            
    $table = lc($table)  if (!$PreserveCase) ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//" . $table ;
    
    if (defined ($meta = $DBIx::Recordset::Metadata{$metakey})) 
        {
        print DBIx::Recordset::LOG "DB:   use cached meta data for $table\n" if ($self->{'*Debug'} > 2) ;
        return $meta 
        }

    my $hdl = $self->{'*DBHdl'} ;
    my $drv = $self->{'*Driver'} ;
    my $sth ;
    
    my $ListFields = DBIx::Compat::GetItem ($drv, 'ListFields') ;
    my $QuoteTypes = DBIx::Compat::GetItem ($drv, 'QuoteTypes') ;
    my $NumericTypes = DBIx::Compat::GetItem ($drv, 'NumericTypes') ;
    my $HaveTypes  = DBIx::Compat::GetItem ($drv, 'HaveTypes') ;
    #my @tabs = split (/\s*\,\s*/, $table) ;
    my @tabs = quotewords ('\s*,\s*', 1, $table) ;
    my $tab ;
    my $ltab ;
    my %Quote ;
    my %Numeric ;
    my @Names ;
    my @Types ;
    my @FullNames ;
    my %Table4Field ;
    my %Type4Field ;
    my $i ;

    foreach $tab (@tabs)

        {
        next if ($tab =~ /^\s*$/) ;
    
        eval {
            $sth = &{$ListFields}($hdl, $tab) or carp ("Cannot list fields for $tab ($DBI::errstr)") ;
            } ;
        next if ($@) ; # ignore any table for which we can't get fields

	if ($tab =~ /^"(.*?)"$/)
            { $ltab = $1 ; }
        else
            { $ltab = $tab ; }
	
        my $types ;
        my $fields = $sth?$sth -> FETCH ($PreserveCase?'NAME':'NAME_lc'):[]  ;
        my $num = $#{$fields} + 1 ;
    
        if ($HaveTypes && $sth)
            {
            #print DBIx::Recordset::LOG "DB: Have Types for driver\n" ;
            $types = $sth -> FETCH ('TYPE')  ;
            }
        else
            {
            #print DBIx::Recordset::LOG "DB: No Types for driver\n" ;
            # Drivers does not have fields types -> give him SQL_VARCHAR
            $types = [] ;
            for ($i = 0; $i < $num; $i++)
                { push @$types, DBI::SQL_VARCHAR (); }

            # Setup quoting for SQL_VARCHAR
            $QuoteTypes = { DBI::SQL_VARCHAR() => 1 } ;
            $NumericTypes = { } ;
            }
    
        push @Names, @$fields ;
        push @Types, @$types ;
        $i = 0 ;
        foreach (@$fields)
            {
	    $Table4Field{$_}         = $ltab ;        
            $Table4Field{"$ltab.$_"} = $ltab ;
            $Type4Field{"$_"}        = $types -> [$i] ;
            $Type4Field{"$ltab.$_"}  = $types -> [$i++] ;
            push @FullNames, "$ltab.$_"  ;
            }        

        $sth -> finish if ($sth) ;

        # Set up a hash which tells us which fields to quote and which not
        # We setup two versions, one with tablename and one without
        my $col ;
        my $fieldname ;
        for ($col = 0; $col < $num; $col++ )
            {
            if ($self->{'*Debug'} > 2)
                {
                my $n = $$fields[$col] ;
                my $t = $$types[$col] ;
                print DBIx::Recordset::LOG "DB: TAB = $tab, COL = $col, NAME = $n, TYPE = $t" ;
                }
            $fieldname = $$fields[$col] ;
            if ($$QuoteTypes{$$types[$col]})
                {
                #print DBIx::Recordset::LOG " -> quote\n" if ($self->{'*Debug'} > 2) ;
                $Quote {"$tab.$fieldname"} = 1 ;
                $Quote {"$fieldname"} = 1 ;
                }
            else
                {
                #print DBIx::Recordset::LOG "\n" if ($self->{'*Debug'} > 2) ;
                $Quote {"$tab.$fieldname"} = 0 ;
                $Quote {"$fieldname"} = 0 ;
                }
            if ($$NumericTypes{$$types[$col]})
                {
                print DBIx::Recordset::LOG " -> numeric\n" if ($self->{'*Debug'} > 2) ;
                $Numeric {"$tab.$fieldname"} = 1 ;
                $Numeric {"$fieldname"} = 1 ;
                }
            else
                {
                print DBIx::Recordset::LOG "\n" if ($self->{'*Debug'} > 2) ;
                $Numeric {"$tab.$fieldname"} = 0 ;
                $Numeric {"$fieldname"} = 0 ;
                }
            }
        print DBIx::Recordset::LOG "No Fields found for $tab\n" if ($num == 0 && $self->{'*Debug'} > 1) ;
        }

    print DBIx::Recordset::LOG "No Tables specified\n" if ($#tabs < 0 && $self->{'*Debug'} > 1) ;


    $meta = {} ;
    $meta->{'*Table4Field'}  = \%Table4Field ;
    $meta->{'*Type4Field'}   = \%Type4Field ;
    $meta->{'*FullNames'}    = \@FullNames ;
    $meta->{'*Names'}  = \@Names ;
    $meta->{'*Types'}  = \@Types ;
    $meta->{'*Quote'}  = \%Quote ;    
    $meta->{'*Numeric'}  = \%Numeric ;    
    $meta->{'*NumericTypes'}  = $NumericTypes ;    

    $DBIx::Recordset::Metadata{$metakey} = $meta ;
    

    if (!exists ($meta -> {'*Links'}))
        { 
        my $ltab ;
        my $lfield ;
        my $metakey ;
        my $subnames ;
        my $n ;

        $meta -> {'*Links'} = {} ;

        my $metakeydsn = "$self->{'*DataSource'}//-" ;
        my $metakeydsntf = "$self->{'*DataSource'}//-"  . ($self->{'*TableFilter'}||'');
        my $metadsn    = $DBIx::Recordset::Metadata{$metakeydsn} || {} ;
        my $tabmetadsn = $DBIx::Recordset::Metadata{$metakeydsntf} || {} ;
        my $tables     = $tabmetadsn -> {'*Tables'} ;

        if (!$tables)
            { # Query the driver, which tables are available
            my $ListTables = DBIx::Compat::GetItem ($drv, 'ListTables') ;

	    if ($ListTables)
		{            
		my @tabs = &{$ListTables}($hdl) or $self -> savecroak ("Cannot list tables for $self->{'*DataSource'} ($DBI::errstr)") ;
		my @stab ;
		my $stab ;
                my $tabfilter = $self -> {'*TableFilter'} || '.' ;
                foreach (@tabs)
                    {
		    s/^[^a-zA-Z0-9_.]// ;
		    s/[^a-zA-Z0-9_.]$// ;
                    if ($_ =~ /(^|\.)$tabfilter/i)
                        {
                        @stab = split (/\./);
                        $stab = $PreserveCase?(pop @stab):lc (pop @stab) ;
                        $tables -> {$stab} =  $_ ;
                        }
                    }
		$tabmetadsn -> {'*Tables'} = $tables ;
		if ($self->{'*Debug'} > 3) 
		    {
		    my $t ;
		    foreach $t (keys %$tables)
			{ print DBIx::Recordset::LOG "DB:  Found table $t => $tables->{$t}\n" ; }
		    }
		}
	    else
		{
		$tabmetadsn -> {'*Tables'} = {} ;
		}
            
            $DBIx::Recordset::Metadata{$metakeydsn} = $metadsn ;
            $DBIx::Recordset::Metadata{"$metakeydsn$self->{'*TableFilter'}"} = $tabmetadsn if ($self->{'*TableFilter'}) ;
            }

	if ($#tabs <= 0)
	    {
	    my $fullname ;
            my $tabfilter = $self -> {'*TableFilter'}  ;
	    my $fullltab ;
            my $tableshort = $table ;
            if ($tabfilter && ($table =~ /^$tabfilter(.*?)$/))
                {
                $tableshort     = $1 ;
                }
            foreach $fullname (@FullNames)
		{
		my ($ntab, $n) = split (/\./, $fullname) ;
		my $prefix = '' ;
                my $fullntab = $ntab ;
                
                if ($tabfilter && ($ntab =~ /^$tabfilter(.*?)$/))
                    {
                    $ntab     = $1 ;
                    }

		if ($n =~ /^(.*?)__(.*?)$/)
		    {
		    $prefix = "$1__" ;
		    $n = $2 ;
		    }

		my @part = split (/_/, $n) ;
		my $tf = $tabfilter || '' ;
                for (my $i = 0; $i < $#part; $i++)
		    {
		    $ltab   = join ('_', @part[0..$i]) ;
		    $lfield = join ('_', @part[$i + 1..$#part]) ;
            
		    next if (!$ltab) ;
                    
                    if (!$tables -> {$ltab} && $tables -> {"$tf$ltab"}) 
                        { $fullltab = "$tabfilter$ltab" }
                    else
                        { $fullltab = $ltab }

		    if ($tables -> {$fullltab}) 
			{
			$metakey = $self -> QueryMetaData ($fullltab) ;
			$subnames = $metakey -> {'*Names'} ;
			if (grep (/^$lfield$/i, @$subnames))
			    { # setup link
			    $meta -> {'*Links'}{"-$prefix$ltab"} = {'!Table' => $fullltab, '!LinkedField' => $lfield, '!MainField' => "$prefix$n", '!MainTable' => $fullntab} ;
			    print DBIx::Recordset::LOG "Link found for $ntab.$prefix$n to $ltab.$lfield\n" if ($self->{'*Debug'} > 2) ;
                        
			    #my $metakeyby    = "$self->{'*DataSource'}//$ltab" ;
			    #my $linkedby = $DBIx::Recordset::Metadata{$metakeyby} -> {'*Links'} ;
			    my $linkedby = $metakey -> {'*Links'} ;
			    my $linkedbyname = "\*$prefix$tableshort" ;
                            $linkedby -> {$linkedbyname} = {'!Table' => $fullntab, '!MainField' => $lfield, '!LinkedField' => "$prefix$n", '!LinkedBy' => $fullltab, '!MainTable' => $fullltab} ;
			    #$linkedby -> {"-$tableshort"} = $linkedby -> {$linkedbyname} if (!exists ($linkedby -> {"-$tableshort"})) ;
			    }
			last ;
			}
		    }
		}
	    }
    	else
	    { 
	    foreach $ltab (@tabs)
		{
                next if (!$ltab) ;
                $metakey = $self -> QueryMetaData ($ltab) ;

		my $k ;
		my $v ;
		my $lbtab ;
		my $links = $metakey -> {'*Links'} ;
		while (($k, $v) = each (%$links))
		    {
		    if (!$meta -> {'*Links'}{$k}) 
			{
			$meta -> {'*Links'}{$k} = { %$v } ;
    			print DBIx::Recordset::LOG "Link copied: $k\n" if ($self->{'*Debug'} > 2) ;
			}
		    
		    }
		}
	    }

	}


    return $meta ;
    }


###################################################################################

package DBIx::Database ;

use strict 'vars' ;

use vars (
    '%DBDefault',   # DB Shema default für alle Tabellen 
    '@DBSchema',     # DB Shema definition
    '$LastErr',
    '$LastErrstr',
    '*LastErr',
    '*LastErrstr',
    '*LastError',
    '$PreserveCase',
    '@ISA') ;

@ISA = ('DBIx::Database::Base') ;

*LastErr    = \$DBIx::Recordset::LastErr ;
*LastErrstr = \$DBIx::Recordset::LastErrstr ;
*LastError  = \&DBIx::Recordset::LastError ;
*PreserveCase  = \$DBIx::Recordset::PreserveCase;


use Carp ;

## ----------------------------------------------------------------------------
##
## connect
##

sub connect

    {
    my ($self, $password) = @_ ; 

    my $hdl = $self->{'*DBHdl'}  = DBI->connect($self->{'*DataSource'}, $self->{'*Username'}, $password, $self->{'*DBIAttr'}) or $self -> savecroak ("Cannot connect to $self->{'*DataSource'} ($DBI::errstr)") ;

    $LastErr    = $self->{'*LastErr'}	    = $DBI::err ;
    $LastErrstr = $self->{'*LastErrstr'}    = $DBI::errstr ;

    $self->{'*MainHdl'}    = 1 ;
    $self->{'*Driver'}     = $hdl->{Driver}->{Name} ;
    if ($self->{'*Driver'} eq 'Proxy')
	{
        $self->{'*DataSource'} =~ /dsn\s*=\s*dbi:(.*?):/i ;
	$self->{'*Driver'} = $1 ;
	print DBIx::Recordset::LOG "DB:  Found DBD::Proxy, take compability entrys for driver $self->{'*Driver'}\n" if ($self->{'*Debug'} > 1) ;
	}

    print DBIx::Recordset::LOG "DB:  Successfull connect to $self->{'*DataSource'} \n" if ($self->{'*Debug'} > 1) ;

    my $cmd ;
    if ($hdl && ($cmd = $self -> {'*DoOnConnect'}))
        {
        $self -> DoOnConnect ($cmd) ;
        }
  
    return $hdl ;
    }


## ----------------------------------------------------------------------------
##
## new
##
## creates a new DBIx::Database object. This object fetches all necessary
## meta information from the database for later use by DBIx::Recordset objects.
## Also it builds a list of links between the tables.
##
##
## $data_source  = Driver/DB/Host
## $username     = Username (optional)
## $password     = Password (optional) 
## \%attr        = Attributes (optional) 
## $saveas       = Name for this DBIx::Database object to save
##                 The name can be used in Get, or as !DataSource for DBIx::Recordset
## $keepopen     = keep connection open to use in further DBIx::Recordset setups
## $tabfilter    = regex which tables should be used
##

sub new

    {
    my ($class, $data_source, $username, $password, $attr, $saveas, $keepopen, $tabfilter, $doonconnect, $reconnect) = @_ ;
    
    if (ref ($data_source) eq 'HASH')
        {
        my $p = $data_source ;
        ($data_source, $username, $password, $attr, $saveas, $keepopen, $tabfilter, $doonconnect, $reconnect) = 
        @$p{('!DataSource', '!Username', '!Password', '!DBIAttr', '!SaveAs', '!KeepOpen', '!TableFilter', '!DoOnConnect', '!Reconnect')} ;
        }
            
    $LastErr	= undef ;
    $LastErrstr = undef ;
    
    my $metakey  ;
    my $self ;



    if (!($data_source =~ /^dbi:/i)) 
        {
        $metakey    = "-DATABASE//$1"  ;
        $self = $DBIx::Recordset::Metadata{$metakey} ;
        $self->{'*DBHdl'} = undef if ($reconnect) ;
        $self -> connect ($password) if ($keepopen && !defined ($self->{'*DBHdl'})) ;
        return $self ;
        }
    
    if ($saveas)
        {
        $metakey    = "-DATABASE//$saveas"  ;
        if (defined ($self = $DBIx::Recordset::Metadata{$metakey}))
            {
            $self->{'*DBHdl'} = undef if ($reconnect) ;
            $self -> connect ($password) if ($keepopen && !defined ($self->{'*DBHdl'})) ;
            return $self ;
            }
        }


    $self = {
                '*Debug'      => $DBIx::Recordset::Debug,
                '*DataSource' => $data_source,
                '*DBIAttr'    => $attr,
                '*Username'   => $username, 
                '*TableFilter' => $tabfilter, 
                '*DoOnConnect' => $doonconnect,
               } ;

    bless ($self, $class) ;

    my $hdl ;
    $self->{'*DBHdl'} = undef if ($reconnect) ;


    if (ref ($data_source) and eval { $data_source->isa('DBI::db') } )
      {

	  $self->{'*DBHdl'}      = $data_source;
      }
    else
      {

      }

    if (!defined ($self->{'*DBHdl'}))
        {
        $hdl = $self->connect ($password) ;
        }
    else
        {
        $LastErr	= $self->{'*LastErr'}   = undef ;
        $LastErrstr = $self->{'*LastErrstr'}    = undef ;
    
        $hdl = $self->{'*DBHdl'} ;
        print DBIx::Recordset::LOG "DB:  Use already open dbh for $self->{'*DataSource'}\n" if ($self->{'*Debug'} > 1) ;
        }
            
    $DBIx::Recordset::Metadata{"$self->{'*DataSource'}//*"} ||= {} ; # make sure default table is defined

    my $drv        = $self->{'*Driver'} ;
    my $metakeydsn = "$self->{'*DataSource'}//-" ;
    my $metakeydsntf = "$self->{'*DataSource'}//-"  . ($self->{'*TableFilter'}||'');
    my $metadsn    = $DBIx::Recordset::Metadata{$metakeydsn} || {} ;
    my $tabmetadsn = $DBIx::Recordset::Metadata{$metakeydsntf} || {} ;
    my $tables     = $tabmetadsn -> {'*Tables'} ;

    if (!$tables)
        { # Query the driver, which tables are available
        my $ListTables = DBIx::Compat::GetItem ($drv, 'ListTables') ;

        
        if ($ListTables)
	    {
	    my @tabs = &{$ListTables}($hdl) ; # or $self -> savecroak ("Cannot list tables for $self->{'*DataSource'} ($DBI::errstr)") ;
	    my @stab ;
	    my $stab ;

            $tabfilter ||= '.' ;
            foreach (@tabs)
                {
	        s/^[^a-zA-Z0-9_.]// ;
		s/[^a-zA-Z0-9_.]$// ;
                if ($_ =~ /(^|\.)$tabfilter/i)
                    {
                    @stab = split (/\./);
                    $stab = $PreserveCase?(pop @stab):lc (pop @stab) ;
                    $tables -> {$stab} =  $_ ;
                    }
                }
        
	    $tabmetadsn -> {'*Tables'} = $tables ;
	    if ($self->{'*Debug'} > 2) 
		{
		my $t ;
		foreach $t (keys %$tables)
		    { print DBIx::Recordset::LOG "DB:  Found table $t => $tables->{$t}\n" ; }
		}
	    }
	else    
	    {
	    $tabmetadsn -> {'*Tables'} = {} ;
	    }
            
        $DBIx::Recordset::Metadata{$metakeydsn} = $metadsn ;
        $DBIx::Recordset::Metadata{$metakeydsntf} = $tabmetadsn ;
        }

    my $tab ;
    my $x ;

    while (($tab, $x) = each (%{$tables}))
        {
        $self -> QueryMetaData ($tab) ;
        }

    
    $DBIx::Recordset::Metadata{$metakey} = $self if ($metakey) ;

    # disconnect in case we are running in a Apache/mod_perl startup file
    
    if (defined ($self->{'*DBHdl'}) && !$keepopen)
        {
        $self->{'*DBHdl'} -> disconnect () ;
        undef $self->{'*DBHdl'} ;
        print DBIx::Recordset::LOG "DB:  Disconnect from $self->{'*DataSource'} \n" if ($self->{'*Debug'} > 1) ;
        }
    
    return $self ;
    }


## ----------------------------------------------------------------------------
##
## Get
##
## $name = Name of DBIx::Database obecjt you what to get
##

sub Get

    {
    my ($class, $saveas) = @_ ;
    
    my $metakey  ;
    
    $metakey    = "-DATABASE//$saveas"  ;
    return $DBIx::Recordset::Metadata{$metakey} ;
    }


## ----------------------------------------------------------------------------
##
## TableAttr
##
## get and/or set and attribute for an specfic table
##
## $table = Name of table(s)
## $key   = key
## $value = value
##

sub TableAttr

    {
    my ($self, $table, $key, $value) = @_ ;

    $table = lc($table) if (!$PreserveCase) ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//$table" ;
    
    if (!defined ($meta = $DBIx::Recordset::Metadata{$metakey})) 
        {
        $self -> savecroak ("Unknown table $table in $self->{'*DataSource'}") ;
        }

    # set new value if wanted
    return $meta -> {$key} = $value if (defined ($value)) ;

    # only return value
    return $meta -> {$key} if (exists ($meta -> {$key})) ;

    # check if there is a default value
    $metakey    = "$self->{'*DataSource'}//*" ;
    
    return undef if (!defined ($meta = $DBIx::Recordset::Metadata{$metakey})) ;

    return $meta -> {$key} ;
    }


## ----------------------------------------------------------------------------
##
## TableLink
##
## get and/or set an link description for an table
##
## $table = Name of table(s)
## $key   = linkname
## $value = ref to hash with link description
##


sub TableLink

    {
    my ($self, $table, $key, $value) = @_ ;

    $table = lc($table)  if (!$PreserveCase) ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//$table" ;
    
    if (!defined ($meta = $DBIx::Recordset::Metadata{$metakey})) 
        {
        $self -> savecroak ("Unknown table $table in $self->{'*DataSource'}") ;
        }

    return $meta -> {'*Links'} if (!defined ($key)) ;

    return $meta -> {'*Links'} -> {$key} = $value if (defined ($value)) ;

    return $meta -> {'*Links'} -> {$key}  ;
    }


## ----------------------------------------------------------------------------
##
## MetaData
##
## get/set metadata for a given table
##
## $table     = Name of table
## $metadata  = meta data to set
##


sub MetaData

    {
    my ($self, $table, $metadata, $clear) = @_ ;

    $table = lc($table)  if (!$PreserveCase) ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//$table" ;
    
    if (!defined ($meta = $DBIx::Recordset::Metadata{$metakey})) 
        {
        $self -> savecroak ("Unknown table $table in $self->{'*DataSource'}") ;
        }

    return $meta if (!defined ($metadata) && !$clear) ;

    return $DBIx::Recordset::Metadata{$metakey} = $metadata ;
    }

## ----------------------------------------------------------------------------
##
## AllTables
##
## return reference to hash which keys contains all tables of that datasource
##

sub AllTables

    {
    my $self = shift ;
    my $metakeydsn = "$self->{'*DataSource'}//-" . ($self->{'*TableFilter'} || '') ;
    my $metadsn    = $DBIx::Recordset::Metadata{$metakeydsn} || {} ;
    return $metadsn -> {'*Tables'} ;
    }

## ----------------------------------------------------------------------------
##
## AllNames
##
## return reference to array of all names in all tables
##
## $table     = Name of table
##

sub AllNames

    {
    my ($self, $table) = @_ ;

    $table = lc($table)  if (!$PreserveCase) ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//$table" ;
    
    if (!defined ($meta = $DBIx::Recordset::Metadata{$metakey})) 
        {
        $self -> savecroak ("Unknown table $table in $self->{'*DataSource'}") ;
        }

    return $meta -> {'*Names'}  ;
    }

## ----------------------------------------------------------------------------
##
## AllTypes
##
## return reference to array of all types in all tables
##
## $table     = Name of table
##

sub AllTypes

    {
    my ($self, $table) = @_ ;

    $table = lc($table)  if (!$PreserveCase) ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//$table" ;
    
    if (!defined ($meta = $DBIx::Recordset::Metadata{$metakey})) 
        {
        $self -> savecroak ("Unknown table $table in $self->{'*DataSource'}") ;
        }

    return $meta -> {'*Types'}  ;
    }



## ----------------------------------------------------------------------------
##
## DESTROY
##
## do cleanup
##


sub DESTROY

    {
    my $self = shift ;
    my $orgerr = $@ ;
    local $@ ;

    eval 
	{ 
	if (defined ($self->{'*DBHdl'}))
	    {
	    $self->{'*DBHdl'} -> disconnect () ;
	    undef $self->{'*DBHdl'} ;
	    }
	} ;
    $self -> savecroak ($@) if (!$orgerr && $@) ;
    warn $@ if ($orgerr && $@) ;
    }


## ---------------------------------------------------------------------------------
##
## Datenbank Erzeugen
##
##   in $dbschema    Schema file or ARRAY ref
##   in $shema      schema name (Oracle)
##   in $user       user to grant rights to
##   in $setpriv    resetup privileges
##   in $alterconstraints resetup constraints (-1 to drop containts)
##

   
sub CreateTables

    {
    #my $DataSource  = shift ;
    #my $setupuser   = shift ;
    #my $setuppass   = shift ;
    #my $tabprefix   = shift ;
    my $db          = shift ; 
    my $dbschema     = shift ;
    my $shema       = shift ;
    my $user        = shift ;
    my $setpriv     = shift ;
    my $alterconstraints   = shift ;

    my $DBSchemaRef ;

    print "\nDatenbanktabellen anlegen/aktualisierien:\n" ;

    if (ref ($dbschema) eq 'ARRAY')
        {
        $DBSchemaRef = $dbschema ;
        }
    else
        {
        open FH, $dbschema or die "Schema nicht gefunden ($dbschema) ($!)" ;
            {
            local $/ = undef ;
            my $shema = <FH> ;
            $shema =~ /^(.*)$/s ; # untaint
            $shema = $1 ;
            eval $shema ;
            die "Fehler in $dbschema: $@" if ($@) ;
            }
        close FH ;
        $DBSchemaRef = \@DBSchema ;
        }


    #my $db = DBIx::Database -> new ({'!DataSource' => "$DataSource",
    #                                 '!Username'   => $setupuser,
    #                                 '!Password'   => $setuppass,
    #                                 '!KeepOpen'   => 1,
    #                                 '!TableFilter' => $tabprefix}) ;
    #  
    #die DBIx::Database->LastError . "; Datenbank muß bereits bestehen" if (DBIx::Database->LastError) ;
    #  
    
    my $dbh = $db -> DBHdl ;
    local $dbh -> {RaiseError} = 0 ;
    local $dbh -> {PrintError} = 0 ;
    
    my $tables = $db -> AllTables ;

   
    my $tab ;
    my $tabname ;
    my $type ;
    my $typespec ;
    my $size ;

    my $public = defined ($user) && $db -> {'*Username'} ne $user ;
    my $drv          = $db->{'*Driver'} ;
    my $tabprefix    = $db -> {'*TableFilter'} ;
    my $trans = DBIx::Compat::GetItem ($drv, 'CreateTypes') ; 
    $trans = {} if (!$trans) ;
    my $createseq = DBIx::Compat::GetItem ($drv, 'CreateSeq') ; 
    my $createpublic = $public && DBIx::Compat::GetItem ($drv, 'CreatePublic') ; 
    my $candropcolumn = DBIx::Compat::GetItem ($drv, 'CanDropColumn') ; 
    my $i ;
    my $field ;
    my $cmd ;


    foreach $tab (@$DBSchemaRef)
        {
        my $newtab = 0 ;
        my $newseq = 0 ;
        my $hasseq = 0 ;
        my %tabdef = (%DBDefault, %$tab, %{$tab -> {'!For'} -> {$drv} || {}}) ;
        $tabname = "$tabprefix$tabdef{'!Table'}" ;
        my $init = $tabdef{'!Init'} ;
        my $grant = (defined ($user) && $db -> {'*Username'} ne $user)?$tabdef{'!Grant'}:undef ;
        my $constraint  ;
        my $constraints = $tabdef{'!Constraints'} ;
        my $default = $tabdef{'!Default'} ;
        my $pk   = $tabdef{'!PrimKey'} ;
        my $index= $tabdef{'!Index'} ;
        my $c ;
        my $ccmd ;
        my $cname ;
        my $cval ;
        my $ncnt ;
        if ($tables -> {$tabname})
            {
            printl ("$tabname", LL, "vorhanden\n") ;

            my $fields = $tabdef{'!Fields'} ;
            my $dbfields = $db -> AllNames ($tabname) ;
            my %dbfields = map { $_ => 1 } @$dbfields ;
            my $lastfield ;
            for ($i = 0; $i <= $#$fields; $i+= 2)
                {
                $field    = lc ($fields -> [$i]) ;
                $typespec = $fields -> [$i+1] ;
                $hasseq = 1 if ($createseq && $typespec eq 'counter') ;
                
                $ccmd = '' ;
                $ncnt = 0 ;
                if ($constraints && ($constraint = $constraints -> {$field}))
                    {
                    $cname = "${tabname}_$field" ;
                    for ($c = 0 ; $c < $#$constraint; $c+=2)
                        {
                        if ($constraint -> [$c] eq '!Name')
                            {
                            $cname = $tabprefix . $constraint -> [$c+1] ;
                            $ncnt = 0 ;
                            next ;
                            }
                        $ncnt++ ;
                        $cval = $constraint -> [$c+1] || $constraint -> [$c] ;        
                        $cval =~ s#REFERENCES\s+(.*?)\s*\(#REFERENCES $tabprefix$1 (#i ;
                        $ccmd .= " CONSTRAINT $cname" . ( $ncnt >1?$ncnt:'') . " $cval" ;
                        }
                    }


                if (!$dbfields{$field})
                    {
                    printl ("   Add $field", LL) ;
                    $newseq = 1 if ($createseq && $typespec eq 'counter') ;
             
                    if ($typespec =~ /^(.*?)\s*\((.*?)\)(.*?)$/)
                        {
                        $type = $trans->{$1}?$trans->{$1}:$1 . "($2) $3" ;
                        }
                    else
                        {
                        $type = $typespec ;
                        $type = $trans -> {$typespec} if ($trans -> {$typespec}) ;
                        }
                    $cmd = "ALTER TABLE $tabname ADD $field $type $ccmd" . ($lastfield?" AFTER $lastfield":'') ;            

                    $db -> do ($cmd) ;

                    die "Fehler beim Erstellen des Feldes $tabname.$field:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                    
                    print "ok\n" ;
                    
                    if ($init || $default)
                        {
                        printl ("   $field initialisieren", LL) ;

                        $db -> MetaData ($tabname, undef, 1) ;

                        my $rs = DBIx::Recordset -> Setup ({'!DataSource' => $db, '!Table' => $tabname, '!PrimKey' => $tabdef{'!PrimKey'}}) ;
                        die "Fehler beim Setup von Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;

                        my $rec ;
                        if ($default && defined ($default -> {$field}))
                            {
                            $$rs -> Update ({$field, $default -> {$field}}, "$field is null") ;
                            die "Fehler beim Update in Tabelle $tabname:\n" . $$rs -> LastSQLStatement . "\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                            }

                        if ($init)
                            {
                            foreach $rec (@$init)
                                {
                                $$rs -> Update ({$field, $rec -> {$field}}, {$pk => $rec -> {$pk}}) ;
                                die "Fehler beim Update in Tabelle $tabname:\n" . $$rs -> LastSQLStatement . "\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                                }
                            }
                        print "ok\n" ;
                        }
                    }
                elsif ($alterconstraints && $ccmd)
                    {
                    printl ("   Alter Constraint $field", LL) ;

                    $ccmd = '' ;
                    $ncnt = 0 ;
                    if ($constraints && ($constraint = $constraints -> {$field}))
                        {
                        $cname = "${tabname}_$field" ;
                        for ($c = 0 ; $c < $#$constraint; $c+=2)
                            {
                            if ($constraint -> [$c] eq '!Name')
                                {
                                $cname = $tabprefix . $constraint -> [$c+1] ;
                                $ncnt = 0 ;
                                next ;
                                }
                            $ncnt++ ;
                            $ccmd = " CONSTRAINT $cname" . ( $ncnt>1?$ncnt:'')  ;
                            $cmd = "ALTER TABLE $tabname DROP $ccmd"  ;            

                            $db -> do ($cmd) ;

                            #die "Fehler beim Erstellen des Feldes $tabname.$field:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;

                            if ($alterconstraints > 0)
                                {
                                $cval = $constraint -> [$c] ;
                                if (lc ($cval) eq 'null' || lc ($cval) eq 'not null')
                                    {
                                    $cmd = "ALTER TABLE $tabname MODIFY $field $ccmd $cval" ;            
                                    }
                                else
                                    {
                                    $cval .= " ($field) " . $constraint -> [$c+1] ;        
                                    $cval =~ s#REFERENCES\s+(.*?)\s*\(#REFERENCES $tabprefix$1 (#i ;

                                    $cmd = "ALTER TABLE $tabname ADD $ccmd $cval" ;            
                                    }
                                $db -> do ($cmd) ;
                                die "Fehler beim Ändern des Constraints des Feldes $tabname.$field:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                                }
                            }
                        }

                    
                    print "ok\n" ;
                    }

                $dbfields{$field} = 2 ;
                }
            if ($candropcolumn)
                {
                while (($field, $i) = each (%dbfields))
                    {
                    if ($i == 1)
                        {
                        printl ("   Drop $field", LL) ;
             
                        $cmd = "ALTER TABLE $tabname DROP $field" ;            
                        $db -> do ($cmd) ;

                        die "Fehler beim Entfernen des Feldes $tabname.$field:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                    
                        print "ok\n" ;
                        }
                    }
                }
            }
        else
            {
            printl ("$tabname erstellen", LL) ;

            my $cmd = "CREATE TABLE $tabname (" ;
            $newtab = 1 ;
            
            my $fields = $tabdef{'!Fields'} ;
            for ($i = 0; $i <= $#$fields; $i+= 2)
                {
                $field    = lc($fields -> [$i]) ;
                $typespec = $fields -> [$i+1] ;
                $hasseq = $newseq = 1 if ($createseq && $typespec eq 'counter') ;
             
                if ($typespec =~ /^(.*?)\s*\((.*?)\)(.*?)$/)
                    {
                    $type = $trans -> {$1}?$trans -> {$1}:$1 . "($2) $3" ;
                    }
                else
                    {
                    $type = $typespec ;
                    $type = $trans -> {$typespec} if ($trans -> {$typespec}) ;
                    }

                $ccmd = '' ;
                $ncnt = 0 ;
                if ($constraints && ($constraint = $constraints -> {$field}))
                    {
                    $cname = "${tabname}_$field" ;
                    for ($c = 0 ; $c < $#$constraint; $c+=2)
                        {
                        if ($constraint -> [$c] eq '!Name')
                            {
                            $cname = $tabprefix . $constraint -> [$c+1] ;
                            $ncnt = 0 ;
                            next ;
                            }
                        $ncnt++ ;
                        $cval = $constraint -> [$c+1] || $constraint -> [$c] ;        
                        $cval =~ s#REFERENCES\s+(.*?)\s*\(#REFERENCES $tabprefix$1 (#i ;
                        $ccmd .= " CONSTRAINT $cname" . ( $ncnt >1?$ncnt:'') . " $cval" ;
                        }
                    }


                $cmd .= "$field $type $ccmd" ;
                $cmd .=  ($i == $#$fields - 1?' ':', ') ;            
                }

            $cmd .=  ", PRIMARY KEY ($tabdef{'!PrimKey'})" if ($tabdef{'!PrimKey'}) ;
            $cmd .=  ')' ;

            $db -> do ($cmd) ;

            die "Fehler beim Erstellen der Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;

            print "ok\n" ;

            if ($init)
                {
                printl ("$tabname initialisieren", LL) ;
                    
                my $rs = DBIx::Recordset -> Setup ({'!DataSource' => $db, '!Table' => $tabname, '!PrimKey' => $tabdef{'!PrimKey'}}) ;
                die "Fehler beim Setup von Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;

                my $rec ;
                foreach $rec (@$init)
                    {
                    my %dat ;
                    if ($default) 
                        {
                        %dat = (%$default, %$rec) ;
                        }
                    else
                        {
                        %dat = %$rec ;
                        }
                    
                    $$rs -> Insert (\%dat) ;
                    die "Fehler beim Insert in Tabelle $tabname:\n" . $$rs -> LastSQLStatement . "\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                    }
                print "ok\n" ;
                }
            }

    
        if ($index)
            {
            printl ("$tabname index erstellen", LL) ;

            my $i ;
            for ($i = 0; $i <= $#$index; $i+= 2)
                {
                my $field    = lc($index -> [$i]) ;
                my $name     = "${tabname}_${field}_ndx" ;
                my $attr     = $index -> [$i+1] ;
                if (ref($attr) eq 'HASH')
                    {
                    $name = "$tabprefix$attr->{Name}" ;
                    $attr = $attr -> {Attr} ;
                    }
                
                my $cmd      = "CREATE $attr INDEX $name ON $tabname ($field)" ;                 
                $db -> do ($cmd) ; 
                die "Fehler beim Erstellen des Indexes für $field:\n$cmd\n" . DBIx::Database->LastError  if ($newtab && DBIx::Database->LastError) ;
                }
            print "ok\n" ;
            }


        if ($grant && ($newtab || $setpriv))
            {
            if ($createpublic)

                {
                printl ("public synonym für $tabname erstellen", LL) ;

                if ($setpriv && !$newtab)
                    {
                    my $cmd = "DROP PUBLIC SYNONYM $tabname " ;
                    $db -> do ($cmd) ;
                    }

                my $cmd = "CREATE PUBLIC SYNONYM $tabname FOR $shema.$tabname" ;
                $db -> do ($cmd) ;
                die "Fehler beim Erstellen von public Synonym $tabname:\n$cmd\n" . DBIx::Database->LastError  if ($newtab && DBIx::Database->LastError) ;

                print "ok\n" ;
                }
            printl ("$tabname Berechtigungen setzen", LL) ;
            
            if ($setpriv && !$newtab)
                {
                my $cmd = "REVOKE all ON $tabname FROM $user" ;
                $db -> do ($cmd) ;
                warn "Fehler beim Entziehen der Berechtigungen für  Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                }

            $cmd = 'GRANT ' . join (',', @$grant) . " ON $tabname TO $user" ;                     
            $db -> do ($cmd) ;
            die "Fehler beim Setzen der Berechtigungen für  Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;

            print "ok\n" ;
            }

        if ($hasseq)
            {
            $tabname = "${tabname}_seq" ;

            if ($newseq)
                {
                printl ("$tabname erstellen", LL) ;

                my $cmd = "CREATE SEQUENCE $tabname " ;
                $db -> do ($cmd) ;

                die "Fehler beim Erstellen von Sequenz $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                print "ok\n" ;
                }

            if ($grant && ($newseq || $setpriv))
                {
                if ($createpublic)

                    {
                    printl ("public synonym für $tabname erstellen", LL) ;

                    if ($setpriv && !$newseq)
                        {
                        my $cmd = "DROP PUBLIC SYNONYM $tabname " ;
                        $db -> do ($cmd) ;
                        }

                    my $cmd = "CREATE PUBLIC SYNONYM $tabname FOR $shema.$tabname" ;
                    $db -> do ($cmd) ;

                    die "Fehler beim Erstellen von public Synonym $tabname:\n$cmd\n" . DBIx::Database->LastError  if ($newseq && DBIx::Database->LastError) ;
                    print "ok\n" ;
                    }

                printl ("$tabname Berechtigungen setzen", LL) ;
         
                if ($setpriv && !$newseq)
                    {
                    my $cmd = "REVOKE all ON $tabname FROM $user" ;

                    $db -> do ($cmd) ;
                    warn "Fehler beim Entziehen der Berechtigungen für  Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                    }

                $cmd = "GRANT select ON $tabname TO $user" ;                     
                $db -> do ($cmd) ;
                die "Fehler beim Setzen der Berechtigungen für  Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
                print "ok\n" ;

                }
            }
        }
    }

## ---------------------------------------------------------------------------------
##
## Datenbank Tabellen entfernen
##
##   in $shema      schema name (Oracle)
##   in $user       user to revoke rights from
##

    
sub DropTables

    {
    #my $DataSource  = shift ;
    #my $setupuser       = shift ;
    #my $setuppass       = shift ;
    #my $tabprefix       = shift ;
    my $db              = shift ; 
    my $shema           = shift ;
    my $user            = shift ;

    print "\nDatenbank Tabellen entfernen:\n" ;

    #my $db = DBIx::Database -> new ({'!DataSource' => "$DataSource",
    #                                 '!Username'   => $setupuser,
    #                                 '!Password'   => $setuppass,
    #                                 '!KeepOpen'   => 1,
    #                                 '!TableFilter' => $tabprefix}) ;
    #
    #die DBIx::Database->LastError . "; Datenbank muß bereits bestehen" if (DBIx::Database->LastError) ;

    my $tables = $db -> AllTables ;

    
    my $tab ;
    my $tabname ;
    my @seq ;
    my $cmd ;

    my $public = defined ($user) && $db -> {'*Username'} ne $user ;

    my $drv          = $db->{'*Driver'} ;
    my $tabprefix    = $db -> {'*TableFilter'} ;
    my $createseq    = DBIx::Compat::GetItem ($drv, 'CreateSeq') ; 
    my $createpublic = $public && DBIx::Compat::GetItem ($drv, 'CreatePublic') ; 

    foreach $tabname (keys %$tables)
        {
        printl ("$tabname entfernen", LL) ;

        if ($createpublic)
            {
            my $cmd = "DROP PUBLIC SYNONYM $tabname " ;

            $db -> do ($cmd) ;
            }

        #push @seq, $tabname if ($createseq && $typespec eq 'counter') ;
 
        $cmd = "DROP TABLE $tabname" ;            

        $db -> do ($cmd) ;

        $db -> MetaData ($tabname, undef, 1) ;
        $tables -> {$tabname} = 0 ;

        die "Fehler beim Entfernen der Tabelle $tabname:\n$cmd\n" . DBIx::Database->LastError  if (DBIx::Database->LastError) ;
        
        print "ok\n" ;

        if ($createseq)
            {
            $tabname = "${tabname}_seq" ;

            #printl ("$tabname erstellen", LL) ;

            my $cmd = "DROP SEQUENCE $tabname " ;

            $db -> do ($cmd) ;

            if ($createpublic)
                {
                my $cmd = "DROP PUBLIC SYNONYM $tabname " ;

                $db -> do ($cmd) ;
                }
            }
        }
    }

## ---------------------------------------------------------------------------------
##
## Output with fixed length
##
##   in	$txt    Text
##   in	$length Length
##   in	$txt2   Weiterer Text
##


sub printl

    {
    my ($txt, $length, $txt2) = @_ ;

    print $txt, ' ' x ($length - length($txt)), ' ', $txt2 ;
    } ;


###################################################################################

1;
__END__

=pod

=head1 NAME

DBIx::Database / DBIx::Recordset - Perl extension for DBI recordsets

=head1 SYNOPSIS

 use DBIx::Database;

=head1 DESCRIPTION

See perldoc DBIx::Recordset for an description.


=head1 AUTHOR

G.Richter (richter@dev.ecos.de)

