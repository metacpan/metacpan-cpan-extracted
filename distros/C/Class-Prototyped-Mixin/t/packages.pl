

package HelloWorld;

sub hello {
  my ($self, $age) = @_;
  return "Hello World! I am $age years old"
}


1;

package HelloWorld::Uppercase;
use base qw(Class::Prototyped);

__PACKAGE__->reflect->addSlot(
  [qw(hello superable)] => sub {
    my $self = shift;
    my $ret = $self->reflect->super('hello', @_);
    uc $ret
  }
 );


package HelloWorld::Bold;
use base qw(Class::Prototyped);

__PACKAGE__->reflect->addSlot(
  [qw(hello superable)] => sub {
    my $self = shift;
    my $ret = $self->reflect->super('hello', @_);
    "<b>$ret</b>";
  }
 );


package HelloWorld::Italic;
use base qw(Class::Prototyped);

__PACKAGE__->reflect->addSlot(
  [qw(hello superable)] => sub {
    my $self = shift;
    my $ret = $self->reflect->super('hello', @_);
    "<i>$ret</i>";   }
 );
