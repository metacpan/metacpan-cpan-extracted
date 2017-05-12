package # hide from PAUSE
    RestTest::Schema::ResultSet::Track;

use base 'RestTest::Schema::ResultSet';

sub search {
	my $self = shift;
	my ($clause, $params) = @_;

  if (ref $clause eq 'ARRAY') {
    # test custom attrs
    if (my $pretend = delete $clause->[0]->{'cd.pretend'}) {
      $clause->[0]->{'cd.year'} = $pretend;
    }
  }
  my $rs = $self->SUPER::search(@_);
}

1;
