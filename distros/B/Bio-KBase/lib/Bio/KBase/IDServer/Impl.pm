package Bio::KBase::IDServer::Impl;
use strict;

=head1 NAME

IDServerAPI

=head1 DESCRIPTION

The KBase ID provides access to the mappings between KBase identifiers and
external identifiers, the original identifiers for data that was migrated from
other databases into the KBase.

=cut

#BEGIN_HEADER

use Try::Tiny;
use Config::Simple;
use Data::Dumper;
use MongoDB;
use strict;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(conn db coll_data coll_next));

sub _init_instance
{
    my($self) = @_;

    my $host;
    if (my $e = $ENV{KB_DEPLOYMENT_CONFIG})
    {
	my $service = $ENV{KB_SERVICE_NAME};
	my $c = Config::Simple->new();
	$c->read($e);
	$host = $c->param("$service.mongodb-host");
    }

    if (!$host)
    {
	$host = "mongodb.kbase.us";
	warn "No deployment configuration found; falling back to $host";
    }

    my $conn;

    try {
	$conn = MongoDB::Connection->new(host => $host);
    } catch {
	die "Error connecting to MongoDB server on $host: $_";
    };

    my $db = $conn->idserver_db;
    my $coll_data = $db->data;
    my $coll_next = $db->next;
    $self->conn($conn);
    $self->db($db);
    $self->coll_data($coll_data);
    $self->coll_next($coll_next);

    $coll_data->ensure_index({ext_name => 1, ext_id => 1});
    $coll_data->ensure_index({kb_id => 1});
    $coll_next->ensure_index({prefix => 1});
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 kbase_ids_to_external_ids

  $return = $obj->kbase_ids_to_external_ids($ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a kbase_id
$return is a reference to a hash where the key is a kbase_id and the value is a reference to a list containing 2 items:
	0: an external_db
	1: an external_id
kbase_id is a string
external_db is a string
external_id is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a kbase_id
$return is a reference to a hash where the key is a kbase_id and the value is a reference to a list containing 2 items:
	0: an external_db
	1: an external_id
kbase_id is a string
external_db is a string
external_id is a string


=end text



=item Description

Given a set of KBase identifiers, look up the associated external identifiers.
If no external ID is associated with the KBase id, no entry will be present in the return.

=back

=cut

sub kbase_ids_to_external_ids
{
    my($self, $ids) = @_;
    my $ctx = $Bio::KBase::IDServer::Service::CallContext;
    my($return);
    #BEGIN kbase_ids_to_external_ids
            
    my $iter = $self->coll_data->find({ kb_id => { '$in' => $ids }});
    $return = {};

    while (my $ent = $iter->next)
    {
	$return->{$ent->{kb_id}} = [ $ent->{ext_name}, $ent->{ext_id} ] ;
    }
    
    #END kbase_ids_to_external_ids
    return($return);
}




=head2 external_ids_to_kbase_ids

  $return = $obj->external_ids_to_kbase_ids($external_db, $ext_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$external_db is an external_db
$ext_ids is a reference to a list where each element is an external_id
$return is a reference to a hash where the key is an external_id and the value is a kbase_id
external_db is a string
external_id is a string
kbase_id is a string

</pre>

=end html

=begin text

$external_db is an external_db
$ext_ids is a reference to a list where each element is an external_id
$return is a reference to a hash where the key is an external_id and the value is a kbase_id
external_db is a string
external_id is a string
kbase_id is a string


=end text



=item Description

Given a set of external identifiers, look up the associated KBase identifiers.
If no KBase ID is associated with the external id, no entry will be present in the return.

=back

=cut

sub external_ids_to_kbase_ids
{
    my($self, $external_db, $ext_ids) = @_;
    my $ctx = $Bio::KBase::IDServer::Service::CallContext;
    my($return);
    #BEGIN external_ids_to_kbase_ids
            
my $n = @$ext_ids;
print STDERR "$$ start find on $n\n";
    my $iter = $self->coll_data->find({ ext_name => $external_db, ext_id => { '$in' => $ext_ids }});
    $return = {};

    while (my $ent = $iter->next)
    {
	$return->{$ent->{ext_id}} = $ent->{kb_id};
    }
print STDERR "$$ finish find on $n\n";

    #END external_ids_to_kbase_ids
    return($return);
}




=head2 register_ids

  $return = $obj->register_ids($prefix, $db_name, $ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$prefix is a kbase_id_prefix
$db_name is an external_db
$ids is a reference to a list where each element is an external_id
$return is a reference to a hash where the key is an external_id and the value is a kbase_id
kbase_id_prefix is a string
external_db is a string
external_id is a string
kbase_id is a string

</pre>

=end html

=begin text

$prefix is a kbase_id_prefix
$db_name is an external_db
$ids is a reference to a list where each element is an external_id
$return is a reference to a hash where the key is an external_id and the value is a kbase_id
kbase_id_prefix is a string
external_db is a string
external_id is a string
kbase_id is a string


=end text



=item Description

Register a set of identifiers. All will be assigned identifiers with the given
prefix.

If an external ID has already been registered, the existing registration will be returned instead 
of a new ID being allocated.

=back

=cut

sub register_ids
{
    my($self, $prefix, $db_name, $ids) = @_;
    my $ctx = $Bio::KBase::IDServer::Service::CallContext;
    my($return);
    #BEGIN register_ids

    #
    # Begin by looking up the identifiers in the existing data.
    #

    $return = {};

    my $iter = $self->coll_data->find({ ext_name => $db_name, ext_id => { '$in' => $ids }});

    my %to_allocate = map { $_ => 1 } @$ids;

    while (my $ent = $iter->next)
    {
	my $id = $ent->{ext_id};
	$return->{$id} = $ent->{kb_id};
	delete $to_allocate{$id};
    }

    print STDERR "After initial check " . Dumper(\%to_allocate, $return);
            
    #
    # Do an atomic MongoDB findAndModify to increment the next_val by
    # the number of IDs we're registering (or inserting a new record
    # if not already present).
    #

    # Maintain original ordering.
    my @to_allocate = grep { exists $to_allocate{$_} } @$ids;
    my $n_ids = @to_allocate;
    
    my $res = $self->db->run_command({
	findAndModify => "next",
	query => { prefix => $prefix },
	update => { '$inc' => { next_val => $n_ids } },
	upsert => 1
	});

    if (!ref($res))
    {
	die "MongoDB error: $res";
    }
    
    if (!$res->{ok})
    {
	die "MongoDB error $res->{err}";
    }

    print Dumper($res);
    
    my $start = $res->{value}->{next_val};

    my @vals;

    my $suffix = $start;
    for my $id (@to_allocate)
    {
	my $kid = join(".", $prefix, $suffix++);
	$return->{$id} = $kid;
	push @vals, { ext_name => $db_name, ext_id => $id, kb_id => $kid};
    }

    $self->coll_data->batch_insert(\@vals) if (@vals);

    #END register_ids
    return($return);
}




=head2 allocate_id_range

  $starting_value = $obj->allocate_id_range($kbase_id_prefix, $count)

=over 4

=item Parameter and return types

=begin html

<pre>
$kbase_id_prefix is a kbase_id_prefix
$count is an int
$starting_value is an int
kbase_id_prefix is a string

</pre>

=end html

=begin text

$kbase_id_prefix is a kbase_id_prefix
$count is an int
$starting_value is an int
kbase_id_prefix is a string


=end text



=item Description

Allocate a set of identifiers. This allows efficient registration of a large
number of identifiers (e.g. several thousand features in a genome).

The return is the first identifier allocated.

=back

=cut

sub allocate_id_range
{
    my($self, $kbase_id_prefix, $count) = @_;
    my $ctx = $Bio::KBase::IDServer::Service::CallContext;
    my($starting_value);
    #BEGIN allocate_id_range
            
    my $res = $self->db->run_command({
	findAndModify => "next",
	query => { prefix => $kbase_id_prefix },
	update => { '$inc' => { next_val => $count } },
	upsert => 1
	});

    if (!ref($res))
    {
	die "MongoDB error: $res";
    }
    
    if (!$res->{ok})
    {
	die "MongoDB error $res->{err}";
    }

    $starting_value = $res->{value}->{next_val};

    #END allocate_id_range
    return($starting_value);
}




=head2 register_allocated_ids

  $obj->register_allocated_ids($prefix, $db_name, $assignments)

=over 4

=item Parameter and return types

=begin html

<pre>
$prefix is a kbase_id_prefix
$db_name is an external_db
$assignments is a reference to a hash where the key is an external_id and the value is an int
kbase_id_prefix is a string
external_db is a string
external_id is a string

</pre>

=end html

=begin text

$prefix is a kbase_id_prefix
$db_name is an external_db
$assignments is a reference to a hash where the key is an external_id and the value is an int
kbase_id_prefix is a string
external_db is a string
external_id is a string


=end text



=item Description

Register the mappings for a set of external identifiers. The
KBase identifiers used here were previously allocated using allocate_id_range.

Does not return a value.

=back

=cut

sub register_allocated_ids
{
    my($self, $prefix, $db_name, $assignments) = @_;
    my $ctx = $Bio::KBase::IDServer::Service::CallContext;
    #BEGIN register_allocated_ids
            
    my @vals;

    while (my($ext_id, $suffix) = each %$assignments)
    {
	my $kid = join(".", $prefix, $suffix);
	push @vals, { ext_name => $db_name, ext_id => $ext_id, kb_id => $kid};
    }

    $self->coll_data->batch_insert(\@vals) if @vals;

    #END register_allocated_ids
    return();
}




=head1 TYPES



=head2 kbase_id

=over 4



=item Description

A KBase ID is string starting with the characters "kb|".

KBase IDs are typed. The types are designated using a short string. For instance,
"g" denotes a genome, "fp" denotes a feature representing a protein-encoding gene, etc.

KBase IDs may be hierarchical. If a KBase genome identifier is "kb|g.1234", a protein
within that genome may be represented as "kb|g.1234.fp.771".


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 external_db

=over 4



=item Description

Each external database is represented using a short string. Microbes Online is "MOL",
the SEED is "SEED", etc.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 external_id

=over 4



=item Description

External database identifiers are strings. They are the precise identifier used
by that database. It is important to note that if a database uses the same 
identifier space for more than one data type (for instance, if integers are used for
identifying both genomes and genes, and if the same number is valid for both a
genome and a gene) then the distinction must be made by using separate exgternal database
strings for the different types; e.g. DBNAME-GENE and DBNAME-GENOME for a 
database DBNAME that has overlapping namespace for genes and genomes).


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 kbase_id_prefix

=over 4



=item Description

A KBase identifier prefix. This is a string that starts with "kb|" and includes either a
single type designator (e.g. "kb|g") or is a prefix for a hierarchical identifier (e.g.
"kb|g.1234.fp").


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=cut

1;
