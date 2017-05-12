###################################################
## YAWM.pm
## Andrew N. Hicox <andrew@hicox.com>
## http://www.hicox.com
##
## Yet Annother Wrapper Module
## Handy tools for talking to databases
###################################################


## Global Stuff ###################################
  package DBIx::YAWM;
  use 5.6.0;
  use warnings;

  require Exporter;
  use AutoLoader qw(AUTOLOAD);
  
## Class Global Values ############################ 
  our @ISA = qw(Exporter);
  our $VERSION = 2.35;
  our $errstr = ();
  our @EXPORT_OK = ($VERSION, $errstr);


## new ############################################
 sub new {
    #local vars
     my %p = @_;
     my $obj = bless ({});
    #you must at least, include Server, User, Pass, and DBType
     unless (
         (exists ($p{Server})) &&
         (exists ($p{User}))   &&
         (exists ($p{DBType})) 
     ){
         $errstr = "Server, User, and DBType are required options to New";
         return (undef);
     }
    #if it's Oracle, we'll be needing a SID too
     if (($p{DBType} eq "Oracle") && (! exists ($p{SID}))){
         $errstr = "SID is a required option for DBType Oracle";
         return (undef);
     }
    #add in anything which might have been sent in
     foreach (keys %p){ $obj->{$_} = $p{$_}; }
    #default values
     $obj->{'LongReadLen'} = 15000 unless (exists($obj->{'LongReadLen'}));
     $obj->{'LongTruncOk'} = 0 unless (exists($obj->{'LongTruncOk'}));
    #login to database
     unless ($obj->Login()){
         $errstr = $obj->{errstr};
         return (undef);
     }
    #return object
     return ($obj);
 }


## Login ##########################################
 sub Login {
    #local vars
     my $self = shift();
     my %p = @_;
     my ($connect_str, @connect_args) = ();
    #are we already logged in?
     if (exists ($self->{dbh})){ return (1); }
    #require appropriate dbi module
     my $mod = "DBD\::$self->{DBType}";
     eval "require $mod";
     if ($@){
         $self->{'errstr'} = "Login: failed to load DBD module $mod: $@";
         return (undef);
     }
    #wow, a "connection string" ... 
     if ($self->{DBType} eq "Sybase"){
         $connect_str = "dbi:Sybase:server=$self->{Server}";
     }elsif ($self->{DBType} eq "Oracle"){
        #if we have a port number we could give that too
         if (exists($self->{Port})){
             $connect_str = "dbi:Oracle:host=$self->{Server};sid=$self->{SID};port=$self->{Port}";
         }else{
             $connect_str = "dbi:Oracle:host=$self->{Server};sid=$self->{SID}";
         }
     }elsif ($self->{DBType} eq "mysql"){
         $connect_str = "dbi:mysql";
         if ($self->{'Database'}){ $connect_str .= ":database=$self->{'Database'}"; }
         $connect_str .= ";host=$self->{Server};";
         if ($self->{'Port'}){ $connect_str .= "port=$self->{'Port'};"; }
     }else{
        #wow this is really ghetto
         $self->{errstr} = "Sorry Dude, ";
         $self->{errstr}.= "I don't know how to make connection strings for this DBType ";
         $self->{errstr}.= "someone needs to edit YAWM.pm";
         return (undef);
     }
     push (@connect_args, $connect_str);
     push (@connect_args, $self->{User});
     push (@connect_args, $self->{Pass}) if (exists($self->{Pass}));
    #make the connection
     unless ($self->{dbh} = DBI->connect(@connect_args)){
         $self->{errstr} = "Login failed: $DBI::errstr";
         return (undef);
     }
    #go ahead and set LongReadLen and LongTruncOk
     $self->{dbh}->{'LongReadLen'} = $self->{'LongReadLen'};
     $self->{dbh}->{'LongTruncOk'} = $self->{'LongTruncOk'};
    #it's all good baby bay bay ...
     return (1);
 }


## Destroy ########################################
 sub Destroy {
    my $self = shift;
    $self->{dbh}->disconnect;
    $self = undef;
 }
 

## True for perl include ##########################
 1;
__END__
## AutoLoaded Methods


## Query ##########################################
sub Query {
    #local vars
     my $self = shift();
     my %params = @_;
     my ($QUERY,$sth,@data,$rec_count,@OUT) = ();
    #check input for required data
     if (
         (! exists ($params{'Select'})) ||
         (! exists ($params{'From'}))
     ){
         $self->{errstr} = "Query missing required data.";
         return (undef);
     }
    #check that -Select is an array ref
     if (ref($params{'Select'}) ne "ARRAY"){
         $self->{errstr} = "Query: Select must be an array reference";
         return (undef);
     }
    #if not logged into db, do it now
     unless ($self->Login()){
         $self->{errstr} = "Login failed $self->{errstr}";
         return (undef);
     }
    #make a query string
     my $select_str = join (", ", @{$params{'Select'}});
     if (exists($params{'Where'})){
         $QUERY = "select " . $params{'Options'} . " $select_str from $params{'From'} where $params{'Where'}";
     }else{
         $QUERY = "select " . $params{'Options'} . " $select_str from $params{'From'}";
     }
    #prepare the query
     if ($self->{'Debug'} > 1){ print "[Query]: preparing query ...\n"; }
     if ($self->{'Debug'} > 1){ print "[Query]:\t $QUERY\n"; }
     unless ($sth = $self->{dbh}->prepare($QUERY)){
         $self->{errstr} = "Query: failed prepare: $QUERY / $DBI::errstr";
         return (undef);
     }
    #execute the query
     if ($self->{'Debug'} > 1){ print "[Query]: executing query ...\n"; }
     unless ($sth->execute()){
         $self->{errstr} = "[Query]: FATAL ERROR / can't execute query $QUERY / $DBI::errstr";
         return (undef);
     }
    #fetch the records
     if ($self->{'Debug'} > 1){ print "[Query]: fetching records ...\n"; }
     while (@data = $sth->fetchrow_array()){
         $rec_count ++;
         my $count = -1;
         my %hash = ();
         foreach (@data){
             $count ++;
             $hash{$params{'Select'}->[$count]} = $_;
         }
         push (@OUT,\%hash);
     }
     $sth->finish();
    #make sure we got something
     if (! $rec_count){
         if ($self->{'Debug'}){ print "[Query]: no records returned\n"; }
         $self->{errstr} = "no records returned";
         return (undef);
     }else{
         if ($self->{'Debug'}){ print "[Query]: recieved $rec_count records\n"; }
         return (\@OUT);
     }
}


## Insert #########################################
 ##insert a record into the given table of the 
 ##database. 
sub Insert {
    #local vars
     my ($self, %p) = @_;
     my (@vals,$sth) = ();
    #requried options
     unless (
         (exists($p{Insert})) &&
         (exists($p{Into}))
     ){
         $self->{errstr} = "Insert and Into are required options to Insert";
         return(undef);
     }
    #proctecting against disaster
     unless ($self->{CanInsert}){
         $self->{errstr} = "The CanInsert option was not set in this object at creation ";
         $self->{errstr}.= "you may not use the Insert method on this object.";
         return (undef);
     }
    #filters
     foreach (keys %{$p{Insert}}){
        #don't insert null values
         unless (length($p{Insert}->{$_})  > 0){
             delete($p{Insert}->{$_});
             next;
         }
     }
     
     #Ints has been replaced by 'NoQuote', but we maintain
     #backward compatibility
     foreach (keys %{$p{'Ints'}}){ $p{'NoQuote'}->{$_} = 1; }
    
    #formulate the sql
     my $field_names = join (', ', sort (keys %{$p{Insert}}));
     foreach (sort (keys %{$p{Insert}})){
     	if (exists($p{'NoQuote'}->{$_})){
     		push (@vals, $p{Insert}->{$_});
     	}else{
     		push (@vals, $self->{dbh}->quote($p{Insert}->{$_}));
     	}
     }
     
     my $field_values = join (', ',@vals);
     my $sql = "INSERT " . $p{'Options'} . " INTO $p{Into} ($field_names) VALUES ($field_values)";
    #prepare the statement
     if ($self->{'Debug'} > 1){ print "[Insert]: preparing query ...\n"; }
     if ($self->{'Debug'} > 1){ print "[Insert]:\t $sql"; }
     unless ($sth = $self->{dbh}->prepare($sql)){
         $self->{errstr} = "Insert: failed prepare: $sql / $DBI::errstr";
         return (undef);
     }
    #execute insert
     if ($self->{'Debug'} > 1){ print "[Insert]: executing insert ...\n"; }
     unless ($sth->execute()){
         $self->{errstr} = "[Insert]: FATAL ERROR / can't execute insert $sql / $DBI::errstr";
         return (undef);
     }
     $sth->finish();
    #well it must be all-good
     return (1);
}


## Do #############################################
## prepare and execute an SQL statement of no
## particular type. If errors are encountered undef is
## returned and errors go on $obj->{errstr} as usual
## if successfull, whatever is returned from dbi->execute
## is returned here
sub Do {
    #local vars
     my ($self, %p) = @_;
    #required options
     unless (exists($p{SQL})){
         $self->{'errstr'} = "[Do]: SQL is a required option to Do";
         return (undef);
     }
    #prepare statement
     warn ("[Do]: (prepare): $p{SQL}") if $self->{'Debug'};
     my $sth = $self->{dbh}->prepare($p{SQL}) || do {
         $self->{'errstr'} = "[Do]: failed to prepare SQL ($p{SQL}): $DBI::errstr";
         warn ($self->{'errstr'}) if $self->{'Debug'};
         return (undef);
     };
     warn ("[Do]: (executing)") if $self->{'Debug'};
     my $res = $sth->execute() || do {
         $self->{'errstr'} = "[Do]: failed to execute SQL ($p{SQL}): $DBI::errstr";
         warn ($self->{'errstr'}) if $self->{'Debug'};
         return (undef);
     };
     $sth->finish();
     return ($res);
}


## Update #########################################
## update a record (or records) in the database with 
## new field settings
sub Update {
	my ($self, %p) = @_;
   #required options
   	exists($p{'Table'}) || do {
   		$self->{'errstr'} = "[Update]: 'Table' specifies the table of view to update the record(s) in, please specify";
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
   	};
   	exists($p{'Where'}) || do {
   		$self->{'errstr'} = "[Update]: 'Where' specified which record(s) in 'Table' to update. please specify";
   		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
   	};
   	exists($p{'Fields'}) || do {
   		$self->{'errstr'} = "[Update]: 'Fields' is a hash reference indicating the field values to update, please specify";
   		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
   	};
   #construct SQL String
    my $sql = "update " . $p{'Options'} . " " . $p{'Table'} . " set ";
    my @fields = ();
	foreach (keys %{$p{'Fields'}}){
		my $str = "$_ = ";
		$str   .= $self->{dbh}->quote($p{'Fields'}->{$_});
		push (@fields, $str); 
	}
	$sql .= join(", ", @fields);
	$sql .= " ";
	$sql .= "where $p{'Where'}";
    warn("[Update]: (prepare): $sql\n") if $self->{'Debug'};
   #prepare sql
    my $sth = $self->{dbh}->prepare($sql) || do {
    	$self->{'errstr'} = "[Update]: failed to prepare sql statement $DBI::errstr [SQL]: $sql";
    	warn ($self->{'errstr'}) if $self->{'Debug'};
        return (undef);
    };
   #execute sql
    $sth->execute() || do {
    	$self->{'errstr'} = "[Update]: failed to execute sql: $DBI::errstr";
    	warn ($self->{'errstr'}) if $self->{'Debug'};
        return (undef);
    };
    return (1);
}




## flatQuery ######################################
## use DBI's built in fetchrow_hashref(), which
## (I'm guessing) is implemented in xs and far 
## superior to what we've been doing here for all
## these years. As such, we don't (necessarily)
## have to take an array ref on Select ... 
## hence the name 'flatQuery' ... we can take either
## a string or an array ... otherwise pretty much
## the same old.

sub flatQuery {

	my ($self, %p) = @_;
	
	#verify required inputs
	foreach ('Select', 'From'){
		exists($p{$_}) || do {
			$self->{'errstr'} = $_ . " is a required option to Query";
			return (undef);
		};
	}
	
	#select has to be an array reference or a string
	if ($#{$p{'Select'}} >= 0){
		
		#flatten select
		$p{'Select'} = join (', ', @{$p{'Select'}});
	
	}
	
	#error out if it's a null string
	(length($p{'Select'}) > 0) || do {
		$self->{'errstr'} = "'Select' option contains no fields to select!";
		return (undef);
	};
	
	#log into the database
	$self->Login() || do {
		$self->{'errstr'} = "Login failed: " . $self->{'errstr'};
		return (undef);
	};
	
	#struct query string
	my $QUERY = "select " . $p{'Options'} . " " . $p{'Select'} . " from " . $p{'From'};
	$QUERY   .= " where " . $p{'Where'} if ($p{'Where'} !~/^\s*$/);
	
	#prepare the query
	warn ("[Query]: preparing query ...") if ($self->{'Debug'} > 1);
	warn ("[Query]:\t $QUERY\n") if ($self->{'Debug'} > 1);
	my $sth = $self->{'dbh'}->prepare($QUERY) || do {
		$self->{errstr} = "Query: failed prepare: $QUERY / $DBI::errstr";
		return (undef);
	};
		
	#do it
	$sth->execute() || do {
	
	        #ok, right here ... new for 2.34
	        #we're going to detect ORA-ORA-03114 "not connected to oracle"
	        #we'll try to re-connect and re-execute.
	        if ( ($self->{'DBType'} eq "Oracle") && ($DBI::errstr =~/ORA-(\d{1,5})/i) ){
	                my $ora_code = $1;
	                
	                #if we wanted to detect other ora failure codes, here's the spot for it.
	                
	                #ORA-03114: try destroying the db handle and reconnecting
	                if ($ora_code eq "03114"){
	                        warn ("detected ORA-03114, attempting reconnect") if ($self->{'Debug'});
	                        $self->{dbh}->disconnect;
	                        delete($self->{dnh});
	                        $self->Login() || do {
	                                $self->{'errstr'}  = "[ORA-03114 encountered, reconnect failed] ";
	                                $self->{'errstr'} .= "can't execute query: " . $QUERY . " / " . $DBI::errstr;
	                                return(undef)
	                        };
	                        warn ("detected ORA-03114, reconnect succeeded, retrying query") if ($self->{'Debug'});
                                $sth->execute() || do {
                                        $self->{'errstr'}  = "[ORA-03114 encountered, reconnect success, but query still fails] ";
                                        $self->{'errstr'} = "can't execute query: " . $QUERY . " / " . $DBI::errstr;
                                        return (undef);
                                };
	                        
	                        
	                }
	        }else{
                        #just your run of the mill failure
                        $self->{'errstr'} = "can't execute query: " . $QUERY . " / " . $DBI::errstr;
                        return (undef);
                }
	
	};
	
	#well now dbi does hashref internal, and you know its got to be better than what we've been
	#up to ... so we're going to use this. with any luck, this'll handle the 'as' clause as well
	my (@out, $rec) = ();
	while ($rec = $sth->fetchrow_hashref()){ 
	
		#translate field names to lowercase if option supplied
		if ($p{'lc'} !~/^\s*$/){
			foreach my $k (keys %{$rec}){
				my $kl = lc($k);
				$rec->{$kl} = $rec->{$k};
				delete($rec->{$k}) if ($k ne $kl);
			}
		}
	
		push (@out, $rec); 
		
	}
	$sth->finish();
	warn ("retrieved: " . ($#out + 1) . " records") if $self->{'Debug'};
	
	#if no records returned
	($#out >= 0) || do {
		$self->{'errstr'} = "no records returned";
		return (undef);
	};
	
	#return what we got
	return (\@out);
}
