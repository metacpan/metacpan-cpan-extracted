package Bio::KBase::GenomeAnnotation::GenomeAnnotationImpl;
use strict;
use Bio::KBase::Exceptions;

=head1 NAME

GenomeAnnotation

=head1 DESCRIPTION



=cut

#BEGIN_HEADER

use ANNOserver;
use Digest::MD5 'md5_hex';
use SeedUtils;
use Bio::KBase::IDServer::Client;
use Data::Dumper;
use gjoseqlib;

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



=head2 genomeTO_to_reconstructionTO

  $return = $obj->genomeTO_to_reconstructionTO($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a reconstructionTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int
reconstructionTO is a reference to a hash where the following keys are defined:
	subsystems has a value which is a variant_subsystem_pairs
	bindings has a value which is a fid_role_pairs
	assignments has a value which is a fid_function_pairs
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string
fid_role_pairs is a reference to a list where each element is a fid_role_pair
fid_role_pair is a reference to a list containing 2 items:
	0: a fid
	1: a role
fid is a string
role is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
function is a string

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a reconstructionTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int
reconstructionTO is a reference to a hash where the following keys are defined:
	subsystems has a value which is a variant_subsystem_pairs
	bindings has a value which is a fid_role_pairs
	assignments has a value which is a fid_function_pairs
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string
fid_role_pairs is a reference to a list where each element is a fid_role_pair
fid_role_pair is a reference to a list containing 2 items:
	0: a fid
	1: a role
fid is a string
role is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
function is a string


=end text



=item Description



=back

=cut

sub genomeTO_to_reconstructionTO
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomeTO_to_reconstructionTO:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomeTO_to_reconstructionTO');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN genomeTO_to_reconstructionTO

    use ANNOserver;
    my $annoO = ANNOserver->new;
    my %in_models = map { chop; ($_ => 1) } `all_roles_used_in_models`;
    my %bindings_to_roles;

    my $features = $genomeTO->{features};
    my @role_fid_tuples;
    my $assignments = [];
    foreach my $fidH (@$features)
    {
	my $fid = $fidH->{id};
	my $f = $fidH->{function};
	if ($f)
	{
	    
	    push(@$assignments,[$fid,$f]);
	    foreach my $role (&SeedUtils::roles_of_function($f))
	    {
		push(@role_fid_tuples,[$role,$fid]);
		if ($in_models{$role}) { $bindings_to_roles{$role}->{$fid} = 1 }
	    }
	}
    }
    my $mr = $annoO->metabolic_reconstruction({-roles => \@role_fid_tuples});
    my $sub_vars = [];
    my $bindings = [];
    my %subsys;
    foreach my $tuple (@$mr)
    {
	my($sub_var,$role,$fid) = @$tuple;
	my($sub,$var) = split(/:/,$sub_var);
	if ($var !~ /\*?(0|-1)\b/)
	{
	    $subsys{$sub} = $var;
	    $bindings_to_roles{$role}->{$fid} = 1;
	}
    }
    foreach my $role (keys(%bindings_to_roles))
    {
	my $roles = $bindings_to_roles{$role};
	my @fids = keys(%$roles);
	foreach my $fid (@fids)
	{
	    push(@$bindings,[$fid,$role]);
	}
    }
    my @sv = map { [$_,$subsys{$_}] } keys(%subsys);
    $return = {
	subsystems => \@sv,
	assignments => $assignments,
	bindings   => $bindings,
    };
    
    #END genomeTO_to_reconstructionTO
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomeTO_to_reconstructionTO:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomeTO_to_reconstructionTO');
    }
    return($return);
}




=head2 genomeTO_to_feature_data

  $return = $obj->genomeTO_to_feature_data($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a fid_data_tuples
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int
fid_data_tuples is a reference to a list where each element is a fid_data_tuple
fid_data_tuple is a reference to a list containing 4 items:
	0: a fid
	1: a md5
	2: a location
	3: a function
fid is a string
md5 is a string
function is a string

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a fid_data_tuples
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int
fid_data_tuples is a reference to a list where each element is a fid_data_tuple
fid_data_tuple is a reference to a list containing 4 items:
	0: a fid
	1: a md5
	2: a location
	3: a function
fid is a string
md5 is a string
function is a string


=end text



=item Description



=back

=cut

sub genomeTO_to_feature_data
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genomeTO_to_feature_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomeTO_to_feature_data');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN genomeTO_to_feature_data

    my $feature_data = [];
    my $features = $genomeTO->{features};
    foreach my $feature (@$features)
    {
	my $fid = $feature->{id};
	my $loc = join(",",map { my($contig,$beg,$strand,$len) = @$_; 
				 "$contig\_$beg$strand$len" 
			       } @{$feature->{location}});
	my $type = $feature->{type};
	my $func = $feature->{function};
	my $md5 = "";
	$md5 = md5_hex(uc($feature->{protein_translation})) if $feature->{protein_translation};
	my $aliases = join(",",@{$feature->{aliases}});
	push(@$feature_data,[$fid,$loc,$type,$func,$aliases,$md5]);
    }
    $return = $feature_data;
    #END genomeTO_to_feature_data
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genomeTO_to_feature_data:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genomeTO_to_feature_data');
    }
    return($return);
}




=head2 reconstructionTO_to_roles

  $return = $obj->reconstructionTO_to_roles($reconstructionTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$reconstructionTO is a reconstructionTO
$return is a reference to a list where each element is a role
reconstructionTO is a reference to a hash where the following keys are defined:
	subsystems has a value which is a variant_subsystem_pairs
	bindings has a value which is a fid_role_pairs
	assignments has a value which is a fid_function_pairs
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string
fid_role_pairs is a reference to a list where each element is a fid_role_pair
fid_role_pair is a reference to a list containing 2 items:
	0: a fid
	1: a role
fid is a string
role is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
function is a string

</pre>

=end html

=begin text

$reconstructionTO is a reconstructionTO
$return is a reference to a list where each element is a role
reconstructionTO is a reference to a hash where the following keys are defined:
	subsystems has a value which is a variant_subsystem_pairs
	bindings has a value which is a fid_role_pairs
	assignments has a value which is a fid_function_pairs
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string
fid_role_pairs is a reference to a list where each element is a fid_role_pair
fid_role_pair is a reference to a list containing 2 items:
	0: a fid
	1: a role
fid is a string
role is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
function is a string


=end text



=item Description



=back

=cut

sub reconstructionTO_to_roles
{
    my $self = shift;
    my($reconstructionTO) = @_;

    my @_bad_arguments;
    (ref($reconstructionTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"reconstructionTO\" (value was \"$reconstructionTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to reconstructionTO_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reconstructionTO_to_roles');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN reconstructionTO_to_roles

    my $bindings = $reconstructionTO->{bindings};
    my %roles = map { ($_->[1] => 1) } @$bindings;
    $return = [sort keys(%roles)];

    #END reconstructionTO_to_roles
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to reconstructionTO_to_roles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reconstructionTO_to_roles');
    }
    return($return);
}




=head2 reconstructionTO_to_subsystems

  $return = $obj->reconstructionTO_to_subsystems($reconstructionTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$reconstructionTO is a reconstructionTO
$return is a variant_subsystem_pairs
reconstructionTO is a reference to a hash where the following keys are defined:
	subsystems has a value which is a variant_subsystem_pairs
	bindings has a value which is a fid_role_pairs
	assignments has a value which is a fid_function_pairs
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string
fid_role_pairs is a reference to a list where each element is a fid_role_pair
fid_role_pair is a reference to a list containing 2 items:
	0: a fid
	1: a role
fid is a string
role is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
function is a string

</pre>

=end html

=begin text

$reconstructionTO is a reconstructionTO
$return is a variant_subsystem_pairs
reconstructionTO is a reference to a hash where the following keys are defined:
	subsystems has a value which is a variant_subsystem_pairs
	bindings has a value which is a fid_role_pairs
	assignments has a value which is a fid_function_pairs
variant_subsystem_pairs is a reference to a list where each element is a variant_of_subsystem
variant_of_subsystem is a reference to a list containing 2 items:
	0: a subsystem
	1: a variant
subsystem is a string
variant is a string
fid_role_pairs is a reference to a list where each element is a fid_role_pair
fid_role_pair is a reference to a list containing 2 items:
	0: a fid
	1: a role
fid is a string
role is a string
fid_function_pairs is a reference to a list where each element is a fid_function_pair
fid_function_pair is a reference to a list containing 2 items:
	0: a fid
	1: a function
function is a string


=end text



=item Description



=back

=cut

sub reconstructionTO_to_subsystems
{
    my $self = shift;
    my($reconstructionTO) = @_;

    my @_bad_arguments;
    (ref($reconstructionTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"reconstructionTO\" (value was \"$reconstructionTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to reconstructionTO_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reconstructionTO_to_subsystems');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN reconstructionTO_to_subsystems

    my $subsys_pairs = $reconstructionTO->{subsystems};
    $return = $subsys_pairs;
    
    #END reconstructionTO_to_subsystems
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to reconstructionTO_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'reconstructionTO_to_subsystems');
    }
    return($return);
}




=head2 annotate_genome

  $return = $obj->annotate_genome($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description

Given a genome object populated with contig data, perform gene calling
and functional annotation and return the annotated genome.
 NOTE: Many of these "transformations" modify the input hash and
       copy the pointer.  Be warned.

=back

=cut

sub annotate_genome
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to annotate_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_genome');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN annotate_genome
    my $genome = $genomeTO;
    my $anno = ANNOserver->new();

    #
    # Reformat the contigs for use with the ANNOserver.
    #
    my @contigs;
    foreach my $gctg (@{$genome->{contigs}})
    {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }

    #
    # Call genes.
    #
    print STDERR "Call genes...\n";
    my $peg_calls = $anno->call_genes(-input => \@contigs, -geneticCode => $genome->{genetic_code});
    print STDERR "Call genes...done\n";


    #
    # Call RNAs
    #
    my($genus, $species, $strain) = split(/\s+/, $genome->{scientific_name}, 3);
    print STDERR "Call rnas '$genus' '$species' '$strain' '$genome->{domain}'...\n";
    my $rna_calls = $anno->find_rnas(-input => \@contigs, -genus => $genus, -species => $species,
				     -domain => $genome->{domain});
    print STDERR "Call rnas...done\n";

    my($fasta_rna, $rna_locations) = @$rna_calls;

    my %feature_loc;
    my %feature_func;
    my %feature_anno;
    
    for my $ent (@$rna_locations)
    {
	my($loc_id, $contig, $start, $stop, $func) = @$ent;
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	$feature_loc{$loc_id} = [$contig, $start, $strand, $len];
	$feature_func{$loc_id} = $func if $func;
    }

    my($fasta_proteins, $protein_locations) = @$peg_calls;

    my $features = $genome->{features};
    if (!$features)
    {
	$features = [];
	$genome->{features} = $features;
    }

    #
    # Assign functions for proteins.
    #

    my $prot_fh;
    open($prot_fh, "<", \$fasta_proteins) or die "Cannot open the fasta string as a filehandle: $!";
    my $handle = $anno->assign_function_to_prot(-input => $prot_fh,
						-kmer => 8,
						-scoreThreshold => 3,
						-seqHitThreshold => 3);
    while (my $res = $handle->get_next())
    {
	my($id, $function, $otu, $score, $nonoverlap_hits, $overlap_hits, $details, $fam) = @$res;
	$feature_func{$id} = $function;
	$feature_anno{$id} = "Set function to\n$function\nby assign_function_to_prot with otu=$otu score=$score nonoverlap=$nonoverlap_hits hits=$overlap_hits figfam=$fam";
    }
    close($prot_fh);
    
    for my $ent (@$protein_locations)
    {
	my($loc_id, $contig, $start, $stop) = @$ent;
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	$feature_loc{$loc_id} = [$contig, $start, $strand, $len];
    }

    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');

    #
    # Create features for PEGs
    #
    my $n_pegs = @$protein_locations;
    my $protein_prefix = "$genome->{id}.peg";
    my $peg_id_start = $id_server->allocate_id_range($protein_prefix, $n_pegs) + 0;
    print STDERR "allocated peg id start $peg_id_start for $n_pegs pegs\n";

    open($prot_fh, "<", \$fasta_proteins) or die "Cannot open the fasta string as a filehandle: $!";
    my $next_id = $peg_id_start;
    while (my($id, $def, $seq) = read_next_fasta_seq($prot_fh))
    {
	my $loc = $feature_loc{$id};
	my $kb_id = "$protein_prefix.$next_id";
	$next_id++;
	my $annos = [];
	push(@$annos, ['Initial gene call performed by call_genes',
		       'genome annotation service',
		       time
		       ]);
	if ($feature_anno{$id})
	{
	    push(@$annos, [$feature_anno{$id}, 'genome annotation service', time]);
	}
	my $feature = {
	    id => $kb_id,
	    location => [$loc],
	    type => 'peg',
	    protein_translation => $seq,
	    aliases => [],
	    $feature_func{$id} ? (function => $feature_func{$id}) : (),
	    annotations => $annos,
	};
	push(@$features, $feature);
    }
    close($prot_fh);

    #
    # Create features for RNAs
    #
    my $n_rnas = @$rna_locations;
    my $rna_prefix = "$genome->{id}.rna";
    my $rna_id_start = $id_server->allocate_id_range($rna_prefix, $n_rnas) + 0;
    print STDERR "allocated id start $rna_id_start for $n_rnas nras\n";

    my $rna_fh;
    open($rna_fh, "<", \$fasta_rna) or die "Cannot open the fasta string as a filehandle: $!";
    $next_id = $rna_id_start;
    while (my($id, $def, $seq) = read_next_fasta_seq($rna_fh))
    {
	my $loc = $feature_loc{$id};
	my $kb_id = "$rna_prefix.$next_id";
	$next_id++;
	my $feature = {
	    id => $kb_id,
	    location => [$loc],
	    type => 'rna',
	    $feature_func{$id} ? (function => $feature_func{$id}) : (),
	    aliases => [],
	    annotations => [ ['Initial RNA call performed by find_rnas', 'genome annotation service', time] ],
	};
	push(@$features, $feature);
    }

    $return = $genome;
    
    #END annotate_genome
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to annotate_genome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_genome');
    }
    return($return);
}




=head2 call_selenoproteins

  $return = $obj->call_selenoproteins($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub call_selenoproteins
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_selenoproteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_selenoproteins');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN call_selenoproteins
    
    #
    #...Find the selenoproteins...
    #
    use find_special_proteins;
    
    # Reformat the contigs into "Gary-tuples"
    my @contigs;
    foreach my $gctg (@{$genomeTO->{contigs}}) {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }
    
    my $parms   = { contigs => \@contigs };
    my @results = &find_special_proteins::find_selenoproteins( $parms );
    
    #
    # Allocate IDs for PEGs
    #
    my $n_pegs = @results;
    my $protein_prefix = "$genomeTO->{id}.peg";
    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');
    my $peg_id_start = $id_server->allocate_id_range($protein_prefix, $n_pegs) + 0;
    my $next_id = $peg_id_start;
    print STDERR "allocated peg id start $peg_id_start for $n_pegs pegs\n";
    
    #
    # Create features for PEGs
    #
    my $features = $genomeTO->{features};
    if (!$features)
    {
	$features = [];
	$genomeTO->{features} = $features;
    }
    
    # Reformat result from &find_special_proteins::find_selenoproteins().
    foreach my $feature (@results) {
	my $loc  = $feature->{location};
	my $seq  = $feature->{sequence};
	my $func = $feature->{reference_def};
	
	my ($contig, $start, $stop, $strand) = &SeedUtils::parse_location( $feature->{location} );
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	
	my $kb_id = "$protein_prefix.$next_id";
	++$next_id;
	
	my $annos = [];
	push(@$annos, ["Set function to\n$func\nfor initial gene call performed by call_selenoproteins",
		       'genome annotation service',
		       time
		       ]);
	
	my $feature = {
	    id => $kb_id,
	    location => [[ $contig, $start, $strand, $len ]],
	    type => 'peg',
	    protein_translation => $seq,
	    aliases => [],
	    $func ? (function => $func) : (),
	    annotations => $annos,
	};
	push(@$features, $feature);
    }
    $return = $genomeTO;

    #END call_selenoproteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_selenoproteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_selenoproteins');
    }
    return($return);
}




=head2 call_pyrrolysoproteins

  $return = $obj->call_pyrrolysoproteins($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub call_pyrrolysoproteins
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_pyrrolysoproteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_pyrrolysoproteins');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN call_pyrrolysoproteins
    
    #
    #...Find the pyrrolysoproteins...
    #
    use find_special_proteins;
    
    # Reformat the contigs into "Gary-tuples"
    my @contigs;
    foreach my $gctg (@{$genomeTO->{contigs}}) {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }
    
    #...Only difference from 'call_selenoproteins' is 'pyrrolysine' flag, and annotations written
    my $parms   = { contigs => \@contigs, pyrrolysine => 1 };
    my @results = &find_special_proteins::find_selenoproteins( $parms );
    
    #
    # Allocate IDs for PEGs
    #
    my $n_pegs = @results;
    my $protein_prefix = "$genomeTO->{id}.peg";
    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');
    my $peg_id_start = $id_server->allocate_id_range($protein_prefix, $n_pegs) + 0;
    my $next_id = $peg_id_start;
    print STDERR "allocated peg id start $peg_id_start for $n_pegs pegs\n";
    
    #
    # Create features for PEGs
    #
    my $features = $genomeTO->{features};
    if (!$features)
    {
	$features = [];
	$genomeTO->{features} = $features;
    }
    
    # Reformat result from &find_special_proteins::find_selenoproteins({pyrrolysine => 1}).
    foreach my $feature (@results) {
	my $loc  = $feature->{location};
	my $seq  = $feature->{sequence};
	my $func = $feature->{reference_def};
	
	my ($contig, $start, $stop, $strand) = &SeedUtils::parse_location( $feature->{location} );
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	
	my $kb_id = "$protein_prefix.$next_id";
	++$next_id;
	
	my $annos = [];
	push(@$annos, ["Set function to\n$func\nfor initial gene call performed by call_pyrrolysoproteins",
		       'genome annotation service',
		       time
		       ]);
	
	my $feature = {
	    id => $kb_id,
	    location => [[ $contig, $start, $strand, $len ]],
	    type => 'peg',
	    protein_translation => $seq,
	    aliases => [],
	    $func ? (function => $func) : (),
	    annotations => $annos,
	};
	push(@$features, $feature);
    }
    $return = $genomeTO;

    #END call_pyrrolysoproteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_pyrrolysoproteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_pyrrolysoproteins');
    }
    return($return);
}




=head2 call_RNAs

  $return = $obj->call_RNAs($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub call_RNAs
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_RNAs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_RNAs');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN call_RNAs
    ##################################################
    use ANNOserver;
    my $anno = ANNOserver->new();
    #
    # Reformat the contigs for use with the ANNOserver.
    #
    my @contigs;
    foreach my $gctg (@{$genomeTO->{contigs}})
    {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }

    #
    # Call RNAs
    #
    my($genus, $species, $strain) = split(/\s+/, $genomeTO->{scientific_name}, 3);
    print STDERR "Call rnas '$genus' '$species' '$strain' '$genomeTO->{domain}'...\n";
    my $rna_calls = $anno->find_rnas(-input => \@contigs, -genus => $genus, -species => $species,
				     -domain => $genomeTO->{domain});
    print STDERR "Call rnas...done\n";
    my($fasta_rna, $rna_locations) = @$rna_calls;

    my %feature_loc;
    my %feature_func;
    my %feature_anno;
    
    for my $ent (@$rna_locations)
    {
	my($loc_id, $contig, $start, $stop, $func) = @$ent;
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	$feature_loc{$loc_id} = [$contig, $start, $strand, $len];
	$feature_func{$loc_id} = $func if $func;
    }
    my $features = $genomeTO->{features};
    if (!$features)
    {
	$features = [];
	$genomeTO->{features} = $features;
    }

    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');

    #
    # Create features for RNAs
    #
    my $n_rnas = @$rna_locations;
    my $rna_prefix = "$genomeTO->{id}.rna";
    my $rna_id_start = $id_server->allocate_id_range($rna_prefix, $n_rnas) + 0;
    print STDERR "allocated id start $rna_id_start for $n_rnas nras\n";

    my $rna_fh;
    open($rna_fh, "<", \$fasta_rna) or die "Cannot open the fasta string as a filehandle: $!";
    my $next_id = $rna_id_start;
    while (my($id, $def, $seq) = read_next_fasta_seq($rna_fh))
    {
	my $loc = $feature_loc{$id};
	my $kb_id = "$rna_prefix.$next_id";
	$next_id++;
	my $feature = {
	    id => $kb_id,
	    location => [$loc],
	    type => 'rna',
	    $feature_func{$id} ? (function => $feature_func{$id}) : (),
	    aliases => [],
	    annotations => [ ['Initial RNA call performed by find_rnas', 'genome annotation service', time] ],
	};
	push(@$features, $feature);
    }
    $return = $genomeTO;

    #END call_RNAs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_RNAs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_RNAs');
    }
    return($return);
}




=head2 call_CDSs

  $return = $obj->call_CDSs($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub call_CDSs
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_CDSs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_CDSs');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN call_CDSs
    my $genome = $genomeTO;
    my $anno = ANNOserver->new();

    #
    # Reformat the contigs for use with the ANNOserver.
    #
    my @contigs;
    foreach my $gctg (@{$genome->{contigs}})
    {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }

    #
    # Call genes.
    #
    print STDERR "Call genes...\n";
    my $peg_calls = $anno->call_genes(-input => \@contigs, -geneticCode => $genome->{genetic_code});
    print STDERR "Call genes...done\n";
    my($fasta_proteins, $protein_locations) = @$peg_calls;
    
    my %feature_loc;
    my %feature_func;
    my %feature_anno;
    my $features = $genome->{features};
    if (!$features)
    {
	$features = [];
	$genome->{features} = $features;
    }

    #
    # Assign functions for proteins.
    #
    my $prot_fh;
    open($prot_fh, "<", \$fasta_proteins) or die "Cannot open the fasta string as a filehandle: $!";
    my $handle = $anno->assign_function_to_prot(-input => $prot_fh,
						-kmer => 8,
						-scoreThreshold => 3,
						-seqHitThreshold => 3);
    while (my $res = $handle->get_next())
    {
	my($id, $function, $otu, $score, $nonoverlap_hits, $overlap_hits, $details, $fam) = @$res;
	$feature_func{$id} = $function;
	$feature_anno{$id} = "Set function to\n$function\nby assign_function_to_prot with otu=$otu score=$score nonoverlap=$nonoverlap_hits hits=$overlap_hits figfam=$fam";
    }
    close($prot_fh);
    
    for my $ent (@$protein_locations)
    {
	my($loc_id, $contig, $start, $stop) = @$ent;
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	$feature_loc{$loc_id} = [$contig, $start, $strand, $len];
    }

    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');

    #
    # Create features for PEGs
    #
    my $n_pegs = @$protein_locations;
    my $protein_prefix = "$genome->{id}.peg";
    my $peg_id_start = $id_server->allocate_id_range($protein_prefix, $n_pegs) + 0;
    print STDERR "allocated peg id start $peg_id_start for $n_pegs pegs\n";

    open($prot_fh, "<", \$fasta_proteins) or die "Cannot open the fasta string as a filehandle: $!";
    my $next_id = $peg_id_start;
    while (my($id, $def, $seq) = read_next_fasta_seq($prot_fh))
    {
	my $loc = $feature_loc{$id};
	my $kb_id = "$protein_prefix.$next_id";
	$next_id++;
	my $annos = [];
	push(@$annos, ['Initial gene call performed by call_genes', 'genome annotation service', time]);
	if ($feature_anno{$id})
	{
	    push(@$annos, [$feature_anno{$id}, 'genome annotation service', time]);
	}
	my $feature = {
	    id => $kb_id,
	    location => [$loc],
	    type => 'peg',
	    protein_translation => $seq,
	    aliases => [],
	    $feature_func{$id} ? (function => $feature_func{$id}) : (),
	    annotations => $annos,
	};
	push(@$features, $feature);
    }
    close($prot_fh);
    $return = $genomeTO;
#   print STDERR (ref($return), qq(\n), Dumper($return));
    
    #END call_CDSs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_CDSs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_CDSs');
    }
    return($return);
}




=head2 find_close_neighbors

  $return = $obj->find_close_neighbors($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub find_close_neighbors
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to find_close_neighbors:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'find_close_neighbors');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN find_close_neighbors
    #END find_close_neighbors
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to find_close_neighbors:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'find_close_neighbors');
    }
    return($return);
}




=head2 assign_functions_to_CDSs

  $return = $obj->assign_functions_to_CDSs($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub assign_functions_to_CDSs
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to assign_functions_to_CDSs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'assign_functions_to_CDSs');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN assign_functions_to_CDSs
    my $features = $genomeTO->{features};
    my %to;
    my $i;
    my @prots;
    for ($i=0; ($i < @$features); $i++)
    {
	$to{$features->[$i]->{id}} = $i;
	my $fid = $features->[$i];
	my $translation;
	if (defined($translation = $fid->{protein_translation}))
	{
	    my $id = $fid->{id};
	    push(@prots,[$id,'',$translation]);
	}
    }
    my $anno = ANNOserver->new();
    my $handle = $anno->assign_function_to_prot(-input => \@prots,
						-kmer => 8,
						-scoreThreshold => 3,
						-seqHitThreshold => 3);
    while (my $res = $handle->get_next())
    {
	my($id, $function, $otu, $score, $nonoverlap_hits, $overlap_hits, $details, $fam) = @$res;
	$features->[$to{$id}]->{function} = $function;
	push(@{$features->[$to{$id}]->{annotations}},
	     ["Set function to\n$function\nby assign_function_to_CDSs with otu=$otu score=$score nonoverlap=$nonoverlap_hits hits=$overlap_hits figfam=$fam",
	      'genome annotation service',
	      time
	     ]);
    }
    $return = $genomeTO;
    #END assign_functions_to_CDSs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to assign_functions_to_CDSs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'assign_functions_to_CDSs');
    }
    return($return);
}




=head2 annotate_proteins

  $return = $obj->annotate_proteins($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description

Given a genome object populated with feature data, reannotate
the features that have protein translations. Return the updated
genome object.

=back

=cut

sub annotate_proteins
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to annotate_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_proteins');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN annotate_proteins
    #END annotate_proteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to annotate_proteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_proteins');
    }
    return($return);
}




=head2 call_CDSs_by_projection

  $return = $obj->call_CDSs_by_projection($genomeTO)

=over 4

=item Parameter and return types

=begin html

<pre>
$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genomeTO is a genomeTO
$return is a genomeTO
genomeTO is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome_id
	1: a float

	DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
	0: a string
	1: an int
	2: an int
	3: an int
	4: a string

	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description



=back

=cut

sub call_CDSs_by_projection
{
    my $self = shift;
    my($genomeTO) = @_;

    my @_bad_arguments;
    (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genomeTO\" (value was \"$genomeTO\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_CDSs_by_projection:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_CDSs_by_projection');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN call_CDSs_by_projection
    use CallByProjection;
    my @contigs;
    foreach my $gctg (@{$genomeTO->{contigs}})
    {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }
    my $parms;
    $parms->{-source} = 'KBase';
    $parms->{-csObj}  = Bio::KBase::CDMI::CDMIClient->new_for_script();

    $parms->{-k} = 4;
    $parms->{-must_pin} = 0.3;
    my $calls = &CallByProjection::call_solid_genes($genomeTO->{close_genomes},
						    \@contigs,
						    $genomeTO->{DNA_kmer_data},
						    $parms);
    $parms->{-must_pin} = 0.2;
    my $new_calls = &CallByProjection::fill_in_by_walking($genomeTO->{close_genomes},
							  \@contigs,
							  $genomeTO->{DNA_kmer_data},
							  $calls,
							  $parms);
    my $features = $genomeTO->{features};
    if (!$features)
    {
	$features = [];
	$genomeTO->{features} = $features;
    }

    my $callsN = keys(%$calls) + keys(%$new_calls);
    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');
    my $cds_prefix = "$genomeTO->{id}.CDS";
    my $cds_id_start = $id_server->allocate_id_range($cds_prefix, $callsN) + 0;
    my $next_id = $cds_id_start;
    foreach my $hit (keys(%$calls),keys(%$new_calls))
    {
	my($contig,undef,undef) = split(":",$hit);
	my $tuple = $calls->{$hit};
	my($b,$e,$trans,$func,$close_fid) = @$tuple;
	my $len = abs($e-$b)+1;
	my $strand = ($b < $e) ? '+' : '-';

	my $anno_type = $calls->{$hit} ? ["called by projection using kmers from $close_fid",'genome annotation service',time] :
	                                 ["called by projextion based on neighbors from $close_fid",'genome annotation service',time];
	my $kb_id = "$cds_prefix.$next_id";
	my $fidH = { location => [$contig,$b,$strand,$len],
		     id => $kb_id,
		     type => 'CDS',
		     function => $func,
		     aliases => [],
		     annotations => [$anno_type] 
                   };
	push(@$features, $fidH);
 	$next_id++;
    }
    $return = $genomeTO;
    #END call_CDSs_by_projection
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_CDSs_by_projection:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_CDSs_by_projection');
    }
    return($return);
}




=head1 TYPES



=head2 md5

=over 4



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



=head2 md5s

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a md5
</pre>

=end html

=begin text

a reference to a list where each element is a md5

=end text

=back



=head2 genome_id

=over 4



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



=head2 feature_id

=over 4



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



=head2 contig_id

=over 4



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



=head2 feature_type

=over 4



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



=head2 region_of_dna

=over 4



=item Description

A region of DNA is maintained as a tuple of four components:

                the contig
                the beginning position (from 1)
                the strand
                the length

           We often speak of "a region".  By "location", we mean a sequence
           of regions from the same genome (perhaps from distinct contigs).


=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: a contig_id
1: an int
2: a string
3: an int

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: a contig_id
1: an int
2: a string
3: an int


=end text

=back



=head2 location

=over 4



=item Description

a "location" refers to a sequence of regions


=item Definition

=begin html

<pre>
a reference to a list where each element is a region_of_dna
</pre>

=end html

=begin text

a reference to a list where each element is a region_of_dna

=end text

=back



=head2 annotation

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a string
1: a string
2: an int

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a string
1: a string
2: an int


=end text

=back



=head2 feature

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a feature_id
location has a value which is a location
type has a value which is a feature_type
function has a value which is a string
protein_translation has a value which is a string
aliases has a value which is a reference to a list where each element is a string
annotations has a value which is a reference to a list where each element is an annotation

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a feature_id
location has a value which is a location
type has a value which is a feature_type
function has a value which is a string
protein_translation has a value which is a string
aliases has a value which is a reference to a list where each element is a string
annotations has a value which is a reference to a list where each element is an annotation


=end text

=back



=head2 contig

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a contig_id
dna has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a contig_id
dna has a value which is a string


=end text

=back



=head2 genomeTO

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a genome_id
scientific_name has a value which is a string
domain has a value which is a string
genetic_code has a value which is an int
source has a value which is a string
source_id has a value which is a string
close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
0: a genome_id
1: a float

DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
0: a string
1: an int
2: an int
3: an int
4: a string

contigs has a value which is a reference to a list where each element is a contig
features has a value which is a reference to a list where each element is a feature

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a genome_id
scientific_name has a value which is a string
domain has a value which is a string
genetic_code has a value which is an int
source has a value which is a string
source_id has a value which is a string
close_genomes has a value which is a reference to a list where each element is a reference to a list containing 2 items:
0: a genome_id
1: a float

DNA_kmer_data has a value which is a reference to a list where each element is a reference to a list containing 5 items:
0: a string
1: an int
2: an int
3: an int
4: a string

contigs has a value which is a reference to a list where each element is a contig
features has a value which is a reference to a list where each element is a feature


=end text

=back



=head2 subsystem

=over 4



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



=head2 variant

=over 4



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



=head2 variant_of_subsystem

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a subsystem
1: a variant

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a subsystem
1: a variant


=end text

=back



=head2 variant_subsystem_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a variant_of_subsystem
</pre>

=end html

=begin text

a reference to a list where each element is a variant_of_subsystem

=end text

=back



=head2 fid

=over 4



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



=head2 role

=over 4



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



=head2 function

=over 4



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



=head2 fid_role_pair

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a role

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a role


=end text

=back



=head2 fid_role_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid_role_pair
</pre>

=end html

=begin text

a reference to a list where each element is a fid_role_pair

=end text

=back



=head2 fid_function_pair

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a function

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a function


=end text

=back



=head2 fid_function_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid_function_pair
</pre>

=end html

=begin text

a reference to a list where each element is a fid_function_pair

=end text

=back



=head2 reconstructionTO

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
subsystems has a value which is a variant_subsystem_pairs
bindings has a value which is a fid_role_pairs
assignments has a value which is a fid_function_pairs

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
subsystems has a value which is a variant_subsystem_pairs
bindings has a value which is a fid_role_pairs
assignments has a value which is a fid_function_pairs


=end text

=back



=head2 fid_data_tuple

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: a fid
1: a md5
2: a location
3: a function

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: a fid
1: a md5
2: a location
3: a function


=end text

=back



=head2 fid_data_tuples

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid_data_tuple
</pre>

=end html

=begin text

a reference to a list where each element is a fid_data_tuple

=end text

=back



=cut

1;
