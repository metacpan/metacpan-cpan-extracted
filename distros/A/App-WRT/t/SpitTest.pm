package SpitTest;

use base 'App::WRT::MethodSpit';

__PACKAGE__->methodspit( qw( cat ) );
__PACKAGE__->methodspit_depend(
  'cat',
  { moose => 'bark' }
);

sub new {
  my ($class) = shift;
  my $self = { @_ };
  bless $self, $class;
}

1;
