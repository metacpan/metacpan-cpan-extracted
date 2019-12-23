package App::CSE::Command;
$App::CSE::Command::VERSION = '0.015';
use Moose;

has 'cse' => ( is => 'ro' , isa => 'App::CSE', weak_ref => 1, required => 1);

sub options_specs{
  my ($self) = @_;
  return [];
}

=head execute

Does stuff and return an exit code.

=cut

sub execute{
  my ($self) = @_;
  die "Implement me in $self";
}


__PACKAGE__->meta->make_immutable();
