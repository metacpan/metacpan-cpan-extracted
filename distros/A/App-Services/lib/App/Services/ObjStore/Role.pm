package App::Services::ObjStore::Role;
{
  $App::Services::ObjStore::Role::VERSION = '0.002';
}    #-- Log service interface

use Moose::Role;

use common::sense;

has obj_store_svc => (
	is       => 'rw',
	isa      => 'App::Services::ObjStore::Service',
	handles  => [qw(all_objects)],
	required => 1,

);

no Moose::Role;

1;

__END__

=pod

=head1 NAME

App::Services::ObjStore::Role

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
