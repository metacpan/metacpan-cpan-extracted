package Cogit::Object::Blob;
$Cogit::Object::Blob::VERSION = '0.001001';
use Moo;
use namespace::clean;

extends 'Cogit::Object';

has '+kind' => ( default => sub { 'blob' } );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Object::Blob

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
