#########################################################################
# This file contains POD only - it's the advanced usage documentation
#
#
#########################################################################
package Data::Sync::Advanced;

=pod

=head1 NAME

Data::Sync - A simple metadirectory/datapump module (advanced usage)


=head1 DESCRIPTION

The basic functionality of Data::Sync is described in the main POD documentation. This documentation details more complex or rarely used functionality. You may have a requirement to customise Data::Sync by subclassing it, or you may wish to have more granular control over data flow for example. Or you may just want to use individual functions of the module as a sort of toolkit. If any of these are the case, you're reading the right document

 
=head1 EXTRA METHODS

=head2 get

 my $AoH = $sync->get();

This function triggers the read function defined in the Data::Sync constructor, and returns the resulting data as an array of hashes (see perlref if you are unfamilar with how to access this kind of data structure).
 
=head2 put

 my $result = $sync->put($AoH);

This function writes the content of $AoH (an array of hashes) to the target defined in the Data::Sync constructor, and returns the result (1 for success).

=head2 hashrecord

 my $hash = $sync->hashrecord($hashref,$arrayref);

This function is used internally by Data::Sync to detect changes in records (for minimising writes), but is also accessible for other uses. It takes a hashref of the db record, and an arrayref of attributes to include in the hash. It returns a hex representation of the MD5 hash of the concatenated record values. You can also call it with

 my $hash = Data::Sync->hashrecord($hashref,$arrayref);
 
(i.e. it does not depend on values set in the object constructor).

=head2 remap

 my $remapped = $sync->remap($AoH)
 
Remaps the field names, as defined in $sync->mappings. Takes array of hashes, returns array of hashes with the hash keys renamed.

=head2 runtransform

 my $transformed = $sync->runtransform($AoH);
 
Runs the transformations defined in $sync->transform. Takes array of hashes, returns array of hashes. You can use this function in conjunction with mappings as a utility function to perform recursive transformations of data:

 my $sync = Data::Sync->new();
 $sync->transform(name=>lowercase);
 my $transformed = $sync->runtransform($AoH);
 
will recurse through a data structure (an array of arrays, array of hashes, array of hashes of arrays of hashes etc) of arbitrary depth, performing the transform on all hash values where the key matches (including every value of hash values containing anonymous arrays).

=head2 makebuiltattributes

 my $transformed = $sync->makebuiltattributes($AoH);
 
Create attributes in the data set as defined in buildattributes().

=head2 scanhashtable

 my $hashed = $self->scanhashtable($AoH);
 
Check the dataset against the stored hashtable, to filter out unchanged records. Returns a dataset with unchanged records removed. Requires that hashattributes has been set in the target definition.

=head2 hashrecord

 my $hash = $self->hashrecord(\%record,[ATTRIB,ATTRIB]);
 
returns a hexdigest MD5 hash of the attributes in the record.

=head2 getdeletes

 my @deletes = $self->getdeletes();
 
returns a list of TARGETINDEX=>value entries for all entries that have been deleted. This is a function of hashing, so will only detect deletes if the following steps are followed (the run method does this):

 1) read from source
 2) transform etc
 3) hash the entries
 
Note that you don't need to write for deletes to be detected - the hashing of entries is done by scanhashtable before the write to target function is called. This means that using get() and scanhashtable() you can set the deltas to the current state without performing a write.

=head1 batch update mode

 $sync->source($handle,{	batchsize=>x,
 				controls=>[$ldapcontrol]	} );

Batch update mode is only used in the standard (i.e. $sync->run based) usage of Data::Sync. Its primarily intended to handle asynchronous, persistent/paged LDAP searches, or SQL database queries where you want to see the updates as quickly as possible (without necessarily waiting for them all to complete). For details on how to construct persistent & asynchronous LDAP controls, see Net::LDAP::Control. This will read a batch from the handle, perform the operation, read the next batch from the handle, and so on. Note that with a DBI handle, this will still be working against an entire record set matching your criteria, so the memory advantages are limited.

=head1 subclassing Data::Sync

For whatever reason, you may want to subclass Data::Sync - perhaps to implement RDBMS specific read or write functions, or to add new functionality. Data::Sync is (or should be) subclass safe. The main functions you are likely to want to overload are:

 readdbi
 writedbi
 readldap
 writeldap

each will be passed the following parameters in sequential order:

 self
 db/ldap handle
 anonymous hash of parameters (see 'source' and 'target' methods.
 
and called by get/put or run().

You might also want to overload ::run with your own variant. ::run calls the read, remap, transform and writes methods sequentially (If you look at ::run, it also calls sourceToAoH - this is a vital call to convert a DBI or LDAP handle into an array of hashes record set, before remapping and transforming the records).

You may also wish to use a database other than SQLite to hash records, in which case you need to overload getdeletes() and scanhashtable(). See the code for more details.

=head1 EXAMPLE USES

 my $source1 = Data::Sync->new();
 $source1->source($dbhandle,"select * from sourcetable1");
 $source1->mappings(NAME=>NEWNAME);
 $source1->transform(NEWNAME=>lowercase);
 
 my $source2->new();
 $source2->source($dbhandle2,"select * from sourcetable2");
 $source2->mappings(FULLNAME=>NEWNAME);
 $source2->transform(NEWNAME=>lowercase);
 
 my $target=Data::Sync->new();
 $target->target($dbhandle3,{index=>NEWNAME});
 
 my $set1 = $source1->get();
 $set1 = $source1->remap($set1);
 $set1 = $source1->runtransform($set1);
 
 my $set2 = $source2->get();
 $set2 = $source2->remap($set2);
 $set2 = $source2->runtransform($set2);
 
 my @recordset = (@$set1,@$set2);
 $target->put(\@recordset);
 
Would read the two defined sources, remap & transform the contents, join the two datasets together, and write them both to the target.
