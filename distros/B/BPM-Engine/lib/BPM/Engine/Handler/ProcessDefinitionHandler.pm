package BPM::Engine::Handler::ProcessDefinitionHandler;
BEGIN {
    $BPM::Engine::Handler::ProcessDefinitionHandler::VERSION   = '0.01';
    $BPM::Engine::Handler::ProcessDefinitionHandler::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireEndWithOne, RequireTidyCode)
use MooseX::Declare;

role BPM::Engine::Handler::ProcessDefinitionHandler {

  use BPM::Engine::Types qw/Exception LibXMLDoc UUID/;
  use BPM::Engine::Exceptions qw/throw_engine throw_model throw_store/;

  method get_packages (@args) {

      return $self->schema->resultset('Package')->search_rs(@args);
      }

  method get_package (UUID|HashRef $id, HashRef $args = {}) {

      my $pid = ref($id) ? $id : { package_id => $id };

      return $self->schema->resultset('Package')->find($pid, $args)
          || do {
            my $pack = $pid->{package_id} || $pid->{package_uid} || '';
            my $error = "Package $pack not found";
            $self->logger->error($error);
            throw_store(error => $error);
            };
      }  
  
  method create_package (Str|ScalarRef|LibXMLDoc $args) {

      my $package = eval {
          $self->schema->resultset('Package')->create_from_xpdl($args);
          };
      if(my $err = $@) {
          $self->error($err);
          is_Exception($err) ? $err->rethrow() : throw_model(error => $err);
          }

      return $package;
      }

  method delete_package (UUID|HashRef $id) {

      my $package = $self->schema->resultset('Package')->find($id)
          or do {
            $id = $id->{package_id} || $id->{package_uid} || '' if (ref($id));
            $self->error("Package '$id' not found");
            throw_store(error => "Package '$id' not found")
            };

      return $package->delete;
      }

  method get_process_definitions (@args) {

      return $self->schema->resultset('Process')->search_rs(@args);
      }

  method get_process_definition (UUID|HashRef $id, HashRef $args = {}) {

      my $pid = ref($id) ? $id : { process_id => $id };

      return $self->schema->resultset('Process')->find($pid, $args)
          || do {
            my $proc = $pid->{process_id} || $pid->{process_uid} || '';
            my $error = "Process $proc not found";
            $self->logger->error($error);
            throw_store(error => $error);
            };
      }

}

1;
__END__

=pod

=head1 NAME

BPM::Engine::Handler::ProcessDefinitionHandler - Engine role

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This Moose role provides process definition methods to L<BPM::Engine>.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut