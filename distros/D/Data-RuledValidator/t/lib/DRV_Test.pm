package DRV_Test;

sub new{
  shift;
  my %query = @_;
  bless \%query;
}

sub p{
  my($self, $k, $v) = @_;
  return
    @_ == 3 ? $self->{$k} = $v :
    @_ == 2 ? ref $self->{$k} ?
              wantarray       ? @{$self->{$k}} : $self->{$k}->[0] : $self->{$k} :
              keys %{$self};
}

sub self{
  shift;
}

package Data::RuledValidator::Filter;

sub birth_year_check{
  my($self, $v, $drv, $values) = @_;
  my($q, $method) = ($drv->obj, $drv->method);
  my($year) = $q->$method('birth_year');
  my $r = $q->$method(birthyear_is_1777 => $year == 1777);
  return $$v = $r;
}

1;
