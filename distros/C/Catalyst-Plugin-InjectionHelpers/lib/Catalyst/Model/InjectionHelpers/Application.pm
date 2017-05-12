package Catalyst::Model::InjectionHelpers::Application;

use Moose;
with 'Catalyst::ComponentRole::InjectionHelpers'; 

has instance => (
  is=>'ro',
  init_arg=>undef,
  lazy=>1,
  required=>1,
  default=>sub {$_[0]->build_new_instance($_[0]->application)} );

sub ACCEPT_CONTEXT {
  my ($self, $c, @ignored) = @_;
  return $self->instance;
}

__PACKAGE__->meta->make_immutable;


=head1 NAME

Catalyst::Model::InjectionHelpers::Application - Adaptor for application scoped models

=head1 SYNOPSIS

    package MyApp;

    use Catalyst 'InjectionHelper';

    MyApp->inject_components(
    'Model::ApplicationScoped' => {
      from_class=>'MyApp::Singleton', 
      adaptor=>'Application', 
      roles=>['MyApp::Role::Foo'], 
      method=>sub {
        my ($adaptor, $class, $app, %args) = @_;
        return $class->new(aaa=>$args{arg});
      },
    });

    MyApp->config(
      'Model::ApplicationScoped' => { aaa=>100 },
    );

    MyApp->setup;
    
=head1 DESCRIPTION

Injection helper adaptor for application scoped model.  See L<Catalyst::Plugin::InjectionHelpers>
for details.

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
