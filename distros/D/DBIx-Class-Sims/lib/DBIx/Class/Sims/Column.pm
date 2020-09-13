# This class exists to encapsulate the a DBIx::Class column hashref and provide
# Sims-specific functionality to navigate columns and what goes into a column.

package DBIx::Class::Sims::Column;

use 5.010_001;

use strictures 2;

use DDP;

use DateTime::Event::Random;

# The type functions are given a column object, so have all the random functions
# be available as methods on the column object.
use DBIx::Class::Sims::Random qw(
  random_integer random_decimal
  random_string random_regex
  random_item random_choice
);

# Requires the following attributes:
# * source
# * name
# * info
sub new {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->initialize;
  return $self;
}

my %types = (
  numeric => {( map { $_ => 1 } qw(
    tinyint smallint mediumint bigint
    int integer int1 int2 int3 int4 int8 middleint
    bool boolean
  ))},
  decimal => {( map { $_ => 1 } qw(
    float float4 float8
    real
    double
    decimal dec
    numeric
    fixed
  ))},
  string => {( map { $_ => 1 } qw(
    char varchar varchar2
    binary varbinary
    text tinytext mediumtext longtext long
    blob tinyblob mediumblob longblob
  ))},
  # These will be unhandled
  datetime => {( map { $_ => 1 } qw(
    date
    datetime
    timestamp
    year
  ))},
  #unknown => {( map { $_ => 1 } qw(
  #  enum set bit json
  #  geometry point linestring polygon
  #  multipoint multilinestring multipolygon geometrycollection
  #))},
);

sub initialize {
  my $self = shift;

  $self->{is_in_pk} = 0;
  $self->{uks} = [];
  $self->{fks} = [];

  $self->info->{data_type} //= 'unknown';
  if ( exists $types{numeric}{$self->info->{data_type}} ) {
    $self->{type} = 'numeric';
  }
  elsif ( exists $types{decimal}{$self->info->{data_type}} ) {
    $self->{type} = 'decimal';
  }
  elsif ( exists $types{string}{$self->info->{data_type}} ) {
    $self->{type} = 'string';
  }
  elsif ( exists $types{datetime}{$self->info->{data_type}} ) {
    $self->{type} = 'datetime';
  }
  else {
    $self->{type} = 'unknown';
  }

  # This is to conform to the interface expected by the types tests.
  $self->{predictable_values} = $self->source->runner->{predictable_values};

  return;
}

sub info { shift->{info} }
sub name { shift->{name} }
sub source { shift->{source} }
sub sim_spec {
  my $self = shift;

  unless (exists $self->{sim_spec}) {
    if ($self->info->{sim}) {
      $self->{sim_spec} = MyCloner::clone($self->info->{sim});

      # Handle the optional plural of "value"
      if (exists $self->{sim_spec}{values}) {
        $self->{sim_spec}{value} = delete $self->{sim_spec}{values};
      }
    }
    else {
      $self->{sim_spec} = undef;
    }
  }

  return $self->{sim_spec};
}

sub is_nullable { shift->info->{is_nullable} }
sub is_auto_increment { shift->info->{is_auto_increment} }
sub is_inflated { defined shift->info->{_inflate_info} }

sub has_default_value { exists shift->{info}{default_value} }
#sub default_value {}

sub is_in_pk { shift->{is_in_pk} }
sub in_pk { shift->{is_in_pk} = 1; return }

sub is_in_uk { @{shift->{uks}} != 0 }
sub in_uk { push @{shift->{uks}}, $_[0]; return }

sub is_in_fk { @{shift->{fks}} != 0 }
sub in_fk { push @{shift->{fks}}, $_[0]; return }
sub fks { @{shift->{fks}} }

sub is_datetime { shift->{type} eq 'datetime' }
sub is_decimal  { shift->{type} eq 'decimal' }
sub is_numeric  { shift->{type} eq 'numeric' }
sub is_string   { shift->{type} eq 'string' }
#sub is_unknown { shift->{type} eq 'unknown' }

sub generate_value {
  my $self = shift;
  my %opts = @_;
  $opts{die_on_unknown} //= 1;

  my $spec = $self->sim_spec;
  if ( $self->is_numeric ) {
    my $min = $spec->{min} // 0;
    my $max = $spec->{max} // 100;
    return int(rand($max-$min))+$min;
  }
  elsif ( $self->is_decimal ) {
    my $min = $spec->{min} // 0;
    my $max = $spec->{max} // 100;
    return rand($max-$min)+$min;
  }
  elsif ( $self->is_string ) {
    my $min = $spec->{min} // 1;
    my $max = $spec->{max} // $self->info->{data_length} // $self->info->{size} // $min;
    return $self->random_regex(
      '\w' . "{$min,$max}"
    );
  }
  elsif ( $self->is_datetime ) {
    my $dt_set = DateTime::Event::Random->new(
      start => DateTime->new( year => 1900 ),
      end   => DateTime->new( year => 2100 ),
    );
    return $dt_set->next( DateTime->today )->datetime;
  }
  elsif ( $opts{die_on_unknown} ) {
    die "ERROR: @{[$self->source->name]}\.@{[$self->name]} is not nullable, but I don't know how to handle @{[$self->info->{data_type}]}\n";
  }
}

1;
__END__
