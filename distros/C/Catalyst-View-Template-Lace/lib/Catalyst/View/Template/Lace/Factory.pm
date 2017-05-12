package Catalyst::View::Template::Lace::Factory;

use Moo;

extends 'Template::Lace::Factory';

has 'catalyst_component_name' => (is=>'ro');

sub ACCEPT_CONTEXT {
  my ($factory, $c, @args) = @_;
  return $factory unless ref $c;
  return $factory->create(@args, ctx=>$c);
}

1;

=head1 NAME

Catalyst::View::Template::Lace::Factory - Adapt Template::Lace for Catalyst

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

This is a subclass of L<Template::Lace::Factory> which does C<ACCEPT_CONTEXT>
so that we can adapt the creation of templates to L<Catalyst>.  Any arguments
passed to the C<view> method are sent to C<create>.  We also capture the context
object and send it as C<ctx> as an argument, that way your templates get access
to context via the C<ctx> attributes (see L<Catalyst::View::Template::Lace>.)

Otherwise there's no real user useful bits here beyond education.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Template::Lace>, L<Catalyst::View::Template::Lace>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
