package Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic;
$Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic::VERSION = '0.02';
use strict;
use warnings;

#ABSTRACT: A generic sequence mapper for sequence mapping
use Carp;
use Module::Runtime 'use_module';
use Module::Find;
use Scalar::Util 'blessed';
use Moose;
use namespace::autoclean;
###############################################################################
## Searching/Mapping related methods
has 'init_sim_search' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'init_sim_search', @_ ) },
);

has 'seq_align' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'seq_align', @_ ) },
);

has 'extract_sim_metric' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'extract_sim_metric', @_ ) },
);

has 'reduce_sim_metric' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'reduce_sim_metric', @_ ) },
);

has 'cleanup' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'cleanup', @_ ) },
);

###############################################################################
## Reference Database related methods
has 'create_refDB' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'create_refDB', @_ ) },
);

has 'use_refDB' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
    trigger => sub { $_[0]->_nondefault_set( 'use_refDB', @_ ) },
);

## around modifiers to allow $self to be passed as an argument
around qw(
  create_refDB
  use_refDB
  cleanup
  reduce_sim_metric
  seq_align
  init_sim_search
  extract_sim_metric
  ) => sub {
    my $orig = shift;
    my $self = shift;

    # Modify the behavior (if needed)
    return sub {
        ## may put code to modify the logic prior to returning
        return $self->$orig->( $self, @_ );
    };
  };
###############################################################################
## Parameters used for database creation/access, similarity search &  mapping
has 'refDB_access_params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    trigger => sub { $_[0]->_nondefault_set( 'refDB_access_params', @_ ) },
);

has 'sim_search_params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    trigger => sub { $_[0]->_nondefault_set( 'sim_search_params', @_ ) },
);

has 'extract_sim_metric_params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    trigger =>
      sub { $_[0]->_nondefault_set( 'extract_sim_metric_params', @_ ) },
);

has 'seqmap_params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    trigger => sub { $_[0]->_nondefault_set( 'seqmap_params', @_ ) },
);
###############################################################################
## around accessors to allow updating of parameters
around qw(
  refDB_access_params
  sim_search_params
  extract_sim_metric_params
  seqmap_params
  ) => sub {
    my $orig = shift;
    my $self = shift;

    #current prameter value
    my $current_param_value = $self->$orig;

    # my new parameter value
    my $new_param_value = shift;

    #return current value if no new value is provided
    return $current_param_value
      unless $new_param_value;

    #update current value with new value, if new value is non empty
    if ($current_param_value) {
        return ( keys %$new_param_value )
          ? $self->$orig( { %$current_param_value, %$new_param_value } )
          : $self->$orig( {} )
          ;    #reset to empty hash if new value is the empty hash
    }
    else {
        #set current value to new value if current value is not defined
        return $self->$orig($new_param_value);
    }

  };
###############################################################################
## Keep track of what has been explicitly set by the user

has '_has_nondefault_value' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        is_nondefault        => 'exists',
        get_nondefault_value => 'get',
        set_nondefault_value => 'set',
    },
);

sub _nondefault_set {
    my ( $self, $attribute, $new_value, $old_value ) = @_;
    $self->set_nondefault_value( $attribute, 1 );
}
###############################################################################
## This may be used by the init_sim_search method to store the code for each
## external function (or program) that one may want to interface with

has '_code_for' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        has_function_for => 'exists',
        get_function_for => 'get',
        set_function_for => 'set',
    },
);
###############################################################################

__PACKAGE__->meta->make_immutable;

1;



=head1 NAME

Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic Generic Sequence Mapper

=head1 VERSION

version 0.02

=head1 SYNOPSIS

To use the module one must do *at least* the following:

  use Module::Find;
  use Moose::Util qw( apply_all_roles );
  use Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic;

The rest depends on the dataflow role applied to the mapper
The example under USAGE utilizes the LinearLinearGeneric role
to demonstrate the usage of the Generic module with the most
code that needs to be implemented by the user.


=head1 DESCRIPTION

This module loads all the components that can actually map sequences to a reference
database. If you don't want to nuke your namespace with all the components, you can 
load them as needed by using the specific component name, e.g.:

  use Bio::SeqAlignment::Components::SeqMapping::Mapper::ComponentName;

where ComponentName is the name of the component you need.
If you choose violence, you can load all the components at once by using:

  use Bio::SeqAlignment::Components::SeqMapping::Mapper;

=head1 USAGE


  use Module::Find;
  use Moose::Util qw( apply_all_roles );
  use Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic;

  ## apply the LinearLinearGeneric role to the Generic module
  use Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric;
  use Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic;
  
  my $mapper = Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic->new(
    create_refDB       => \&create_db,
    use_refDB          => \&use_refDB,
    init_sim_search    => \&init_sim_search,
    seq_align          => \&seq_align,
    extract_sim_metric => \&extract_sim_metric,
    reduce_sim_metric  => \&reduce_sim_metric
  );

  ## db_location : where to create the database
  ## dbname : name of the database
  ## dbfiles : array ref of the files that hold the reference sequences
  $mapper->create_refDB->( $db_location, $dbname, \@dbfiles );
  my $ref_DB = $mapper->use_refDB->( $db_location, 'Hsapiens.cds.sample' );
  $mapper->sim_search_params( { ... } ); 

  ## apply the LinearLinearGeneric Dataflow role to the mapper
  apply_all_roles( $mapper,
    'Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric'
  );

  ## workload : array ref of the sequences to be mapped
  ## max_workers : number of workers to use for process level parallelism through MCE
  my @workload = ... ;
  $results        = $mapper->sim_seq_search( \@workload, max_workers => 4 );

  ## a combo of the the following methods will be required to be implemented 
  ## by the user depending on the dataflow role applied to the mapper
  sub init_sim_search {
    my ( $self, %params ) = @_;
    ...
  }    

  sub reduce_sim_metric {
    my ( $self, $sim_metric, %params ) = @_;
    ...
  }

  sub seq_align {
     my ( $self, $query_fname ) = @_;
     ...
  }

  sub extract_sim_metric {
     my ( $self,          $seq_align )           = @_;
     ...
  }

  sub create_db {
    my ( $self, $dbloc, $dbname, $files_aref ) = @_;
    ...
  }

  sub use_refDB {
     my $self = shift;
     ...
  }

=head1 ATTRIBUTES

=head2 cleanup

A code reference that cleans up the data after the mapping process. This method
is required to be implemented by the user. If you don't implement it, the default
is a coderef to an empty subroutine. If you leave it unimplemented, you probably
don't need this.

=head2 create_refDB

A code reference that creates the reference database. This method is required to
be implemented by the user. If you don't implement it, the default is a coderef to
an empty subroutine. If you leave it unimplemented, you probably don't need this,
e.g. you have already created your database of reference sequences somehow.
Perhaps the database was created by someone else, or you are using a pre-existing
database, or you created the database through this interface at some time in the
past. If none of the above hold true, then you probably DO need to provide the
code for this method, through the created_refDB attribute.

=head2 extract_sim_metric

A code reference that extracts the similarity metric from the search. This method
is required to be implemented by the user. If you don't implement it, the default
is a coderef to an empty subroutine. If you leave it unimplemented, you probably
don't need this, e.g. you are NOT using the LinearLinearGeneric dataflow role.

=head2 extract_sim_metric_params

A hash reference that holds the parameters for extracting the similarity metric. This
attribute is required to be set by the user. If you don't set it, the default is an
empty hash reference. If you leave it unimplemented, you probably don't need this, e.g.
your similarity extraction is not parameterized, and the extraction is hardwired into
the extract_sim_metric method. However, DO consider scenarios in which the extraction
is parameterized, e.g. you have to filter out some sequences from the search results
based on some criteria, that can be controlled by the user.

=head2 init_sim_search

A code reference that initializes the similarity search. This method is required
to be implemented by the user. If not implemented, the default is a coderef to 
an empty subroutine. If you leave it unimplemented, you probably don't need this.

=head2 reduce_sim_metric

A code reference that reduces the similarity metric to a single value. This method
is required to be implemented by the user. If you don't implement it, the default
is a coderef to an empty subroutine. If you leave it unimplemented, you probably
don't need this, e.g. you are NOT using the LinearLinearGeneric dataflow role.

=head2 refDB_access_params

A hash reference that holds the parameters for accessing the reference database.
This attribute is required to be set by the user. If you don't set it, the default
is an empty hash reference. If you leave it unimplemented, you probably don't need
this, i.e. you will not be (for example) accessing the database over the network.

=head2 seq_align

A code reference that performs the sequence alignment. This method is required
to be implemented by the user. If you don't implement it, the default is a coderef
to an empty subroutine. If you leave it unimplemented, you probably don't mind 
having a non-working code. 

=head2 seqmap_params

A hash reference that holds the parameters for the sequence mapping. This attribute
is required to be set by the user. If you don't set it, the default is an empty hash
reference. If you leave it unimplemented, you probably don't need this, e.g. you 
have hardwired the mapping parameters into the seq_align method. However, DO consider
scenarios in which the mapping is parameterized, e.g. you have to filter out some
sequences before the search based on some criteria, that can be controlled by the user.
Another scenario that you may (or rather SHOULD) use this parameter for is to control
the similarity search parameters, e.g. provide match/mismatch scores, gap penalties,
etc. that are used by the similarity search algorithm.

=head2 sim_search_params

A hash reference that holds the parameters for the similarity search. This attribute
is required to be set by the user. If you don't set it, the default is an empty hash
reference. If you leave it unimplemented, you probably don't need this, e.g. you are
performing a similarity search with a default you have somehow hardwired into the
similarity search code (that would be the init_sim_search or seq_align methods).

=head2 sim_seq_search

This is a B<role> method that is applied to the generic mapper. It is provided 
by a dataflow role that is composed into the generic mapper. This method is used
to perform the sequence mapping. This method is implemented in one of the generic
mapper's dataflow roles, e.g. LinearLinearGeneric, LinearGeneric, etc. The user
only needs to apply this to the generic mapper, and then call it with the 
appropriate arguments. See under USAGE for how to do this in general, and
under the B<EnhancingEdlib> example for a specific example.

=head2 use_refDB

A code reference that accesses the reference database. This method is required to
be implemented by the user. If you don't implement it, the default is a coderef to
an empty subroutine. If you leave it unimplemented, you probably don't mind have
a code that does not work.


=head1 METHODS

=head2 _nondefault_set

A method that sets the _has_nondefault_value attribute. This method is used internally
to keep track of what has been explicitly set by the user.

=head2 _code_for

A method that sets the _code_for attribute. This method is used internally to keep
track of the code for each external function (or program) that one may want to interface
with.


=head1 SEE ALSO

=over 4

=item * L<Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric|https://metacpan.org/pod/Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric>

LinearLinear Generic Dataflow role that can be composed into the Generic Mapper.

=item * L<Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearGeneric|https://metacpan.org/pod/Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearGeneric>

Linear Generic Dataflow role that can be composed into the Generic Mapper.

=item * L<Bio::SeqAlignment::Examples::EnhancingEdlib|https://metacpan.org/pod/Bio::SeqAlignment::Examples::EnhancingEdlib>

Example of how to use the Generic Mapper with the LinearLinearGeneric and the 
LinearGeneric Dataflow roles, along with the Edlib alignment library.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
