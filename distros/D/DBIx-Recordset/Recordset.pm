
###################################################################################
#
#   DBIx::Recordset - Copyright (c) 1997-2001 Gerald Richter / ECOS
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
#   $Id: Recordset.pm,v 1.106 2002/10/15 14:11:19 richter Exp $
#
###################################################################################



package DBIx::Recordset ;

use strict 'vars' ;
use Carp ;
use Data::Dumper;

use DBIx::Database ;
use DBIx::Compat ;
use Text::ParseWords ;

use vars 
    qw(
    $VERSION
    @ISA
    @EXPORT
    @EXPORT_OK

    $self
    @self
    %self
    
    $newself

    $Debug 

    $fld
    @fld 

    %Compat

    $id
    $numOpen

    %Data
    %Metadata

    %unaryoperators
    
    $LastErr
    $LastErrstr

    $PreserveCase
    $FetchsizeWarn
    );

use DBI ;

require Exporter;

@ISA       = qw(Exporter DBIx::Database::Base);

$VERSION = '0.26';


$PreserveCase = 0 ;
$FetchsizeWarn = 2 ;

$id = 1 ;
$numOpen = 0 ;

$Debug = 0 ;     # Disable debugging output

# Write Modes

use constant wmNONE   => 0 ;
use constant wmINSERT => 1 ;
use constant wmUPDATE => 2 ;
use constant wmDELETE => 4 ;
use constant wmCLEAR  => 8 ;
use constant wmALL    => 15 ;

# required Filters 

use constant rqINSERT => 1 ;
use constant rqUPDATE => 2 ;

# OnDelete actions

use constant odDELETE => 1 ;
use constant odCLEAR  => 2 ;


%unaryoperators = (
    'is null' => 1,
    'is not null' => 1
	) ;


# Get filehandle of logfile
if (defined ($INC{'Embperl.pm'}))
    {
    tie *LOG, 'Embperl::Log' ;
    }
elsif (defined ($INC{'HTML/Embperl.pm'}))
    {
    tie *LOG, 'HTML::Embperl::Log' ;
    }
else
    {
    *LOG = \*STDOUT ; 
    }


## ----------------------------------------------------------------------------
##
## SetupDBConnection
##
## $data_source  = Driver/DB/Host
##                  or recordset from which the data_source and dbhdl should be taken (optional)
## $table        = table (multiple tables must be comma separated)
## $username     = Username (optional)
## $password     = Password (optional) 
## \%attr        = Attributes (optional) 
##


sub SetupDBConnection($$$;$$\%)

    {
    my ($self, $data_source,  $table, $username, $password, $attr, $autolink) = @_ ;

    if ($table =~ /^\"/)
        {
        $self->{'*Table'}      = $table ;
        }
    else
        {
        $self->{'*Table'}      = $PreserveCase?$table:lc ($table) ;
        }

    $self->{'*MainTable'}  = $PreserveCase?$table:lc ($table) ;
    $self->{'*Id'}         = $id++ ;

    if (!($data_source =~ /^dbi\:/i)) 
        {
        my $metakey    = "-DATABASE//$data_source"  ;
        $data_source = $DBIx::Recordset::Metadata{$metakey} if (exists $DBIx::Recordset::Metadata{$metakey}) ;
        }

    if (ref ($data_source) eq 'DBIx::Recordset')
        { # copy from another recordset
        $self->{'*Driver'}     = $data_source->{'*Driver'} ;   
        $self->{'*DataSource'} = $data_source->{'*DataSource'} ;
        $self->{'*Username'}   = $data_source->{'*Username'} ; 
        $self->{'*DBHdl'}      = $data_source->{'*DBHdl'} ;    
        $self->{'*DBIAttr'}    = $data_source->{'*DBIAttr'} ;
        $self->{'*MainHdl'}    = 0 ;
        $self->{'*TableFilter'}= $data_source->{'*TableFilter'} ;
	$self->{'*Query'}      = $data_source->{'*Query'} ;
        }
    elsif (ref ($data_source) eq 'DBIx::Database')
        { # copy from database object
        $self->{'*DataSource'} = $data_source->{'*DataSource'} ;
        $self->{'*Username'}   = $data_source->{'*Username'} ; 
        $self->{'*DBIAttr'}    = $data_source->{'*DBIAttr'} ;
        $self->{'*TableFilter'}= $data_source->{'*TableFilter'} ;
        $self->{'*DBHdl'}      = $data_source->{'*DBHdl'} ;    
        $self->{'*Driver'}     = $data_source->{'*Driver'} ;   
        $self->{'*DoOnConnect'} = $data_source->{'*DoOnConnect'} ;
        }
     elsif (ref ($data_source) and eval { $data_source->isa('DBI::db') } )
         { # copy from database handle
         $self->{'*Driver'}     = $data_source->{'Driver'}->{'Name'} ;
         $self->{'*DataSource'} = $data_source->{'Name'} ;
         # DBI does not save user name
         $self->{'*Username'}   = undef ;
         $self->{'*DBHdl'}      = $data_source ;
         # XXX no idea how to fetch attr hash other than handle itself
         $self->{'*DBIAttr'}    = {} ;
         $self->{'*MainHdl'}    = 0 ;
         }
    else
        {
        $self->{'*DataSource'} = $data_source ;
        $self->{'*Username'}   = $username ;
        $self->{'*DBIAttr'}    = $attr ;
        $self->{'*DBHdl'}      = undef ;
        }

    
    my $hdl ;

    if (!defined ($self->{'*DBHdl'}))
        {
        $hdl = $self->{'*DBHdl'}  = DBI->connect($self->{'*DataSource'}, $self->{'*Username'}, $password, $self->{'*DBIAttr'}) or return undef ;

        $LastErr    = $self->{'*LastErr'}	= $DBI::err ;
        $LastErrstr = $self->{'*LastErrstr'}    = $DBI::errstr ;
    
        $self->{'*MainHdl'}    = 1 ;
        $self->{'*Driver'}     = $hdl->{Driver}->{Name} ;
	if ($self->{'*Driver'} eq 'Proxy')
	    {
            $self->{'*DataSource'} =~ /dsn\s*=\s*dbi:(.*?):/i ;
	    $self->{'*Driver'} = $1 ;
	    print LOG "DB:  Found DBD::Proxy, take compability entrys for driver $self->{'*Driver'}\n" if ($self->{'*Debug'} > 1) ;
	    }

        $numOpen++ ;

        print LOG "DB:  Successfull connect to $self->{'*DataSource'} (id=$self->{'*Id'}, numOpen = $numOpen)\n" if ($self->{'*Debug'} > 1) ;

        my $cmd ;
        if ($hdl && ($cmd = $self -> {'*DoOnConnect'}))
            {
            $self -> DoOnConnect ($cmd) ;
            }
        }
    else
        {
        $LastErr    = $self->{'*LastErr'}	= undef ;
        $LastErrstr = $self->{'*LastErrstr'}    = undef ;
    
        $hdl = $self->{'*DBHdl'} ;
        print LOG "DB:  Use already open dbh for $self->{'*DataSource'} (id=$self->{'*Id'}, numOpen = $numOpen)\n" if ($self->{'*Debug'} > 1) ;
        }
            
    

    my $meta = $self -> QueryMetaData ($self->{'*Table'}) ;
    my $metakey    = "$self->{'*DataSource'}//" . $self->{'*Table'} ;
    
    $self->{'*NullOperator'}  = DBIx::Compat::GetItem ($self->{'*Driver'}, 'NullOperator') ;
    $self->{'*HasInOperator'} = DBIx::Compat::GetItem ($self->{'*Driver'}, 'HasInOperator') ;

    $meta or $self -> savecroak ("No meta data available for $self->{'*Table'}") ;

    $self->{'*Table4Field'} = $meta->{'*Table4Field'} ;
    $self->{'*Type4Field'}  = $meta->{'*Type4Field'} ;
    #$self->{'*MainFields'} = $meta->{'*MainFields'} ;
    $self->{'*FullNames'}= $meta->{'*FullNames'} ;
    $self->{'*Names'}    = $meta->{'*Names'} ;
    $self->{'*Types'}    = $meta->{'*Types'} ;
    $self->{'*Quote'}    = $meta->{'*Quote'} ;
    $self->{'*Numeric'}  = $meta->{'*Numeric'} ;
    $self->{'*NumericTypes'}  = $meta->{'*NumericTypes'} ;
    $self->{'*Links'}    = $meta->{'*Links'} ;
    $self->{'*PrimKey'}  = $meta->{'!PrimKey'} ;


    return $hdl ;
    }


## ----------------------------------------------------------------------------
##
## TIEARRAY
##
## tie an array to the object, object must be aready blessed
##
## tie @self, 'DBIx::Recordset', $self ;
##


sub TIEARRAY
    {
    my ($class, $arg) = @_ ;
    my $rs ;    
    
    if (ref ($arg) eq 'HASH')
        {
        $rs = DBIx::Recordset -> SetupObject ($arg) or return undef ;
        }
    elsif (ref ($arg) eq 'DBIx::Recordset')
        {
        $rs = $arg ;
        }
    else
        {
        croak ("Need DBIx::Recordset or setup parameter") ;
        }

    
    return $rs ;
    }


sub STORESIZE
    
    {
    my ($self, $size) = @_ ;

    $self -> ReleaseRecords if ($size == 0) ;
    }


## ----------------------------------------------------------------------------
##
## New
##
## creates an new recordset object and ties an array and an hash to it
##
## returns a typeglob which contains:
## scalar:  ref to new object
## array:   array tied to object
## hash:    hash tied to object
##
## $data_source  = Driver/DB/Host
## $table        = table (multiple tables must be comma separated)
## $username     = Username (optional)
## $password     = Password (optional) 
## \%attr        = Attributes (optional) 
##


sub New
    {
    my ($class, $data_source,  $table, $username, $password, $attr) = @_ ;
    
    my $self = {'*Debug' => $Debug} ;

    bless ($self, $class) ;

    my $rc = $self->SetupDBConnection ($data_source,  $table, $username, $password, $attr) ;
    
    $self->{'*Placeholders'}= $DBIx::Compat::Compat{$self->{'*Driver'}}{Placeholders} ;
    $self->{'*Placeholders'}= $DBIx::Compat::Compat{'*'}{Placeholders} if (!defined ($self->{'*Placeholders'})) ;    
    $self->{'*Placeholders'}= 0 if ($self->{'*Placeholders'} < 10) ; # only full support for placeholders works

    if ($self->{'*Debug'} > 0)
        {
        print LOG "DB:  ERROR open DB $data_source ($DBI::errstr)\n" if (!defined ($rc)) ;

        my $n = '' ;
        $n = ' NOT' if (!$self->{'*Placeholders'}) ;
        print LOG "DB:  New Recordset driver=$self->{'*Driver'}  placeholders$n supported\n" if ($self->{'*Debug'} > 2)
        }

    return defined($rc)?$self:undef ;
    }

## ----------------------------------------------------------------------------
##
## SetupMemberVar
##
## setup a member config variable checking
## 1.) given parameter
## 2.) TableAttr
## 3.) default
##


sub SetupMemberVar
    {
    my ($self, $name, $param, $default) = @_ ;

    my $pn = "!$name" ;
    my $sn = "\*$name" ;
    my $attr ;

    if (exists $param -> {$pn})
	{
	$self -> {$sn} = $param -> {$pn} ;
	}
    elsif (defined ($attr = $self -> TableAttr ($pn)))
	{
	$self -> {$sn} = $attr ;
	}
    else
	{
	$self -> {$sn} ||= $default ;
	}
    print LOG "DB:  Setup: $pn = " . (defined ($self->{$sn})?$self->{$sn}:'<undef>') . "\n" if ($self -> {'*Debug'} > 2) ;
    }


## ----------------------------------------------------------------------------
##
## Setup
##
## creates an new recordset object and ties an array and an hash to it
##
## Same as New, but parameters passed as hash:
##
## !DataSource  = Driver/DB/Host
##                or a Recordset object from which to take the DataSource, DBIAttrs and username
## !Username    = username
## !Password    = password
## !DBIAttr     = reference to a hash which is passed to the DBI connect method
##
## !Table       = Tablename, muliply tables are comma separated
## !Fields      = fields which should be return by a query
## !Order	= order for any query
## !TabRelation = condition which describes the relation
##                between the given tables
## !TabJoin     = JOIN to use in table part of select statement
## !PrimKey     = name of primary key
## !StoreAll	= store all fetched data
## !LinkName    = query !NameField field(s) instead of !MainField for links
##		    0 = off
##		    1 = select additional fields
##		    2 = build name in uppercase of !MainField
##		    3 = replace !MainField with content of !NameField
##
## !Default     = hash with default record data
## !IgnoreEmpty = 1 ignore undef values, 2 ignore empty strings
##
## !WriteMode   = 1 => allow insert (wmINSERT)
##                2 => allow update (wmUPDATE)
##		  4 => allow delete (wmDELETE)
##                8 => allow delete all (wmCLEAR)
##		    default = 7
## !TableFilter = prefix which tables should be used
##


sub SetupObject

    {
    my ($class, $parm) = @_ ;

    my $self = New ($class, $$parm{'!DataSource'}, $$parm{'!Table'}, $$parm{'!Username'}, $$parm{'!Password'}, $$parm{'!DBIAttr'}) or return undef ; 


    HTML::Embperl::RegisterCleanup (sub { $self -> Disconnect }) if (defined (&HTML::Embperl::RegisterCleanup)) ;

    $self -> SetupMemberVar ('Debug', $parm, $Debug) ;
    $self -> SetupMemberVar ('Fields', $parm) ;
    $self -> SetupMemberVar ('TabRelation', $parm) ;
    $self -> SetupMemberVar ('TabJoin', $parm) ;
    $self -> SetupMemberVar ('PrimKey', $parm) ;
    $self -> SetupMemberVar ('Serial', $parm) ;
    $self -> SetupMemberVar ('Sequence', $parm) ;
    $self -> SetupMemberVar ('SeqClass', $parm) ;
    $self -> SetupMemberVar ('StoreAll', $parm) ;
    $self -> SetupMemberVar ('Default', $parm) ;
    $self -> SetupMemberVar ('IgnoreEmpty', $parm, 0) ;
    $self -> SetupMemberVar ('WriteMode', $parm, 7) ;
    $self -> SetupMemberVar ('TieRow', $parm, 1) ;
    $self -> SetupMemberVar ('LongNames', $parm, 0) ;
    $self -> SetupMemberVar ('KeepFirst', $parm, 0) ;
    $self -> SetupMemberVar ('LinkName', $parm, 0) ;
    $self -> SetupMemberVar ('NameField', $parm) ;
    $self -> SetupMemberVar ('Order', $parm) ;
    $self -> SetupMemberVar ('TableFilter', $parm) ;
    $self -> SetupMemberVar ('DoOnConnect', $parm) ;
    $self -> SetupMemberVar ('Query', $parm) ;

    if ($self -> {'*Serial'}) 
        {
        $self->{'*PrimKey'}     = $self -> {'*Serial'} if (!$parm->{'!PrimKey'}) ;
        $self->{'*Sequence'}    ||= "$self->{'*Table'}_seq" ;
    
        if ($self->{'*SeqClass'})
            {
            my @seqparm = split (/\s*,\s*/, $self->{'*SeqClass'}) ;

            my $class = shift @seqparm ;
            if (!defined (&{"$class\:\:new"}))
                {
                my $fn = $class ;
                $fn =~ s/::/\//g ;
                $fn .= '.pm' ;
                require $fn ;
                }
            $self->{'*SeqObj'} = $class -> new ($self -> {'*DBHdl'}, @seqparm) ; 
            }
        else
            {                        
            $self->{'*GetSerialPreInsert'} = DBIx::Compat::GetItem ($self -> {'*Driver'}, 'GetSerialPreInsert')  ;
            $self->{'*GetSerialPostInsert'} = DBIx::Compat::GetItem ($self -> {'*Driver'}, 'GetSerialPostInsert')  ;
            }
        }

    $Data{$self->{'*Id'}}   = [] ;
    $self->{'*FetchStart'}  = 0 ;
    $self->{'*LastSerial'}  = undef ;
    $self->{'*FetchMax'}    = undef ;
    $self->{'*EOD'}         = undef ;
    $self->{'*CurrRow'}     = 0 ;
    $self->{'*Stats'} = {} ;
    $self->{'*CurrRecStack'} = [] ;

    $self->{'*LinkSet'} = {} ;
    $LastErr	= $self->{'*LastErr'}	    = undef ;
    $LastErrstr = $self->{'*LastErrstr'}    = undef ;

    my $ofunc = $self->{'*OutputFunctions'} = {} ;
    my $ifunc = $self->{'*InputFunctions'}  = {} ;
    my $irfunc_insert = $self->{'*InputFunctionsRequiredOnInsert'}  = [] ;
    my $irfunc_update = $self->{'*InputFunctionsRequiredOnUpdate'}  = [] ;
    my $names = $self->{'*Names'} ;
    my $types = $self->{'*Types'} ;
    my $key ;
    my $value ;
    my $conversion ;
    my $dbg = ($self -> {'*Debug'} > 2) ;

    foreach $conversion (($self -> TableAttr ('!Filter'), $$parm{'!Filter'}))  
	{
	if ($conversion)
	    {
	    foreach $key (sort keys %$conversion)
		{
		$value = $conversion -> {$key} ;
		if ($key =~ /^-?\d*$/)
		    { # numeric -> SQL_TYPE
		    my $i = 0 ;
		    my $name ;
		    foreach (@$types)
			{
			if ($_ == $key) 
			    {
			    $name = $names -> [$i] ;
			    if ($value -> [0] || $ifunc -> {$name}) 
                                {
                                local $^W = 0 ;
                                $ifunc -> {$name} = $value -> [0] ;
		                print LOG "DB:  Apply input Filter to $name (type=$_)\n" if ($dbg) ;
		                push @$irfunc_insert, $name if ($value -> [2] & rqINSERT) ;
		                print LOG "DB:  Apply required INSERT Filter to $name (type=$_)\n" if ($dbg && $value -> [2] & rqINSERT) ;
		                push @$irfunc_update, $name if ($value -> [2] & rqUPDATE) ;
		                print LOG "DB:  Apply required UPDATE Filter to $name (type=$_)\n" if ($dbg && $value -> [2] & rqUPDATE) ;
                                }
			    $ofunc -> {$name} = $value -> [1] if ($value -> [1] || $ofunc -> {$name}) ;
			    print LOG "DB:  Apply output Filter to $name  (type=$_)\n" if ($dbg && ($value -> [1] || $ofunc -> {$name})) ;
                            }
			$i++ ;
			}
		    }
		else
		    {    	    
		    if ($value -> [0] || $ifunc -> {$key}) 
                        {
                        local $^W = 0 ;
                        $ifunc -> {$key} = $value -> [0] ;
		        print LOG "DB:  Apply input Filter to $key\n" if ($dbg) ;
		        push @$irfunc_insert, $key if ($value -> [2] & rqINSERT) ;
		        print LOG "DB:  Apply required INSERT Filter to $key\n" if ($dbg && $value -> [2] & rqINSERT) ;
		        push @$irfunc_update, $key if ($value -> [2] & rqUPDATE) ;
	                print LOG "DB:  Apply required UPDATE Filter to $key\n" if ($dbg && $value -> [2] & rqUPDATE) ;
                        }
    		    $ofunc -> {$key} = $value -> [1] if ($value -> [1] || $ofunc -> {$key}) ;
		    print LOG "DB:  Apply output Filter to $key\n" if ($dbg && ($value -> [1] || $ofunc -> {$key})) ;
		    }
		}
	    }
	}

    delete $self->{'*OutputFunctions'} if (keys (%$ofunc) == 0) ;
    delete $self->{'*InputFunctionsRequiredOnInsert'} if ($#$irfunc_insert == -1) ;
    delete $self->{'*InputFunctionsRequiredOnUpdate'} if ($#$irfunc_update == -1) ;
    	

    my $links =  $$parm{'!Links'} ;
    if (defined ($links))
        {
        my $k ;
        my $v ;
        while (($k, $v) = each (%$links))
            {
            $v -> {'!LinkedField'} = $v -> {'!MainField'} if (defined ($v) && !defined ($v -> {'!LinkedField'})) ;
            $v -> {'!MainField'}   = $v -> {'!LinkedField'} if (defined ($v) && !defined ($v -> {'!MainField'})) ;
            }
        $self->{'*Links'} = $links ;
        }

    if ($self->{'*LinkName'})
        {
        ($self->{'*Fields'}, $self->{'*Table'}, $self->{'*TabJoin'}, $self->{'*TabRelation'}, $self->{'*ReplaceFields'}) = 
               $self -> BuildFields ($self->{'*Fields'}, $self->{'*Table'}, $self->{'*TabRelation'}) ;
        }

    return $self ;
    }


sub Setup

    {
    my ($class, $parm) = @_ ;

    local *self ;
    
    $self = SetupObject ($class, $parm) or return undef ;

    tie @self, $class, $self ;
    if ($parm -> {'!HashAsRowKey'})
	{
	tie %self, "$class\:\:Hash", $self ;
	}
    else
	{
	tie %self, "$class\:\:CurrRow", $self ;
	}

    return *self ;
    }


## ----------------------------------------------------------------------------
##
## ReleaseRecords ...
##
## Release all records, write data if necessary
##

sub ReleaseRecords

    {
    $_[0] -> {'*LastKey'} = undef ;
    $_[0] -> Flush (1) ;
    #delete $Data{$_[0] -> {'*Id'}}  ;
    $Data{$_[0] -> {'*Id'}} = [] ;
    }



## ----------------------------------------------------------------------------
##
## undef and untie the object
##

sub Undef

    {
    my ($objname) = @_ ;

    if (!($objname =~ /\:\:/))
        {
        my ($c) = caller () ;
        $objname = "$c\:\:$objname" ;
        } 
    
    print LOG "DB:  Undef $objname\n" if (defined (${$objname}) && (${$objname}->{'*Debug'} > 1 || $Debug > 1)) ; 
    
    
    if (defined (${$objname}) && ref (${$objname}) && UNIVERSAL::isa (${$objname}, 'DBIx::Recordset')) 
        {
        # Cleanup rows and write them if necessary
        ${$objname} -> ReleaseRecords () ;
        ${$objname} -> Disconnect () ;
        }

    if (defined (%{$objname}))
        {
        my $obj = tied (%{$objname}) ;
        $obj -> {'*Recordset'} = undef if ($obj) ;
        $obj = undef ;
        }

    #${$objname} = undef ;
    untie %{$objname} ;
    undef ${$objname} if (defined (${$objname}) && ref (${$objname})) ;
    untie @{$objname} ;
    }


## ----------------------------------------------------------------------------
##
## disconnect from database
##

sub Disconnect ($)
    {
    my ($self) = @_ ;

    if (defined ($self->{'*StHdl'})) 
        {
        $self->{'*StHdl'} -> finish () ;
        print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
        undef $self->{'*StHdl'} ;
        }

    $self -> ReleaseRecords () ;

    if (defined ($self->{'*DBHdl'}) && $self->{'*MainHdl'})
        {
        $numOpen-- ;
        print LOG "DB:  Call DBI disconnect (id=$self->{'*Id'}, numOpen = $numOpen)\n" if ($self->{'*Debug'} > 3) ;
        $self->{'*DBHdl'} -> disconnect () ;
        undef $self->{'*DBHdl'} ;
        }


    print LOG "DB:  Disconnect (id=$self->{'*Id'}, numOpen = $numOpen)\n" if ($self->{'*Debug'} > 1) ;
    }


## ----------------------------------------------------------------------------
##
## do some cleanup 
##

sub DESTROY ($)
    {
    my ($self) = @_ ;
    my $orgerr = $@ ;
    local $@ ;

    eval 
	{ 
	$self -> Disconnect () ;

	delete $Data{$self -> {'*Id'}}  ;

	    {
	    local $^W = 0 ;
	    print LOG "DB:  DESTROY (id=$self->{'*Id'}, numOpen = $numOpen)\n" if ($self->{'*Debug'} > 2) ;
	    }
	} ;
    $self -> savecroak ($@) if (!$orgerr && $@) ;
    warn $@ if ($orgerr && $@) ;
    }



## ----------------------------------------------------------------------------
##
## begin transaction
##

sub Begin 

    {
    my ($self) = @_ ;

    # 'begin' method is unhandled by DBI
    ## ??  $self->{'*DBHdl'} -> func('begin') unless $self->{'*DBHdl'}->{'AutoCommit'};
    }

## ----------------------------------------------------------------------------
##
## commit transaction
##

sub Commit 

    {
    my ($self) = @_ ;

    $self -> Flush ;
    $self->{'*DBHdl'} -> commit unless $self->{'*DBHdl'}->{'AutoCommit'} ;
    }

## ----------------------------------------------------------------------------
##
## rollback transaction
##

sub Rollback

    {
    my ($self) = @_ ;

    $self -> ReleaseRecords ;

    $self->{'*DBHdl'} -> rollback unless $self->{'*DBHdl'}->{'AutoCommit'} ;
    }

## ----------------------------------------------------------------------------
##
## store something in the array
##

sub STORE 

    {
    my ($self, $fetch, $value) = @_ ;

    $fetch += $self->{'*FetchStart'} ;
    #$max    = $self->{'*FetchMax'} ;
    print LOG "DB:  STORE \[$fetch\] = " . (defined ($value)?$value:'<undef>') . "\n"  if ($self->{'*Debug'} > 3) ;
    if ($self->{'*Debug'} > 2 && ref ($value) eq 'HASH')
        {
        my $k ;
        my $v ;
        while (($k, $v) = each (%$value))
            {
            print LOG "<$k>=<$v> " ;
            }
        print LOG "\n" ;
        }        
    my $r ;
    my $rec ;
    $value ||= {} ;
    if (keys %$value)
        {
        my %rowdata ;
        $r = tie %rowdata, 'DBIx::Recordset::Row', $self ;
        %rowdata = %$value ;
        $rec = $Data{$self->{'*Id'}}[$fetch] = \%rowdata ;
        }
    else
        {
        local $^W = 0 ;

        $r = tie %$value, 'DBIx::Recordset::Row', $self, $value ;
        $rec = $Data{$self->{'*Id'}}[$fetch] = $value ;
	my $dirty = $r->{'*dirty'} ; # preserve dirty state  
        %$value = %{$self -> {'*Default'}} if (exists ($self -> {'*Default'})) ;
	$r->{'*dirty'}   = $dirty
        }
    $r -> {'*new'} = 1 ;

    #$self->{'*LastRow'} = $fetch ;
    #$self->{'*LastKey'} = $r -> FETCH ($self -> {'*PrimKey'}) ;

    return $rec ;
    } 

## ----------------------------------------------------------------------------
##
## Add
##
## Add a new record
##

sub Add
    
    {
    my ($self, $data) = @_ ;

    my $num = $#{$Data{$self->{'*Id'}}} + 1 ;

    $self -> STORE ($num, $data) if ($data) ;
    
    $self -> {'*CurrRow'} = $num + 1 ;
    $self -> {'*LastRow'} = $num ;
    
    return $num ;
    }


## ----------------------------------------------------------------------------
##
## StHdl
##
## return DBI statement handle of last select
##

sub StHdl ($)

    {
    return $_[0] -> {'*StHdl'} ;
    }


## ----------------------------------------------------------------------------
##
## TableName
##
## return name of table
##

sub TableName ($)

    {
    return $_[0] -> {'*Table'} ;
    }

## ----------------------------------------------------------------------------
##
## TableNameWithoutFilter
##
## return name of table. If a !TabFilter was specified, and the table start with 
## that filter text, it is removed from the front of the name
##

sub TableNameWithoutFilter ($)

    {
    my $tab = $_[0] -> {'*Table'} ;

    return $1 if ($tab =~ /^$_[0]->{'*TableFilter'}(.*?)$/) ;
    return $tab ;
    }

## ----------------------------------------------------------------------------
##
## PrimKey
##
## return name of primary key
##

sub PrimKey ($)

    {
    return $_[0] -> {'*PrimKey'} ;
    }


## ----------------------------------------------------------------------------
##
## TableFilter
##
## return table filter
##

sub TableFilter ($)

    {
    return $_[0] -> {'*TableFilter'} ;
    }


## ----------------------------------------------------------------------------
##
## AllNames
##
## return reference to array of all names in all tables
##

sub AllNames

    {
    return $_[0] -> {'*Names'} ;
    }

## ----------------------------------------------------------------------------
##
## AllTypes
##
## return reference to array of all types in all tables
##

sub AllTypes

    {
    return $_[0] -> {'*Types'} ;
    }


## ----------------------------------------------------------------------------
##
## Names
##
## return reference to array of names of the last query
##

sub Names

    {
    my $self = shift ;
    if ($self -> {'*LinkName'} < 2)
        {
        return $self->{'*SelectFields'} ;
        }
    else
        {
        my $names = $self->{'*SelectFields'};
        my $repl = $self -> {'*ReplaceFields'} ;
        my @newnames  ;
        my $i  ;
        for ($i = 0; $i <= $#$repl; $i++)
            {
            #print LOG "### Names $i = $names->[$i]\n" ;
            push @newnames, $names -> [$i] ; 
            }
        return \@newnames ;
        }
    }


## ----------------------------------------------------------------------------
##
## Types
##
## return reference to array of types of the last query
##

sub Types

    {
    my $sth = $_[0] -> {'*StHdl'} ;
    return undef if (!$sth) ;
    return $sth -> FETCH('TYPE') ;
    }


## ----------------------------------------------------------------------------
##
## Link
##
## if linkname if undef returns reference to an hash of all links
## else returns reference to that link
##

sub Link

    {
    my ($self, $linkname) = @_ ;

    my $links = $self -> {'*Links'} ;
    return undef if (!defined ($links)) ;
    return $links if (!defined ($linkname)) ;
    return $links -> {$linkname}  ;
    }

## ----------------------------------------------------------------------------
##
## Link4Field
##
## returns the Linkname for that field, if any
##

sub Link4Field

    {
    my ($self, $field) = @_ ;

    my $links = $self -> {'*Links'} ;
    return undef if (!defined ($field)) ;

    my $tab4f = $self -> {'*Table4Field'} ;

    if (!exists ($self -> {'*MainFields'}))
        {
        my $k ;
        my $v ;

        my $mf = {} ;
        my $f ;
        while (($k, $v) = each (%$links))
            {
            $f = $v -> {'!MainField'} ;
            $mf -> {$f} = $k ;
            $mf -> {"$tab4f->{$f}.$f"} = $k ;
            print LOG "DB:  Field $v->{'!MainField'} has link $k\n" ;
            }
        $self -> {'*MainFields'} = $mf ;
        }

    return $self -> {'*MainFields'} -> {$field} ;
    }

## ----------------------------------------------------------------------------
##
## Links
##
## return reference to an hash of links
##

sub Links

    {
    return $_[0] -> {'*Links'} ;
    }

## ----------------------------------------------------------------------------
##
## TableAttr
##
## get and/or set an unser defined attribute of that table
##
## $key   = key
## $value = new value (optional)
## $table = Name of table(s) (optional)
##

sub TableAttr

    {
    my ($self, $key, $value, $table) = @_ ;

   $table ||= $self -> {'*MainTable'} ;

    my $meta ;
    my $metakey    = "$self->{'*DataSource'}//" . ($PreserveCase?$table:lc ($table)) ; ;
    
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
## Stats
##
## return statistics
##

sub Stats

    {
    return $_[0] -> {'*Stats'} ;
    }


## ----------------------------------------------------------------------------
##
## StartRecordNo
##
## return the record no which will be returned for index 0
##

sub StartRecordNo

    {
    return $_[0] -> {'*StartRecordNo'} ;
    }

## ----------------------------------------------------------------------------
##
## LastSQLStatement
##
## return the last executed SQL Statement
##

sub LastSQLStatement

    {
    return $_[0] -> {'*LastSQLStatement'} ;
    }

## ----------------------------------------------------------------------------
##
## LastSerial
##
## return the last value of the field defined with !Serial
##

sub LastSerial

    {
    return $_[0] -> {'*LastSerial'} ;
    }


## ----------------------------------------------------------------------------
##
## LastError
##
## returns the last error message and code (code only in array context)
##

sub LastError

    {
    my $self = shift ;

    if (ref $self)
	{
	if (wantarray)
	    {
	    return ($self -> {'*LastErrstr'}, $self -> {'*LastErr'}) ;
	    }
	else
	    {
	    return $self -> {'*LastErrstr'} ;
	    }
	}
    else
	{
	if (wantarray)
	    {
	    return ($LastErrstr, $LastErr) ;
	    }
	else
	    {
	    return $LastErrstr ;
	    }
	}
    }


## ----------------------------------------------------------------------------
##
## SQL Insert ...
##
## $fields = comma separated list of fields to insert
## $vals   = comma separated list of values to insert
## \@bind_values = values which should be insert for placeholders
## \@bind_types  = data types of bind_values
##

sub SQLInsert ($$$$)

    {
    my ($self, $fields, $vals, $bind_values, $bind_types) = @_ ;
  
    $self -> savecroak ("Insert disabled for table $self->{'*Table'}") if (!($self->{'*WriteMode'} & wmINSERT)) ;
      
    $self->{'*Stats'}{insert}++ ;

    if (defined ($bind_values))
        {
        return $self->do ("INSERT INTO $self->{'*Table'} ($fields) VALUES ($vals)", undef, $bind_values, $bind_types) ;
        }
    else
        {
        return $self->do ("INSERT INTO $self->{'*Table'} ($fields) VALUES ($vals)") ;
        }
    }

## ----------------------------------------------------------------------------
##
## SQL Update ...
##
## $data = komma separated list of fields=value to update
## $where = SQL Where condition
## \@bind_values = values which should be insert for placeholders
## \@bind_types  = data types of bind_values
##
##

sub SQLUpdate ($$$$)

    {
    my ($self, $data, $where, $bind_values, $bind_types) = @_ ;
    
    $self -> savecroak ("Update disabled for table $self->{'*Table'}") if (!($self->{'*WriteMode'} & wmUPDATE)) ;

    $self->{'*Stats'}{update}++ ;

    if (defined ($bind_values))
        {
        return $self->do ("UPDATE $self->{'*Table'} SET $data WHERE $where", undef, $bind_values, $bind_types) ;
        }
    else
        {
        return $self->do ("UPDATE $self->{'*Table'} SET $data WHERE $where") ;
        }
    }

## ----------------------------------------------------------------------------
##
## SQL Delete ...
##
## $where = SQL Where condition
## \@bind_values = values which should be insert for placeholders
## \@bind_types  = data types of bind_values
##
##

sub SQLDelete ($$$)

    {
    my ($self, $where, $bind_values, $bind_types) = @_ ;
    
    $self -> savecroak ("Delete disabled for table $self->{'*Table'}") if (!($self->{'*WriteMode'} & wmDELETE)) ;
    $self -> savecroak ("Clear (Delete all) disabled for table $self->{'*Table'}") if (!$where && !($self->{'*WriteMode'} & wmCLEAR)) ;

    $self->{'*Stats'}{'delete'}++ ;

    if (defined ($bind_values))
        {
        return $self->do ("DELETE FROM $self->{'*Table'} " . ($where?"WHERE $where":''), undef, $bind_values, $bind_types) ;
        }
    else
        {
        return $self->do ("DELETE FROM $self->{'*Table'} " . ($where?"WHERE $where":'')) ;
        }
    }




## ----------------------------------------------------------------------------
##
## SQL Select
##
## Does an SQL Select of the form
##
##  SELECT $fields FROM <table> WHERE $expr ORDERBY $order
##
## $expr    = SQL Where condition (optional, defaults to no condition)
## $fields  = fields to select (optional, default to *)
## $order   = fields for sql order by or undef for no sorting (optional, defaults to no order) 
## $group   = fields for sql group by or undef (optional, defaults to no grouping) 
## $append  = append that string to the select statemtn for other options (optional) 
## \@bind_values = values which should be inserted for placeholders
## \@bind_types  = data types of bind_values
##

sub SQLSelect ($;$$$$$$$)
    {
    my ($self, $expr, $fields, $order, $group, $append, $bind_values, $bind_types, $makesql, ) = @_ ;

    my $sth ;  # statement handle
    my $where ; # where or nothing
    my $orderby ; # order by or nothing
    my $groupby ; # group by or nothing
    my $rc  ;        #
    my $table ;

    if (defined ($self->{'*StHdl'})) 
        {
        $self->{'*StHdl'} -> finish () ;
        print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
        }
    undef $self->{'*StHdl'} ;
    $self->ReleaseRecords ;
    undef $self->{'*LastKey'} ;
    $self->{'*FetchStart'} = 0 ;
    $self->{'*StartRecordNo'} = 0 ;
    $self->{'*FetchMax'} = undef ;
    $self->{'*EOD'} = undef ;
    $self->{'*SelectFields'} = undef ;
    $self->{'*LastRecord'} = undef ;

    $order  ||= '' ;
    $expr   ||= '' ;
    $group  ||= '' ;
    $append ||= '' ;
    $orderby  = $order?'ORDER BY':'' ;
    $groupby  = $group?'GROUP BY':'' ;
    $where    = $expr?'WHERE':'' ;
    $fields ||= '*';
    $table    = $self->{'*TabJoin'} || $self->{'*Table'} ;

    my $statement;
    if ($self->{'*Query'}) {
       $statement = $self->{'*Query'} . " " . $append;
    } else {
       $statement = "SELECT $fields FROM $table $where $expr $groupby $group $orderby $order $append" ;
    }



    if ($self->{'*Debug'} > 1)
        { 
        my $bv = $bind_values || [] ;
        my $bt = $bind_types || [] ;
        print LOG "DB:  '$statement' bind_values=<@$bv> bind_types=<@$bt>\n" ;
        }

    $self -> {'*LastSQLStatement'} = $statement ;

    return $statement if $makesql;

    $self->{'*Stats'}{'select'}++ ;

    $sth = $self->{'*DBHdl'} -> prepare ($statement) ;

    if (defined ($sth))
        {
        my @x ;
        my $ni = 0 ;
        
        my $Numeric = $self->{'*NumericTypes'} ;
        local $^W = 0 ; # avoid warnings
        for (my $i = 0 ; $i < @$bind_values; $i++)
            {
            #print LOG "bind $i  bv=<$bind_values->[$i]>  bvcnv=" . ($Numeric -> {$bind_types -> [$i]}?$bind_values -> [$i]+0:$bind_values -> [$i]) . "  bt=$bind_types->[$i]  n=$Numeric->{$bind_types->[$i]}\n" ;
            $bind_values -> [$i] += 0 if (defined ($bind_values -> [$i]) && defined ($bind_types -> [$i]) && $Numeric -> {$bind_types -> [$i]}) ;
            #my $bti = $bind_types -> [$i]+0 ;
            #$sth -> bind_param ($i+1, $bind_values -> [$i], {TYPE => $bti}) ;
            #$sth -> bind_param ($i+1, $bind_values -> [$i], $bind_types -> [$i] == DBI::SQL_CHAR()?DBI::SQL_CHAR():undef) ;
	    my $bt = $bind_types -> [$i] ;
            $sth -> bind_param ($i+1, $bind_values -> [$i], (defined ($bt) && $bt <= DBI::SQL_CHAR())?{TYPE => $bt}:undef ) ;
            }
        $rc = $sth -> execute  ;
	$self->{'*SelectedRows'} = $sth->rows;
	}
        
    $LastErr	= $self->{'*LastErr'}	    = $DBI::err ;
    $LastErrstr = $self->{'*LastErrstr'}    = $DBI::errstr ;
    
    my $names ;
    if ($rc)
    	{
	$names = $sth -> FETCH (($PreserveCase?'NAME':'NAME_lc')) ;
    	$self->{'*NumFields'} = $#{$names} + 1 ;
	}
    else
    	{
	print LOG "DB:  ERROR $DBI::errstr\n"  if ($self->{'*Debug'}) ;
	print LOG "DB:  in '$statement' bind_values=<@$bind_values> bind_types=<@$bind_types>\n" if ($self->{'*Debug'} == 1) ;
    
    	$self->{'*NumFields'} = 0 ;
	
	undef $sth ;
	}

    $self->{'*CurrRow'} = 0 ;
    $self->{'*LastRow'} = 0 ;
    $self->{'*StHdl'}   = $sth ;

    my @ofunca  ;
    my $ofunc  = $self -> {'*OutputFunctions'} ;

    if ($ofunc && $names)
	{
	my $i = 0 ;

	foreach (@$names)
	    {
	    $ofunca [$i++] = $ofunc -> {$_} ;
	    }
	}

    $self -> {'*OutputFuncArray'} = \@ofunca ;
    

	
    if ($self->{'*LongNames'})
        {
        if ($fields eq '*')
	    {
	    $self->{'*SelectFields'} = $self->{'*FullNames'} ;
	    }
        else
            {
            my $tab4f  = $self -> {'*Table4Field'} ;
            #my @allfields = map { (/\./)?$_:"$tab4f->{$_}.$_" } split (/\s*,\s*/, $fields) ;
            my @allfields = map { (/\./)?$_:"$tab4f->{$_}.$_" } quotewords ('\s*,\s*', 0, $fields) ;
            shift @allfields if (lc($allfields[0]) eq 'distinct') ;
            $self->{'*SelectFields'} = \@allfields ;
            }
        }
    else
	{
	$self->{'*SelectFields'} = $names ;
	}


    return $rc ;
    }

## ----------------------------------------------------------------------------
##
## FECTHSIZE - returns the number of rows form the last SQLSelect
##
## WARNING: Not all DBD drivers returns the correct number of rows
## so we issue a warning/error message when this function is used
##



sub FETCHSIZE 

    {
    my ($self) = @_;

    die "FETCHSIZE may not supported by your DBD driver, set \$FetchsizeWarn to zero if you are sure it works. Read about \$FetchsizeWarn in the docs!"  if ($FetchsizeWarn == 2) ;
    warn "FETCHSIZE may not supported by your DBD driver, set \$FetchsizeWarn to zero if you are sure it works. Read about \$FetchsizeWarn in the docs!"  if ($FetchsizeWarn == 1) ;
        
    my $sel = $self->{'*SelectedRows'} ;
    return $sel if (!defined ($self->{'*FetchMax'})) ;

    my $max = $self->{'*FetchMax'} - $self->{'*FetchStart'} + 1 ;
    return $max<$sel?$max:$sel ;
    }   


## ----------------------------------------------------------------------------
##
## Fetch the data from a previous SQL Select
##
## $fetch     = Row to fetch
## 
## fetchs the nth row and return a ref to an hash containing the entire row data
##


sub FETCH  
    {
    my ($self, $fetch) = @_ ;

    print LOG "DB:  FETCH \[$fetch\]\n"  if ($self->{'*Debug'} > 3) ;

    $fetch += $self->{'*FetchStart'} ;

    return $self->{'*LastRecord'} if (defined ($self->{'*LastRecordFetch'}) && $fetch == $self->{'*LastRecordFetch'} && $self->{'*LastRecord'}) ; 

    my $max ;
    my $key ;
    my $dat ;                           # row data

    
    $max    = $self->{'*FetchMax'} ;

    my $row = $self->{'*CurrRow'} ;     # row next to fetch from db
    my $sth = $self->{'*StHdl'} ;       # statement handle
    my $data = $Data{$self->{'*Id'}} ;  # data storage (Data is stored in a seperate hash to avoid circular references)

    if ($row <= $fetch && !$self->{'*EOD'} && defined ($sth))
        {

        # successfull select has happend before ?
        return undef if (!defined ($sth)) ;
        return undef if (defined ($max) && $row > $max) ;
        
        my $fld = $self->{'*SelectFields'} ;
        my $arr  ;
        my $i  ;

	if ($self -> {'*StoreAll'})
	    {
	    while ($row < $fetch)
		{
    	        if (!($arr = $sth -> fetchrow_arrayref ()))
		    {
		    $self->{'*EOD'} = 1 ;
		    $sth -> finish ;
                    print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, LastRow = $row, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
                    undef $self->{'*StHdl'} ;
		    last ;
		    }
                
                $i = 0 ;
                $data->[$row] = [ @$arr ] ;
		$row++ ;

                last if (defined ($max) && $row > $max) ;
		}
	    }
	else
	    {
	    while ($row < $fetch)
		{
    	        if (!$sth -> fetchrow_arrayref ())
		    {
		    $self->{'*EOD'} = 1 ;
		    $sth -> finish ;
                    print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
                    undef $self->{'*StHdl'} ;
		    last ;
		    }
		$row++ ;
                last if (defined ($max) && $row > $max) ;
		}
	    }


        $self->{'*LastRow'}   = $row ;
        if ($row == $fetch && !$self->{'*EOD'})
    	    {
            
    	    $arr = $sth -> fetchrow_arrayref () ;
            
            if ($arr)
                {
                $row++ ;
                $dat = {} ;
                if ($self -> {'*TieRow'})
		    {
		    my $obj = tie %$dat, 'DBIx::Recordset::Row', $self, $fld, $arr ;
		    $self->{'*LastKey'} = $obj -> FETCH ($self -> {'*PrimKey'}) ;
		    }
		else
		    {
		    @$dat{@$fld} = @$arr ;
                

		    my $nf = $self -> {'*NameField'} || $self -> TableAttr ('!NameField') ;
		    if ($nf)
			{
			if (!ref $nf)
			    {
			    $dat -> {'!Name'} = $dat -> {uc($nf)} || $dat -> {$nf} ;
			    }
			else
			    {    
			    $dat -> {'!Name'} = join (' ', map { $dat -> {uc ($_)} || $dat -> {$_} } @$nf) ;
			    }
			}

                    $self->{'*LastKey'} = $dat -> {$self -> {'*PrimKey'}} if ($self -> {'*PrimKey'}) ;
		    }
            
                $data -> [$fetch] = $dat ;
                }
            else
                {
                $dat = $data -> [$fetch] = undef ;
                #print LOG "new dat undef\n"  ;
    	        $self->{'*EOD'} = 1 ;
		$sth -> finish ;
                print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
                undef $self->{'*StHdl'} ;
                }
            }
        $self->{'*CurrRow'} = $row ;
        }
    else
        {
	my $obj ;

        $dat = $data -> [$fetch] if (!defined ($max) || $fetch <= $max);
	if (ref $dat eq 'ARRAY')
	    { # just an Array so tie it now
	    my $arr = $dat ;	
            $dat = {} ;
            $obj = tie %$dat, 'DBIx::Recordset::Row', $self, $self->{'*SelectFields'} , $arr ;
            $data -> [$fetch] = $dat ;
	    $self->{'*LastRow'} = $fetch ;
            $self->{'*LastKey'} = $obj -> FETCH ($self -> {'*PrimKey'}) ;
	    }
	else
	    {
	    #my $v ;
	    #my $k ;
	    #print LOG "old dat\n" ; #  = $dat  ref = " . ref ($dat) . " tied = " . ref (tied(%$dat)) . " fetch = $fetch\n"  ;
	    #while (($k, $v) = each (%$dat))
	    #        {
	    #        print "$k = $v\n" ;
	    #        }


	    my $obj = tied(%$dat) if ($dat) ;
	    $self->{'*LastRow'} = $fetch ;
	    $self->{'*LastKey'} = $obj?($obj -> FETCH ($self -> {'*PrimKey'})):undef ;
	    }
        }


        if ($row == $fetch + 1 && !$self->{'*EOD'})
            {
            # check if there are more records, if not close the statement handle
    	    my $arr ;
            
            $arr = $sth -> fetchrow_arrayref () if ($sth) ;
            my $orgrow = $row ;

            if ($arr)
                {
                $data->[$row] = [ @$arr ] ;
		$row++ ;
                $self->{'*CurrRow'} = $row ;
                }
            if ((defined ($max) && $orgrow > $max) || !$arr)
		{
		$self->{'*EOD'} = 1 ;
		$sth -> finish if ($sth) ;
                print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, LastRow = $row, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
                undef $self->{'*StHdl'} ;
		}
            }

    $self->{'*LastRecord'} = $dat ;
    $self->{'*LastRecordFetch'} = $fetch ;

    print LOG 'DB:  FETCH return ' . (defined ($dat)?$dat:'<undef>') . "\n"  if ($self->{'*Debug'} > 3) ;
    return $dat ;
    }


## ----------------------------------------------------------------------------
## 
## Reset ...
##
## position the record pointer before the first row, just as same as after Search
##

sub Reset ($)
    {
    my $self = shift ;

    $self->{'*LastRecord'} = undef ;
    $self ->{'*LastRow'}   = 0 ;
    }

## ----------------------------------------------------------------------------
## 
## First ...
##
## position the record pointer to the first row and return it
##

sub First ($;$)

    {
    my ($self, $new) = @_ ;
    my $rec = $self -> FETCH (0) ;
    return $rec if (defined ($rec) || !$new) ;
    # create new record 
    return $self -> {'*LastRecord'} = $self -> STORE (0) ;
    }


## ----------------------------------------------------------------------------
## 
## Last ...
##
## position the record pointer to the last row
## DOES NOT WORK!!
##
##

sub Last ($)
    {
    $_[0] -> FETCH (0x7fffffff) ; # maxmimun postiv integer
    return undef if ($_[0] -> {'*LastRow'} == 0) ;
    return $_[0] -> Prev ;
    }


## ----------------------------------------------------------------------------
## 
## Next ...
##
## position the record pointer to the next row and return it
##

sub Next ($;$)
    {
    my ($self, $new) = @_ ;
    my $lr   =  $self -> {'*LastRow'} ;

    $lr -= $self -> {'*FetchStart'} ;
    $lr = 0 if ($lr < 0) ;
    $lr++ if (defined ($self -> {'*LastRecord'})) ;

    ##$lr++ if ($_[0] ->{'*CurrRow'} > 0 || $_[0] ->{'*EOD'}) ; 
    my $rec = $self -> FETCH ($lr) ;
    return $rec if (defined ($rec) || !$new) ;

    # create new record 
    return $self -> {'*LastRecord'} = $self -> STORE ($lr) ;
    }


## ----------------------------------------------------------------------------
## 
## Prev ...
##
## position the record pointer to the previous row and return it
##

sub Prev ($)
    {
    $_[0] -> {'*LastRow'} = 0 if (($_[0] -> {'*LastRow'})-- == 0) ;
    return $_[0] -> FETCH ($_[0] ->{'*LastRow'} - $_[0] -> {'*FetchStart'}) ;
    }


## ----------------------------------------------------------------------------
##
## Fetch the data from current row
##


sub Curr ($;$)
    {
    my ($self, $new) = @_ ;

    my $lr ;
    return $lr if ($lr = $self->{'*LastRecord'}) ; 

    my $n = $self ->{'*LastRow'} - $self -> {'*FetchStart'} ;
    my $rec = $self -> FETCH ($n) ;
    return $rec if (defined ($rec) || !$new) ;

    # create new record 
    return $self -> STORE ($n) ;
    }

## ----------------------------------------------------------------------------
## 
## BuildFields ...
##

sub BuildFields

    {
    my ($self, $fields, $table, $tabrel) = @_ ;


    my @fields ;
    my $tab4f  = $self -> {'*Table4Field'} ;
    my $fnames = $self -> {'*FullNames'} ;
    my $debug  = $self -> {'*Debug'} ;
    my $drv    = $self->{'*Driver'} ;
    my %tables ;
    my %fields ;
    my %tabrel ;
    my @replace ;
    my $linkname ;
    my $link ;
    my $nf ;
    my $fn ;
    my @allfields ;
    my @orderedfields ;
    my $i ;
    my $n ;
    my $m ;
    my %namefields ;

    my $leftjoin = DBIx::Compat::GetItem ($drv, 'SupportSQLJoin') ;
    my $numtabs = 99 ;
    
    local $^W = 0 ;

    $numtabs = 2 if (DBIx::Compat::GetItem ($drv, 'SQLJoinOnly2Tabs')) ;


    #%tables = map { $_ => 1 } split (/\s*,\s*/, $table) ;
    %tables = map { $_ => 1 } quotewords ('\s*,\s*', 0, $table) ;
    $numtabs -= keys %tables ;

    #print LOG "###--> numtabs = $numtabs\n" ;
    if (defined ($fields) && !($fields =~ /^\s*\*\s*$/))
        {
        #@allfields = map { (/\./)?$_:"$tab4f->{$_}.$_" } split (/\s*,\s*/, $fields) ;
#        @allfields = map { (/\./)?$_:"$tab4f->{$_}.$_" } quotewords ('\s*,\s*', 0, $fields) ;
	@allfields = map { (/\./ || !$tab4f->{$_})?$_:"$tab4f->{$_}.$_" } quotewords ('\s*,\s*', 0, $fields) ;
        #print LOG "###allfields = @allfields\n" ;
	}
    else
        {
        @allfields = @$fnames ;
        }

    $nf = $self -> {'*NameField'} || $self -> TableAttr ('!NameField') ;
    if ($nf)
	{
	if (ref ($nf) eq 'ARRAY')
	    {
	    %namefields = map { ($fn = "$tab4f->{$_}\.$_") => 1 } @$nf ;
	    }
	else
	    {
	    %namefields = ( "$tab4f->{$nf}.$nf" => 1 ) ;
	    }

	@orderedfields = keys %namefields ;
	foreach $fn (@allfields)
	    {
	    push @orderedfields, $fn if (!$namefields{$fn}) ;
	    }
	}
    else
	{
	@orderedfields = @allfields ;
	}

    $i = 0 ;
    %fields = map { $_ => $i++ } @orderedfields ;

    $n = $#orderedfields ;
    $m = $n + 1;
    for ($i = 0; $i <=$n; $i++)
        {
        #print LOG "###loop numtabs = $numtabs\n" ;
	$fn = $orderedfields[$i] ;
        $replace[$i] = [$i] ;
        next if ($numtabs <= 0) ;
        next if (!($linkname = $self -> Link4Field ($fn))) ;
        next if (!($link = $self -> Link ($linkname))) ;
            # does not work with another Datasource or with an link to the table itself
        next if ($link -> {'!DataSource'} || $link -> {'!Table'} eq $self -> {'!Table'}) ; 

        $nf = $link->{'!NameField'} || $self -> TableAttr ('!NameField', undef, $link->{'!Table'}) ;

        if (!$link -> {'!LinkedBy'} && $nf)
            {
            $replace[$i] = [] ;
            if (ref $nf)
                {
                foreach (@$nf)
                    { 
                    if (!exists $fields{"$link->{'!Table'}.$_"})
                        {
                        push @orderedfields, "$link->{'!Table'}.$_" ;
                        push @allfields, "$link->{'!Table'}.$_" ;
                        $fields{"$link->{'!Table'}.$_"} = $m ; 
                        push @{$replace[$i]}, $m ;

                        print LOG "[$$] DB:  Add to $self->{'*Table'} linked name field $link->{'!Table'}.$_ (i=$i, n=$n, m=$m)\n" if ($debug > 2) ;            
                        $m++ ;
                        }
                    }
                }
            else
                {
                if (!exists $fields{"$link->{'!Table'}.$nf"})
                    {
                    push @orderedfields, "$link->{'!Table'}.$nf" ;
                    push @allfields, "$link->{'!Table'}.$nf" ;
                    $fields{"$link->{'!Table'}.$nf"} = $m ; 
                    push @{$replace[$i]}, $m ;

                    print LOG "[$$] DB:  Add to $self->{'*Table'} linked name field $link->{'!Table'}.$nf (i=$i, n=$n, m=$m)\n" if ($debug > 2) ;            
                    $m++ ;
                    }
                }

            $numtabs-- if (!exists $tables{$link->{'!Table'}}) ;
	    $tables{$link->{'!Table'}} = "$fn = $link->{'!Table'}.$link->{'!LinkedField'}" ;
            }
        elsif ($debug > 2 && !$link -> {'!LinkedBy'})
            { print LOG "[$$] DB:  No name, so do not add to $self->{'*Table'} linked name field $link->{'!Table'}.$fn\n" ;}            
        }

    #my $rfields = join (',', @allfields) ;
    my $rfields = join (',', @orderedfields) ;
    my $rtables = join (',', keys %tables) ;

    delete $tables{$table} ;
    my $rtabrel ;
    
    if ($leftjoin == 1)
      {
	  my @tabs = keys %tables ;
	  $rtabrel = ('(' x scalar(@tabs)) . $table . ' ' . join (' ', map { "LEFT JOIN $_ on $tables{$_})" } @tabs) ;
      } 
    elsif ($leftjoin == 2)	
      {
	  my $v ;

	  $tabrel = ($tabrel?"$tabrel and ":'') . join (' and ', map { $v = $tables{$_} ; $v =~ s/=/*=/ ; $v } keys %tables) ;
      } 
    elsif ($leftjoin == 3) 
      {
	  my $v ;

	  $tabrel = ($tabrel?"$tabrel and ":'') . join (' and ', map { "$tables{$_} (+)" } keys %tables) ;
      } 
    elsif ($leftjoin == 4)
      {
	  my @tabs = keys %tables ;
	  $rtabrel = $table . ' ' . join ' ', map { "LEFT JOIN $_ on $tables{$_}" } @tabs ;
      }
    else 
      {
	  my $v ;

	  $rtabrel = $table . ',' . join (',', map { "OUTER $_ " } keys %tables) ;
	  $tabrel = ($tabrel?"$tabrel and ":'') . join (' and ', values %tables) ;
      }

    return ($rfields, $rtables, $rtabrel, $tabrel, \@replace) ;
    }


## ----------------------------------------------------------------------------
## 
## BuildWhere ...
##
## \%where/$where   = hash of which the SQL Where condition is build
##                    or SQL Where condition as text
## \@bind_values    = returns the bind_value array for placeholder supported
## \@bind_types     = returns the bind_type  array for placeholder supported
##
##
## Builds the WHERE condition for SELECT, UPDATE, DELETE 
## upon the data which is given in the hash \%where or string $where
##
##      Key                 Value
##      <fieldname>         Value for field (automatily quote if necessary)
##      '<fieldname>        Value for field (always quote)
##      #<fieldname>        Value for field (never quote, convert to number)
##      \<fieldname>        Value for field (leave value as it is)
##      +<field>|<field>..  Value for fields (value must be in one/all fields
##                          depending on $compconj
##      $compconj           'or' or 'and' (default is 'or') 
##
##      $valuesplit         regex for spliting a field value in mulitply value
##                          per default one of the values must match the field
##                          could be changed via $valueconj
##      $valueconj          'or' or 'and' (default is 'or') 
##
##      $conj               'or' or 'and' (default is 'and') conjunction between
##                          fields
##
##      $operator           Default operator
##      *<fieldname>        Operator for the named field
##
##	$primkey	    primary key
##
##	$where		    where as string
##

sub BuildWhere ($$$$)

    {
    my ($self, $where, $xbind_values, $bind_types, $sub) = @_ ;
    
    
    my $expr = '' ;
    my $primkey ;
    my $Quote = $self->{'*Quote'} ;
    my $Debug = $self->{'*Debug'} ;
    my $ignore       = $self->{'*IgnoreEmpty'} ;
    my $nullop       = $self->{'*NullOperator'} ;
    my $hasIn        = $self->{'*HasInOperator'} ;
    my $linkname     = $self->{'*LinkName'} ;
    my $tab4f        = $self->{'*Table4Field'} ;
    my $type4f       = $self->{'*Type4Field'} ;
    my $ifunc        = $self->{'*InputFunctions'} ;
    my $bind_values  = ref ($xbind_values) eq 'ARRAY'?$xbind_values:$$xbind_values ;
    
    if (!ref($where))
        { # We have the where as string
        $expr = $where ;
        if ($Debug > 2) { print LOG "DB:  Literal where -> $expr\n" ; }
        }
    elsif (exists $where -> {'$where'})
        { # We have the where as string
        $expr = $where -> {'$where'} ;
        if (exists $where -> {'$values'})
            {
            if (ref ($xbind_values) eq 'ARRAY')
                {
                push @$xbind_values, @{$where -> {'$values'}} ;
                }
            else
                {
                $$xbind_values = $where -> {'$values'} ;
                }
            }
        if ($Debug > 2) { print LOG "DB:  Literal where -> $expr\n" ; }
        }
    elsif (defined ($primkey = $self->{'*PrimKey'}) && defined ($where -> {$primkey}) && 
           (!defined ($where -> {"\*$primkey"}) || $where -> {"\*$primkey"} eq '=') &&
           !ref ($where -> {$primkey}))
        { # simplify where when ask for <primkey> = ?
        my $oper = $$where{"\*$primkey"} || '=' ;

        my $pkey = $primkey ;
        $pkey = "$tab4f->{$primkey}.$primkey" if ($linkname && !($primkey =~ /\./)) ;

        # any input conversion ?
	my $val = $where -> {$primkey} ;
	my $if  = $ifunc -> {$primkey} ; 
	$val = &{$if} ($val) if ($if) ;

        $expr = "$pkey$oper ? "; push @$bind_values, $val ; push @$bind_types, $type4f -> {$primkey} ;
        if ($Debug > 2) { print LOG "DB:  Primary Key $primkey found -> $expr\n" ; }
        }
    else
        {         
        my $key ;
        my $lkey ;
        my $val ;

        my @mvals ;
    
        my $field ;
        my @fields ;

        my $econj ;
        my $vconj ;
        my $fconj ;
    
        my $vexp  ;
        my $fieldexp  ;

        my $type ;
        my $oper = $$where{'$operator'} || '=' ;
        my $op ;

        my $mvalsplit = $$where{'$valuesplit'} || "\t" ;

        my $lexpr = '' ;
        my $multcnt ;
	my $uright ;
        
	$econj = '' ;
    
 
        while (($key, $val) = each (%$where))
            {
            my @multtypes ;
            my @multval ;
            my $if ;

            $type  = substr ($key, 0, 1) || ' ' ;
            $val = undef if ($ignore > 1 && defined ($val) && $val eq '') ;

            if ($Debug > 2) { print LOG "DB:  SelectWhere <$key>=<" . (defined ($val)?$val:'<undef>') ."> type = $type\n" ; }

            $vexp  = '' ;
            if (substr ($key, 0, 5) eq '$expr')
                {
                $vexp = $self -> BuildWhere ($val, $bind_values, $bind_types, 1) if ($val) ;
                }
            else
                {
                if (($type =~ /^(\w|\\|\+|\'|\#|\s)$/) && !($ignore && !defined ($val)))
                    {
                    if ($type eq '+')
                        { # composite field
                
                        if ($Debug > 3) { print LOG "DB:  Composite Field $key\n" ; }

                        $fconj    = '' ;
                        $fieldexp = '' ;
                        @fields   = split (/\&|\|/, substr ($key, 1)) ;

                        $multcnt = 0 ;
                        foreach $field (@fields)
                            {
                            if ($Debug > 3) { print LOG "DB:  Composite Field processing $field\n" ; }

                            if (!defined ($$Quote{$PreserveCase?$field:lc ($field)}))
                                {
                                if ($Debug > 2) { print LOG "DB:  Ignore non existing Composite Field $field\n" ; }
                                next ;
                                } # ignore no existent field

                            $op = $$where{"*$field"} || $oper ;

                            $field = "$tab4f->{$field}.$field" if ($linkname && !($field =~ /\./)) ;

                            if (($uright = $unaryoperators{lc($op)}))
			        {
    			        if ($uright == 1)
				    { $fieldexp = "$fieldexp $fconj $field $op" }
			        else
				    { $fieldexp = "$fieldexp $fconj $op $field" }
			        }
                            elsif ($type eq '\\') 
                                { $fieldexp = "$fieldexp $fconj $field $op $val" ; }
                            elsif (defined ($val)) 
                                { 
                                $fieldexp = "$fieldexp $fconj $field $op ?" ;
                                push @multtypes, $type4f -> {$field} ; 
                                $multcnt++ ;
                                }
                            elsif ($op eq '<>')
                                { $fieldexp = "$fieldexp $fconj $field $nullop not NULL" ; }
                            else
                                { $fieldexp = "$fieldexp $fconj $field $nullop NULL" ; }

                        
                            $fconj ||= $$where{'$compconj'} || ' or ' ; 

                            if ($Debug > 3) { print LOG "DB:  Composite Field get $fieldexp\n" ; }

                            }
                        if ($fieldexp eq '')
                            { next ; } # ignore no existent field

                        }
                    else
                        { # single field
                        $multcnt = 0 ;
                        # any input conversion ?
		        $if  = $ifunc -> {$PreserveCase?$key:lc ($key)} ; 
		        ## see bvelow ## $val = &{$if} ($val) if ($if && !ref($val)) ;

                        if ($type eq '\\' || $type eq '#' || $type eq "'")
                            { # remove leading backslash, # or '
                            $key = substr ($key, 1) ;
                            }

                        $lkey = $PreserveCase?$key:lc ($key) ;

                    	        
		        if ($type eq "'")
                            {
                            $$Quote{$lkey} = 1 ;
                            }
                        elsif ($type eq '#')
                            {
                            $$Quote{$lkey} = 0 ;
                            }

		        
		        {
		        local $^W = 0 ; # avoid warnings

		        #$val += 0 if ($$Quote{$lkey}) ; # convert value to a number if necessary
		        }

                        if (!defined ($$Quote{$lkey}) && $type ne '\\')
                            {
                            if ($Debug > 3) { print LOG "DB:  Ignore Single Field $key\n" ; }
                            next ; # ignore no existent field
                            } 

                        if ($Debug > 3) { print LOG "DB:  Single Field $key\n" ; }

                        $op = $$where{"*$key"} || $oper ;

                        $key = "$tab4f->{$lkey}.$key" if ($linkname && $type ne '\\' && !($key =~ /\./)) ;

                        if (($uright = $unaryoperators{lc($op)}))
			    {
			    if ($uright == 1)
			        { $fieldexp = "$key $op" }
			    else
			        { $fieldexp = "$op $key" }
			    }
                        elsif ($type eq '\\') 
                            { $fieldexp = "$key $op $val" ; }
                        elsif (defined ($val)) 
                            { 
                            $fieldexp = "$key $op ?" ; 
                            push @multtypes, $type4f -> {$lkey} ;
                            $multcnt++ ;
                            }
                        elsif ($op eq '<>')
                            { $fieldexp = "$key $nullop not NULL" ; }
                        else
                            { $fieldexp = "$key $nullop NULL" ; }

                    
                        if ($Debug > 3) { print LOG "DB:  Single Field gives $fieldexp\n" ; }
                        }
    
                    my @multop ;
                    @multop = @$op if (ref ($op) eq 'ARRAY') ;


                    if (!defined ($val))
                        { @mvals = (undef) }
                    elsif ($val eq '')
                        { @mvals = ('') }
                    else
                        { 
                        if (ref ($val) eq 'ARRAY')
                            { 
                            if ($if) 
                                { @mvals = map { &{$if} ($_) } @$val } 
                            else
                                { @mvals = @$val ; }
                            }
                        else
                            {   
                            if ($if) 
                                { @mvals = map { &{$if} ($_) } split (/$mvalsplit/, $val) ; } 
                            else
                                { @mvals = split (/$mvalsplit/, $val) ; }
                            }
                        }
                    $vconj = '' ;
                    my $i ;

                    if ($hasIn && @mvals > 1 && !@multop && $op eq '=' && !$$where{'$valueconj'} && $type ne '+')
                        {
                        my $j = 0 ;
                        $vexp = "$key IN (" ;
                        foreach $val (@mvals)
                            {
                            $i = $multcnt ;
                            push @$bind_values, $val while ($i-- > 0) ;
                            push @$bind_types, @multtypes ;
                            $vexp .= $j++?',?':'?' ;
                            }                
                        $vexp .= ')' ;
                        }
                    else
                        {
                        foreach $val (@mvals)
                            {
                            $i = $multcnt ;
                            push @$bind_values, $val while ($i-- > 0) ;
                            push @$bind_types, @multtypes ;
                            if (@multop)
                                { $vexp = "$vexp $vconj ($key " . (shift @multop) . ' ?)' ; }
                            else
                                { $vexp = "$vexp $vconj ($fieldexp)" ; }
                            $vconj ||= $$where{'$valueconj'} || ' or ' ; 
                            }                
                    
                        }
                    }
                }

            if ($vexp)
                {
                if ($Debug > 3) { local $^W = 0 ; print LOG "DB:  Key $key gives $vexp bind_values = <@$bind_values> bind_types=<@$bind_types>\n" ; }

                $expr = "$expr $econj ($vexp)"  ;
        
                $econj ||= $$where{'$conj'} || ' and ' ; 
                }

            if ($Debug > 3 && $lexpr ne $expr) { $lexpr = $expr ; print LOG "DB:  expr is $expr\n" ; }
            }
        }


    # Now we add the Table relations, if any

    my $tabrel = $self->{'*TabRelation'} ;

    if ($tabrel && !$sub)
        {
        if ($expr)
            {
            $expr = "($tabrel) and ($expr)" ;
            }
        else
            {
            $expr = $tabrel ;
            }
        }
    
    return $expr ;
    }


## ----------------------------------------------------------------------------
##
## Dirty - see if there is at least one dirty row
##
##

sub Dirty
    {
    my $self = shift;
    my $data = $Data{ $self->{'*Id'} };
    
    return undef unless ( ref($data) eq 'ARRAY');
    
    foreach my $rowdata (@$data) 
        {
        print LOG "DIRTY: rowref " . (defined ($rowdata)?$rowdata:'<undef>') . "\n" if $self->{'*Debug'} > 4;
        next unless ((ref($rowdata) eq 'HASH')
                      and eval { tied(%$rowdata)->isa('DBIx::Recordset::Row') } );
        return 1 if tied(%$rowdata)->Dirty ;
        };
    return 0;	# clean
    }

 
## ----------------------------------------------------------------------------
##
## Fush ...
##
## Write all dirty rows to the database
##

sub Flush

    {
    my $self    = shift ;
    
    return if ($self -> {'*InFlush'}) ; # avoid endless recursion
    
    my $release = shift ;
    my $dat ;
    my $obj ;
    my $dbg = $self->{'*Debug'} ;
    my $id   = $self->{'*Id'} ;
    my $data = $Data{$id} ;
    my $rc = 1 ;

    print LOG "DB:  FLUSH Recordset id = $id  $self \n" if ($dbg > 2) ;

    $self -> {'*InFlush'} = 1 ;
    $self -> {'*UndefKey'} = undef ; # invalidate record for undef hashkey
    $self->{'*LastRecord'} = undef ; 
    $self->{'*LastRecordFetch'} = undef ; 
    if (defined ($self->{'*StHdl'})) 
        {
        $self->{'*StHdl'} -> finish () ;
        print LOG "DB:  Call DBI finish (id=$self->{'*Id'}, Last = $self->{'*LastSQLStatement'})\n" if ($self->{'*Debug'} > 3) ;
        undef $self->{'*StHdl'} ;
        }


    eval
        {    
        my $err ;
        
        foreach $dat (@$data)
	    {
            $obj = (ref ($dat) eq 'HASH')?tied (%$dat):undef ;
            if (defined ($obj)) 
                {
                # isolate row update errors
                eval 
                    {
                    local $SIG{__DIE__};
                    $obj -> Flush ();
                    } or $rc = undef ;

                $err ||= $@ ;
                $obj -> {'*Recordset'} = undef if ($release) ;
                }
	    }
        die $err if ($err) ;
        } ;

    $self -> {'*InFlush'} = 0 ;

    $self -> savecroak ($@) if ($@) ;

    return $rc ;
    }




## ----------------------------------------------------------------------------
##
## Insert ...
##
## \%data = hash of fields for new record
##

sub Insert ($\%)

    {
    my ($self, $data) = @_ ;

    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $data) ;
        ($self = $newself) or return undef ;
        }

    my @bind_values ;
    my @bind_types ;
    my @qvals ;
    my @keys ;
    my $key ;
    my $val ;
    my $q ;

    my $type4f = $self->{'*Type4Field'} ;
    my $Quote = $self->{'*Quote'} ;
    my $ifunc = $self->{'*InputFunctions'} ;
    my $irfunc = $self->{'*InputFunctionsRequiredOnInsert'} ;
    my $insertserial ;

    if ($self -> {'*GetSerialPreInsert'})
        {
        my $val = $data -> {$self -> {'*Serial'}} ;
        $val = $$val if (ref ($val) eq 'SCALAR') ;
        if (!defined ($val)) 
            { 
            $data -> {$self -> {'*Serial'}} = &{$self -> {'*GetSerialPreInsert'}} ($self -> {'*DBHdl'},
                                                                           $self -> {'*Table'}, 
                                                                           $self -> {'*Sequence'}) ;
            $insertserial = $self -> {'*Serial'} ;
            }
        $self -> {'*LastSerial'} = $data -> {$self -> {'*Serial'}} ;
        }
    elsif ($self -> {'*SeqObj'})
        {
        my $val = $data -> {$self -> {'*Serial'}} ;
        $val = $$val if (ref ($val) eq 'SCALAR') ;
        if (!defined ($val)) 
            { 
            $data -> {$self -> {'*Serial'}} = $self -> {'*SeqObj'} -> NextVal ($self -> {'*Sequence'}) ;
            $insertserial = $self -> {'*Serial'} ;
            }
        $self -> {'*LastSerial'} = $data -> {$self -> {'*Serial'}} ;
        }


    while (($key, $val) = each (%$data))
        {
        $val = $$val if (ref ($val) eq 'SCALAR') ;
        # any input conversion ?
	my $if = $ifunc -> {$key} ;
	$val = &{$if} ($val, 'insert', $data) if ($if) ;
	next if (!defined ($val)) ; # skip NULL values
	if ($key =~ /^\\(.*?)$/)
	    {
            push @qvals, $val ;
            push @keys, $1 ;
            }
	elsif (defined ($$Quote{$PreserveCase?$key:lc ($key)}))
            {
            push @bind_values ,$val ;
            push @qvals, '?' ;
            push @keys, $key ;
            push @bind_types, $type4f -> {$PreserveCase?$key:lc ($key)} ;
            }
        }

    if (@qvals == 1 && $insertserial && exists ($data -> {$insertserial}))
        { # if the serial is the only value remove if and make no insert
        @qvals = () ;
        }    

    if ($#qvals > -1)
        {
        foreach $key (@$irfunc)
            {
            next if (exists ($data -> {$key})) ; # input function alread applied
	    my $if = $ifunc -> {$key} ;
	    $val = &{$if} (undef, 'insert', $data) if ($if) ;
	    next if (!defined ($val)) ; # skip NULL values
	    if ($key =~ /^\\(.*?)$/)
		{
                push @qvals, $val ;
                push @keys, $1 ;
                }
	    elsif (defined ($$Quote{$PreserveCase?$key:lc ($key)}))
                {
                push @bind_values ,$val ;
                push @qvals, '?' ;
                push @keys, $key ;
                push @bind_types, $type4f -> {$PreserveCase?$key:lc ($key)} ;
                }
            }
        }
    
    my $rc  ;

    if ($#qvals > -1)
        {
        my $valstr = join (',', @qvals) ;
        my $keystr = join (',', @keys) ;

        $rc = $self->SQLInsert ($keystr, $valstr, \@bind_values, \@bind_types) ;

        $self -> {'*LastSerial'} = &{$self -> {'*GetSerialPostInsert'}} ($self -> {'*DBHdl'},
                                                                           $self -> {'*Table'}, 
                                                                           $self -> {'*Sequence'}) if ($self -> {'*GetSerialPostInsert'}) ; 

        }
    else
        {
        $self -> {'*LastSerial'} = undef ;
        }                

    return $newself?*newself:$rc ;
    }

## ----------------------------------------------------------------------------
##
## Update ...
##
## \%data = hash of fields for new record
## $where/\%where = SQL Where condition
##
##

sub Update ($\%$)

    {
    my ($self, $data, $where) = @_ ;
    
    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $data) ;
        ($self = $newself) or return undef ;
        }

    my $expr  ;
    my @bind_values ;
    my @bind_types ;
    my $key ;
    my $val ;
    my @vals ;
    my $q ;

    my $type4f = $self->{'*Type4Field'} ;
    my $primkey ;
    my $Quote = $self->{'*Quote'} ;
    my $ifunc = $self->{'*InputFunctions'} ;
    my $irfunc = $self->{'*InputFunctionsRequiredOnUpdate'} ;
    my $dbg = $self -> {'*Debug'} > 2 ;
        
    if ($irfunc)
        {
        map { $data -> {$_} = undef if (!exists ($data -> {$_})) } @$irfunc ;
        }
       
    
    if (defined ($primkey = $self->{'*PrimKey'}))
	{
        $val = $data -> {$primkey} ;
	$val = $$val if (ref ($val) eq 'SCALAR') ;
	#print LOG "1 primkey = $primkey d=$data->{$primkey} w=" . ($where?$where->{$primkey}:'<undef>') . " v=$val\n" ;
	if (defined ($val) && !$where)
	    {
	    $where = {$primkey => $val} ;
	    }
	elsif (ref ($where) eq 'HASH' && $val eq $where -> {$primkey})
	    {
	    delete $data -> {$primkey} ;
	    }
	else
	    {
	    $primkey = '' ;
	    }
	}
    else
	{
	$primkey = '' ;
	}

    #print LOG "2 primkey = $primkey d=$data->{$primkey} w=" . ($where?$where->{$primkey}:'<undef>') . " v=$val\n" ;
    my $datacnt = 0 ; 

    while (($key, $val) = each (%$data))
        {
        next if ($key eq $primkey) ;
        $val = $$val if (ref ($val) eq 'SCALAR') ;
        # any input conversion ?
        my $if = $ifunc -> {$key} ;
        print LOG "DB:  UPDATE: $key = " . (defined ($val)?$val:'<undef>') . " " . ($if?"input filter = $if":'') . "\n" if ($dbg) ;
       $val = &{$if} ($val, 'update', $data, $where) if ($if) ;
       if ($key =~ /^\\(.*?)$/)
            {
            push @vals, "$1=$val" ;
            $datacnt++ ;
            }
        elsif (defined ($$Quote{$PreserveCase?$key:lc ($key)}))
            { 
            push @vals, "$key=?" ;
            push @bind_values, $val ;
            push @bind_types, $type4f -> {$PreserveCase?$key:lc ($key)} ;
            $datacnt++ ;
            }
        }

    my $rc = '' ;
    if ($datacnt)
        {
	my $valstr = join (',', @vals) ;

	if (defined ($where))
	    { $expr = $self->BuildWhere ($where, \@bind_values, \@bind_types) ; }
	else
	    { $expr = $self->BuildWhere ($data, \@bind_values, \@bind_types) ; }


	$rc = $self->SQLUpdate ($valstr, $expr, \@bind_values, \@bind_types) ;
	}

    return $newself?*newself:$rc ;
    }



## ----------------------------------------------------------------------------
##
## UpdateInsert ...
##
## First try an update, if this fail insert an new record
##
## \%data = hash of fields for record
##

sub UpdateInsert ($\%)

    {
    my ($self, $fdat) = @_ ;

    my $rc ;

    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $fdat) ;
        ($self = $newself) or return undef ;
        }

    $rc = $self -> Update ($fdat) ;
    print LOG "DB:  UpdateInsert update returns: $rc  affected rows: $DBI::rows\n" if ($self->{'*Debug'} > 2) ;
    
    if (!$rc || $DBI::rows <= 0)
        {
        $rc = $self -> Insert ($fdat) ;
        }
    return $newself?*newself:$rc ;
    }




## ----------------------------------------------------------------------------
##
## Delete ...
##
## $where/\%where = SQL Where condition
##
##

sub Delete ($$)

    {
    my ($self, $where) = @_ ;
    
    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $where) ;
        ($self = $newself) or return undef ;
        }

    my @bind_values ;
    my @bind_types ;
    my $expr = $self->BuildWhere ($where,\@bind_values,\@bind_types) ;

    $self->{'*LastKey'} = undef ;

    my $rc = $self->SQLDelete ($expr, \@bind_values, \@bind_types) ;
    return $newself?*newself:$rc ;
    }

## ----------------------------------------------------------------------------
##
## DeleteWithLinks ...
##
## $where/\%where = SQL Where condition
##
##

sub DeleteWithLinks ($$;$)

    {
    my ($self, $where, $seen) = @_ ;

    $seen = {} if (ref ($seen) ne 'HASH') ;

    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $where) ;
        ($self = $newself) or return undef ;
        }

    $self -> savecroak ("Delete disabled for table $self->{'*Table'}") if (!($self->{'*WriteMode'} & wmDELETE)) ;
    
    my @bind_values ;
    my @bind_types ;
    my $expr = $self->BuildWhere ($where,\@bind_values,\@bind_types) ;

    my $clear_disabled_diag =
      "(!$expr && !($self->{'*WriteMode'} & wmCLEAR))";
    $self -> savecroak ("Clear (Delete all) disabled for table $self->{'*Table'}: $clear_disabled_diag") if (!$expr && !($self->{'*WriteMode'} & wmCLEAR)) ;

    my $links = $self -> {'*Links'} ;

    my $k ;
    my $link ;
    my $od ;
    my $selected = 0 ;

    foreach $k (keys %$links)
        {
        $link = $links -> {$k} ;
        if ($od = $link -> {'!OnDelete'})
            {
            if (!$selected)
                {
                my $rc = $self->SQLSelect ($expr, '*', undef, undef, undef, \@bind_values, \@bind_types) ;
                $selected = 1 ;
                }
            
            $self -> Reset ;
            my $lf = $link -> {'!LinkedField'} ;
            my $rec ;
            while ($rec = $self -> Next)
                {
	        my $setup = {%$link} ;
	        my $mv ;
	        if (exists ($rec -> {$link -> {'!MainField'}}))
		    { 
		    $mv = $rec -> {$link -> {'!MainField'}} ;
		    }
	        else
		    { 
		    $mv = $rec -> {"$link->{'!MainTable'}.$link->{'!MainField'}"} ;
		    }
                $setup -> {'!DataSource'} = $self if (!defined ($link -> {'!DataSource'})) ;
                print LOG "DB:  DeleteLinks  link = $k  Setup New Recordset for table $link->{'!Table'}, $lf = " . (defined ($mv)?$mv:'<undef>') . "\n" if ($self->{'*Debug'} > 1) ;
                my $updset = DBIx::Recordset -> Setup ($setup) ;

                if ($od & odDELETE)
                    {
                    my $seenkey = "$link->{'!Table'}::$lf::$mv" ;
                    if (!$seen -> {$seenkey})
                        {
                        $seen -> {$seenkey} = 1 ; # avoid endless recursion
                        $$updset -> DeleteWithLinks ({$lf => $mv}, $seen) ;
                        }
                    else
                        {
                        print LOG "DB:  DeleteLinks  detected recursion, do not follow link (key=$seenkey)\n" if ($self->{'*Debug'} > 1) ;
                        }
                    }
                elsif ($od & odCLEAR)
                    {
                    $$updset -> Update ({$lf => undef}, {$lf => $mv}) ;
                    }
                }
            }
        }

    $self->{'*LastKey'} = undef ;

    my $rc = $self->SQLDelete ($expr, \@bind_values, \@bind_types) ;
    return $newself?*newself:$rc ;
    }


## ----------------------------------------------------------------------------
##
## Select
##
## Does an SQL Select of the form
##
##  SELECT $fields FROM <table> WHERE $expr ORDERBY $order
##
## $where/%where = SQL Where condition (optional, defaults to no condition)
## $fields       = fields to select (optional, default to *)
## $order        = fields for sql order by or undef for no sorting (optional, defaults to no order) 
## $group        = fields for sql group by or undef (optional, defaults to no grouping) 
## $append       = append that string to the select statemtn for other options (optional) 
##


sub Select (;$$$$$)
    {
    my ($self, $where, $fields, $order, $group, $append, $makesql) = @_ ;

    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $where) ;
        ($self = $newself) or return undef ;
        }

    my $bind_values = [] ;
    my @bind_types ;
    my $expr = $self->BuildWhere ($where, \$bind_values, \@bind_types) ;

    my $rc = $self->SQLSelect ($expr, $self->{'*Fields'} || $fields, $self->{'*Order'} || $order, $group, $append, $bind_values, \@bind_types, $makesql, ) ;
    return $newself?*newself:$rc ;
    }


## ----------------------------------------------------------------------------
##
## Search data
##
## \%fdat   = hash of form data
##      
##   Special keys in hash:
##      $start: first row to fetch 
##      $max:   maximum number of rows to fetch
##	$next:	next n records
##	$prev:	previous n records
##	$order: fieldname(s) for ordering (could also contain USING)
##      $group: fields for sql group by or undef (optional, defaults to no grouping) 
##      $append:append that string to the select statemtn for other options (optional) 
##      $fields:fieldnams(s) to retrieve    
##



sub Search ($\%)

    {
    my ($self, $fdat) = @_ ;

    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $fdat) ;
        ($self = $newself) or return undef;
        }

    my $Quote = $self->{'*Quote'} ;

    my $start = $$fdat{'$start'} || 0 ;
    my $max   = $$fdat{'$max'} ;

    $start = 0 if (defined ($$fdat{'$first'}) || (defined ($start) && $start < 0)) ;
    $max   = 1 if (defined ($max) && $max < 1) ;

    if (defined ($$fdat{'$prev'}))
        {
        $start -= $max ; 
        if ($start < 0) { $start = 0 ; }
        }
    elsif (defined ($$fdat{'$next'}))
        { $start += $max ; }
    elsif (defined ($$fdat{'$goto'}))
        { 
	$start = $$fdat{'$gotorow'} - 1 ;
        if ($start < 0) { $start = 0 ; }
	}

    my $startrecno = $start ;
    my $append = '' ;
    if (defined ($max) && !$$fdat{'$last'})
        {
        my $LimitOffset = DBIx::Compat::GetItem ($self->{'*Driver'}, 'LimitOffset')  ;
        if ($LimitOffset) 
            {
            $append = &{$LimitOffset}($start,$$fdat{'$last'}?0:$max+1);
            $start = 0 if ($append) ;
            }
        }

    my $rc ;
    
    {
    local $^W = 0 ;
    $rc = $self->Select($fdat, $$fdat{'$fields'}, $$fdat{'$order'}, $$fdat{'$group'}, "$$fdat{'$append'} $append", $fdat->{'$makesql'} ) ; 
    }

    if ($rc && $$fdat{'$last'})
	{ # read all until last row
	my $storeall = $self->{'*StoreAll'} ;
	$self->{'*StoreAll'} = 1 ;
	$self -> FETCH (0x7ffffff) ;
	$startrecno = $start = $self->{'*LastRow'} - ($max || 1) ;
	$self->{'*StoreAll'} = $storeall ;
	}

    $self->{'*StartRecordNo'} = $startrecno ;
    $self->{'*FetchStart'} = $start ;
    $self->{'*FetchMax'}   = $start + $max - 1 if (defined ($max)) ;


    return $newself?*newself:$rc ;
    }




## ----------------------------------------------------------------------------
##
## Execute
##
##
## \%fdat   = hash of form data
##
##      =search  = search data
##      =update  = update record(s)
##      =insert  = insert record
##      =delete  = delete record(s)
##      =empty   = setup empty object
##


sub Execute ($\%)

    {
    my ($self, $fdat) = @_ ;

    local *newself ;
    if (!ref ($self)) 
        {
        *newself = Setup ($self, $fdat) ;
        ($self = $newself)  or return undef ;
        }


    if ($self->{'*Debug'} > 2)
         { print LOG 'DB:  Execute ' . ($$fdat{'=search'}?'=search ':'') .
                ($$fdat{'=update'}?'=update ':'') . ($$fdat{'=insert'}?'=insert ':'') .
                ($$fdat{'=empty'}?'=empty':'') . ($$fdat{'=delete'}?'=delete':'') . "\n" ; }

    my $rc = '-' ;
    if (defined ($$fdat{'=search'})) 
        {
        $rc = $self -> Search ($fdat) 
        }
    else
        {
        my $serial ;
        #$rc = $self -> UpdateInsert ($fdat) if (defined ($$fdat{'=update'}) && defined ($$fdat{'=insert'}) && !defined($rc)) ;
        $rc = $self -> Update ($fdat) if (defined ($$fdat{'=update'}) && $rc eq  '-') ;
        if (defined ($$fdat{'=insert'}) && $rc eq  '-') 
             {
             $rc = $self -> Insert ($fdat) ;
             if (defined ($rc) && $self -> {'*LastSerial'}) 
                {
                $serial = $self -> {'*LastSerial'} ;
                $rc = $self -> Search ({$self->{'*Serial'} => $serial}) ;
                return $newself?*newself:$rc ;
                }
             }
        $rc = $self -> DeleteWithLinks ($fdat) if (defined ($$fdat{'=delete'}) && $rc eq  '-') ;
        $rc = $self -> Search ($fdat) if (!defined ($$fdat{'=empty'}) && defined ($rc)) ;
        $rc = 1 if (defined ($$fdat{'=empty'}) && $rc eq  '-') ;
        }
                
    return $newself?*newself:$rc ;
    }

## ----------------------------------------------------------------------------
##
## PushCurrRec
##

sub PushCurrRec

    {
    my ($self) = @_ ;

    # Save Current Record
    my $sp = $self->{'*CurrRecStack'} ;
    push @$sp, $self->{'*LastRow'} ;
    push @$sp, $self->{'*LastKey'} ;
    push @$sp, $self->{'*FetchMax'} ;
    }



## ----------------------------------------------------------------------------
##
## PopCurrRec
##

sub PopCurrRec

    {
    my ($self) = @_ ;

    #Restore pointers
    my $sp = $self->{'*CurrRecStack'} ;
    $self->{'*FetchMax'} = pop @$sp  ;
    $self->{'*LastKey'}  = pop @$sp  ;
    $self->{'*LastRow'}  = pop @$sp  ;
    }

## ----------------------------------------------------------------------------
##
## MoreRecords
##

sub MoreRecords

    {
    my ($self, $ignoremax) = @_ ;

    $self -> PushCurrRec ;
    $self->{'*FetchMax'} = undef if ($ignoremax) ;

    my $more = $self -> Next () ;

    $self -> PopCurrRec ;

    return $more ; # && (ref $more) && keys (%$more) > 0 ;
    }


## ----------------------------------------------------------------------------
##
## PrevNextForm
##
##
##  $textprev   = Text for previous button
##  $textnext   = Text for next button
##  \%fdat      = fields/values for select where
##
##


sub PrevNextForm

    {
    my ($self, $textprev, $textnext, $fdat) = @_ ;

  
    my $param = $textprev ;
    my $textfirst ;
    my $textlast ;
    my $textgoto ;
    
    if (ref $textprev eq 'HASH')
	{
	$fdat = $textnext ;
	$textprev  = $param -> {'-prev'} ;  
	$textnext  = $param -> {'-next'} ;  
	$textfirst = $param -> {'-first'} ;  
	$textlast  = $param -> {'-last'} ;
	$textgoto  = $param -> {'-goto'} ;
	}
	  
  
  
    my $more  = $self -> MoreRecords (1) ;
    my $start = $self -> {'*StartRecordNo'} ;
    my $max   = $self -> {'*FetchMax'} - $self -> {'*FetchStart'} + 1 ;

    
    my $esc = '' ;
    $esc = '\\' if ((defined ($HTML::Embperl::escmode) && ($HTML::Embperl::escmode & 1)) || (defined ($Embperl::escmode) && ($Embperl::escmode & 1))) ;
    my $buttons = "$esc<form method=$esc\"POST$esc\"$esc>$esc<input type=$esc\"hidden$esc\" name=$esc\"\$start$esc\" value=$esc\"$start$esc\"$esc>\n$esc<input type=$esc\"hidden$esc\" name=$esc\"\$max$esc\" value=$esc\"$max$esc\"$esc>\n" ;
    my $k ;
    my $v ;

    if ($fdat)
        {
        while (($k, $v) = each (%$fdat))
            {
            if (substr ($k, 0, 1) eq '\\')
        	    {
        	    $k = '\\' . $k ;
        	    }
            if ($k ne '$start' && $k ne '$max' && $k ne '$prev' && $k ne '$next' && $k ne '$goto' && $k ne '$gotorow'
	         && $k ne '$first' && $k ne '$last')
        	    {
	            $buttons .= "$esc<input type=$esc\"hidden$esc\" name=$esc\"" . $k . "$esc\" value=$esc\"$v$esc\"$esc>\n" ;
		    }
            }
        }

    if ($start > 0 && $textfirst)
        {
        $buttons .= "$esc<input type=$esc\"submit$esc\" name=$esc\"\$first$esc\" value=$esc\"$textfirst$esc\"$esc> " ;
        }
    if ($start > 0 && $textprev)
        {
        $buttons .= "$esc<input type=$esc\"submit$esc\" name=$esc\"\$prev$esc\" value=$esc\"$textprev$esc\"$esc> " ;
        }
    if ($textgoto)
        {
        $buttons .= "$esc<input type=$esc\"text$esc\" size=6 name=$esc\"\$gotorow$esc\"$esc>" ;
        $buttons .= "$esc<input type=$esc\"submit$esc\" name=$esc\"\$goto$esc\" value=$esc\"$textgoto$esc\"$esc> " ;
        }
    if ($more > 0 && $textnext)
        {
        $buttons .= "$esc<input type=$esc\"submit$esc\" name=$esc\"\$next$esc\" value=$esc\"$textnext$esc\"$esc> " ;
        }
    if ($more > 0 && $textlast)
        {
        $buttons .= "$esc<input type=$esc\"submit$esc\" name=$esc\"\$last$esc\" value=$esc\"$textlast$esc\"$esc>" ;
        }
    $buttons .= "$esc</form$esc>" ;

    return $buttons ;    
    }




##########################################################################################

1;

package DBIx::Recordset::CurrRow ;


use Carp ;

## ----------------------------------------------------------------------------
##
## TIEHASH
##
## tie an hash to the object, object must be aready blessed
##
## tie %self, 'DBIx::Recordset::CurrRow', $self ;
##

sub TIEHASH
    {
    my ($class, $arg) = @_ ;
    my $rs ;    
    
    if (ref ($arg) eq 'HASH')
        {
        $rs = DBIx::Recordset -> SetupObject ($arg) or return undef ;
        }
    elsif (ref ($arg) eq 'DBIx::Recordset')
        {
        $rs = $arg ;
        }
    else
        {
        croak ("Need DBIx::Recordset or setup parameter") ;
        }


    my $self = {'*Recordset' => $rs} ;

    bless ($self, $class) ;
    
    return $self ;
    }




## ----------------------------------------------------------------------------
##
## Fetch the data from a previous SQL Select
##
## $fetch     = Column to fetch
## 
##


sub FETCH ()
    {
#    if (wantarray)
#        {
#        my @result ;
#        my $rs = $_[0] -> {'*Recordset'} ;
#        $rs -> PushCurrRec ;
#        my $rec = $rs -> First () ;
#        while ($rec)
#            {
##            push @result, tied (%$rec) -> FETCH ($_[1]) ;
#            push @result, $rec -> {$_[1]} ;
#            $rec = $rs -> Next () ;
#            }
#        $rs -> PopCurrRec ;
#        return @result ;
#        }
#    else
        {
        my $rec = $_[0] -> {'*Recordset'} -> Curr ;
	if (defined ($rec))
	    {
            my $obj ;
	    return $obj -> FETCH ($_[1]) if ($obj = tied (%$rec)) ;
            return $rec -> {$_[1]}  ;
	    }
        return undef ;
        }
    }


## ----------------------------------------------------------------------------

sub STORE ()
    {
    if (ref $_[2] eq 'ARRAY')
        { # array
        my ($self, $key, $dat) = @_ ;
        my $rs = $self -> {'*Recordset'} ;
        $rs -> PushCurrRec ;
        my $rec = $rs -> First (1) ;
        my $i = 0 ;
        while ($rec)
            {
            tied (%$rec) -> STORE ($key, $$dat[$i++]) ;
            last if ($i > $#$dat) ;
            $rec = $rs -> Next (1) ;
            }
        $rs -> PopCurrRec ;
        }
    else
        {
        tied (%{$_[0] -> {'*Recordset'} -> Curr (1)}) -> STORE ($_[1], $_[2]) ;
        }
    }


## ----------------------------------------------------------------------------

sub FIRSTKEY 
    {
    my $rec = $_[0] -> {'*Recordset'} -> Curr ;
    my $obj = tied (%{$rec}) ;

    return tied (%{$rec}) -> FIRSTKEY if ($obj) ;
    
    my $k = keys %$rec ;
    return each %$rec ;
    }


## ----------------------------------------------------------------------------

sub NEXTKEY 
    {
    my $rec = $_[0] -> {'*Recordset'} -> Curr ;
    my $obj = tied (%{$rec}) ;

    return tied (%{$rec}) -> NEXTKEY if ($obj) ; 
    return each %$rec ;
    }

## ----------------------------------------------------------------------------

sub EXISTS
    {
    return exists ($_[0] -> {'*Recordset'} -> Curr -> {$_[1]}) ;
    }

## ----------------------------------------------------------------------------

sub DELETE
    {
    carp ("Cannot DELETE a field from a database record") ;
    }
                
## ----------------------------------------------------------------------------

sub CLEAR ($)

    {
    #carp ("Cannot DELETE all fields from a database record") ;
    } 

## ----------------------------------------------------------------------------

sub DESTROY

    {
    my $self = shift ;
    my $orgerr = $@ ;
    local $@ ;

    eval 
	{ 

	$self -> {'*Recordset'} -> ReleaseRecords () if (defined ($self -> {'*Recordset'})) ;
    
	    {
	    local $^W = 0 ;
	    print DBIx::Recordset::LOG "DB:  ::CurrRow::DESTROY\n" if ($self -> {'*Recordset'} -> {'*Debug'} > 3) ;
	    }
	} ;
    $self -> savecroak ($@) if (!$orgerr && $@) ;
    warn $@ if ($orgerr && $@) ;
    }

##########################################################################################

package DBIx::Recordset::Hash ;

use Carp ;


## ----------------------------------------------------------------------------
##
## PreFetch
##
## Prefetch data
##
##

sub PreFetch
    
    {
    my ($self, $rs) = @_ ;
    my $where = $self -> {'*PreFetch'} ;
    my %keyhash ;
    my $rec ;
    my $merge = $self -> {'*MergeFunc'}  ;
    my $pk ;

    $rs -> Search ($where eq '*'?undef:$where) or return undef ;
    my $primkey = $rs -> {'*PrimKey'} or $rs -> savecroak ('Need !PrimKey') ;
    while ($rec = $rs -> Next)
        {
        $pk = $rec -> {$primkey} ;
        if ($merge && exists ($keyhash{$pk}))
            {
            if (tied (%{$keyhash{$pk}}))
                {
                my %data = %{$keyhash{$pk}} ;
                $keyhash{$pk} = \%data ;
                }

            &$merge ($keyhash{$pk}, $rec) ;
            }
        else
            {
            $keyhash{$pk} = $rec ;
            }
        }
    $self -> {'*KeyHash'} = \%keyhash ;
    $self -> {'*ExpiresTime'} = time + $self -> {'*Expires'} if ($self -> {'*Expires'} > 0) ;
    }

## ----------------------------------------------------------------------------
##
## PreFetchIfExpires
##
## Prefetch data
##
##

sub PreFetchIfExpires
    
  {

      my ($self, $rs) = @_ ;

      my $prefetch;

      if (ref ($self -> {'*Expires'}) eq 'CODE') {
	  $prefetch =  $self -> {'*Expires'}->($self);
      } elsif (defined ($self -> {'*ExpiresTime'})) {
	  $prefetch =  $self -> {'*ExpiresTime'} < time
      }

      $self -> PreFetch ($rs) if $prefetch;
    
  }

## ----------------------------------------------------------------------------
##
## TIEHASH
##
## tie an hash to the object, object must be aready blessed
##
## tie %self, 'DBIx::Recordset::Hash', $self ;
##

sub TIEHASH
    {
    my ($class, $arg) = @_ ;
    my $rs ;    
    my $keyhash ;

    my $self ;

    if (ref ($arg) eq 'HASH')
        {
        $self = 
                {
                '*Expires'   => $arg -> {'!Expires'},
                '*PreFetch'  => $arg -> {'!PreFetch'},
                '*MergeFunc' => $arg -> {'!MergeFunc'},
                } ;

        $rs = DBIx::Recordset -> SetupObject ($arg) or return undef ;
        }
    elsif (ref ($arg) eq 'DBIx::Recordset')
        {
        $rs = $arg ;
        $self = {} ;
        }
    else
        {
        croak ("Need DBIx::Recordset or setup parameter") ;
        }


    $self -> {'*Recordset'} = $rs ;

    bless ($self, $class) ;
 
    $self -> PreFetch ($rs) if ($self -> {'*PreFetch'}) ;

    return $self ;
    }


## ----------------------------------------------------------------------------
##
## Fetch the data from a previous SQL Select
##
## $fetch     = PrimKey for Row to fetch
## 
##


sub FETCH 
    {
    my ($self, $fetch) = @_ ;
    my $rs    = $self->{'*Recordset'} ;  

    return $rs-> {'*UndefKey'} if (!defined ($fetch)) ;  # undef could be used as key for autoincrement values
    
    my $h ;

    if ($self -> {'*PreFetch'}) 
        {
        $self -> PreFetchIfExpires ($rs) ;

        $h = $self -> {'*KeyHash'} -> {$fetch} ;
        }
    else
        {    
        print DBIx::Recordset::LOG "DB:  Hash::FETCH \{" . (defined ($fetch)?$fetch:'<undef>') ."\}\n"  if ($rs->{'*Debug'} > 3) ;

        if (!defined ($rs->{'*LastKey'}) || $fetch ne $rs->{'*LastKey'})
            {
            $rs->SQLSelect ("$rs->{'*PrimKey'} = ?", undef, undef, undef, undef, [$fetch], [$rs->{'*Type4Field'}{$rs->{'*PrimKey'}}]) or return undef ; 
    
            $h = $rs -> FETCH (0) ;
            my $merge = $self -> {'*MergeFunc'}  ;
            $self -> {'*LastMergeRec'} = undef ;
            if ($merge && $rs -> MoreRecords)
                {
                my %data = %$h ;
                my $rec ;
                my $i = 1 ;
                while ($rec = $rs -> FETCH($i++))
                    {
                    &$merge (\%data, $rec) ;
                    }
                $self -> {'*LastMergeRec'} = $h = \%data ;
                }
            }
        else
            {
            if ($self -> {'*LastMergeRec'})
                { $h = $self -> {'*LastMergeRec'} }
            else
                { $h = $rs -> Curr ; }
            }
        }

    print DBIx::Recordset::LOG "DB:  Hash::FETCH return " . (defined ($h)?$h:'<undef>') . "\n" if ($rs->{'*Debug'} > 3) ;
  
    return $h ;
    }

## ----------------------------------------------------------------------------
##
## store something in the hash
##
## $key     = PrimKey for Row to fetch
## $value   = Hashref with row data
##

sub STORE

    {
    my ($self, $key, $value) = @_ ;
    my $rs    = $self -> {'*Recordset'} ;  

    print DBIx::Recordset::LOG "DB:  ::Hash::STORE \{" . (defined ($key)?$key:'<undef>') . "\} = " . (defined ($value)?$value:'<undef>') . "\n" if ($rs->{'*Debug'} > 3) ;

    $rs -> savecroak ("Hash::STORE need hashref as value") if (!ref ($value) eq 'HASH') ;

    #$rs -> savecroak ("Hash::STORE doesn't work with !PreFetch") if ($self -> {'*PreFetch'}) ;
    return if ($self -> {'*PreFetch'}) ;

    my %dat = %$value ;                 # save values, if any
    $dat{$rs -> {'*PrimKey'}} = $key ;  # setup primary key value
    %$value = () ;                      # clear out data in tied hash
    my $r = tie %$value, 'DBIx::Recordset::Row', $rs, \%dat, undef, 1 ;
    
    #$r -> STORE ($rs -> {'*PrimKey'}, $key) ;
    #$r -> {'*new'}   = 1 ;
    
    # setup recordset
    $rs-> ReleaseRecords ;
    $DBIx::Recordset::Data{$rs-> {'*Id'}}[0] = $value ;
    $rs-> {'*UndefKey'} = defined($key)?undef:$value ;
    $rs-> {'*LastKey'} = $key ;
    $rs-> {'*CurrRow'} = 1 ;
    $rs-> {'*LastRow'} = 0 ;
    } 

## ----------------------------------------------------------------------------

sub FIRSTKEY 
    {
    my $self  = shift ;

    my $rs    = $self->{'*Recordset'} ;  
    my $primkey = $rs->{'*PrimKey'}  ;


    if ($self -> {'*PreFetch'}) 
        {
        $self -> PreFetchIfExpires ($rs) ;
        
        my $keyhash = $self -> {'*KeyHash'} ;
        my $foo = keys %$keyhash ; # reset iterator

        return each %$keyhash ;
        }

    $rs->SQLSelect () or return undef ; 

    my $dat = $rs -> First (0) or return undef ;
    my $key = $dat -> {$rs->{'*PrimKey'}} ;
    
    if ($rs->{'*Debug'} > 3) 
        {
        print DBIx::Recordset::LOG "DB:  Hash::FIRSTKEY \{" . (defined ($key)?$key:'<undef>') . "\}\n" ;
        }        

    return $key ;
    }

## ----------------------------------------------------------------------------

sub NEXTKEY 
    {
    my $self  = shift ;
    my $rs    = $self->{'*Recordset'} ;  

    if ($self -> {'*PreFetch'}) 
        {
        ##$self -> PreFetchIfExpires ($rs) ;
        
        my $keyhash = $self -> {'*KeyHash'} ;
        return each %$keyhash ;
        }

    my $dat   = $rs -> Next () or return undef ;
    my $key   = $dat -> {$rs->{'*PrimKey'}} ;

    if ($rs->{'*Debug'} > 3) 
        {
        print DBIx::Recordset::LOG "DB:  Hash::NEXTKEY \{" . (defined ($key)?$key:'<undef>') . "\}\n" ;
        }        

    return $key ;
    }

## ----------------------------------------------------------------------------

sub EXISTS
    {
    my ($self, $key)  = @_ ;

    if ($self -> {'*PreFetch'}) 
        {
        my $rs    = $self->{'*Recordset'} ;  
        $self -> PreFetchIfExpires ($rs) ;
        
        my $keyhash = $self -> {'*KeyHash'} ;
        return exists ($keyhash -> {$key}) ;
        }

    return defined ($self -> FETCH ($key)) ;
    }

## ----------------------------------------------------------------------------

sub DELETE
    {
    my ($self, $key) = @_ ;
    my $rs    = $self -> {'*Recordset'} ;  
    
    $rs->{'*LastKey'} = undef ;
    
    $rs->SQLDelete ("$rs->{'*PrimKey'} = ?", [$key], [$rs->{'*Type4Field'}{$rs->{'*PrimKey'}}]) or return undef ; 

    return 1 ;
    }
                
## ----------------------------------------------------------------------------

sub CLEAR 

    {
    my ($self, $key) = @_ ;
    my $rs    = $self -> {'*Recordset'} ;  

    $rs->SQLDelete ('') or return undef ; 
    } 

## ----------------------------------------------------------------------------
##
## Dirty  - see if there are unsaved changes
##

sub Dirty { return $_[0]->{'*Recordset'}->Dirty() }
 
## ----------------------------------------------------------------------------

sub Flush

    {
    $_[0]->{'*Recordset'} -> Flush () ;
    }

## ----------------------------------------------------------------------------

sub DESTROY

    {
    my $self = shift ;
    my $orgerr = $@ ;
    local $@ ;

    eval 
	{ 

	$self -> {'*Recordset'} -> ReleaseRecords ()  if (defined ($self -> {'*Recordset'})) ;

	    {
	    local $^W = 0 ;
	    print DBIx::Recordset::LOG "DB:  ::Hash::DESTROY\n" if ($self -> {'*Recordset'} -> {'*Debug'} > 3) ;
	    }
	} ;
    $self -> savecroak ($@) if (!$orgerr && $@) ;
    warn $@ if ($orgerr && $@) ;
    }

##########################################################################################

package DBIx::Recordset::Access ;

use overload 'bool' => sub { 1 }, '%{}' => \&gethash, '@{}' => \&getarray ; #, '${}' => \&getscalar ;

sub new 
    {
    my $class = shift;
    my $arg   = shift ;
    bless $arg, $class;
    }


sub gethash 
    {
    my $self = shift ;
    return \%$$self ;
    }

sub getarray
    {
    my $self = shift ;
    return \@$$self ;
    }

sub getscalar
    {
    my $self = shift ;
    return \$$$self ;
    }

##########################################################################################

package DBIx::Recordset::Row ;

use Carp ;

sub TIEHASH  

    {
    my ($class, $rs, $names, $dat, $new) = @_ ;

    my $self = {'*Recordset' => $rs} ;
    my $data = $self -> {'*data'} = {} ;
    my $upd  = $self -> {'*upd'}  = {} ;

    bless ($self, $class) ;
 
    if (ref ($names) eq 'HASH')
        {
        my $v ;
        my $k ;

        if ($new)
            {
            my $dirty = 0 ;
            $self->{'*new'}     = 1 ;                  # mark it as new record
            
            my $lk ;
            while (($k, $v) = each (%$names))
                {
                $lk = $DBIx::Recordset::PreserveCase?$k:lc ($k) ;
                # store the value and remeber it for later update
                $upd ->{$lk} = \($data->{$lk} = $v) ;
                $dirty = 1 ;
                }
            $self->{'*dirty'}   = $dirty ;             # mark it as dirty only if data exists
            }
        else
            {
            while (($k, $v) = each (%$names))
                {
                $data -> {$DBIx::Recordset::PreserveCase?$k:lc ($k)} = $v ;
                }
            }
        }
    else
        {
        my $i = 0 ;
	my $of ;
        my $ofunc    = $rs -> {'*OutputFuncArray'} || [] ;
	my $linkname = $rs -> {'*LinkName'} ;
        if ($rs -> {'*KeepFirst'})
            {
            $i = -1 ;
	    %$data = () ;
            if ($dat)
                {
                foreach my $k (@$dat)
                    {
                    $i++ ;
                    my $hkey = ($DBIx::Recordset::PreserveCase?$$names[$i]:lc($$names[$i])) ;

                    #warn "hkey = $hkey data = $k\n" ;
                    $data -> {$hkey} = ($ofunc->[$i]?(&{$ofunc->[$i]}($k)):$k) if (!exists $data -> {$hkey}) ;
                    }
                }
            }
	elsif ($linkname < 2)
            {    
            $i = -1 ;
	    %$data = map { $i++ ; ($DBIx::Recordset::PreserveCase?$$names[$i]:lc($$names[$i])) => ($ofunc->[$i]?(&{$ofunc->[$i]}($_)):$_) } @$dat if ($dat) ;
            }
        elsif ($linkname < 3)
            {
            my $r ;
            my $repl = $rs -> {'*ReplaceFields'} ;
            my $n ;
                
            foreach $r (@$repl)
                {
                $n = $DBIx::Recordset::PreserveCase?$names -> [$i]:lc ($names -> [$i]) ;
                $of = $ofunc -> [$i] ;
		$data -> {$n} = ($of?(&{$of}($dat->[$i])):$dat->[$i]) ;
                $data -> {uc($n)} = join (' ', map ({ ($ofunc->[$_]?(&{$ofunc->[$_]}($dat->[$_])):$dat->[$_])} @$r)) if ($#$r > 0 || $r -> [0] != $i) ;
                $i++ ;
                }
            }
        else
            {
            my $r ;
            my $repl = $rs -> {'*ReplaceFields'} ;
                
            foreach $r (@$repl)
                {
                $data -> {($DBIx::Recordset::PreserveCase?$$names[$i]:lc($$names[$i]))} = join (' ', map ({ ($ofunc->[$_]?(&{$ofunc->[$_]}($dat->[$_])):$dat->[$_])} @$r)) ;
		#print LOG "###repl $r -> $data->{$$names[$i]}\n" ;
                $i++ ;
                }
            }
        
        $self -> {'*Recordset'} = $rs ; 
        }

    if (!$new)
        {
        my $pk = $rs -> {'*PrimKey'} ;

        if ($pk && exists ($data -> {$pk})) 
            {
            $self -> {'*PrimKeyOrgValue'} = $data -> {$pk} ;
            }
        else
            {
            # save whole record for usage as key in later update
            %{$self -> {'*org'}} = %$data ;

            $self -> {'*PrimKeyOrgValue'} = $self -> {'*org'} ;
            }
        }


    return $self ;
    }

## ----------------------------------------------------------------------------

sub STORE
    {
    my ($self, $key, $value)  = @_ ;
    my $rs  = $self -> {'*Recordset'} ;  
    my $dat = $self -> {'*data'} ;
    
    local $^W = 0 ;

    print DBIx::Recordset::LOG "DB:  Row::STORE $key = $value\n" if ($rs->{'*Debug'} > 3) ;
    # any changes?
    if ($dat -> {$key} ne $value || defined ($dat -> {$key}) != defined($value))
	{
	# store the value and remeber it for later update
	$self -> {'*upd'}{$key} = \($dat -> {$_[1]} = $value) ;
	$self -> {'*dirty'}   = 1 ;                  # mark row dirty
	}
    }

## ----------------------------------------------------------------------------

sub FETCH
    {
    my ($self, $key) = @_ ;
    return undef if (!$key) ;
    my $rs   = $self -> {'*Recordset'} ;  
    my $data = $self -> {'*data'}{$key} ;
    my $link ;
    if (!defined($data))
        {
        if ($key eq '!Name')
            {
            my $nf = $rs -> {'*NameField'} || $rs -> TableAttr ('!NameField') ;
            if (!ref $nf)
                {
                return $self -> {'*data'}{$key} = $self -> {'*data'}{uc($nf)} || $self -> {'*data'}{$nf} ;
                }
            
            return $self -> {'*data'}{$key} = join (' ', map { $self -> {'*data'}{uc ($_)} || $self -> {'*data'}{$_} } @$nf) ;
            }
        elsif (defined ($link = $rs -> {'*Links'}{$key}))
            {
            my $lf = $link -> {'!LinkedField'} ;
            my $dat = $self -> {'*data'} ;
	    my $mv ;
	    if (exists ($dat -> {$link -> {'!MainField'}}))
		{ 
		$mv = $dat -> {$link -> {'!MainField'}} ;
		}
	    else
		{ 
		$mv = $dat -> {"$link->{'!MainTable'}.$link->{'!MainField'}"} ;
		}
            if ($link -> {'!UseHash'})
                {
                my $linkset = $rs -> {'*LinkSet'}{$key} ;
                if (!$linkset)
                    {
	            my $setup = {%$link} ;
                    $setup -> {'!PrimKey'} = $lf ;
                    $setup -> {'!DataSource'} = $rs if (!defined ($link -> {'!DataSource'})) ;
                    my %linkset ;
                    print DBIx::Recordset::LOG "DB:  Row::FETCH $key = Setup New Recordset for table $link->{'!Table'}, $lf = " . (defined ($mv)?$mv:'<undef>') . "\n" if ($rs->{'*Debug'} > 3) ;
                    $rs -> {'*LinkSet'}{$key} = $linkset = tie %linkset, 'DBIx::Recordset::Hash', $setup ;
                    }
                $data = $linkset -> FETCH ($mv) ;            
                }
            else
                {
                my $linkkey = "$key-$lf-$mv" ;
                my $linkset = $rs -> {'*LinkSet'}{$linkkey} ;
                if (!$linkset)
                    {
	            my $setup = {%$link} ;
                    $setup -> {$lf} = $mv ;
                    $setup -> {'!Default'} = { $lf => $mv } ;
                    $setup -> {'!DataSource'} = $rs if (!defined ($link -> {'!DataSource'})) ;
                    print DBIx::Recordset::LOG "DB:  Row::FETCH $key = Setup New Recordset for table $link->{'!Table'}, $lf = " . (defined ($mv)?$mv:'<undef>') . "\n" if ($rs->{'*Debug'} > 3) ;

                    $linkset = DBIx::Recordset -> Search ($setup) ;
                    $data = $self -> {'*data'}{$key} = DBIx::Recordset::Access -> new(\$linkset) ;

                    if ($link -> {'!Cache'})
                        {
                        $rs -> {'*LinkSet'}{$linkkey} = $linkset ;
                        }
                    }
                else
                    {
                    $$linkset -> Reset ;
                    $data = DBIx::Recordset::Access -> new(\$linkset) ;
                    }
                }

            my $of = $rs -> {'*OutputFunctions'}{$key} ;
	    $data = &{$of}($data) if ($of) ;	    
            }
        }

    if ($rs && $rs->{'*Debug'} > 3) { local $^W=0;print DBIx::Recordset::LOG "DB:  Row::FETCH " . (defined ($key)?$key:'<undef>') . " = <" . (defined ($data)?$data:'<undef>') . ">\n" } ;
    
    return $data ;
    }

## ----------------------------------------------------------------------------

sub FIRSTKEY
    {
    my ($self) = @_ ;
    my $a = scalar keys %{$self -> {'*data'}};
    
    return each %{$self -> {'*data'}} ;
    }

## ----------------------------------------------------------------------------

sub NEXTKEY
    {
    return each %{$_[0] -> {'*data'}} ;
    }

## ----------------------------------------------------------------------------

sub EXISTS
    {
    exists ($_[0]->{'*data'}{$_[1]}) ;
    }


## ----------------------------------------------------------------------------

sub DELETE
    {
    carp ("Cannot DELETE a field from a database record") ;
    }
                
## ----------------------------------------------------------------------------

sub CLEAR ($)

    {
    #carp ("Cannot DELETE all fields from a database record") ;
    } 

## ----------------------------------------------------------------------------
##
## report the cleanless of the row
##

sub Dirty { return $_[0]->{'*dirty'} }

## ----------------------------------------------------------------------------
##
## Flush data to database if row is dirty
##


sub Flush

    {
    my $self = shift ;
    my $rs    = $self -> {'*Recordset'} ;  
    
    return 1 if (!$rs) ;

    if ($self -> {'*dirty'}) 
        {
        my $rc ;
        print DBIx::Recordset::LOG "DB:  Row::Flush id=$rs->{'*Id'} $self\n" if ($rs->{'*Debug'} > 3) ;

        my $dat = $self -> {'*upd'} ;
        if ($self -> {'*new'})
            {
            $rc = $rs -> Insert ($dat)  ;
            }
        else
            {
            my $pko ;
            my $pk = $rs -> {'*PrimKey'} ;
            $dat->{$pk} = \($self -> {'*data'}{$pk}) if ($pk && !exists ($dat->{$pk})) ;
            #carp ("Need primary key to update record") if (!exists($self -> {"=$pk"})) ;
            if (!exists($self -> {'*PrimKeyOrgValue'})) 
                {
                $rc = $rs -> Update ($dat)  ;
                }
            elsif (ref ($pko = $self -> {'*PrimKeyOrgValue'}) eq 'HASH')
                {
                $rc = $rs -> Update ($dat, $pko)  ;
                }
            else
                {
                $rc = $rs -> Update ($dat, {$pk => $pko} )  ;
                }
            if ($rc != 1 && $rc ne '')
                { # must excatly be one row!
                print DBIx::Recordset::LOG "DB:  ERROR: Row Update has updated $rc rows instead of one ($rs->{'*LastSQLStatement'})\n" if ($rs->{'*Debug'}) ;
                #$rs -> savecroak ("DB:  ERROR: Row Update has updated $rc rows instead of one ($rs->{'*LastSQLStatement'})") ;            
                }	      
            }
        

        delete $self -> {'*new'} ;
        delete $self -> {'*dirty'} ;
        $self -> {'*upd'} = {} ;
        }

    my $k ;
    my $v ;
    my $lrs ;
    my $rname ;
    # "each" is not reentrant !!!!!!!!!!!!!!
    #while (($k, $v) = each (%{$rs -> {'*Links'}}))
    foreach $k (keys %{$rs -> {'*Links'}})
        { # Flush linked tables
        
        if ($lrs = $self->{'*data'}{$k})
            {
            $rname = '' ;
            $rname = eval {ref ($$lrs)} || '' ;
            ${$lrs} -> Flush () if ($rname eq 'DBIx::Recordset') ; #if (defined ($lrs) && ref ($lrs) && defined ($$lrs) && ) ;
            }
        }

    return 1 ;
    }



## ----------------------------------------------------------------------------

sub DESTROY

    {
    my $self = shift ;
    my $orgerr = $@ ;
    local $@ ;

    eval 
	{ 
    
	    {
	    local $^W = 0 ;
	    print DBIx::Recordset::LOG "DB:  Row::DESTROY\n" if ($DBIx::Recordset::Debug > 2 || $self -> {'*Recordset'} -> {'*Debug'} > 3) ;
	    }

	$self -> Flush () ;
	} ;
    if (!$orgerr && $@)
        {
        Carp::croak $@ ;
        }
    elsif ($orgerr && $@)   
        {
        warn $@  ;
        }
    }


################################################################################

1;
__END__

=pod

=head1 NAME

DBIx::Recordset - Perl extension for DBI recordsets

=head1 SYNOPSIS

 use DBIx::Recordset;

 # Setup a new object and select some recods...
 *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:Oracle:....',
                                    '!Table'      => 'users',
                                    '$where'      => 'name = ? and age > ?',
                                    '$values'     => ['richter', 25] }) ;

 # Get the values of field foo ...
 print "First Records value of foo is $set[0]{foo}\n" ;
 print "Second Records value of foo is $set[1]{foo}\n" ;
 # Get the value of the field age of the current record ...
 print "Age is $set{age}\n" ;

 # Do another select with the already created object...
 $set -> Search ({name => 'bar'}) ;

 # Show the result...
 print "All users with name bar:\n" ;
 while ($rec = $set -> Next)
    {
    print $rec -> {age} ;
    }

 # Setup another object and insert a new record
 *set2 = DBIx::Recordset -> Insert ({'!DataSource' => 'dbi:Oracle:....',
                                     '!Table'      => 'users',
                                     'name'        => 'foo',
                                     'age'         => 25 }) ;
 
 
 # Update this record (change age from 25 to 99)...
 $set -> Update ({age => 99}, {name => 'foo'}) ; 


=head1 DESCRIPTION

DBIx::Recordset is a perl module for abstraction and simplification of
database access.

The goal is to make standard database access (select/insert/update/delete)
easier to handle and independend of the underlying DBMS. Special attention is
made on web applications to make it possible to handle the state-less access
and to process the posted data of formfields, but DBIx::Recordset is not
limited to web applications.

B<DBIx::Recordset> uses the DBI API to access the database, so it should work with
every database for which a DBD driver is available (see also DBIx::Compat).

Most public functions take a hash reference as parameter, which makes it simple
to supply various different arguments to the same function. The parameter hash
can also be taken from a hash containing posted formfields like those available with
CGI.pm, mod_perl, HTML::Embperl and others.

Before using a recordset it is necessary to setup an object. Of course the
setup step can be made with the same function call as the first database access,
but it can also be handled separately.

Most functions which set up an object return a B<typglob>. A typglob in Perl is an 
object which holds pointers to all datatypes with the same name. Therefore a typglob
must always have a name and B<can't> be declared with B<my>. You can only
use it as B<global> variable or declare it with B<local>. The trick for using
a typglob is that setup functions can return a B<reference to an object>, an
B<array> and a B<hash> at the same time.

The object is used to access the object's methods, the array is used to access
the records currently selected in the recordset and the hash is used to access
the current record.

If you don't like the idea of using typglobs you can also set up the object,
array and hash separately, or just set the ones you need.

=head1 ARGUMENTS

Since most methods take a hash reference as argument, here is a
description of the valid arguments first.

=head2 Setup Parameters

All parameters starting with an '!' are only recognized at setup time.
If you specify them in later function calls they will be ignored.
You can also preset these parameters with the TableAttr method of 
DBIx::Database.  This allows you to presetup most parameters
for the whole database and they will be use every time you create a new
DBIx::Recordset object, without specifing it every time.

=item B<!DataSource>

Specifies the database to which to connect. This information can be given in
the following ways:

=over 4

=item Driver/DB/Host.

Same as the first parameter to the DBI connect function.

=item DBIx::Recordset object

Takes the same database handle as the given DBIx::Recordset object.

=item DBIx::Database object

Takes Driver/DB/Host from the given database object. See L<DBIx::Database> 
for details about DBIx::Database object. When using more then one Recordset
object, this is the most efficient method.

=item DBIx::Datasbase object name

Takes Driver/DB/Host from the database object which is saved under
the given name ($saveas parameter to DBIx::Database -> new)

=item an DBI database handle

Uses given database handle.

=back

=item B<!Table>

Tablename. Multiple tables are comma-separated.

=item B<!Username>

Username. Same as the second parameter to the DBI connect function.

=item B<!Password>

Password. Same as the third parameter to the DBI connect function.

=item B<!DBIAttr>

Reference to a hash which holds the attributes for the DBI connect
function. See perldoc DBI for a detailed description.

=item B<!Fields>

Fields which should be returned by a query. If you have specified multiple
tables the fieldnames should be unique. If the names are not unique you must
specify them along with the tablename (e.g. tab1.field).


NOTE 1: Fieldnames specified with !Fields can't be overridden. If you plan
to use other fields with this object later, use $Fields instead.

NOTE 2: The keys for the returned hash normally don't have a table part.
Only the fieldname part forms the key. (See !LongNames for an exception.)

NOTE 3: Because the query result is returned in a hash, there can only be
one out of multiple fields with the same name fetched at once.
If you specify multiple fields with the same name, only one is returned
from a query. Which one this actually is depends on the DBD driver.
(See !LongNames for an exception.)

NOTE 4: Some databases (e.g. mSQL) require you to always qualify a fieldname
with a tablename if more than one table is accessed in one query.

=item B<!TableFilter>

The TableFilter parameter specifies which tables should be honoured
when DBIx::Recordset searches for links between tables (see
below). When given as parameter to DBIx::Database it filters for which
tables DBIx::Database retrieves metadata. Only thoses tables are used
which starts with prefix given by C<!TableFilter>. Also the DBIx::Recordset
link detection tries to use this value as a prefix of table names, so
you can leave out this prefix when you write a fieldname that should
be detected as a link to another table.

=item B<!LongNames>

When set to 1, the keys of the hash returned for each record not only
consist of the fieldnames, but are built in the form table.field.

=item B<!Order>

Fields which should be used for ordering any query. If you have specified multiple
tables the fieldnames should be unique. If the names are not unique you must
specify them among with the tablename (e.g. tab1.field).


NOTE 1: Fieldnames specified with !Order can't be overridden. If you plan
to use other fields with this object later, use $order instead.


=item B<!TabRelation>

Condition which describes the relation between the given tables
(e.g. tab1.id = tab2.id) (See also L<!TabJoin>.)

  Example

  '!Table'       => 'tab1, tab2',
  '!TabRelation' => 'tab1.id=tab2.id',
  'name'         => 'foo'

  This will generate the following SQL statement:

  SELECT * FROM tab1, tab2 WHERE name = 'foo' and tab1.id=tab2.id ;


=item B<!TabJoin>

!TabJoin allows you to specify an B<INNER/RIGHT/LEFT JOIN> which is
used in a B<SELECT> statement. (See also L<!TabRelation>.)

  Example

  '!Table'   => 'tab1, tab2',
  '!TabJoin' => 'tab1 LEFT JOIN tab2 ON	(tab1.id=tab2.id)',
  'name'     => 'foo'

  This will generate the following SQL statement:

  SELECT * FROM tab1 LEFT JOIN tab2 ON	(tab1.id=tab2.id) WHERE name = 
'foo' ;



=item B<!PrimKey>

Name of the primary key. When this key appears in a WHERE parameter list
(see below), DBIx::Recordset will ignore all other keys in the list,
speeding up WHERE expression preparation and execution. Note that this
key does NOT have to correspond to a field tagged as PRIMARY KEY in a
CREATE TABLE statement.

=item B<!Serial>

Name of the primary key. In contrast to C<!PrimKey> this field is treated
as an autoincrement field. If the database does not support autoincrement fields,
but sequences the field is set to the next value of a sequence (see C<!Sequence> and C<!SeqClass>)
upon each insert. If a C<!SeqClass> is given the values are always retrived from the sequence class
regardless if the DBMS supports autoincrement or not.
The value from this field from the last insert could be retrieved
by the function C<LastSerial>.

=item C<!Sequence>

Name of the sequence to use for this table when inserting a new record and
C<!Serial> is defind. Defaults to <tablename>_seq.

=item C<!SeqClass>

Name and Parameter for a class that can generate unique sequence values. This is
a string that holds comma separated values. The first value is the class name and
the following parameters are given to the new constructor. See also I<DBIx::Recordset::FileSeq>
and I<DBIx::Recordset::DBSeq>. 

Example:  '!SeqClass' => 'DBIx::Recordset::FileSeq, /tmp/seq'


=item B<!WriteMode>

!WriteMode specifies which write operations to the database are allowed and which are
disabled. You may want to set !WriteMode to zero if you only need to query data, to
avoid accidentally changing the content of the database.

B<NOTE:> The !WriteMode only works for the DBIx::Recordset methods. If you
disable !WriteMode, it is still possible to use B<do> to send normal
SQL statements to the database engine to write/delete any data.

!WriteMode consists of some flags, which may be added together:

=over 4

=item DBIx::Recordset::wmNONE (0)

Allow B<no> write access to the table(s)

=item DBIx::Recordset::wmINSERT (1)

Allow INSERT

=item DBIx::Recordset::wmUPDATE (2)

Allow UPDATE

=item DBIx::Recordset::wmDELETE (4)

Allow DELETE

=item DBIx::Recordset::wmCLEAR (8)

To allow DELETE for the whole table, wmDELETE must be also specified. This is 
necessary for assigning a hash to a hash which is tied to a table. (Perl will 
first erase the whole table, then insert the new data.)

=item DBIx::Recordset::wmALL (15)

Allow every access to the table(s)


=back

Default is wmINSERT + wmUPDATE + wmDELETE


=item B<!StoreAll>

If present, this will cause DBIx::Recordset to store all rows which will be fetched between
consecutive accesses, so it's possible to access data in a random order. (e.g.
row 5, 2, 7, 1 etc.) If not specified, rows will only be fetched into memory
if requested, which means that you will have to access rows in ascending order.
(e.g. 1,2,3 if you try 3,2,4 you will get an undef for row 2 while 3 and 4 is ok)
see also B<DATA ACCESS> below.

=item B<!HashAsRowKey>

By default, the hash returned by the setup function is tied to the
current record. You can use it to access the fields of the current
record. If you set this parameter to true, the hash will by tied to the whole
database. This means that the key of the hash will be used as the primary key in
the table to select one row. (This parameter only has an effect on functions
which return a typglob.)

=item B<!IgnoreEmpty>

This parameter defines how B<empty> and B<undefined> values are handled. 
The values 1 and 2 may be helpful when using DBIx::Recordset inside a CGI
script, because browsers send empty formfields as empty strings.

=over 4

=item B<0 (default)>

An undefined value is treated as SQL B<NULL>: an empty string remains an empty 
string.

=item B<1>

All fields with an undefined value are ignored when building the WHERE expression.

=item B<2>

All fields with an undefined value or an empty string are ignored when building the 
WHERE expression.

=back

B<NOTE:> The default for versions before 0.18 was 2.

=item B<!Filter>

Filters can be used to pre/post-process the data which is read from/written to the database.
The !Filter parameter takes a hash reference which contains the filter functions. If the key
is numeric, it is treated as a type value and the filter is applied to all fields of that 
type. If the key if alphanumeric, the filter is applied to the named field.  Every filter 
description consists of an array with at least two elements.  The first element must contain the input
function, and the second element must contain the output function. Either may be undef, if only
one of them are necessary. The data is passed to the input function before it is written to the
database. The input function must return the value in the correct format for the database. The output
function is applied to data read from the database before it is returned
to the user.
 
 
 Example:

     '!Filter'   => 
	{
	DBI::SQL_DATE     => 
	    [ 
		sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
		sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
	    ],

	'datefield' =>
	    [ 
		sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
		sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
	    ],

	}

Both filters convert a date in the format dd.mm.yy to the database format 19yymmdd and
vice versa. The first one does this for all fields of the type SQL_DATE, the second one
does this for the fields with the name datefield.

The B<!Filter> parameter can also be passed to the function B<TableAttr> of the B<DBIx::Database>
object. In this case it applies to all DBIx::Recordset objects which use
these tables.

A third parameter can be optionally specified. It could be set to C<DBIx::Recordset::rqINSERT>,
C<DBIx::Recordset::rqUPDATE>, or the sum of both. If set, the InputFunction (which is called during
UPDATE or INSERT) is always called for this field in updates and/or inserts depending on the value.
If there is no data specified for this field
as an argument to a function which causes an UPDATE/INSERT, the InputFunction
is called with an argument of B<undef>.

During UPDATE and INSERT the input function gets either the string 'insert' or 'update' passed as
second parameter.



=item B<!LinkName>

This allows you to get a clear text description of a linked table, instead of (or in addition
to) the !LinkField. For example, if you have a record with all your bills, and each record contains
a customer number, setting !LinkName DBIx::Recordset can automatically retrieve the 
name of
the customer instead of (or in addition to) the bill record itself.

=over 4

=item 1 select additional fields

This will additionally select all fields given in B<!NameField> of the Link or the table
attributes (see TableAttr).

=item 2 build name in uppercase of !MainField

This takes the values of B<!NameField> of the Link or the table attributes (see 
TableAttr)
and joins the content of these fields together into a new field, which has the same name
as the !MainField, but in uppercase.


=item 2 replace !MainField with the contents of !NameField

Same as 2, but the !MainField is replaced with "name" of the linked record.

=back

See also B<!Links> and B<WORKING WITH MULTIPLE TABLES> below



=item B<!Links>

This parameter can be used to link multiple tables together. It takes a
reference to a hash, which has - as keys, names for a special B<"linkfield">
and - as value, a parameter hash. The parameter hash can contain all the
B<Setup parameters>. The setup parameters are taken to construct a new
recordset object to access the linked table. If !DataSource is omitted (as it
normally should be), the same DataSource (and database handle), as the
main object is taken. There are special parameters which can only 
occur in a link definition (see next paragraph). For a detailed description of
how links are handled, see B<WORKING WITH MULTIPLE TABLES> below.

=head2 Link Parameters

=item B<!MainField>

The B<!MailField> parameter holds a fieldname which is used to retrieve
a key value for the search in the linked table from the main table.
If omitted, it is set to the same value as B<!LinkedField>.

=item B<!LinkedField>

The fieldname which holds the key value in the linked table.
If omitted, it is set to the same value as B<!MainField>.

=item B<!NameField>

This specifies the field or fields which will be used as a "name" for the destination table. 
It may be a string or a reference to an array of strings.
For example, if you link to an address table, you may specify the field "nickname" as the 
name field
for that table, or you may use ['name', 'street', 'city'].

Look at B<!LinkName> for more information.


=item B<!DoOnConnect>

You can give an SQL Statement (or an array reference of SQL statements), that will be
executed every time, just after an connect to the db. As third possibilty you can give an
hash reference. After every successful connect, DBIx::Recordset excutes the statements, in
the element which corresponds to the name of the driver. '*' is executed for all drivers. 

=item B<!Default>

Specifies default values for new rows that are inserted via hash or array access. The Insert
method ignores this parameter.

=item B<!TieRow>

Setting this parameter to zero will cause DBIx::Recordset to B<not> tie the returned rows to
an DBIx::Recordset::Row object and instead returns an simple hash. The benefit of this is
that it will speed up things, but you aren't able to write to such an row, nor can you use
the link feature with such a row.

=item B<!Debug>

Set the debug level. See DEBUGGING.


=item B<!PreFetch>

Only for tieing a hash! Gives an where expression (either as string or as hashref) 
that is used to prefetch records from that
database. All following accesses to the tied hash only access this prefetched data and
don't execute any database queries. See C<!Expires> how to force a refetch.
Giving a '*' as value to C<!PreFetch> fetches the whole table into memory.

 The following example prefetches all record with id < 7:

 tie %dbhash, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $DSN,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  'foo',
                                        '!PreFetch'     =>  {
                                                             '*id' => '<',
                                                             'id' => 7
                                                            },
                                        '!PrimKey'      =>  'id'} ;

 The following example prefetches all records:

 tie %dbhash, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $DSN,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  'bar',
                                        '!PreFetch'     =>  '*',
                                        '!PrimKey'      =>  'id'} ;

=item B<!Expires>

Only for tieing a hash! If the values is numeric, the prefetched data will be refetched 
is it is older then the given number of seconds. If the values is a CODEREF the function
is called and the data is refetched is the function returns true.

=item B<!MergeFunc>

Only for tieing a hash! Gives an reference to an function that is called when more then one
record for a given hash key is found to merge the records into one. The function receives
a refence to both records a arguments. If more the two records are found, the function is
called again for each following record, which is already merged data as first parameter.

 The following example sets up a hash, that, when more then one record with the same id is
 found, the field C<sum> is added and the first record is returned, where the C<sum> field
 contains the sum of B<all> found records:

 tie %dbhash, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $DSN,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  'bar',
                                        '!MergeFunc'    =>  sub { my ($a, $b) = @_ ; $a->{sum} += $b->{sum} ; },
                                        '!PrimKey'      =>  'id'} ;

=head2 Where Parameters

The following parameters are used to build an SQL WHERE expression

=item B<$where>

Give an SQL WHERE expression literaly. If C<$where> is specified, all
other where parameters described below are ignored. The only expection
is C<$values> which can be used to give the values to bind to the
placeholders in C<$where>

=item B<$values>

Values which should be bound to the placeholders given in C<$where>.

 Example:

 *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:Oracle:....',
                                    '!Table'      => 'users',
                                    '$where'      => 'name = ? and age > ?',
                                    '$values'     => ['richter', 25] }) ;
 

B<NOTE:> Filters defined with C<!Filter> are B<not> applied to these values, 
because DBIx::Recordset has no chance to know with values belongs to
which field.


=item B<{fieldname}>

Value for field. The value will be quoted automatically, if necessary.
The value can also be an array ref in which case the values are put
together with the operator passed via B<$valueconj> (default: or)

  Example:

  'name' => [ 'mouse', 'cat'] will expand to name='mouse' or name='cat'


=item B<'{fieldname}>

Value for field. The value will always be quoted. This is only necessary if
DBIx::Recordset cannot determine the correct type for a field.

=item B<#{fieldname}>

Value for field. The value will never be quoted, but will converted a to number.
This is only necessary if
DBIx::Recordset cannot determine the correct type for a field.

=item B<\{fieldname}>

Value for field. The value will not be converted in any way, i.e. you have to
quote it before supplying it to DBIx::Recordset if necessary.

=item B<+{fieldname}|{fieldname}..>

Values for multiple fields. The value must be in one/all fields depending on $compconj
 Example:
 '+name|text' => 'abc' will expand to name='abc' or text='abc'

=item B<$compconj>

'or' or 'and' (default is 'or'). Specifies the conjunction between multiple
fields. (see above)

=item B<$valuesplit>

Regular expression for splitting a field value in multiple values
(default is '\t') The conjunction for multiple values could be specified
with B<$valueconj>. By default, only one of the values must match the field.


 Example:
 'name' => "mouse\tcat" will expand to name='mouse' or name='cat'

 NOTE: The above example can also be written as 'name' => [ 'mouse', 'cat']


=item B<$valueconj>

'or' or 'and' (default is 'or'). Specifies the conjunction for multiple values.

=item B<$conj>

'or' or 'and' (default is 'and') conjunction between fields

=item B<$operator>

Default operator if not otherwise specified for a field. (default is '=')

=item B<*{fieldname}>

Operator for the named field

 Example:
 'value' => 9, '*value' => '>' expand to value > 9


Could also be an array ref, so you can pass different operators for the values. This
is mainly handy when you need to select a range

  Example:

    $set -> Search  ({id          => [5,    7   ],
                     '*id'        => ['>=', '<='],
                     '$valueconj' => 'and'})  ;

  This will expanded to "id >= 5 and id <= 7"

NOTE: To get a range you need to specify the C<$valueconj> parameter as C<and> because
it defaults to C<or>.

=item B<$expr>

B<$expr> can be used to group parts of the where expression for proper priority. To
specify more the one sub expression, add a numerical index to $expr (e.g. $expr1, $expr2)

  Example:

    $set -> Search  ({id          => 5,
                     '$expr'      => 
                        {
                        'name'  => 'Richter',
                        'country' => 'de',
                        '$conj'   => 'or'
                        }
                      }) ;

    This will expand to

        (name = 'Richter' or country = 'de') and id = 5
                     

=head2 Search parameters

=item B<$start>

First row to fetch. The row specified here will appear as index 0 in
the data array.

=item B<$max>

Maximum number of rows to fetch. Every attempt to fetch more rows than specified
here will return undef, even if the select returns more rows.

=item B<$next>

Add the number supplied with B<$max> to B<$start>. This is intended to implement
a next button.

=item B<$prev>

Subtract the number supplied with B<$max> from B<$start>. This is intended to 
implement
a previous button.

=item B<$order>

Fieldname(s) for ordering (ORDER BY) (must be comma-separated, could also contain 
USING)

=item B<$group>

Fieldname(s) for grouping (GROUP BY) (must be comma-separated, could also contain 
HAVING).

=item B<$append>

String which is appended to the end of a SELECT statement, can contain any data.

=item B<$fields>

Fields which should be returned by a query. If you have specified multiple
tables the fieldnames should be unique. If the names are not unique you must
specify them along with the tablename (e.g. tab1.field).


NOTE 1: If B<!fields> is supplied at setup time, this can not be overridden
by $fields.

NOTE 2: The keys for the returned hash normally don't have a table part.
Only the fieldname
part forms the key. (See !LongNames for an exception.)

NOTE 3: Because the query result is returned in a hash, there can only be
one out of multiple fields  with the same name fetched at once.
If you specify multiple fields with same name, only one is returned
from a query. Which one this actually is, depends on the DBD driver.
(See !LongNames for an exception.)

=item B<$primkey>

Name of primary key. DBIx::Recordset assumes that if specified, this is a unique
key to the given table(s). DBIx::Recordset can not verify this. You are responsible
for specifying the right key. If such a primary exists in your table, you
should specify it here, because it helps DBIx::Recordset optimize the building
of WHERE expressions.

See also B<!PrimKey>


=head2 Execute parameters

The following parameters specify which action is to be executed:

=item B<=search>

search data

=item B<=update>

update record(s)

=item B<=insert>

insert record

=item B<=delete>

delete record(s)

=item B<=empty>

setup empty object


=head1 METHODS

=over 4

=item B<*set = DBIx::Recordset -E<gt> Setup (\%params)>

Setup a new object and connect it to a database and table(s). Collects
information about the tables which are needed later. Returns a typglob
which can be used to access the object ($set), an array (@set) and a 
hash (%set).

B<params:> setup

=item B<$set = DBIx::Recordset -E<gt> SetupObject (\%params)>

Same as above, but setup only the object, do not tie anything (no array, no hash)

B<params:> setup

=item B<$set = tie @set, 'DBIx::Recordset', $set>

=item B<$set = tie @set, 'DBIx::Recordset', \%params>

Ties an array to a recordset object. The result of a query which is executed
by the returned object can be accessed via the tied array. If the array contents
are modified, the database is updated accordingly (see Data access below for
more details). The first form ties the array to an already existing object, the 
second one setup a new object.

B<params:> setup


=item B<$set = tie %set, 'DBIx::Recordset::Hash', $set>

=item B<$set = tie %set, 'DBIx::Recordset::Hash', \%params>

Ties a hash to a recordset object. The hash can be used to access/update/insert
single rows of a table: the hash key is identical to the primary key
value of the table. (see Data access below for more details)

The first form ties the hash to an already existing object, the second one
sets up a new object.

B<params:> setup



=item B<$set = tie %set, 'DBIx::Recordset::CurrRow', $set>

=item B<$set = tie %set, 'DBIx::Recordset::CurrRow', \%params>

Ties a hash to a recordset object. The hash can be used to access the fields
of the current record of the recordset object.
(See Data access below for more details.)

The first form ties the hash to an already existing object, the second one
sets up a new object.

B<params:> setup


=item B<*set = DBIx::Recordset -E<gt> Select (\%params, $fields, $order)>

=item B<$set -E<gt> Select (\%params, $fields, $order)>

=item B<$set -E<gt> Select ($where, $fields, $order)>

Selects records from the recordsets table(s).

The first syntax setups a new DBIx::Recordset object and does the select.

The second and third syntax selects from an existing DBIx::Recordset object.


B<params:> setup (only syntax 1), where  (without $order and $fields)

B<where:>  (only syntax 3) string for SQL WHERE expression

B<fields:> comma separated list of fieldnames to select

B<order:>  comma separated list of fieldnames to sort on



=item B<*set = DBIx::Recordset -E<gt> Search (\%params)>

=item B<set -E<gt> Search (\%params)>

Does a search on the given tables and prepares data to access them via
@set or %set. The first syntax also sets up a new object.

B<params:> setup (only syntax 1), where, search


=item B<*set = DBIx::Recordset -E<gt> Insert (\%params)>

=item B<$set -E<gt> Insert (\%params)>

Inserts a new record in the recordset table(s). Params should contain one
entry for every field for which you want to insert a value.

Fieldnames may be prefixed with a '\' in which case they are not processed (quoted)
in any way.

B<params:> setup (only syntax 1), fields



=item B<*set = DBIx::Recordset -E<gt> Update (\%params, $where)>

=item B<*set = DBIx::Recordset -E<gt> Update (\%params, $where)>

=item B<set -E<gt> Update (\%params, $where)>

=item B<set -E<gt> Update (\%params, $where)>

Updates one or more records in the recordset table(s). Parameters should contain
one entry for every field you want to update. The $where contains the SQL WHERE
condition as a string or as a reference to a hash. If $where is omitted, the
where conditions are buily from the parameters. If !PrimKey is given for the
table, only that !PrimKey is used for the WHERE clause.

Fieldnames may be prefixed with a '\', in which case they are not processed (quoted)
in any way.


B<params:> setup (only syntax 1+2), where (only if $where is omitted), fields



=item B<*set = DBIx::Recordset -E<gt> Delete (\%params)>

=item B<$set -E<gt> Delete (\%params)>

Deletes one or more records from the recordsets table(s).

B<params:> setup (only syntax 1), where

=item B<*set = DBIx::Recordset -E<gt> DeleteWithLinks (\%params)>

=item B<$set -E<gt> DeleteWithLinks (\%params)>

Deletes one or more records from the recordsets table(s).
Additonal all record of links with have the C<!OnDelete> set, are either
deleted or the correspending field is set to undef. What to do
is determinated by the constants C<odDELETE> and C<odCLEAR>. This is
very helpfull to guaratee the inetgrity of the database.

B<params:> setup (only syntax 1), where



=item B<*set = DBIx::Recordset -E<gt> Execute (\%params)>

=item B<$set -E<gt> Execute (\%params)>

Executes one of the above methods, depending on the given arguments.
If multiple execute parameters are specified, the priority is
 =search
 =update
 =insert
 =delete
 =empty

If none of the above parameters are specified, a search is performed.
A search is always performed.  On an C<=update>, the C<!PrimKey>, if given, is looked upon
and used for the where part of the SQL statement, while all other parameters
are updated.


B<params:> setup (only syntax 1), execute, where, search, fields


=item B<$set -E<gt> do ($statement, $attribs, \%params)>

Same as DBI. Executes a single SQL statement on the open database.

=item B<$set -E<gt> Reset ()>

Set the record pointer to the initial state, so the next call to 

C<Next> returns the first row.

=item B<$set -E<gt> First ()>

Position the record pointer to the first row and returns it.


=item B<$set -E<gt> Next ()>

Position the record pointer to the next row and returns it.


=item B<$set -E<gt> Prev ()> 

Position the record pointer to the previous row and returns it.

=item B<$set -E<gt> Curr ()> 

Returns the current row.

=item B<$set -E<gt> AllNames ()>

Returns a reference to an array of all fieldnames of all tables
used by the object.

=item B<$set -E<gt> Names ()>

Returns a reference to an array of the fieldnames from the last
query.

=item B<$set -E<gt> AllTypes ()>

Returns a reference to an array of all fieldtypes of all tables
used by the object.

=item B<$set -E<gt> Types ()>

Returns a reference to an array of the fieldtypes from the last
query.

=item B<$set -E<gt> Add ()>

=item B<$set -E<gt> Add (\%data)>

Adds a new row to a recordset. The first one adds an empty row, the
second one will assign initial data to it.
The Add method returns an index into the array where the new record
is located.

  Example:

  # Add an empty record
  $i = $set -> Add () ;
  # Now assign some data
  $set[$i]{id} = 5 ;
  $set[$i]{name} = 'test' ;
  # and here it is written to the database
  # (without Flush it is written, when the record goes out of scope)
  $set -> Flush () ;

Add will also set the current record to the newly created empty
record. So, you can assign the data by simply using the current record.

  # Add an empty record
  $set -> Add () ;
  # Now assign some data to the new record
  $set{id} = 5 ;
  $set{name} = 'test' ;


=item B<$set -E<gt> MoreRecords ([$ignoremax])>

Returns true if there are more records to fetch from the current
recordset. If the $ignoremax parameter is specified and is true, 
MoreRecords ignores the $max parameter of the last Search.

To tell you if there are more records, More actually fetches the next
record from the database and stores it in memory. It does not, however, 
change the current record.

=item B<$set -E<gt> PrevNextForm ($prevtext, $nexttext, \%fdat)>

=item B<$set -E<gt> PrevNextForm (\%param, \%fdat)>

Returns a HTML form which contains a previous and a next button and
all data from %fdat, as hidden fields. When calling the Search method,
You must set the $max parameter to the number of rows
you want to see at once. After the search and the retrieval of the
rows, you can call PrevNextForm to generate the needed buttons for
scrolling through the recordset.

The second for allows you the specifies addtional parameter, which creates
first, previous, next, last and goto buttons. Example:

 $set -> PrevNextForm ({-first => 'First',  -prev => '<<Back', 
                        -next  => 'Next>>', -last => 'Last',
                        -goto  => 'Goto #'}, \%fdat)

The goto button lets you jump to an random record number. If you obmit any
of the parameters, the corresponding button will not be shown.



=item B<$set -E<gt> Flush>

The Flush method flushes all data to the database and therefore makes sure
that the db is up-to-date. Normally, DBIx::Recordset holds the update in memory
until the row is destroyed, by either a new Select/Search or by the Recordsetobject
itself is destroyed. With this method you can make sure that every update is
really written to the db.

=item $set -> Dirty ()

Returns true if there is at least one dirty row containing unflushed data.



=item B<DBIx::Recordset::Undef ($name)>

Undef takes the name of a typglob and will destroy the array, the hash,
and the object. All unwritten data is  written to the db.  All
db connections are closed and all memory is freed.

  Example:
  # this destroys $set, @set and %set
  DBIx::Recordset::Undef ('set') ;



=item B<$set -E<gt> Begin>

Starts a transaction. Calls the DBI method begin.


=item B<$set -E<gt> Rollback>

Rolls back a transaction. Calls the DBI method rollback and makes sure that all 
internal buffers of DBIx::Recordset are flushed.


=item B<$set -E<gt> Commit>

Commits a transaction. Calls the DBI method commit and makes sure that all 
internal buffers of DBIx::Recordset are flushed.


=item B<$set -E<gt> DBHdl ()>

Returns the DBI database handle.


=item B<$set -E<gt> StHdl ()>

Returns the DBI statement handle of the last select.

=item $set -> TableName ()

Returns the name of the table of the recordset object.

=item $set -> TableNameWithOutFilter ()

Returns the name of the table of the recordset object, but removes
the string given with !TableFilter, if it is the prefix of the table name.

=item $set -> PrimKey ()

Returns the primary key given in the !PrimKey parameter.

=item $set -> TableFilter ()

Returns the table filter given in the !TableFilter parameter.



=item B<$set -E<gt> StartRecordNo ()>

Returns the record number of the record which will be returned for index 0.


=item B<$set -E<gt> LastSQLStatement ()>

Returns the last executed SQL Statement.

=item B<$set -E<gt> LastSerial ()>

Return the last value of the field defined with !Serial

=item B<$set -E<gt> Disconnect ()>

Closes the connection to the database.


=item B<$set -E<gt> Link($linkname)>

If $linkname is undef, returns reference to a hash of all links
of the object. Otherwise, it returns a reference to the link with 
the given name.

=item B<$set -E<gt> Links()>

Returns reference to a hash of all links
of the object.


=item B<$set -E<gt> Link4Field($fieldname)>

Returns the name of the link for that field, or <undef> if
there is no link for that field.


=item $set -> TableAttr ($key, $value, $table)

get and/or set an attribute of the table

=over 4

=item $key

key to set/get

=item $value

if present, set key to this value

=item $table

Optional, let you specify another table, then the one use by the recordset object.

=back

=item $set -> Stats ()

Returns an hash ref with some statistical values.

=item $set -> LastError ()

=item DBIx::Recordset -> LastError ()

Returns the last error message, if any. If called in an array context the first
element receives the last error message and the second the last error code.


=back


=head1 DATA ACCESS

The data which is returned by a B<Select> or a B<Search> can be accessed
in two ways:

1.) Through an array. Each item of the array corresponds to one of
the selected records. Each array-item is a reference to a hash containing
an entry for every field.

Example:
 $set[1]{id}	    access the field 'id' of the second record found
 $set[3]{name}	    access the field 'name' of the fourth record found

The record is fetched from the DBD driver when you access it the first time
and is stored by DBIx::Recordset for later access. If you don't access the records
one after each other, the skipped records are not stored and therefore can't be
accessed anymore, unless you specify the B<!StoreAll> parameter.

2.) DBIx::Recordset holds a B<current record> which can be accessed directly via
a hash. The current record is the one you last accessed via the array. After
a Select or Search, it is reset to the first record. You can change the current
record via the methods B<Next>, B<Prev>, B<First>, B<Add>.

Example:
 $set{id}	    access the field 'id' of the current record
 $set{name}	    access the field 'name' of the current record



Instead of doing a B<Select> or B<Search> you can directly access one row
of a table when you have tied a hash to DBIx::Recordset::Hash or have
specified the B<!HashAsRowKey> Parameter.
The hashkey will work as primary key to the table. You must specify the
B<!PrimKey> as setup parameter.

Example:
 $set{4}{name}	    access the field 'name' of the row with primary key = 4

=head1 MODIFYING DATA DIRECTLY

One way to update/insert data into the database is by using the Update, Insert
or Execute method of the DBIx::Recordset object. A second way is to directly
assign new values to the result of a previous Select/Search.

Example:
  # setup a new object and search all records with name xyz
  *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:db:tab',
				     '!PrimKey => 'id',
				     '!Table'  => 'tabname',
				     'name'    => 'xyz'}) ;

  #now you can update an existing record by assigning new values
  #Note: if possible, specify a PrimKey for update to work faster
  $set[0]{'name'} = 'zyx' ;

  # or insert a new record by setting up an new array row
  $set[9]{'name'} = 'foo' ;
  $set[9]{'id'}   = 10 ;

  # if you don't know the index of a new row you can obtain
  # one by using Add
  my $i = $set -> Add () ;
  $set[$i]{'name'} = 'more foo' ;
  $set[$i]{'id'}   = 11 ;

  # or add an empty record via Add and assign the values to the current
  # record
  $set -> Add () ;
  $set{'name'} = 'more foo' ;
  $set{'id'}   = 11 ;

  # or insert the data directly via Add
  $set -> Add ({'name' => 'even more foo',
		'id'   => 12}) ;

  # NOTE: up to this point, NO data is actually written to the db!

  # we are done with that object,  Undef will flush all data to the db
  DBIx::Recordset::Undef ('set') ;

IMPORTANT: The data is not written to the database until you explicitly
call B<flush>, or a new query is started, or the object is destroyed. This is 
to keep the actual writes to the database to a minimum.

=head1 WORKING WITH MULTIPLE TABLES

DBIx::Recordset has some nice features to make working with multiple tables
and their relations easier. 

=head2 Joins

First, you can specify more than one
table to the B<!Table> parameter. If you do so, you need to specify how both
tables are related. You do this with B<!TabRelation> parameter. This method
will access all the specified tables simultanously.

=head2 Join Example:

If you have the following two tables, where the field street_id is a 
pointer to the table street:

  table name
  name	    char (30),
  street_id  integer

  table street
  id	    integer,
  street    char (30),
  city      char (30)

You can perform the following search:

  *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:drv:db',
		     '!Table'	   => 'name, street',
		     '!TabRelation'=> 'name.street_id = street.id'}) ;

The result is that you get a set which contains the fields B<name>, B<street_id>,
B<street>, B<city> and B<id>, where id is always equal to street_id. If there are multiple
streets for one name, you will get as many records for that name as there are streets
present for it. For this reason, this approach works best when you have a 
1:1 relation.

It is also possible to specify B<JOINs>. Here's how:

  *set = DBIx::Recordset -> Search ({
            '!DataSource' => 'dbi:drv:db',
	    '!Table'   => 'name, street',
	    '!TabJoin' => 'name LEFT JOIN street ON (name.street_id=street.id)'}) ;


The difference between this and the first example is that this version 
also returns a record even if neither table contains a record for the 
given id. The way it's done depends on the JOIN you are given (LEFT/RIGHT/INNER) 
(see your SQL documentation for details about JOINs).

=head2 Links

If you have 1:n relations between two tables, the following may be a better
way to handle it:

  *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:drv:db',
		     '!Table'	   => 'name',
		     '!Links'	   => {
			'-street'  => {
			    '!Table' => 'street',
			    '!LinkedField' => 'id',
			    '!MainField'   => 'street_id'
			    }
			}
		    }) ;

After that query, every record will contain the fields B<name> and B<street_id>.
Additionally, there is a pseudofield named B<-street>, which could be
used to access another recordset object, which is the result of a query
where B<street_id = id>. Use

  $set{name} to access the name field
  $set{-street}{street} to access the first street (as long as the
				    current record of the subobject isn't
				    modified)

  $set{-street}[0]{street}	first street
  $set{-street}[1]{street}	second street
  $set{-street}[2]{street}	third street

  $set[2]{-street}[1]{street} to access the second street of the
				    third name

You can have multiple linked tables in one recordset; you can also nest
linked tables or link a table to itself.


B<NOTE:> If you select only some fields and not all, the field which is specified by
'!MainField' must be also given in the '!Fields' or '$fields' parameter.

B<NOTE:> See also B<Automatic detection of links> below

=head2 LinkName

In the LinkName feature you may specify a "name" for every table. A name is one or 
more fields
which gives a human readable "key" of that record. For example in the above example 
B<id> is the
key of the record, but the human readable form is B<street>. 


  *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:drv:db',
		     '!Table'	   => 'name',
		     '!LinkName'   => 1,
		     '!Links'	   => {
			'-street'  => {
			    '!Table' => 'street',
			    '!LinkedField' => 'id',
			    '!MainField'   => 'street_id',
			    '!NameField'   => 'street'
			    }
			}
		    }) ;

For every record in the table, this example will return the fields:

  name  street_id  street

If you have more complex records, you may also specify more than one field in 
!NameField and pass it as an reference to an array e.g. ['street', 'city']. 
In this case, the result will contain

  name  street_id  street  city

If you set !LinkName to 2, the result will contain the fields

  name  street_id  STREET_ID

where STREET_ID contains the values of the street and city fields joined together. If you 
set !LinkName
to 3, you will get only

  name  street_id

where street_id contains the values of the street and city fields joined together. 


NOTE: The !NameField can also be specified as a table attribute with the function 
TableAttr. In this
case you don't need to specify it in every link. When a !NameField is given in a link 
description,
it overrides the table attribute.


=head2 Automatic detection of links

DBIx::Recordset and DBIx::Database will try to automatically detect links between tables
based on the field and table names. For this feature to work, the field which points to 
another table must consist of the table name and the field name of the destination joined
together with an underscore (as in the above example name.street_id). Then it will 
automatically recognized as a pointer to street.id.

  *set = DBIx::Recordset -> Search ({'!DataSource' => 'dbi:drv:db',
				     '!Table'	   => 'name') ;

is enough. DBIx::Recordset will automatically add the !Links attribute. 
Additionally, DBIx::Recordset adds a backlink (which starts with a star ('*')), so for the
table street, in our above example,
there will be a link, named *name, which is a pointer from table street to all records in the
table name where street.id is equal to name.street_id.

You may use the
!Links attribute to specify links which can not be automatically detected.

NOTE: To specify more then one link from one table to another table, you may prefix the field name
with an specifier followed by two underscores. Example:  first__street_id, second__street_id.
The link (and backlink) names are named with the prefix, e.g. -first__street and the backlink
*first__name.


=head1 DBIx::Database

The DBIx::Database object gathers information about a datasource. Its main purpose is 
to create, at startup, an object which retrieves all necessary information from the 
database.  This object detects links between tables and stores this information for use 
by the DBIx::Recordset objects. There are additional methods which allow you to add kinds 
of information which cannot be retreived automatically.

Example:

  $db = DBIx::Database -> new ({'!DataSource'   =>  $DSN,
		                '!Username'     =>  $User,
				'!Password'     =>  $Password,
                                '!KeepOpen'     => 1}) ;

   *set = DBIx::Recordset -> Search ({'!DataSource'   =>  $db,
			              '!Table'        =>  'foo',
				     })  ;




=head2 new ($data_source, $username, $password, \%attr, $saveas, $keepopen)

=over 4

=item $data_source

Specifies the database to which to connect. 
Driver/DB/Host. Same as the first parameter to the DBI connect function.

=item $username

Username (optional)

=item $password

Password (optional) 

=item \%attr 

Attributes (optional) Same as the attribute parameter to the DBI connect function.

=item $saveas

Name for this DBIx::Database object to save as.
The name can be used in DBIx::Database::Get, or as !DataSource parameter in call to the
DBIx::Recordset object.

This is intended as mechanism to retrieve the necessary metadata; for example, when 
your web server starts (e.g. in the startup.pl file of mod_perl). 
Here you can give the database
object a name. Later in your mod_perl or Embperl scripts, you can use this metadata by
specifying this name. This will speed up the setup of DBIx::Recordset object without the 
need to pass a reference to the DBIx::Database object.


=item $keepopen

Normaly the database connection will be closed after the metadata has been retrieved from
the database. This makes sure you don't get trouble when using the new method in a mod_perl
startup file. You can keep the connection open to use them in further setup calls to DBIx::Recordset
objects. When the database is not kept open, you must specify the C<!Password> parameter each
time the recordset has to be reopend.

=item $tabfilter

same as setup parameter !TableFilter

=item $doonconnect

same as setup parameter !DoOnConnect

=item $reconnect

If set, forces I<DBIx::Database> to C<undef> any preexisting database handle and call connect in any
case. This is usefull in together with I<Apache::DBI>. While the database connection are still kept
open by I<Apache::DBI>, I<Apache::DBI> preforms a test if the handle is still vaild (which DBIx::Database
itself wouldn't).

=back

You also can specify a hashref which can contain the following parameters:

!DataSource, !Username, !Password, !DBIAttr, !SaveAs, !KeepOpen, !TableFilter, !DoOnConnect, !Reconnect


=head2 $db = DBIx::Database -> DBHdl 

returns the database handle (only if you specify !KeepOpen when calling C<new>).


=head2 $db = DBIx::Database -> Get ($name)

$name = The name of the DBIx::Database object you wish to retrieve 


Get a DBIx::Database object which has already been set up based on the name.



=head2 $db -> TableAttr ($table, $key, $value)

get and/or set an attribute for an specfic table.

=over 4

=item $table

Name of table(s). You may use '*' instead of the table
name to specify a default value which applies to all
tables for which no other value is specified.

=item $key

key to set/get

=item $value

if present, set key to this value

=back

=head2 $db -> TableLink ($table, $linkname, $value)

Get and/or set a link description for an table. If no $linkname
is given, returns all links for that table.

=over 4

=item $table

Name of table(s)

=item $linkname

Name of link to set/get

=item $value

if present, this must be a reference to a hash with the link decription.
See !Links for more information.

=back


=head2 $db -> MetaData ($table, $metadata, $clear)

Get and/or set the meta data for the given table.

=over 4

=item $table

Name of table(s)

=item $metadata

If present, this must be a reference to a hash with the new metadata. You
should only use this if you really know what you are doing.

=item $clear

Clears the metadata for the given table, The next call to DBIx::Database -> new
will recreate the metadata. Useful if your table has changed (e.g. by
ALTER TABLE).

=back

=head2 $db -> AllTables

This returns a reference to a hash of the keys to all the tables of 
the datasource.

=head2 $db -> AllNames ($table)

Returns a reference to an array of all fieldnames for the given table.

=head2 $db -> AllTypes ($table)

Returns a reference to an array of all fieldtypes for the given table.

=item $db -> do ($statement, $attribs, \%params)

Same as DBI. Executes a single SQL statement on the open database.



=head2 $db -> CreateTables ($dbschema, $schemaname, $user, $setpriv, $alterconstraints)

The CreateTables method is used to create an modify the schema of your database. 
The idea is to define the schema as a Perl data structure and give it to this function,
it will compare the actual schema of the database with the one provided and creates
new tables, new fields or drop fields as neccessary. It also sets the permission on the
tables and is able to create indices for the tables. It will B<never> drop a whole table!
NOTE: Create tables cannot deteminate changes of the datatype of a fields, because DBI is
not able to provide this information in a standart way.

=over 4

=item $dbschema

Either the name of a file which contains the schema or a array ref. See below how this
schema must look like. 

=item $schemaname

schemaname (only used for Oracle)

=item $user

User that should be granted access. See C<!Grant> parameter.

=item $setpriv

If set to true, access privilegs are revoked and granted again for already existing tables.
That is necessary when C<$user> changes.

=item $alterconstraints

If set to true contrains are cleared/set for already existing fields. DBI doesn't provide a
database independ way to check which contrains already exists.

=back

=head2 Schema definition

If give as a filename, the file must contain an hash C<%DBDefault> and an array C<@DBSchema>. 
The first gives default and the second is an array of hashs. Every of this hash defines one
table.

Example:

  %DBDefault = 

    (
    '!Grant' => 
        [
        'select', 
        'insert',
        'update',
        'delete',
        ],
    )
     ;


  @DBSchema = (

    {
    '!Table' => 'language',
    '!Fields' => 
        [
        'id'            => 'char (2)',
        'directory'     => 'varchar(40)',
        'name'          => 'varchar(40)',
        'europe'        => 'bool', 
        ],
    '!PrimKey' => 'id',
    '!Default' =>
        {
        'europe'    => 1,
        },
    '!Init' =>
        [
        {'id' => 'de', 'directory' => 'html_49', 'name' => 'deutsch'},
        {'id' => 'en', 'directory' => 'html_76', 'name' => 'english'},
        {'id' => 'fr', 'directory' => 'html_31', 'name' => 'french'},
        ],
   '!Index' =>
        [
        'directory' => '',
        ]
 
    },

  );

The hash which defines a table can have the following keys:

=over 4

=item !Table

Gives the table name

=item !Fields

Array with field names and types. There a some types which a translated
database specifc. You can define more database specific translation in
Compat.pm.

=over 4

=item bit

boolean

=item counter

If an autoincrementing integer. For databases (like Oracle) that doesn't have such a 
datatype a sequence is generated to provide the autoincrement value
and the fields will be of type integer.

=item tinytext

variables length text with up to 255 characters

=item text

variables length text 

=back

=item !PrimKey

Name of the primary key

=item !For

Can contain the same key as the table definintion, but is only executed for a specifc
database.

Example:

    '!For' => { 
        'Oracle' => {
            '!Constraints' =>
                {
                'web_id'           => ['foreign key' => 'REFERENCES web (id)'],

                'prim__menu_id'    => ['!Name'       => 'web_prim_menu_id',
                                       'foreign key' => 'REFERENCES menu (id)',
                                       'not null'    => ''],
                }
            },
        },


=item !Contraints

Used to define contraints. See example under C<!For>.

=over 4

=item !Name => <name>

=item <constraint> => <second part>

=back

=item !Init

Used to initialy populate the table.

=item !Default

Used to set a default value for a field, when the table is created.
This doesn't have any affect for further INSERTs/UPDATEs.

=item !Grant

Give the rights that should be grant to C<$user>

=item !Index

Gives the names for the fields for which indices should be created.
If the second parameter for an index is not empty, it gives the
index name, otherwise a default name is used.


=back

=head2 $db -> DropTables ($schemaname, $user) 


Drops B<all> tables. Use with care!

=over 4

=item $schemaname

schemaname (only used for Oracle)

=item $user

User that should be revoked access. See C<!Grant> parameter.

=back


=head1 Casesensitive/insensitiv

In SQL all names (field/tablenames etc.) should be case insensitive. Various
DBMS handle the case of names differently. For that reason I<DBIx::Recordset>
translates all names to lower case, ensuring your application will
run with any DBMS, regardless of whether names are returned in
lower/uppercase by the
DBMS. Some DBMS are case-sensitive (I know at least Sybase, depending on your collate
settings). To use such a case-sensitive DBMS, it is best to create your database
with all names written in lowercase. In a situation where this isn't possible, you 
can set C<$PreserveCase> to 1. In this case DBIx::Recordset will not perform any
case translation. B<NOTE:> C<$PreserveCase> is still experimental and may change in
future releases.

=head1 FETCHSIZE / $FetchsizeWarn

Some operations in Perl (i.e. C<foreach>, assigning arrays) need to know the size
of the whole array. When Perl needs to know the size of an array it call the method
C<FETCHSIZE>. Since not all DBD drivers/DBMS returns the number of selected rows
after an SQL C<SELECT>, the only way to really determine the number of selected
rows would be to fetch them all from the DBMS. Since this could cause a lot of work, it
may be very inefficent. Therefore I<DBIx::Recordset> by default calls die()
when Perl calls
FETCHSIZE. If you know your DBD drivers returns the correct value in C<$sth> -> C<rows>
after the execution of an C<SELECT>, you can set C<$FetchsizeWarn> to zero to let
C<FETCHSIZE> return the value from C<$sth> -> C<rows>. Setting it to 1 will cause
I<DBIx::Recordset> to only issue a warning, but perform the operation.

B<NOTE:> Since I don't have enough experience with the behaviour of this
feature with different DBMS, this is considered experimental.




=head1 DEBUGGING

DBIx::Recordset is able to write a logfile so you can see what's happening
inside. There are two public variables and the C<!Debug> parameter used for
this purpose:

=over 4

=item $DBIx::Recordset::Debug or !Debug

Debuglevel 
 0 = off
 1 = log only errors
 2 = show connect, disconnect and SQL Statements
 3 = some more infos 
 4 = much infos

C<$DBIx::Recordset::Debug> sets the default debug level for new objects,
C<!Debug> can be used to set the debuglevel on a per object basis.

=item DBIx::Recordset::LOG

The filehandle used for logging. The default is STDOUT, unless you are running under 
HTML::Embperl, in which case the default is the Embperl logfile.

=back

 Example:

    # open the log file
    open LOG, ">test.log" or die "Cannot open test.log" ; 

    # assign filehandle
    *DBIx::Recordset::LOG = \*LOG ; 
    
    # set debugging level
    $DBIx::Recordset::Debug = 2 ; 

    # now you can create a new DBIx::Recordset object



=head1 SECURITY

Since one possible application of DBIx::Recordset is its use in a web-server
environment, some attention should paid to security issues.

The current version of DBIx::Recordset does not include extended security management, 
but some features can be used to make your database access safer. (More security features
will come in future releases.)

First of all, use the security feature of your database. Assign the web server
process as few rights as possible.

The greatest security risk is when you feed DBIx::Recordset a hash which 
contains the formfield data posted to the web server. Somebody who knows DBIx::Recordset
can post other parameters than those you would expect a normal user to post. For this 
reason, a primary issue is to override all parameters which should B<never> be posted by 
your script.

Example:
 *set = DBIx::Recordset -> Search ({%fdat,
				                    ('!DataSource'	=>  
"dbi:$Driver:$DB",
				                     '!Table'	=>  "$Table")}) ;

(assuming your posted form data is in %fdat). The above call will make sure
that nobody from outside can override the values supplied by $Driver, $DB and
$Table.

It is also wise to initialize your objects by supplying parameters
which can not be changed. 

Somewhere in your script startup (or at server startup time) add a setup call:

 *set = DBIx::Recordset-> Setup ({'!DataSource'  =>  "dbi:$Driver:$DB",
			                        '!Table'	  =>  "$Table",
			                        '!Fields'	  =>  "a, b, c"}) ;

Later, when you process a request you can write:

 $set -> Search (\%fdat) ;

This will make sure that only the database specified by $Driver, $DB, the
table specified by $Table and the Fields a, b, and c can be accessed.


=head1 Compatibility with different DBD drivers

I have put a great deal of effort into making DBIx::Recordset run with various DBD drivers.
The problem is that not all necessary information is specified via the DBI interface (yet).
So I have made the module B<DBIx::Compat> which gives information about the 
difference between various DBD drivers and their underlying database systems. 
Currently, there are definitions for:

=item B<DBD::mSQL>

=item B<DBD::mysql>

=item B<DBD::Pg>

=item B<DBD::Solid>

=item B<DBD::ODBC>

=item B<DBD::CSV>

=item B<DBD::Oracle (requires DBD::Oracle 0.60 or higher)>

=item B<DBD::Sysbase>

=item B<DBD::Informix>

=item B<DBD::InterBase>

DBIx::Recordset has been tested with all those DBD drivers (on Linux 2.0.32, except 
DBD::ODBC, which has been tested on Windows '95 using Access 7 and with MS SQL Server).


If you want to use another DBD driver with DBIx::Recordset, it may
be necessary to create an entry for that driver. 
See B<perldoc DBIx::Compat> for more information.





=head1 EXAMPLES

The following are some examples of how to use DBIx::Recordset. The Examples are
from the test.pl. The examples show the DBIx::Recordset call first, followed by the
generated SQL command.


 *set = DBIx::Recordset-> Setup ({'!DataSource'  =>  "dbi:$Driver:$DB",
                    			    '!Table'	  =>  "$Table"}) ;

Setup a DBIx::Recordset for driver $Driver, database $DB to access table $Table.


 $set -> Select () ;

 SELECT * from <table> ;


 $set -> Select ({'id'=>2}) ;
 is the same as
 $set1 -> Select ('id=2') ;

 SELECT * from <table> WHERE id = 2 ;


 $set -> Search({ '$fields' => 'id, balance AS paid - total ' }) ;

 SELECT id, balance AS paid - total FROM <table>


 $set -> Select ({name => "Second Name\tFirst Name"}) ;

 SELECT * from <table> WHERE name = 'Second Name' or name = 'First Name' ;


 $set1 -> Select ({value => "9991 9992\t9993",
    		       '$valuesplit' => ' |\t'}) ;

 SELECT * from <table> WHERE value = 9991 or value = 9992 or value = 9993 ;


 $set -> Select ({'+name&value' => "9992"}) ;

 SELECT * from <table> WHERE name = '9992' or value = 9992 ;


 $set -> Select ({'+name&value' => "Second Name\t9991"}) ;

 SELECT * from <table> WHERE (name = 'Second Name' or name = '9991) or
			    (value = 0 or value = 9991) ;


 $set -> Search ({id => 1,name => 'First Name',addon => 'Is'}) ;

 SELECT * from <table> WHERE id = 1 and name = 'First Name' and addon = 'Is' ;


 $set1 -> Search ({'$start'=>0,'$max'=>2, '$order'=>'id'})  or die "not ok 
($DBI::errstr)" ;

 SELECT * from <table> ORDER BY id ;
 B<Note:> Because of the B<start> and B<max> only records 0,1 will be returned


 $set1 -> Search ({'$start'=>0,'$max'=>2, '$next'=>1, '$order'=>'id'})  or die "not ok 
($DBI::errstr)" ;

 SELECT * from <table> ORDER BY id ;
 B<Note:> Because of the B<start>, B<max> and B<next> only records 2,3 will be 
returned


 $set1 -> Search ({'$start'=>2,'$max'=>1, '$prev'=>1, '$order'=>'id'})  or die "not ok 
($DBI::errstr)" ;

 SELECT * from <table> ORDER BY id ;
 B<Note:> Because of the B<start>, B<max> and B<prev> only records 0,1,2 will be 
returned


 $set1 -> Search ({'$start'=>5,'$max'=>5, '$next'=>1, '$order'=>'id'})  or die "not ok 
($DBI::errstr)" ;

 SELECT * from <table> ORDER BY id ;
 B<Note:> Because of the B<start>, B<max> and B<next> only records 5-9 will be 
returned


 *set6 = DBIx::Recordset -> Search ({  '!DataSource'   =>  "dbi:$Driver:$DB",
				                        '!Table'	    =>	"t1, t2",
				                        '!TabRelation'  =>
	"t1.value=t2.value",
                                        '!Fields'       =>  'id, name, text',
                                        'id'            =>  "2\t4" }) or die "not ok 
($DBI::errstr)" ;

 SELECT id, name, text FROM t1, t2 WHERE (id=2 or id=4) and t1.value=t2.value ;


 $set6 -> Search ({'name'            =>  "Fourth Name" }) or die "not ok 
($DBI::errstr)" ;
 SELECT id, name, text FROM t1, t2 WHERE (name = 'Fourth Name') and 
t1.value=t2.value 
;



 $set6 -> Search ({'id'            =>  3,
                  '$operator'     =>  '<' }) or die "not ok ($DBI::errstr)" ;

 SELECT id, name, text FROM t1, t2 WHERE (id < 3) and t1.value=t2.value ;


 $set6 -> Search ({'id'            =>  4,
                  'name'          =>  'Second Name',
                  '*id'           =>  '<',
                  '*name'         =>  '<>' }) or die "not ok ($DBI::errstr)" ;

 SELECT id, name, text FROM t1, t2 WHERE (id<4 and name <> 'Second Name') and 
t1.value=t2.value ;


 $set6 -> Search ({'id'            =>  2,
                  'name'          =>  'Fourth Name',
                  '*id'           =>  '<',
                  '*name'         =>  '=',
                  '$conj'         =>  'or' }) or die "not ok ($DBI::errstr)" ;

 SELECT id, name, text FROM t1, t2 WHERE (id<2 or name='Fourth Name') and 
t1.value=t2.value ;


 $set6 -> Search ({'+id|addon'     =>  "7\tit",
                  'name'          =>  'Fourth Name',
                  '*id'           =>  '<',
                  '*addon'        =>  '=',
                  '*name'         =>  '<>',
                  '$conj'         =>  'and' }) or die "not ok ($DBI::errstr)" ;

 SELECT id, name, text FROM t1, t2 WHERE (t1.value=t2.value) and (  ((name <> 
Fourth 
Name)) and (  (  id < 7  or  addon = 7)  or  (  id < 0  or  addon = 0)))


 $set6 -> Search ({'+id|addon'     =>  "6\tit",
                  'name'          =>  'Fourth Name',
                  '*id'           =>  '>',
                  '*addon'        =>  '<>',
                  '*name'         =>  '=',
                  '$compconj'     =>  'and',
                  '$conj'         =>  'or' }) or die "not ok ($DBI::errstr)" ;


 SELECT id, name, text FROM t1, t2 WHERE (t1.value=t2.value) and (  ((name = 
Fourth 
Name)) or (  (  id > 6 and addon <> 6)  or  (  id > 0 and addon <> 0))) ;


 *set7 = DBIx::Recordset -> Search ({  '!DataSource'   =>  "dbi:$Driver:$DB",
                                    '!Table'        =>  "t1, t2",
                                    '!TabRelation'  =>  "t1.id=t2.id",
                                    '!Fields'       =>  'name, typ'}) or die "not ok 
($DBI::errstr)" ;

 SELECT name, typ FROM t1, t2 WHERE t1.id=t2.id ;


 %h = ('id'    => 22,
      'name2' => 'sqlinsert id 22',
      'value2'=> 1022) ;


 *set9 = DBIx::Recordset -> Insert ({%h,
                                    ('!DataSource'   =>  "dbi:$Driver:$DB",
                                     '!Table'        =>  "$Table[1]")}) or die "not ok 
($DBI::errstr)" ;

 INSERT INTO <table> (id, name2, value2) VALUES (22, 'sqlinsert id 22', 1022) ;


 %h = ('id'    => 22,
      'name2' => 'sqlinsert id 22u',
      'value2'=> 2022) ;


 $set9 -> Update (\%h, 'id=22') or die "not ok ($DBI::errstr)" ;

 UPDATE <table> WHERE id=22 SET id=22, name2='sqlinsert id 22u', value2=2022 ;


 %h = ('id'    => 21,
      'name2' => 'sqlinsert id 21u',
      'value2'=> 2021) ;

 *set10 = DBIx::Recordset -> Update ({%h,
                                    ('!DataSource'   =>  "dbi:$Driver:$DB",
                                     '!Table'        =>  "$Table[1]",
                                     '!PrimKey'      =>  'id')}) or die "not ok 
($DBI::errstr)" ;

 UPDATE <table> WHERE id=21 SET name2='sqlinsert id 21u', value2=2021 ;


 %h = ('id'    => 21,
      'name2' => 'Ready for delete 21u',
      'value2'=> 202331) ;


 *set11 = DBIx::Recordset -> Delete ({%h,
                                    ('!DataSource'   =>  "dbi:$Driver:$DB",
                                     '!Table'        =>  "$Table[1]",
                                     '!PrimKey'      =>  'id')}) or die "not ok 
($DBI::errstr)" ;

 DELETE FROM <table> WHERE id = 21 ;



 *set12 = DBIx::Recordset -> Execute ({'id'  => 20,
                                   '*id' => '<',
                                   '!DataSource'   =>  "dbi:$Driver:$DB",
                                   '!Table'        =>  "$Table[1]",
                                   '!PrimKey'      =>  'id'}) or die "not ok 
($DBI::errstr)" ;

 SELECT * FROM <table> WHERE id<20 ;


 *set13 = DBIx::Recordset -> Execute ({'=search' => 'ok',
                    'name'  => 'Fourth Name',
                    '!DataSource'   =>  "dbi:$Driver:$DB",
                    '!Table'        =>  "$Table[0]",
                    '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;

 SELECT * FROM <table>  WHERE   ((name = Fourth Name))


 $set12 -> Execute ({'=insert' => 'ok',
                    'id'     => 31,
                    'name2'  => 'insert by exec',
                    'value2'  => 3031,
 # Execute should ignore the following params, since it is already setup
                    '!DataSource'   =>  "dbi:$Driver:$DB",
                    '!Table'        =>  "quztr",
                    '!PrimKey'      =>  'id99'}) or die "not ok ($DBI::errstr)" ;

 SELECT * FROM <table> ;


 $set12 -> Execute ({'=update' => 'ok',
                    'id'     => 31,
                    'name2'  => 'update by exec'}) or die "not ok ($DBI::errstr)" ;

 UPDATE <table> SET name2=update by exec,id=31 WHERE id=31 ;


 $set12 -> Execute ({'=insert' => 'ok',
                    'id'     => 32,
                    'name2'  => 'insert/upd by exec',
                    'value2'  => 3032}) or die "not ok ($DBI::errstr)" ;


 INSERT INTO <table> (name2,id,value2) VALUES (insert/upd by exec,32,3032) ;


 $set12 -> Execute ({'=delete' => 'ok',
                    'id'     => 32,
                    'name2'  => 'ins/update by exec',
                    'value2'  => 3032}) or die "not ok ($DBI::errstr)" ;

 DELETE FROM <table> WHERE id=32 ;


=head1 SUPPORT

As far as possible for me, support will be available via the DBI Users' mailing 
list. (dbi-user@fugue.com)

=head1 AUTHOR

G.Richter (richter@dev.ecos.de)

=head1 SEE ALSO

=item Perl(1)
=item DBI(3)
=item DBIx::Compat(3)
=item HTML::Embperl(3) 
http://perl.apache.org/embperl/
=item Tie::DBI(3)
http://stein.cshl.org/~lstein/Tie-DBI/


=cut

