
package My::Fixtures;

use strict;
use warnings 'all';
use base 'Class::DBI::Lite::Fixture';
use My::State;

my @state_info = qw( AL:Alabama AK:Alaska AR:Arkansas );
my @states = ( );

sub setup_states
{
  push @states, map {
    my ($abbr, $name) = split /\:/, $_;
    My::State->find_or_create(
      state_name  => $name,
      state_abbr  => $abbr,
    )
  } @state_info;
}# end setup_states()

sub destroy_states
{
  map { eval{$_->delete} } @states;
}# end destroy_states()

1;# return true:

