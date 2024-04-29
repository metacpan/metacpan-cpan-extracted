package DBIx::DataModel::Meta::Type;
use strict;
use warnings;
use parent "DBIx::DataModel::Meta";
use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils qw/define_readonly_accessors does/;
use DBIx::DataModel::Carp;

use Scalar::Util         qw/weaken/;
use Params::Validate     qw/validate_with OBJECT SCALAR HASHREF/;
use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

sub new {
  my $class = shift;

  # parse arguments and create $self
  my $self = validate_with(
    params      => \@_,
    spec        => {
      schema   => {type => OBJECT, isa  => "DBIx::DataModel::Meta::Schema"},
      name     => {type => SCALAR},
      handlers => {type => HASHREF},
    },
    allow_extra => 0,
   );

  while (my ($name, $body) = each %{$self->{handlers}}) {
    does($body, 'CODE')
      or croak "handler body for $name is not a code reference";
  }

  # avoid circular references
  weaken $self->{schema};

  bless $self, $class;
}


# accessor methods
define_readonly_accessors(__PACKAGE__, qw/schema name handlers/);


1;

__END__

=head1 NAME

DBIx::DataModel::Meta::Type - registered collection of column handlers

=head1 SYNOPSIS

  my $type = DBIx::DataModel::Meta::Type->new(
    schema   => $meta_schema,
    name     => $type_name,
    handlers => {
      $handler_name_1 => sub { ... },
      $handler_name_2 => sub { ... },
      ...
    },
  );

=head1 DESCRIPTION

A I<type> is just a hashref of handler names and
handler bodies (coderefs). The type can then be applied to some
columns in some tables through the
L<DBIx::DataModel::Doc::Reference/define_column_type> method.








