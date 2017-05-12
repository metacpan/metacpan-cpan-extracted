package Dallycot::Value::DateTime;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Date and time values

use strict;
use warnings;
use experimental qw(switch);

use utf8;
use parent 'Dallycot::Value::Any';

use Carp qw(croak);
use DateTime;
use List::Util qw(any);
use Scalar::Util qw(blessed);
use Promises qw(deferred);

sub new {
  my($class, %options) = @_;

  $class = ref $class || $class;

  for my $k (keys %options) {
    $options{$k} = $options{$k} -> value -> numify if blessed($options{$k}) && $options{$k}->isa('Dallycot::Value::Numeric');
  }

  my $datetime_class = delete $options{'class'};
  $datetime_class //= 'DateTime';

  if($options{object}) {
    return bless [
      $datetime_class->from_object(object => $options{object})
    ] => $class;
  }
  else {
    return bless [
      $datetime_class->new(
        map { $_ => $options{$_} } grep { $options{$_} } keys %options
      )
    ] => $class;
  }
}

sub to_rdf {
  my($self, $model) = @_;

  # we need to record the date/time as represented in RDF, but might want to
  # record the calendar type as well
  my $literal = RDF::Trine::Node::Literal->new(
    DateTime->from_object(object => $self->[0])->iso8601,
    '',
    $model -> meta_uri('xsd:dateTime')
  );

  return $literal if $self->[0] -> isa('DateTime');

  my $bnode = $model->bnode;
  $model -> add_type($bnode, 'loc:DateTime');
  $model -> add_connection($bnode, 'rdf:value', $literal);
  my $calendar_type = (reverse split(/::/, blessed($self->[0])))[0];
  $model -> add_connection($bnode, 'loc:calendar', $calendar_type);
  if($self->[0]->can('epoch')) {
    $model -> add_connection($bnode, 'loc:epoch', $model->integer(
      $self->[0]->epoch
    ));
  }

  return $bnode;
}

sub now {
  my($class, $timezone) = @_;

  $class = ref $class || $class;

  return bless [ DateTime -> now(time_zone => $timezone) ] => $class;
}

sub in_timezone {
  my($self, $timezone) = @_;

  my $class = ref $self;

  return bless [ $self -> [0] -> clone -> set_time_zone($timezone) ] => $class;
}

# sub to_calendar {
#   my($self, $calendar_class) = @_;
#
#   my $class = ref $self;
#
#   return bless [ $calendar_class->from_object(object => $self->[0]) ] => $class;
# }

sub as_text {
  my($self) = @_;

  if($self -> [0] -> can('datetime')) {
    return $self -> [0] -> datetime;
  }
  else {
    return $self -> [0] -> date;
  }
}

sub is_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value == $other->value );

  return $d->promise;
}

sub is_less {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value < $other->value );

  return $d->promise;
}

sub is_less_or_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value <= $other->value );

  return $d->promise;
}

sub is_greater {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value > $other->value );

  return $d->promise;
}

sub is_greater_or_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value >= $other->value );

  return $d->promise;
}

sub prepend {
  my( $self, @things ) = @_;

  # if durations, we add
  # if numeric, we add as seconds
  # otherwise, we can't prepend
  if(any { !$_->isa('Dallycot::Value::Numeric') && !$_->isa('Dallycot::Value::Duration') } @things) {
    croak 'Only durations and numeric values may be added to dates and times';
  }

  my @durations = map {
    my $v = $_;
    given(blessed $v) {
      when('Dallycot::Value::Numeric') {
        DateTime::Duration->new(
          seconds => $v->value->numify
        );
      }
      when('Dallycot::Value::Duration') {
        $v -> value;
      }
    }
  } @things;

  my $accumulator = $self->value;
  $accumulator = $accumulator + $_ for @durations;
  return $self -> new(object => $accumulator, class => blessed($accumulator));
}

1;
