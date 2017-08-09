package DBIx::Class::Wrapper::Object;
$DBIx::Class::Wrapper::Object::VERSION = '0.009';
use Moose;
has 'factory' => ( isa => 'DBIx::Class::Wrapper::Factory' , required => 1 , is => 'ro' );

=head1 NAME

DBIx::Class::Wrapper::Object - Base class for object containing business code around another DBIC object.

=head1 PROPERTIES

=over

=item bm

The business model. Mandatory.

=back

=head1 EXAMPLE

  package My::BM::O::User;
  use Moose;
  extends qw/DBIx::Class::Wrapper::Object/;

  has 'dbuser' => ( isa => 'My::Schema::Result::User' , is => 'ro' , required => 1 , handles => qw/.*/ );

  sub check_password{
      my ($self , $password) = @_;
      return $self->password() eq $password; # Do NOT do that :)
  }
  1;

=cut

__PACKAGE__->meta->make_immutable();
1;
