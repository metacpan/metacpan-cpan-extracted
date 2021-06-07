package Alien::Graphene;
# ABSTRACT: Alien package for the Graphene graphics math library
$Alien::Graphene::VERSION = '0.003';
use strict;
use warnings;

use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

use File::Spec;

sub gi_typelib_path {
	my ($class) = @_;
	$class->install_type eq 'share'
		? ( File::Spec->catfile( $class->dist_dir, qw(lib girepository-1.0) ) )
		: ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Graphene - Alien package for the Graphene graphics math library

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Alien::Base>

=back

=head1 CLASS METHODS

=head2 gi_typelib_path

A path for using with L<Glib::Object::Introspection> to load the typelib
needed.

  use Env qw(@GI_TYPELIB_PATH);
  push @GI_TYPELIB_PATH, Alien::Graphene->gi_typelib_path;

=head1 SEE ALSO

L<Graphene|https://ebassi.github.io/graphene/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
