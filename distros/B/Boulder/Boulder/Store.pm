# $Id: Store.pm,v 1.6 2002/06/28 20:31:59 lstein Exp $

# Prototype support library for storing Boulder streams.
# Basic design is as follows:
#   The "data" file, named <basename>.records contains
#       a recno style data file.  Records are delimited by
#       newlines.  Each record has this form:

#       tag=long string value&tag=long string value...
#       Subrecords are delimited by {} pairs as per the
#       usual boulderio format.

#   The "index" file, named <basename>.index, is a DB_Hash
#       that contains several things:
#       1. Indexes.  The key <key path> is used to translate
#          from index to the list of record entries.
#       2. Other information:
#             .INDICES -- list of tags that are indexed.

package Boulder::Store;

=head1 NAME

Boulder::Store - Simple persistent storage for Stone tag/value objects

=head1 SYNOPSIS

 Boulder:Store;

 my $store=new Boulder::Store('test.db',1);
 my $s = new Stone (Name=>'george',
	            Age=>23,
		    Sex=>M,
		    Address=>{
			   Street=>'29 Rockland drive',
			   Town=>'Fort Washington',
			   ZIP=>'77777'
			   }
		       );
 $store->put($s);
 $store->put(new Stone(Name=>'fred',
		       Age=>30,
		       Sex=>M,
		       Address=>{
                                   Street=>'19 Gravel Path',
				   Town=>'Bedrock',
				   ZIP=>'12345'},
		       Phone=>{
				 Day=>'111-1111',
				 Eve=>'222-2222'
				 }
			     ));
 $store->put(new Stone(Name=>'andrew',
		       Age=>18,
		       Sex=>M));

 $store->add_index('Name');

 my $stone = $store->get(0);
 print "name = ",$stone->Name;

=head1 DESCRIPTION

Boulder::Store provides persistent storage for Boulder objects using a
simple DB_File implementation.  To use it, you need to have Berkeley
db installed (also known as libdb), and the Perl DB_File module.  See
the DB_File package for more details on obtaining Berkeley db if you
do not already have it.

Boulder::Store provides an unsophisticated query mechanism which takes
advantage of indexes that you specify.  Despite its lack of
sophistication, the query system is often very helpful.

=head1 CLASS METHODS

=over 4

=item $store = Boulder::Store->new("database/path",$writable)

The B<new()> method creates a new Boulder::Store object and associates
it with the database file provided in the first parameter (undef is a
valid pathname, in which case all methods work but the data isn't
stored).  The second parameter should be a B<true> value if you want
to open the database for writing.  Otherwise it's opened read only.

Because the underlying storage implementation is not multi-user, only
one process can have the database for writing at a time.  A
B<fcntl()>-based locking mechanism is used to give a process that has
the database opened for writing exclusive access to the database.
This also prevents the database from being opened for reading while
another process is writing to it (this is a B<good> thing).  Multiple
simultaneous processes can open the database read only.

Physically the data is stored in a human-readable file with the
extension ".data".

=back

=head1 OBJECT METHODS

=over 4

=item $stone = $store->read_record(@taglist)

The semantics of this call are exactly the same as in
B<Boulder::Stream>.  Stones are returned in sequential order, starting
with the first record.  In addition to their built-in tags, each stone
returned from this call has an additional tag called "record_no".
This is the zero-based record number of the stone in the database.
Use the B<reset()> method to begin iterating from the beginning of the
database.

If called in an array context, B<read_record()> returns a list of all
stones in the database that contains one or more of the provided tags.

=item $stone = $store->write_record($stone [,$index])

This has the same semantics as B<Boulder::Stream>.  A stone is
appended to the end of the database.  If successful, this call returns
the record number of the new entry.  By providing an optional second
parameter, you can control where the stone is entered.  A positive
numeric index will write the stone into the database at that position.
A value of -1 will use the Stone's internal record number (if present)
to determine where to place it.

=item $stone = $store->get($record_no)

This is random access to the database.  Provide a record number and
this call will return the stone stored at that position.

=item $record_number = $store->put($stone,$record_no)

This is a random write to the database.  Provide a record number and
this call stores the stone at the indicated position, replacing whatever
was there before.

If no record number is provided, this call will look for the presence
of a 'record_no' tag in the stone itself and put it back in that
position.  This allows you to pull a stone out of the database, modify
it, and then put it back in without worrying about its record number.
If no record is found in the stone, then the effect is identical to
write_record().

The record number of the inserted stone is returned from this call, or
-1 if an error occurred.

=item $store->delete($stone),Boulder::Store::delete($record_no)

These method calls delete a stone from the database.  You can provide
either the record number or a stone containing the 'record_no' tag.
B<Warning>: if the database is heavily indexed deletes can be
time-consuming as it requires the index to be brought back into synch.

=item $record_count = $store->length()

This returns the length of the database, in records.

=item $store->reset()

This resets the database, nullifying any queries in effect, and
causing read_record() to begin fetching stones from the first record.

=item $store->query(%query_array)

This creates a query on the database used for selecting stones in
B<read_record()>.  The query is an associative array.  Three types of
keys/value pairs are allowed:

=over 4

=item (1) $index=>$value

This instructs Boulder::Store to look for stones containing the
specified tags in which the tag's value (determined by the Stone
B<index()> method) exactly matches the provided
value.  Example:

	$db->query('STS.left_primer.length'=>30);

Only the non-bracketed forms of the index string are allowed (this
is probably a bug...)

If the tag path was declared to be an index, then this search
will be fast.  Otherwise Boulder::Store must iterate over every
record in the database.

=item (2) EVAL=>'expression'

This instructs Boulder::Store to look for stones in which the
provided expression evaluates to B<true>.  When the expression
is evaluated, the variable B<$s> will be set to the current 
record's stone.  As a shortcut, you can use "<index.string>"
as shorthand for "$s->index('index.string')".

=item (3) EVAL=>['expression1','expression2','expression3'...]

This lets you provide a whole bunch of expressions, and is exactly
equivalent to EVAL=>'(expression1) && (expression2) && (expression3)'.

=back

You can mix query types in the parameter provided to B<query()>.
For example, here's how to look up all stones in which the sex is
male and the age is greater than 30:

	$db->query('sex'=>'M',EVAL=>'<age> > 30');

When a query is in effect, B<read_record()> returns only Stones
that satisfy the query.  In an array context, B<read_record()> 
returns a list of all Stones that satisfy the query.  When no
more satisfactory Stones are found, B<read_record()> returns
B<undef> until a new query is entered or B<reset()> is called.

=item $store->add_index(@indices)

Declare one or more tag paths to be a part of a fast index.
B<read_record()> will take advantage of this record when processing
queries.  For example:

	$db->add_index('age','sex','person.pets');

You can add indexes any time you like, when the database is first
created or later.  There is a trade off:  B<write_record()>,
B<put()>, and other data-modifying calls will become slower as 
more indexes are added.

The index is stored in an external file with the extension ".index".
An index file is created even if you haven't indexed any tags.

=item $store->reindex_all()

Call this if the index gets screwed up (or lost).  It rebuilds it
from scratch.

=back

=head1 CAVEATS

Boulder::Store makes heavy use of the flock() call in order to avoid
corruption of DB_File databases when multiple processes try to write
simultaneously.  flock() may not work correctly across NFS mounts,
particularly on Linux machines that are not running the rpc.lockd
daemon.  Please confirm that your flock() works across NFS before
attempting to use Boulder::Store.  If the store.t test hangs during
testing, this is the likely culprit.

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>, Cold Spring Harbor Laboratory,
Cold Spring Harbor, NY.  This module can be used and distributed on
the same terms as Perl itself.

=head1 SEE ALSO

L<Boulder>, L<Boulder::Stream>, L<Stone>

=cut

use Boulder::Stream;
use Carp;
use Fcntl;
use DB_File;

$VERSION = '1.20';

@ISA = 'Boulder::Stream';
$lockfh='lock00000';
$LOCK_SH = 1;
$LOCK_EX = 2;
$LOCK_UN = 8;

# Override the old new() method.
# There is no passthrough behavior in the database version,
# because this is usually undesirable.
# In this case,$in is the pathname to the database to open.
sub new {
    my($package,$in,$writable) = @_;
    my $self = bless {
	'records'=>undef,	# filled in by _open_databases
	'dbrecno'=>undef,	# filled in by _open_databases
	'index'=>undef,		# filled in by _open_databases
	'writable'=>$writable,
	'basename'=>$in,
	'passthru'=>undef,
	'binary'=>'true',
	'nextrecord'=>0,	# next record to retrieve during iterations
	'query_records'=>undef,	# list of records during optimized queries
	'query_test'=>undef,	# an expression to apply to each record during a query
	'IN'=>undef,
	'OUT'=>undef,
	'delim'=>'=',
	'record_stop'=>"\n",
	'line_end'=>'&',
        'index_delim'=>' ',
	'subrec_start'=>"\{",
	'subrec_end'=>"\}"
	},$package;
    return undef unless _lock($self,'lock');
    return _open_databases($self,$in) ? $self : undef;
}

sub DESTROY {
    my $self = shift;
    undef $self->{'dbrecno'};
    untie %{$self->{'index'}};
    untie @{$self->{'records'}};
    _lock($self,'unlock');
}

#####################
# private routines
####################
# Obtain exclusive privileges if database is
# writable.  Otherwise obtain shared privileges.
# Note that this call does not work across file systems,
# at least on non-linux systems.  Should use fcntl()
# instead (but don't have Stevens at hand).
sub _lock {
    my($self,$lockit) = @_;
    my $in = $self->{'basename'};
    my $lockfilename = "$in.lock";
    if ($lockit eq 'lock') {
	$lockfh++;
	open($lockfh,"+>$lockfilename") || return undef;
	$self->{'lockfh'}=$lockfh;
	return flock($lockfh,$self->{'writable'} ? $LOCK_EX : $LOCK_SH);
    } else {
	my $lockfh = $self->{'lockfh'};
	unlink $lockfilename;
	flock($lockfh,$LOCK_UN);
	close($lockfh);
	1;
    }
}

sub _open_databases {
    my $self = shift;

    # Try to open up and/or create the recno and index files
    my($in)=$self->{'basename'};
    my (@records,%index);
    my ($permissions) = $self->{'writable'} ? (O_RDWR|O_CREAT) : O_RDONLY;
    $self->{'dbrecno'} = tie(@records,DB_File,"$in.data",
			     $permissions,0640,$DB_RECNO) || return undef;
    tie(%index,DB_File,"$in.index",$permissions,0640,$DB_HASH) || return undef;

    $self->{'records'}=\@records;
    $self->{'index'}=\%index;
    1;
}

#########################################################################
# DELETE EVERYTHING FROM THE DATABASE
#########################################################################
sub empty {
    my $self = shift;
    my($base) = $self->{'basename'};
    &DESTROY($self);		# this closes the database and releases locks

    # delete the files
    foreach ('.data','.index') {
	unlink "$base$_";
    }
    
    # Now reopen things
    return _open_databases($self);
}

########################################################################
# DATA STORAGE
########################################################################
# This overrides the base object write_record.
# It writes the stone into the given position in the file.
# You can provide an index to put the record at a particular
# position, leave it undef to append the record to the end
# of the table, or provide a -1 to use the current record
# number of the stone to get the position.  Just for fun,
# we return the record number of the added object.
sub write_record {
    my($self,$stone,$index) = @_;
    unless ($self->{'writable'}) {
	warn "Attempt to write to read-only database $self->{'basename'}";
	return undef;
    }

    my ($nextrecord);

    if (defined($index) && $index == -1) {
	my $stonepos = $stone->get('record_no');
	$nextrecord = defined($stonepos) ? $stonepos : $self->length;
    } else {
	$nextrecord = (defined($index) && ($index >= 0) && ($index < $self->length))
	    ? $index : $self->length;
    }

    # We figure out here what indices need to be updated
    my %need_updating;		# indexes that need fixing
    if ($nextrecord != $self->length) {
	my $old = $self->get($nextrecord);
	if ($old) {
	    foreach ($self->indexed_keys) {
		my $oldvalue = join('',$old->index($_));
		my $newvalue = join('',$stone->index($_));
		$need_updating{$_}++ if $oldvalue ne $newvalue;
	    }
	}
	$self->unindex_record($nextrecord,keys %need_updating) if %need_updating;
    } else {
	grep($need_updating{$_}++,$self->indexed_keys);
    }

    # Write out the Stone record.
    $stone->replace('record_no',$nextrecord); # keep track of this please
    my ($key,$value,@value,@lines);

    foreach $key ($stone->tags) {
	@value = $stone->get($key);
	$key = $self->escapekey($key);
	foreach $value (@value) {
	    if (ref $value && defined $value->{'.name'}) {
		$value = $self->escapeval($value);
		push(@lines,"$key$self->{delim}$value");
	    } else {
		push(@lines,"$key$self->{delim}$self->{subrec_start}");
		push(@lines,_write_nested($self,1,$value));
	    }
	}
    }
    $self->{'records'}->[$nextrecord]=join("$self->{line_end}",@lines);
    $self->index_record($nextrecord,keys %need_updating) if %need_updating;

    $nextrecord;
}

# put() is an alias for write_record, except that it
# requires a record number.
sub put {
    my($self,$stone,$record_no) = @_;
    croak 'Usage: put($stone [,$record_no])' unless defined $stone;
    $record_no = $stone->get('record_no') unless defined($record_no);
    $self->write_record($stone,$record_no);
}

# Delete the record number from the database.  You may
# provide either a numeric recno, or the stone itself.
# The deleted stone is returned (sans its record no).
sub delete {
    my($self,$s) = @_;
    my $recno;
    if ( $s->isa('Stone') ) {
	$recno = $s->get('record_no');
    } else {
	$recno = $s;
    }
    $self->unindex_record($recno); # remove from the index
    $s = $self->get($recno) unless $s->isa('Stone');
    delete $s->{recno};		# record number is gonzo
    $self->{'dbrecno'}->del($recno);	# this does the actual delete
    $self->renumber_indices($recno);
    $self->renumber_records($recno);
    return $s;
}

########################################################################
# DATA RETRIEVAL
########################################################################
sub read_one_record {
    my($self,@keywords) = @_;

    return undef if $self->done;

    my(%interested,$key,$value);
    grep($interested{$_}++,@keywords);
    $interested{'record_no'}++;	# always interested in this one

    my $delim=$self->{'delim'};
    my $subrec_start=$self->{'subrec_start'};
    my $subrec_end=$self->{'subrec_end'};
    my ($stone,$pebble,$found);

    while (1) {
	
	undef $self->{LEVEL},last unless $_ = $self->next_pair;

	if (/$subrec_end$/o) {
	    $self->{LEVEL}--,last if $self->{LEVEL};
	    next;
	}

	next unless ($key,$value) = split($self->{delim},$_);
	$key = $self->unescapekey($key);
	$stone = new Stone() unless $stone;

	if ((!@keywords) || $interested{$key}) {

	    $found++;
	    if ($value =~ /$subrec_start/o) {
		$self->{LEVEL}++;
		$pebble = read_one_record($self); # call ourselves recursively
		$stone->insert($key=>$pebble);
		next;
	    }

	    $stone->insert($key=>$self->unescapeval($value));
	}
    }

    return undef unless $found;
    return $stone;
}

# Read_record has the semantics that if a query is active,
# it will only return stones that satisfy the query.
sub read_record {
    my($self,@tags) = @_;
    my $query = $self->{'query_test'};
    my $s;

    if (wantarray) {
	my(@result);
	while (!$self->done) {
	    $s = $self->read_one_record(@tags);
	    next unless $s;
	    next if $query && !($query->($s));
	    push(@result,$s);
	}
	return @result;
    } else {
	while (!$self->done) {
	    $s = $self->read_one_record(@tags);
	    next unless $s;
	    return $s unless $query;
	    return $s if $query->($s);
	}
	return undef;
    }
}

# Random access.  This will have the interesting side effect
# of causing read_record() to begin iterating from this record
# number.
sub get {
    my($self,$record,@tags) = @_;
    $self->{'nextrecord'} = $record if defined($record);
    undef $self->{'EOF'};
    return $self->read_record(@tags);
}

# Reset database so we start iterating over the entire
# database at record no 0 again.
sub reset {
    my $self = shift;
    $self->{'EOF'} = undef;
    $self->{'nextrecord'} = 0;
    $self->{'query_test'} = undef;
    $self->{'query_records'} = undef;
}

# Return the number of records in this file
sub length {
    my $self = shift;
    return $self->{'dbrecno'}->length;
}

# Return the number of unread query records
sub length_qrecs {
    my $self = shift;
    return $#{$self->{'query_records'}} + 1;
}

# Create a query.  read_record() will then
# iterate over the query results.  A query consists of
# an associative array of this form:
#    index1=>value1,
#    index2=>value2,
#    ...
#    indexN=>valueN,
#    'EVAL'=>[expression1,expression2,expression3...]
#    'EVAL'=>expression
#
# The index forms test for equality, and take advantage
# of any fast indexed keywords you've declared.  For
# example, this will identify all white males:
# $db->query('Demographics.Sex'=>'M',
#            'Demographics.Race'=>'white');
#
# The code form allows you to retrieve Stones satisfying
# any arbitrary snippets of Perl code.  Internally, the
# variable "$s" will be set to the current Stone.
# For example, find all whites > 30 years of age:
#
# $db->query('Demographics.Race'=>'white',
#            'EVAL'=>'$s->index(Age) > 30');
#
# EVAL (and "eval" too) expressions are ANDed together 
# in the order you declare them.  Internally indexed 
# keywords are evaluated first in order to speed things up.

# A cute feature that may go away:
#   You can use the expression <path.to.index> as shorthand
#   for $s->index('path.to.index')
sub query {
    my($self,%query) = @_;
    my($type,@expressions,%keylookups);

    foreach $type (keys %query) {
	if ($type =~ /^EVAL$/i) {
	    push (@expressions,$query{$type}) unless ref $query{$type};
	    push (@expressions,@{$query{$type}}) if ref $query{$type};
	} else {
	    $keylookups{$type} = $query{$type};
	}
    }

    # All the eval expressions are turned into a piece
    # of perl code.
    my $perlcode;
    foreach (@expressions) {
	s/<([\w.]+)>/\$s->index('$1')/g;
	$_ = "($_)";
    }

    my %fast;
    grep($fast{$_}++,$self->indexed_keys);
    my %fastrecs;
    my $fastset;	# this flag keeps track of the first access to %fastrecs

    foreach (keys %keylookups) {

	if ($fast{$_}) {
	    my (@records) = $self->lookup($_,$keylookups{$_});
	    if ($fastset) {
		my %tmp;
		grep($fastrecs{$_} && $tmp{$_}++,@records);
		%fastrecs = %tmp;
	    } else {
		grep($fastrecs{$_}++,@records);
		$fastset++;
	    }

	} else {		# slow record-by-record search
	    unshift(@expressions,"(\$s->index('$_') eq '$keylookups{$_}')");
	}

    }
    $perlcode = 'sub { my $s = shift;' . join(' && ',@expressions) . ';}' if @expressions;
    $perlcode = 'sub {1;}' unless @expressions;
    
    # The next step either looks up a compiled query or
    # creates one.  We use a package global for this
    # purpose, since the same query may be used for
    # different databases.
    my $coderef;
    unless ($coderef = $QUERIES{$perlcode}) {
	$coderef = $QUERIES{$perlcode} = eval $perlcode;
	return undef if $@;
    }

    $self->reset;		# clear out old information
    $self->{'query_test'} = $coderef; # set us to check each record against the code
    $self->{'query_records'} = [keys %fastrecs] if $fastset;
    return 1;
}

# fetch() allows you to pass a query to the
# database, and get out all the stones that hit.
# Internally it is just a call to query() followed
# by an array-context call to read_record
sub fetch {
    my($self,%query) = @_;
    $self->query(%query);
    my(@result) = $self->read_record();	# call in array context
    return @result;
}

#--------------------------------------
# Internal (private) procedures.
#--------------------------------------
sub _write_nested {
    my($self,$level,$stone) = @_;

    my($key,$value,@value,@lines);

    foreach $key ($stone->tags) {
	@value = $stone->get($key);
	$key = $self->escapekey($key);
	foreach $value (@value) {
	    if (ref $value && defined $value->{'.name'}) {
		$value = $self->escapeval($value);
		push(@lines,"$key$self->{delim}$value");
	    } else {
		push(@lines,"$key$self->{delim}$self->{subrec_start}");
		push(@lines,_write_nested($self,$level+1,$value));
	    }
	}
    }

    push(@lines,$self->{'subrec_end'});
    return @lines;
}

# This finds an array of key/value pairs and
# stashes it where we can find it.
# This is overriden from the basic Boulder::Stream class,
# and relies on the state variable 'nextrecord' to tell
# it where to start reading from.
sub read_next_rec {
    my($self) = @_;
    my $data;

    # two modes of retrieval:
    # 1. regular iterate through the entire database
    # 2. iterate through subset of records in 'query_records'
    unless ($self->{'query_records'}) {
	return !($self->{EOF}++) if $self->length <= $self->{'nextrecord'};
	$data = $self->{'records'}->[$self->{'nextrecord'}];
	$self->{'nextrecord'}++;
    } else {
	my $nextrecord = shift @{$self->{'query_records'}};
	return !($self->{EOF}++) unless $nextrecord ne '';
	$data = $self->{'records'}->[$nextrecord];
    }

    # unpack the guy into pairs
    $self->{PAIRS}=[split($self->{'line_end'},$data)];
}

 # This fiddles 'nextrecord' or 'query_records', as appropriate, so that
 # the next call to read_next_rec will skip over $skip records.
sub skip_recs {
    my($self,$skip) = @_;
    unless ($self->{'query_records'}) {
	$self->{'nextrecord'} += $skip;
    } else {
	splice(@{$self->{'query_records'}}, 0, $skip);
    }
}

# Index a stone record
sub index_record { 
    my ($self,$recno,@indices) = @_;

    my $s = $self->get($recno);
    return undef unless defined($s);

    my($index,@values,$value);
    @indices = $self->indexed_keys unless @indices;
    foreach $index (@indices) {
	@values = $s->index($index);
	foreach $value (@values) {
	    my %current;
	    grep($current{$_}++,split(" ",$self->{'index'}->{"$index:$value"}));
	    $current{$recno}++; # add us to the list
	    $self->{'index'}->{"$index:$value"} = join(" ",keys %current);
	}
    }
    1;
}

# This is a NOP for now.
sub unindex_record { 
    my ($self,$recno,@indices) = @_;

    my $s = $self->get($recno);
    return undef unless defined($s);

    my($index,@values,$value);
    @indices = $self->indexed_keys unless @indices;

    foreach $index (@indices) {
	@values = $s->index($index);
	foreach $value (@values) {
	    my %current;
	    grep($current{$_}++,split(" ",$self->{'index'}->{"$index:$value"}));
	    delete $current{$recno}; # remove us from the list
	    $self->{'index'}->{"$index:$value"} = join(" ",keys %current); # put index back
	}
    }
    1;
};

# This gets called after a record delete, when all the indexes need to be
# shifted downwards -- this is probably WAY slow.
sub renumber_indices {
    my ($self,$deleted_recno) = @_;
    while (($key,$value) = each %{$self->{'index'}}) {
	next if $key =~/^\./;
	@values = split(" ",$value);
	foreach (@values) {
	    $_-- if $_ > $deleted_recno;
	}
	# This will probably put us into an infinite loop!
	$self->{'index'}->{$key} = join(" ",@values);
    }
}

# This also gets called after a record delete, when all the indexes need to be
# shifted downwards -- this is probably WAY slow.
sub renumber_records {
    my ($self,$deleted_recno) = @_;
    $self->reset;
    $recno = -1;
    while ($s=$self->read_record) {
	$recno++;
	next unless $s->get('record_no') > $deleted_recno;
	$s->replace('record_no',$recno);
	$self->put($s);
    }
}

# Look up a stone record using its index.  Will return a list
# of the matching records
sub lookup {
    my ($self,$index,$value) = @_;
    my %records;
    grep($records{$_}++,split(" ",$self->{'index'}->{"$index:$value"}));
    return keys %records;
}

# Add an index (or list of indices) to the database.
# If new, then we do a reindexing.
sub add_index {
    my ($self,@indices) = @_;
    my (%oldindices);
    grep($oldindices{$_}++,$self->indexed_keys);
    my (@newindices) = grep(!$oldindices{$_},@indices);
    $self->reindex_some_keys(@newindices);
    $self->{'index'}->{'.INDICES'}=join($self->{'index_delim'},keys %oldindices,@newindices);
}

# Return the indexed keys as an associative array (convenient)
sub indexed_keys {
    my $self = shift;
    return split($self->{'index_delim'},$self->{'index'}->{'.INDICES'});
}

# Reindex all records that contain records involving the provided indices.
sub reindex_some_keys {
    my($self,@new) = @_;
    my ($s,$index,$value);
    $self->reset;		# reset to beginning of database

    while ($s=$self->read_record) { # return all the stones
	foreach $index (@new) {
	    foreach $value ($s->index($index)){ # pull out all the values at this index (if any)
		my %current;
		grep($current{$_}++,split(" ",$self->{'index'}->{"$index:$value"}));
		$current{$s->get('record_no')}++;
		$self->{'index'}->{"$index:$value"}=join(" ",keys %current);
	    }
	}
    }

}

# Completely rebuild the index.
sub reindex_all {
    my $self = shift;
    my ($index,$s,@values,$value);
    $self->reset;
    foreach $index ($self->indexed_keys) {
	undef %records;
	while ($s=$self->read_record) { # return all the stones
	    foreach $value ($s->index($index)){ # pull out all the values at this index (if any)
		    $records{"$index:$value"}->{$s->get('record_no')}++;
		}
	}
	foreach (keys %records) {
	    $self->{'index'}->{$_}=join(" ",keys %{$records{$_}});
	}
    }
}


1;
