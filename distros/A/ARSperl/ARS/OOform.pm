# 
# ARSperl - An ARS v2-v4 / Perl5 Integration Kit 
# 
# Copyright (C) 1995-1999 Joel Murphy, jmurphy@acsu.buffalo.edu 
# Jeff Murphy, jcmurphy@acsu.buffalo.edu 
# 
# This program is free software; you can redistribute it and/or modify 
# it under the terms as Perl itself.  
# 
# Refer to the file called "Artistic" that accompanies the source distribution
# of ARSperl (or the one that accompanies the source distribution of Perl 
# itself) for a full description.  
# 
# Official Home Page: 
# http://www.arsperl.org/
# 
# Mailing List (must be subscribed to post):  
# See URL above.
#

package ARS::form;
require Carp;

# new ARS::form(-form => name, -vui => view, -connection => connection)

sub new {
	my ($class, $self) = (shift, {});
	my ($b) = bless($self, $class);
	
	my ($form, $vui, $connection) =  
	  ARS::rearrange([FORM,VUI,CONNECTION],@_);
	
	$connection->pushMessage(&ARS::AR_RETURN_ERROR,
				 81000,
				 "usage: new ARS::form(-form => name, -vui => vui, -connection => connection)\nform and connection parameters are required."
				)    
	  if(!defined($form) || !defined($connection));
	
	$vui = "Default Admin View" unless defined $vui;
	
	$self->{'form'}       = $form;
	$self->{'connection'} = $connection;
	$self->{'vui'}        = $vui;
	my %f = ARS::ars_GetFieldTable($connection->{'ctrl'}, 
				       $form);
	
	$connection->tryCatch();
	$self->{'fields'}     = \%f;
	
	my %rev = reverse %f; # convenient
	$self->{'fields_rev'} = \%rev;
	
	my(%t, %enums);
	
	foreach (keys %f) {
		print "caching field: $_\n" if $self->{'connection'}->{'.debug'};
		my $fv = ARS::ars_GetField($self->{'connection'}->{'ctrl'},
					   $self->{'form'},
					   $f{$_});
		$connection->tryCatch();
		$t{$_} = $fv->{'dataType'};
		print "\tdatatype: $t{$_}\n" if $self->{'connection'}->{'.debug'};

		if ($fv->{'dataType'} eq "enum") {
			if (ref($fv->{'limit'}->{'enumLimits'}) eq "ARRAY") {
                                my $i = 0;
                                $enums{$_} = { map { $i++, $_ } @{$fv->{'limit'}->{'enumLimits'}} };
                        }
			elsif (exists $fv->{'limit'}->{'enumLimits'}->{'regularList'}) {
                                my $i = 0;
                                $enums{$_} = { map { $i++, $_ } @{$fv->{'limit'}->{'enumLimits'}->{'regularList'}} };
			} else {
                                $enums{$_} = { map { $_->{itemNumber}, $_->{itemName} } @{$fv->{'limit'}->{'enumLimits'}->{customList}} };
			}
		}
	}
	
	$self->{'fieldtypes'} = \%t;
	$self->{'fieldEnumValues'} = \%enums;
	return $b;
}

sub DESTROY {
  
}

# getEnumValues(-field => "fieldname")

sub getEnumValues {
	my ($this) = shift;
	my ($field) = ARS::rearrange([FIELD], @_);
	if(ref($this->{'fieldEnumValues'}->{$field}) eq "ARRAY") {
		return @{$this->{'fieldEnumValues'}->{$field}};
	}
        $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
                                           81006,
                                           "field $field is not an enumeration field.");
	$this->{'connection'}->tryCatch();
	return undef;
}

# query(-query => "qualifier", -maxhits => 100, -firstretrieve => 0)

sub query {
    my ($this) = shift;
    my ($query, $maxhits, $firstretr) = ARS::rearrange([QUERY,MAXHITS,FIRSTRETRIEVE], @_);
    $query = "(1 = 1)" unless defined($query);
    $maxhits = 0 unless defined($maxhits);
    $firstretr = 0 unless defined($firstretr);
    
    if($this->{'connection'}->{'.debug'}) {
	print "form->query(".$this->{'form'}.", $query, ".$this->{'vui'}.")\n";
    }
    
    $this->{'qualifier'} = 
      ARS::ars_LoadQualifier($this->{'connection'}->{'ctrl'},
			     $this->{'form'},
			     $query,
			     $this->{'vui'});
    $this->{'connection'}->tryCatch();
    
    my @sortOrder = ();
    if(defined($this->{'sortOrder'}) && 
       ref($this->{'sortOrder'}) eq "ARRAY") {
    		@sortOrder = @{$this->{'sortOrder'}};
    }
    
    my @matches = ARS::ars_GetListEntry($this->{'connection'}->{'ctrl'},
					$this->{'form'},
					$this->{'qualifier'},
					$maxhits, $firstretr,
					@sortOrder);
    
    my(@mids, @mdescs);
    for(my $i = 0; $i <= $#matches ; $i += 2) {
	push @mids, $matches[$i];
	push @mdescs, $matches[$i+1];
    }
    
    $this->{'matches'} = \@mids;
    $this->{'querylist'} = \@mdescs;
    
    return @mids;
}

# getFieldID(-field => name)

sub getFieldID {
    my $this = shift;
    my ($name) = ARS::rearrange([FIELD], @_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->getFieldID(-field => name)\nname parameter is required.")
	unless defined($name);
    
    if(!defined($this->{'fields'}->{$name})) {
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81001,
					   "field '$name' not in view: ".$this->{'vui'}."\n"
					   );
    }
    
    return $this->{'fields'}->{$name} if(defined($name));
}

# getFieldName(-id => id)

sub getFieldName {
    my $this = shift;
    my ($id) = ARS::rearrange([ID], @_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->getFieldName(-id => id)\nid parameter required."
				       )
	unless defined($id);
    
    return $this->{'fields_rev'}->{$id} if defined($this->{'fields_rev'}->{$id});
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81002,
				       "field id '$id' not available on form: ".$this->{'form'}.""
				       );
}

# getFieldType(-field => name, -id => id)

sub getFieldType {
    my $this = shift;
    my ($name, $id) = ARS::rearrange([FIELD,ID], @_);
    
    if(!defined($name) && !defined($id)) {
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81000,
					   "usage: form->getFieldType(-field => name, -id => id)\none of the parameters must be specified.");
    }
    
    if(defined($name) && !defined($this->{'fieldtypes'}->{$name})) {
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81001,
					   "field '$name' not in view: ".$this->{'vui'}."\n"
					   );
    }
    
    #print "getFieldType($name, $id)\n" if $this->{'connection'}->{'.debug'};
    
    return $this->{'fieldtypes'}->{$name} if defined($name);
    
    # they didnt give us a name, but instead gave us an id. look up the
    # name and return the type.
    
    if(defined($id)) {
	my $n = $this->getFieldName(-id => $id);
	return $this->{'fieldtypes'}->{$n};
    }
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81003,
				       "couldn't determine dataType for field.");
}

# delete(-entry => id)

sub delete {
    my $this = shift;
    my ($id) = ARS::rearrange([ENTRY],@_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->delete(-entry => id)\nentry parameter is required.")
	unless defined($id);
    
    my (@d);
    
    # allow the user to delete multiple entries in one shot
    
    if(ref($id) eq "ARRAY") {
	@d = @{$id};
    } else {
	push @d, $id;
    }
    
    foreach (@d) {
      ARS::ars_DeleteEntry($this->{'connection'}->{'ctrl'},
			   $this->{'form'},
			   $_);
	$this->{'connection'}->tryCatch();
    }
}

# merge(-type => mergeType, -values => { field1 => value1, ... })

sub merge {
	my ($this) = shift;
	my ($type, $vals) = 
	  ARS::rearrange([TYPE,[VALUE,VALUES]],@_);

	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81000,
					   "usage: form->merge(-type => mergeType, -values => { field1 => value1, ... })\ntype and values parameters are required.")
	  unless(defined($type) && defined($vals));
	
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81000,
					   "usage: form->merge(-type => mergeType, -values => { field1 => value1, ... })\nvalues parameter must be HASH ref.") 
	  unless ref($vals) eq "HASH";
	
	my (%realmap);
	
	# as we work thru each value, we need to perform translations for
	# enum fields.
	
	foreach (keys %{$vals}) {
		my ($rv) = $this->value2internal(-field => $_,
						 -value => $vals->{$_});
		#print "[form->merge] realval for $_ = $rv\n";
		$realmap{$this->getFieldID($_)} = $rv;
	}

	print "merge/type=$type\n" if $this->{'connection'}->{'.debug'};

	my ($rv) = ARS::ars_MergeEntry($this->{'connection'}->{'ctrl'},
				       $this->{'form'},
				       $type,
				       %realmap);
	

	$this->{'connection'}->tryCatch();

	# if ($rv is "") and there are no FATAL or ERRORs and
	# an entry id was in our vals realmap hash, then this was
	# a successful "OVERWRITE" or "MERGE" operation. lets return
	# the entry-id. if $rv is no "", then whatever operation this
	# was - it was successful. if it's "" and we had no entry-id
	# specified - or we did have one specified and there are FATALs
	# or ERRORs then something is wrong. complicated, but that's how
	# the C API works. we try to make the OO layer a little nicer for
	# the end user.

	if(($rv eq "") && defined($realmap{1})) {
		if(!$this->{'connection'}->hasFatals() &&
		   !$this->{'connection'}->hasErrors()) {
			$rv = $realmap{1};
		}
	}
		   
	return $rv;
}

# set(-entry => id, -gettime => tstamp, -values => { field1 => value1, ... })

sub set {
    my ($this) = shift;
    my ($entry,$gettime,$vals) = 
      ARS::rearrange([ENTRY,GETTIME,[VALUE,VALUES]],@_);
    
    $gettime = 0 unless defined($gettime);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->set(-entry => id, -gettime => tstamp, -values => { field1 => value1, ... })\nentry and values parameters are required."
				       )
	unless (defined($vals) && defined($entry));
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->set(-entry => id, -values => { field1 => value1, ... })\nvalues parameter must be HASH ref.") 
	unless ref($vals) eq "HASH";
    
    my (%realmap);
    
    # as we work thru each value, we need to perform translations for
    # enum fields.
    
    foreach (keys %{$vals}) {
	my ($rv) = $this->value2internal(-field => $_,
					 -value => $vals->{$_});
	#print "realval for $_ = $rv\n";
	$realmap{$this->getFieldID($_)} = $rv;
    }
    
    my ($rv) = ARS::ars_SetEntry($this->{'connection'}->{'ctrl'},
				 $this->{'form'},
				 $entry,
				 $gettime,
				 %realmap);
    
    $this->{'connection'}->tryCatch();
    
    return $rv;
}

# value2internal(-field => name, -value => value)

sub value2internal {
    my ($this) = shift;
    my ($f, $v) = ARS::rearrange([FIELD,VALUE], @_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->value2internal(-field => name, -value => value)\nfield parameter is required.") 
	unless (defined($f));
    
    return $v unless defined $v;
    my ($t) = $this->getFieldType($f);
    
    print "value2internal($f, $v) type=$t\n" 
	if $this->{'connection'}->{'.debug'};
    
    # translate an text value into an enumeration number if this
    # field is an enumeration field and we havent been passed a number
    # to begin with.
    
    if(($t eq "enum") && ($v !~ /^\d+$/)) {
	if(!defined($this->{'fieldEnumValues'}->{$f})) {
	    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					       81004,
					       "[1] unable to translate enumeration value for field '$f'");
	}
	foreach (keys %{$this->{'fieldEnumValues'}->{$f}}) {
	    return $_ if $this->{'fieldEnumValues'}->{$f}->{$_} eq $v;
	}
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81004,
					   "[2] unable to translate enumeration value for field '$f'");
    }
    
    # we don't need translation..
    
    return $v;
}

# internal2value(-field => name, -id => id, -value => value)

sub internal2value {
    my ($this) = shift;
    my ($f, $id, $v) = ARS::rearrange([FIELD,ID,VALUE], @_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->internal2value(-field => name, -id => id, -value => value)\nid or field parameter are required.")
	unless (defined($f) || defined($id));
    
    $f = $this->getFieldName(-id => $id) unless defined($f);
    
    my ($t) = $this->getFieldType($f);
    
    print "internal2value($f, $v) type=$t\n" 
	if $this->{'connection'}->{'.debug'};
    
    # translate an enumeration value into a text value
    
    if($t eq "enum") {
	# if the field doesnt exist in our cache, or if the
	# enumeration value exceeds the known list of enumerations,
	# barf.
	
	return undef unless defined $v;
	if(!defined($this->{'fieldEnumValues'}->{$f}) || 
	   (!exists($this->{'fieldEnumValues'}->{$f}->{$v})) ) {
	    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					       81004,
					       "[1] unable to translate enumeration value for field '$f'"
					       );
	}
	
	return $this->{'fieldEnumValues'}->{$f}->{$v}
	}
    
    # we don't need translation..
    
    return $v;
}

# create(-values => { field1 => value1, ... })

sub create {
    my ($this) = shift;
    my ($vals) = ARS::rearrange([[VALUES,VALUE]],@_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->create(-values => { field1 => value1, ... })\nvalues parameter is required.") 
	unless defined($vals);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->create(-values => { field1 => value1, ... })\nvalues parameter must be HASH ref.") 
	unless ref($vals) eq "HASH";
    
    my (%realmap);
    
    print "Mapping field information.\n" if $self->{'connection'}->{'.debug'};
    foreach (keys %{$vals}) {
	my ($rv) = $this->value2internal(-field => $_,
					 -value => $vals->{$_});
	#print "realval for $_ = $rv\n";
	$realmap{$this->getFieldID($_)} = $rv;
    }
    
    print "calling ars_CreateEntry..\n" if $self->{'connection'}->{'.debug'};
    my ($id) = ARS::ars_CreateEntry($this->{'connection'}->{'ctrl'},
				    $this->{'form'},
				    %realmap);
    
    print "calling tryCatch()..\n" if $self->{'connection'}->{'.debug'};
    $this->{'connection'}->tryCatch();
    
    return $id;
}

# get(-entry => entryid, -fields => [ field1, field2 ])

sub get {
    my $this = shift;
    my ($eid, $fields) = ARS::rearrange([ENTRY,[FIELD,FIELDS]],@_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->get(-entry => entryid, -fields => [ field1, field2, ... ])\nentry parameter is required.") 
	unless defined($eid);
    
    my (@fieldlist) = ();
    my ($allfields) = 1;
    
    if(defined($fields)) {
	$allfields = 0;
	foreach (@{$fields}) {
	    push @fieldlist, $this->getFieldID($_);
	}
    }
    
    # what we want to do is: retrieve all of the values, but for
    # certain datatypes (attachments) we want to insert
    # an object instead of the field value. for enum types, 
    # we want to decode the value.
    
    #print "(";  print $this->{'form'}; print ", $eid, @fieldlist)\n";
    
    my @v;
    if($allfields == 0) {
	@v = ARS::ars_GetEntry($this->{'connection'}->{'ctrl'},
			       $this->{'form'},
			       $eid, @fieldlist);
    } else {
	@v = ARS::ars_GetEntry($this->{'connection'}->{'ctrl'},
			       $this->{'form'},
			       $eid);
    }
    
    my @rv;
    
    for(my $i = 0 ; $i <= $#v ; $i += 2) {
	if($this->getFieldType(-id => $v[$i]) eq "attach") {
	    push @rv, $v[$i+1]; # "attach";
	} 
	elsif($this->getFieldType(-id => $v[$i]) eq "enum") {
	    push @rv, $this->internal2value(-id => $v[$i],
					    -value => $v[$i+1]);
	} 
	else {
	    push @rv, $v[$i+1];
	}
    }
    
    return @rv unless ($#rv == 0);
    return $rv[0];
}


# getAsHash(-entry => entryid, -fields => [field1, field2, ...])

sub getAsHash {
    my $this = shift;
    my ($eid, $fields) = ARS::rearrange([ENTRY,[FIELD,FIELDS]],@_);
    
    $this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
				       81000,
				       "usage: form->getAsHash(-entry => entryid, -fields => [ field1, field2, ... ])\nentry parameter is required.") 
	unless defined($eid);
    
    my (@fieldlist) = ();
    my ($allfields) = 1;
    
    if(defined($fields)) {
	$allfields = 0;
	foreach (@{$fields}) {
	    push @fieldlist, $this->getFieldID($_);
	}
    }
    
    my @v;
    if($allfields == 0) {
	@v = ARS::ars_GetEntry($this->{'connection'}->{'ctrl'},
			       $this->{'form'},
			       $eid, @fieldlist);
    } else {
	@v = ARS::ars_GetEntry($this->{'connection'}->{'ctrl'},
			       $this->{'form'},
			       $eid);
    }
    
    for(my $i = 0 ; $i <= $#v ; $i += 2) {
	if($this->getFieldType(-id => $v[$i]) eq "attach") {
	    #$v[$i+1] = "attach";
	} 
	elsif($this->getFieldType(-id => $v[$i]) eq "enum") {
	    $v[$i+1] = $this->internal2value(-id => $v[$i], 
					     -value => $v[$i+1]);
	}
	$v[$i] = $this->getFieldName(-id => $v[$i]);
    }
    
    return @v;
}

# getAttachment(-entry => eid, -field => fieldname, -file => filename)
# if file isnt specified, the attachment is returned "in core"

sub getAttachment {
    my $this = shift;
    my ($eid, $field, $file) = ARS::rearrange([ENTRY,FIELD,FILE],@_);
    
    if(!defined($eid) && !defined($field)) {
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81000,
					   "usage: getAttachment(-entry => eid, -field => fieldname, -file => filename)\nentry and field parameters are required.");
    }
    
    if(defined($file)) {
	my $rv = ARS::ars_GetEntryBLOB($this->{'connection'}->{'ctrl'},
				       $this->{'form'},
				       $eid,
				       $this->getFieldID($field),
				     ARS::AR_LOC_FILENAME,
				       $file);
	$this->{'connection'}->tryCatch();
	return $rv;
    } 
    
    return  ARS::ars_GetEntryBLOB($this->{'connection'}->{'ctrl'},
				  $this->{'form'},
				  $eid,
				  $this->getFieldID($field),
				ARS::AR_LOC_BUFFER);
}

#setSort(... )

sub setSort {
    my $this = shift;
    
    if(($#_+1) % 2 == 1){
	$this->{'connection'}->pushMessage(&ARS::AR_RETURN_ERROR,
					   81000,
					   "usage: setSort(...)\nMust have an even number of parameters. (nparm = $#_)");
    }
    
    my (@t) = @_;
    
    for(my $i = 0 ; $i <= $#t ; $i+=2) {
	$t[$i] = $this->getFieldID($t[$i]);
    }
    
    $this->{'sortOrder'} = \@t;
}

1;
