package Cantella::Worker::Types;

use MooseX::Types -declare => [
  'WorkerClassName'
];

our $VERSION = '0.001001';
$VERSION = eval $VERSION;

use MooseX::Types::Moose qw/ClassName/;
use Moose::Util qw/does_role/;

subtype WorkerClassName,
  as ClassName,
  where { does_role($_, 'Cantella::Worker::Role::Worker') },
  message { "Worker class does not do role 'Cantella::Worker::Role::Worker'" };

1;

__END__;

=head1 NAME

Cantella::Worker::Types - Types related to Cantella::Worker classes

=head1 TYPES

=head2 WorkerClassName

A ClassName that does the role L<Cantella::Worker::Role::Worker>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2010 by Guillermo Roditi.
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

