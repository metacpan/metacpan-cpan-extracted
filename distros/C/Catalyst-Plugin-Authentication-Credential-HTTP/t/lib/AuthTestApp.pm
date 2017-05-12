package AuthTestApp;
use Catalyst qw/
  Authentication
  Authentication::Store::Minimal
  Authentication::Credential::HTTP
  /;
use Test::More;
our $users;
sub moose : Local {
    my ( $self, $c ) = @_;
    $c->authorization_required;
    $c->res->body( $c->user->id );
}
__PACKAGE__->config->{authentication}{http}{type} = 'basic';
__PACKAGE__->config->{authentication}{users} = $users = {
    foo => { password         => "s3cr3t", },
};
__PACKAGE__->setup;

