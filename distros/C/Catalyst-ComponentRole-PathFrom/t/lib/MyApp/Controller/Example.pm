package MyApp::Controller::Example;
use base 'Catalyst::Controller';

sub test :Local {
  my ($self, $c) = @_;
}

sub test2 :Local {
  my ($self, $c) = @_;
}

sub test3 :Local PathFrom('ffffff') {
  my ($self, $c) = @_;
}

sub test4 :Local PathFrom(':namespace/ffffff') {
  my ($self, $c) = @_;
}

__PACKAGE__->meta->make_immutable;
