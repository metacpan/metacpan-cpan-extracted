package TestSchema::Result::Artist;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

use TestUtils::MakeInstanceMetaClassNonInlinableIf
  $ENV{DBIC_MOOSECOLUMNS_NON_INLINABLE};

BEGIN {
  if ($ENV{DBIC_MOOSECOLUMNS_SUBCLASS}) {
    extends 'TestSchema::Result';
  }
  else {
    eval q{ use DBIx::Class::MooseColumns; 1; } or die;
    extends 'DBIx::Class::Core';
  }
}

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table('artist');

# used for testing if ->add_column() works (also PK so used to find the row)
has artist_id => (
  isa => 'Int',
  is  => 'rw',
  add_column => {
    is_auto_increment => 1,
  },
);

# used for testing if ->add_column() works, also for reader/writer, predicate,
# clearer methods
has name => (
  isa => 'Maybe[Str]',
  is  => 'rw',
  predicate => 'has_name',
  clearer   => 'clear_name',
  add_column => {
    is_nullable => 0,
  },
);

# used to test custom accessor
has title => (
  isa => 'Maybe[Str]',
  is  => 'rw',
  accessor => '_title',
  add_column => {
    is_nullable => 1,
  },
);

# used for InflateColumn tests
has birthday => (
  isa => 'Maybe[Str]',
  is  => 'rw',
  add_column => {
    is_nullable => 1,
    data_type => 'date',
  },
);

# used for benchmarking (Moose accessor)
has phone => (
  # no type constraint (to be fair)
  is  => 'rw',
  add_column => {
  },
);

# used for benchmarking (CAG accessor)
has address => (
  isa => 'Maybe[Str]',
  is  => 'rw',
);

__PACKAGE__->add_column( address => {} );

# used for testing if ->add_column() works (ie. not called on this attribute)
has guess => (
  isa => 'Int',
  is  => 'ro',
  default => sub { int(rand 100)+1 },
);

# used to test the builder
has initials => (
  isa => 'Str',
  is  => 'rw',
  builder    => '_build_initials',
  add_column => {
  },
);

# used to test the default value
has is_active => (
  isa => 'Int',
  is  => 'rw',
  default => 1,
  add_column => {
  },
);

# used to test the initializer
has favourite_color => (
  isa => 'Maybe[Str]',
  is  => 'rw',
  initializer => '_initialize_favourite_color',
  add_column => {
    is_nullable => 1,
  },
);

# used for testing the trigger method
has last_album => (
  isa         => 'Maybe[Str]',
  is          => 'rw',
  add_column  => {
    is_nullable => 1,
  },
  trigger     => sub {
    my ($self, $new_value, $old_value) = (shift, @_);

    $self->is_active(1);
  },
);

sub _build_initials
{
  my ($self) = (shift, @_);

  return join "", map { uc $_ } ($self->name || "") =~ /(?:^| )(.)/g;
}

sub _initialize_favourite_color
{
  my ($self, $value, $setter, $attr) = (shift, @_);

  $setter->(lc $value);
}

# silly example (better to do this with a trigger) but i couldn't invent
# anything better :-)
sub title
{
  my ($self, $value) = (shift, @_);

  if (@_ > 0) {
    die "Invalid title" if defined $value && $value ne 'Dr' && $value ne 'Prof';
    return $self->_title($value);
  }
  else {
    return $self->_title;
  }
}

__PACKAGE__->set_primary_key('artist_id');

__PACKAGE__->meta->make_immutable( inline_constructor => 0 )
  if $ENV{DBIC_MOOSECOLUMNS_IMMUTABLE} && !$ENV{DBIC_MOOSECOLUMNS_NON_INLINABLE};

1;
