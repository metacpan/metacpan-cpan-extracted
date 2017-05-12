package Catalyst::Component::WithDelayedSetup;

use Moose::Role;
our $VERSION = '0.002';

{
  package Catalyst::Component::Deferred;

  use Moose;

  has setup => (is=>'ro', required=>1, isa=>'CodeRef');

  has target => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    isa => 'Object',
    required => 1,
    default => sub { shift->setup->() } );

  sub ACCEPT_CONTEXT { return shift->target }
}

use Catalyst::Component::Deferred;

around 'COMPONENT', sub {
  my ($orig, $class, @args) = @_;
  return Catalyst::Component::Deferred
    ->new( setup => sub { $class->$orig(@args) });
};

1;

=head1 NAME

Catalyst::Component::WithDelayedSetup - Moose Role for components which setup late

=head1 SYNOPSIS

    package MyApp::Model::Foo;

    use Moose;
    extends 'Catalyst::Model';
    with 'Catalyst::Component::DelayedSetup';

    # Proceed as normal

=head1 DESCRIPTION

Sometimes you want an application scoped component that nevertheless needs other
application components as part of its setup.  In the past this was not reliable
since Application scoped components are setup in linear order.  You could not
call $app->model('A') in a COMPONENT method and expect $app->model('B') to be there
This role defers creating the application scoped instance until after your application is
fully setup.  This means you can now assume your other application scoped components
(components that do COMPONENT but not ACCEPT_CONTEXT) are available as dependencies.

Please note this means that your instance is not created until the first time its
called in a request.  As a result any errors with configuration will not show up
until later in runtime.  So there is a larger burden on your testing to make sure
your application startup and runtime is accurate.  Also note that even though your
instance creation is deferred to request time, the request context is NOT given,
but the application is (this means that you cannot depend on components that do
ACCEPT_CONTEXT, since you don't have one...).

Please note it makes no sense to use this component role and then do the ACCEPT_CONTEXT
method...

=head1 SEE ALSO

L<Catalyst::Component>, L<Catalyst>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
