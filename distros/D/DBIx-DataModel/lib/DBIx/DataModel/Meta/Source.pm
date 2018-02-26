package DBIx::DataModel::Meta::Source;
use strict;
use warnings;
use parent "DBIx::DataModel::Meta";
use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils qw/define_class define_readonly_accessors/;

use Params::Validate qw/validate_with SCALAR ARRAYREF HASHREF OBJECT/;
use Scalar::Util     qw/weaken/;
use List::MoreUtils  qw/any/;
use Carp::Clan       qw[^(DBIx::DataModel::|SQL::Abstract)];

use namespace::clean;

#----------------------------------------------------------------------
# COMPILE-TIME METHODS
#----------------------------------------------------------------------

my %common_arg_spec = (
  schema          => {isa  => "DBIx::DataModel::Meta::Schema"},
  class           => {type => SCALAR},
  default_columns => {type => SCALAR,          default => "*"},
  parents         => {type => OBJECT|ARRAYREF, default => [] },
  primary_key     => {type => SCALAR|ARRAYREF, default => [] },
  aliased_tables  => {type => HASHREF,         default => {} }, # for joins

  # other slot filled later : 'name'
);

define_readonly_accessors(__PACKAGE__, keys %common_arg_spec, 'name');


sub _new_meta_source { # called by new() in Meta::Table and Meta::Join
  my $class         = shift;
  my $more_arg_spec = shift;
  my $isa_slot      = shift;

  # validation spec is built from a common part and a specific part
  my %spec = (%common_arg_spec, %$more_arg_spec);

  # validate the parameters
  my $self = validate_with(
    params      => \@_,
    spec        => \%spec,
    allow_extra => 0,
   );

  # force into arrayref if accepts ARRAYREF but given as scalar
  for my $attr (grep {($spec{$_}{type} || 0) & ARRAYREF} keys %spec) {
    next if not $self->{$attr};
    $self->{$attr} = [$self->{$attr}] if not ref $self->{$attr};
  }

  # the name is the short class name (before prepending the schema)
  $self->{name} = $self->{class};

  # prepend schema name in class name, unless it already contains "::"
  $self->{class} =~ s/^/$self->{schema}{class}::/
    unless $self->{class} =~ /::/;

  # avoid circular references
  weaken $self->{schema};

  # instanciate the metaclass
  bless $self, $class;

  # build the list of parent classes
  my @isa = map {$_->{class}} @{$self->{parents}};
  if ($isa_slot) {
    my $parent_class = $self->{schema}{$isa_slot}[0];
    unshift @isa, $parent_class
      unless any {$_->isa($parent_class)} @isa;
  }

  # create the Perl class
  define_class(
    name   => $self->{class},
    isa    => \@isa,
    metadm => $self,
   );

  return $self;
}


#----------------------------------------------------------------------
# RUN-TIME METHODS
#----------------------------------------------------------------------



sub ancestors { # walk through parent metaobjects, similar to C3 inheritance
  my $self = shift;
  my %seen;
  my @pool = $self->parents;
  my @result;
  while (@pool) {
    my $parent = shift @pool;
    if (!$seen{$parent}){
      $seen{$parent} = 1;
      push @result, $parent;
      push @pool, $parent->parents;
    }
  }
  return @result;
}




sub path               {shift->_consolidate_hash('path', @_)}
sub auto_insert_column {shift->_consolidate_hash('auto_insert_columns', @_)}
sub auto_update_column {shift->_consolidate_hash('auto_update_columns', @_)}
sub no_update_column   {shift->_consolidate_hash('no_update_columns', @_)}

sub _consolidate_hash {
  my ($self, $field, $optional_hash_key) = @_;
  my %hash;

  my @meta_sources = ($self, $self->ancestors, $self->{schema});

  foreach my $meta_source (reverse @meta_sources) {
    while (my ($name, $val) = each %{$meta_source->{$field} || {}}) {
      $val ? $hash{$name} = $val : delete $hash{$name};
    }
  }
  # foreach my $meta_source ($self, $self->ancestors, $self->{schema}) {
  #   while (my ($name, $val) = each %{$meta_source->{$field} || {}}) {
  #     $hash{$name} ||= $val;
  #   }
  # }
  return $optional_hash_key ? $hash{$optional_hash_key} : %hash;
}


sub db_from {
  my $self = shift;
  my $class = ref $self;
  die "db_from() not implemented in $class";
}

sub where {
  my $self = shift;
  my $class = ref $self;
  die "where() not implemented in $class";
}


1;


