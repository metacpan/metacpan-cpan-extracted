package DBIx::Class::MooseColumns::Meta::Role::Attribute;

use Moose::Role;
use namespace::autoclean;

use Moose::Util qw(ensure_all_roles);

=head1 NAME

DBIx::Class::MooseColumns::Meta::Role::Attribute - Attribute metaclass trait for DBIx::Class::MooseColumns

=cut

has _column_info => (
  isa => 'Maybe[HashRef]',
  is  => 'rw',
);

around new => sub {
  my ($orig, $class, $name, %options) = @_;

  my $column_info = delete $options{add_column};
  $column_info->{accessor} = $options{accessor} if $options{accessor};

  my $self = $class->$orig($name, %options);

  $self->_column_info($column_info);

  return $self;
};

before attach_to_class => sub {
  my ($self, $meta) = @_;

  my $column_info = $self->_column_info
    or return;

  my $class     = $meta->name;
  my $attr_name = $self->name;

  $class->add_column($attr_name => $column_info);

  # removing the accessor method that CAG installed (otherwise Moose
  # complains)
  $meta->remove_method($column_info->{accessor} || $attr_name);

  #FIXME respect the API - check for $class->inflate_column() calls instead of peeking into the guts of the object
  my $is_inflated_column
    = exists $class->column_info($self->name)->{_inflate_info};

  ensure_all_roles($self,
    $is_inflated_column
      ? __PACKAGE__ . '::DBICColumn::Inflated'
      : __PACKAGE__ . '::DBICColumn'
  );
};

1;
