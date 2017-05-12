package
   DBIx::Introspector::Driver;

use Moo;

has name => (
   is => 'ro',
   required => 1,
);

has _connected_determination_strategy => (
   is => 'ro',
   default => sub { sub { 1 } },
   init_arg => 'connected_determination_strategy',
);

has _unconnected_determination_strategy => (
   is => 'ro',
   default => sub { sub { 1 } },
   init_arg => 'unconnected_determination_strategy',
);

has _connected_options => (
   is => 'ro',
   builder => sub {
      +{
         _introspector_driver => sub { $_[0]->name },
      }
   },
   init_arg => 'connected_options',
);

has _unconnected_options => (
   is => 'ro',
   builder => sub {
      +{
         _introspector_driver => sub { $_[0]->name },
      }
   },
   init_arg => 'unconnected_options',
);

has _parents => (
   is => 'ro',
   default => sub { +[] },
   init_arg => 'parents',
);

sub _add_connected_option {
   my ($self, $key, $value) = @_;

   $self->_connected_options->{$key} = $value
}

sub _add_unconnected_option {
   my ($self, $key, $value) = @_;

   $self->_unconnected_options->{$key} = $value
}

sub _determine {
   my ($self, $dbh, $dsn) = @_;

   my $connected_strategy = $self->_connected_determination_strategy;

   return $self->$connected_strategy($dbh, $dsn) if $dbh;

   my $unconnected_strategy = $self->_unconnected_determination_strategy;
   $self->$unconnected_strategy($dsn)
}

sub _get_when_unconnected {
   my ($self, $args) = @_;

   my $drivers_by_name = $args->{drivers_by_name};
   my $key = $args->{key};

   if (exists $self->_unconnected_options->{$key}) {
      my $option = $self->_unconnected_options->{$key};

      return $option->($self, $args->{dbh})
        if ref $option && ref $option eq 'CODE';
      return $option;
   }
   elsif (@{$self->_parents}) {
      my @p = @{$self->_parents};
      for my $parent (@p) {
         my $driver = $drivers_by_name->{$parent};
         die "no such driver <$parent>" unless $driver;
         my $ret = $driver->_get_when_unconnected($args);
         return $ret if defined $ret
      }
   }
   return undef
}

sub _get_when_connected {
   my ($self, $args) = @_;

   my $drivers_by_name = $args->{drivers_by_name};
   my $key = $args->{key};

   if (exists $self->_connected_options->{$key}) {
      my $option = $self->_connected_options->{$key};

      return $option->($self, $args->{dbh}, $args->{dsn})
        if ref $option && ref $option eq 'CODE';
      return $option;
   }
   elsif (@{$self->_parents}) {
      my @p = @{$self->_parents};
      for my $parent (@p) {
         my $driver = $drivers_by_name->{$parent};
         die "no such driver <$parent>" unless $driver;
         my $ret = $driver->_get_when_connected($args);
         return $ret if $ret
      }
   }
   return undef
}

sub _get_info_from_dbh {
  my ($self, $dbh, $info) = @_;

  if ($info =~ /[^0-9]/) {
    require DBI::Const::GetInfoType;
    $info = $DBI::Const::GetInfoType::GetInfoType{$info};
    die "Info type '$_[1]' not provided by DBI::Const::GetInfoType"
      unless defined $info;
  }

  $dbh->get_info($info);
}

1;
