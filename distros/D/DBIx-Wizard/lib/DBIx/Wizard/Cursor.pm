package DBIx::Wizard::Cursor;

use strict;
use DBIx::Wizard::ResultSet;

sub new {
  my ($class, $rh_args) = @_;
  return bless($rh_args || {}, $class);
}

sub next {
  my $self = shift;

  my $rh_row = $self->{sth}->fetchrow_hashref();
  return unless $rh_row;

  my $rs = $self->{rs};

  if ($rs->{inflate}) {
    my $ic = $rs->_resolve_inflate_class;
    DBIx::Wizard::ResultSet::_inflate_time_objects([$rh_row], $rs->{db}, $rs->{table}, $ic);
  }

  return $rh_row;
}

1;
