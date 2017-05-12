package BPM::Engine::Handler::ProcessInstanceHandler;
BEGIN {
    $BPM::Engine::Handler::ProcessInstanceHandler::VERSION   = '0.01';
    $BPM::Engine::Handler::ProcessInstanceHandler::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireEndWithOne, RequireTidyCode)
use MooseX::Declare;

role BPM::Engine::Handler::ProcessInstanceHandler {

  use Scalar::Util qw/blessed/;
  use BPM::Engine::Types qw/UUID/;  
  use BPM::Engine::Exceptions qw/throw_store throw_abstract/;
  use aliased 'BPM::Engine::Store::Result::Process';
  use aliased 'BPM::Engine::Store::Result::ProcessInstance';

  requires 'runner';
  requires 'get_process_definition';

  method create_process_instance (UUID|Process $process, HashRef $args = {}) {

      $process =
        $self->get_process_definition($process, { prefetch => 'package' })
        unless blessed($process);

      return $process->new_instance($args);
      }

  method get_process_instances (@args) {

      return $self->schema->resultset('ProcessInstance')->search_rs(@args);
      }

  method get_process_instance (Int|HashRef $id, HashRef $args = {}) {

      return $self->schema->resultset('ProcessInstance')->find($id, $args)
          || throw_store(error => "Process instance '$id' not found");
      }

  method start_process_instance (Int|ProcessInstance $pi, HashRef $args = {}) {

      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      foreach (keys %{$args}) {
          $pi->attribute($_ => $args->{$_});
          }

      my $runner = $self->runner($pi);
      $runner->start_process();
      
      return;
      }

  method delete_process_instance (Int|HashRef|ProcessInstance $pi) {

      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      return $pi->delete;
      }

  method process_instance_attribute 
      (Int|HashRef|ProcessInstance $pi, Str $attr, Str $value?) {

      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      return defined($value) ?
          $pi->attribute($attr => $value ) :
          $pi->attribute($attr);
      }

  method change_process_instance_state (Int|ProcessInstance $pi, Str $state) {

      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      $pi->apply_transition($state);
      }

  method terminate_process_instance (Int|ProcessInstance $pi) {

      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      throw_abstract(error => 'Method not implemented');
      }

  method abort_process_instance (Int|ProcessInstance $pi) {

      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      throw_abstract(error => 'Method not implemented');
      }

}

1;
__END__

=pod

=head1 NAME

BPM::Engine::Handler::ProcessInstanceHandler - Engine role

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This Moose role provides process instance methods to L<BPM::Engine>.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut