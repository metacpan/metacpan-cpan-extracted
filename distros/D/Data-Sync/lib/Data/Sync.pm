#####################################################################
# Data::Sync
#
# Classes to make development of metadirectory/datapump apps
# simple and fast
#
# C Colbourn 2005
#
#####################################################################
# Revision
# ========
#
# 0.01	CColbourn		New module
#
# 0.02	CColbourn		Enhancements - see POD CHANGES
#
# 0.03	CColbourn		Enhancements - see POD CHANGES
#
# 0.04	CColbourn		Enhancements - see POD CHANGES
#
# 0.05	CColbourn		Bugfix - see POD CHANGES
#
# 0.06	CColbourn		Enhancements - see POD CHANGES
#
# 0.07	CColbourn		Enhancements - see POD CHANGES
#
# 0.08	CColbourn		Enhancements - see POD CHANGES
#
#####################################################################
# Notes
# =====
#
#####################################################################

use strict;
use warnings;


package Data::Sync;
our $VERSION="0.08";

#####################################################################
# New - constructor of datasync object
#
# takes parameters. 
# returns blessed object
#
#####################################################################
sub new
{
	my $self = shift;
	my %synchash;
	my %params = @_;

	# make the object first!
	my $syncobject = bless \%synchash,$self;

	# define logging. If logging not set, use a coderef of return
	if ($params{'log'})
	{
		$syncobject->{'log'} = \&writelog;
		$syncobject->{'loghandle'} = $params{'log'};
	}
	else
	{
		$syncobject->{'log'} = sub{return}
	}
	if ($params{'configfile'})
	{
		my $return = $syncobject->load($params{'configfile'});
		if (!$return)
		{
			$self->{'log'}->($self->{'loghandle'},"ERROR: Not a readable config file ".$params{'configfile'});
			$self->{'lasterror'} = "Not a readable config file ".$params{'configfile'};
			return
		}
	}
	
	# assign the jobname (only needed if hashing or record mapping)
	if (!$params{'jobname'})
	{
		$params{'jobname'}="noname";
	}
	$syncobject->{'name'} = $params{'jobname'};

	# define the default multivalue record separator for concatenating LDAP multivalue attributes into a string
	$syncobject->{'mvseparator'} = "|";
	
	# put something to stdout for progress reporting. Convenience for debugging. Deliberately undocumented
	if ($params{'progressoutputs'})
	{
		if (!$params{'readprogress'}){$syncobject->{'readprogress'} = sub{print "R"}}
		if (!$params{'transformprogress'}){$syncobject->{'transformprogress'} = sub {print "T"}}
		if (!$params{'writeprogress'}){$syncobject->{'writeprogress'} = sub {print "W"}}
	}
	else
	{
		if(!$params{'readprogress'}){$syncobject->{'readprogress'} = sub {return}};
		if(!$params{'transformprogress'}){$syncobject->{'transformprogress'} = sub {return}};
		if(!$params{'writeprogress'}){$syncobject->{'writeprogress'} = sub {return}};
	}

	# return the object
	return $syncobject; 
	
}

#####################################################################
# source
#
# defines the source data type & match critera
#
# takes $handle,\%search criteria
# returns true on successful definition
#####################################################################
sub source
{
	my $self = shift;
	my $handle = shift;
	my $criteriaref = shift;

	# do this regardless
	$self->{'readhandle'}=$handle;

	if (!$criteriaref)
	{
		# this /should/ mean the config is coming from a file
		# so return if the configs already been loaded (and
		# if not, it won't hurt anything to continue)
		if ($self->{'readcriteria'})
		{
			return 1;
		}
	}

	# assign the criteria hash as properties 
	$self->{'readcriteria'} = $criteriaref;

	if (!$self->{'readcriteria'}->{'batchsize'})
	{
		$self->{'readcriteria'}->{'batchsize'}=0;
	}

	# Create coderef for LDAP
	if ($handle =~/LDAP/)
	{
		$self->{'read'} = \&readldap; 
	}

	# everything else will be DBI/SQL
	else
	{
		$self->{'read'} =\&readdbi
	}

	1;
}

#########################################################
# readldap - read from an ldap datasource
#
# takes object as param
#
# returns result handle
#########################################################
sub readldap
{
	
	my $self = shift;	
	my $result = $self->{'readhandle'}->search
		(filter=>$self->{'readcriteria'}->{'filter'},
		base=>$self->{'readcriteria'}->{'base'},
		scope=>$self->{'readcriteria'}->{'scope'},
		attrs=>$self->{'readcriteria'}->{'attrs'},
		controls=>[$self->{'readcriteria'}->{'controls'}]);
	if ($result->code)
	{
		$self->{'log'}->($self->{'loghandle'},"ERROR:".$result->error);
		return $result->error
	}
	else {return $result}
}

#########################################################
# readdbi - read from a dbi datasource
#
# takes object as param
#
# returns result handle
#########################################################
sub readdbi
{
	my $self = shift;
	
	my $stm = $self->{'readhandle'}->prepare($self->{'readcriteria'}->{'select'}) or return;
	my $result = $stm->execute;
	if ($result || $result eq "0E0"){return $stm}
	else
	{
		$self->{'log'}->($self->{'loghandle'},"ERROR: Could not read from database");
		$self->{'lasterror'}="ERROR: Could not read from database";
		return undef;
	}
}




#########################################################
# target - define the data target
#
# takes $handle, \%writecriteria
#
# returns 1 on success
#
#########################################################
sub target
{
	my $self = shift;
	my $handle = shift;

	$self->{'writehandle'} = $handle;
	
	my $criteriaref = shift;
	if (!$criteriaref)
	{
		# this /may/ mean the config is coming from a file
		# so return if the configs already been loaded (and
		# if not, it may be an ldap target so continue;
		if ($self->{'readcriteria'} && $handle!~/LDAP/)
		{
			return 1;
		}
	}
	else 
	{
		$self->{'writecriteria'} = $criteriaref;
	}

	# LDAP index is /always/ DN, but an index is needed for hashing.
	if ($handle =~ /LDAP/){$criteriaref->{index} = "dn"}
	
	
	# Checking for fubars
	if ($criteriaref->{hashattributes} && !$criteriaref->{index})
	{
		$self->{log}->($self->{loghandle},"Can't set a target with hashing and no index!");
		$self->lasterror = "Can't set a target with hashing and no index!";
		return;
	}
	
	
		
	# create coderef to write to LDAP
	if ($handle =~/LDAP/)
	{
		$self->{'write'} = \&writeldap;
	}

	# write coderef for DBI
	if ($handle =~/DBI/)
	{
		$self->{'write'} = \&writedbi;
	}
	1;
}

########################################################
# writedbi
#
# takes object as param
#
# return t/f
########################################################
sub writedbi	
{		
	my $self = shift;
	my $writedata = shift;

		
	for my $line (@$writedata)
	{
		if ($line->{'Data::Sync::Action'} && $line->{'Data::Sync::Action'} eq "DELETE")
		{
			my $delete = "delete from ".$self->{writecriteria}->{table}. " where ";
			$delete .= $self->{writecriteria}->{index} ."=?";
			
			my $stm = $self->{writehandle}->prepare($delete);
			
			my $result = $stm->execute($line->{$self->{writecriteria}->{index}});
			if (!$result || $result eq "0E0")
			{
				$self->{'log'}->($self->{'loghandle'},"ERROR: Delete failed because ".$self->{'writehandle'}->errstr);
				$self->{'lasterror'}="ERROR: Delete failed because ".$self->{'writehandle'}->errstr;
			}
			
			next;
		}
		
		# Otherwise, the entry must be an update/add
		my @keys = keys %$line;
		my @values = map $_,values %$line;
		
		if ($self->{writecriteria}->{index})
		{
			my $update = "update ".$self->{'writecriteria'}->{'table'}. " set ";

			my @keys = keys %$line;
			my @values = map $_,values %$line;

			$update.=join "=?,",@keys;

			$update .="=? where ";
			$update .= $self->{'writecriteria'}->{'index'};
			$update .="=?";
			$self->{'log'}->($self->{'loghandle'},"Updating $update, ".join ",",@values);

			my $stm = $self->{'writehandle'}->prepare($update);

			my $result = $stm->execute(@values,$line->{$self->{'writecriteria'}->{'index'}});
			if (!$result || $result eq "0E0")
			{
				my $insert = "insert into ".$self->{'writecriteria'}->{'table'}." (";
				$insert .= join ",",@keys;
				$insert .=") VALUES (";
				$insert .=join ",",map { "?" } (0..scalar @values-1);
				$insert .=")";
				$self->{'log'}->($self->{'loghandle'},"Update failed, adding $insert, ".join ",",@values);
				$stm = $self->{'writehandle'}->prepare($insert);
				$result = $stm->execute(@values);
			}
			if (!$result || $result eq "0E0")
			{
				$self->{'log'}->($self->{'loghandle'},"ERROR: Add failed because ".$self->{'writehandle'}->errstr);
				$self->{'lasterror'}="ERROR: Add failed because ".$self->{'writehandle'}->errstr;
			}
			$self->{'writeprogress'}->($line->{$self->{'writecriteria'}->{'index'}});		
		}
		else
		{
			my $insert = "insert into ".$self->{'writecriteria'}->{'table'}." (";
			$insert .= join ",",@keys;
			$insert .=") VALUES (";
			$insert .=join ",",map { "?" } (0..scalar @values-1);
			$insert .=")";
			$self->{'log'}->($self->{'loghandle'},"Adding $insert, ".join ",",@values);
			my $stm = $self->{'writehandle'}->prepare($insert);
			my $result = $stm->execute(@values);
		}		
	}

}




########################################################
# writeldap - write to an ldap server
#
# takes object as param
#
# returns t/f
#########################################################
sub writeldap
{
	my $self = shift;
	my $writedata = shift;

	#if ($self->{'writecriteria'}->{'hashattributes'})
	#{
	#	my $checkedrecordset = $self->scanhashtable($writedata);
	#	$writedata = $checkedrecordset;
	#}

	
	foreach my $line (@$writedata)
	{
		my $dn = $line->{'dn'};

		delete $line->{'dn'}; # don't want the dn included in the hash of attrs to write
		
		if ($line->{'Data::Sync::Action'} && $line->{'Data::Sync::Action'} eq "DELETE")
		{
			my $result = $self->{'writehandle'}->delete($dn);
			if ($result->code)
			{
				$self->{'log'}->($self->{'loghandle'},"Delete of $dn failed because ".$result->error);
				$self->{lasterror} = "Delete of $dn failed because ".$result->error;
			}
			else
			{
				$self->{'log'}->($self->{'loghandle'},"Deleted $dn");
			}
			next;
		}
		
		# otherwise it's a modify or add
			
		
		$self->{'log'}->($self->{'loghandle'},"Modifying $dn, values ".join ",",values %$line);

		# experimental problem solution 20060212 - sunone/fedora and (possibly) AD will not permit a 'replace' on the objectclass
		# attribute in a modify - so we want to cover that off. Remove from the structure /unless/ a flag is set (document in ::Advanced)
		#my $modline = $line;
		#if (!$self->{writeobjectclass})
		#{
		#	for (keys %$modline)
		#	{
		#		print "$_ --\n";
		#		if (lc($_) eq "objectclass")
		#		{
		#			delete $$modline{$_};
		#		}
		#	}
		#}
		
	
	
		my $result =
			$self->{'writehandle'}->modify
			(
				dn=>$dn,
				replace=>[%$line]
			);
		
		
		if ($result->code)
		{
			$self->{'log'}->($self->{'loghandle'},"Modify failed '".$result->error."', adding $dn, values ".join ",",values %$line);
			$result =
				$self->{'writehandle'}->add
				(
					dn=>$dn,
					attrs=>[%$line]
				);
		
		}
		
		if ($result->code)
		{
			$self->{'log'}->($self->{'loghandle'},"ERROR: ".$result->error);
			$self->{'lasterror'}="ERROR: Add failed :".$result->error;
			
			return undef;
		}
		$self->{'writeprogress'}->("W");
	}
	return 1;
}




########################################################
# sourceToAoH
#
# Convert data from source to an array of hashes
# so that there's a standard form to write data out
#
# takes data handle (LDAP result or DBI)
#
# returns ref to AoH
#
########################################################
sub sourceToAoH
{
	my $self = shift;
	my $handle = shift;

	my @records;
	my $counter=1;
	
	# Convert LDAP
	if ($handle=~/LDAP/)
	{
		my $recordset = $self->ldapToAoH($handle);
		@records = @$recordset;
	}
	
	# convert DBI
	if ($handle=~/DBI/)
	{
		my $recordset = $self->dbiToAoH($handle);
		@records = @$recordset;
	}
	

	# if it's an empty recordset return unddef
	if (scalar @records == 0){return}

	# check against the hash records if defined and remove if the record has not changed.
	#if ($self->{'readcriteria'}->{'hashattributes'})
	#{
	#	my $checkedrecordset = $self->scanhashtable(\@records);
	#	@records = @$checkedrecordset;
	#	
	#}

	return \@records;
	
}

#############################################################
# ldapToAoH - convert the content of an LDAP handle to an AoH
# takes - ldap handle
# returns - AoH
#############################################################
sub ldapToAoH
{
	my $self = shift;
	my $handle = shift;
	
	my @records;
	my $counter=1;
	
		
	if ($self->{'readcriteria'}->{'batchsize'} >0)
	{
		while ($counter<= $self->{'readcriteria'}->{'batchsize'})
		{
			my $entry=$handle->shift_entry;
			if (!$entry){last}
			my %record;
			for my $attrib ($entry->attributes)
			{
				$record{$attrib} = $entry->get_value($attrib);
			}
			$self->{'log'}->($self->{'loghandle'},"Read ".$entry->dn." from the directory");
			push @records,\%record;
			$counter++;
			$self->{'readprogress'}->($entry->dn);
		}
	}
	else
	{
		while (my $entry=$handle->shift_entry)
		{
			my %record;
			for my $attrib ($entry->attributes)
			{
				$record{$attrib} = $entry->get_value($attrib);
			}
			$self->{'log'}->($self->{'loghandle'},"Read ".$entry->dn." from the directory");
			push @records,\%record;
			$counter++;
			$self->{'readprogress'}->($entry->dn);
		}
	}	
	
		
		


	return \@records;
}

#############################################################
# dbiToAoH - converts a db handle to an AoH
# takes - DB handle
# returns - AoH
#############################################################
sub dbiToAoH
{
	my $self = shift;
	my $handle = shift;

	my @records;
	my $counter=1;
	my $recordcounter=0;	
	# this separation looks a bit strange, but combining into a single loop resulted in a segfault from DBI that I chased 
	# for HOURS! resolve at a later date.
	if ($self->{'readcriteria'}->{'batchsize'} >0)
	{
		while ($counter <= $self->{'readcriteria'}->{'batchsize'}) 
		{
			my $entry = $handle->fetchrow_hashref; 
			if (!$entry){last}
			my %record;
			for my $attrib (keys %$entry)
			{
				$record{$attrib} = $entry->{$attrib}
			}
			$self->{'log'}->($self->{'loghandle'},"Read entry ".++$recordcounter." from the database");
			push @records,\%record;
			$counter++;
						
			$self->{'readprogress'}->();
		}
	}
	else
	{
		while (my $entry = $handle->fetchrow_hashref)
		{
			my %record;
			for my $attrib (keys %$entry)
			{
				$record{$attrib} = $entry->{$attrib}
			}
			$self->{'log'}->($self->{'loghandle'},"Read entry ".++$recordcounter." from the database");
			push @records,\%record;
			$self->{'readprogress'}->();
		}
	}	

	return \@records;
}

#############################################################
# hashrecord - take a record as a hash, and return the MD5
# hash
#
# takes hashref of record, arrayref of attribs to hash
#
#############################################################
sub hashrecord
{
	require Digest::MD5;
	my $self = shift;
	my $record = shift;
	my $attribs = shift;

	# make a hash of the current record
	my $attribstring;
	for (@$attribs)
	{
		if (!ref($_))
		{
			$attribstring .= $$record{$_};
		}
	}

	my $newhash = Digest::MD5->new;
	$newhash->add($attribstring);

	return $newhash->hexdigest;
}
	
#############################################################
# scanhashtable - run through a record set checking records
#  against the stored hash table
#  takes - a record set (AoH)
#  returns - a record set minus unchanged records.
#############################################################
sub scanhashtable
{
	my $self = shift;
	my $recordset = shift;
	
	require DBI;
	require Digest::MD5;

	my @records = @$recordset;
	my @hashcheckedrecords;

	my $hashdb = DBI->connect("DBI:SQLite:dbname=".$self->{'name'},"","") or die $!;

	# check the hash table for this database exists - if not, create it
	my $stm = $hashdb->prepare("select * from hashtable");
		
	if (!$stm)
	{
		$stm = $hashdb->prepare ("create table hashtable (targetkey CHAR(100),attribhash CHAR(32), status CHAR(1))");
		$stm->execute;
	}
	else
	{
		# tombstone previously deleted entries
		my $tmbstm = $hashdb->prepare("update hashtable set status=? where status=?");
		my $result = $tmbstm->execute("T","D");
		if (!$result || $result eq "0E0")
		{
			$self->{log}->($self->{loghandle},"Can't update status of previously deleted entries - expect write errors");
		}
		# mark all entries deleted, any that still exist will be marked update/exists
		my $delstm = $hashdb->prepare("update hashtable set status=? where status != ?");
		$result = $delstm->execute("D","T");
		if (!$result || $result eq "0E0")
		{
			$self->{log}->($self->{loghandle},"Can't update status of all entries - deltas may fail");
		}
	}
	
	my $getstm = $hashdb->prepare ("select attribhash from hashtable where targetkey=?");
	my $putstm = $hashdb->prepare("insert into hashtable (targetkey,attribhash) VALUES (?,?)");
	my $updstm = $hashdb->prepare("update hashtable set attribhash=? where targetkey=?");
	my $statusstm = $hashdb->prepare("update hashtable set status=? where targetkey=?");
	
	for my $record (@records)
	{
		$getstm->execute(${$record}{$self->{'writecriteria'}->{'index'}});
		my $oldhash = $getstm->fetchrow;
		
		my $newhash = $self->hashrecord($record,\@{$self->{writecriteria}->{hashattributes}});
		
		if (!$oldhash)
		{
			$putstm->execute(${$record}{$self->{'writecriteria'}->{'index'}},$newhash);
			push @hashcheckedrecords,$record;
			$statusstm->execute("N",${$record}{$self->{writecriteria}->{index}});
		}
		elsif($oldhash ne $newhash)
		{
			$updstm->execute($newhash,${$record}{$self->{'writecriteria'}->{'index'}});
			push @hashcheckedrecords,$record;
			$statusstm->execute("U",${$record}{$self->{writecriteria}->{index}});
		}
		else
		{
			$statusstm->execute("E",${$record}{$self->{writecriteria}->{index}});
		}
	}
	return \@hashcheckedrecords;
}

#############################################################
# getdeletes - get a list of the deleted records
# takes - null
# returns - arrayref of deleted entries
#############################################################
sub getdeletes
{
	my $self = shift;
	my $hashdb = DBI->connect("DBI:SQLite:dbname=".$self->{'name'},"","") or die $!;
	
	
	my $stm = $hashdb->prepare("select targetkey from hashtable where status=?");
	my $result = $stm->execute("D");
	
	
	if (!$result)
	{
		return
	}
	else
	{
		#return $stm->fetchall_arrayref();
		# fits into the existing code better to return a hash of index=>value
		my @deleteds;
		while (my $entry = $stm->fetchrow_array)
		{
			push @deleteds,{$self->{writecriteria}->{index} => $entry};
		}
		return \@deleteds;
	}
}

#############################################################
# deletes - define the behaviour for deleted records
#
# takes - hash of named params
# returns - success/fail
#############################################################
sub deletes
{
	my $self = shift;
	my $params;
	if (!@_){return} # don't set anything if blank
	if (scalar @_ == 1 && $_[0] =~/delete/i)
	{
		$params = "delete";
	}
	else
	{
		my %paramshash = @_;
		$params = \%paramshash;
	}
	
	$self->{deleteactions} = $params;
	
	return 1;
}


#############################################################
# Run - read the data, transform it, then write it.
#
# takes no parameters (apart from object)
# returns success or fail.
#
#############################################################
sub run
{
	my $self = shift;

	# fetch from source
	my $receivedata = $self->{'read'}->($self);

	# If we don't get anything back, return 0
	if (!$receivedata){return}

	my $result;
	
	my $AoHdata=[];
	while ($AoHdata)
	{
		# convert to an AoH
		my $AoHdata = $self->sourceToAoH($receivedata);
		if (!$AoHdata){last}
		
		# construct templated attributes
		$AoHdata = $self->makebuiltattributes($AoHdata);

		# remap attrib names to target names
		$AoHdata = $self->remap($AoHdata);

		# perform data transforms
		$AoHdata = $self->runtransform($AoHdata);

		if ($self->{validation})
		{
			my $result = $self->validate($AoHdata);
			if (!$result)
			{
				$self->{lasterror} = "ERROR: Validation failed";
				return undef;
			}
			
		}

		# check against hashtable
		if ($self->{writecriteria}->{hashattributes})
		{
			$AoHdata = $self->scanhashtable($AoHdata);
		}
		
		# handle deletions here - it MUST be after scanhashtable - note, it might be handy to put this in a separate function for ease of overloading.
		if ($self->{deleteactions})
		{
			my $deletes = $self->getdeletes();
			
			if ($deletes)
			{
				if ($self->{deleteactions} eq "delete")
				{
					for my $record (@$deletes)
					{
						# It's very unlikely that 'Data::Sync::Action' will collide with a true field name
						$record->{"Data::Sync::Action"} = "DELETE";
					}
				}
				else # set up an update
				{
					#$deletes = $self->runtransform($deletes,$self->{deleteactions});
					for my $entry (@$deletes)
					{
						%$entry = (%$entry,%{$self->{deleteactions}});
					}
				
				}
				# need to build attributes, remap and run transforms on deletes (for building DNs & field mappings)
				#$deletes = $self->makebuiltattributes($deletes);
				#$deletes = $self->remap($deletes);
				#$deletes = $self->runtransform($deletes);
				$AoHdata = \(@$AoHdata,@$deletes);
			}
		}

		# write to target
		$result = $self->{'write'}->($self,$AoHdata);
		
		# jump out if not in batch mode
		if ($self->{'readcriteria'}->{'batchsize'} == 0){last}

	}
		
	#set the timestamp	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$mon+=1;
	$year+=1900;	
	$self->{'lastruntime'} = sprintf("%4d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$sec);
	
	return $result;
}

#############################################################
# mappings - define mappings from source to target
#
# takes hash of sourceattrib=>targetattrib
#
# returns success or fail
#
#############################################################
sub mappings
{
	my $self = shift;
	my %params = @_;

	$self->{'map'} = \%params;

	return 1;
}

##############################################################
# remap - rename source keys in data to target keys
#
# takes data structure in AoH form
# returns data structure in AoH form
#
##############################################################
sub remap
{
	my $self = shift;
	my $data = shift;
	my @newdata;

	for my $line (@$data)
	{
		my %record;
		for my $attrib (keys %$line)
		{
			# retain unchanged name if nothing in map

			if ($self->{'map'}->{$attrib})
			{
				$record{$self->{'map'}->{$attrib}} = $$line{$attrib};
				$self->{'log'}->($self->{'loghandle'},"Remapped ".$attrib." to ".$self->{'map'}->{$attrib});
			}
			else
			{
				$record{$attrib}=$$line{$attrib}
			}
		}

		push @newdata,\%record;
	}

	return \@newdata;
}	


##############################################################
# transforms - define transformations of data
#
# takes hash of params
# returns success or fail
#
##############################################################
sub transforms
{
	my $self = shift;

	$self->{transformations} = $self->maketrfunctions(@_);
	
	return 1;
}

##############################################################
# maketrfunctions - convert the various transform functions
#   into coderefs etc
#
# takes hash of params
# returns hash of coderefs etc
##############################################################
sub maketrfunctions
{	
	my $self = shift;
	
	my %params=@_;

	# params are attrib=>regexstring or attrib=>coderef

	# if param is a regex, transform to a coderef
	for (keys %params)
	{
		# capture the concatenate special case
		if ($params{$_} =~/^concatenate$/){}
		# otherwise turn a function name into a coderef
		elsif ($params{$_} =~/^\w+$/)
		{
			$params{$_} = \&{$params{$_}};
		}
		elsif ($params{$_} !~/CODE/)
		{
			$params{$_}=eval "sub { #!#$_#!#
						my \$data=shift;
						\$data =~".$params{$_}.";
						return \$data;}";
		}
	}
		
	return \%params;

	
}

##############################################################
# runtransform - perform regexes and data transforms on
# the data
#
# takes AoH
# returns AoH
#
##############################################################
sub runtransform
{

	my $self = shift;
	my $inData = shift;
	my $transformations = shift;
	if (!$transformations){$transformations = $self->{transformations}}
		
	my @outData;
	
	for my $line (@$inData)
	{
		my %record;
		for my $attrib (keys %$line)
		{
			# only convert if there is a transform for this
			if ($transformations->{$attrib})
			{
				my $before = $$line{$attrib};
				# handle possible multi valued attribs
				$record{$attrib} = $self->recursiveTransform($$line{$attrib},$transformations->{$attrib});
			}
			else
			{
				$record{$attrib} = $$line{$attrib}
			}
		}
		push @outData,\%record;
		$self->{'transformprogress'}->();
	}

	return \@outData;

}

############################################################
# recursiveTransform - recursively transform data
#
# takes attrib,$transformation
#
# returns transformed attrib
#
############################################################
sub recursiveTransform
{
	my $self = shift;
	my $data = shift;
	my $transformation = shift;


	# if the transformation is to join values together
	if ($data =~/ARRAY/ && $transformation eq "concatenate")
	{
		my $string = join $self->{'mvseparator'},@$data;
		$data = $string;
	}
	# otherwise act on each instance
	elsif ($data =~/ARRAY/)
        {
                for (0..scalar @$data -1)
                {
                        $$data[$_] = $self->recursiveTransform($$data[$_],$transformation);
                }
        }

        elsif ($data =~/HASH/)
        {
                for my $inst (keys %$data)
                {
                        $$data{$inst} = $self->recursiveTransform($$data{$inst},$transformation);
                }
        }

        elsif ($transformation =~/CODE/)
        {
		my $before = $data;
		$data = $transformation->($data);
		$self->{'log'}->($self->{'loghandle'},"Transformed $before to ".$data);
	}

	return $data;
}
		
##########################################################
# buildattributes - fake up attributes from source data
#
# takes attribname=>'<template>' where %NAME% is the source
# data
# Note: this runs before runtransform, so data can be 
# templated here, then transformed in runtransform for more
# sophisticated constructions
#
# returns success\fail
#
###########################################################
sub buildattributes
{
	my $self = shift;
	my %attribs = @_;

	$self->{'buildattribs'} = \%attribs;

	return 1;
}	

#############################################################
# makebuiltattributes - add built attributes to the data map
#
# takes AoH
# returns AoH
#
#############################################################
sub makebuiltattributes
{
	my $self = shift;

	my $indataref = shift;
	my @inData = @$indataref;

	for my $line (@inData)
	{
		for my $newattrib (keys %{$self->{'buildattribs'}})
		{
			$$line{$newattrib} = $self->{'buildattribs'}->{$newattrib};
			# s/// the template
			$$line{$newattrib} =~s/%(.*?)%/$$line{$1}/g;
			$self->{'log'}->($self->{'loghandle'},"Created attribute $newattrib containing ".$$line{$newattrib});
		}
	}

	return \@inData;
}	

######################################################
# writelog - write logging information
#
# takes $fh,$string
#
# returns undef
#
######################################################
sub writelog
{
	my $fh = shift;
	my $string = shift;
	if ($fh eq "STDOUT")
	{
		print $string."\n";
	}
	else
	{
		print $fh $string."\n";
	}

	return;
}

########################################################
# log - log an entry
# takes message
# returns nothing
########################################################
sub log
{
	my $self = shift;
	my $message = shift;
	
	$self->{log}->($self->{loghandle},$message);
}



########################################################################
# save - saves config to a DDS file
#
# takes filename
# returns success or fail
#
########################################################################
sub save
{
	my $self = shift;
	my $filename = shift;
	
	require Data::Dump::Streamer;
	
	if (!$filename)
	{
		$self->{'log'}->($self->{'loghandle'},"ERROR: No filename supplied to save");
		$self->{'lasterror'}="ERROR: No filename supplied to save";
	}

	my $fh;
	open ($fh,">",$filename) or do
				{
					$self->{'lasterror'} = "Unable to open $filename for writing because $!";
					return;
				};


	my $dds = Data::Dump::Streamer->new;

	# clone the object and remove non serialisable or unwanted keys
	my $clone = \%$self;
	delete $clone->{'writehandle'};
	delete $clone->{'readhandle'};
	delete $clone->{'loghandle'};
	delete $clone->{'log'};

	print $fh $dds->Dump($clone)->Out();

	close $fh;

	return 1;
}

#######################################################################
# load - read back a config file
#
# takes filename
# returns 1 on success, 0 on fail
#
#######################################################################
sub load
{
	my $self = shift;
	my $filename = shift;

	require Data::Dump::Streamer;
	
	if (!$filename)
	{
		$self->{'log'}->($self->{'loghandle'},"ERROR: No filename supplied to save");
		$self->{'lasterror'}="ERROR: No filename supplied to save";
	}
	
	my $Data_Sync1; # this is what Data::Dump::Streamer calls the object
	my $fh;
	open ($fh,"<",$filename) or do
				{
					$self->{'lasterror'} = "Unable to open $filename for reading because $!";
					return;
				};
	my $evalstring;
	while (<$fh>)
	{
		$evalstring .=$_;
	}

	eval $evalstring;
	my $successfulload;
	for my $attrib (keys %$Data_Sync1)
	{
		$self->{$attrib} = $Data_Sync1->{$attrib};
		$successfulload++;
	}

	if (!$successfulload)
	{
		if ($self->{'log'})
		{
			$self->{'log'}->($self->{'loghandle'},"ERROR: Unsuccessful load from $filename") ;
		}
		$self->{'lasterror'}="Unsuccessful load from $filename";
		return;
	}

	return 1;

}

########################################################################
# error - returns last error
#
# takes no parameter
# returns error
#
########################################################################
sub error
{
	my $self = shift;

	return $self->{'lasterror'};
}

########################################################################
# lastruntime - returns last run time
#
# no parameters, returns datetime as YYYYMMDDHHMMSS
#
########################################################################
sub lastruntime
{
	my $self = shift;
	return $self->{'lastruntime'};
}



#######################################################################
# mvseparator - convenience function to change the multivalue
# separator
#
# takes scalar or null
# returns true or separator
#
#######################################################################
sub mvseparator
{
	my $self = shift;
	my $separator = shift;
	if (!$separator){return $self->{mvseparator}}
	else 
	{
		$self->{mvseparator} = $separator;
		return 1;
	}
}

########################################################################
# commit - commit the write handle
#
# takes null
# returns result
#
########################################################################
sub commit
{
	my $self = shift;
	my $result;

	$result = $self->{target}->{writehandle}->commit();

	return $result;
}	

########################################################################
# validate - checks that the data in the dataset is what you expect
#
# takes hash of param=>regex
#
# returns t/f
#
########################################################################
sub validation
{
	my $self = shift;
	my %params = @_;

	for my $attrib (keys %params)
	{
		$self->{validation}->{$attrib} = eval "sub { my \$self =shift;
							my \$string = shift;
							return \$string =~ $params{$attrib};}";
	}

	return 1;
}

#########################################################################
# validate - run the validation
#
# takes AoH
# returns t/f & logs
#
#########################################################################
sub validate
{
	my $self = shift;
	my $AoH = shift;
	my $errorflag = 0;

	for my $record (@$AoH)
	{
		
		my $errorcounter = 0;	
		for my $attrib (keys %$record)
		{
			# only try to validate the field if a validation pattern match is defined
			if (!$self->{validation}->{$attrib}){next}

			# recursively validate, in case of multi valued attributes
			my $result =  $self->recursivevalidate($$record{$attrib},$self->{validation}->{$attrib});
			$errorcounter +=(!$result);
		}
		$self->{log}->($self->{loghandle},"Record ". join ",",values %$record," validated with $errorcounter errors");
		if ($errorcounter){$errorflag+= $errorcounter }
	}

	$self->{log}->($self->{loghandle},"Validation completed with $errorflag errors");
	if ($errorflag > 0) {return}
	else {return 1}

}

########################################################################
# recursivevalidate - run the validation coderefs against a complex
#  object
########################################################################
sub recursivevalidate
{
	my $self = shift;
	my $value = shift;
	my $matchref = shift;

	if (!ref($value))
	{
		# take a copy of the value and regex that, just to make sure
		# we don't accidentally do a s///
		my $tempvalue = $value;
		my $result = $matchref->($self,$tempvalue);
		return $result;
	}

	elsif ($value =~ /ARRAY/)
	{
		my $errorcounter;
		for (@$value)
		{
			my $result = $self->recursivevalidate($_,$matchref);
			$errorcounter +=(!$result);
		}
		if ($errorcounter){return}
		return 1;
	}
	
	elsif ($value =~/HASH/)
	{
		
		my $errorcounter;
		for (values %$value)
		{
			my $result = $self->recursivevalidate($_,$matchref);
			$errorcounter +=(!$result);
		}
		if ($errorcounter){return}
		return 1;
	}

}


######################################################################################
# get - utility function to get a set of records
######################################################################################
sub get
{
	my $self = shift;

	my $result = $self->{read}->($self);

	if (!$result) { return undef }

	my $recordset = $self->sourceToAoH($result);
	
	return $recordset;

}

#######################################################################################
# put - utility function to write a set of records
#######################################################################################
sub put
{
	my $self = shift;
	my $recordset = shift;
	my $result = $self->{write}->($self,$recordset);
	return $result;
}





########################################################################
########################################################################
# transformation functions
########################################################################
########################################################################

sub stripspaces
{
	my $var = shift;
	$var=~s/ //g;
	return $var;
}

sub stripnewlines
{
	my $var = shift;
	$var=~s/\n/ /g;
	# (just in case)
	$var=~s/\r//g;
	return $var;
}

sub uppercase
{
	my $var = shift;
	return uc($var);
}

sub lowercase
{
	my $var =shift;
	return lc($var);
}



1;

#########################################################################
#########################################################################
# Nothing but POD from here on out
#########################################################################
#########################################################################

=pod

=head1 NAME

Data::Sync - A simple metadirectory/datapump module

=head1 SYNOPSIS

 use Data::Sync;

 my $sync = Data::Sync->new(log=>"STDOUT",[configfile=>"config.dds"],[jobname=>"MyJob"]);

 $sync->source($dbhandle,{
				select=>"select * from testtable",
				index=>"NAME",
			});

 or

 $sync->source($ldaphandle,{filter=>"(cn=*)",
				scope=>"sub",
				base=>"ou=testcontainer,dc=test,dc=org"});

 $sync->target($dbhandle,{table=>'targettable',
				index=>'NAME'});

 or

 $sync->target($ldaphandle);

 $sync->mappings(FIRSTNAME=>'givenName',SURNAME=>'sn');

 $sync->buildattributes(dn=>"cn=%NAME%,ou=testcontainer,dc=test,dc=org",
			objectclass=>"organizationalUnit");

 $sync->transforms(	PHONE=>'s/0(\d{4})/\+44 \($1\) /',
			ADDRESS=>sub{my $address=shift;
					$address=~s/\n/\<BR\>/g;
					return $address});

 $sync->validation(	address=>"/street/i",
			name=>"/(Dr|Mr|Mrs|Ms|Miss)/" );

 $sync->save("filename");

 $sync->load("filename");

 $sync->run();

 print $sync->error();

 print $sync->lastruntime();

 print $sync->commit();

(For more complex uses, see Data::Sync::Advanced)

=head1 DESCRIPTION

NB: 0.07 is an interim release - the next version will contain significant changes, including changes to the UI.

Data::Sync is a simple metadirectory/data pump module. It automates a number of the common tasks required when writing code to migrate/sync information from one datasource to another. 

In order to use Data::Sync, you must define a source and a target. The first parameter to the source & target methods is a bound DBI/Net::LDAP handle.

Having defined your datasources, define how attributes map between them with mappings. If an attribute returned from the data source has no entry in the mapping table, it will be assumed that the name is the same in both databases.

Attributes can be built up from multiple other attributes using buildattributes. This uses a simple template, %FIELDNAME% which is replaced at run time with the value of the field from the current record. More complex modifications to data can be made with transforms, which runs after the built attributes are created.

Transforms can be made with the method transforms, which takes a hash of FIELDNAME=>transformation. This transformation can be one of three things: a regular expression in string form (see synopsis), the name of a predefined transformation supplied in Data::Sync, or a code ref.

Finally, if you are confident your data is all in the right format, use run. That will read the data from the source, modify it as you have specified, validate it against the pattern matches you've specified (if any) and write it to the target.

B<WARNING!> There is no implied or real warranty associated with the use of this software. That's fairly obvious, but worth repeating here. Metadirectory applications have the potential to destroy data in a very big way - they must be constructed carefully, and thoroughly tested before use on a live system.

=head1 CONSTRUCTOR

 my $sync = Data::Sync->new(log=>"STDOUT");
 my $sync = Data::Sync->new(log=>$fh);
 my $sync = Data::Sync->new(configfile=>"config.dds");
 my $sync = Data::Sync->new(jobname=>"MyJob");

The constructor returns a Data::Sync object. Optionally, to use logging, pass the string STDOUT as the log parameter to print logging to STDOUT, or a lexical filehandle.  You can specify a config file to get the configuration from, in which case you don't need to call mappings/transforms etc, although you'll still need pass the db/ldap handles (only) to source & target.

If you are using attribute hashing to minimise unnecessary writes, you should specify a jobname, as this is the name given to the SQLite hash database.

=head1 METHODS

=head2 source

 $sync->source($dbhandle,{select=>"select * from testtable"});

 or

 $sync->source($ldaphandle,{filter=>"(cn=*)",
				scope=>"sub",
				base=>"ou=testcontainer,dc=test,dc=org"});

 or

 $sync->source($dbhandle); # only if loading config file

Requires a valid, bound (i.e. logged in) Net::LDAP or DBI handle, and a hash of parameters for the data source (assuming you aren't loading the config from a file). LDAP parameters are:
 filter
 scope
 base
 attrs
 controls

(See Net::LDAP for more details of these parameters).

DBI parameters are:
 select

 
=head2 target

 $sync->target($dbhandle,{table=>'targettable',
				index=>'NAME'});

 or

 $sync->target($ldaphandle);

 or

 $sync->target($db); # only if loading config from a file
 
 or
 
 $sync->target($dbhandle,{table=>'targettable',
				index=>'NAME'
  				hashattributes=>["ADDRESS","PHONE"]
					});
					
 or
 
 $sync->target($ldaphandle,{hashattributes=>["ADDRESS","PHONE"]}
				);

 
Requires a valid, bound (i.e. logged in) DBI or Net::LDAP handle, and a hash of parameters (unless you are loading the config from a file). No parameters are required for LDAP data targets, but a dn must have been either read from the data source or constructed using buildattributes. Valid DBI parameters are

 table - the table you wish to write to on the data target
 index - the attribute you wish to use as an index

There is no 'pre check' on datatypes or lengths, so if you attempt to write a record with an oversized or mismatched data type, it will fail with an error. 

Note: if you are writing from DB to LDAP, you must construct all mandatory attributes using buildattributes, or additions will fail.

Attribute hashing can be specified with the keys:

 index=>"index/key attribute"
 hashattributes=>["attrib","attrib","attrib"]

When running, this will create an MD5 hash of the concatentation of the specified attributes, and store it in a database under the specified index. Next time the job is run, it will hash the value again, and compare it with the last hashed value. If they are the same, the record will not be written to the target. These entries are stored in a SQLite database - if you want to manipulate the database directly, you can do so with a sqlite3 client. The SQLite database takes it's name from the 'jobname' attribute specified in $sync->new. If you didn't specify a jobname, it will default to 'noname' - so if you are running multiple jobs with attribute hashing in the same directory on your disk, it's important to make sure they have names.


=head2 mappings

 $sync->mappings(FIRSTNAME=>'givenName',SURNAME=>'sn');

Maps individual field names from the data source, to their corresponding field names in the data target.

=head2 buildattributes

 $sync->buildattributes(dn=>"cn=%NAME%,ou=testcontainer,dc=test,dc=org",
			objectclass=>"organizationalUnit");

Builds new target attributes up from existing source attributes. A simple template form is used - the template should be a string variable, containing the source field name between % delimiters. If no % delimiters are found, the string will be written as a literal.

=head2 transforms

 $sync->transforms(	PHONE=>'s/0(\\d{4})/\+44 \(\$1\)/',
			OFFICE=>"stripspaces",
			ADDRESS=>sub{my $address=shift;
			$address=~s/\n/\<BR\>/g;
			return $address});

Converts each field in the source data using the parameters passed. Each parameter pair is the I<target> field name, along with a regex (in a string), a coderef, or a standard function. The following list of transformation functions are supplied in this version:

 stripspaces
 stripnewline
 uppercase
 lowercase
 concatenate

concatenate joins together the values of a multi valued attribute with the content of $sync->{mvseparator} - this defaults to | but can be changed with:

 $sync->mvseparator("<separator>");

Transformations are recursive, so if you are importing some form of hierarchical data, the transformation will walk the tree until it finds a scalar (or a list, in the case of concatenate) that it can perform the transformation on.

Note: If passing a regex in a string, make sure you use single quotes. Double quotes will invite perl to interpolate the contents, with unexpected results. 

=head2 validation

 $sync->validation(	address=>"/street/i",
			name=>"/(Dr|Mr|Mrs|Ms|Miss)/" );

Validation defines pattern matches for attributes. The validation methods are the last to be called before writing. If any of the specified fields fail to match the specified pattern match, the whole validation will fail and the write will not happen. Validation is optional, you don't have to specify a validation set, but it's useful to ensure that the constructed record set is what you were expecting before you write it out. Validation is also recursive, so it will handle multi valued attributes and subtrees in LDAP.

=head2 deletes

 $sync->deletes("delete");

 or
 
 $sync->delete(attrib=>value,attrib=>value);
 
Define the action to be taken against entries that have been deleted. Note that this only works if hashing is defined in 'target'. The parameters can be "delete", in which case the entry is deleted, or attrib=>value pairs, in which case the specified attributes are changed to the string in 'value'. Note that it is impossible to do a 'transform' on the attribute value, as the data is no longer present once a delete has been detected.



=head2 save

 $sync->save("filename");

Saves the config to a Data::Dump::Streamer file. Returns 1 on success.

=head2 load

 $sync->load("filename");

Loads the config from a Data::Dump::Streamer file previously created with save. You still need to define the source and target db/ldap handles with source & target, but if you've loaded the config from a file you can omit the hash of options.

=head2 run

 $sync->run() or die $sync->error."\n";

No parameters. Reads the data from the source, converts and renames it as defined in mappings, buildattributes and transforms, and writes it to the target.

=head2 error

 print $sync->error;

Returns the last error encountered by the module. This is set e.g. when a file fails to load correctly, when a sql error is encountered etc. When this occurs, the return value from the called function will be zero, and error() should be called to identify the problem.

=head2 lastruntime

 print $sync->lastruntime;

Returns the last time the job was run as YYYYMMDDHHMMSS. This is saved in the config file.

=head2 mvseparator

 $sync->mvseparator("<separator>");

 print $sync->mvseparator();

Sets or returns the multi valued attribute separator. (defaults to |)

=head2 commit

 $sync->commit();

Calls the write handle commit method, where the write handle is DBI (there's no rollback/commit available in LDAP). This is provided as a convenience, just in case you have autocommit turned off on your db handle.

=head1 SEE ALSO

More detail on extra methods, accessing the internal methods of Data::Sync from your code, and subclassing are detailed in Data::Sync::Advanced

=head1 PREREQS

If you want to save and load definition files, you'll need Data::Dump::Streamer

If you are using DBI datasources, you will need DBI & the appropriate DBI drivers.

If you are using LDAP datasources, you will need Net::LDAP.

If you are using attribute hashing, you will also need DBI & DBD::SQLite

=head1 VERSION

0.07

=head1 BUGS & CAVEATS

Data::Sync handles column/attribute names as case sensitive. Postgresql (at least at time of writing) appears to return column names as lc, whether they're created lc or not. I make no guarantees about this, but using lower case column names in all Data::Sync code seems to work OK. Please ensure that any code you write using this module with postgresql is particularly thoroughly tested.

=head1 TODO

Hashing individual attributes so if one attribute changes, only that attribute is written.

UI changes: instead of passing a handle, pass a type=>LDAP/DBI/Psql etc, and the connect parameters. Restructure in subclasses so that DBI is a generic sql, but can be subclassed by specific classes for particular datasources. This is a major change to the UI. write a handle factory to create the db/ldap handle. The AoH for records, and methods for read and write are required. This sits well with the dispatcher class. Retain handle passing UI facility if possible, but deprecate.

Implementing Data::Sync::Datasource as a dispatcher class redirecting to ::dbi & ::ldap would fit the UML model better, might make subclassing easier, and would probably be easier to maintain. For other divisions see Classes.dia

Validation can  be extended for deletes by putting a % comparison of recordset vs delete set in 'run'

Multiple sources in a single job? Possibly by naming, and with a default name to support existing syntax.

Separate out the table creation methods into a subclass(?) and use a dispatcher? (table creation WIP)

Friendly CSV/TD source/target methods

Modular datasource/targets for including non dbi/ldap datasources?
		
Example using AnyData & XML

Multiple targets in a single job?

Caching?

UTF8/ANSI handling.

Perltidy the tests (thanks for spotting the mess Gavin)

=head1 CHANGES

v0.08

Bugfix, added package statement to Advanced.pm to ensure correct CPAN indexing

v0.07

Added in 'add if no index' facility on writedbi

Generalised delta code

Removed 'use DDS' and replaced with 'require' in save and load methods, so dependency is only if using those functions

Implemented ::deletes

Generalised sourceToAoH & write methods

Separated complex uses into Data::Sync::Advanced POD

Implemented get & put methods

Implemented hashrecord method

extended testing

v0.06

Implemented a commit method for the writehandle.

Implemented validate function

v0.05

Fixed some 0E0 problems with return values from DBI.

Added postgresql caveat.

Extended developer test suite to include MySQL & Postgresql

v0.04

Implemented basic attribute hashing

Added concatenate function for multivalued ldap attributes

v0.03

Added uppercase and lowercase transformations

Moved read and write subs out of anonymous blocks

hid raw regex in #!#<regex>#!# inside coderef for regex transformations (can be parsed out for display/edit in gui)

implemented batch updating

V0.02

Implemented load & save functions.

Implemented error function

Modified stripnewlines to replace with whitespace.

=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Charles Colbourn

charlesc@g0n.net

=cut
