package Catalyst::Model::InjectionHelpers::PerRequest;

use Moose;
use Scalar::Util qw/blessed refaddr/;

with 'Catalyst::ComponentRole::InjectionHelpers'; 

sub ACCEPT_CONTEXT {
  my ($self, $c, @args) = @_;
  return $self->build_new_instance($c, @args) unless blessed $c;
  my $key = blessed $self ? refaddr $self : $self;
  return $c->stash->{"__InstancePerContext_${key}"} ||= 
    $self->build_new_instance($c, @args);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::Model::InjectionHelpers::PerRequest - Adaptor that returns a request scoped model

=head1 SYNOPSIS

    package MyApp;

    use Catalyst 'InjectionHelper';

    MyApp->inject_components(
    'Model::PerRequest' => {
      from_class=>'MyApp::PerRequest', 
      adaptor=>'PerRequest', 
      method=>'new'
    });

    MyApp->config(
      'Model::Factory' => { aaa=>100 },
    );

    MyApp->setup;
    
=head1 DESCRIPTION

Injection helper adaptor that returns a new model once for each request, scoped
to the request.  See L<Catalyst::Plugin::InjectionHelpers> for details.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst::Plugin::InjectionHelpers>
L<Catalyst>, L<Catalyst::Model::InjectionHelpers::Application>,
L<Catalyst::Model::InjectionHelpers::Factory>, L<Catalyst::Model::InjectionHelpers::PerRequest>
L<Catalyst::ModelRole::InjectionHelpers>

=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
