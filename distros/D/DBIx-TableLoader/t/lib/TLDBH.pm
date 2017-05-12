package # no_index
  TLSTH;

sub new {
  bless {}, shift
}

sub execute {
  my $self = shift;
  push @{ $self->{execute} ||= [] }, [@_];
}

package # no_index
  TLDBH;

sub new {
  my $class = shift;
  my $self = {
    @_ == 1 ? %{ $_[0] } : @_,
  };
  bless $self, $class;
  $self->reset;
  return $self;
}

sub prepare {
  $_[0]->{prepared}++;
  return $_[0]->{sth};
}

sub quote_identifier { shift; join('.', map { qq["$_"] } grep { $_ } @_); }

sub do { $_[0]->{do} = $_[1] }

sub type_info {
  my $self = shift;
  return $self->{driver_type} ? {TYPE_NAME => $self->{driver_type}} : undef;
}

sub begin_work       { $_[0]->{begin}++;    $_[0]->{tr}++ }
sub commit           { $_[0]->{commit}++;   $_[0]->{tr}-- }
sub rollback         { $_[0]->{rollback}++; $_[0]->{tr}-- }

sub reset {
  my $self = shift;

  $self->{sth} ||= TLSTH->new;
  $self->{sth}->{execute} = [];

  $self->{prepared} = 0;
  $self->{begin} = $self->{commit} = $self->{rollback} = 0;
}

1;
