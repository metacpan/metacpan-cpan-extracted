package Cikl::EventBuilder;
use strict;
use warnings;
use Cikl::Models::Event;
use Cikl::AddressBuilder qw/address_from_protoevent/;
use Mouse;
use namespace::autoclean;
use Try::Tiny;
use DateTime;
use Cikl::Util::TimeHelpers qw/normalize_timestamp create_strptime_parser create_default_timestamp_parser/;

has 'default_event_data' => (
  is => 'rw',
  isa => 'HashRef',
  required => 1,
  default => sub { return {}; }
);

has 'refresh' => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
  required => 1
);

has 'detecttime_format' => (
  is => 'rw', 
  isa => 'Maybe[Str]',
  required => 0
);

has 'detecttime_zone' => (
  is => 'rw', 
  isa => 'Maybe[Str]',
  required => 0
);

has 'detecttime_parser' => (
  is => 'ro',
  init_arg => undef,
  isa => 'CodeRef',
  lazy => 1,
  builder => '_build_detecttime_parser'
);

sub _build_detecttime_parser {
  my $self = shift;
  if (defined($self->detecttime_format)) {
    return create_strptime_parser(
      $self->detecttime_format, $self->detecttime_zone);
  }
  return create_default_timestamp_parser();
}

has 'not_before' => (
  is => 'rw', 
  isa => 'Int',
  required => 1,
  default => sub {
    return DateTime->now()->subtract(days => 3)->epoch();
  }
);

has '_now' => (
  is => 'ro', 
  default => sub { time() },
  init_arg => undef
);

sub merge_default_event_data {
  my $self = shift;
  my $data_to_merge = shift;
  my $merged_data = {%{$self->default_event_data}, %$data_to_merge};
  $self->default_event_data($merged_data);
}

sub normalize {
  my $self = shift;
  my $r = shift;

  my $now  = $self->_now;
  my $dt = $self->detecttime_parser->($r->{detecttime}, $now);
  if($dt < $self->not_before) {
    return(undef);
  }
  $r->{detecttime} = $dt;

  $r->{reporttime} = $self->refresh ? $now : 
      normalize_timestamp($r->{reporttime}, $now);

  $r->{address} = address_from_protoevent($r);
  # MPR: Disabling value expansion, for now.
#  foreach my $key (keys %$r){
#    my $v = $r->{$key};
#    next unless($v);
#    if($v =~ /<(\S+)>/){
#      my $value_to_expand = $1;
#      my $x = $r->{$value_to_expand};
#      if($x){
#        $r->{$key} =~ s/<\S+>/$x/;
#      }
#    }
#  }
  return $r;
}

sub build_event {
  my $self = shift;
  my $hashref = shift;
  my $err;

  if (!defined($hashref)) {
    die("build_event requires a hashref of arguments!");
  }
  my $merged_hash = {%{$self->default_event_data}, %$hashref};
  my $normalized;
  try {
    $normalized = $self->normalize($merged_hash);
  } catch {
    $err = shift;
  };
  if ($err) {
    die($err);
  }
  if (!defined($normalized)) {
    return undef;
  }

  my $event;
  try {
    $event = Cikl::Models::Event->new($normalized);
  } catch {
    $err = shift;
  };
  if ($err) {
    die("Failed to build event. Likely missing a required field: $err");
  }
  return $event;
}

__PACKAGE__->meta->make_immutable;

1;

