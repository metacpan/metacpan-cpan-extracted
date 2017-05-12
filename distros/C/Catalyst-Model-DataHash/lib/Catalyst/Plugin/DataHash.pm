package Catalyst::Plugin::DataHash;

use Moo::Role;
use CatalystX::InjectComponent;

our $VERSION = 1;

before 'setup_components' => sub {
  my $class = shift;
  $class->config(default_model=>'DataHash');
  CatalystX::InjectComponent->inject(
    into => $class,
    component => 'Catalyst::Model::DataHash',
    as => 'Model::DataHash' );
};

1;

=head1 NAME

Catalyst::Plugin::DataHash - Inject a Catalyst::Model::DataHash and make that default_model

=head1 SYNOPSIS

    package MyApp;
    
    use Catalyst qw/DataHash/;

    MyApp->setup;

=head1 DESCRIPTION

Plugin that injects a model into your application that is based off
L<Catalyst::Model::DataHash> and sets that to be the default_model for the
application.  This way you can use it without having to name the model in
your actions.  For example:

    sub myaction :Local {
      my ($self, $c) = @_;
      $c->model->set(a=>1);
    }

=head1 SEE ALSO

L<Catalyst>, L<Data::Perl::Role::Collection::Hash>, L<CatalystX::InjectComponent>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
